-- resources/adminsystem/server/housing.lua
-- Thin-Proxy auf houseManager (keine SQL mehr hier!)

local function getCharLVL(src)
  local ok, d = pcall(function()
    return exports['playerManager'] and exports['playerManager']:GetPlayerData(src) or nil
  end)
  if not ok or not d or not d.character then return 0 end
  return tonumber(d.character.level) or 0
end

local function hasAdminPermission(src, required)
  local lvl = getCharLVL(src)
  required = tonumber(required) or 10
  return lvl >= required
end

-- ===== HOUSES =====
lib.callback.register('LCV:ADMIN:Houses:GetAll', function(source)
  if not hasAdminPermission(source, 10) then
    return { ok=false, error='Keine Berechtigung', houses = {} }
  end
  local hm = exports['houseManager']
  local rows = hm and hm:Admin_Houses_GetAll() or {}
  return { ok=true, houses=rows or {} }
end)

lib.callback.register('LCV:ADMIN:Houses:Add', function(source, data)
  if not hasAdminPermission(source, 10) then
    return { ok=false, error='Keine Berechtigung' }
  end
  local hm = exports['houseManager']
  local res = hm and hm:Admin_Houses_Add(data) or { ok=false, error='HM offline' }
  return res
end)

lib.callback.register('LCV:ADMIN:Houses:Update', function(source, data)
  if not hasAdminPermission(source, 10) then
    return { ok=false, error='Keine Berechtigung' }
  end
  local hm = exports['houseManager']
  local res = hm and hm:Admin_Houses_Update(data) or { ok=false, error='HM offline' }
  return res
end)

lib.callback.register('LCV:ADMIN:Houses:Delete', function(source, data)
  if not hasAdminPermission(source, 10) then
    return { ok=false, error='Keine Berechtigung' }
  end
  local hm = exports['houseManager']
  local res = hm and hm:Admin_Houses_Delete(data) or { ok=false, error='HM offline' }
  return res
end)

lib.callback.register('LCV:ADMIN:Houses:ResetPincode', function(source, data)
  if not hasAdminPermission(source, 10) then
    return { ok=false, error='Keine Berechtigung' }
  end
  local hm = exports['houseManager']
  local res = hm and hm:Admin_Houses_ResetPincode(data) or { ok=false, error='HM offline' }
  return res
end)

-- Teleport bleibt lokal (kein DB)
RegisterNetEvent('LCV:ADMIN:Houses:Teleport', function(id, x, y, z)
  local src = source
  if not hasAdminPermission(src, 10) then return end
  x, y, z = tonumber(x), tonumber(y), tonumber(z)
  if not x or not y or not z then return end
  local ped = GetPlayerPed(src)
  if ped ~= 0 then
    SetEntityCoords(ped, x, y, z, false, false, false, true)
    TriggerClientEvent('LCV:ADMIN:Interactions:NotifyTeleport', src, { x=x, y=y, z=z })
  end
end)

-- ===== HOUSES IPL =====
lib.callback.register('LCV:ADMIN:HousesIPL:GetAll', function(source)
  if not hasAdminPermission(source, 10) then
    return { ok=false, error='Keine Berechtigung', ipls = {} }
  end
  local hm = exports['houseManager']
  local rows = hm and hm:Admin_HousesIPL_GetAll() or {}
  return { ok=true, ipls=rows or {} }
end)

lib.callback.register('LCV:ADMIN:HousesIPL:Add', function(source, data)
  if not hasAdminPermission(source, 10) then
    return { ok=false, error='Keine Berechtigung' }
  end
  local hm = exports['houseManager']
  local res = hm and hm:Admin_HousesIPL_Add(data) or { ok=false, error='HM offline' }
  return res
end)

lib.callback.register('LCV:ADMIN:HousesIPL:Update', function(source, data)
  if not hasAdminPermission(source, 10) then
    return { ok=false, error='Keine Berechtigung' }
  end
  local hm = exports['houseManager']
  local res = hm and hm:Admin_HousesIPL_Update(data) or { ok=false, error='HM offline' }
  return res
end)

lib.callback.register('LCV:ADMIN:HousesIPL:Delete', function(source, data)
  if not hasAdminPermission(source, 10) then
    return { ok=false, error='Keine Berechtigung' }
  end
  local hm = exports['houseManager']
  local res = hm and hm:Admin_HousesIPL_Delete(data) or { ok=false, error='HM offline' }
  return res
end)

-- Teleport bleibt lokal (kein DB)
RegisterNetEvent('LCV:ADMIN:HousesIPL:Teleport', function(id, x, y, z)
  local src = source
  if not hasAdminPermission(src, 10) then return end
  x, y, z = tonumber(x), tonumber(y), tonumber(z)
  if not x or not y or not z then return end
  local ped = GetPlayerPed(src)
  if ped ~= 0 then
    SetEntityCoords(ped, x, y, z, false, false, false, true)
    TriggerClientEvent('LCV:ADMIN:Interactions:NotifyTeleport', src, { x=x, y=y, z=z })
  end
end)
