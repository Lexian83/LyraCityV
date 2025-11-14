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

local function safeEncodeDebug(v)
    local ok, res = pcall(function()
        return json.encode(v)
    end)
    if ok then return res end
    return '<encode failed>'
end

local function parseHouseIdFromPayload(payload)
    if not payload then return nil end

    -- Direkt: nur die ID als Zahl/String
    if type(payload) == 'number' then
        return payload
    end

    if type(payload) == 'string' then
        local n = tonumber(payload)
        if n then return n end

        local ok, decoded = pcall(json.decode, payload)
        if ok and type(decoded) == 'table' then
            if decoded.houseid or decoded.houseId then
                return tonumber(decoded.houseid or decoded.houseId)
            end
        end
        return nil
    end

    -- Table-Varianten
    if type(payload) == 'table' then
        if payload.houseid or payload.houseId then
            return tonumber(payload.houseid or payload.houseId)
        end

        local raw = payload.data
        if raw ~= nil then
            if type(raw) == 'number' then
                return raw
            elseif type(raw) == 'string' then
                local n = tonumber(raw)
                if n then return n end
                local ok, decoded = pcall(json.decode, raw)
                if ok and type(decoded) == 'table' then
                    if decoded.houseid or decoded.houseId then
                        return tonumber(decoded.houseid or decoded.houseId)
                    end
                end
            elseif type(raw) == 'table' then
                if raw.houseid or raw.houseId then
                    return tonumber(raw.houseid or raw.houseId)
                end
            end
        end
    end

    return nil
end

RegisterNetEvent('LCV:Housing:Server:Show', function(payload)
    local src = source
    print('[HOUSING][SERVER] Show Housing UI request')
    print('[HOUSING][SERVER] Payload Debug: ' .. safeEncodeDebug(payload))

    local houseId = parseHouseIdFromPayload(payload)
    print('[HOUSING][SERVER] Parsed houseId = ' .. tostring(houseId))

    local houseName   = nil
    local ownerStatus = nil
    local lockState   = 0

    if houseId then
        local hm = getHouseExports()
        if hm and hm.GetById then
            local ok, row = pcall(function()
                return hm:GetById(houseId)
            end)

            if ok and row then
                houseName   = row.name or ('Haus #' .. tostring(houseId))
                ownerStatus = row.status  -- "frei" / "verkauft" / "vermietet"

                -- robustes Lock-State-Mapping (TinyInt, Bool, String)
                local rawLock = row.lock_state
                if rawLock == nil then
                    lockState = 0
                elseif rawLock == true then
                    lockState = 1
                elseif rawLock == false then
                    lockState = 0
                else
                    lockState = tonumber(rawLock) or 0
                end

                print(('[HOUSING][SERVER] Loaded house #%d name="%s" status="%s" lock_state=%d')
                    :format(houseId, tostring(houseName), tostring(ownerStatus), lockState))
            else
                print('[HOUSING][SERVER] Fehler bei houseManager:GetById für id ' .. tostring(houseId))
            end
        else
            print('[HOUSING][SERVER] houseManager.GetById Export nicht verfügbar')
        end
    else
        print('[HOUSING][SERVER] Konnte houseId aus Payload NICHT lesen.')
    end

    TriggerClientEvent('LCV:Housing:Client:Show', src, {
        houseId     = houseId,
        houseName   = houseName,
        ownerStatus = ownerStatus,
        lockState   = lockState,
    })
end)
