-- lcv-Phone-prop/client.lua
-- Attaches a Phone prop + plays an upper-body anim while Phone UI is open.
-- Listens to 'LCV:Phone:Client:Show' / 'LCV:Phone:Client:Hide'.
-- This resource does NOT manage NUI focus; your main Phone script must handle SendNUIMessage + SetNuiFocus.

local ALLOW_WALK_WITH_UI = true   -- keep WASD movement while UI is open (blocks combat/aim only)

local isPhoneOpen = false
local PhoneProp = nil
-- NEU: Handy-Prop + Text-Lese-Idle
local PhoneModel = `prop_amb_phone`              -- gängiges, leichtes Phone-Prop
local animDict  = "cellphone@"                   -- Handy-Animdict
local animName  = "cellphone_text_read_base"     -- dezente Lesepose
--local animName = "cellphone_call_listen_base" -- Telefonieren


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

local function attachPhone()
    if DoesEntityExist(PhoneProp) then return end
    local ped = PlayerPedId()
    loadModel(PhoneModel)
    loadAnim(animDict)

    PhoneProp = CreateObject(PhoneModel, 0.0, 0.0, 0.0, true, true, false)
    -- Offsets tuned per Jens: rotations 190.0, 160.0, 180.0 (looks correct in-hand)
AttachEntityToEntity(PhoneProp, ped, GetPedBoneIndex(ped, 28422),
    0.0, 0.0, 0.0,
    0.0, 0.0, 0.0,
    true, true, false, true, 1, true
)


    TaskPlayAnim(ped, animDict, animName, 3.0, 3.0, -1, 49, 0, false, false, false)

    -- keep anim alive
    CreateThread(function()
        while isPhoneOpen do
            ensureUpperBodyLoop(ped)
            Wait(400)
        end
    end)
end

local function detachPhone()
    local ped = PlayerPedId()
    ClearPedSecondaryTask(ped)
    if DoesEntityExist(PhoneProp) then
        DeleteEntity(PhoneProp)
        PhoneProp = nil
    end
end

-- Movement filter while UI open (combat/aim off, WASD free)
CreateThread(function()
    while true do
        if isPhoneOpen and ALLOW_WALK_WITH_UI then
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



local function openPhone()
    -- NUI anzeigen
    SendNUIMessage({ action = "openPhone" })

    -- ganz kleines Delay, damit Prop/Anim zuerst sitzt
    CreateThread(function()
        Wait(200)
        SetNuiFocus(true, true)
        SetNuiFocusKeepInput(true) -- erlaubt WASD + UI
    end)
    exports.inputmanager:LCV_OpenUI('Phone', { nui = true, keepInput = false })
    print("[PHONE][CLIENT] Get Trigger to Open from Netevent")
end


local function closePhone()
      -- NUI schließen
    SendNUIMessage({ action = "closePhone" })
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    exports.inputmanager:LCV_CloseUI('Phone')
end
-- Events from your main Phone resource
RegisterNetEvent('LCV:Phone:Client:Show', function()
    if isPhoneOpen then return end
    isPhoneOpen = true
    attachPhone()
    openPhone()
    print("[PHONE][CLIENT] Get Trigger to Open from inputmanager")
end)

RegisterNetEvent('LCV:Phone:Client:Hide', function()
    if not isPhoneOpen then return end
    isPhoneOpen = false
    detachPhone()
    closePhone()
end)

-- NUI callback (optional; harmless if also handled elsewhere)
RegisterNUICallback('LCV:Phone:Hide', function(_, cb)
    if isPhoneOpen then
        isPhoneOpen = false
        detachPhone()
        closePhone()
    end
    cb({ ok = true })
end)

-- Cleanup
AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then
        detachPhone()
        closePhone()
    end
end)
