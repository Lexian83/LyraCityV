-- blipmanager/server/server.lua

local RES_NAME = GetCurrentResourceName()
local BLIPS = { list = {} }

local function toNumber(val, default)
    if val == nil then return default end

    if type(val) == "number" then
        return val
    end

    if type(val) == "string" then
        -- Komma zu Punkt, falls MySQL / phpMyAdmin lokalisiert exportiert
        local fixed = val:gsub(",", ".")
        local n = tonumber(fixed)
        if n ~= nil then
            return n
        end
    end

    return default
end

local function toBool(v)
    return v == true or v == 1 or v == "1" or v == "true"
end

local function loadBlips()
    local rows = MySQL.query.await([[
        SELECT
            `id`,
            `name`,
            `x`, `y`, `z`,
            `sprite`,
            `color`,
            `scale`,
            `shortRange`,
            `display`,
            `category`,
            `visiblefor`,
            `enabled`
        FROM `blips`
        ORDER BY `id` ASC
    ]]) or {}

    local list = {}
    local total = #rows

    for _, row in ipairs(rows) do
        local id    = toNumber(row.id, 0)
        local x     = toNumber(row.x, 0.0)
        local y     = toNumber(row.y, 0.0)
        local z     = toNumber(row.z, 0.0)

        local spr   = toNumber(row.sprite, 1)
        local col   = toNumber(row.color, 0)
        local scale = toNumber(row.scale, 1.0)
        if scale <= 0.0 then scale = 1.0 end

        local sr       = toBool(row.shortRange)
        local display  = toNumber(row.display, 2)
        local vis      = toNumber(row.visiblefor, 0)
        local enabled  = toBool(row.enabled)

        -- Nur sinnvolle display-Werte
        if display ~= 2 and display ~= 3 then
            display = 2
        end

        if enabled then
            list[#list + 1] = {
                id         = id,
                name       = row.name or ("Blip " .. id),
                coords     = { x = x, y = y, z = z },
                sprite     = spr,
                color      = col,
                scale      = scale,
                shortRange = sr,
                display    = display,
                category   = row.category or nil,
                visiblefor = vis
            }
        end
    end

    BLIPS = { list = list }

    print(("[BLIP] Loaded %d row(s), %d active blip(s) from database"):format(total, #list))
end

local function sendAll(target)
    if target then
        TriggerClientEvent('lcv:blip:client:load', target, BLIPS)
    else
        TriggerClientEvent('lcv:blip:client:load', -1, BLIPS)
    end
end

AddEventHandler('onResourceStart', function(res)
    if res ~= RES_NAME then return end
    loadBlips()
    sendAll()
end)

RegisterNetEvent('blip_reload', function()
    loadBlips()
    sendAll()
end)

AddEventHandler('playerJoining', function()
    local src = source
    if src and src > 0 then
        CreateThread(function()
            Wait(1000)
            sendAll(src)
        end)
    end
end)

RegisterNetEvent('lcv:blip:server:requestAll', function()
    local src = source
    if src and src > 0 then
        sendAll(src)
    end
end)
