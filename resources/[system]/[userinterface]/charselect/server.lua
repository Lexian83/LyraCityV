-- LCV Character Select - Server Side
-- Dependencies: oxmysql
-- Ensure order in server.cfg: ensure oxmysql, ensure log (optional), ensure LCV_charselect

local MAX_CHARACTERS = 6             -- adjust for your server
local SHOW_PLUS_REQUIRES_ACE = false  -- if true, player needs ace 'LCV.char.create' AND slots left

-- Optional logger bridge
local function slog(level, msg)
    if LCV and LCV.Util and LCV.Util.log then
        return LCV.Util.log(level, msg)
    end
    -- print(("[LCV-CharSelect][%s] %s"):format((level or 'INFO'):upper(), tostring(msg)))
end

-- Identifier helper
local function getIdentifier(src)
    local ids = GetPlayerIdentifiers(src)
    local license, license2, fivem, steam, discord
    for _, id in ipairs(ids) do
        if id:find("license2:") == 1 then license2 = id
        elseif id:find("license:") == 1 then license = id
        elseif id:find("fivem:") == 1 then fivem = id
        elseif id:find("steam:") == 1 then steam = id
        elseif id:find("discord:") == 1 then discord = id
        end
    end
    return license2 or license or fivem or steam or discord or ids[1]
end

-- Build payload
local function buildPayload(src, id, cb)
    local identifier = id

    -- A) "new" als Zahl erzwingen
    exports.oxmysql:fetch("SELECT CAST(`new` AS UNSIGNED) AS new FROM accounts WHERE id = ?", { identifier }, function(accountRows)
        local canCreate = false
        if accountRows and accountRows[1] and accountRows[1].new == 1 then
            canCreate = true
        end

        -- Debug optional
        -- print('NEW?:', accountRows and accountRows[1] and accountRows[1].new, 'type=', type(accountRows and accountRows[1] and accountRows[1].new))

        exports.oxmysql:fetch([[
            SELECT id, account_id, name, gender,
                   DATE_FORMAT(birthdate, '%d.%m.%Y') AS birthdate,
                   type, is_locked
            FROM characters WHERE account_id = ?
        ]], { identifier }, function(rows)
            rows = rows or {}
            local characters = {}

            for _, r in ipairs(rows) do
                characters[#characters + 1] = {
                    id = r.id,
                    accountid = r.account_id,   -- <- account_id jetzt mit selektiert
                    name = r.name,
                    birthdate = r.birthdate,
                    type = r.type or 'human',
                    is_locked = (r.is_locked == 1),
                    gender = r.gender
                }
            end

            local payload = {
                canCreate = canCreate,
                maxCharacters = MAX_CHARACTERS,
                characters = characters,
            }

            cb(payload)
        end)
    end)
end



-- Open for player
RegisterNetEvent('LCV:charselect:load', function(targetSrc, accountId)
    -- Auth ruft: TriggerEvent('LCV:charselect:load', src, S.account_id)
    local src = tonumber(targetSrc) or -1      -- MUSS der Spieler sein, nicht 'source'
    if src < 1 or not accountId then
        slog('warn', ('charselect:load missing args (src=%s, accountId=%s)'):format(tostring(src), tostring(accountId)))
        return
    end
    buildPayload(src,accountId, function(payload)
        TriggerClientEvent('LCV:charselect:show', src, payload,accountId)
        SetPlayerRoutingBucket(targetSrc, accountId)
        slog('info', ('CharSelect sent to %s (account=%s, chars=%d, canCreate=%s)'):
            format(GetPlayerName(src) or src, tostring(accountId), #(payload.characters or {}), payload.canCreate))
    end)
end)

-- Create character
RegisterNetEvent('LCV:charselect:create', function()
    local src = source
    local identifier = getIdentifier(src)

    exports.oxmysql:fetch("SELECT COUNT(*) AS c FROM characters WHERE account_id = ?", { identifier }, function(rows)
        local count = rows and rows[1] and (rows[1].c or 0) or 0
        local hasAce = (not SHOW_PLUS_REQUIRES_ACE) or IsPlayerAceAllowed(src, 'LCV.char.create')
        if count >= MAX_CHARACTERS or not hasAce then
            TriggerClientEvent('ox_lib:notify', src, { type='error', description='Keine freien Charakter-Slots.' })
            slog('warn', ('Create denied for %s (count=%d, ace=%s)'):format(GetPlayerName(src), count, tostring(hasAce)))
            return
        end

        exports.oxmysql:insert("INSERT INTO characters (account_id, firstname, lastname, birthdate, status, char_type, is_locked) VALUES (?, 'Vorname', 'Nachname', CURDATE(), 'normal', 'human', 0)", { identifier }, function(newId)
            slog('info', ('Created placeholder char %s for %s'):format(tostring(newId), GetPlayerName(src)))
            buildPayload(src, function(payload)
                TriggerClientEvent('LCV:charselect:show', src, payload)
            end)
        end)
    end)
end)

-- Select character
RegisterNetEvent('LCV:charselect:selected', function(charId)
    local src = source
    local identifier = getIdentifier(src)
    slog('info', ('Selected char ID %d'):format(charId))
    exports.oxmysql:fetch("SELECT id, firstname, lastname, status, is_locked FROM characters WHERE id = ? AND account_id = ? LIMIT 1", { charId, identifier }, function(rows)
        if not rows or not rows[1] then
            TriggerClientEvent('ox_lib:notify', src, { type='error', description='Ungültiger Charakter.' })
            slog('warn', ('Invalid char select by %s (id=%s)'):format(GetPlayerName(src), tostring(charId)))
            return
        end
        local row = rows[1]
        if row.is_locked == 1 then
            TriggerClientEvent('ox_lib:notify', src, { type='error', description='Dieser Charakter ist gesperrt.' })
            return
        end
        TriggerClientEvent('LCV:charselect:close', src)
        -- TriggerEvent('LCV:charselect:spawn', src, row.id) -- hook for your spawn logic
        slog('info', ('Selected char %d for %s'):format(row.id, GetPlayerName(src)))
    end)
end)