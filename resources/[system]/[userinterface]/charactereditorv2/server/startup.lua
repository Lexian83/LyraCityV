-- LCV Character Editor - Server (manager-only, no SQL)
-- Vorsichtig angepasst: Save läuft NUR über playerManager

local function log(level, msg)
    level = level or "INFO"
    print(("[CharacterEditor][%s] %s"):format(level, tostring(msg)))
end

-- Robust: JSON-Decode wenn String reinkommt
local function decodeMaybeJSON(data)
    if type(data) == 'string' then
        local ok, parsed = pcall(function() return json.decode(data) end)
        return ok and parsed or nil
    end
    return data
end

-- PlayerManager-Locator (resilient gegen Ressourcennamen)
local function PM()
    if GetResourceState('playerManager') == 'started' then return exports['playerManager'] end
    if GetResourceState('lcv-playermanager') == 'started' then return exports['lcv-playermanager'] end
    return nil
end

-- YYYY-MM-DD erzwingen (falls UI DD.MM.YYYY liefert)
local function normalizeBirthdate(val)
    if not val or val == '' then return '2000-01-01' end
    if type(val) == 'string' then
        -- 1) DD.MM.YYYY -> YYYY-MM-DD
        local d,m,y = val:match('^(%d%d)%.(%d%d)%.(%d%d%d%d)$')
        if d and m and y then
            return string.format('%04d-%02d-%02d', tonumber(y), tonumber(m), tonumber(d))
        end
        -- 2) YYYY-MM-DD passt schon
        local y2,m2,d2 = val:match('^(%d%d%d%d)%-(%d%d)%-(%d%d)$')
        if y2 and m2 and d2 then return val end
        -- 3) Fallback leer -> Default
        return '2000-01-01'
    end
    return '2000-01-01'
end

-- ====== Editor öffnen (weiterhin wie bei dir)
RegisterNetEvent('character:Edit', function(oldData, accId)
    local src = source
    if type(oldData) == 'string' then
        oldData = decodeMaybeJSON(oldData) or {}
    elseif type(oldData) ~= 'table' then
        oldData = {}
    end
    TriggerClientEvent('character:Edit', src, oldData, accId)
end)

-- ====== Live-Sync (weiterreichen an Client)
RegisterNetEvent('character:Sync', function(data, clothes)
    local src = source
    local parsed        = decodeMaybeJSON(data)
    local parsedClothes = decodeMaybeJSON(clothes)
    if not parsed or type(parsed) ~= 'table' then
        log('WARN', 'character:Sync: invalid data')
        return
    end
    local model = (parsed.sex == 0) and 'mp_f_freemode_01' or 'mp_m_freemode_01'
    TriggerClientEvent('character:SetModel', src, model)
    TriggerClientEvent('character:Sync', src, parsed, parsedClothes or {})
end)

-- ====== Modell vorbereiten (unchanged)
RegisterNetEvent('character:AwaitModel', function(characterSex)
    local src = source
    local model = (characterSex == 0) and 'mp_f_freemode_01' or 'mp_m_freemode_01'
    TriggerClientEvent('character:SetModel', src, model)
    TriggerClientEvent('character:FinishSync', src)
end)

-- ====== Speichern (NEUER CHAR) -> NUR playerManager
-- NUI -> client/editor.lua -> TriggerServerEvent('character:Done', payload, account_id)
RegisterNetEvent('character:Done', function(payload, account_id)
    local src = source

    payload = decodeMaybeJSON(payload) or payload
    if type(payload) ~= 'table' then
        log("WARN", "character:Done ohne gültigen Payload -> zurück ins Charselect.")
        TriggerEvent('LCV:charselect:load', src, account_id)
        return
    end
    if not payload.data or not payload.identity or not payload.clothes then
        log("WARN", "character:Done ohne vollständige Blocks -> zurück ins Charselect.")
        TriggerEvent('LCV:charselect:load', src, account_id)
        return
    end

    local accID = tonumber(account_id)
    if not accID then
        log("ERROR", "character:Done mit ungültiger account_id.")
        TriggerEvent('LCV:charselect:load', src, account_id)
        return
    end

    local d = payload.data
    local i = payload.identity
    local c = payload.clothes

    local fname    = i.fname or ''
    local sname    = i.sname or ''
    local fullName = (sname ~= '' or fname ~= '') and (('%s,%s'):format(sname, fname)) or 'Unbekannt,Unbekannt'

    local birthdate = normalizeBirthdate(i.birthdate)
    local gender    = tonumber(d.sex or 0) or 0
    local country   = i.country or ''
    local past      = tonumber(i.past or 0) or 0

    local newChar = {
        name             = fullName,
        gender           = gender,
        heritage_country = country,
        birthdate        = birthdate,
        past             = past,
        residence_permit = 0,
        health           = 200,
        thirst           = 200,
        food             = 200,
        pos              = { x = 0, y = 0, z = 0 },
        heading          = 0,
        dimension        = 0,
        appearance       = d,
        clothes          = c,
    }

    local pm = PM()
    if not pm or not pm.CreateCharacter then
        log("ERROR", "playerManager Export CreateCharacter nicht verfügbar.")
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Serverfehler: PlayerManager nicht verfügbar.' })
        TriggerEvent('LCV:charselect:load', src, accID)
        return
    end

    local ok, err = pcall(function()
        pm:CreateCharacter(accID, newChar, function(id)
            if not id then
                log("ERROR", ("Charakter konnte nicht gespeichert werden (Account %s)."):format(accID))
                TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Charakter konnte nicht gespeichert werden.' })
                TriggerEvent('LCV:charselect:load', src, accID)
                return
            end
            log("INFO", ("Charakter gespeichert via playerManager. ID=%s, Account=%s, Name=%s"):format(id, accID, newChar.name))
            TriggerClientEvent('character:SaveSuccess', src, id)
            -- Zurück in die Char-Auswahl
            TriggerEvent('LCV:charselect:load', src, accID)
        end)
    end)

    if not ok then
        log("ERROR", "CreateCharacter Export-Fehler: " .. tostring(err))
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Serverfehler beim Speichern.' })
        TriggerEvent('LCV:charselect:load', src, accID)
    end
end)

-- ====== Abbruch (unchanged)
RegisterNetEvent('character:Cancel', function(account_id)
    local src = source
    log("INFO", ("Editor abgebrochen von %s, zurück zum Charselect."):format(src))
    TriggerEvent('LCV:charselect:load', src, account_id)
end)
