-- interactionmanager/server.lua
-- Lädt statische Interaktionspunkte aus `interaction_points`
-- und verteilt sie an alle Clients.

local RES_NAME = GetCurrentResourceName()
local POINTS = {}

local function loadInteractionPoints()
    local rows = MySQL.query.await([[
        SELECT id, name, description, type, x, y, z, radius, enabled, data
        FROM interaction_points
        WHERE enabled = 1
        ORDER BY id ASC
    ]])

    POINTS = {}

    if rows and #rows > 0 then
        for _, row in ipairs(rows) do
            local entry = {
                id = row.id,
                name = row.name,
                description = row.description,
                type = row.type,
                coords = { x = row.x, y = row.y, z = row.z },
                radius = row.radius or 1.5,
                data = nil,
            }

            if row.data and row.data ~= "" then
                local ok, decoded = pcall(json.decode, row.data)
                if ok and type(decoded) == "table" then
                    entry.data = decoded
                end
            end

            POINTS[#POINTS + 1] = entry
        end
    end

    print(("[INTERACT] Loaded %d interaction points from database."):format(#POINTS))
end

local function sendAllPoints(target)
    if target then
        TriggerClientEvent('lcv:interaction:client:setPoints', target, POINTS)
    else
        TriggerClientEvent('lcv:interaction:client:setPoints', -1, POINTS)
    end
end

AddEventHandler('onResourceStart', function(res)
    if res ~= RES_NAME then return end
    loadInteractionPoints()
    sendAllPoints()
end)

AddEventHandler('playerJoining', function()
    local src = source
    if not src or src <= 0 then return end
    CreateThread(function()
        Wait(1000)
        sendAllPoints(src)
    end)
end)

-- Hot-Reload für Admins (z.B. nach Edit im Adminpanel)
RegisterNetEvent('lcv:interaction:server:reloadPoints', function()
    -- hier ggf. Permission-Check einbauen
    loadInteractionPoints()
    sendAllPoints()
end)

-- Nur aktuelle Punkte ziehen (ohne DB-Reload)
RegisterNetEvent('lcv:interaction:server:requestPoints', function()
    local src = source
    if src and src > 0 then
        sendAllPoints(src)
    end
end)
