-- resources/housing/server.lua

local json = json

local function getHouseExports()
    if GetResourceState('houseManager') == 'started' then
        return exports['houseManager']
    elseif GetResourceState('lcv-housemanager') == 'started' then
        return exports['lcv-housemanager']
    end
    return nil
end

local function parseHouseIdFromPayload(payload)
    if not payload then return nil end

    -- Erwartet: payload.data = '{"houseid":20}' ODER payload.data = { houseid = 20 }
    local raw = payload.data

    if type(raw) == 'table' then
        return tonumber(raw.houseid)
    elseif type(raw) == 'string' then
        local ok, decoded = pcall(json.decode, raw)
        if ok and type(decoded) == 'table' then
            return tonumber(decoded.houseid)
        end
    end

    return nil
end

RegisterNetEvent('LCV:Housing:Server:Show', function(payload)
    local src = source
    print('[HOUSING][SERVER] Show Housing UI request')

    local houseId = parseHouseIdFromPayload(payload)
    local houseName = nil

    if houseId then
        local hm = getHouseExports()
        if hm and hm.GetById then
            local ok, row = pcall(function()
                return hm:GetById(houseId)
            end)

            if ok and row then
                houseName = row.name or ('Haus #' .. tostring(houseId))
            else
                print('[HOUSING][SERVER] Fehler bei houseManager:GetById für id '..tostring(houseId))
            end
        else
            print('[HOUSING][SERVER] houseManager.GetById Export nicht verfügbar')
        end
    end

    TriggerClientEvent('LCV:Housing:Client:Show', src, {
        houseId   = houseId,
        houseName = houseName
    })
end)
