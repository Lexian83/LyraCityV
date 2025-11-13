-- housing/client.lua


local function openHousing()
    -- NUI anzeigen
    SendNUIMessage({ action = "openHousing" })

    -- ganz kleines Delay, damit Prop/Anim zuerst sitzt
    CreateThread(function()
        Wait(200)
        SetNuiFocus(true, true)
        SetNuiFocusKeepInput(true) -- erlaubt WASD + UI
    end)
    exports.inputmanager:LCV_OpenUI('Housing', { nui = true, keepInput = false })
    print("[HOUSING][CLIENT] Get Trigger to Open from Netevent")
end


local function closeHousing()
      -- NUI schließen
    SendNUIMessage({ action = "closeHousing" })
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    exports.inputmanager:LCV_CloseUI('Housing')
end
-- Events from your main Phone resource
RegisterNetEvent('LCV:Housing:Client:Show', function()
    openHousing()
    print("[HOUSING][CLIENT] Get Trigger to Open from inputmanager")
end)

RegisterNetEvent('LCV:Housing:Client:Hide', function()
    closeHousing()
end)

-- NUI callback (optional; harmless if also handled elsewhere)
RegisterNUICallback('LCV:Housing:Hide', function(_, cb)
        closeHousing()
end)

-- Cleanup
AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then
        closeHousing()
    end
end)
