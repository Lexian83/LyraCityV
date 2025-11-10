-- LCV Character Select - Server Side (ACE-free, type-safe)

local MAX_CHARACTERS = 6

local function slog(level, msg)
    level = level or "info"
    if LCV and LCV.Util and LCV.Util.log then
        return LCV.Util.log(level, msg)
    else
        print(("[LCV-CharSelect][%s] %s"):format(level:upper(), tostring(msg)))
    end
end

local function getDiscordId(src)
    src = tonumber(src)
    if not src then return nil end

    for _, id in ipairs(GetPlayerIdentifiers(src)) do
        if id:sub(1, 8) == "discord:" then
            return id:sub(9)
        end
    end
end

-- Charaktere für Account laden
local function loadCharactersForAccount(src, accountId, accountNewFlag, cb)
    if not accountId then
        return cb({
            canCreate     = false,
            maxCharacters = MAX_CHARACTERS,
            characters    = {}
        }, nil)
    end

    MySQL.query([[
        SELECT
            id,
            account_id,
            name,
            gender,
            DATE_FORMAT(birthdate, '%d.%m.%Y') AS birthdate,
            type,
            is_locked
        FROM characters
        WHERE account_id = ?
        ORDER BY id ASC
    ]], { accountId }, function(rows)
        rows = rows or {}
        local characters = {}

        for _, r in ipairs(rows) do
            characters[#characters + 1] = {
                id        = r.id,
                accountid = r.account_id,
                name      = r.name or ("Char #" .. r.id),
                gender    = r.gender,
                birthdate = r.birthdate,
                type      = r.type or 0,
                is_locked = (r.is_locked == 1)
            }
        end

        local canCreate = (tonumber(accountNewFlag) == 1)
        if #characters >= MAX_CHARACTERS then
            canCreate = false
        end

        cb({
            canCreate     = canCreate,
            maxCharacters = MAX_CHARACTERS,
            characters    = characters
        }, accountId)
    end)
end

-- Account + Characters anhand accountId oder Discord finden
-- cb(payload, resolvedAccountId)
local function buildPayload(src, rawAccountId, cb)
    src = tonumber(src)
    if not src or src <= 0 then
        return cb({
            canCreate     = false,
            maxCharacters = MAX_CHARACTERS,
            characters    = {}
        }, nil)
    end

    -- 1) numeric accountId übergeben?
    local numericId = tonumber(rawAccountId)
    if numericId then
        MySQL.single(
            "SELECT CAST(`new` AS UNSIGNED) AS new FROM accounts WHERE id = ? LIMIT 1",
            { numericId },
            function(acc)
                if acc then
                    return loadCharactersForAccount(src, numericId, acc.new, cb)
                end

                -- Fallback über Discord
                local discordId = getDiscordId(src)
                if not discordId then
                    slog("warn", ("buildPayload: no account for id=%s / no discord for %s")
                        :format(tostring(rawAccountId), tostring(src)))
                    return cb({
                        canCreate     = false,
                        maxCharacters = MAX_CHARACTERS,
                        characters    = {}
                    }, nil)
                end

                MySQL.single(
                    "SELECT id, CAST(`new` AS UNSIGNED) AS new FROM accounts WHERE discord_id = ? LIMIT 1",
                    { discordId },
                    function(acc2)
                        if not acc2 then
                            return cb({
                                canCreate     = true,
                                maxCharacters = MAX_CHARACTERS,
                                characters    = {}
                            }, nil)
                        end
                        loadCharactersForAccount(src, acc2.id, acc2.new, cb)
                    end
                )
            end
        )
        return
    end

    -- 2) Kein numeric accountId -> über Discord
    local discordId = getDiscordId(src)
    if not discordId then
        slog("warn", ("buildPayload: no valid accountId and no discord for %s"):format(tostring(src)))
        return cb({
            canCreate     = false,
            maxCharacters = MAX_CHARACTERS,
            characters    = {}
        }, nil)
    end

    MySQL.single(
        "SELECT id, CAST(`new` AS UNSIGNED) AS new FROM accounts WHERE discord_id = ? LIMIT 1",
        { discordId },
        function(acc)
            if not acc then
                return cb({
                    canCreate     = true,
                    maxCharacters = MAX_CHARACTERS,
                    characters    = {}
                }, nil)
            end

            loadCharactersForAccount(src, acc.id, acc.new, cb)
        end
    )
end

-- Charselect öffnen (vom Auth oder Editor)
RegisterNetEvent("LCV:charselect:load", function(targetSrc, accountId)
    local eventSource = source
    local src = tonumber(eventSource) or 0

    -- Wenn von Server intern (TriggerEvent) aufgerufen: targetSrc enthält Spieler-ID
    if src == 0 and targetSrc ~= nil then
        local t = tonumber(targetSrc)
        if t and t > 0 then
            src = t
        end
    end

    if src <= 0 then
        slog("warn", ("charselect:load invalid src (source=%s target=%s)")
            :format(tostring(eventSource), tostring(targetSrc)))
        return
    end

    buildPayload(src, accountId, function(payload, resolvedAccountId)
        resolvedAccountId = resolvedAccountId or accountId

        TriggerClientEvent("LCV:charselect:show", src, payload, resolvedAccountId)

        if resolvedAccountId then
            SetPlayerRoutingBucket(src, resolvedAccountId)
        end

        slog("info", ("CharSelect opened for %s (acc=%s chars=%d canCreate=%s)")
            :format(
                GetPlayerName(src) or src,
                tostring(resolvedAccountId),
                #(payload.characters or {}),
                tostring(payload.canCreate)
            ))
    end)
end)

-- Reload aus Client (optional)
RegisterNetEvent("LCV:charselect:reload", function()
    local src = tonumber(source) or 0
    if src <= 0 then
        return
    end

    buildPayload(src, nil, function(payload, resolvedAccountId)
        TriggerClientEvent("LCV:charselect:show", src, payload, resolvedAccountId)

        slog("info", ("CharSelect reload for %s (acc=%s chars=%d canCreate=%s)")
            :format(
                GetPlayerName(src) or src,
                tostring(resolvedAccountId),
                #(payload.characters or {}),
                tostring(payload.canCreate)
            ))
    end)
end)

-- NUI schließen
RegisterNetEvent("LCV:charselect:close", function()
    local src = tonumber(source) or 0
    if src > 0 then
        TriggerClientEvent("LCV:charselect:close", src)
    end
end)

-- Charakter auswählen
RegisterNetEvent("LCV:charselect:select", function(charId)
    local src = tonumber(source) or 0
    if src <= 0 then return end

    local id = tonumber(charId)
    if not id then
        TriggerClientEvent("ox_lib:notify", src, {
            type = "error",
            description = "Ungültige Charakter-ID."
        })
        return
    end

    MySQL.single([[
        SELECT id, account_id, is_locked
        FROM characters
        WHERE id = ?
        LIMIT 1
    ]], { id }, function(row)
        if not row then
            TriggerClientEvent("ox_lib:notify", src, {
                type = "error",
                description = "Ungültiger Charakter."
            })
            return
        end

        if row.is_locked == 1 then
            TriggerClientEvent("ox_lib:notify", src, {
                type = "error",
                description = "Dieser Charakter ist gesperrt."
            })
            return
        end

        TriggerClientEvent("LCV:charselect:close", src)

        -- hier hängst du dein Spawn-System dran
        TriggerEvent("LCV:charselect:spawn", src, row.id)

        slog("info", ("Selected char %d for %s")
            :format(id, GetPlayerName(src) or src))
    end)
end)

AddEventHandler("playerDropped", function()
    -- optional: cleanup / bucket reset etc.
end)
