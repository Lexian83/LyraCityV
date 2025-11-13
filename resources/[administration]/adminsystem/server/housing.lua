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

local function asBool(v)
    if v == nil then return false end
    local t = type(v)
    if t == "boolean" then
        return v
    elseif t == "number" then
        return v == 1
    elseif t == "string" then
        v = v:lower()
        return (v == "1" or v == "true" or v == "yes" or v == "on")
    end
    return false
end

local function hmJsonEncode(tbl)
    if not tbl then return '{}' end
    if type(tbl) == 'string' then return tbl end
    local ok, res = pcall(json.encode, tbl)
    return ok and res or '{}'
end

-- ================== HOUSING SYSTEM ==================

lib.callback.register('LCV:ADMIN:Houses:GetAll', function(source)
    if not hasAdminPermission(source, 10) then
        return { ok = false, error = 'Keine Berechtigung', houses = {} }
    end

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

    for _, h in ipairs(rows) do
        h.id                 = tonumber(h.id) or 0
        h.ownerid            = tonumber(h.ownerid) or 0
        h.entry_x            = tonumber(h.entry_x) or 0.0
        h.entry_y            = tonumber(h.entry_y) or 0.0
        h.entry_z            = tonumber(h.entry_z) or 0.0
        h.garage_trigger_x   = tonumber(h.garage_trigger_x) or nil
        h.garage_trigger_y   = tonumber(h.garage_trigger_y) or nil
        h.garage_trigger_z   = tonumber(h.garage_trigger_z) or nil
        h.garage_x           = tonumber(h.garage_x) or nil
        h.garage_y           = tonumber(h.garage_y) or nil
        h.garage_z           = tonumber(h.garage_z) or nil
        h.price              = tonumber(h.price) or 0
        h.rent               = tonumber(h.rent) or 0
        h.ipl                = tonumber(h.ipl) or nil
        h.lock_state         = (tonumber(h.lock_state) == 1) and 1 or 0

        h.hotel              = asBool(h.hotel)
h.apartments         = tonumber(h.apartments) or 0
h.garage_size        = tonumber(h.garage_size) or 0

h.allowed_bike       = asBool(h.allowed_bike)
h.allowed_motorbike  = asBool(h.allowed_motorbike)
h.allowed_car        = asBool(h.allowed_car)
h.allowed_truck      = asBool(h.allowed_truck)
h.allowed_plane      = asBool(h.allowed_plane)
h.allowed_helicopter = asBool(h.allowed_helicopter)
h.allowed_boat       = asBool(h.allowed_boat)


        h.maxkeys            = tonumber(h.maxkeys) or 0
        -- h.keys bleibt JSON / wird im UI nicht direkt genutzt
        h.pincode            = h.pincode

        local rs = h.rent_start
        if rs == "0000-00-00 00:00:00" or rs == "" then
            h.rent_start = nil
        end

        local hasOwner     = h.ownerid and h.ownerid > 0
        local hasRentStart = h.rent_start ~= nil

        if not hasOwner then
            h.status = "frei"
        elseif hasOwner and not hasRentStart then
            h.status = "verkauft"
        else
            h.status = "vermietet"
        end

        h.interaction_radius = tonumber(h.interaction_radius) or 0.5
    end
    return { ok = true, houses = rows }
end)

lib.callback.register('LCV:ADMIN:Houses:Add', function(source, data)
    if not hasAdminPermission(source, 10) then
        return { ok = false, error = 'Keine Berechtigung' }
    end

    if not data or not data.name or not data.entry_x or not data.entry_y or not data.entry_z then
        return { ok = false, error = 'Name + Eingang sind erforderlich.' }
    end

    local name    = tostring(data.name)
    local ownerid = tonumber(data.ownerid) or 0
    local radius  = tonumber(data.radius) or 0.5

    local hotel        = (tonumber(data.hotel) == 1) and 1 or 0
    local apartments   = tonumber(data.apartments) or 0
    local garage_size  = tonumber(data.garage_size) or 0
    local maxkeys      = tonumber(data.maxkeys) or 0
    local pincode      = (data.pincode and tostring(data.pincode) ~= '' and tostring(data.pincode)) or nil

    local allowed_bike        = (tonumber(data.allowed_bike) == 1) and 1 or 0
local allowed_motorbike   = (tonumber(data.allowed_motorbike) == 1) and 1 or 0
local allowed_car         = (tonumber(data.allowed_car) == 1) and 1 or 0
local allowed_truck       = (tonumber(data.allowed_truck) == 1) and 1 or 0
local allowed_plane       = (tonumber(data.allowed_plane) == 1) and 1 or 0
local allowed_helicopter  = (tonumber(data.allowed_helicopter) == 1) and 1 or 0
local allowed_boat        = (tonumber(data.allowed_boat) == 1) and 1 or 0


    local id = MySQL.insert.await([[
        INSERT INTO houses
            (name, ownerid,
             entry_x, entry_y, entry_z,
             garage_trigger_x, garage_trigger_y, garage_trigger_z,
             garage_x, garage_y, garage_z,
             price, rent, ipl, lock_state,
             hotel, apartments, garage_size,
             allowed_bike, allowed_motorbike, allowed_car,
             allowed_truck, allowed_plane, allowed_helicopter, allowed_boat,
             maxkeys, `keys`, pincode)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1,
        ?, ?, ?,
        ?, ?, ?,
        ?, ?, ?, ?,
        ?, ?, ?)

    ]], {
        name,
        ownerid > 0 and ownerid or nil,
        tonumber(data.entry_x) or 0.0,
        tonumber(data.entry_y) or 0.0,
        tonumber(data.entry_z) or 0.0,
        tonumber(data.garage_trigger_x) or nil,
        tonumber(data.garage_trigger_y) or nil,
        tonumber(data.garage_trigger_z) or nil,
        tonumber(data.garage_x) or nil,
        tonumber(data.garage_y) or nil,
        tonumber(data.garage_z) or nil,
        tonumber(data.price) or 0,
        tonumber(data.rent) or 0,
        tonumber(data.ipl) or nil,
        hotel,
        apartments,
        garage_size,
        allowed_bike, allowed_motorbike, allowed_car,
        allowed_truck, allowed_plane, allowed_helicopter, allowed_boat,
        maxkeys,
        nil, -- `keys`
        pincode
    })

    if not id or id <= 0 then
        return { ok = false, error = 'Insert fehlgeschlagen' }
    end

    local houseId  = id
    local dataJson = json.encode({ houseid = houseId })

    -- ENTRY Interaction
    MySQL.insert.await([[
        INSERT INTO interaction_points
            (name, description, type, x, y, z, radius, enabled, data)
        VALUES ('HOUSE', ?, 'house', ?, ?, ?, ?, 1, ?)
    ]], {
        name,
        tonumber(data.entry_x) or 0.0,
        tonumber(data.entry_y) or 0.0,
        tonumber(data.entry_z) or 0.0,
        radius,
        dataJson
    })

    -- GARAGE Interaction
    if data.garage_trigger_x and data.garage_trigger_y and data.garage_trigger_z then
        MySQL.insert.await([[
            INSERT INTO interaction_points
                (name, description, type, x, y, z, radius, enabled, data)
            VALUES ('HOUSE_GARAGE', ?, 'garage', ?, ?, ?, ?, 1, ?)
        ]], {
            name,
            tonumber(data.garage_trigger_x) or 0.0,
            tonumber(data.garage_trigger_y) or 0.0,
            tonumber(data.garage_trigger_z) or 0.0,
            radius,
            dataJson
        })
    end

    -- EXIT Interaction via IPL
    if data.ipl then
        local ipl = MySQL.single.await('SELECT exit_x, exit_y, exit_z FROM house_ipl WHERE id = ?', { tonumber(data.ipl) })
        if ipl then
            MySQL.insert.await([[
                INSERT INTO interaction_points
                    (name, description, type, x, y, z, radius, enabled, data)
                VALUES ('EXIT_HOUSE', ?, 'house_exit', ?, ?, ?, ?, 1, ?)
            ]], {
                name,
                tonumber(ipl.exit_x) or 0.0,
                tonumber(ipl.exit_y) or 0.0,
                tonumber(ipl.exit_z) or 0.0,
                radius,
                dataJson
            })
        end
    end

    TriggerEvent('lcv:interaction:server:reloadPoints')
    TriggerEvent('LCV:house:forceSync')

    return { ok = true }
end)

lib.callback.register('LCV:ADMIN:Houses:Update', function(source, data)
    if not hasAdminPermission(source, 10) then
        return { ok = false, error = 'Keine Berechtigung' }
    end

    local id = tonumber(data and data.id)
    if not id then
        return { ok = false, error = 'Ungültige ID' }
    end

    local name = tostring(data.name or '')
    if name == '' then
        return { ok = false, error = 'Name ist erforderlich.' }
    end

    local ownerid = tonumber(data.ownerid) or 0
    local radius  = tonumber(data.radius) or 0.5

    local hotel        = (tonumber(data.hotel) == 1) and 1 or 0
    local apartments   = tonumber(data.apartments) or 0
    local garage_size  = tonumber(data.garage_size) or 0
    local maxkeys      = tonumber(data.maxkeys) or 0
    local pincode      = (data.pincode and tostring(data.pincode) ~= '' and tostring(data.pincode)) or nil

    local allowed_bike        = (tonumber(data.allowed_bike) == 1) and 1 or 0
local allowed_motorbike   = (tonumber(data.allowed_motorbike) == 1) and 1 or 0
local allowed_car         = (tonumber(data.allowed_car) == 1) and 1 or 0
local allowed_truck       = (tonumber(data.allowed_truck) == 1) and 1 or 0
local allowed_plane       = (tonumber(data.allowed_plane) == 1) and 1 or 0
local allowed_helicopter  = (tonumber(data.allowed_helicopter) == 1) and 1 or 0
local allowed_boat        = (tonumber(data.allowed_boat) == 1) and 1 or 0


    local affected = MySQL.update.await([[
        UPDATE houses
        SET name = ?, ownerid = ?,
            entry_x = ?, entry_y = ?, entry_z = ?,
            garage_trigger_x = ?, garage_trigger_y = ?, garage_trigger_z = ?,
            garage_x = ?, garage_y = ?, garage_z = ?,
            price = ?, rent = ?, ipl = ?,
            hotel = ?, apartments = ?, garage_size = ?,
            allowed_bike = ?, allowed_motorbike = ?, allowed_car = ?,
            allowed_truck = ?, allowed_plane = ?, allowed_helicopter = ?, allowed_boat = ?,
            maxkeys = ?, pincode = ?
        WHERE id = ?
    ]], {
        name,
        ownerid > 0 and ownerid or nil,
        tonumber(data.entry_x) or 0.0,
        tonumber(data.entry_y) or 0.0,
        tonumber(data.entry_z) or 0.0,
        tonumber(data.garage_trigger_x) or nil,
        tonumber(data.garage_trigger_y) or nil,
        tonumber(data.garage_trigger_z) or nil,
        tonumber(data.garage_x) or nil,
        tonumber(data.garage_y) or nil,
        tonumber(data.garage_z) or nil,
        tonumber(data.price) or 0,
        tonumber(data.rent) or 0,
        tonumber(data.ipl) or nil,
        hotel,
        apartments,
        garage_size,
        allowed_bike, allowed_motorbike, allowed_car,
        allowed_truck, allowed_plane, allowed_helicopter, allowed_boat,
        maxkeys,
        pincode,
        id
    })

    if not affected or affected < 1 then
        return { ok = false, error = 'Update fehlgeschlagen.' }
    end

    local dataJson = hmJsonEncode({ houseid = id })

    -- ENTRY
    MySQL.update.await([[
        UPDATE interaction_points
        SET description = ?, x = ?, y = ?, z = ?, radius = ?
        WHERE name = 'HOUSE' AND JSON_EXTRACT(data, '$.houseid') = ?
    ]], {
        name,
        tonumber(data.entry_x) or 0.0,
        tonumber(data.entry_y) or 0.0,
        tonumber(data.entry_z) or 0.0,
        radius,
        id
    })

    -- GARAGE
    MySQL.update.await([[
        UPDATE interaction_points
        SET description = ?, x = ?, y = ?, z = ?, radius = ?
        WHERE name = 'HOUSE_GARAGE' AND JSON_EXTRACT(data, '$.houseid') = ?
    ]], {
        name,
        tonumber(data.garage_trigger_x) or 0.0,
        tonumber(data.garage_trigger_y) or 0.0,
        tonumber(data.garage_trigger_z) or 0.0,
        radius,
        id
    })

    -- EXIT via IPL
    if data.ipl then
        local ipl = MySQL.single.await('SELECT exit_x, exit_y, exit_z FROM house_ipl WHERE id = ?', { tonumber(data.ipl) })
        if ipl and ipl.exit_x and ipl.exit_y and ipl.exit_z then
            MySQL.update.await([[
                UPDATE interaction_points
                SET description = ?, x = ?, y = ?, z = ?, radius = ?
                WHERE name = 'EXIT_HOUSE' AND JSON_EXTRACT(data, '$.houseid') = ?
            ]], {
                name,
                tonumber(ipl.exit_x) or 0.0,
                tonumber(ipl.exit_y) or 0.0,
                tonumber(ipl.exit_z) or 0.0,
                radius,
                id
            })
        end
    end

    TriggerEvent('lcv:interaction:server:reloadPoints')
    TriggerEvent('LCV:house:forceSync')
    return { ok = true }
end)

lib.callback.register('LCV:ADMIN:Houses:Delete', function(source, data)
    if not hasAdminPermission(source, 10) then
        return { ok = false, error = 'Keine Berechtigung' }
    end

    local id = tonumber(data and data.id)
    if not id then
        return { ok = false, error = 'Ungültige ID' }
    end

    MySQL.update.await([[
        DELETE FROM interaction_points
        WHERE JSON_EXTRACT(data, '$.houseid') = ?
    ]], { id })

    local okQ, affected = pcall(function()
        return MySQL.update.await('DELETE FROM houses WHERE id = ?', { id })
    end)

    if not okQ or (affected or 0) <= 0 then
        return { ok = false, error = 'Kein Datensatz gelöscht' }
    end

    TriggerEvent('lcv:interaction:server:reloadPoints')
    TriggerEvent('LCV:house:forceSync')
    return { ok = true }
end)

lib.callback.register('LCV:ADMIN:Houses:ResetPincode', function(source, data)
    if not hasAdminPermission(source, 10) then
        return { ok = false, error = 'Keine Berechtigung' }
    end

    local id = tonumber(data and data.id)
    if not id then
        return { ok = false, error = 'Ungültige ID' }
    end

    MySQL.update.await('UPDATE houses SET pincode = NULL WHERE id = ?', { id })
    return { ok = true }
end)

-- Teleport vom Client (NUI ruft Client, Client triggert dieses Event)
RegisterNetEvent('LCV:ADMIN:Houses:Teleport', function(id, x, y, z)
    local src = source
    if not hasAdminPermission(src, 10) then return end

    x, y, z = tonumber(x), tonumber(y), tonumber(z)
    if not x or not y or not z then return end

    local ped = GetPlayerPed(src)
    if ped ~= 0 then
        SetEntityCoords(ped, x, y, z, false, false, false, true)
        TriggerClientEvent('LCV:ADMIN:Interactions:NotifyTeleport', src, { x = x, y = y, z = z })
    end
end)