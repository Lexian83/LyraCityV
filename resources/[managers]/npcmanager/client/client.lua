-- npcmanager/client.lua
-- Static NPC Spawner für LyraCityV
-- - Kein HUD
-- - Keine Marker
-- - Keine Keybinds
-- - Saubere Positionierung
-- - Export: GetNPCPositions() für interactionmanager/Admin-UI

local spawned = {}   -- [id] = { ped=ped, data=data, coords={x,y,z} }
local targets = {}   -- für Interaktion/Admin, aus spawned gebaut
local selIndex = 1   -- bleibt für spätere Admin-Nutzung

-- ============ Utils ============

local function joa(m)
    if type(m) == "string" then
        return joaat(m)
    end
    return m
end

local function loadModel(m)
    m = joa(m)
    RequestModel(m)
    while not HasModelLoaded(m) do
        Wait(0)
    end
    return m
end

local function makePedPassive(p)
    SetEntityInvincible(p, true)
    SetBlockingOfNonTemporaryEvents(p, true)
    SetPedFleeAttributes(p, 0, false)
    SetPedCombatAttributes(p, 46, true)
    SetPedCanRagdoll(p, false)
end

local function deleteOne(id)
    local e = spawned[id]
    if e and e.ped and DoesEntityExist(e.ped) then
        ClearPedTasksImmediately(e.ped)
        DeleteEntity(e.ped)
    end
    spawned[id] = nil
end

local function clearAll()
    for id in pairs(spawned) do
        deleteOne(id)
    end
end

-- Entfernt alte Dubletten an Zielposition (Model + Nähe)
local function cleanupExistingAt(data)
    if not data or not data.coords or not data.model then return end

    local modelHash = joa(data.model)
    local x = data.coords.x + 0.0
    local y = data.coords.y + 0.0
    local z = (data.coords.z or 0.0) + 0.0
    local center = vector3(x, y, z)
    local radius = 2.0

    local handle, ped = FindFirstPed()
    if handle == -1 then return end

    local success = true
    while success do
        if DoesEntityExist(ped)
            and not IsPedAPlayer(ped)
            and GetEntityModel(ped) == modelHash
        then
            local px, py, pz = table.unpack(GetEntityCoords(ped))
            if #(vector3(px, py, pz) - center) <= radius then
                DeleteEntity(ped)
            end
        end
        success, ped = FindNextPed(handle)
    end

    EndFindPed(handle)
end

-- ============ Spawn ============

local function spawnOne(id, data)
    if not data or not data.coords or not data.model then return end

    -- Dubletten an der Stelle mit gleichem Model wegräumen
    cleanupExistingAt(data)

    -- alten Eintrag (falls vorhanden) löschen
    deleteOne(id)

    local x = data.coords.x + 0.0
    local y = data.coords.y + 0.0
    local baseZ = (data.coords.z or 0.0) + 0.0
    local heading = tonumber(data.heading or data.coords.w or 0.0) or 0.0

    local zOffset      = tonumber(data.zOffset) or 0.0
    local groundOffset = tonumber(data.groundOffset) or 0.0
    local autoGround   = data.autoGround == true

    -- Model laden
    local model = loadModel(data.model)
    if not model then
        print(("[NPC] #%s invalid model '%s'"):format(tostring(id), tostring(data.model)))
        return
    end

    -- Standard: wir gehen davon aus, dass die gespeicherte Z-Höhe vom Spieler kommt
    -- und ziehen den Ped etwas nach unten (ca. Fußhöhe).
    local spawnZ = baseZ - 1.0 + zOffset

    -- Wenn AutoGround aktiv ist, versuchen wir echten Boden zu finden.
    if autoGround then
        local found, groundZ = GetGroundZFor_3dCoord(x, y, baseZ + 50.0, false)
        if found and groundZ then
            -- klassisch auf Boden + Offset
            spawnZ = groundZ + groundOffset
        else
            -- kein Ground gefunden (typisch bei MLOs) -> Fallback:
            -- nutze weiterhin gespeicherte Position, aber korrigiert um -1.0 + zOffset
            spawnZ = baseZ - 1.0 + zOffset
        end
    end

    local ped = CreatePed(4, model, x, y, spawnZ, heading, false, false)
    if not ped or ped == 0 then
        print(("[NPC] #%s CreatePed failed"):format(tostring(id)))
        SetModelAsNoLongerNeeded(model)
        return
    end

    SetEntityAsMissionEntity(ped, true, false)
    SetEntityCollision(ped, true, true)
    SetEntityHeading(ped, heading)
    makePedPassive(ped)

    if data.scenario and data.scenario ~= "" then
        -- Scenario laufen lassen; NICHT hart zurück-snappen,
        -- damit Sitz-/Tresen-Scenarios normal funktionieren.
        TaskStartScenarioInPlace(ped, data.scenario, 0, true)
    end

    FreezeEntityPosition(ped, true)
    SetModelAsNoLongerNeeded(model)

    local px, py, pz = table.unpack(GetEntityCoords(ped))
    spawned[id] = {
        ped = ped,
        data = data,
        coords = { x = px, y = py, z = pz }
    }
end


-- Baut die Liste für Interaktionen/Admin auf Basis der finalen Ped-Position
local function rebuildTargets()
    targets = {}
    for id, e in pairs(spawned) do
        local d = e.data or {}
        local c = e.coords or d.coords
        if c then
            targets[#targets + 1] = {
                id = tostring(id),
                name = d.name or ("NPC " .. tostring(id)),
                coords = vector3(c.x, c.y, c.z),
                type = d.interactionType or (d.interactable and "interactive" or "static")
            }
        end
    end
    if selIndex < 1 then selIndex = 1 end
    if selIndex > #targets then selIndex = #targets end
end

-- Entfernt Fremd-/Doppel-Peds in Nähe unserer Spots, die nicht in spawned stehen
local function cleanupStrays()
    local handle, ped = FindFirstPed()
    if handle == -1 then return end

    local success = true
    while success do
        if DoesEntityExist(ped) and not IsPedAPlayer(ped) then
            local isOwned = false
            local px, py, pz = table.unpack(GetEntityCoords(ped))
            local pos = vector3(px, py, pz)

            -- Gehört der Ped zu unseren?
            for _, e in pairs(spawned) do
                if e.ped == ped then
                    isOwned = true
                    break
                end
            end

            if not isOwned then
                -- Steht er nah an einem unserer NPC-Spots? -> weg.
                for _, e in pairs(spawned) do
                    local d = e.data or {}
                    local c = e.coords or d.coords
                    if c and #(pos - vector3(c.x, c.y, c.z)) <= 2.0 then
                        DeleteEntity(ped)
                        break
                    end
                end
            end
        end

        success, ped = FindNextPed(handle)
    end

    EndFindPed(handle)
end

-- ============ Events vom Server ============

RegisterNetEvent("lcv:npc:client:load", function(payload)
    clearAll()

    if type(payload) == "table" and payload.list and type(payload.list) == "table" then
        for _, row in ipairs(payload.list) do
            spawnOne(row.id or tostring(_), row)
        end
    elseif type(payload) == "table" then
        for id, row in pairs(payload) do
            spawnOne(id, row)
        end
    end

    rebuildTargets()

    -- Kurze Verzögerung, dann Strays killen (alte Network-Peds / Map-Dubletten)
    CreateThread(function()
        Wait(2000)
        cleanupStrays()
        rebuildTargets()
    end)
end)

RegisterNetEvent("lcv:npc:client:spawnOne", function(id, data)
    spawnOne(id, data)
    rebuildTargets()
end)

RegisterNetEvent("lcv:npc:spawnOne", function(id, data)
    spawnOne(id, data)
    rebuildTargets()
end)

RegisterNetEvent("lcv:npc:client:deleteOne", function(id)
    deleteOne(id)
    rebuildTargets()
end)

RegisterNetEvent("lcv:npc:deleteOne", function(id)
    deleteOne(id)
    rebuildTargets()
end)

RegisterNetEvent("lcv:npc:client:clearAll", function()
    clearAll()
    rebuildTargets()
end)

RegisterNetEvent("lcv:npc:clearAll", function()
    clearAll()
    rebuildTargets()
end)

-- ============ Client → Server: Daten anfordern ============

local function requestAll()
    TriggerServerEvent("lcv:npc:server:requestAll")
end

AddEventHandler("onClientResourceStart", function(res)
    if res == GetCurrentResourceName() then
        requestAll()
    end
end)

AddEventHandler("playerSpawned", function()
    if next(spawned) == nil then
        requestAll()
    end
end)

-- ============ Export für interactionmanager/Admin-HUD ============

exports("GetNPCPositions", function()
    return targets or {}
end)
