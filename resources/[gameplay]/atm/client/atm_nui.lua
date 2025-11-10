-- atm/client/atm_nui.lua
-- NUI glue for ATM Vue app

-- === ATM NUI + Animation ===

local atmUIOpen = false
local atmEntity = 0
local atmCtrlThread = nil

-- Stellt den Spieler exakt vor den übergebenen ATM und startet die ATM-Loop
local function startAtmAnim(entity)
  local ped = PlayerPedId()
  if IsPedInAnyVehicle(ped, false) then return end

  -- Nur ausrichten, wenn wir eine gültige ATM-Entity bekommen
  if entity and entity ~= 0 and DoesEntityExist(entity) then
    local ax, ay, az = table.unpack(GetEntityCoords(entity))
    local aheading    = GetEntityHeading(entity)

    -- Punkt ~0.55m VOR dem ATM (in Blickrichtung des ATMs)
    -- (wir nutzen die Heading, damit's mit allen ATM-Props sauber passt)
    local rad    = math.rad(aheading)
    local fwdX   = -math.sin(rad)   -- Richtung "vor" dem ATM
    local fwdY   =  math.cos(rad)
    local dist   = -0.55            -- Abstand nach Bedarf 0.45–0.75
    local tx     = ax + fwdX * dist
    local ty     = ay + fwdY * dist

    -- Sichere Bodenhöhe ermitteln
    local _, groundZ = GetGroundZFor_3dCoord(tx, ty, az + 1.0, false)
    local tz = (groundZ ~= 0.0 and groundZ) or az

    -- Nur teleportieren, wenn der Spieler halbwegs in der Nähe ist (Vermeidet "magisches" Beamen quer über die Map)
    local px, py, pz = table.unpack(GetEntityCoords(ped))
    if #(vector3(px, py, pz) - vector3(ax, ay, az)) < 3.0 then
      SetEntityCoords(ped, tx, ty, tz, false, false, false, true)
      SetEntityHeading(ped, aheading)
    else
      -- ist man weit weg, drehen wir ihn wenigstens korrekt
      SetEntityHeading(ped, aheading)
    end

    -- Blick zum Automaten (reiner Kosmetik)
    TaskLookAtEntity(ped, entity, 2000, 2048, 2)
  end

  -- Waffe ausblenden + sauberes Starten der Szene
  SetPedCurrentWeaponVisible(ped, false, true, true, true)
  ClearPedTasksImmediately(ped)
  TaskStartScenarioInPlace(ped, "PROP_HUMAN_ATM", 0, true)
end


local function stopAtmAnim()
  local ped = PlayerPedId()
  ClearPedTasks(ped)
  SetPedCurrentWeaponVisible(ped, true, true, true, true)
end

local function startControlBlock()
  if atmCtrlThread then return end
  atmCtrlThread = CreateThread(function()
    while atmUIOpen do
      -- Bewegung & Kampf deaktivieren, damit die Szene “sauber” bleibt
      DisableControlAction(0, 30, true)  -- Move LR
      DisableControlAction(0, 31, true)  -- Move UD
      DisableControlAction(0, 21, true)  -- Sprint
      DisableControlAction(0, 22, true)  -- Jump
      DisableControlAction(0, 24, true)  -- Attack
      DisableControlAction(0, 25, true)  -- Aim
      DisableControlAction(0, 37, true)  -- Select Weapon
      DisableControlAction(0, 44, true)  -- Cover
      DisableControlAction(0, 140, true) -- Melee
      DisableControlAction(0, 141, true)
      DisableControlAction(0, 142, true)
      DisableControlAction(0, 143, true)
      -- Kamera drehen darf bleiben; wenn nicht gewünscht:
      -- DisableControlAction(0, 1, true)  -- Look LR
      -- DisableControlAction(0, 2, true)  -- Look UD
      Wait(0)
    end
    atmCtrlThread = nil
  end)
end



local function openATM(entity)
  atmUIOpen = true
  atmEntity = entity or 0
  SetNuiFocus(true, true)
  SendNUIMessage({ type = 'atm:open', view = 'dashboard' })
  startAtmAnim(atmEntity)
  startControlBlock()
  exports.inputmanager:LCV_OpenUI('ATM', { nui = true, keepInput = false })
end
local function closeATM()
  atmUIOpen = false
  SetNuiFocus(false, false)
  stopAtmAnim()
  SendNUIMessage({ type = 'atm:close' })
  exports.inputmanager:LCV_CloseUI('ATM')
end


RegisterNetEvent('LCV:atm:client:open', function(entity)
  -- entity = ATM Prop (kann 0 sein), kommt von deinem Interaction-Manager
  openATM(entity)
end)

RegisterNUICallback('atm:close', function(data, cb)
  closeATM()
  cb(true)
end)

RegisterNUICallback('atm:getAccount', function(data, cb)
  local res = lib.callback.await('LCV:atm:server:getAccount', false)
  cb(res or { ok=false, err='no account' })
end)

RegisterNUICallback('atm:getStatement', function(data, cb)
  local limit = tonumber(data and data.limit) or 25
  local offset = tonumber(data and data.offset) or 0
  local res = lib.callback.await('LCV:atm:server:getStatement', false, limit, offset)
  cb(res or {})
end)

RegisterNUICallback('atm:deposit', function(data, cb)
  local amount = tonumber(data and data.amount) or 0
  local ok, newBal, msg = lib.callback.await('LCV:atm:server:deposit', false, amount)
  if ok then
    SendNUIMessage({ type='atm:update', balance=newBal })
  end
  cb({ ok, newBal, msg })
end)

RegisterNUICallback('atm:withdraw', function(data, cb)
  local amount = tonumber(data and data.amount) or 0
  local ok, newBal, msg = lib.callback.await('LCV:atm:server:withdraw', false, amount)
  if ok then
    SendNUIMessage({ type='atm:update', balance=newBal })
  end
  cb({ ok, newBal, msg })
end)