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

-- Sicherstellen, dass MySQL verfügbar ist
if not MySQL then
    print('[HouseManager][WARN] MySQL ist nil beim Laden. Prüfe @oxmysql/lib/MySQL.lua im fxmanifest.')
end


local function toNumber(val)
    local n = tonumber(val)
    return n
end

local function jenc(v)
    if v == nil then return nil end
    if type(v) == "string" then return v end
    local ok, res = pcall(json.encode, v)
    if ok then return res end
    return nil
end

local function createInteractionPoint(name, description, pType, x, y, z, dataTbl)
    if not x or not y or not z then return end

    local dataJson = jenc(dataTbl)

    MySQL.insert.await([[
        INSERT INTO interaction_points
            (name, description, type, x, y, z, radius, enabled, data)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        name,
        description or name,
        pType,
        tonumber(x) or 0.0,
        tonumber(y) or 0.0,
        tonumber(z) or 0.0,
        1.0,                        -- radius = 1
        1,                          -- enabled = 1
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
    return MySQL.single.await('SELECT id, ipl_name, ipl, posx, posy, posz, exit_x, exit_y, exit_z FROM house_ipl WHERE id = ?', { iplId })
end


local function getAllHouses()
    local rows = MySQL.query.await([[
        SELECT id, garage_trigger_x, garage_trigger_y, garage_trigger_z
        FROM houses
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
        log("DEBUG", ("House[1]: id=%s gt_x=%s gt_y=%s gt_z=%s"):format(
            tostring(h.id),
            tostring(h.garage_trigger_x),
            tostring(h.garage_trigger_y),
            tostring(h.garage_trigger_z)
        ))
    end
end


-- =========================
-- Exports
-- =========================

-- getownerbyhouseid(houseId) -> ownerid or nil
exports('getownerbyhouseid', function(houseId)
    local row = MySQL.single.await('SELECT ownerid FROM houses WHERE id = ?', { tonumber(houseId) })
    return row and tonumber(row.ownerid) or nil
end)

-- getlockstate(houseId) -> 0/1 or nil
exports('getlockstate', function(houseId)
    local row = MySQL.single.await('SELECT lock_state FROM houses WHERE id = ?', { tonumber(houseId) })
    return row and tonumber(row.lock_state) or nil
end)

-- getrent(houseId) -> rent or nil
exports('getrent', function(houseId)
    local row = MySQL.single.await('SELECT rent FROM houses WHERE id = ?', { tonumber(houseId) })
    return row and tonumber(row.rent) or nil
end)

-- getprice(houseId) -> price or nil
exports('getprice', function(houseId)
    local row = MySQL.single.await('SELECT price FROM houses WHERE id = ?', { tonumber(houseId) })
    return row and tonumber(row.price) or nil
end)

-- =========================
-- House CRUD Events
-- (TODO: Permissions an dein Adminsystem hängen)
-- =========================

-- House erstellen
RegisterNetEvent('LCV:house:create', function(data)
    local src  = source
    data       = data or {}

    -- Minimal-Validation
    local name = tostring(data.name or ""):sub(1, 128)
    if name == "" then
        log("WARN", ("create: ungültiger Name von src=%s"):format(src))
        return
    end

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
        (data.lock_state == 0 and 0) or 1,
        toNumber(data.inside_x),
        toNumber(data.inside_y),
        toNumber(data.inside_z),
        toNumber(data.ipl),
        toNumber(data.fridgeid),
        toNumber(data.storeid)
    }

    local id = MySQL.insert.await([[
        INSERT INTO houses
        (name, ownerid, entry_x, entry_y, entry_z,
         garage_trigger_x, garage_trigger_y, garage_trigger_z,
         garage_x, garage_y, garage_z,
         price, buyed_at, rent, rent_start, data, lock_state,
         inside_x, inside_y, inside_z, ipl, fridgeid, storeid)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], params)

    if id and id > 0 then
    local houseId   = id
    local houseName = name

    -- ENTRY: HOUSE
    -- name = "HOUSE"
    -- description = houses.name
    -- type = "house"
    -- xyz = entry_x/y/z
    createInteractionPoint(
        'HOUSE',
        houseName,
        'house',
        params[3], params[4], params[5],
        { houseid = houseId }
    )

    -- GARAGE: HOUSE_GARAGE (nur wenn Trigger-Koordinaten vorhanden)
    -- name = "HOUSE_GARAGE"
    -- description = houses.name
    -- type = "garage"
    -- xyz = garage_trigger_x/y/z
    if params[6] and params[7] and params[8] then
        createInteractionPoint(
            'HOUSE_GARAGE',
            houseName,
            'garage',
            params[6], params[7], params[8],
            { houseid = houseId }
        )
    end

    -- EXIT: EXIT_HOUSE (nur wenn ipl + exit_x/y/z definiert)
    -- name = "EXIT_HOUSE"
    -- description = houses.name
    -- type = "house" (gleicher Typ wie Entry für deinen Interaction-Flow)
    -- xyz = exit_x/y/z aus house_ipl
    local iplId = params[21]
    if iplId then
        local ipl = MySQL.single.await('SELECT exit_x, exit_y, exit_z FROM house_ipl WHERE id = ?', { iplId })
        if ipl and ipl.exit_x and ipl.exit_y and ipl.exit_z then
            createInteractionPoint(
                'EXIT_HOUSE',
                houseName,
                'house',
                ipl.exit_x, ipl.exit_y, ipl.exit_z,
                { houseid = houseId }
            )
        else
            log("WARN", ("Haus #%d: ipl=%s hat keine exit_x/y/z, EXIT_HOUSE nicht erzeugt."):format(houseId, tostring(iplId)))
        end
    end

    log("INFO", ("Haus + InteractionPoints erstellt #%d von src=%s"):format(houseId, src))
    TriggerClientEvent('LCV:house:refresh', -1, houseId)
    sendAllHouses()
else
    log("ERROR", ("Haus erstellen fehlgeschlagen von src=%s"):format(src))
end

end)

-- Haus updaten (only whitelisted Felder)
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
        inside_x = true, inside_y = true, inside_z = true,
        ipl = true, fridgeid = true, storeid = true,
    }

    local sets, vals = {}, {}
    for k, v in pairs(patch) do
        if allowed[k] then
            if k == 'data' then
                v = jenc(v)
            elseif k == 'lock_state' then
                v = (tonumber(v) == 0) and 0 or 1
            elseif k ~= 'buyed_at' and k ~= 'rent_start' and k ~= 'name' then
                v = toNumber(v)
            end
            table.insert(sets, ("`%s` = ?"):format(k))
            table.insert(vals, v)
        end
    end

    if #sets == 0 then return end

    table.insert(vals, houseId)

    local affected = MySQL.update.await(
        ("UPDATE houses SET %s WHERE id = ?"):format(table.concat(sets, ", ")),
        vals
    )

    if affected and affected > 0 then
        log("INFO", ("Haus #%d aktualisiert von src=%s"):format(houseId, src))
        TriggerClientEvent('LCV:house:refresh', -1, houseId)
        sendAllHouses()
    end
end)

-- Haus löschen
RegisterNetEvent('LCV:house:delete', function(houseId)
    local src = source
    houseId = tonumber(houseId)
    if not houseId then return end

    local affected = MySQL.update.await('DELETE FROM houses WHERE id = ?', { houseId })
    if affected and affected > 0 then
        log("INFO", ("Haus #%d gelöscht von src=%s"):format(houseId, src))
        TriggerClientEvent('LCV:house:deleted', -1, houseId)
        sendAllHouses()
    end
end)

-- lockstate updaten
RegisterNetEvent('LCV:house:setLockState', function(houseId, state)
    houseId = tonumber(houseId)
    local src = source
    if not houseId then return end
    local lock = (tonumber(state) == 0) and 0 or 1

    MySQL.update.await('UPDATE houses SET lock_state = ? WHERE id = ?', { lock, houseId })
    log("DEBUG", ("LockState Haus #%d -> %d (src=%s)"):format(houseId, lock, src))
    TriggerClientEvent('LCV:house:lockChanged', -1, houseId, lock)
end)

-- owner updaten
RegisterNetEvent('LCV:house:setOwner', function(houseId, ownerId)
    houseId = tonumber(houseId)
    ownerId = tonumber(ownerId) or 0
    if not houseId then return end

    MySQL.update.await('UPDATE houses SET ownerid = ?, buyed_at = IF(? > 0, NOW(), buyed_at) WHERE id = ?', {
        ownerId, ownerId, houseId
    })
    log("INFO", ("Owner Haus #%d -> %d"):format(houseId, ownerId))
    TriggerClientEvent('LCV:house:ownerChanged', -1, houseId, ownerId)
end)

-- rentstart updaten
RegisterNetEvent('LCV:house:setRentStart', function(houseId, startDate)
    houseId = tonumber(houseId)
    if not houseId then return end
    -- startDate: string 'YYYY-MM-DD HH:MM:SS' oder nil
    MySQL.update.await('UPDATE houses SET rent_start = ? WHERE id = ?', { startDate, houseId })
    log("DEBUG", ("RentStart Haus #%d -> %s"):format(houseId, tostring(startDate)))
end)

-- Sync für die kreise auf dem boden
RegisterNetEvent('LCV:house:requestSync', function()
    local src = source
    sendAllHouses(src)
end)

-- =========================
-- Enter / Leave House
-- =========================
-- erwartet: Client triggert diese Serverevents mit gültiger houseId

RegisterNetEvent('LCV:house:enter', function(houseId)
    local src = source
    houseId = tonumber(houseId)
    if not houseId then return end

    local house = getHouse(houseId)
    if not house then return end

    if not house.ipl then
        log("WARN", ("Enter: Haus #%d hat kein IPL gesetzt."):format(houseId))
        return
    end

    local ipl = getHouseIPL(house.ipl)
    if not ipl or not ipl.posx or not ipl.posy or not ipl.posz then
        log("WARN", ("Enter: Keine Innenposition für Haus #%d (IPL #%s)"):format(houseId, tostring(house.ipl)))
        return
    end

    local bucketId = house.id
    if SetPlayerRoutingBucket then
        SetPlayerRoutingBucket(src, bucketId)
    end

    TriggerClientEvent('LCV:house:client:enter', src, {
        houseId     = house.id,
        bucketId    = bucketId,
        inside      = { x = ipl.posx, y = ipl.posy, z = ipl.posz },
        interiorIpl = ipl.ipl and ipl.ipl ~= '' and ipl.ipl or nil,
    })
end)


RegisterNetEvent('LCV:house:leave', function(houseId)
    local src = source
    houseId = tonumber(houseId)
    if not houseId then return end

    local house = getHouse(houseId)
    if not house then return end

    local ipl = nil
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
        interiorIpl = ipl and ipl.ipl and ipl.ipl ~= '' and ipl.ipl or nil,
    })
end)


-- =========================
-- Weekly Rent Watcher
-- =========================
-- Konfig in server.cfg:
-- set lcv_house_rent_day 0    # 0=Sonntag, 1=Montag, ... 6=Samstag
-- set lcv_house_rent_hour 22
-- set lcv_house_rent_minute 0

local function getRentConvarInt(name, default)
    local v = tonumber(GetConvar(name, tostring(default)))
    if not v then return default end
    return v
end

local rentDay    = getRentConvarInt('lcv_house_rent_day', 0)
local rentHour   = getRentConvarInt('lcv_house_rent_hour', 22)
local rentMinute = getRentConvarInt('lcv_house_rent_minute', 0)

-- Lua: os.date('*t').wday: 1=Sonntag ... 7=Samstag
local function isRentTime(now)
    local wday = (now.wday - 1) -- 0-6
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
            local acc = MySQL.single.await('SELECT account_number, balance FROM bank_accounts WHERE owner = ? LIMIT 1', { ownerId })

            if not acc or (acc.balance or 0) < rent then
                -- Kein/zu wenig Geld -> Haus freigeben
                MySQL.update.await('UPDATE houses SET ownerid = 0, rent_start = NULL WHERE id = ?', { h.id })
                log("INFO", ("Miete fehlgeschlagen -> Haus #%d von owner=%d freigegeben."):format(h.id, ownerId))
            else
                -- Abbuchen
                local affected = MySQL.update.await([[
                    UPDATE bank_accounts
                    SET balance = balance - ?
                    WHERE account_number = ? AND balance >= ?
                ]], { rent, acc.account_number, rent })

                if affected and affected > 0 then
                    local newBal = MySQL.scalar.await('SELECT balance FROM bank_accounts WHERE account_number = ?', { acc.account_number }) or 0

                    MySQL.insert.await([[
                        INSERT INTO bank_log (account_number, kind, amount, source, destination, meta)
                        VALUES (?, ?, ?, ?, ?, ?)
                    ]], {
                        acc.account_number,
                        'withdraw',
                        rent,
                        'house_rent',
                        ('house_' .. h.id),
                        jenc({ house_id = h.id, ownerid = ownerId })
                    })

                    log("INFO", ("Miete abgebucht: Haus #%d owner=%d rent=%d newBalance=%d")
                        :format(h.id, ownerId, rent, newBal))
                else
                    -- Race-Condition / plötzlich kein Geld -> freigeben
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
        Wait(60 * 1000) -- 1x pro Minute prüfen

        local now = os.date('*t')
        if isRentTime(now) then
            -- Nur einmal pro Tag bei passender Minute
            if lastRunYDay ~= now.yday or lastRunYear ~= now.year then
                lastRunYDay  = now.yday
                lastRunYear  = now.year
                runRentCycle()
            end
        end
    end
end)
