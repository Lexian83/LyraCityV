-- resources/housing/client.lua

local currentHouse = {
    id          = nil,
    name        = nil,
    ownerStatus = nil,
    ownerName   = nil,  -- 👈 NEU
    lockState   = 0,
    secured     = 0,
    pincode     = 0,
    isOwner     = false,
}

local function openHousing(data)
    currentHouse.id          = data and data.houseId     or nil
    currentHouse.name        = data and data.houseName   or nil
    currentHouse.ownerStatus = data and data.ownerStatus or nil
    currentHouse.ownerName   = data and data.ownerName    or nil  -- 👈 NEU
    currentHouse.lockState   = data and tonumber(data.lockState) or 0
    currentHouse.secured     = data and tonumber(data.secured)   or 0
    currentHouse.pincode     = data and tonumber(data.pincode)   or 0
    currentHouse.isOwner     = data and (data.isOwner == true or data.isOwner == 1) or false

    SendNUIMessage({
        action      = "openHousing",
        houseId     = currentHouse.id,
        houseName   = currentHouse.name,
        ownerStatus = currentHouse.ownerStatus,
        ownerName   = currentHouse.ownerName,   -- 👈 NEU
        lockState   = currentHouse.lockState,
        secured     = currentHouse.secured,
        pincode     = currentHouse.pincode,
        isOwner     = currentHouse.isOwner,
    })

    CreateThread(function()
        Wait(200)
        SetNuiFocus(true, true)
        SetNuiFocusKeepInput(false)
    end)

    exports.inputmanager:LCV_OpenUI('Housing', { nui = true, keepInput = false })

    print(("[HOUSING][CLIENT] Open UI (houseId=%s lockState=%s secured=%s pincode=%s isOwner=%s)")
        :format(
            tostring(currentHouse.id),
            tostring(currentHouse.lockState),
            tostring(currentHouse.secured),
            tostring(currentHouse.pincode),
            tostring(currentHouse.isOwner)
        ))
end

local function closeHousing()
    SendNUIMessage({ action = "closeHousing" })
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    exports.inputmanager:LCV_CloseUI('Housing')

    currentHouse.id          = nil
    currentHouse.name        = nil
    currentHouse.ownerStatus = nil
    currentHouse.ownerName   = nil   -- 👈 NEU
    currentHouse.lockState   = 0
    currentHouse.secured     = 0
    currentHouse.pincode     = 0
    currentHouse.isOwner     = false
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

-- 🔒 NUI → Server: Lock-State ändern
RegisterNUICallback('LCV:Housing:ToggleLock', function(data, cb)
    local houseId = currentHouse.id
    if not houseId then
        print("[HOUSING][CLIENT] ToggleLock: kein aktuelles Haus, Abbruch.")
        if cb then cb('no-house') end
        return
    end

    local desired = data and data.state
    desired = tonumber(desired)

    if desired ~= 0 and desired ~= 1 then
        desired = (currentHouse.lockState == 1) and 0 or 1
    end

    currentHouse.lockState = desired

    print(("[HOUSING][CLIENT] ToggleLock -> houseId=%s state=%s")
        :format(tostring(houseId), tostring(desired)))

    -- an HouseManager (SSOT) weiterreichen
    TriggerServerEvent('LCV:house:setLockState', houseId, desired)

    if cb then cb('ok') end
end)

-- Optional: wenn HouseManager den Lock-State broadcastet
RegisterNetEvent('LCV:house:lockChanged', function(houseId, lock, secured, pincode)
    houseId = tonumber(houseId)
    if not houseId or not currentHouse.id then return end
    if tonumber(currentHouse.id) ~= houseId then return end

    currentHouse.lockState = tonumber(lock)    or currentHouse.lockState
    currentHouse.secured   = tonumber(secured) or currentHouse.secured
    currentHouse.pincode   = tonumber(pincode) or currentHouse.pincode

    SendNUIMessage({
        action      = "openHousing",
        houseId     = currentHouse.id,
        houseName   = currentHouse.name,
        ownerStatus = currentHouse.ownerStatus,
        ownerName   = currentHouse.ownerName,   -- 👈 NEU
        lockState   = currentHouse.lockState,
        secured     = currentHouse.secured,
        pincode     = currentHouse.pincode,
        isOwner     = currentHouse.isOwner,
    })
end)

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then
        closeHousing()
    end
end)
