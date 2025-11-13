-- resources/houseManager/client/houseManager_client.lua

local houseGarageTriggers = {}  -- gelbe Trigger-Markierungen (bestehend)
local houseGarageSpawns   = {}  -- ORANGE Ein-/Ausparkpunkte (NEU)

-- Farben/Konstanten
local COLOR_YELLOW = { r = 255, g = 255, b = 0,   a = 150 }
local COLOR_ORANGE = { r = 255, g = 128, b = 0,   a = 170 }
local DRAW_DIST_TRIGGER = 30.0
local DRAW_DIST_SPAWN   = 50.0   -- ⬅️ mehr Sichtweite

local function groundZ(x, y, z)
    -- Holt GroundZ; wenn nicht gefunden, nimm gegebenes z
    local found, gz = GetGroundZFor_3dCoord(x + 0.0, y + 0.0, (z or 1000.0) + 0.0, 0)
    if found and gz and gz > -1000.0 then
        return gz
    end
    return z or 0.0
end

local function safeCoords(pos)
    if not pos or type(pos) ~= "table" then return nil end
    if not pos.x or not pos.y or not pos.z then return nil end
    return vector3(tonumber(pos.x) + 0.0, tonumber(pos.y) + 0.0, tonumber(pos.z) + 0.0)
end
local function jdec(s, d)
    if not s then return d end
    if type(s) == "table" then return s end
    local ok, res = pcall(function() return json.decode(s) end)
    return ok and res or d
end

local function doDoorFx()
    -- Türsound; falls es nervt oder kein Soundset existiert, auskommentieren.
    PlaySoundFrontend(-1, "DOOR_CLOSE", "MP_PROPERTIES_ELEVATOR_DOORS", false)
end

CreateThread(function()
    Wait(500)
    print("[HouseManager][CLIENT] houseManager_client.lua geladen (mit ORANGE Spawn-Markern).")
end)

-- =========================
-- SYNC: Triggers & Spawns
-- =========================

RegisterNetEvent('LCV:house:sync', function(list)
    houseGarageTriggers = {}
    houseGarageSpawns   = {}

    if not list then
        print("[HouseManager][CLIENT] Sync erhalten, aber Liste ist nil.")
        return
    end

    print(("[HouseManager][CLIENT] Sync erhalten, Elemente: %d"):format(#list))

    for _, h in ipairs(list) do
        local id = tonumber(h.id)

        -- Trigger-Marker wie gehabt (gelb)
        local gx = tonumber(h.garage_trigger_x)
        local gy = tonumber(h.garage_trigger_y)
        local gz = tonumber(h.garage_trigger_z)
        if id and gx and gy and gz then
            local rad = tonumber(h.radius) or 0.5
            houseGarageTriggers[#houseGarageTriggers + 1] = {
                id = id, x = gx, y = gy, z = gz, radius = rad
            }
        end

       -- NEU: Ein-/Ausparkpunkte aus garage_spawns (orange)
local spawnsRaw = h.garage_spawns
local spawns = jdec(spawnsRaw, {})  -- ← decodiert auch Strings zu Tabellen
if type(spawns) == "table" then
    for _, s in ipairs(spawns) do
        local sx = tonumber(s.x)
        local sy = tonumber(s.y)
        local sz = tonumber(s.z)
        if sx and sy and sz then
            houseGarageSpawns[#houseGarageSpawns + 1] = {
                houseId = id,
                sid     = tonumber(s.sid) or 0,
                x       = sx, y = sy, z = sz,
                heading = tonumber(s.heading) or 0.0,
                radius  = tonumber(s.radius) or 3.0,
                stype   = tostring(s.type or "both")
            }
        end
    end
end

    end
if #houseGarageSpawns > 0 then
    local s0 = houseGarageSpawns[1]
    print(("[HouseManager][CLIENT] First spawn: (#%s) x=%.2f y=%.2f z=%.2f r=%.1f")
        :format(tostring(s0.sid), s0.x, s0.y, s0.z, s0.radius))
end

    print(("[HouseManager][CLIENT] Garage Trigger: %d | Garage Spawns: %d"):format(#houseGarageTriggers, #houseGarageSpawns))
end)

-- Beim Client-Start einmal Daten holen
CreateThread(function()
    Wait(2000)
    TriggerServerEvent('LCV:house:requestSync')
end)

-- =========================
-- Marker zeichnen
-- =========================

CreateThread(function()
    while true do
        local sleep = 1000
        local ped = PlayerPedId()
        local pcoords = GetEntityCoords(ped)

        -- Trigger (gelb, wie zuvor)
        if #houseGarageTriggers > 0 then
            for _, g in ipairs(houseGarageTriggers) do
                local dist = #(pcoords - vector3(g.x, g.y, g.z))
                if dist < DRAW_DIST_TRIGGER then
                    sleep = 0
                    DrawMarker(
                        1,
                        g.x, g.y, g.z - 0.95,    -- leicht in den Boden
                        0.0, 0.0, 0.0,
                        0.0, 0.0, 0.0,
                        g.radius, g.radius, 0.2,
                        COLOR_YELLOW.r, COLOR_YELLOW.g, COLOR_YELLOW.b, COLOR_YELLOW.a,
                        false, true, 2, false, nil, nil, false
                    )
                end
            end
        end

        -- Ein-/Ausparkpunkte (ORANGE)
if #houseGarageSpawns > 0 then
    for _, s in ipairs(houseGarageSpawns) do
        local dist = #(pcoords - vector3(s.x, s.y, s.z))
        if dist < DRAW_DIST_SPAWN then
            sleep = 0
            local gz = groundZ(s.x, s.y, s.z)
            local drawZ = (gz or s.z) + 0.05

            -- gut sichtbarer Zylinder knapp über Boden
            DrawMarker(
                1,
                s.x, s.y, drawZ - 0.95,
                0.0, 0.0, 0.0,
                0.0, 0.0, 0.0,
                s.radius, s.radius, 0.35,
                COLOR_ORANGE.r, COLOR_ORANGE.g, COLOR_ORANGE.b, COLOR_ORANGE.a,
                false, true, 2, false, nil, nil, false
            )

            -- optionaler „Punkt“-Marker direkt auf GroundZ für extra Sichtbarkeit
            DrawMarker(
                2,                      -- Type 2: Checker/Locator
                s.x, s.y, drawZ + 0.05,
                0.0, 0.0, 0.0,
                0.0, 0.0, 0.0,
                0.25, 0.25, 0.25,
                COLOR_ORANGE.r, COLOR_ORANGE.g, COLOR_ORANGE.b, 200,
                false, true, 2, false, nil, nil, false
            )
        end
    end
end


        Wait(sleep)
    end
end)

-- =========================
-- ENTER / LEAVE
-- =========================

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
