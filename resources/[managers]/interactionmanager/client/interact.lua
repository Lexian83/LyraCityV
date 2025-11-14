-- lcv-interactionmanager/client/interact.lua
-- Routes the universal Use key to context-specific interactions (ATM first).

local STATIC_POINTS = {}


local ATM_MODELS = {
  `prop_atm_01`, `prop_atm_02`, `prop_atm_03`, `prop_fleeca_atm`
}

local VEND_SODA_MODELS = {
  `prop_vend_soda_01`,`prop_vend_soda_02`,`prop_vend_fridge01`,`m23_2_prop_m32_vend_drink_01a`,`sf_prop_sf_vend_drink_01a`,`ch_chint10_vending_smallroom_01`
}

local USE_RANGE = 1.5 -- meters

local USE_RANGE_NPC = 3.0 -- meters


RegisterNetEvent('lcv:interaction:client:setPoints', function(list)
  STATIC_POINTS = {}

  if type(list) ~= "table" then return end

  for _, p in ipairs(list) do
    if p.coords and p.type then
      STATIC_POINTS[#STATIC_POINTS+1] = {
        id = p.id,
        name = p.name or ("Point "..tostring(p.id)),
        description = p.description,
        type = p.type,
        coords = vector3(p.coords.x, p.coords.y, p.coords.z),
        radius = p.radius or USE_RANGE,
        data = p.data or {}
      }
    end
  end
end)


-- Beim Start einmal Punkte holen (falls Resource später startet)
CreateThread(function()
  Wait(1000)
  TriggerServerEvent('lcv:interaction:server:requestPoints')
end)




--- Returns entity and type if something valid is in range.
local function findInteractable()
  local ped = PlayerPedId()
  if not ped or ped == 0 then return nil end
  local pcoords = GetEntityCoords(ped)

  -- 1) ATMs (by nearby prop check)
  for _, model in ipairs(ATM_MODELS) do
    local atm = GetClosestObjectOfType(pcoords.x, pcoords.y, pcoords.z, USE_RANGE, model, false, false, false)
    if atm and atm ~= 0 and #(GetEntityCoords(atm) - pcoords) <= USE_RANGE then
      return atm, 'atm'
    end
  end

    -- 2) SODA VENDOR MACHINE (by nearby prop check)
  for _, model in ipairs(VEND_SODA_MODELS ) do
    local soda = GetClosestObjectOfType(pcoords.x, pcoords.y, pcoords.z, USE_RANGE, model, false, false, false)
    if soda and soda ~= 0 and #(GetEntityCoords(soda) - pcoords) <= USE_RANGE then
      return soda, 'soda'
    end
  end
  -- 3) NPCs (by coordinate list from npcmanager)
  local npcs = exports['npcmanager']:GetNPCPositions()
-- zuerst Array-Pfad (ipairs)
for _, npc in ipairs(npcs or {}) do
  if npc.coords and #(npc.coords - pcoords) <= USE_RANGE_NPC then
    return npc, 'npc'
  end
end

-- Fallback, falls doch mal eine Map reinkommt
for id, npc in pairs(npcs or {}) do
  if npc.coords and #(npc.coords - pcoords) <= USE_RANGE_NPC then
    npc.id = npc.id or id
    return npc, 'npc'
  end
end

  -- 4) Static Interactions aus Datenbank (z.B. MLO-PCs ohne echtes Objekt)
  for _, spot in ipairs(STATIC_POINTS) do
    local r = spot.radius or USE_RANGE
    if #(spot.coords - pcoords) <= r then
      --print(("[INTERACT] Hit STATIC_POINT id=%s type=%s dist=%.2f r=%.2f"):format(tostring(spot.id), tostring(spot.type), #(spot.coords - pcoords), r))
      return spot, spot.type
    end
  end


  -- More detectors later (NPCs, doors, shops, etc.)

  -- PCs, Terminals, Doors, 

  return nil
end


-- Main entry: triggered by inputmanager(keys.lua) on CMD:World:Interact
RegisterNetEvent('LCV:world:interact', function()
  local ped = PlayerPedId()
  if IsPedInAnyVehicle(ped, false) or IsEntityDead(ped) then return end

  local target, etype = findInteractable()

  if not target then
    lib.notify({ description = 'Nichts zum Interagieren in der Nähe.', type = 'info' })
    return
  end

  -- ATM
  if etype == 'atm' then
    TriggerEvent('LCV:atm:client:open', target)
    return

  -- PC (Static Point)
  elseif etype == 'pc' then
    local label = (type(target) == "table" and (target.description or target.name)) or "PC-Terminal"
    TriggerServerEvent('LCV:PC:Server:Show', target)
    lib.notify({ description = label.. ' | ' ..(target.data.faction or 'Keine Faction'), type = 'info' })
    return

      -- VENDOR SODA (Probs)
  elseif etype == 'soda' then
   lib.notify({ description = "Dies ist ein SODA AUTOMAT", type = "info" })
    return

      -- Housing Trigger
    elseif etype == 'house' then
      TriggerEvent('LCV:Housing:Client:Show',target)
      print(('HAUS DATEN: DATA: %s'):format(target.data))
      lib.notify({ description = "Dies ist ein HAUSTRIGGER", type = "info" })
    return

  -- NPC
  elseif etype == 'npc' then
    local npcType = target.type or "generic"
    local npcId   = target.id
    local npcName = target.name or "NPC"

    if npcType == "bank" then
      lib.notify({ description = ("Dieser NPC ist BANK | name: %s | ID:%s"):format(npcName,npcId), type = "info" })
    elseif npcType == "mechanic" then
      lib.notify({ description = ("Dieser NPC ist MECHANIK | name: %s | ID:%s"):format(npcName,npcId), type = "info" })
    elseif npcType == "airport" then
      lib.notify({ description = ("Dieser NPC ist AIRPORT | name: %s | ID:%s"):format(npcName,npcId), type = "info" })
    elseif npcType == "nurse" then
      lib.notify({ description = ("Dieser NPC ist KRANKENHAUS | name: %s | ID:%s"):format(npcName,npcId), type = "info" })
    elseif npcType == "cop" then
      lib.notify({ description = ("Dieser NPC ist POLIZEI | name: %s | ID:%s"):format(npcName,npcId), type = "info" })
    else
      lib.notify({ description = ("Dieser NPC hat noch keine Aktion. name: %s | ID:%s"):format(npcName,npcId), type = "info" })
    end
    return
  end

  -- Fallback: wir hatten zwar ein target, aber keinen Handler dafür
  lib.notify({
    description = ('Interaktionstyp "%s" ist noch nicht implementiert.'):format(tostring(etype)),
    type = 'info'
  })
end)
