-- resources/houseManager/server/exports.lua
print('houseManager/server/exports.lua live = 2025-11-13-SSOT-ADMIN-B')

local function toN(v, d) local n=tonumber(v); if n==nil then return d end; return n end
local function asBool(v)
  if v == nil then return false end
  local t = type(v)
  if t == 'boolean' then return v end
  if t == 'number' then return v == 1 end
  if t == 'string' then v = v:lower(); return (v == '1' or v == 'true' or v == 'yes' or v == 'on') end
  return false
end
local function jenc(tbl)
  if tbl == nil then return nil end
  if type(tbl) == 'string' then return tbl end
  local ok, res = pcall(json.encode, tbl)
  return ok and res or nil
end
-- helper
local function jdec(s, d)
  if not s then return d end
  if type(s) == 'table' then return s end
  local ok, res = pcall(json.decode, s)
  return ok and res or d
end

local function ensure_spawns(row)
  -- wenn keine Spawns aber Legacy-Feld vorhanden -> 1 Spawn migrieren
  local spawns = jdec(row.garage_spawns, nil)
  if (not spawns or #spawns == 0) and row.garage_x and row.garage_y and row.garage_z then
    spawns = {{
      sid = 1,
      type = "both",
      x = tonumber(row.garage_x) or 0.0,
      y = tonumber(row.garage_y) or 0.0,
      z = tonumber(row.garage_z) or 0.0,
      heading = tonumber(row.heading or 0.0) or 0.0,
      radius = 3.0
    }}
    -- zurück in DB schreiben (Migration)
    MySQL.update.await('UPDATE houses SET garage_spawns = ? WHERE id = ?', { json.encode(spawns), tonumber(row.id) })
  end
  row.garage_spawns = spawns or {}
  row.garage_spawns_count = #row.garage_spawns
end

-- ===== Normalisierung für UI/Client =====
local function normalize_house(row)
  row.id                 = toN(row.id)
  row.ownerid            = toN(row.ownerid)
  row.entry_x            = toN(row.entry_x, 0.0)+0.0
  row.entry_y            = toN(row.entry_y, 0.0)+0.0
  row.entry_z            = toN(row.entry_z, 0.0)+0.0
  row.garage_trigger_x   = toN(row.garage_trigger_x, 0.0)+0.0
  row.garage_trigger_y   = toN(row.garage_trigger_y, 0.0)+0.0
  row.garage_trigger_z   = toN(row.garage_trigger_z, 0.0)+0.0
  row.garage_x           = toN(row.garage_x, 0.0)+0.0
  row.garage_y           = toN(row.garage_y, 0.0)+0.0
  row.garage_z           = toN(row.garage_z, 0.0)+0.0
  row.price              = toN(row.price, 0)
  row.rent               = toN(row.rent, 0)
  row.ipl                = toN(row.ipl)
  -- 1 = abgeschlossen, 0 = offen
row.lock_state         = asBool(row.lock_state) and 1 or 0


  row.hotel              = asBool(row.hotel)
  row.apartments         = toN(row.apartments, 0)
  row.garage_size        = toN(row.garage_size, 0)

  row.allowed_bike       = asBool(row.allowed_bike)
  row.allowed_motorbike  = asBool(row.allowed_motorbike)
  row.allowed_car        = asBool(row.allowed_car)
  row.allowed_truck      = asBool(row.allowed_truck)
  row.allowed_plane      = asBool(row.allowed_plane)
  row.allowed_helicopter = asBool(row.allowed_helicopter)
  row.allowed_boat       = asBool(row.allowed_boat)

  row.maxkeys            = toN(row.maxkeys, 0)
  row.interaction_radius = toN(row.interaction_radius, 0.5)
  row.secured            = (row.secured == 1 or row.secured == true or tostring(row.secured) == '1') and 1 or 0

  -- Status ableiten
  local hasOwner     = row.ownerid and row.ownerid > 0
  local rs = row.rent_start
  if rs == "0000-00-00 00:00:00" or rs == "" then rs = nil end
  local hasRentStart = rs ~= nil
  if not hasOwner then
    row.status = "frei"
  elseif hasOwner and not hasRentStart then
    row.status = "verkauft"
  else
    row.status = "vermietet"
  end
  ensure_spawns(row)  -- 👈 NEU
  local spawns = jdec(row.garage_spawns, nil)

-- Migration: falls noch alte garage_x/y/z existieren, daraus 1. Spawn erzeugen
if (not spawns or #spawns == 0) and row.garage_x and row.garage_y and row.garage_z then
  spawns = {{
    sid = 1,
    type = 'both',
    x = tonumber(row.garage_x) or 0.0,
    y = tonumber(row.garage_y) or 0.0,
    z = tonumber(row.garage_z) or 0.0,
    heading = tonumber(row.heading or 0.0) or 0.0,
    radius = 3.0
  }}
  -- direkt persistieren, damit alle künftigen Reads den JSON-Wert haben
  if row.id then
    MySQL.update.await('UPDATE houses SET garage_spawns = ? WHERE id = ?', { json.encode(spawns), tonumber(row.id) })
  end
end

row.garage_spawns = spawns or {}
row.garage_spawns_count = #row.garage_spawns
  return row
end

-- ===== Getters (Bestand) =====
exports('getownerbyhouseid', function(houseId)
  local row = MySQL.single.await('SELECT ownerid FROM houses WHERE id = ?', { tonumber(houseId) })
  return row and tonumber(row.ownerid) or nil
end)
exports('getlockstate', function(houseId)
  local row = MySQL.single.await('SELECT lock_state FROM houses WHERE id = ?', { tonumber(houseId) })
  if not row then return nil end
  return asBool(row.lock_state) and 1 or 0
end)

exports('getrent', function(houseId)
  local row = MySQL.single.await('SELECT rent FROM houses WHERE id = ?', { tonumber(houseId) })
  return row and tonumber(row.rent) or nil
end)
exports('getprice', function(houseId)
  local row = MySQL.single.await('SELECT price FROM houses WHERE id = ?', { tonumber(houseId) })
  return row and tonumber(row.price) or nil
end)
exports('getpincode', function(houseId)
  local row = MySQL.single.await('SELECT pincode FROM houses WHERE id = ?', { tonumber(houseId) })
  return row and row.pincode or nil
end)
exports('getanzahlapartments', function(houseId)
  local row = MySQL.single.await('SELECT apartments FROM houses WHERE id = ?', { tonumber(houseId) })
  return row and tonumber(row.apartments) or 0
end)
exports('getsecured', function(houseId)
  houseId = tonumber(houseId)
  if not houseId then return false end
  local row = MySQL.single.await('SELECT secured FROM houses WHERE id = ?', { houseId })
  return row and (tonumber(row.secured) == 1) or false
end)

-- ===== AdminGetAll (JOIN für interaction_radius) =====
local function HM_Admin_Houses_GetAll()
  local rows = MySQL.query.await([[
    SELECT 
      h.*,
      i.radius AS interaction_radius
    FROM houses h
    LEFT JOIN interaction_points i
      ON i.name = 'HOUSE'
     AND JSON_EXTRACT(i.data, '$.houseid') = h.id
    ORDER BY h.id ASC
  ]]) or {}
  for i=1,#rows do rows[i] = normalize_house(rows[i]) end
  return rows
end
exports('Admin_Houses_GetAll', HM_Admin_Houses_GetAll)

-- ===== Admin Add / Update / Delete / ResetPincode =====
local function HM_Admin_Houses_Add(data)
  if not data or not data.name or not data.entry_x or not data.entry_y or not data.entry_z then
    return { ok=false, error='Name + Eingang sind erforderlich.' }
  end

  local name    = tostring(data.name)
  local ownerid = toN(data.ownerid)
  local radius  = toN(data.radius, 0.5)

  local hotel        = (toN(data.hotel,0) == 1) and 1 or 0
  local apartments   = toN(data.apartments, 0)
  local garage_size  = toN(data.garage_size, 0)
  local maxkeys      = toN(data.maxkeys, 0)
  local pincode      = (data.pincode and tostring(data.pincode) ~= '' and tostring(data.pincode)) or nil
  local secured      = (toN(data.secured, 0) == 1) and 1 or 0

  local allowed_bike        = (toN(data.allowed_bike,1) == 1) and 1 or 0
  local allowed_motorbike   = (toN(data.allowed_motorbike,1) == 1) and 1 or 0
  local allowed_car         = (toN(data.allowed_car,1) == 1) and 1 or 0
  local allowed_truck       = (toN(data.allowed_truck,0) == 1) and 1 or 0
  local allowed_plane       = (toN(data.allowed_plane,0) == 1) and 1 or 0
  local allowed_helicopter  = (toN(data.allowed_helicopter,0) == 1) and 1 or 0
  local allowed_boat        = (toN(data.allowed_boat,0) == 1) and 1 or 0

  -- hier bei Bedarf ein Start-Spawn übernehmen; sonst NULL:
  local garage_spawns = nil
  -- if data.garage_x and data.garage_y and data.garage_z then
  --   garage_spawns = json.encode({{ sid=1, type="both", x=toN(data.garage_x,0), y=toN(data.garage_y,0), z=toN(data.garage_z,0), heading=0.0, radius=3.0 }})
  -- end

  local id = MySQL.insert.await([[
    INSERT INTO houses
      (name, ownerid,
       entry_x, entry_y, entry_z,
       garage_trigger_x, garage_trigger_y, garage_trigger_z,
       garage_x, garage_y, garage_z,
       garage_spawns,
       price, buyed_at, rent, rent_start, data, lock_state, secured,
       ipl, fridgeid, storeid,
       hotel, apartments, garage_size,
       allowed_bike, allowed_motorbike, allowed_car,
       allowed_truck, allowed_plane, allowed_helicopter, allowed_boat,
       maxkeys, `keys`, pincode)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?,
            ?, ?, ?,
            ?, ?, ?,
            ?, ?, ?, ?, ?, ?, ?,
            ?, ?, ?)
  ]], {
    name,
    ownerid and ownerid > 0 and ownerid or nil,
    toN(data.entry_x,0.0), toN(data.entry_y,0.0), toN(data.entry_z,0.0),
    toN(data.garage_trigger_x), toN(data.garage_trigger_y), toN(data.garage_trigger_z),
    toN(data.garage_x), toN(data.garage_y), toN(data.garage_z),
    garage_spawns,              -- 👈 NEU (JSON oder NULL)
    toN(data.price,0),
    nil,                        -- buyed_at
    toN(data.rent,0),
    nil,                        -- rent_start
    nil,                        -- data (frei für spätere Metadaten)
    1,                          -- lock_state (standard: 1)
    secured,                    -- secured
    toN(data.ipl),
    nil,                        -- fridgeid
    nil,                        -- storeid
    hotel, apartments, garage_size,
    allowed_bike, allowed_motorbike, allowed_car,
    allowed_truck, allowed_plane, allowed_helicopter, allowed_boat,
    maxkeys, nil, pincode
  })

  if not id or id <= 0 then return { ok=false, error='Insert fehlgeschlagen' } end

  local dataJson = jenc({ houseid = id })

  -- ENTRY interaction
  MySQL.insert.await([[
    INSERT INTO interaction_points
      (name, description, type, x, y, z, radius, enabled, data)
    VALUES ('HOUSE', ?, 'house', ?, ?, ?, ?, 1, ?)
  ]], { name, toN(data.entry_x,0.0), toN(data.entry_y,0.0), toN(data.entry_z,0.0), radius, dataJson })

  -- GARAGE interaction
  if data.garage_trigger_x and data.garage_trigger_y and data.garage_trigger_z then
    MySQL.insert.await([[
      INSERT INTO interaction_points
        (name, description, type, x, y, z, radius, enabled, data)
      VALUES ('HOUSE_GARAGE', ?, 'garage', ?, ?, ?, ?, 1, ?)
    ]], { name, toN(data.garage_trigger_x,0.0), toN(data.garage_trigger_y,0.0), toN(data.garage_trigger_z,0.0), radius, dataJson })
  end

  -- EXIT via IPL
  if data.ipl then
    local ipl = MySQL.single.await('SELECT exit_x, exit_y, exit_z FROM house_ipl WHERE id = ?', { toN(data.ipl) })
    if ipl then
      MySQL.insert.await([[
        INSERT INTO interaction_points
          (name, description, type, x, y, z, radius, enabled, data)
        VALUES ('EXIT_HOUSE', ?, 'house_exit', ?, ?, ?, ?, 1, ?)
      ]], { name, toN(ipl.exit_x,0.0), toN(ipl.exit_y,0.0), toN(ipl.exit_z,0.0), radius, dataJson })
    end
  end

  TriggerEvent('lcv:interaction:server:reloadPoints')
  TriggerEvent('LCV:house:forceSync')
  return { ok=true, id=id }
end



local function HM_Admin_Houses_Update(data)
  local id = toN(data and data.id)
  if not id then return { ok=false, error='Ungültige ID' } end
  local name = tostring(data.name or '')
  if name == '' then return { ok=false, error='Name ist erforderlich.' } end

  local ownerid = toN(data.ownerid)
  local radius  = toN(data.radius, 0.5)

  local hotel        = (toN(data.hotel,0) == 1) and 1 or 0
  local apartments   = toN(data.apartments, 0)
  local garage_size  = toN(data.garage_size, 0)
  local maxkeys      = toN(data.maxkeys, 0)
  local pincode      = (data.pincode and tostring(data.pincode) ~= '' and tostring(data.pincode)) or nil
  local secured      = (toN(data.secured, 0) == 1) and 1 or 0  -- 👈 NEU

  local allowed_bike        = (toN(data.allowed_bike,1) == 1) and 1 or 0
  local allowed_motorbike   = (toN(data.allowed_motorbike,1) == 1) and 1 or 0
  local allowed_car         = (toN(data.allowed_car,1) == 1) and 1 or 0
  local allowed_truck       = (toN(data.allowed_truck,0) == 1) and 1 or 0
  local allowed_plane       = (toN(data.allowed_plane,0) == 1) and 1 or 0
  local allowed_helicopter  = (toN(data.allowed_helicopter,0) == 1) and 1 or 0
  local allowed_boat        = (toN(data.allowed_boat,0) == 1) and 1 or 0

  local affected = MySQL.update.await([[
    UPDATE houses
    SET name = ?, ownerid = ?,
        entry_x = ?, entry_y = ?, entry_z = ?,
        garage_trigger_x = ?, garage_trigger_y = ?, garage_trigger_z = ?,
        garage_x = ?, garage_y = ?, garage_z = ?,
        price = ?, rent = ?, ipl = ?, lock_state = 1, secured = ?,
        allowed_bike = ?, allowed_motorbike = ?, allowed_car = ?,
        allowed_truck = ?, allowed_plane = ?, allowed_helicopter = ?, allowed_boat = ?,
        maxkeys = ?, pincode = ?
    WHERE id = ?
  ]], {
    name,
    ownerid and ownerid > 0 and ownerid or nil,
    toN(data.entry_x,0.0), toN(data.entry_y,0.0), toN(data.entry_z,0.0),
    toN(data.garage_trigger_x), toN(data.garage_trigger_y), toN(data.garage_trigger_z),
    toN(data.garage_x), toN(data.garage_y), toN(data.garage_z),
    toN(data.price,0), toN(data.rent,0), toN(data.ipl),
    secured,  -- 👈
    hotel, apartments, garage_size,
    allowed_bike, allowed_motorbike, allowed_car,
    allowed_truck, allowed_plane, allowed_helicopter, allowed_boat,
    maxkeys, pincode, id
  })
  --if not affected or affected < 1 then return { ok=false, error='Update fehlgeschlagen.' } end

  local radiusJson = toN(radius, 0.5)
  MySQL.update.await([[
    UPDATE interaction_points
    SET description = ?, x = ?, y = ?, z = ?, radius = ?
    WHERE name = 'HOUSE' AND JSON_EXTRACT(data, '$.houseid') = ?
  ]], { name, toN(data.entry_x,0.0), toN(data.entry_y,0.0), toN(data.entry_z,0.0), radiusJson, id })

  MySQL.update.await([[
    UPDATE interaction_points
    SET description = ?, x = ?, y = ?, z = ?, radius = ?
    WHERE name = 'HOUSE_GARAGE' AND JSON_EXTRACT(data, '$.houseid') = ?
  ]], { name, toN(data.garage_trigger_x,0.0), toN(data.garage_trigger_y,0.0), toN(data.garage_trigger_z,0.0), radiusJson, id })

  if data.ipl then
    local ipl = MySQL.single.await('SELECT exit_x, exit_y, exit_z FROM house_ipl WHERE id = ?', { toN(data.ipl) })
    if ipl and ipl.exit_x and ipl.exit_y and ipl.exit_z then
      MySQL.update.await([[
        UPDATE interaction_points
        SET description = ?, x = ?, y = ?, z = ?, radius = ?
        WHERE name = 'EXIT_HOUSE' AND JSON_EXTRACT(data, '$.houseid') = ?
      ]], { name, toN(ipl.exit_x,0.0), toN(ipl.exit_y,0.0), toN(ipl.exit_z,0.0), radiusJson, id })
    end
  end

-- 0 geänderte Zeilen sind kein Fehler, das kann bei identischen Werten passieren
local changed = tonumber(affected or 0) or 0
if changed > 0 then
  -- Nur bei echten Änderungen Syncs auslösen
  TriggerEvent('lcv:interaction:server:reloadPoints')
  TriggerEvent('LCV:house:forceSync')
end
return { ok = true, changed = changed }

end


local function HM_Admin_Houses_Delete(data)
  local id = toN(data and data.id)
  if not id then return { ok=false, error='Ungültige ID' } end

  MySQL.update.await([[
    DELETE FROM interaction_points
    WHERE JSON_EXTRACT(data, '$.houseid') = ?
  ]], { id })

  local okQ, affected = pcall(function()
    return MySQL.update.await('DELETE FROM houses WHERE id = ?', { id })
  end)

  if not okQ or (affected or 0) <= 0 then
    return { ok=false, error='Kein Datensatz gelöscht' }
  end

  TriggerEvent('lcv:interaction:server:reloadPoints')
  TriggerEvent('LCV:house:forceSync')
  return { ok=true }
end

local function HM_Admin_Houses_ResetPincode(data)
  local id = toN(data and data.id)
  if not id then return { ok=false, error='Ungültige ID' } end
  MySQL.update.await('UPDATE houses SET pincode = NULL WHERE id = ?', { id })
  return { ok=true }
end

exports('Admin_Houses_Add', HM_Admin_Houses_Add)
exports('Admin_Houses_Update', HM_Admin_Houses_Update)
exports('Admin_Houses_Delete', HM_Admin_Houses_Delete)
exports('Admin_Houses_ResetPincode', HM_Admin_Houses_ResetPincode)

-- ====== HOUSE IPL (SSOT) ======
local function normalize_ipl(r)
  r.id = toN(r.id)
  r.posx = toN(r.posx,0.0)+0.0; r.posy = toN(r.posy,0.0)+0.0; r.posz = toN(r.posz,0.0)+0.0
  r.exit_x = toN(r.exit_x,0.0)+0.0; r.exit_y = toN(r.exit_y,0.0)+0.0; r.exit_z = toN(r.exit_z,0.0)+0.0
  return r
end

local function HM_Admin_HousesIPL_GetAll()
  local rows = MySQL.query.await([[
    SELECT id, ipl_name, ipl, posx, posy, posz, exit_x, exit_y, exit_z
    FROM house_ipl
    ORDER BY id ASC
  ]]) or {}
  for i=1,#rows do rows[i] = normalize_ipl(rows[i]) end
  return rows
end

local function HM_Admin_HousesIPL_Add(data)
  if not data or not data.ipl_name or not data.posx or not data.posy or not data.posz then
    return { ok=false, error='Name + pos erforderlich' }
  end

  -- Leere ipl-Strings als NULL speichern (sauberer)
  local iplValue = (data.ipl and tostring(data.ipl) or '')
  if iplValue == '' then iplValue = nil end

  local okIns, insertIdOrErr = pcall(function()
    return MySQL.insert.await([[
      INSERT INTO house_ipl (ipl_name, ipl, posx, posy, posz, exit_x, exit_y, exit_z)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
      tostring(data.ipl_name),
      iplValue,
      toN(data.posx,0.0), toN(data.posy,0.0), toN(data.posz,0.0),
      toN(data.exit_x), toN(data.exit_y), toN(data.exit_z)
    })
  end)

  if not okIns then
    local msg = tostring(insertIdOrErr or '')
    if msg:find('Duplicate entry') and msg:find('uniq_ipl_name') then
      return { ok=false, error='duplicate_ipl_name' }
    end
    return { ok=false, error='db_insert_failed' }
  end

  local id = tonumber(insertIdOrErr or 0) or 0
  if id <= 0 then
    return { ok=false, error='Insert fehlgeschlagen' }
  end
  return { ok=true, id=id }
end


local function HM_Admin_HousesIPL_Delete(data)
  local id = toN(data and data.id)
  if not id then return { ok=false, error='Ungültige ID' } end
  local okQ, affected = pcall(function()
    return MySQL.update.await('DELETE FROM house_ipl WHERE id = ?', { id })
  end)
  if not okQ or (affected or 0) <= 0 then return { ok=false, error='Kein Datensatz gelöscht' } end
  return { ok=true }
end

exports('Admin_HousesIPL_GetAll', HM_Admin_HousesIPL_GetAll)
exports('Admin_HousesIPL_Add',    HM_Admin_HousesIPL_Add)
exports('Admin_HousesIPL_Update', HM_Admin_HousesIPL_Update)
exports('Admin_HousesIPL_Delete', HM_Admin_HousesIPL_Delete)

-- ===== OPTIONAL: GetAll für andere Module =====
local function HM_GetAll()
  local rows = MySQL.query.await([[
    SELECT 
      h.*,
      i.radius AS interaction_radius
    FROM houses h
    LEFT JOIN interaction_points i
      ON i.name = 'HOUSE'
     AND JSON_EXTRACT(i.data, '$.houseid') = h.id
    ORDER BY h.id ASC
  ]]) or {}
  for i=1,#rows do rows[i] = normalize_house(rows[i]) end
  return rows
end
exports('GetAll', HM_GetAll)
-- =======================
--  GARAGE SPAWNS (ADMIN)
-- =======================

local function HM_Admin_Houses_GarageSpawns_List(houseId)
  houseId = tonumber(houseId)
  if not houseId then return { ok=false, error='invalid houseId', spawns={} } end
  local row = MySQL.single.await('SELECT garage_spawns FROM houses WHERE id = ?', { houseId })
  local spawns = jdec(row and row.garage_spawns, {})
  return { ok=true, spawns=spawns }
end

local function next_sid(spawns)
  local maxsid = 0
  for _, s in ipairs(spawns) do
    local sid = tonumber(s.sid) or 0
    if sid > maxsid then maxsid = sid end
  end
  return maxsid + 1
end

local function HM_Admin_Houses_GarageSpawns_Add(houseId, spawn)
  houseId = tonumber(houseId)
  if not houseId then return { ok=false, error='invalid houseId' } end
  if type(spawn) ~= 'table' then return { ok=false, error='invalid spawn' } end

  local row = MySQL.single.await('SELECT garage_spawns FROM houses WHERE id = ?', { houseId })
  local spawns = jdec(row and row.garage_spawns, {})

  spawn.sid     = spawn.sid or next_sid(spawns)
  spawn.type    = spawn.type or 'both'
  spawn.x       = tonumber(spawn.x) or 0.0
  spawn.y       = tonumber(spawn.y) or 0.0
  spawn.z       = tonumber(spawn.z) or 0.0
  spawn.heading = tonumber(spawn.heading) or 0.0
  spawn.radius  = tonumber(spawn.radius or 3.0) or 3.0

  spawns[#spawns+1] = spawn
  MySQL.update.await('UPDATE houses SET garage_spawns = ? WHERE id = ?', { json.encode(spawns), houseId })
  TriggerEvent('LCV:house:forceSync')

  return { ok=true, sid=spawn.sid, spawns=spawns }
end

local function HM_Admin_Houses_GarageSpawns_Update(houseId, spawn)
  houseId = tonumber(houseId)
  if not houseId then return { ok=false, error='invalid houseId' } end
  if type(spawn) ~= 'table' or not spawn.sid then return { ok=false, error='invalid spawn.sid' } end
  local sid = tonumber(spawn.sid)
  local row = MySQL.single.await('SELECT garage_spawns FROM houses WHERE id = ?', { houseId })
  local spawns = jdec(row and row.garage_spawns, {})
  local found = false
  for i, s in ipairs(spawns) do
  if tonumber(s.sid) == sid then
    s.type    = spawn.type    or s.type
    s.x       = (spawn.x ~= nil) and tonumber(spawn.x) or s.x
    s.y       = (spawn.y ~= nil) and tonumber(spawn.y) or s.y
    s.z       = (spawn.z ~= nil) and tonumber(spawn.z) or s.z
    s.heading = (spawn.heading ~= nil) and tonumber(spawn.heading) or s.heading
    s.radius  = (spawn.radius ~= nil) and tonumber(spawn.radius) or s.radius
    s.allowed = spawn.allowed or s.allowed
    s.label   = spawn.label   or s.label
    found = true
    break
  end
end
if not found then return { ok=false, error='sid not found' } end

MySQL.update.await('UPDATE houses SET garage_spawns = ? WHERE id = ?', { json.encode(spawns), houseId })
TriggerEvent('LCV:house:forceSync')   -- ✅ nach erfolgreichem Update

return { ok=true, spawns=spawns }

end

local function HM_Admin_Houses_GarageSpawns_Delete(houseId, sid)
  houseId = tonumber(houseId); sid = tonumber(sid)
  if not houseId or not sid then return { ok=false, error='invalid id/sid' } end
  local row = MySQL.single.await('SELECT garage_spawns FROM houses WHERE id = ?', { houseId })
  local spawns = jdec(row and row.garage_spawns, {})
  local out = {}
  local removed = false
  for _, s in ipairs(spawns) do
    if tonumber(s.sid) ~= sid then
      out[#out+1] = s
    else
      removed = true
    end
  end
  if not removed then return { ok=false, error='sid not found' } end
  MySQL.update.await('UPDATE houses SET garage_spawns = ? WHERE id = ?', { json.encode(out), houseId })
  TriggerEvent('LCV:house:forceSync')

  return { ok=true, spawns=out }
end

exports('Admin_Houses_GarageSpawns_List',   HM_Admin_Houses_GarageSpawns_List)
exports('Admin_Houses_GarageSpawns_Add',    HM_Admin_Houses_GarageSpawns_Add)
exports('Admin_Houses_GarageSpawns_Update', HM_Admin_Houses_GarageSpawns_Update)
exports('Admin_Houses_GarageSpawns_Delete', HM_Admin_Houses_GarageSpawns_Delete)
-- ===== OPTIONAL: GetAll für andere Module =====
local function HM_GetAll()
  local rows = MySQL.query.await([[
    SELECT 
      h.*,
      i.radius AS interaction_radius
    FROM houses h
    LEFT JOIN interaction_points i
      ON i.name = 'HOUSE'
     AND JSON_EXTRACT(i.data, '$.houseid') = h.id
    ORDER BY h.id ASC
  ]]) or {}
  for i=1,#rows do rows[i] = normalize_house(rows[i]) end
  return rows
end

-- Ein einzelnes Haus nach ID holen
local function HM_GetById(houseId)
  houseId = toN(houseId)
  if not houseId then return nil end

  local row = MySQL.single.await([[
    SELECT 
      h.*,
      i.radius AS interaction_radius
    FROM houses h
    LEFT JOIN interaction_points i
      ON i.name = 'HOUSE'
     AND JSON_EXTRACT(i.data, '$.houseid') = h.id
    WHERE h.id = ?
    LIMIT 1
  ]], { houseId }) or nil

  if not row then return nil end
  return normalize_house(row)
end

exports('GetById', HM_GetById)
exports('GetAll', HM_GetAll)

