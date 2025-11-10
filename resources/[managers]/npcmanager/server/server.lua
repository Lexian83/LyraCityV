-- npcmanager/server.lua
-- Lädt NPC-Definitionen aus der Datenbank (Tabelle `npcs`)
-- und sendet sie an Clients.

local RES_NAME = GetCurrentResourceName()
local NPCS = { list = {} }

--- NPCs aus DB laden (Tabelle `npcs`)
local function loadNPCs()
    local rows = MySQL.query.await([[
        SELECT
            id,
            name,
            model,
            x, y, z,
            heading,
            scenario,
            interactionType,
            interactable,
            autoGround,
            groundOffset,
            zOffset
        FROM npcs
        ORDER BY id ASC
    ]]) or {}

    local list = {}

    if #rows > 0 then
        for _, row in ipairs(rows) do
            -- Sicher casten, weil oxmysql gern Strings liefert
            local id           = tonumber(row.id) or 0
            local x            = tonumber(row.x) or 0.0
            local y            = tonumber(row.y) or 0.0
            local z            = tonumber(row.z) or 0.0
            local heading      = tonumber(row.heading) or 0.0
            local interactable = tonumber(row.interactable) or 0
            local autoGround   = tonumber(row.autoGround) or 0
            local groundOffset = tonumber(row.groundOffset) or 0.0
            local zOffset      = tonumber(row.zOffset) or 0.0

            list[#list + 1] = {
                id              = id,
                name            = row.name or ("NPC " .. id),
                model           = row.model,
                coords          = { x = x, y = y, z = z },
                heading         = heading,
                scenario        = row.scenario,
                interactionType = row.interactionType,
                interactable    = (interactable == 1),
                autoGround      = (autoGround == 1),
                groundOffset    = groundOffset,
                zOffset         = zOffset
            }
        end
    end

    NPCS = { list = list }

    print(('[NPC] Ready with %d NPC(s) from database'):format(#list))
end

--- NPC-Daten an Client(s) schicken
local function sendAll(target)
    if target then
        TriggerClientEvent('lcv:npc:client:load', target, NPCS)
    else
        TriggerClientEvent('lcv:npc:client:load', -1, NPCS)
    end
end

-- Resource-Start: DB laden + an alle schicken
AddEventHandler('onResourceStart', function(res)
    if res ~= RES_NAME then return end
    loadNPCs()
    sendAll()
end)

-- Spieler joint: bekommt aktuelle Liste
AddEventHandler('playerJoining', function()
    local src = source
    if not src or src <= 0 then return end

    CreateThread(function()
        Wait(1000)
        sendAll(src)
    end)
end)

-- Admin / Debug / Hot-Reload: NPCs neu laden (aus DB)
RegisterNetEvent('npc_reload', function()
    -- Kann sowohl vom Server (TriggerEvent) als auch Client (TriggerServerEvent) kommen
    loadNPCs()
    sendAll() -- immer an alle, damit alle denselben Stand haben
end)

-- Expliziter Reload-Request (z.B. von Admin-Tools)
RegisterNetEvent('lcv:npc:server:requestReload', function()
    local src = source
    loadNPCs()
    if src and src > 0 then
        sendAll(src)
    else
        sendAll()
    end
end)

-- Client will nur aktuelle Daten (ohne Reload)
RegisterNetEvent('lcv:npc:server:requestAll', function()
    local src = source
    if src and src > 0 then
        sendAll(src)
    end
end)
