-- server.lua

-- Hilfsfunktion: sicheres JSON-Decode (falls UI String sendet)
local function decodeMaybeJSON(data)
    if type(data) == 'string' then
        local ok, parsed = pcall(function() return json.decode(data) end)
        if ok and parsed ~= nil then
            return parsed
        else
            print('[Character Editor] Failed to sync character. Character data format is not object or JSON string.')
            return nil
        end
    end
    return data
end

-- Entspricht: alt.on('character:Edit', handleCharacterEdit)
RegisterNetEvent('character:Edit', function(oldData,accid)
    local src = source
    TriggerClientEvent('character:Edit', src, oldData,accid)
end)

-- Entspricht: alt.onClient('character:Done', handleDone)
RegisterNetEvent('character:Done', function(data,account_id)
local src = source
    -- Speichern und so

if not data or not data.data or not data.identity or not data.clothes then return end

 -- Extrahiere Daten aus den NUI-Objekten
    local d = data.data
    local i = data.identity
    local c = data.clothes

    -- Beispielhafte Felder anpassen an deine DB-Struktur
    local params = {
        ['accID'] = account_id,
        ['name'] = string.format("%s,%s", i.sname, i.fname),
        ['birthdate'] = i.birthdate,
        ['gender']    = d.sex,
        ['country']   = i.country,

        ['clothes']   = json.encode(c),
        ['appearance']  = json.encode(d),

        ['created'] = os.date("%Y-%m-%d %H:%M:%S"),
        ['past'] = i.past,
    }

    local query = [[
        INSERT INTO characters (account_id, name, gender, heritage_country, health, thirst, food, pos_x, pos_y, pos_z,heading,dimension,created_at,level,birthdate,type,is_locked,appearance,clothes, residence_permit, past)
        VALUES (:accID, :name, :gender, :country, 200, 200, 200, 0, 0, 0, 0, 0, :created, 0, :birthdate, 0, 0, :appearance, :clothes, 0, :past)
    ]]
    
    exports.oxmysql:insert(query, params, function(id)
        if id then
            -- print(('[Lyra City V] Charakter gespeichert (ID: %s)'):format(id))
            TriggerClientEvent('character:SaveSuccess', src, id)
        else
            print('[Lyra City V] FEHLER: Charakter konnte nicht gespeichert werden!')
        end
    end)



TriggerEvent('LCV:charselect:load', src, account_id)

-- print(('[Charedit - Server][character:Done] Account ID: %s | data.data.sex: %s | data.identity.fname: %s'):format(account_id, data.data.sex,data.identity.fname))

end)

-- Entspricht: alt.onClient('character:AwaitModel', handleAwaitModel)
RegisterNetEvent('character:AwaitModel', function(characterSex)
    local src = source
    -- In alt:V: player.model = (sex===0 ? mp_f : mp_m) + emitClient FinishSync
    -- Empfehlung in FiveM: Modell clientseitig setzen (streaming-sicher)
    local model = (characterSex == 0) and 'mp_f_freemode_01' or 'mp_m_freemode_01'
    TriggerClientEvent('character:SetModel', src, model)
    TriggerClientEvent('character:FinishSync', src)
end)

-- Entspricht: alt.on('character:Sync', handleCharacterSync)
RegisterNetEvent('character:Sync', function(data,clothes)
      -- print('SERVER:character:Sync ')
    local src = source
    local parsed = decodeMaybeJSON(data)
    local parsedClothes = decodeMaybeJSON(clothes)
    if not parsed then return end

    -- alt:V-Logik: sex === 0 -> female, sonst male
    local model = (parsed.sex == 0) and 'mp_f_freemode_01' or 'mp_m_freemode_01'

    -- In alt:V wurde direkt player.model gesetzt; hier setzen wir das Modell clientseitig:
    TriggerClientEvent('character:SetModel', src, model)
    -- print('SERVER:character:Sync:TriggerClient:character:SetModel ')

    -- In alt:V: alt.emitClient(player, 'character:Sync', data)
    TriggerClientEvent('character:Sync', src, parsed,clothes)
    -- print('SERVER:character:Sync:TriggerClient:character:Sync ')
end)
