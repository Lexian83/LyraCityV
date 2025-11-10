-- lcv-tablet-prop/client.lua
-- Attaches a tablet prop + plays an upper-body anim while Tablet UI is open.
-- Listens to 'LCV:Tablet:Client:Show' / 'LCV:Tablet:Client:Hide'.
-- This resource does NOT manage NUI focus; your main tablet script must handle SendNUIMessage + SetNuiFocus.

local isPcOpen = false


-- Movement filter while UI open (combat/aim off, WASD free)
CreateThread(function()
    while true do
        if isPcOpen then
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



local function openPC(data)
    local faction = data and data.data and data.data.faction or nil
    local officerName = data and data.data and data.data.officerName or nil
    local location = data and data.data and data.data.location or nil

    SendNUIMessage({
        action = "openPC",
        faction = faction,
        officerName = officerName,
        location = location
    })

    print("[PC][CLIENT] NUI openPC officerName:", officerName)


    CreateThread(function()
        Wait(200)
        SetNuiFocus(true, true)
        SetNuiFocusKeepInput(false)
    end)

    exports.inputmanager:LCV_OpenUI('PC-System', { nui = true, keepInput = false })
end




local function closePC()
      -- NUI schließen
    SendNUIMessage({ action = "closePC" })
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    exports.inputmanager:LCV_CloseUI('PC-System')
end
-- Events from your main tablet resource
RegisterNetEvent('LCV:PC:Client:Show', function(data)
    if isPcOpen then return end
    isPcOpen = true
    openPC(data)
end)

RegisterNetEvent('LCV:PC:Client:Hide', function()
    if not isPcOpen then return end
    isPcOpen = false
    closePC()
end)

-- NUI callback (optional; harmless if also handled elsewhere)
RegisterNUICallback('LCV:PC:Hide', function(_, cb)
      if not isPcOpen then return end
    isPcOpen = false
    closePC()
    cb({ ok = true })
end)


-- Cleanup
AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then
        closePC()
    end
end)
