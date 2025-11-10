-- client_camera.lua
-- Port von alt:V camera.js -> FiveM (Lua)

local camera = nil
local zpos = 0.0
local fov = 90.0
local startPosition = nil
local startCamPosition = nil
local timeBetweenAnimChecks = 0
local controlsThread = nil

local ROTATE_SPEED_RMB = 0.5   -- Rechtsklick-Drehen pro Frame (vorher 2.0)
local Z_STEP           = 0.004 -- Hoch/Runter pro Frame (vorher 0.01)
local Z_MIN            = -1.0  -- Untere Grenze (vorher -1.2)
local Z_MAX            =  1.2  -- Obere Grenze (vorher 1.2)

local FOV_STEP         = 1.0   -- Zoom-Schritt pro Frame (vorher 2.0)
local FOV_MIN          = 10.0  -- näher ran (vorher 10.0)
local FOV_MAX          = 130.0  -- weiter raus (vorher 130.0)

-- Utils: Cursor-Position (FiveM)
local function getCursorAndScreen()
    if GetNuiCursorPosition then
        local x, y = GetNuiCursorPosition()
        local sx, sy = GetActiveScreenResolution()
        return x or 0, y or 0, sx or 1920, sy or 1080
    else
        local nx = GetDisabledControlNormal(0, 239)
        local ny = GetDisabledControlNormal(0, 240)
        local sx, sy = GetActiveScreenResolution()
        return math.floor(nx * sx), math.floor(ny * sy), sx, sy
    end
end

local function ensureAnim(ped)
    if GetGameTimer() > timeBetweenAnimChecks then
        timeBetweenAnimChecks = GetGameTimer() + 1500
        if not IsEntityPlayingAnim(ped, 'mp_am_hold_up', 'handsup_base', 3) then
            RequestAnimDict('mp_am_hold_up')
            while not HasAnimDictLoaded('mp_am_hold_up') do Wait(0) end
            TaskPlayAnim(ped, 'mp_am_hold_up', 'handsup_base', 8.0, 8.0, -1, 2, 0.0, false, false, false)
        end
    end
end

function createPedEditCamera()
    local ped = PlayerPedId()
    local px, py, pz = table.unpack(GetEntityCoords(ped))
    startPosition = vector3(px, py, pz)

    if not DoesCamExist(camera) then
        local fx, fy, fz = table.unpack(GetEntityForwardVector(ped))
        local forwardCameraPosition = vector3(px + fx * 1.2, py + fy * 1.2, pz + zpos)
        fov = 90.0
        startCamPosition = forwardCameraPosition

        camera = CreateCamWithParams(
            'DEFAULT_SCRIPTED_CAMERA',
            forwardCameraPosition.x,
            forwardCameraPosition.y,
            forwardCameraPosition.z,
            0.0, 0.0, 0.0,
            fov,
            true, 0
        )

        PointCamAtCoord(camera, px, py, pz)
        SetCamActive(camera, true)
        RenderScriptCams(true, false, 0, true, false)
        Wait(0) -- kleiner Puffer für stabilen Renderstart
    end

    -- Steuerungs-Loop
    if not controlsThread then
        controlsThread = CreateThread(function()
            while DoesCamExist(camera) do
                -- Ped ggf. nach Modelwechsel neu holen
                local pedNow = PlayerPedId()

                HideHudAndRadarThisFrame()
                DisableAllControlActions(0)
                DisableAllControlActions(1)

                DisableControlAction(0, 0, true)
                DisableControlAction(0, 1, true)
                DisableControlAction(0, 2, true)
                DisableControlAction(0, 24, true)
                DisableControlAction(0, 25, true)
                DisableControlAction(0, 32, true) -- W
                DisableControlAction(0, 33, true) -- S
                DisableControlAction(0, 34, true) -- A
                DisableControlAction(0, 35, true) -- D

                local cx, cy, sx, sy = getCursorAndScreen()
                local pedHeading = GetEntityHeading(pedNow)

                -- Scroll Up (15)
                if IsDisabledControlPressed(0, 15) then
                    if cx < (sx / 2 + 250) and cx > (sx / 2 - 250) then
                        fov = fov - FOV_STEP
                        if fov < FOV_MIN then fov = FOV_MIN end
                        SetCamFov(camera, fov)
                        SetCamActive(camera, true)
                        RenderScriptCams(true, false, 0, true, false)
                    end
                end

                -- Scroll Down (16)
                if IsDisabledControlPressed(0, 16) then
                    if cx < (sx / 2 + 250) and cx > (sx / 2 - 250) then
                        fov = fov + FOV_STEP
                        if fov > FOV_MAX then fov = FOV_MAX end
                        SetCamFov(camera, fov)
                        SetCamActive(camera, true)
                        RenderScriptCams(true, false, 0, true, false)
                    end
                end

                -- W (hoch)
                if IsDisabledControlPressed(0, 32) then
                    zpos = zpos + Z_STEP
                    if zpos > Z_MAX then zpos = Z_MAX end
                    SetCamCoord(camera, startCamPosition.x, startCamPosition.y, startCamPosition.z + zpos)
                    PointCamAtCoord(camera, startPosition.x, startPosition.y, startPosition.z + zpos)
                    SetCamActive(camera, true)
                    RenderScriptCams(true, false, 0, true, false)
                end

                -- S (runter)
                if IsDisabledControlPressed(0, 33) then
                    zpos = zpos - Z_STEP
                    if zpos < Z_MIN then zpos = Z_MIN end
                    SetCamCoord(camera, startCamPosition.x, startCamPosition.y, startCamPosition.z + zpos)
                    PointCamAtCoord(camera, startPosition.x, startPosition.y, startPosition.z + zpos)
                    SetCamActive(camera, true)
                    RenderScriptCams(true, false, 0, true, false)
                end

                -- RMB (25): links/rechts drehen via Cursor X
                if IsDisabledControlPressed(0, 25) then
                    if cx < (sx / 2) then
                        SetEntityHeading(pedNow, pedHeading - ROTATE_SPEED_RMB)
                    elseif cx > (sx / 2) then
                        SetEntityHeading(pedNow, pedHeading + ROTATE_SPEED_RMB)
                    end
                end

                -- D (35) rotate +
                if IsDisabledControlPressed(0, 35) then
                    SetEntityHeading(pedNow, pedHeading + ROTATE_SPEED_RMB)
                end
                -- A (34) rotate -
                if IsDisabledControlPressed(0, 34) then
                    SetEntityHeading(pedNow, pedHeading - ROTATE_SPEED_RMB)
                end

                -- Animations-Check (alle ~1.5s)
                ensureAnim(pedNow)
                Wait(0)
            end
            controlsThread = nil
        end)
    end
end

function destroyPedEditCamera()
    local ped = PlayerPedId()
    if controlsThread then
        controlsThread = nil
    end

    if DoesCamExist(camera) then
        DestroyAllCams(true)
        RenderScriptCams(false, false, 0, false, false)
        camera = nil
    else
        DestroyAllCams(true)
        RenderScriptCams(false, false, 0, false, false)
    end

    zpos = 0.0
    fov = 90.0
    startPosition = nil
    startCamPosition = nil
    -- print('DESTROY PED EDIT CAM')
    ClearPedTasksImmediately(ped)
    ClearPedTasks(ped)
    ClearPedSecondaryTask(ped)
end

function setFov(value)
    fov = value + 0.0
    if DoesCamExist(camera) then
        SetCamFov(camera, fov)
        SetCamActive(camera, true)
        RenderScriptCams(true, false, 0, true, false)
    end
end

function setZPos(value)
    zpos = value + 0.0
    if DoesCamExist(camera) and startCamPosition and startPosition then
        SetCamCoord(camera, startCamPosition.x, startCamPosition.y, startCamPosition.z + zpos)
        PointCamAtCoord(camera, startPosition.x, startPosition.y, startPosition.z + zpos)
        SetCamActive(camera, true)
        RenderScriptCams(true, false, 0, true, false)
    end
end
