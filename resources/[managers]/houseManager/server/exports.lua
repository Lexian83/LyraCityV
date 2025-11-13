-- houseManager/server/exports.lua
print('houseManager/server/exports.lua live = 2025-11-12-SSOT-GETALL-A')


local function normalize_house(row)
    -- Falls nötig, leichte Normalisierung (numeric cast etc.)
    local function toN(v, d) local n=tonumber(v); if n==nil then return d end; return n end
    row.id = toN(row.id)
    row.entry_x = toN(row.entry_x, 0.0)+0.0
    row.entry_y = toN(row.entry_y, 0.0)+0.0
    row.entry_z = toN(row.entry_z, 0.0)+0.0
    row.garage_trigger_x = toN(row.garage_trigger_x, 0.0)+0.0
    row.garage_trigger_y = toN(row.garage_trigger_y, 0.0)+0.0
    row.garage_trigger_z = toN(row.garage_trigger_z, 0.0)+0.0
    row.garage_x = toN(row.garage_x, 0.0)+0.0
    row.garage_y = toN(row.garage_y, 0.0)+0.0
    row.garage_z = toN(row.garage_z, 0.0)+0.0
    row.price = toN(row.price, 0)
    row.rent = toN(row.rent, 0)
    row.lock_state = toN(row.lock_state, 0)
    row.hotel = toN(row.hotel, 0)
    row.apartments = toN(row.apartments, 0)
    row.garage_size = toN(row.garage_size, 0)
    row.allowed_bike = toN(row.allowed_bike, 1)
    row.allowed_motorbike = toN(row.allowed_motorbike, 1)
    row.allowed_car = toN(row.allowed_car, 1)
    row.allowed_truck = toN(row.allowed_truck, 0)
    row.allowed_plane = toN(row.allowed_plane, 0)
    row.allowed_helicopter = toN(row.allowed_helicopter, 0)
    row.allowed_boat = toN(row.allowed_boat, 0)
    row.maxkeys = toN(row.maxkeys, 0)
    row.interaction_radius = toN(row.interaction_radius, row.radius or 0.5)
    row.secured = toN(row.secured, 0)
    return row
end

local function HM_GetAll()
    local rows = MySQL.query.await([[
        SELECT
            id, name, ownerid,
            entry_x, entry_y, entry_z,
            garage_trigger_x, garage_trigger_y, garage_trigger_z,
            garage_x, garage_y, garage_z,
            price, rent, ipl, lock_state,
            hotel, apartments, garage_size,
            allowed_bike, allowed_motorbike, allowed_car,
            allowed_truck, allowed_plane, allowed_helicopter, allowed_boat,
            maxkeys, pincode, interaction_radius, secured,
            buyed_at, rent_start
        FROM houses
        ORDER BY id ASC
    ]]) or {}

    for i=1,#rows do rows[i] = normalize_house(rows[i]) end
    return rows
end

exports('GetAll', HM_GetAll)

-- =========================
-- Exports
-- =========================

exports('getownerbyhouseid', function(houseId)
    local row = MySQL.single.await('SELECT ownerid FROM houses WHERE id = ?', { tonumber(houseId) })
    return row and tonumber(row.ownerid) or nil
end)

exports('getlockstate', function(houseId)
    local row = MySQL.single.await('SELECT lock_state FROM houses WHERE id = ?', { tonumber(houseId) })
    return row and tonumber(row.lock_state) or nil
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

-- NEU: secured-Export (0/1)
exports('getsecured', function(houseId)
    houseId = tonumber(houseId)
    if not houseId then return false end
    local row = MySQL.single.await('SELECT secured FROM houses WHERE id = ?', { houseId })
    return row and (tonumber(row.secured) == 1) or false
end)
