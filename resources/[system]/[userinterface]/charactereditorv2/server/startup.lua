-- LCV Character Editor - Server
-- Integriert in LCV.Characters + playerManager + charselect

local function log(level, msg)
    level = level or "INFO"
    print(("[CharacterEditor][%s] %s"):format(level, tostring(msg)))
end

-- Hilfsfunktion: sicheres JSON-Decode
local function decodeMaybeJSON(data)
    if type(data) == 'string' then
        local ok, parsed = pcall(function()
            return json.decode(data)
        end)

        if ok and parsed ~= nil then
            return parsed
        else
            log("WARN", "Failed to decode JSON.")
            return nil
        end
    end

    return data
end

-- Öffnet den Editor mit optionalen bestehenden Daten
-- Wird z.B. von charselect/client.lua via:
--   TriggerServerEvent('character:Edit', oldData, accountId)
RegisterNetEvent('character:Edit', function(oldData, accId)
    local src = source

    if type(oldData) == 'string' then
        oldData = decodeMaybeJSON(oldData) or {}
    elseif type(oldData) ~= 'table' then
        oldData = {}
    end

    TriggerClientEvent('character:Edit', src, oldData, accId)
end)

-- Charakter speichern (NEUER CHAR) -> nutzt LCV.Characters.create
-- NUI -> client/editor.lua -> TriggerServerEvent('character:Done', data, accountid)
RegisterNetEvent('character:Done', function(payload, account_id)
    local src = source

    payload = decodeMaybeJSON(payload) or payload

    if not account_id then
        log("ERROR", ("character:Done ohne account_id von %s"):format(src))
        -- Zurück ins Charselect, falls möglich
        TriggerEvent('LCV:charselect:load', src, nil)
        return
    end

    if type(payload) ~= 'table' then
        log("WARN", "character:Done ohne gültigen Payload -> zurück ins Charselect.")
        TriggerEvent('LCV:charselect:load', src, account_id)
        return
    end

    -- Erwartete Struktur aus app.js:
    -- {
    --   data = { ... Appearance ... },
    --   clothes = { ... },
    --   identity = { fname, sname, birthdate, country, past }
    -- }
    if not payload.data or not payload.identity or not payload.clothes then
        -- Das behandeln wir als "Abbruch" / unvollständig -> zurück ins Charselect
        log("WARN", "character:Done ohne vollständige Blocks -> zurück ins Charselect.")
        TriggerEvent('LCV:charselect:load', src, account_id)
        return
    end

    local d = payload.data
    local i = payload.identity
    local c = payload.clothes

    local accID = tonumber(account_id)
    if not accID then
        log("ERROR", "character:Done mit ungültiger account_id.")
        TriggerEvent('LCV:charselect:load', src, account_id)
        return
    end

    local fname    = i.fname or ''
    local sname    = i.sname or ''
    local fullName = (sname ~= '' or fname ~= '')
        and (('%s,%s'):format(sname, fname))
        or 'Unbekannt,Unbekannt'

    local birthdate = i.birthdate or '2000-01-01'
    local gender    = d.sex or 0
    local country   = i.country or ''
    local past      = i.past or 0

    -- Datenobjekt passend zu LCV.Characters.create
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

    -- Bevorzugt: unser SQL-Wrapper
    if LCV and LCV.Characters and LCV.Characters.create then
        LCV.Characters.create(accID, newChar, function(id)
            if not id then
                log("ERROR", ("Charakter konnte nicht gespeichert werden (Account %s)."):format(accID))
                TriggerClientEvent('ox_lib:notify', src, {
                    type = 'error',
                    description = 'Charakter konnte nicht gespeichert werden.',
                })
                TriggerEvent('LCV:charselect:load', src, accID)
                return
            end

            log("INFO", ("Charakter gespeichert via LCV.Characters.create. ID=%s, Account=%s, Name=%s")
                :format(id, accID, newChar.name))

            -- Optional: "new"-Flag entfernen (kompatibel zu deinem alten System)
            if LCV.DB and LCV.DB.update then
                LCV.DB.update('UPDATE accounts SET new = 0 WHERE id = ?', { accID }, function() end)
            elseif exports.oxmysql then
                exports.oxmysql:update('UPDATE accounts SET new = 0 WHERE id = ?', { accID })
            end

            -- Erfolg an Client (falls genutzt)
            TriggerClientEvent('character:SaveSuccess', src, id)

            -- Zurück in die Char-Auswahl
            TriggerEvent('LCV:charselect:load', src, accID)
        end)
        return
    end

    -- Fallback: direkt via oxmysql (falls LCV.Characters noch nicht aktiv)
    if exports.oxmysql then
        local params = {
            accID      = accID,
            name       = newChar.name,
            gender     = newChar.gender,
            country    = newChar.heritage_country,
            birthdate  = newChar.birthdate,
            created    = os.date('%Y-%m-%d %H:%M:%S'),
            appearance = json.encode(newChar.appearance),
            clothes    = json.encode(newChar.clothes),
            past       = newChar.past,
        }

        local query = [[
            INSERT INTO characters (
                account_id,
                name,
                gender,
                heritage_country,
                health,
                thirst,
                food,
                pos_x,
                pos_y,
                pos_z,
                heading,
                dimension,
                created_at,
                level,
                birthdate,
                type,
                is_locked,
                appearance,
                clothes,
                residence_permit,
                past
            ) VALUES (
                :accID,
                :name,
                :gender,
                :country,
                200,
                200,
                200,
                0,
                0,
                0,
                0,
                0,
                :created,
                0,
                :birthdate,
                0,
                0,
                :appearance,
                :clothes,
                0,
                :past
            )
        ]]

        exports.oxmysql:insert(query, params, function(id)
            if not id then
                log("ERROR", ("[Fallback] Charakter konnte nicht gespeichert werden (Account %s)."):format(accID))
                TriggerClientEvent('ox_lib:notify', src, {
                    type = 'error',
                    description = 'Charakter konnte nicht gespeichert werden.',
                })
                TriggerEvent('LCV:charselect:load', src, accID)
                return
            end

            log("INFO", ("[Fallback] Charakter gespeichert. ID=%s, Account=%s, Name=%s")
                :format(id, accID, newChar.name))

            if accID then
                exports.oxmysql:update('UPDATE accounts SET new = 0 WHERE id = ?', { accID })
            end

            TriggerClientEvent('character:SaveSuccess', src, id)
            TriggerEvent('LCV:charselect:load', src, accID)
        end)
    else
        log("ERROR", "Weder LCV.Characters.create noch oxmysql verfügbar. Charakter nicht gespeichert.")
        TriggerClientEvent('ox_lib:notify', src, {
            type = 'error',
            description = 'Serverfehler beim Speichern des Charakters.',
        })
        TriggerEvent('LCV:charselect:load', src, accID)
    end
end)

-- Abbruch im Editor -> einfach zurück zum Charselect (kein Save)
RegisterNetEvent('character:Cancel', function(account_id)
    local src = source
    log("INFO", ("Editor abgebrochen von %s, zurück zum Charselect."):format(src))
    TriggerEvent('LCV:charselect:load', src, account_id)
end)

-- Modell vorbereiten (wird aus dem Editor abgefragt)
RegisterNetEvent('character:AwaitModel', function(characterSex)
    local src = source
    local model = (characterSex == 0) and 'mp_f_freemode_01' or 'mp_m_freemode_01'

    TriggerClientEvent('character:SetModel', src, model)
    TriggerClientEvent('character:FinishSync', src)
end)

-- Live-Sync während der Bearbeitung (Schieberegler etc.)
RegisterNetEvent('character:Sync', function(data, clothes)
    local src = source

    local parsed        = decodeMaybeJSON(data)
    local parsedClothes = decodeMaybeJSON(clothes)

    if not parsed or type(parsed) ~= 'table' then
        log('[WARN]', 'character:Sync: invalid data')
        return
    end

    local model = (parsed.sex == 0) and 'mp_f_freemode_01' or 'mp_m_freemode_01'

    TriggerClientEvent('character:SetModel', src, model)
    TriggerClientEvent('character:Sync', src, parsed, parsedClothes or {})
end)
