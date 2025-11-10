local showing = false
local accountid = 0

-- Öffnet die Charselect-UI mit Payload vom Server
RegisterNetEvent('LCV:charselect:show', function(payload, account_id)
    accountid = account_id or 0
    showing = true

    -- Dein Input-Manager / NUI öffnen
    exports.inputmanager:LCV_OpenUI('charselect')

    SendNUIMessage({ action = 'setData', payload = payload })
    SendNUIMessage({ action = 'open' })

    SetNuiFocus(true, true)

    -- Loading-Screen schließen
    ShutdownLoadingScreen()
    ShutdownLoadingScreenNui()
    DoScreenFadeIn(500)
end)

-- Schließt die Charselect-UI
RegisterNetEvent('LCV:charselect:close', function()
    showing = false

    exports.inputmanager:LCV_CloseUI('charselect')

    SendNUIMessage({ action = 'close' })
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    SetPauseMenuActive(false)

    local ped = PlayerPedId()
    FreezeEntityPosition(ped, false)
end)

-- ESC / Controls während Charselect blocken
CreateThread(function()
    while true do
        if showing then
            DisableControlAction(0, 1, true)   -- LookLeftRight
            DisableControlAction(0, 2, true)   -- LookUpDown
            DisableControlAction(0, 142, true) -- Melee
            DisableControlAction(0, 18, true)  -- Enter
        end
        Wait(0)
    end
end)

-- ========== NUI Callbacks ==========

-- Neuer Charakter -> dein Editor
RegisterNUICallback('createCharacter', function(_, cb)
    -- UI schließen
    TriggerEvent('LCV:charselect:close')

    -- Öffnet deinen Character-Editor (bestehendes System)
    -- Der Editor sollte am Ende 'LCV:Player:CreateCharacter' triggern.
    TriggerServerEvent('character:Edit', _, accountid)

    cb({ ok = true })
end)

-- Charakter auswählen -> PlayerManager
RegisterNUICallback('selectCharacter', function(data, cb)
    if not data or not data.id then
        cb({ ok = false, error = "no id" })
        return
    end

    -- UI schließen
    TriggerEvent('LCV:charselect:close')

    -- An Charselect-Server, der es an PlayerManager weitergibt
    TriggerServerEvent('LCV:charselect:select', data.id)

    cb({ ok = true })
end)

-- UI per Close-Button schließen
RegisterNUICallback('close', function(_, cb)
    showing = false
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    SetPauseMenuActive(false)

    TriggerEvent('LCV:charselect:closed')
    cb({ ok = true })
end)

-- ========== Initialer Trigger nach Join ==========
-- Lädt Charselect nach dem ersten Spawn vom Server (auth → charselect:load)

CreateThread(function()
    while not NetworkIsPlayerActive(PlayerId()) do Wait(50) end
    while not DoesEntityExist(PlayerPedId()) do Wait(50) end
    while IsEntityDead(PlayerPedId()) do Wait(50) end
    Wait(200)

    local ped = PlayerPedId()
    FreezeEntityPosition(ped, true)

    -- Triggert auf dem Server:
    -- auth → LCV:playerSpawned → LCV:charselect:load → LCV:charselect:show
    TriggerServerEvent('LCV:playerSpawned')
    LoadAllObjectsNow()
end)
