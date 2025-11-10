-- LCV Character Editor - Server

-- Hilfsfunktion: sicheres JSON-Decode
local function decodeMaybeJSON(data)
    if type(data) == 'string' then
        local ok, parsed = pcall(function()
            return json.decode(data)
        end)

        if ok and parsed ~= nil then
            return parsed
        else
            print('[Character Editor] Failed to decode JSON.')
            return nil
        end
    end

    return data
end

-- Öffnet den Editor mit optionalen bestehenden Daten
RegisterNetEvent('character:Edit', function(oldData, accId)
    local src = source

    if type(oldData) == 'string' then
        oldData = decodeMaybeJSON(oldData) or {}
    elseif type(oldData) ~= 'table' then
        oldData = {}
    end

    TriggerClientEvent('character:Edit', src, oldData, accId)
end)

-- Charakter wurde im Editor abgeschlossen -> speichern & zurück ins Charselect
RegisterNetEvent('character:Done', function(data, account_id)
    local src = source

    if not account_id then
        print(('[Character Editor] character:Done ohne account_id von %s'):format(src))
        return
    end

    -- Data ggf. decoden
    data = decodeMaybeJSON(data) or data

    if type(data) ~= 'table'
        or not data.data
        or not data.identity
        or not data.clothes
    then
        print('[Character Editor] Invalid data in character:Done (missing blocks).')
        return
    end

    local d = data.data
    local i = data.identity
    local c = data.clothes

    -- Fallbacks, damit der Insert nie an NULL/NOT NULL crasht
    local accID     = tonumber(account_id)
    local fname     = i.fname or ''
    local sname     = i.sname or ''
    local fullName  = (sname ~= '' or fname ~= '')
        and (('%s,%s'):format(sname, fname))
        or 'Unbekannt,Unbekannt'

    local birthdate = i.birthdate or '2000-01-01'
    local gender    = d.sex or 0
    local country   = i.country or ''
    local past      = i.past or 0

    local params = {
        accID      = accID,
        name       = fullName,
        gender     = gender,
        country    = country,
        birthdate  = birthdate,
        created    = os.date('%Y-%m-%d %H:%M:%S'),
        appearance = json.encode(d),
        clothes    = json.encode(c),
        past       = past,
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
            print(('[LyraCityV][Character Editor] FEHLER: Charakter konnte nicht gespeichert werden (Account %s).')
                :format(tostring(accID)))
            TriggerClientEvent('ox_lib:notify', src, {
                type = 'error',
                description = 'Charakter konnte nicht gespeichert werden.',
            })
            return
        end

        print(('[LyraCityV][Character Editor] Charakter gespeichert. ID=%s, Account=%s, Name=%s')
            :format(id, tostring(accID), params.name))

        -- Optional: Account als "nicht mehr neu" markieren
        if accID then
            exports.oxmysql:update('UPDATE accounts SET new = 0 WHERE id = ?', { accID })
        end

        -- Erfolg zurück an Client (falls du das im UI nutzt)
        TriggerClientEvent('character:SaveSuccess', src, id)

        -- Direkt zurück ins Char-Select:
        -- Wichtig: Das ist ein SERVER-Event, das in deiner Charselect-Resource
        -- den Payload baut und dann das UI beim Spieler öffnet.
        TriggerEvent('LCV:charselect:load', src, accID)
    end)
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

    local parsed       = decodeMaybeJSON(data)
    local parsedClothes = decodeMaybeJSON(clothes)

    if not parsed or type(parsed) ~= 'table' then
        print('[Character Editor] character:Sync: invalid data')
        return
    end

    local model = (parsed.sex == 0) and 'mp_f_freemode_01' or 'mp_m_freemode_01'

    TriggerClientEvent('character:SetModel', src, model)
    TriggerClientEvent('character:Sync', src, parsed, parsedClothes or {})
end)
