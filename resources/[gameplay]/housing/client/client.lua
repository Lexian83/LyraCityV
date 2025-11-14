-- resources/housing/client.lua

local currentHouse = {
    id   = nil,
    name = nil,
}

local function openHousing(data)
    currentHouse.id   = data and data.houseId   or nil
    currentHouse.name = data and data.houseName or nil

    SendNUIMessage({
        action    = "openHousing",
        houseId   = currentHouse.id,
        houseName = currentHouse.name,
    })

    CreateThread(function()
        Wait(200)
        SetNuiFocus(true, true)
        SetNuiFocusKeepInput(true)
    end)

    exports.inputmanager:LCV_OpenUI('Housing', { nui = true, keepInput = false })
    print("[HOUSING][CLIENT] Open UI (houseId="..tostring(currentHouse.id)..")")
end

local function closeHousing()
    SendNUIMessage({ action = "closeHousing" })
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    exports.inputmanager:LCV_CloseUI('Housing')
    currentHouse.id   = nil
    currentHouse.name = nil
end

RegisterNetEvent('LCV:Housing:Client:Show', function(data)
    openHousing(data)
end)

RegisterNetEvent('LCV:Housing:Client:Hide', function()
    closeHousing()
end)

RegisterNUICallback('LCV:Housing:Hide', function(_, cb)
    closeHousing()
    if cb then cb('ok') end
end)

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then
        closeHousing()
    end
end)
