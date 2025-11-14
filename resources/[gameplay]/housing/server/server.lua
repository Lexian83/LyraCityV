-- resources/housing/server.lua

local json = json

-- Hilfsfunktion, um House-Exports zu holen (houseManager / lcv-housemanager)
local function getHouseExports()
    if GetResourceState('houseManager') == 'started' then
        return exports['houseManager']
    elseif GetResourceState('lcv-housemanager') == 'started' then
        return exports['lcv-housemanager']
    end
    return nil
end

local function safeEncodeDebug(v)
    local ok, res = pcall(function() return json.encode(v) end)
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
        -- könnte entweder "20" oder '{"houseid":20}' sein
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
        -- 1) direkt: payload.houseid / payload.houseId
        if payload.houseid or payload.houseId then
            return tonumber(payload.houseid or payload.houseId)
        end

        -- 2) klassisch: payload.data = {...} oder payload.data = '{"houseid":20}'
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

    local houseName  = nil
    local ownerStatus = nil

    if houseId then
        local hm = getHouseExports()
        if hm and hm.GetById then
            local ok, row = pcall(function()
                return hm:GetById(houseId)   -- liefert normalisiertes Haus inkl. row.status
            end)

            if ok and row then
                houseName = row.name or ('Haus #' .. tostring(houseId))

                -- Status aus SSOT übernehmen: "frei" / "verkauft" / "vermietet"
                -- falls aus irgendeinem Grund nicht gesetzt, leiten wir aus ownerid ab
                local st = row.status
                if not st or st == '' then
                    local hasOwner = row.ownerid and row.ownerid > 0
                    if not hasOwner then
                        st = 'frei'
                    else
                        st = 'verkauft'
                    end
                end
                ownerStatus = st

                print(('[HOUSING][SERVER] Loaded house #%d name="%s" status="%s"')
                    :format(houseId, tostring(houseName), tostring(ownerStatus)))
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
    })
end)
