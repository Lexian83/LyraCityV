-- resources/houseManager/client/houseManager_client.lua

local houseGarageTriggers = {}

local function safeCoords(pos)
    if not pos then return nil end
    if not pos.x or not pos.y or not pos.z then return nil end
    return vector3(tonumber(pos.x) + 0.0, tonumber(pos.y) + 0.0, tonumber(pos.z) + 0.0)
end

local function doDoorFx()
    -- Wenn das Soundset nicht existiert, kannst du die Zeile auskommentieren.
    PlaySoundFrontend(-1, "DOOR_CLOSE", "MP_PROPERTIES_ELEVATOR_DOORS", false)
end

-- =========================================================
-- DEBUG: Loaded
-- =========================================================
CreateThread(function()
    Wait(500)
    print("[HouseManager][CLIENT] houseManager_client.lua geladen.")
end)

-- =========================================================
-- SYNC: Garage Trigger Marker
-- =========================================================

RegisterNetEvent('LCV:house:sync', function(list)
    houseGarageTriggers = {}

    if not list then
        print("[HouseManager][CLIENT] Sync erhalten, aber Liste ist nil.")
        return
    end

    print(("[HouseManager][CLIENT] Sync erhalten, Elemente: %d"):format(#list))

    for _, h in ipairs(list) do
        local id = tonumber(h.id)
        local gx = tonumber(h.garage_trigger_x)
        local gy = tonumber(h.garage_trigger_y)
        local gz = tonumber(h.garage_trigger_z)

        if id and gx and gy and gz then
    local rad = tonumber(h.radius) or 1.5  -- Fallback falls NULL
    houseGarageTriggers[#houseGarageTriggers + 1] = {
        id = id,
        x = gx,
        y = gy,
        z = gz,
        radius = rad
    }
end

    end

    print(("[HouseManager][CLIENT] Garage Trigger geladen: %d"):format(#houseGarageTriggers))
end)

-- Beim Client-Start einmal anfragen
CreateThread(function()
    Wait(2000)
    TriggerServerEvent('LCV:house:requestSync')
end)

-- Marker zeichnen
CreateThread(function()
    while true do
        local sleep = 1000

        if #houseGarageTriggers > 0 then
            local ped = PlayerPedId()
            local px, py, pz = table.unpack(GetEntityCoords(ped))

            for _, g in ipairs(houseGarageTriggers) do
                local dist = #(vector3(px, py, pz) - vector3(g.x, g.y, g.z))

                if dist < 30.0 then
                    sleep = 0

                    DrawMarker(
    1,
    g.x, g.y, g.z - 0.95,
    0.0, 0.0, 0.0,
    0.0, 0.0, 0.0,
    g.radius, g.radius, 0.2,  -- Radius aus DB
    255, 255, 0, 150,
    false, true, 2, false, nil, nil, false
)

                end
            end
        end

        Wait(sleep)
    end
end)

-- =========================================================
-- HOUSE ENTER / LEAVE
-- =========================================================

RegisterNetEvent('LCV:house:client:enter', function(data)
    if not data then return end
    local pos = safeCoords(data.inside)
    if not pos then
        print("[HouseManager][CLIENT] ENTER ohne gültige inside-Coords.")
        return
    end

    local ped = PlayerPedId()

    if data.interiorIpl and data.interiorIpl ~= "" then
        RequestIpl(data.interiorIpl)
    end

    DoScreenFadeOut(500)
    Wait(600)

    SetEntityCoordsNoOffset(ped, pos.x, pos.y, pos.z, false, false, false)
    doDoorFx()

    Wait(300)
    DoScreenFadeIn(500)
end)

RegisterNetEvent('LCV:house:client:leave', function(data)
    if not data then return end
    local pos = safeCoords(data.entry)
    if not pos then
        print("[HouseManager][CLIENT] LEAVE ohne gültige entry-Coords.")
        return
    end

    local ped = PlayerPedId()

    DoScreenFadeOut(500)
    Wait(600)

    if data.interiorIpl and data.interiorIpl ~= "" then
        RemoveIpl(data.interiorIpl)
    end

    SetEntityCoordsNoOffset(ped, pos.x, pos.y, pos.z, false, false, false)
    doDoorFx()

    Wait(300)
    DoScreenFadeIn(500)
end)
