-- ### MULTI KEY FUNCTIONS ###
-- Key Routings
local keyRoutes = {
  ["+LCV_use"] = {
    default     = function() TriggerEvent('LCV:world:interact') end,
    inventory   = function() TriggerEvent('LCV:inv:useSelected') end,
    charselect  = function() TriggerEvent('LCV:charselect:confirm') end,
    charcreate  = function() TriggerEvent('LCV:char:toggleGender') end,
  }
}

-- Funktionen
local function runKeyRoute(cmd)
  local top = UI.current()
  local map = keyRoutes[cmd]
  if not map then return end
  if top and map[top] then map[top]() else map.default() end
end


-- Register Commands
RegisterCommand('+LCV_use', function() runKeyRoute('+LCV_use') end, false)
RegisterCommand('-LCV_use-dummy', function() end, false)

-- Key Mapping
RegisterKeyMapping('+LCV_use', 'Interagieren / Benutzen', 'keyboard', 'entf')

-- ############################
-- ### SINGLE KEY FUNCTIONS ###
-- ############################

-- Command + Keybinding (E) -- Inventar
RegisterCommand('CMD:World:Interact', function()
  if UI.anyOpen() then return end
  TriggerServerEvent('LCV:world:interact') -- Manager / Interactionmanager
end, false)
RegisterKeyMapping('CMD:World:Interact', 'Interaktion', 'keyboard', 'I')

-- Command + Keybinding (I) -- Inventar
RegisterCommand('CMD:OpenInventory', function()
  if UI.anyOpen() then return end
  TriggerServerEvent('ax-inv:Server:OpenInventory')
end, false)
RegisterKeyMapping('CMD:OpenInventory', 'Öffne das Inventar', 'keyboard', 'I')


-- Command + Keybinding (F12) -- SUpportmenu
RegisterCommand('LCV_openSYSTEM_admin', function()
    print('Command Trigger')
if UI.isOpen('chareditor') then
    print('chareditor OPEN')
end
if UI.isOpen('chareditor') then
    print('charselect OPEN')
end

 if UI.isOpen('chareditor') or UI.isOpen('charselect') then return end
 TriggerServerEvent('LCV:ADMIN:Server:Show')
  --TriggerServerEvent('LCV:menu:open:admin')LCV:ADMIN:Server:Show
end, false)
-- Achtung: F12 kann mit Steam-Screenshot kollidieren. Falls Probleme: z. B. auf F10 wechseln.
RegisterKeyMapping('LCV_openSYSTEM_admin', 'Support Menü', 'keyboard', 'F12')


-- Command + Keybinding (X) -- Wheelmenu

RegisterCommand('+LCV_open_wheel', function()
    if UI.anyOpen() then return end
    TriggerEvent('LCV:menu:open:wheel')
end, false)

RegisterCommand('-LCV_open_wheel', function()
 TriggerEvent('LCV:menu:close:wheel')
end, false)


RegisterKeyMapping('+LCV_open_wheel', 'Aktionsmenü', 'keyboard', 'X')

-- Command + Keybinding (UP) -- Phone
RegisterCommand('CMD:OpenPhone', function()
  if UI.anyOpen() then 
    print("[KEYS][CLIENT] ANY UI OPEN ... CANT OPEN")
    return 
    end
  TriggerServerEvent('LCV:Phone:Server:Show')
  print("[KEYS][CLIENT] Send Trigger to Client")
end, false)
RegisterKeyMapping('CMD:OpenPhone', 'Öffne das Handy', 'keyboard', 'UP')



-----------------------------------------------------------------------------
RegisterCommand('dbg_lookobj', function() -- das was am nächsten zu player ist
    local ped = PlayerPedId()
    local pcoords = GetEntityCoords(ped)
    local handle, obj = FindFirstObject()
    local success
    local closest, closestDist, closestModel

    if handle ~= -1 then
        repeat
            if DoesEntityExist(obj) then
                local oc = GetEntityCoords(obj)
                local dist = #(oc - pcoords)
                if dist < 3.0 then
                    if not closest or dist < closestDist then
                        closest = obj
                        closestDist = dist
                        closestModel = GetEntityModel(obj)
                    end
                end
            end
            success, obj = FindNextObject(handle)
        until not success
        EndFindObject(handle)
    end

    if closest then
        print(string.format(
            "Closest object: hash=%s name=%s dist=%.2f",
            closestModel,
            GetDisplayNameFromVehicleModel(closestModel), -- gibt Mist aus, aber Hash ist wichtig
            closestDist
        ))
    else
        print("Kein Objekt in Reichweite gefunden.")
    end
end, false)

-- Debug-Overlay Storage
local dbgObjects = {}
local dbgHighlightUntil = 0
local dbgLastRadius = 0.0

-- Thread zum Zeichnen der Outlines
CreateThread(function()
    while true do
        Wait(0)

        if dbgHighlightUntil > 0 then
            local now = GetGameTimer()
            if now <= dbgHighlightUntil then
                -- Outline-Farbe: grün
                SetEntityDrawOutlineColor(0, 255, 0, 255)

                for _, o in ipairs(dbgObjects) do
                    if DoesEntityExist(o.entity) then
                        SetEntityDrawOutline(o.entity, true)
                    end
                end
            else
                -- Zeit abgelaufen: Outlines wieder aus
                for _, o in ipairs(dbgObjects) do
                    if DoesEntityExist(o.entity) then
                        SetEntityDrawOutline(o.entity, false)
                    end
                end
                dbgObjects = {}
                dbgHighlightUntil = 0
            end
        end
    end
end)

RegisterCommand('dbg_objs', function(source, args)
    local ped = PlayerPedId()
    local pcoords = GetEntityCoords(ped)
    local radius = tonumber(args[1]) or 5.0 -- Standard-Radius 5m

    local handle, obj = FindFirstObject()
    if handle == -1 then
        print('[DBG_OBJS] FindFirstObject failed')
        return
    end

    local objects = {}
    local success = true

    while success do
        if DoesEntityExist(obj) then
            local ocoords = GetEntityCoords(obj)
            local dist = #(ocoords - pcoords)

            if dist <= radius then
                local model = GetEntityModel(obj)
                objects[#objects + 1] = {
                    entity = obj,
                    model = model,
                    dist = dist,
                    x = ocoords.x,
                    y = ocoords.y,
                    z = ocoords.z
                }
            end
        end

        success, obj = FindNextObject(handle)
    end

    EndFindObject(handle)

    table.sort(objects, function(a, b)
        return a.dist < b.dist
    end)

    print(('[DBG_OBJS] %d objects within %.1fm:'):format(#objects, radius))

    for i, o in ipairs(objects) do
        local model = o.model
        if model < 0 then
            model = model + 0x100000000 -- 32-Bit Fix
        end

        print(("[%02d] modelHash=0x%08X dist=%.2f coords=(%.2f, %.2f, %.2f)")
            :format(i, model, o.dist, o.x, o.y, o.z))
    end

    -- Highlight aktivieren (5 Sekunden)
    dbgObjects = objects
    dbgLastRadius = radius
    dbgHighlightUntil = GetGameTimer() + 5000

    print(string.format("[DBG_OBJS] Highlighting %d objects for 5s.", #objects))
end, false)


RegisterKeyMapping('dbg_objs', 'Aktionsmenü', 'keyboard', 'F5')