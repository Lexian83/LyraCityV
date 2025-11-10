-- =====================================================
-- Lyra City V – Admin Menu Client (HARDENED)
-- =====================================================

local INVIS  = false
local GOD    = false
local FLY    = false
local LABELS = false
local LabelsCache = {}
local flyBase = 0.5
local flyFine = 1.0
local lastGroundPos = nil
local flyThreadRunning = false  -- <== NEU

------------------------------------------------------------
-- 🔹 UTILITIES
------------------------------------------------------------
local function DrawText3D(x, y, z, text)
    local onScreen,_x,_y = World3dToScreen2d(x, y, z)
    if not onScreen then return end
    SetTextScale(0.30, 0.30)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextOutline()
    SetTextCentre(true)
    SetTextColour(255, 255, 255, 215)
    BeginTextCommandDisplayText("STRING")
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(_x, _y)
end

local function notify(msg, typ)
    lib.notify({ title = 'Admin', description = msg, type = typ or 'info' })
end

------------------------------------------------------------
-- 🔹 INVISIBILITY (applied by server update)
------------------------------------------------------------
local function applyInvisibility(state)
    INVIS = state and true or false
    local ped = PlayerPedId()

    NetworkSetEntityInvisibleToNetwork(ped, INVIS)

    if INVIS then
        SetEntityVisible(ped, true, false)
        SetEntityAlpha(ped, 100, false)           -- ~40% sichtbar (0..255)
        SetPedCurrentWeaponVisible(ped, false, true, true, true)
        notify('Unsichtbar (lokal halbtransparent)', 'success')
    else
        SetEntityVisible(ped, true, false)
        ResetEntityAlpha(ped)
        SetPedCurrentWeaponVisible(ped, true, true, true, true)
        notify('Unsichtbarkeit deaktiviert', 'info')
    end
end

RegisterNetEvent('LCV:admin:updatePlayerInvis', function(src, state)
    local mySrc = GetPlayerServerId(PlayerId())
    if src ~= mySrc then return end
    applyInvisibility(state)
end)

------------------------------------------------------------
-- 🔹 GODMODE (applied by server update)
------------------------------------------------------------
local function applyGodMode(state)
    GOD = state and true or false
    local ped = PlayerPedId()
    SetEntityInvincible(ped, GOD)
    SetPlayerInvincible(PlayerId(), GOD)
    notify(GOD and 'Godmode aktiviert' or 'Godmode deaktiviert', GOD and 'success' or 'info')
end

RegisterNetEvent('LCV:admin:updatePlayerGod', function(state)
    applyGodMode(state)
end)

------------------------------------------------------------
-- 🔹 FLY MODE + NOCLIP (applied by server update)
------------------------------------------------------------
local function getCamBasis()
    local camRot = GetGameplayCamRot(2)
    local hdg = math.rad(camRot.z)
    local pitch = math.rad(camRot.x)
    local forward = vector3(
        -math.sin(hdg) * math.cos(pitch),
         math.cos(hdg) * math.cos(pitch),
        -math.sin(pitch)
    )
    local right = vector3(math.cos(hdg), math.sin(hdg), 0.0)
    return forward, right
end

local function landSafely(ped)
    local pos = GetEntityCoords(ped)
    local found, groundZ = GetGroundZFor_3dCoord(pos.x, pos.y, pos.z, false)
    if found then
        SetEntityCoordsNoOffset(ped, pos.x, pos.y, groundZ + 0.1, false, false, true)
    elseif lastGroundPos then
        SetEntityCoordsNoOffset(ped, lastGroundPos.x, lastGroundPos.y, lastGroundPos.z + 0.2, false, false, true)
    end
end

local function setFly(state)
    local ped = PlayerPedId()
    FLY = state and true or false

    if not FLY then
        -- Warte, bis evtl. Loop-Thread sauber raus ist
        local t0 = GetGameTimer()
        while flyThreadRunning and (GetGameTimer() - t0) < 1000 do
            Wait(0)
        end

        -- HARTE ENTSperr-Sequenz (stellt sicheres Laufen wieder her)
        ped = PlayerPedId()
        FreezeEntityPosition(ped, false)
        SetEntityCollision(ped, true, true)
        SetEntityVelocity(ped, 0.0, 0.0, 0.0)
        SetPedCanRagdoll(ped, true)

        -- Sicher landen
        landSafely(ped)

        -- WICHTIG: ursprüngliche States re-applien,
        -- damit Unsichtbarkeit/Godmode konsistent bleiben
        applyInvisibility(INVIS)
        applyGodMode(GOD)

        notify('Flugmodus deaktiviert', 'info')
        return
    end

    -- === AN ===
    notify('Flugmodus (NoClip) aktiviert', 'success')

    CreateThread(function()
        flyThreadRunning = true
        local pos = GetEntityCoords(ped)
        local ok, gz = GetGroundZFor_3dCoord(pos.x, pos.y, pos.z, false)
        if ok then lastGroundPos = vector3(pos.x, pos.y, gz) end

        while FLY do
            Wait(0)
            ped = PlayerPedId()

            FreezeEntityPosition(ped, true)
            SetEntityCollision(ped, false, false)
            SetEntityVelocity(ped, 0.0, 0.0, 0.0)
            SetPedCanRagdoll(ped, false)
            SetEntityInvincible(ped, true)

            local speed = flyBase * flyFine
            if IsControlPressed(0, 21) then speed = speed * 2.2 end  -- SHIFT
            if IsControlPressed(0, 19) then speed = speed * 0.5 end  -- ALT

            if IsControlJustPressed(0, 241) then      -- MWHEEL UP
                flyFine = math.min(flyFine + 0.1, 5.0)
            elseif IsControlJustPressed(0, 242) then  -- MWHEEL DOWN
                flyFine = math.max(flyFine - 0.1, 0.3)
            end

            local forward, right = getCamBasis()
            pos = GetEntityCoords(ped)

            if IsControlPressed(0, 32) then pos = pos + forward * speed end   -- W
            if IsControlPressed(0, 33) then pos = pos - forward * speed end   -- S
            if IsControlPressed(0, 34) then pos = pos - right   * speed end   -- A
            if IsControlPressed(0, 35) then pos = pos + right   * speed end   -- D
            if IsControlPressed(0, 22) then pos = vector3(pos.x, pos.y, pos.z + speed) end -- SPACE
            if IsControlPressed(0, 36) then pos = vector3(pos.x, pos.y, pos.z - speed) end -- CTRL

            SetEntityCoordsNoOffset(ped, pos.x, pos.y, pos.z, true, true, true)

            local okG, gZ = GetGroundZFor_3dCoord(pos.x, pos.y, pos.z, false)
            if okG then lastGroundPos = vector3(pos.x, pos.y, gZ) end
        end

        -- Cleanup falls der Loop endet, auch wenn state bereits geändert wurde
        ped = PlayerPedId()
        FreezeEntityPosition(ped, false)
        SetEntityCollision(ped, true, true)
        SetPedCanRagdoll(ped, true)
        landSafely(ped)
        applyInvisibility(INVIS)
        applyGodMode(GOD)
        flyThreadRunning = false
    end)
end


RegisterNetEvent('LCV:admin:updatePlayerFly', function(state)
    setFly(state)
end)

------------------------------------------------------------
-- 🔹 OVERHEAD LABELS
------------------------------------------------------------
local function RequestLabelsSnapshot()
    TriggerServerEvent('lcv:labels:request')
end

RegisterNetEvent('lcv:labels:snapshot', function(data)
    LabelsCache = {}
    for _,row in ipairs(data or {}) do
        LabelsCache[row.sid] = { name = row.name or ('Player '..row.sid), charId = row.charId }
    end
end)

CreateThread(function()
    while true do
        if LABELS then
            local myPed = PlayerPedId()
            local myPos = GetEntityCoords(myPed)
            local mySid = GetPlayerServerId(PlayerId())

            for _, player in ipairs(GetActivePlayers()) do
                local sid = GetPlayerServerId(player)
                local ped = GetPlayerPed(player)
                if DoesEntityExist(ped) then
                    local pos = GetEntityCoords(ped)
                    local dist = #(myPos - pos)
                    if sid == mySid or dist < 60.0 then
                        local head = GetPedBoneCoords(ped, 0x796E, 0.0, 0.0, 0.2)
                        local entry = LabelsCache[sid]
                        local label
                        if entry then
                            label = (entry.name or ('Player '..sid)) .. " | #" .. (entry.charId or sid)
                        else
                            label = ('%s | #%d'):format(GetPlayerName(player), sid)
                        end
                        local zOffset = (sid == mySid) and 0.55 or 0.35
                        DrawText3D(head.x, head.y, head.z + zOffset, label)
                    end
                end
            end
            Wait(0)
        else
            Wait(500)
        end
    end
end)

CreateThread(function()
    while true do
        if LABELS then
            RequestLabelsSnapshot()
            Wait(3000)
        else
            Wait(1000)
        end
    end
end)

------------------------------------------------------------
-- 🔹 ADMIN MENU (server-authoritative toggles)
------------------------------------------------------------
local function registerAdminMenu()
    lib.registerMenu({
        id = 'menu:admin',
        title = 'Administration',
        position = 'top-left',
        onCheck = function(selected, checked)
            if selected == 1 then
                TriggerServerEvent('LCV:admin:setInvis', checked)
            elseif selected == 2 then
                TriggerServerEvent('LCV:admin:setGod', checked)
            elseif selected == 3 then
                TriggerServerEvent('LCV:admin:setFly', checked)
            elseif selected == 4 then
                LABELS = checked and true or false
                if LABELS then RequestLabelsSnapshot() end
                TriggerServerEvent('lcv:labels:toggle', LABELS)
                notify(LABELS and 'Overhead-Labels aktiviert' or 'Overhead-Labels deaktiviert', LABELS and 'success' or 'info')
            end
        end,
        options = {
            { label = 'Unsichtbar',      checked = INVIS },
            { label = 'Godmode',         checked = GOD },
            { label = 'Flugmodus',       checked = FLY },
            { label = 'Overhead-Labels', checked = LABELS, description = 'Zeigt Name + Char-ID' },
            { label = 'Koordinaten anzeigen', description = 'Zeigt aktuelle Position im F8' },
        }
    }, function(selected)
        if selected == 5 then
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local heading = GetEntityHeading(ped)
            print(("Position: x=%.2f, y=%.2f, z=%.2f | Heading: %.2f")
                :format(coords.x, coords.y, coords.z, heading))
        end
    end)
end

RegisterNetEvent('LCV:menu:open:admin', function()
    registerAdminMenu()
    lib.showMenu('menu:admin')
end)