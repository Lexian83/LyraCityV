-- c-coma.lua
-- Coma system: when player dies, start a 15-minute countdown,
-- show NUI ("Du bist im Koma") with timer, then auto-respawn at Pillbox.
-- Cancels if player is revived before timer ends.

-- Config
local PILLBOX = vector4(295.83, -584.62, 43.26, 70.0)
local DEFAULT_COMA_MS = 900000 -- 15 minutes
local UPDATE_INTERVAL = 200    -- ms for UI updates
local DISABLE_CONTROLS = true
local RESPAWN_HEALTH_PCT = 0.50

-- State
local comaActive = false
local comaEndAt = 0
local lastSentRemain = -1


-- Disbale HP regenration
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(1)
		SetPlayerHealthRechargeMultiplier(PlayerId(), 0.0)
	end
end)


local function getComaMs()
    local v = GetConvar('LCV_coma_ms', tostring(DEFAULT_COMA_MS))
    local n = tonumber(v) or DEFAULT_COMA_MS
    if n < 10000 then n = 10000 end -- min 10s safety
    return n
end

local function showComaUI(show)
    SendNUIMessage({ type = 'coma_show', show = show })
    SetNuiFocus(false, false)

    -- alle UI?? Schliesen
    if (show) then 
    TriggerEvent('LCV:inventory:Close')

    -- In die UI Map eintragen
    exports.inputmanager:LCV_OpenUI('unconscious')
    else
    exports.inputmanager:LCV_CloseUI('unconscious')
    end
    
end

local function setComaTime(msRemain)
    if msRemain == lastSentRemain then return end
    lastSentRemain = msRemain
    SendNUIMessage({ type = 'coma_time', ms = msRemain })
end

-- sichere Bodenhöhe suchen (falls Z „luftig“ ist)
local function findSafeGround(x, y, z)
    local ok, groundZ = GetGroundZFor_3dCoord(x, y, z, false)
    if ok then return vector3(x, y, groundZ + 1.0) end
    -- brute-force nach unten „tasten“
    for dz = 5.0, 50.0, 2.5 do
        ok, groundZ = GetGroundZFor_3dCoord(x, y, z - dz, false)
        if ok then return vector3(x, y, groundZ + 1.0) end
    end
    return vector3(x, y, z + 1.0)
end

local function loadCollisionAt(coords, timeoutMs)
    RequestCollisionAtCoord(coords.x, coords.y, coords.z)
    local t = GetGameTimer() + (timeoutMs or 3000)
    while not HasCollisionLoadedAroundEntity(PlayerPedId()) and GetGameTimer() < t do
        RequestCollisionAtCoord(coords.x, coords.y, coords.z)
        Wait(0)
    end
end

local function cleanPed(ped)
    ClearPedBloodDamage(ped)
    ResetPedVisibleDamage(ped)
    ClearPedLastDamageBone(ped)
    ClearPedTasksImmediately(ped)
    ClearPlayerWantedLevel(PlayerId())
    RemoveAllPedWeapons(ped, true)
end

local function setHalfHealth(ped)
  -- Health/Armor nach Respawn korrekt setzen
-- Stelle sicher, dass Max-Health auf 200 steht (FiveM “voll”)
if GetEntityMaxHealth(ped) < 200 then
    SetPedMaxHealth(ped, 200)
end
local maxH = GetEntityMaxHealth(ped)

-- 50% vom Max-Health (Konfig: RESPAWN_HEALTH_PCT)
local target = math.floor(maxH * (RESPAWN_HEALTH_PCT or 0.50))
target = math.max(1, math.min(target, maxH))

SetEntityHealth(ped, 100)
SetPedArmour(ped, 0)
end

local function doRespawnPillbox()
    local ped = PlayerPedId()

    -- Fade out
    DoScreenFadeOut(600)
    while not IsScreenFadedOut() do Wait(0) end

    -- Ziel-Koords absichern (Boden finden + Kollision laden)
    local target = findSafeGround(PILLBOX.x, PILLBOX.y, PILLBOX.z)

    -- kurz einfrieren & unverwundbar, damit kein Fall-/Weltschaden zuschlägt
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetPlayerInvincible(PlayerId(), true)
    SetPedCanRagdoll(ped, false)

    -- Resurrect & teleport
    NetworkResurrectLocalPlayer(target.x, target.y, target.z, PILLBOX.w, true, true, false)
    SetEntityCoordsNoOffset(ped, target.x, target.y, target.z, false, false, false)
    SetEntityHeading(ped, PILLBOX.w)

    -- Kollision wirklich laden, bevor wir loslassen
    loadCollisionAt(target, 5000)
    Wait(100)

    -- Zustand säubern, 50% HP setzen
    cleanPed(ped)
    setHalfHealth(ped)
    ResetPedRagdollTimer(ped)

    -- kleine Schonfrist
    Wait(1200)
    SetPedCanRagdoll(ped, true)
    SetEntityInvincible(ped, false)
    SetPlayerInvincible(PlayerId(), false)
    FreezeEntityPosition(ped, false)

    -- Fade in
    DoScreenFadeIn(800)
end


-- Main watcher
CreateThread(function()
    local wasDead = false
    while true do
        local ped = PlayerPedId()
        local dead = IsEntityDead(ped)

        if dead and not wasDead and not comaActive then
            wasDead = true
            comaActive = true
            comaEndAt = GetGameTimer() + getComaMs()
            lastSentRemain = -1
            showComaUI(true)
            -- immediate set
            setComaTime(comaEndAt - GetGameTimer())
        elseif not dead and wasDead then
            wasDead = false
        end

        -- If revived before timer ends, cancel coma
        if comaActive and not dead then
            setHalfHealth(PlayerPedId())
            comaActive = false
            showComaUI(false)
        end

        -- Countdown & completion
        if comaActive then
            local remain = comaEndAt - GetGameTimer()
            if remain <= 0 then
                comaActive = false
                showComaUI(false)
                doRespawnPillbox()
            else
                setComaTime(remain)
            end
        end

        Wait(UPDATE_INTERVAL)
    end
end)

-- Disable controls while in coma
CreateThread(function()
    while true do
        if comaActive and DISABLE_CONTROLS then
            -- Disable most movement and interaction
            DisableAllControlActions(0)
            -- Allow chat toggle / pause menu basics if you want (comment out to hard lock)
            EnableControlAction(0, 245, true) -- chat
            EnableControlAction(0, 199, true) -- pause
            EnableControlAction(0, 200, true) -- pause/ESC
        end
        Wait(0)
    end
end)

-- Safety: on resource start or player spawn, hide UI
AddEventHandler('onResourceStart', function(res)
    if res == GetCurrentResourceName() then
        showComaUI(false)
    end
end)

AddEventHandler('playerSpawned', function()
    showComaUI(false)
end)

-- HP Überwachung

local lastHP = -1
local CHECK_INTERVAL = 200  -- in ms (0.2 Sekunden)

CreateThread(function()
    while true do
        local ped = PlayerPedId()
        local hp = GetEntityHealth(ped)

        if hp ~= lastHP then
            TriggerEvent("onHpChange", hp, lastHP)  -- dein eigenes Event!
            lastHP = hp
        end

        Wait(CHECK_INTERVAL)
    end
end)

-- Beispiel-Nutzung:
AddEventHandler("onHpChange", function(current, previous)
    local diff = current - previous
    if diff < 0 then
        print(("HP verloren: %d"):format(math.abs(diff)))
    elseif diff > 0 then
        print(("HP gewonnen: +%d"):format(diff))
    end

    -- optional: UI-Update
    local pct = math.floor((current / GetEntityMaxHealth(PlayerPedId())) * 100)
    TriggerEvent("LCV:ui:setHealth", pct)
end)
