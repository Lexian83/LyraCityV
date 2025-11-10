-- resources/houseManager/client/houseManager_client.lua

local houseGarageTriggers = {}

local function safeCoords(pos)
    if not pos then return nil end
    if not pos.x or not pos.y or not pos.z then return nil end
    return vector3(tonumber(pos.x) + 0.0, tonumber(pos.y) + 0.0, tonumber(pos.z) + 0.0)
end

local function doDoorFx()
    -- Kleiner Tür-Sound (anpassbar)
    -- Library-Beispiel, kannst du ersetzen falls Pack fehlt
    PlaySoundFrontend(-1, "DOOR_CLOSE", "MP_PROPERTIES_ELEVATOR_DOORS", false)
end

RegisterNetEvent('LCV:house:client:enter', function(data)
    local pos = safeCoords(data and data.inside)
    if not pos then return end

    local ped = PlayerPedId()

    DoScreenFadeOut(500)
    Wait(600)

    SetEntityCoordsNoOffset(ped, pos.x, pos.y, pos.z, false, false, false)
    doDoorFx()

    Wait(300)
    DoScreenFadeIn(500)
end)

RegisterNetEvent('LCV:house:client:leave', function(data)
    local pos = safeCoords(data and data.entry)
    if not pos then return end

    local ped = PlayerPedId()

    DoScreenFadeOut(500)
    Wait(600)

    SetEntityCoordsNoOffset(ped, pos.x, pos.y, pos.z, false, false, false)
    doDoorFx()

    Wait(300)
    DoScreenFadeIn(500)
end)

RegisterNetEvent('LCV:house:sync', function(list)
    houseGarageTriggers = {}

    if not list then return end

    for _, h in ipairs(list) do
        if h.garage_trigger_x and h.garage_trigger_y and h.garage_trigger_z then
            table.insert(houseGarageTriggers, {
                id = h.id,
                x = tonumber(h.garage_trigger_x) + 0.0,
                y = tonumber(h.garage_trigger_y) + 0.0,
                z = tonumber(h.garage_trigger_z) + 0.0
            })
        end
    end
end)

CreateThread(function()
    Wait(1500)
    TriggerServerEvent('LCV:house:requestSync')
end)

CreateThread(function()
    while true do
        local sleep = 1000
        local ped = PlayerPedId()
        local px, py, pz = table.unpack(GetEntityCoords(ped))

        for _, g in ipairs(houseGarageTriggers) do
            local dist = #(vector3(px, py, pz) - vector3(g.x, g.y, g.z))

            if dist < 30.0 then
                sleep = 0

                -- Gelber Kreis am Boden (Marker Type 1 = flacher Zylinder)
                DrawMarker(
                    1,
                    g.x, g.y, g.z - 0.95,        -- Position (leicht im Boden)
                    0.0, 0.0, 0.0,               -- Dir
                    0.0, 0.0, 0.0,               -- Rot
                    2.0, 2.0, 0.2,               -- Größe X,Y,Z
                    255, 255, 0, 150,            -- Farbe RGBA (gelb, halbtransparent)
                    false, true, 2, false, nil, nil, false
                )
            end
        end

        Wait(sleep)
    end
end)
