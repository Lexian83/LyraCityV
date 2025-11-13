local isADMINOpen = false

-- Movement filter while UI open
CreateThread(function()
    while true do
        if isADMINOpen then
            DisableControlAction(0, 24, true)
            DisableControlAction(0, 25, true)
            DisableControlAction(0, 45, true)
            DisableControlAction(0, 140, true)
            DisableControlAction(0, 141, true)
            DisableControlAction(0, 142, true)
            DisableControlAction(0, 257, true)
            DisableControlAction(0, 263, true)
        end
        Wait(0)
    end
end)

local function openADMIN(data)
    SendNUIMessage({ action = "openADMIN" })
exports.inputmanager:LCV_OpenUI('ADMINSYSTEM', { nui = true, keepInput = false })
    CreateThread(function()
        Wait(150)
        SetNuiFocus(true, true)
        SetNuiFocusKeepInput(false)
    end)
end

local function closeADMIN()
    SendNUIMessage({ action = "closeADMIN" })
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    exports.inputmanager:LCV_CloseUI('ADMINSYSTEM')
end

RegisterNetEvent('LCV:ADMIN:Client:Show', function(data)
    if isADMINOpen then return end
    isADMINOpen = true
    openADMIN(data)
end)

RegisterNetEvent('LCV:ADMIN:Client:Hide', function()
    if not isADMINOpen then return end
    isADMINOpen = false
    closeADMIN()
end)

-- NUI: Close Button
RegisterNUICallback('LCV:ADMIN:Hide', function(_, cb)
    if not isADMINOpen then
        cb({ ok = true })
        return
    end

    isADMINOpen = false
    closeADMIN()
    cb({ ok = true })
end)

-- ========= NUI <-> SERVER BRIDGES FÜR INTERACTIONS =========

-- GetAll (Tabelle)
RegisterNUICallback('LCV:ADMIN:Interactions:GetAll', function(_, cb)
    lib.callback('LCV:ADMIN:Interactions:GetAll', false, function(result)
        cb(result or { ok = false, error = 'no_response', interactions = {} })
    end)
end)

-- Add (Form)
RegisterNUICallback('LCV:ADMIN:Interactions:Add', function(data, cb)
    lib.callback('LCV:ADMIN:Interactions:Add', false, function(result)
        cb(result or { ok = false, error = 'no_response' })
    end, data)
end)

-- Update (Edit)
RegisterNUICallback('LCV:ADMIN:Interactions:Update', function(data, cb)
    lib.callback('LCV:ADMIN:Interactions:Update', false, function(result)
        cb(result or { ok = false, error = 'no_response' })
    end, data)
end)

-- Delete (mit NUI-Bestätigung)
RegisterNUICallback('LCV:ADMIN:Interactions:Delete', function(data, cb)
    if not data or not data.id then
        cb({ ok = false, error = 'missing_id' })
        return
    end

    lib.callback('LCV:ADMIN:Interactions:Delete', false, function(result)
        cb(result or { ok = false, error = 'no_response' })
    end, data)
end)

-- Spielerposition fürs Add-Formular
RegisterNUICallback('LCV:ADMIN:Interactions:GetPlayerPos', function(_, cb)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    cb({
        ok = true,
        x = coords.x + 0.0,
        y = coords.y + 0.0,
        z = coords.z + 0.0
    })
end)
-- NPCs: Spielerposition für NUI (Add & Edit) - OHNE Boden-Offset
RegisterNUICallback('LCV:ADMIN:Npcs:GetPlayerPos', function(_, cb)
    local ped = PlayerPedId()
    if not ped or ped == 0 or not DoesEntityExist(ped) then
        cb({ ok = false, error = 'no_ped' })
        return
    end

    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped) or 0.0

    cb({
        ok = true,
        x = coords.x + 0.0,
        y = coords.y + 0.0,
        z = coords.z + 0.0,
        heading = heading + 0.0
    })
end)

-- NPCs: GetAll
RegisterNUICallback('LCV:ADMIN:Npcs:GetAll', function(_, cb)
    lib.callback('LCV:ADMIN:Npcs:GetAll', false, function(result)
        cb(result or { ok = false, error = 'no_response', npcs = {} })
    end)
end)

-- NPCs: Add
RegisterNUICallback('LCV:ADMIN:Npcs:Add', function(data, cb)
    lib.callback('LCV:ADMIN:Npcs:Add', false, function(result)
        cb(result or { ok = false, error = 'no_response' })
    end, data)
end)

-- NPCs: Update
RegisterNUICallback('LCV:ADMIN:Npcs:Update', function(data, cb)
    lib.callback('LCV:ADMIN:Npcs:Update', false, function(result)
        cb(result or { ok = false, error = 'no_response' })
    end, data)
end)

-- NPCs: Delete
RegisterNUICallback('LCV:ADMIN:Npcs:Delete', function(data, cb)
    if not data or not data.id then
        cb({ ok = false, error = 'missing_id' })
        return
    end

    lib.callback('LCV:ADMIN:Npcs:Delete', false, function(result)
        cb(result or { ok = false, error = 'no_response' })
    end, data)
end)

-- NPCs: Teleport (mit kleinem Fade)
RegisterNUICallback('LCV:ADMIN:Npcs:Teleport', function(data, cb)
    if not data or not data.x or not data.y or not data.z then
        cb({ ok = false, error = 'bad_coords' })
        return
    end

    CreateThread(function()
        if not IsScreenFadedOut() and not IsScreenFadingOut() then
            DoScreenFadeOut(250)
            Wait(260)
        end

        TriggerServerEvent('LCV:ADMIN:Npcs:Teleport', data.id, data.x, data.y, data.z)

        Wait(200)
        DoScreenFadeIn(250)
    end)

    cb({ ok = true })
end)

-- Teleport-Anfrage aus NUI
RegisterNUICallback('LCV:ADMIN:Interactions:Teleport', function(data, cb)
    if not data or not data.x or not data.y or not data.z then
        cb({ ok = false, error = 'bad_coords' })
        return
    end

    CreateThread(function()
        if not IsScreenFadedOut() and not IsScreenFadingOut() then
            DoScreenFadeOut(250)
            Wait(260)
        end

        TriggerServerEvent('LCV:ADMIN:Interactions:Teleport', data.id, data.x, data.y, data.z)

        Wait(200)
        DoScreenFadeIn(250)
    end)

    cb({ ok = true })
end)

-- Teleport-Toast
RegisterNetEvent('LCV:ADMIN:Interactions:NotifyTeleport', function(coords)
    local text = ("Du wurdest teleportiert zu [%.2f, %.2f, %.2f]"):format(coords.x, coords.y, coords.z)
    lib.notify({
        title = 'Teleport erfolgreich',
        description = text,
        type = 'success',
        position = 'center-right',
        duration = 4000
    })
    PlaySoundFrontend(-1, 'SELECT', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
end)

-- ===== Quick Admin Toggles =====

local noclipEnabled = false
local godmodeEnabled = false
local invisibleEnabled = false
local nametagsEnabled = false
local nametagCache = {}

-- Fly / NoClip Basis
local flyBaseSpeed = 0.5
local flyFine = 1.0
local lastGroundPos = nil

-- Kamera-Basisvektoren
local function getCamBasis()
    local camRot = GetGameplayCamRot(2)
    local hdg = math.rad(camRot.z)
    local pitch = math.rad(camRot.x)

    local forward = vector3(
        -math.sin(hdg) * math.cos(pitch),
         math.cos(hdg) * math.cos(pitch),
        -math.sin(pitch)
    )

    local right = vector3(
        math.cos(hdg),
        math.sin(hdg),
        0.0
    )

    return forward, right
end

-- Sicher landen
local function landSafely(ped)
    local pos = GetEntityCoords(ped)
    local found, groundZ = GetGroundZFor_3dCoord(pos.x, pos.y, pos.z, false)

    if found then
        SetEntityCoordsNoOffset(ped, pos.x, pos.y, groundZ + 0.1, false, false, true)
    elseif lastGroundPos then
        SetEntityCoordsNoOffset(ped, lastGroundPos.x, lastGroundPos.y, lastGroundPos.z + 0.2, false, false, true)
    end
end

-- GODMODE
local function setGodmode(state)
    godmodeEnabled = state
    local ped = PlayerPedId()
    SetEntityInvincible(ped, state)
end

-- UNSICHTBAR (separat, nicht automatisch an NoClip gekoppelt)
local function setInvisible(state)
    invisibleEnabled = state
    local ped = PlayerPedId()

    if state then
        NetworkSetEntityInvisibleToNetwork(ped, true)
        SetEntityAlpha(ped, 128, false) -- ~50%
        SetEntityVisible(ped, false, false) -- für andere weg
        SetEntityVisible(ped, true, true)   -- lokal sichtbar
    else
        NetworkSetEntityInvisibleToNetwork(ped, false)
        ResetEntityAlpha(ped)
        SetEntityVisible(ped, true, false)
    end
end

-- NOCLIP / FLY
local function setNoClip(state)
    if state == noclipEnabled then
        return
    end

    noclipEnabled = state
    local ped = PlayerPedId()

    -- AUS
    if not state then
        FreezeEntityPosition(ped, false)
        SetEntityCollision(ped, true, true)
        SetEntityVelocity(ped, 0.0, 0.0, 0.0)
        SetPedCanRagdoll(ped, true)
        landSafely(ped)
        -- nur Godmode-Status respektieren
        SetEntityInvincible(ped, godmodeEnabled)
        return
    end

    -- AN
    CreateThread(function()
        while noclipEnabled do
            Wait(0)

            ped = PlayerPedId()
            FreezeEntityPosition(ped, true)
            SetEntityCollision(ped, false, false)
            SetEntityVelocity(ped, 0.0, 0.0, 0.0)
            SetPedCanRagdoll(ped, false)
            SetEntityInvincible(ped, true)

            local speed = flyBaseSpeed * flyFine

            -- Shift schneller, Alt langsamer
            if IsControlPressed(0, 21) then -- Shift
                speed = speed * 2.2
            end
            if IsControlPressed(0, 19) then -- Alt
                speed = speed * 0.5
            end

            -- Mausrad feinjustiert
            if IsControlJustPressed(0, 241) then
                flyFine = math.min(flyFine + 0.1, 5.0)
            elseif IsControlJustPressed(0, 242) then
                flyFine = math.max(flyFine - 0.1, 0.3)
            end

            local forward, right = getCamBasis()
            local pos = GetEntityCoords(ped)
            local moved = false

            -- W / S
            if IsControlPressed(0, 32) then -- W
                pos = pos + forward * speed
                moved = true
            end
            if IsControlPressed(0, 33) then -- S
                pos = pos - forward * speed
                moved = true
            end

            -- A / D
            if IsControlPressed(0, 34) then -- A
                pos = pos - right * speed
                moved = true
            end
            if IsControlPressed(0, 35) then -- D
                pos = pos + right * speed
                moved = true
            end

            -- Hoch / Runter
            if IsControlPressed(0, 22) then -- Space
                pos = vector3(pos.x, pos.y, pos.z + speed)
                moved = true
            end
            if IsControlPressed(0, 36) then -- Ctrl
                pos = vector3(pos.x, pos.y, pos.z - speed)
                moved = true
            end

            if moved then
                SetEntityCoordsNoOffset(ped, pos.x, pos.y, pos.z, true, true, true)

                -- Charakter in Blickrichtung drehen
                local camRot = GetGameplayCamRot(2)
                SetEntityHeading(ped, camRot.z)

                -- Bodenposition merken
                local okG, gZ = GetGroundZFor_3dCoord(pos.x, pos.y, pos.z, false)
                if okG then
                    lastGroundPos = vector3(pos.x, pos.y, gZ)
                end
            end
        end

        -- Cleanup, wenn Schleife endet (NoClip aus)
        local p = PlayerPedId()
        FreezeEntityPosition(p, false)
        SetEntityCollision(p, true, true)
        SetPedCanRagdoll(p, true)
        landSafely(p)
        SetEntityInvincible(p, godmodeEnabled)
    end)
end

-- NAMETAGS (wie zuvor, nur gelassen)
local function draw3DText(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    if not onScreen then return end

    SetTextScale(0.3, 0.3)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextCentre(1)

    BeginTextCommandDisplayText("STRING")
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(_x, _y)
end

local function getCharIdAndNameForPlayer(serverId)
    local now = GetGameTimer()
    local cached = nametagCache[serverId]

    if cached and (now - cached.ts) < 10000 then
        return cached.id, cached.name
    end

    local res = lib.callback.await('LCV:ADMIN:GetPlayerCharacter', false, serverId)
    if res and res.id then
        nametagCache[serverId] = {
            id = res.id,
            name = res.name or '',
            ts = now
        }
        return res.id, res.name or ''
    end

    nametagCache[serverId] = {
        id = serverId,
        name = '',
        ts = now
    }
    return serverId, ''
end

local function setNametags(state)
    if nametagsEnabled == state then return end
    nametagsEnabled = state

    if not state then
        return
    end

    CreateThread(function()
        while nametagsEnabled do
            local myPed = PlayerPedId()
            local myCoords = GetEntityCoords(myPed)

            for _, player in ipairs(GetActivePlayers()) do
                local ped = GetPlayerPed(player)
                if DoesEntityExist(ped) then
                    local serverId = GetPlayerServerId(player)
                    local coords = GetEntityCoords(ped)
                    local dist = #(coords - myCoords)

                    if dist < 50.0 then
                        local charId, name = getCharIdAndNameForPlayer(serverId)
                        local pedId = ped

                        local label = ("CID:%s | PED:%d"):format(charId, pedId)
                        if name ~= "" then
                            label = label .. " | " .. name
                        end

                        draw3DText(coords.x, coords.y, coords.z + 1.0, label)
                    end
                end
            end

            Wait(0)
        end
    end)
end

-- NUI Toggle Callbacks -> immer echten State zurückgeben

RegisterNUICallback('LCV:ADMIN:Toggle:noclip', function(data, cb)
    local desired
    if data and type(data.enabled) == "boolean" then
        desired = data.enabled
    else
        desired = not noclipEnabled
    end

    setNoClip(desired)

    cb({
        ok = true,
        state = noclipEnabled
    })
end)

RegisterNUICallback('LCV:ADMIN:Toggle:godmode', function(data, cb)
    local enabled = data and data.enabled == true
    setGodmode(enabled)
    cb({
        ok = true,
        state = godmodeEnabled
    })
end)

RegisterNUICallback('LCV:ADMIN:Toggle:invisible', function(data, cb)
    local enabled = data and data.enabled == true
    setInvisible(enabled)
    cb({
        ok = true,
        state = invisibleEnabled
    })
end)

RegisterNUICallback('LCV:ADMIN:Toggle:nametags', function(data, cb)
    local enabled = data and data.enabled == true
    setNametags(enabled)
    cb({
        ok = true,
        state = nametagsEnabled
    })
end)

-- Für initialen Sync beim UI-Open
RegisterNUICallback('LCV:ADMIN:Quick:GetState', function(_, cb)
    cb({
        ok = true,
        noclip = noclipEnabled,
        godmode = godmodeEnabled,
        invisible = invisibleEnabled,
        nametags = nametagsEnabled
    })
end)

-- ===== BLIPS: Spielerposition =====
RegisterNUICallback('LCV:ADMIN:Blips:GetPlayerPos', function(_, cb)
    local ped = PlayerPedId()
    if not ped or ped == 0 or not DoesEntityExist(ped) then
        cb({ ok = false, error = 'no_ped' })
        return
    end

    local coords = GetEntityCoords(ped)
    cb({
        ok = true,
        x = coords.x + 0.0,
        y = coords.y + 0.0,
        z = coords.z + 0.0
    })
end)

-- ===== BLIPS: GetAll =====
RegisterNUICallback('LCV:ADMIN:Blips:GetAll', function(_, cb)
    lib.callback('LCV:ADMIN:Blips:GetAll', false, function(result)
        cb(result or { ok = false, error = 'no_response', blips = {} })
    end)
end)

-- ===== BLIPS: Add =====
RegisterNUICallback('LCV:ADMIN:Blips:Add', function(data, cb)
    lib.callback('LCV:ADMIN:Blips:Add', false, function(result)
        cb(result or { ok = false, error = 'no_response' })
    end, data)
end)

-- ===== BLIPS: Update =====
RegisterNUICallback('LCV:ADMIN:Blips:Update', function(data, cb)
    lib.callback('LCV:ADMIN:Blips:Update', false, function(result)
        cb(result or { ok = false, error = 'no_response' })
    end, data)
end)

-- ===== BLIPS: Delete =====
RegisterNUICallback('LCV:ADMIN:Blips:Delete', function(data, cb)
    if not data or not data.id then
        cb({ ok = false, error = 'missing_id' })
        return
    end

    lib.callback('LCV:ADMIN:Blips:Delete', false, function(result)
        cb(result or { ok = false, error = 'no_response' })
    end, data)
end)

-- ===== BLIPS: Teleport =====
RegisterNUICallback('LCV:ADMIN:Blips:Teleport', function(data, cb)
    if not data or not data.x or not data.y or not data.z then
        cb({ ok = false, error = 'bad_coords' })
        return
    end

    CreateThread(function()
        if not IsScreenFadedOut() and not IsScreenFadingOut() then
            DoScreenFadeOut(250)
            Wait(260)
        end

        TriggerServerEvent('LCV:ADMIN:Blips:Teleport', data.id, data.x, data.y, data.z)

        Wait(200)
        DoScreenFadeIn(250)
    end)

    cb({ ok = true })
end)

-- ===== PORT TO WAYPOINT (SAFEGROUND) =====

local function getSafeWaypointCoords()
    local blip = GetFirstBlipInfoId(8) -- 8 = Waypoint
    if blip == 0 then
        return nil, 'no_waypoint'
    end

    local coords = GetBlipInfoIdCoord(blip)
    if not coords then
        return nil, 'no_coords'
    end

    local x = coords.x + 0.0
    local y = coords.y + 0.0

    -- Höhen, auf denen wir nach Boden suchen (von oben nach unten)
    local testHeights = {
        300.0, 250.0, 200.0, 150.0,
        120.0, 90.0, 70.0, 50.0,
        35.0, 25.0, 15.0, 10.0
    }

    local found, z

    -- 1) Ground-Check mit Collision-Request
    for _, h in ipairs(testHeights) do
        RequestCollisionAtCoord(x, y, h)
        found, z = GetGroundZFor_3dCoord(x, y, h, false)
        if found then
            -- leicht über den Boden setzen
            return { x = x, y = y, z = z + 1.0 }
        end
    end

    -- 2) Fallback: SafeCoord über Navmesh (wenn verfügbar)
    -- Flags: NOT_WATER + NOT_INTERIOR + NOT_ISOLATED
    local safeFound, safePos = GetSafeCoordForPed(x, y, 80.0, false, 8 + 4 + 2)
    if safeFound and safePos then
        return { x = safePos.x + 0.0, y = safePos.y + 0.0, z = safePos.z + 1.0 }
    end

    -- 3) Letzte Rettung: gleiche Höhe wie aktueller Ped (horizontaler Port)
    local ped = PlayerPedId()
    if ped and ped ~= 0 and DoesEntityExist(ped) then
        local px, py, pz = table.unpack(GetEntityCoords(ped))
        return { x = x, y = y, z = pz + 1.0 }
    end

    return nil, 'no_ground'
end


RegisterNUICallback('LCV:ADMIN:PortToWaypoint', function(_, cb)
    local ped = PlayerPedId()
    if not ped or ped == 0 or not DoesEntityExist(ped) then
        cb({ ok = false, error = 'no_ped' })
        return
    end

    local wp, err = getSafeWaypointCoords()
    if not wp then
        if err == 'no_waypoint' then
            lib.notify({
                title = 'Teleport fehlgeschlagen',
                description = 'Keine Kartenmarkierung gesetzt.',
                type = 'error',
                position = 'center-right',
                duration = 3000
            })
        else
            lib.notify({
                title = 'Teleport fehlgeschlagen',
                description = 'Konnte sicheren Boden an der Markierung nicht finden.',
                type = 'error',
                position = 'center-right',
                duration = 3000
            })
        end

        cb({ ok = false, error = err or 'no_safe_ground' })
        return
    end

    -- Fade + Server-Teleport bleibt wie gehabt
    CreateThread(function()
        if not IsScreenFadedOut() and not IsScreenFadingOut() then
            DoScreenFadeOut(250)
            Wait(260)
        end

        TriggerServerEvent('LCV:ADMIN:TeleportToWaypoint', wp.x, wp.y, wp.z)

        Wait(200)
        DoScreenFadeIn(250)
    end)

    cb({ ok = true })
end)

-- ================== FACTIONS: NUI BRIDGE ==================

RegisterNUICallback('LCV:ADMIN:Factions:GetAll', function(data, cb)
    lib.callback('LCV:ADMIN:Factions:GetAll', false, function(result)
        cb(result or { ok = false, error = 'no_response', factions = {} })
    end, data)
end)

RegisterNUICallback('LCV:ADMIN:Factions:Create', function(data, cb)
    lib.callback('LCV:ADMIN:Factions:Create', false, function(result)
        cb(result or { ok = false, error = 'no_response' })
    end, data)
end)

RegisterNUICallback('LCV:ADMIN:Factions:Update', function(data, cb)
    lib.callback('LCV:ADMIN:Factions:Update', false, function(result)
        cb(result or { ok = false, error = 'no_response' })
    end, data)
end)

RegisterNUICallback('LCV:ADMIN:Factions:Delete', function(data, cb)
    if not data or not data.id then
        cb({ ok = false, error = 'missing_id' })
        return
    end

    lib.callback('LCV:ADMIN:Factions:Delete', false, function(result)
        cb(result or { ok = false, error = 'no_response' })
    end, data)
end)

-- ============== FACTIONS NUI BRIDGE ==============

RegisterNUICallback('LCV:ADMIN:Factions:GetAll', function(data, cb)
    lib.callback('LCV:ADMIN:Factions:GetAll', false, function(result)
        cb(result or { ok = false, error = 'no_response', factions = {} })
    end, data)
end)

RegisterNUICallback('LCV:ADMIN:Factions:GetCharactersSimple', function(data, cb)
    lib.callback('LCV:ADMIN:Factions:GetCharactersSimple', false, function(result)
        cb(result or { ok = false, error = 'no_response', characters = {} })
    end, data)
end)

RegisterNUICallback('LCV:ADMIN:Factions:GetDetails', function(data, cb)
    lib.callback('LCV:ADMIN:Factions:GetDetails', false, function(result)
        cb(result or { ok = false, error = 'no_response' })
    end, data)
end)

RegisterNUICallback('LCV:ADMIN:Factions:Create', function(data, cb)
    lib.callback('LCV:ADMIN:Factions:Create', false, function(result)
        cb(result or { ok = false, error = 'no_response' })
    end, data)
end)

RegisterNUICallback('LCV:ADMIN:Factions:Update', function(data, cb)
    lib.callback('LCV:ADMIN:Factions:Update', false, function(result)
        cb(result or { ok = false, error = 'no_response' })
    end, data)
end)

RegisterNUICallback('LCV:ADMIN:Factions:Delete', function(data, cb)
    lib.callback('LCV:ADMIN:Factions:Delete', false, function(result)
        cb(result or { ok = false, error = 'no_response' })
    end, data)
end)

RegisterNUICallback('LCV:ADMIN:Factions:AddMember', function(data, cb)
    lib.callback('LCV:ADMIN:Factions:AddMember', false, function(result)
        cb(result or { ok = false, error = 'no_response' })
    end, data)
end)

RegisterNUICallback('LCV:ADMIN:Factions:SetMemberRank', function(data, cb)
    lib.callback('LCV:ADMIN:Factions:SetMemberRank', false, function(result)
        cb(result or { ok = false, error = 'no_response' })
    end, data)
end)

RegisterNUICallback('LCV:ADMIN:Factions:RemoveMember', function(data, cb)
    lib.callback('LCV:ADMIN:Factions:RemoveMember', false, function(result)
        cb(result or { ok = false, error = 'no_response' })
    end, data)
end)

RegisterNUICallback('LCV:ADMIN:Factions:CreateRank', function(data, cb)
    lib.callback('LCV:ADMIN:Factions:CreateRank', false, function(result)
        cb(result or { ok = false, error = 'no_response' })
    end, data)
end)

RegisterNUICallback('LCV:ADMIN:Factions:UpdateRank', function(data, cb)
    lib.callback('LCV:ADMIN:Factions:UpdateRank', false, function(result)
        cb(result or { ok = false, error = 'no_response' })
    end, data)
end)

RegisterNUICallback('LCV:ADMIN:Factions:DeleteRank', function(data, cb)
    lib.callback('LCV:ADMIN:Factions:DeleteRank', false, function(result)
        cb(result or { ok = false, error = 'no_response' })
    end, data)
end)

-- ========== FACTION PERMISSION SCHEMA: NUI BRIDGE ==========

RegisterNUICallback('LCV:ADMIN:Factions:GetPermissionSchema', function(data, cb)
    lib.callback('LCV:ADMIN:Factions:GetPermissionSchema', false, function(result)
        cb(result or { ok = false, error = 'no_response', schema = {} })
    end, data)
end)

RegisterNUICallback('LCV:ADMIN:FactionPerms:GetAll', function(data, cb)
    lib.callback('LCV:ADMIN:FactionPerms:GetAll', false, function(result)
        cb(result or { ok = false, error = 'no_response', perms = {} })
    end, data)
end)

RegisterNUICallback('LCV:ADMIN:FactionPerms:Save', function(data, cb)
    lib.callback('LCV:ADMIN:FactionPerms:Save', false, function(result)
        cb(result or { ok = false, error = 'no_response' })
    end, data)
end)

RegisterNUICallback('LCV:ADMIN:FactionPerms:Delete', function(data, cb)
    lib.callback('LCV:ADMIN:FactionPerms:Delete', false, function(result)
        cb(result or { ok = false, error = 'no_response' })
    end, data)
end)

-- ===== HOME: DUTY =====

RegisterNUICallback('LCV:ADMIN:Home:GetDutyData', function(data, cb)
    lib.callback('LCV:ADMIN:Home:GetDutyData', false, function(result)
        cb(result or { ok = false, error = 'no_response', dutyFactions = {}, currentDuty = {} })
    end, data)
end)

RegisterNUICallback('LCV:ADMIN:Home:SetDuty', function(data, cb)
    lib.callback('LCV:ADMIN:Home:SetDuty', false, function(result)
        cb(result or { ok = false, error = 'no_response' })
    end, data)
end)


-- ===== CHARACTERS: GetAll =====
RegisterNUICallback('LCV:ADMIN:Characters:GetAll', function(_, cb)
    lib.callback('LCV:ADMIN:Characters:GetAll', false, function(result)
        cb(result or { ok = false, error = 'no_response', characters = {} })
    end)
end)

-- ===== CHARACTERS: Update =====
RegisterNUICallback('LCV:ADMIN:Characters:Update', function(data, cb)
    if not data or not data.id then
        cb({ ok = false, error = 'missing_id' })
        return
    end

    lib.callback('LCV:ADMIN:Characters:Update', false, function(result)
        cb(result or { ok = false, error = 'no_response' })
    end, data)
end)

-- ===== CHARACTERS: Delete =====
RegisterNUICallback('LCV:ADMIN:Characters:Delete', function(data, cb)
    if not data or not data.id then
        cb({ ok = false, error = 'missing_id' })
        return
    end

    lib.callback('LCV:ADMIN:Characters:Delete', false, function(result)
        cb(result or { ok = false, error = 'no_response' })
    end, data)
end)

-- ===== HOUSING SYSTEM =====

RegisterNUICallback('LCV:ADMIN:UI:SetPlacementMode', function(data, cb)
    local enabled = data and data.enabled == true

    if enabled then
        -- UI bleibt fokussierbar, aber Input auch im Spiel
        SetNuiFocus(true, true)
        SetNuiFocusKeepInput(true)
    else
        -- Vollbild-Admin, Input wieder blocken wie gehabt
        SetNuiFocus(true, true)
        SetNuiFocusKeepInput(false)
    end

    SendNUIMessage({
        action = "setPlacementMode",
        enabled = enabled
    })

    cb({ ok = true })
end)
-- ===== HOUSES: NUI BRIDGE =====

RegisterNUICallback('LCV:ADMIN:Houses:GetAll', function(_, cb)
    lib.callback('LCV:ADMIN:Houses:GetAll', false, function(result)
        cb(result or { ok = false, error = 'no_response', houses = {} })
    end)
end)

RegisterNUICallback('LCV:ADMIN:Houses:Add', function(data, cb)
    lib.callback('LCV:ADMIN:Houses:Add', false, function(result)
        cb(result or { ok = false, error = 'no_response' })
    end, data)
end)

RegisterNUICallback('LCV:ADMIN:Houses:Update', function(data, cb)
    lib.callback('LCV:ADMIN:Houses:Update', false, function(result)
        cb(result or { ok = false, error = 'no_response' })
    end, data)
end)

RegisterNUICallback('LCV:ADMIN:Houses:Delete', function(data, cb)
    if not data or not data.id then
        cb({ ok = false, error = 'missing_id' })
        return
    end

    lib.callback('LCV:ADMIN:Houses:Delete', false, function(result)
        cb(result or { ok = false, error = 'no_response' })
    end, data)
end)

RegisterNUICallback('LCV:ADMIN:Houses:GetPlayerPos', function(_, cb)
    local ped = PlayerPedId()
    if not ped or ped == 0 or not DoesEntityExist(ped) then
        cb({ ok = false, error = 'no_ped' })
        return
    end
    local coords = GetEntityCoords(ped)
    cb({
        ok = true,
        x = coords.x + 0.0,
        y = coords.y + 0.0,
        z = coords.z + 0.0
    })
end)

RegisterNUICallback('LCV:ADMIN:Houses:Teleport', function(data, cb)
    if not data or not data.x or not data.y or not data.z then
        cb({ ok = false, error = 'bad_coords' })
        return
    end

    CreateThread(function()
        if not IsScreenFadedOut() and not IsScreenFadingOut() then
            DoScreenFadeOut(250)
            Wait(260)
        end

        TriggerServerEvent('LCV:ADMIN:Houses:Teleport', data.id, data.x, data.y, data.z)

        Wait(200)
        DoScreenFadeIn(250)
    end)

    cb({ ok = true })
end)

-- ===== HOUSES IPL: NUI BRIDGE =====

RegisterNUICallback('LCV:ADMIN:HousesIPL:GetAll', function(_, cb)
    lib.callback('LCV:ADMIN:HousesIPL:GetAll', false, function(result)
        cb(result or { ok = false, error = 'no_response', ipls = {} })
    end)
end)

RegisterNUICallback('LCV:ADMIN:HousesIPL:Add', function(data, cb)
    lib.callback('LCV:ADMIN:HousesIPL:Add', false, function(result)
        cb(result or { ok = false, error = 'no_response' })
    end, data)
end)

RegisterNUICallback('LCV:ADMIN:HousesIPL:Update', function(data, cb)
    lib.callback('LCV:ADMIN:HousesIPL:Update', false, function(result)
        cb(result or { ok = false, error = 'no_response' })
    end, data)
end)

RegisterNUICallback('LCV:ADMIN:HousesIPL:Delete', function(data, cb)
    if not data or not data.id then
        cb({ ok = false, error = 'missing_id' })
        return
    end

    lib.callback('LCV:ADMIN:HousesIPL:Delete', false, function(result)
        cb(result or { ok = false, error = 'no_response' })
    end, data)
end)

RegisterNUICallback('LCV:ADMIN:HousesIPL:GetPlayerPos', function(_, cb)
    local ped = PlayerPedId()
    if not ped or ped == 0 or not DoesEntityExist(ped) then
        cb({ ok = false, error = 'no_ped' })
        return
    end
    local coords = GetEntityCoords(ped)
    cb({
        ok = true,
        x = coords.x + 0.0,
        y = coords.y + 0.0,
        z = coords.z + 0.0
    })
end)

RegisterNUICallback('LCV:ADMIN:HousesIPL:Teleport', function(data, cb)
    if not data or not data.x or not data.y or not data.z then
        cb({ ok = false, error = 'bad_coords' })
        return
    end

    CreateThread(function()
        if not IsScreenFadedOut() and not IsScreenFadingOut() then
            DoScreenFadeOut(250)
            Wait(260)
        end

        TriggerServerEvent('LCV:ADMIN:HousesIPL:Teleport', data.id, data.x, data.y, data.z)

        Wait(200)
        DoScreenFadeIn(250)
    end)

    cb({ ok = true })
end)

RegisterNUICallback('LCV:ADMIN:Teleport:Coords', function(data, cb)
    if not data then
        cb({ ok = false, error = 'no_data' })
        return
    end

    local x = tonumber(data.x)
    local y = tonumber(data.y)
    local z = tonumber(data.z)

    if not x or not y or not z then
        cb({ ok = false, error = 'bad_coords' })
        return
    end

    CreateThread(function()
        if not IsScreenFadedOut() and not IsScreenFadingOut() then
            DoScreenFadeOut(250)
            Wait(260)
        end

        TriggerServerEvent('LCV:ADMIN:Teleport:Coords', x, y, z)

        Wait(200)
        DoScreenFadeIn(250)
    end)

    cb({ ok = true })
end)

RegisterNUICallback('LCV:ADMIN:Houses:GetStreetName', function(data, cb)
    local ped = PlayerPedId()
    if not ped or ped == 0 or not DoesEntityExist(ped) then
        cb({ ok = false, error = 'no_ped' })
        return
    end

    local coords = GetEntityCoords(ped)
    local streetHash, crossHash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    local streetName = GetStreetNameFromHashKey(streetHash)
    cb({ ok = true, street = streetName or "" })
end)

RegisterNUICallback('LCV:ADMIN:Houses:ResetPincode', function(data, cb)
    if not data or not data.id then
        cb({ ok = false, error = 'missing_id' })
        return
    end

    lib.callback('LCV:ADMIN:Houses:ResetPincode', false, function(result)
        cb(result or { ok = false, error = 'no_response' })
    end, data)
end)

-- ===== HOUSES: GARAGE_SPAWNS NUI BRIDGES =====
RegisterNUICallback('LCV:ADMIN:Houses:GarageSpawns:List', function(data, cb)
    lib.callback('LCV:ADMIN:Houses:GarageSpawns:List', false, function(result)
        cb(result or { ok=false, error='no_response', spawns = {} })
    end, data)
end)

RegisterNUICallback('LCV:ADMIN:Houses:GarageSpawns:Add', function(data, cb)
    lib.callback('LCV:ADMIN:Houses:GarageSpawns:Add', false, function(result)
        cb(result or { ok=false, error='no_response' })
    end, data)
end)

RegisterNUICallback('LCV:ADMIN:Houses:GarageSpawns:Update', function(data, cb)
    lib.callback('LCV:ADMIN:Houses:GarageSpawns:Update', false, function(result)
        cb(result or { ok=false, error='no_response' })
    end, data)
end)

RegisterNUICallback('LCV:ADMIN:Houses:GarageSpawns:Delete', function(data, cb)
    lib.callback('LCV:ADMIN:Houses:GarageSpawns:Delete', false, function(result)
        cb(result or { ok=false, error='no_response' })
    end, data)
end)


-- Cleanup
AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then
        if isADMINOpen then
            isADMINOpen = false
            closeADMIN()
        end
    end
end)


-- =========================
-- UI: PlacementMode Toggle
-- =========================
RegisterNUICallback('LCV:ADMIN:UI:SetPlacementMode', function(data, cb)
    -- data.enabled: true/false – du kannst hier später die Kamera/Marker o.ä. umschalten.
    -- Für jetzt reicht ein sofortiges OK, damit die UI nicht hängt.
    cb({ ok = true })
end)

-- =========================
-- Houses: Spielerposition
-- =========================
RegisterNUICallback('LCV:ADMIN:Houses:GetPlayerPos', function(data, cb)
    local ped = PlayerPedId()
    if not ped or ped == 0 then
        cb({ ok = false, error = 'no_ped' })
        return
    end
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped) or 0.0
    cb({
        ok = true,
        x = coords.x + 0.0,
        y = coords.y + 0.0,
        z = coords.z + 0.0,
        heading = heading + 0.0
    })
end)

-- =========================
-- Houses: Straßenname (optional)
-- =========================
RegisterNUICallback('LCV:ADMIN:Houses:GetStreetName', function(data, cb)
    local ped = PlayerPedId()
    if not ped or ped == 0 then
        cb({ ok = false, error = 'no_ped' })
        return
    end
    local coords = GetEntityCoords(ped)
    local sHash, cHash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    local streetName = GetStreetNameFromHashKey(sHash)
    local crossName  = GetStreetNameFromHashKey(cHash)
    cb({ ok = true, street = streetName or '', cross = crossName or '' })
end)
-- ===== IPL LOAD / UNLOAD (Clientseitig) =====
local _loadedIpls = {}

RegisterNUICallback('LCV:ADMIN:IPL:Load', function(data, cb)
    local name = data and data.name
    if not name or name == '' then
        cb({ ok = false, error = 'missing_name' })
        return
    end

    -- schon geladen? egal, RequestIpl ist idempotent – wir tracken nur fürs UI
    RequestIpl(name)
    _loadedIpls[name] = true

    lib.notify({
        title = 'IPL geladen',
        description = ('%s wurde angefordert.'):format(name),
        type = 'success',
        position = 'center-right',
        duration = 2500
    })

    cb({ ok = true, loaded = true, name = name })
end)

RegisterNUICallback('LCV:ADMIN:IPL:Unload', function(data, cb)
    local name = data and data.name
    if not name or name == '' then
        cb({ ok = false, error = 'missing_name' })
        return
    end

    RemoveIpl(name)
    _loadedIpls[name] = nil

    lib.notify({
        title = 'IPL entladen',
        description = ('%s wurde entfernt.'):format(name),
        type = 'inform',
        position = 'center-right',
        duration = 2500
    })

    cb({ ok = true, loaded = false, name = name })
end)
