-- resources/houseManager/server/houseManager.lua
-- LyraCityV - Housing Management

LCV      = LCV or {}
LCV.Util = LCV.Util or {}

local json = json

-- =========================
-- Utils & Logging
-- =========================

local function log(level, msg)
    if LCV.Util and LCV.Util.log then
        LCV.Util.log(level, ('[HouseManager] %s'):format(tostring(msg)))
    else
        print(('[HouseManager][%s] %s'):format(level, tostring(msg)))
    end
end

if not MySQL then
    print('[HouseManager][WARN] MySQL ist nil beim Laden. Prüfe @oxmysql/lib/MySQL.lua im fxmanifest.')
end

local function toNumber(v)
    local n = tonumber(v)
    return n
end

local function jenc(v)
    if v == nil then return nil end
    if type(v) == "string" then return v end
    local ok, res = pcall(json.encode, v)
    if ok then return res end
    return nil
end

local function createInteractionPoint(name, description, pType, x, y, z, radius, dataTbl)
    if not x or not y or not z then return end
    radius = tonumber(radius) or 1.0

    local dataJson = jenc(dataTbl)

    MySQL.insert.await([[
        INSERT INTO interaction_points
            (name, description, type, x, y, z, radius, enabled, data)
        VALUES (?, ?, ?, ?, ?, ?, ?, 1, ?)
    ]], {
        name,
        description or name,
        pType,
        tonumber(x) or 0.0,
        tonumber(y) or 0.0,
        tonumber(z) or 0.0,
        radius,
        dataJson
    })
end

-- =========================
-- Core DB Helper
-- =========================

local function getHouse(houseId)
    houseId = tonumber(houseId)
    if not houseId then return nil end
    return MySQL.single.await('SELECT * FROM houses WHERE id = ?', { houseId })
end

local function getHouseIPL(iplId)
    iplId = tonumber(iplId)
    if not iplId then return nil end
    return MySQL.single.await([[
        SELECT id, ipl_name, ipl, posx, posy, posz, exit_x, exit_y, exit_z
        FROM house_ipl WHERE id = ?
    ]], { iplId })
end

local function getAllHouses()
    local rows = MySQL.query.await([[
        SELECT h.id,
               h.garage_trigger_x, h.garage_trigger_y, h.garage_trigger_z,
               ig.radius
        FROM houses h
        LEFT JOIN interaction_points ig
          ON ig.name = 'HOUSE_GARAGE'
         AND JSON_EXTRACT(ig.data, '$.houseid') = h.id
    ]]) or {}
    return rows
end

local function sendAllHouses(target)
    local houses = getAllHouses()
    local count = #houses

    if target then
        log("DEBUG", ("Sende %d Houses an %s"):format(count, tostring(target)))
        TriggerClientEvent('LCV:house:sync', target, houses)
    else
        log("DEBUG", ("Sende %d Houses an alle Clients"):format(count))
        TriggerClientEvent('LCV:house:sync', -1, houses)
    end

    if count > 0 then
        local h = houses[1]
        log("DEBUG", ("House[1]: id=%s gt_x=%s gt_y=%s gt_z=%s radius=%s"):format(
            tostring(h.id),
            tostring(h.garage_trigger_x),
            tostring(h.garage_trigger_y),
            tostring(h.garage_trigger_z),
            tostring(h.radius)
        ))
    end
end


-- =========================
-- House CRUD
-- =========================

RegisterNetEvent('LCV:house:create', function(data)
    local src  = source
    data       = data or {}

    local name = tostring(data.name or ""):sub(1, 128)
    if name == "" then
        log("WARN", ("create: ungültiger Name von src=%s"):format(src))
        return
    end

    local hotel        = (tonumber(data.hotel) == 1) and 1 or 0
    local apartments   = tonumber(data.apartments) or 0
    local garage_size  = tonumber(data.garage_size) or 0
    local maxkeys      = tonumber(data.maxkeys) or 0
    local pincode      = (data.pincode and tostring(data.pincode) ~= '' and tostring(data.pincode)) or nil

    local allowed_bike        = data.allowed_bike and 1 or 0
    local allowed_motorbike   = data.allowed_motorbike and 1 or 0
    local allowed_car         = data.allowed_car and 1 or 0
    local allowed_truck       = data.allowed_truck and 1 or 0
    local allowed_plane       = data.allowed_plane and 1 or 0
    local allowed_helicopter  = data.allowed_helicopter and 1 or 0
    local allowed_boat        = data.allowed_boat and 1 or 0

    local secured             = (tonumber(data.secured) == 1) and 1 or 0  -- 👈 NEU

    local params = {
        name,
        toNumber(data.ownerid),
        tonumber(data.entry_x) or 0.0,
        tonumber(data.entry_y) or 0.0,
        tonumber(data.entry_z) or 0.0,
        toNumber(data.garage_trigger_x),
        toNumber(data.garage_trigger_y),
        toNumber(data.garage_trigger_z),
        toNumber(data.garage_x),
        toNumber(data.garage_y),
        toNumber(data.garage_z),
        tonumber(data.price) or 0,
        data.buyed_at or nil,
        toNumber(data.rent),
        data.rent_start or nil,
        jenc(data.data),
        (tonumber(data.lock_state) == 0) and 0 or 1,
        secured,
        toNumber(data.ipl),
        toNumber(data.fridgeid),
        toNumber(data.storeid),
        hotel,
        apartments,
        garage_size,
        allowed_bike,
        allowed_motorbike,
        allowed_car,
        allowed_truck,
        allowed_plane,
        allowed_helicopter,
        allowed_boat,
        maxkeys,
        nil,      -- keys
        pincode
    }

local id = MySQL.insert.await([[
  INSERT INTO houses
    (name, ownerid,
     entry_x, entry_y, entry_z,
     garage_trigger_x, garage_trigger_y, garage_trigger_z,
     garage_x, garage_y, garage_z,
     price, buyed_at, rent, rent_start, data, lock_state,
     secured, ipl, fridgeid, storeid,                 -- 👈 NEU: secured vor ipl
     hotel, apartments, garage_size,
     allowed_bike, allowed_motorbike, allowed_car,
     allowed_truck, allowed_plane, allowed_helicopter, allowed_boat,
     maxkeys, keys, pincode)
  VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?,
          ?, ?, ?,
          ?, ?, ?,
          ?, ?, ?, ?, ?, ?, ?, ?,
          ?, ?, ?)
]], params)

    if not id or id <= 0 then
        log("ERROR", ("Haus erstellen fehlgeschlagen von src=%s"):format(src))
        return
    end

    local houseId   = id
    local houseName = name
    local radius    = tonumber(data.radius) or 0.5
    local entry_x, entry_y, entry_z = params[3], params[4], params[5]
    local dataTbl = { houseid = houseId }

    -- Entry
    createInteractionPoint('HOUSE', houseName, 'house', entry_x, entry_y, entry_z, radius, dataTbl)

    -- Garage Trigger
    local gx, gy, gz = params[6], params[7], params[8]
    if gx and gy and gz then
        createInteractionPoint('HOUSE_GARAGE', houseName, 'garage', gx, gy, gz, radius, dataTbl)
    end

        -- Exit über IPL
    local iplId = params[19]
    if iplId then
        local ipl = getHouseIPL(iplId)
        if ipl and ipl.exit_x and ipl.exit_y and ipl.exit_z then
            createInteractionPoint('EXIT_HOUSE', houseName, 'house_exit', ipl.exit_x, ipl.exit_y, ipl.exit_z, radius, dataTbl)
        else
            log("WARN", ("Haus #%d: ipl=%s ohne exit_x/y/z, EXIT_HOUSE nicht erzeugt."):format(houseId, tostring(iplId)))
        end
    end

    -- =========================
    -- Hotel-Blip automatisch anlegen
    -- =========================
    if hotel == 1 then
        local bx, by, bz = entry_x, entry_y, entry_z

        if bx and by and bz then
            local blipId = MySQL.insert.await([[
                INSERT INTO blips
                    (name, x, y, z, sprite, color, scale, shortRange, display, category, visiblefor, enabled)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ]], {
                houseName,          -- name
                bx, by, bz,         -- coords
                357,                -- sprite (Hotel/Icon)
                3,                  -- color (hellblau)
                1.0,                -- scale
                0,                  -- shortRange (0 = global sichtbar)
                4,                  -- display
                'Hotel',            -- category
                0,                  -- visiblefor (0 = alle)
                1                   -- enabled
            })

            if blipId and blipId > 0 then
                -- direkt an alle Clients pushen, ohne kompletten Reload
                TriggerClientEvent('lcv:blip:client:spawnOne', -1, {
                    id         = blipId,
                    name       = houseName,
                    coords     = { x = bx, y = by, z = bz },
                    sprite     = 357,
                    color      = 3,
                    scale      = 1.0,
                    shortRange = false,
                    display    = 4,
                    category   = 'Hotel',
                    visiblefor = 0,
                    enabled    = true
                })

                log("INFO", ("Hotel-Blip #%d für Haus #%d '%s' erzeugt."):format(blipId, houseId, houseName))
            else
                log("WARN", ("Haus #%d '%s': Hotel-Blip konnte nicht angelegt werden."):format(houseId, houseName))
            end
        else
            log("WARN", ("Haus #%d '%s' ist Hotel, aber Entry-Coords fehlen -> kein Blip."):format(houseId, houseName))
        end
    end

    log("INFO", ("Haus + InteractionPoints erstellt #%d von src=%s"):format(houseId, src))
    TriggerEvent('LCV:house:forceSync')
end)


RegisterNetEvent('LCV:house:update', function(houseId, patch)
    local src = source
    houseId   = tonumber(houseId)
    patch     = patch or {}
    if not houseId then return end

  local allowed = {
  name = true, ownerid = true,
  entry_x = true, entry_y = true, entry_z = true,
  garage_trigger_x = true, garage_trigger_y = true, garage_trigger_z = true,
  garage_x = true, garage_y = true, garage_z = true,
  price = true, buyed_at = true,
  rent = true, rent_start = true,
  data = true, lock_state = true,
  secured = true,                -- 👈 NEU
  ipl = true, fridgeid = true, storeid = true,
  hotel = true, apartments = true, garage_size = true,
  allowed_bike = true, allowed_motorbike = true, allowed_car = true,
  allowed_truck = true, allowed_plane = true, allowed_helicopter = true, allowed_boat = true,
  maxkeys = true, keys = true, pincode = true
}

    local sets, vals = {}, {}
    for k, v in pairs(patch) do
        if allowed[k] then
            if k == 'data' or k == 'keys' then
  v = jenc(v)
elseif k == 'lock_state' then
  v = (tonumber(v) == 0) and 0 or 1
elseif k == 'secured' then                                  -- 👈 NEU
  v = (tonumber(v) == 1) and 1 or 0
elseif k ~= 'buyed_at' and k ~= 'rent_start' and k ~= 'name' then
  v = toNumber(v)
end
            sets[#sets+1] = ("`%s` = ?"):format(k)
            vals[#vals+1] = v
        end
    end

    if #sets == 0 then return end

    vals[#vals+1] = houseId

    local affected = MySQL.update.await(
        ("UPDATE houses SET %s WHERE id = ?"):format(table.concat(sets, ", ")),
        vals
    )

    if affected and affected > 0 then
        log("INFO", ("Haus #%d aktualisiert von src=%s"):format(houseId, src))
        TriggerEvent('LCV:house:forceSync')
    end
end)

RegisterNetEvent('LCV:house:delete', function(houseId)
    local src = source
    houseId = tonumber(houseId)
    if not houseId then return end

    MySQL.update.await([[
        DELETE FROM interaction_points
        WHERE JSON_EXTRACT(data, '$.houseid') = ?
    ]], { houseId })

    local affected = MySQL.update.await('DELETE FROM houses WHERE id = ?', { houseId })
    if affected and affected > 0 then
        log("INFO", ("Haus #%d gelöscht von src=%s"):format(houseId, src))
        TriggerEvent('LCV:house:forceSync')
    end
end)

RegisterNetEvent('LCV:house:setLockState', function(houseId, state)
    houseId = tonumber(houseId)
    if not houseId then return end
    local lock = (tonumber(state) == 0) and 0 or 1

    MySQL.update.await('UPDATE houses SET lock_state = ? WHERE id = ?', { lock, houseId })
    TriggerClientEvent('LCV:house:lockChanged', -1, houseId, lock)
end)

RegisterNetEvent('LCV:house:setOwner', function(houseId, ownerId)
    houseId = tonumber(houseId)
    ownerId = tonumber(ownerId) or 0
    if not houseId then return end

    MySQL.update.await([[
        UPDATE houses
        SET ownerid = ?, buyed_at = IF(? > 0, NOW(), buyed_at)
        WHERE id = ?
    ]], { ownerId, ownerId, houseId })
end)

RegisterNetEvent('LCV:house:setRentStart', function(houseId, startDate)
    houseId = tonumber(houseId)
    if not houseId then return end
    MySQL.update.await('UPDATE houses SET rent_start = ? WHERE id = ?', { startDate, houseId })
end)

RegisterNetEvent('LCV:house:requestSync', function()
    sendAllHouses(source)
end)

RegisterNetEvent('LCV:house:forceSync', function()
    sendAllHouses()
end)

-- =========================
-- Enter / Leave
-- =========================

RegisterNetEvent('LCV:house:enter', function(houseId)
    local src = source
    houseId = tonumber(houseId)
    if not houseId then return end

    local house = getHouse(houseId)
    if not house then return end
    if not house.ipl then return end

    local ipl = getHouseIPL(house.ipl)
    if not ipl or not ipl.posx or not ipl.posy or not ipl.posz then return end

    local bucketId = house.id
    if SetPlayerRoutingBucket then
        SetPlayerRoutingBucket(src, bucketId)
    end

    TriggerClientEvent('LCV:house:client:enter', src, {
        houseId     = house.id,
        bucketId    = bucketId,
        inside      = { x = ipl.posx, y = ipl.posy, z = ipl.posz },
        interiorIpl = (ipl.ipl and ipl.ipl ~= '' and ipl.ipl) or nil,
    })
end)

RegisterNetEvent('LCV:house:leave', function(houseId)
    local src = source
    houseId = tonumber(houseId)
    if not houseId then return end

    local house = getHouse(houseId)
    if not house then return end

    local ipl
    if house.ipl then
        ipl = getHouseIPL(house.ipl)
    end

    if SetPlayerRoutingBucket then
        SetPlayerRoutingBucket(src, 0)
    end

    TriggerClientEvent('LCV:house:client:leave', src, {
        houseId     = house.id,
        bucketId    = 0,
        entry       = { x = house.entry_x, y = house.entry_y, z = house.entry_z },
        interiorIpl = (ipl and ipl.ipl and ipl.ipl ~= '' and ipl.ipl) or nil,
    })
end)

-- =========================
-- Weekly Rent Watcher
-- =========================
-- server.cfg:
-- set lcv_house_rent_day 0
-- set lcv_house_rent_hour 22
-- set lcv_house_rent_minute 0

local function getRentConvarInt(name, default)
    local v = tonumber(GetConvar(name, tostring(default)))
    return v or default
end

local rentDay    = getRentConvarInt('lcv_house_rent_day', 0)
local rentHour   = getRentConvarInt('lcv_house_rent_hour', 22)
local rentMinute = getRentConvarInt('lcv_house_rent_minute', 0)

local function isRentTime(now)
    local wday = now.wday - 1 -- 1=Sonntag -> 0
    return (wday == rentDay) and (now.hour == rentHour) and (now.min == rentMinute)
end

local lastRunYDay, lastRunYear = nil, nil

local function runRentCycle()
    log("INFO", "Starte House-Rent-Watcher...")

    local houses = MySQL.query.await([[
        SELECT id, ownerid, rent
        FROM houses
        WHERE ownerid IS NOT NULL
          AND ownerid > 0
          AND rent IS NOT NULL
          AND rent > 0
          AND rent_start IS NOT NULL
    ]]) or {}

    if #houses == 0 then
        log("INFO", "Keine Miet-Häuser für Abrechnung gefunden.")
        return
    end

    for _, h in ipairs(houses) do
        local ownerId = tonumber(h.ownerid)
        local rent    = tonumber(h.rent) or 0
        if ownerId and rent > 0 then
            local acc = MySQL.single.await([[
                SELECT account_number, balance
                FROM bank_accounts
                WHERE owner = ?
                LIMIT 1
            ]], { ownerId })

            if not acc or (acc.balance or 0) < rent then
                MySQL.update.await('UPDATE houses SET ownerid = 0, rent_start = NULL WHERE id = ?', { h.id })
                log("INFO", ("Miete fehlgeschlagen -> Haus #%d von owner=%d freigegeben."):format(h.id, ownerId))
            else
                local affected = MySQL.update.await([[
                    UPDATE bank_accounts
                    SET balance = balance - ?
                    WHERE account_number = ? AND balance >= ?
                ]], { rent, acc.account_number, rent })

                if affected and affected > 0 then
                    MySQL.insert.await([[
                        INSERT INTO bank_log (account_number, kind, amount, source, destination, meta)
                        VALUES (?, 'withdraw', ?, 'house_rent', ?, ?)
                    ]], {
                        acc.account_number,
                        rent,
                        ('house_' .. h.id),
                        jenc({ house_id = h.id, ownerid = ownerId })
                    })

                    log("INFO", ("Miete abgebucht: Haus #%d owner=%d rent=%d")
                        :format(h.id, ownerId, rent))
                else
                    MySQL.update.await('UPDATE houses SET ownerid = 0, rent_start = NULL WHERE id = ?', { h.id })
                    log("INFO", ("Miete RaceFail -> Haus #%d freigegeben."):format(h.id))
                end
            end
        end
    end
end

CreateThread(function()
    log("INFO", ("RentWatcher aktiv: day=%d hour=%d minute=%d"):format(rentDay, rentHour, rentMinute))

    while true do
        Wait(60 * 1000)
        local now = os.date('*t')
        if isRentTime(now) then
            if lastRunYDay ~= now.yday or lastRunYear ~= now.year then
                lastRunYDay = now.yday
                lastRunYear = now.year
                runRentCycle()
            end
        end
    end
end)
