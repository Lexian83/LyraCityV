local INV_OPEN = false


local INV_OPEN = false

local function OpenInventoryUI(items, other)
    INV_OPEN = true
    SendNUIMessage({
        action = 'open',
        items = items,
        other = other,
        plyweight = GetPlayerWeight()
    })
    -- Fokus sauber setzen
    SetNuiFocus(true, true)               -- Cursor + Fokus
    -- WICHTIG: kein KeepInput-Dauerzustand hier
    exports.inputmanager:LCV_OpenUI('inventory', { nui = true, keepInput = false })
end

local function CloseInventoryUI()
    if not INV_OPEN then return end
    INV_OPEN = false
    SendNUIMessage({ action = 'close' })
    -- Fokus freigeben
    SetNuiFocus(false, false)
    -- Waffenrad wieder erlauben – falls du es im UI-Loop sperrst
    HudWeaponWheelIgnoreSelection(false)
    exports.inputmanager:LCV_CloseUI('inventory')
    -- Kofferraum zu (deins)
    CloseTrunk()
end


InvFunctions = GetInventoryFunctions()
CreateThread(function()
    while true do
        if INV_OPEN then
            Wait(0)
            -- Hotbar 1..6 blocken (wie bisher)
            for i = 1, 6 do
                DisableControlAction(0, Keys[tostring(i)], true)
                if IsDisabledControlJustPressed(0, Keys[tostring(i)]) then
                    TriggerServerEvent("ax-inv:Server:UseItem", { inventory = "player", item = i })
                end
            end
             if IsControlJustReleased(0,Keys['G']) then
            local ped = GetPlayerPed(-1) 
            local coords = GetEntityCoords(ped)
            if IsPedInAnyVehicle(GetPlayerPed(-1)) then
                local veh = GetVehiclePedIsIn(ped,false)
                local plate = GetVehicleNumberPlateText(veh):gsub(' ','')
                TriggerServerEvent('ax-inv:Server:OpenInventory','GloveBox-'..plate,{slots=5})
            else 
                local vehicle = GetClosestVehicle(GetEntityCoords(PlayerPedId()), 5.0, 0, 127)
                if vehicle ~= 0 and vehicle ~= nil then
                    local trunkcoords = GetOffsetFromEntityInWorldCoords(vehicle, 0, -2.5, 0)
                    if (IsBackEngine(GetEntityModel(vehicle))) then
                        trunkcoords = GetOffsetFromEntityInWorldCoords(vehicle, 0, 2.5, 0)
                    end
                    if (GetDistanceBetweenCoords(coords.x, coords.y, coords.z, trunkcoords) < 2.0) and not IsPedInAnyVehicle(ped) then
                        if GetVehicleDoorLockStatus(vehicle) < 2 then
                            local plate = GetVehicleNumberPlateText(vehicle):gsub(' ','')
                            TriggerServerEvent('ax-inv:Server:OpenInventory','Trunk-'..plate,{slots=20})
                            OpenTrunk()
                        end
                    end
                end
            end
        end
            -- Falls du TAB/Waffenrad im Inventar bewusst blocken willst, dann NUR hier:
            -- DisableControlAction(0, 37, true)                 -- TAB
            -- HudWeaponWheelIgnoreSelection(true)
            -- BlockWeaponWheelThisFrame()

            -- (optional) ESC ins UI routen, aber Game-ESC blocken:
            DisableControlAction(0, 200, true) -- Pause/ESC
        else
            Wait(250)
        end
    end
end)


RegisterNetEvent('ax-inv:Client:OpenInventory')
AddEventHandler('ax-inv:Client:OpenInventory', function(items, other)
    OpenInventoryUI(items, other)
end)


RegisterNetEvent('ax-inv:Client:RefreshInventory')
AddEventHandler('ax-inv:Client:RefreshInventory',function(other)
    SendNUIMessage({
        action = 'refresh',
        items = InvFunctions.GetPlayer().inventory,
        other = other,
        plyweight = GetPlayerWeight()
    })
end)

RegisterNetEvent('ax-inv:Client:CloseInventory')
AddEventHandler('ax-inv:Client:CloseInventory',function()
    SendNUIMessage({
        action = 'close'
    })
    SetNuiFocus(false,false)
    CloseTrunk()
    exports.inputmanager:LCV_CloseUI('inventory')
end)

RegisterNUICallback('SetInventoryData',function(data)
    if not data.toinventory or not data.frominventory then return end
    if string.find(data.frominventory,'Other') or string.find(data.toinventory,'Other') then 
        TriggerServerEvent('ax-inv:Server:SetInventoryData:B/WPlayers',data)
    else
        TriggerServerEvent('ax-inv:Server:SetInventoryData',data)
    end
end)
RegisterNUICallback('CloseInventory', function()
    CloseInventoryUI()
end)


RegisterNUICallback('UseItem',function(data)
    TriggerServerEvent("ax-inv:Server:UseItem",data)
end)

RegisterNUICallback('ChangeVariation',function(data)
    ExecuteCommand(data.component)
end)

RegisterNUICallback('CraftItem', function(data)
    TriggerServerEvent('ax-inv:Server:CraftItem',data)
end)
AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then
        -- harter Reset, falls irgendetwas offen war
        SetNuiFocus(false, false)
        HudWeaponWheelIgnoreSelection(false)
    end
end)
