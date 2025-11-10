local showing = false
local accountid = 0

-- Public event to open with payload
RegisterNetEvent('LCV:charselect:show', function(payload,account_id)
	exports.inputmanager:LCV_OpenUI('charselect')
    SendNUIMessage({ action = 'setData', payload = payload })
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open' })
    showing = true
    -- print('Open Charselector')
        -- WICHTIG: Loading-Screen wirklich schließen
    ShutdownLoadingScreen()
    ShutdownLoadingScreenNui()
    DoScreenFadeIn(500)
	accountid = account_id
end)

RegisterNetEvent('LCV:charselect:close', function()
	exports.inputmanager:LCV_CloseUI('charselect')
       -- NUI zu
    SendNUIMessage({ action = 'close' })
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    SetPauseMenuActive(false)
    showing = false

    -- Spieler wieder freigeben
    local ped = PlayerPedId()
    FreezeEntityPosition(ped, false)
    
    -- print('CHAR SELECTOR CLOSE EVENT')
end)

-- ESC to close
CreateThread(function()
    while true do
        if showing then
            DisableControlAction(0, 1, true)  -- LookLeftRight
            DisableControlAction(0, 2, true)  -- LookUpDown
            DisableControlAction(0, 142, true) -- Melee
            DisableControlAction(0, 18, true) -- Enter
        end
        Wait(0)
    end
end)

-- NUI Callbacks
RegisterNUICallback('createCharacter', function(_, cb)
    -- TriggerEvent('LCV:charselect:create')
    -- TriggerServerEvent('LCV:charselect:create')
    TriggerEvent('LCV:charselect:close')
    -- print('CHAR SELECTOR CLOSE TRIGGER')
    -- TriggerEvent('LCV:editor:open')
	TriggerServerEvent('character:Edit',_,accountid)
    -- print('Open Char Editor')
    cb({ ok = true })
end)

RegisterNUICallback('selectCharacter', function(data, cb)
     TriggerEvent('LCV:charselect:close')
    TriggerServerEvent('LCV:selectCharacterX', data.id)
     -- print('CHAR SELECTOR Select TRIGGER: ', data.id)
    cb({ ok = true })
end)

RegisterNUICallback('close', function(_, cb)
    SetNuiFocus(false, false)
    showing = false
    TriggerEvent('LCV:charselect:closed')
    cb({ ok = true })
end)
-- Eventhandler

CreateThread(function()
    -- Warte bis Network & Ped stehen
    while not NetworkIsPlayerActive(PlayerId()) do Wait(50) end
    while not DoesEntityExist(PlayerPedId()) do Wait(50) end
    -- Optional: warten bis nicht tot/ohne Kollision usw.
    while IsEntityDead(PlayerPedId()) do Wait(50) end
    -- kleine Gnadenfrist, bis Streaming/Kollision sicher ist
    Wait(200)
       local ped = GetPlayerPed(-1)    -- get local ped
        FreezeEntityPosition(ped, true)   -- freeze player

        -- trigger your event here / or whatever you need to load the map / Citizen.Wait instruction etc
        TriggerServerEvent('LCV:playerSpawned')
        LoadAllObjectsNow()
        -- print('Player Spawned!')
end)

