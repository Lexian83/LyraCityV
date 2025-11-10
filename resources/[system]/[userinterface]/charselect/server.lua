-- LCV Character Select - Server Side
-- Jetzt verdrahtet mit playerManager / SQL Characters

local MAX_CHARACTERS = 6

local function slog(level, msg)
    level = level or "info"
    if LCV and LCV.Util and LCV.Util.log then
        return LCV.Util.log(level, ('[LCV-CharSelect] %s'):format(tostring(msg)))
    else
        print(("[LCV-CharSelect][%s] %s"):format(level:upper(), tostring(msg)))
    end
end

-- Lädt alle Charaktere eines Accounts aus LCV.Characters
local function loadCharactersForAccount(accountId, cb)
    if not (LCV and LCV.Characters and LCV.Characters.listByAccount) then
        slog("error", "LCV.Characters.listByAccount nicht verfügbar (SQL-Resource geladen?)")
        return cb({
            canCreate     = false,
            maxCharacters = MAX_CHARACTERS,
            characters    = {}
        })
    end

    LCV.Characters.listByAccount(accountId, function(rows)
        rows = rows or {}
        local characters = {}

        for _, r in ipairs(rows) do
            characters[#characters + 1] = {
                id        = r.id,
                accountid = r.account_id,
                name      = r.name or ("Char #" .. r.id),
                gender    = r.gender,
                birthdate = r.birthdate, -- falls vorhanden im Select
                type      = r.type or 0,
                is_locked = (r.is_locked == 1)
            }
        end

        local canCreate = true
        if #characters >= MAX_CHARACTERS then
            canCreate = false
        end

        cb({
            canCreate     = canCreate,
            maxCharacters = MAX_CHARACTERS,
            characters    = characters
        })
    end)
end

-- Baut Payload auf Basis accountId oder über playerManager
local function buildPayload(src, rawAccountId, cb)
    src = tonumber(src)
    if not src or src <= 0 then
        return cb({
            canCreate     = false,
            maxCharacters = MAX_CHARACTERS,
            characters    = {}
        }, nil)
    end

    local accountId = tonumber(rawAccountId)

    -- Wenn keine accountId mitgegeben: über playerManager holen
    if not accountId and GetResourceState('playerManager') == 'started' then
        local ok, acc = pcall(function()
            return exports['playerManager']:GetAccountId(src)
        end)
        if ok and acc then
            accountId = tonumber(acc)
        end
    end

    if not accountId then
        slog("warn", ("buildPayload: kein accountId für src=%s"):format(src))
        return cb({
            canCreate     = false,
            maxCharacters = MAX_CHARACTERS,
            characters    = {}
        }, nil)
    end

    loadCharactersForAccount(accountId, function(payload)
        cb(payload, accountId)
    end)
end

-- =========================
-- Charselect öffnen (von auth)
-- =========================
-- auth ruft:
--   TriggerEvent('LCV:charselect:load', src, accountId)
AddEventHandler("LCV:charselect:load", function(targetSrc, accountId)
    local eventSource = source
    local src = tonumber(eventSource) or 0

    -- Wenn intern vom Server (TriggerEvent) → targetSrc ist der Spieler
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

        slog("info", ("CharSelect opened for %s (acc=%s chars=%d canCreate=%s)")
            :format(
                GetPlayerName(src) or src,
                tostring(resolvedAccountId),
                #(payload.characters or {}),
                tostring(payload.canCreate)
            ))
    end)
end)

-- =========================
-- Reload aus Client (optional)
-- =========================
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

-- =========================
-- NUI schließen (Server-seitig)
-- =========================
RegisterNetEvent("LCV:charselect:close", function()
    local src = tonumber(source) or 0
    if src > 0 then
        TriggerClientEvent("LCV:charselect:close", src)
    end
end)

-- =========================
-- Charakter auswählen (HOOK → playerManager)
-- =========================
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

    -- UI zu
    TriggerClientEvent("LCV:charselect:close", src)

    -- Übergabe an PlayerManager:
    -- dieser prüft Ownership, lädt Full Data und triggert LCV:spawn
    TriggerEvent("LCV:Player:SelectCharacter", src, id)

    slog("info", ("Selected char %d for %s (weiter an PlayerManager)")
        :format(id, GetPlayerName(src) or src))
end)

-- =========================
-- Platzhalter für Delete/Rename Hooks
-- (UI kann später direkt PlayerManager Events nutzen)
-- =========================
-- Beispiel:
-- RegisterNetEvent("LCV:charselect:delete", function(charId)
--     local src = source
--     TriggerEvent("LCV:Player:DeleteCharacter", src, tonumber(charId))
-- end)
--
-- RegisterNetEvent("LCV:charselect:rename", function(charId, newName)
--     local src = source
--     TriggerEvent("LCV:Player:RenameCharacter", src, tonumber(charId), newName)
-- end)

AddEventHandler("playerDropped", function()
    -- optional: cleanup / bucket reset etc.
end)
