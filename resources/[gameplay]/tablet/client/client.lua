-- lcv-tablet-prop/client.lua
-- Attaches a tablet prop + plays an upper-body anim while Tablet UI is open.
-- Listens to 'LCV:Tablet:Client:Show' / 'LCV:Tablet:Client:Hide'.
-- This resource does NOT manage NUI focus; your main tablet script must handle SendNUIMessage + SetNuiFocus.

local ALLOW_WALK_WITH_UI = true   -- keep WASD movement while UI is open (blocks combat/aim only)

local isTabletOpen = false
local tabletProp = nil
local tabletModel = `prop_cs_tablet`      -- alt: `prop_tablet_02`
local animDict = "amb@code_human_in_bus_passenger_idles@female@tablet@base"
local animName = "base"

local function loadModel(model)
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(5) end
end

local function loadAnim(dict)
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do Wait(5) end
end

local function ensureUpperBodyLoop(ped)
    if not IsEntityPlayingAnim(ped, animDict, animName, 3) then
        TaskPlayAnim(ped, animDict, animName, 3.0, 3.0, -1, 49, 0, false, false, false)
    end
end

local function attachTablet()
    if DoesEntityExist(tabletProp) then return end
    local ped = PlayerPedId()
    loadModel(tabletModel)
    loadAnim(animDict)

    tabletProp = CreateObject(tabletModel, 0.0, 0.0, 0.0, true, true, false)
    -- Bone 60309 = right hand
    -- Offsets tuned per Jens: rotations 190.0, 160.0, 180.0 (looks correct in-hand)
    AttachEntityToEntity(tabletProp, ped, GetPedBoneIndex(ped, 60309),
        0.03, 0.002, -0.02,         -- posX, posY, posZ
        190.0, 160.0, 180.0,        -- rotX, rotY, rotZ  (degrees)
        true, true, false, true, 1, true)

    TaskPlayAnim(ped, animDict, animName, 3.0, 3.0, -1, 49, 0, false, false, false)

    -- keep anim alive
    CreateThread(function()
        while isTabletOpen do
            ensureUpperBodyLoop(ped)
            Wait(400)
        end
    end)
end

local function detachTablet()
    local ped = PlayerPedId()
    ClearPedSecondaryTask(ped)
    if DoesEntityExist(tabletProp) then
        DeleteEntity(tabletProp)
        tabletProp = nil
    end
end

-- Movement filter while UI open (combat/aim off, WASD free)
CreateThread(function()
    while true do
        if isTabletOpen and ALLOW_WALK_WITH_UI then
            DisableControlAction(0, 24, true) -- attack
            DisableControlAction(0, 25, true) -- aim
            DisableControlAction(0, 45, true) -- reload
            DisableControlAction(0, 140, true) -- melee
            DisableControlAction(0, 141, true)
            DisableControlAction(0, 142, true)
            DisableControlAction(0, 257, true) -- attack2
            DisableControlAction(0, 263, true) -- melee2
        end
        Wait(0)
    end
end)



local function openTablet()
    -- NUI anzeigen
    SendNUIMessage({ action = "openTablet" })

    -- ganz kleines Delay, damit Prop/Anim zuerst sitzt
    CreateThread(function()
        Wait(200)
        SetNuiFocus(true, true)
        SetNuiFocusKeepInput(true) -- erlaubt WASD + UI
    end)
    exports.inputmanager:LCV_OpenUI('Tablet', { nui = true, keepInput = false })
end


local function closeTablet()
      -- NUI schließen
    SendNUIMessage({ action = "closeTablet" })
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    exports.inputmanager:LCV_CloseUI('Tablet')
end
-- Events from your main tablet resource
RegisterNetEvent('LCV:Tablet:Client:Show', function()
    if isTabletOpen then return end
    isTabletOpen = true
    attachTablet()
    openTablet()
end)

RegisterNetEvent('LCV:Tablet:Client:Hide', function()
    if not isTabletOpen then return end
    isTabletOpen = false
    detachTablet()
    closeTablet()
end)

-- NUI callback (optional; harmless if also handled elsewhere)
RegisterNUICallback('LCV:Tablet:Hide', function(_, cb)
    if isTabletOpen then
        isTabletOpen = false
        detachTablet()
        closeTablet()
    end
    cb({ ok = true })
end)

-- Cleanup
AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then
        detachTablet()
        closeTablet()
    end
end)
