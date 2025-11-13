-- npcmanager/server.lua
-- Zentrale NPC-Quelle (DB + Sync + Admin-Exports)

local RES_NAME = GetCurrentResourceName()
local NPCS = { list = {} }

-- ========= Loader =========
local function loadNPCs()
    local rows = MySQL.query.await([[
        SELECT
            id, name, model, x, y, z, heading,
            scenario, interactionType,
            interactable, autoGround, groundOffset, zOffset
        FROM npcs
        ORDER BY id ASC
    ]]) or {}

    local list = {}
    for _, row in ipairs(rows) do
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

    NPCS = { list = list }
    print(('[NPC] Ready with %d NPC(s) from database'):format(#list))
end

local function sendAll(target)
    if target then
        TriggerClientEvent('lcv:npc:client:load', target, NPCS)
    else
        TriggerClientEvent('lcv:npc:client:load', -1, NPCS)
    end
end

-- ========= Lifecycle =========
AddEventHandler('onResourceStart', function(res)
    if res ~= RES_NAME then return end
    loadNPCs()
    sendAll()
end)

AddEventHandler('playerJoining', function()
    local src = source
    if not src or src <= 0 then return end
    CreateThread(function()
        Wait(1000)
        sendAll(src)
    end)
end)

RegisterNetEvent('npc_reload', function()
    loadNPCs()
    sendAll()
end)

RegisterNetEvent('lcv:npc:server:requestReload', function()
    local src = source
    loadNPCs()
    if src and src > 0 then sendAll(src) else sendAll() end
end)

RegisterNetEvent('lcv:npc:server:requestAll', function()
    local src = source
    if src and src > 0 then sendAll(src) end
end)

-- ========= Admin-Exports (SSOT) =========
local function toN(v, d) local n=tonumber(v); if n==nil then return d end; return n end

local function Admin_NPCs_GetAll()
    local rows = MySQL.query.await([[
        SELECT id, name, model, x, y, z, heading,
               scenario, interactionType,
               interactable, autoGround, groundOffset, zOffset
        FROM npcs
        ORDER BY id
    ]]) or {}

    for _, r in ipairs(rows) do
        r.interactable = (r.interactable == 1 or r.interactable == true)
        r.autoGround   = (r.autoGround == 1 or r.autoGround == true)
        r.groundOffset = tonumber(r.groundOffset) or 0.1
        r.zOffset      = tonumber(r.zOffset) or 0.0
        r.x            = tonumber(r.x) or 0.0
        r.y            = tonumber(r.y) or 0.0
        r.z            = tonumber(r.z) or 0.0
        r.heading      = tonumber(r.heading) or 0.0
    end
    return rows
end
exports('Admin_NPCs_GetAll', Admin_NPCs_GetAll)

local function Admin_NPCs_Add(data)
    if not data or not data.name or not data.model then
        return { ok = false, error = 'Ungültige Daten' }
    end
    local id = MySQL.insert.await([[
        INSERT INTO npcs
            (name, model, x, y, z, heading, scenario, interactionType,
             interactable, autoGround, groundOffset, zOffset)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        tostring(data.name),
        tostring(data.model),
        toN(data.x, 0.0), toN(data.y, 0.0), toN(data.z, 0.0),
        toN(data.heading, 0.0),
        (data.scenario and tostring(data.scenario) or nil),
        (data.interactionType and tostring(data.interactionType) or nil),
        (data.interactable and 1 or 0),
        (data.autoGround and 1 or 0),
        toN(data.groundOffset, 0.1),
        toN(data.zOffset, 0.0)
    })
    if not id or id <= 0 then return { ok=false, error='Insert fehlgeschlagen' } end
    loadNPCs(); sendAll()
    return { ok=true, id=id }
end
exports('Admin_NPCs_Add', Admin_NPCs_Add)

local function Admin_NPCs_Update(data)
    local id = toN(data and data.id)
    if not id then return { ok=false, error='Ungültige ID' } end

    local affected = MySQL.update.await([[
        UPDATE npcs
        SET name = ?, model = ?, x = ?, y = ?, z = ?, heading = ?,
            scenario = ?, interactionType = ?,
            interactable = ?, autoGround = ?, groundOffset = ?, zOffset = ?
        WHERE id = ?
    ]], {
        tostring(data.name or ''),
        tostring(data.model or ''),
        toN(data.x, 0.0), toN(data.y, 0.0), toN(data.z, 0.0),
        toN(data.heading, 0.0),
        (data.scenario and tostring(data.scenario) or nil),
        (data.interactionType and tostring(data.interactionType) or nil),
        (data.interactable and 1 or 0),
        (data.autoGround and 1 or 0),
        toN(data.groundOffset, 0.1),
        toN(data.zOffset, 0.0),
        id
    })
    local okUpdate = (affected or 0) > 0
    if okUpdate then loadNPCs(); sendAll() end
    return { ok=okUpdate, error = okUpdate and nil or 'Kein Datensatz geändert' }
end
exports('Admin_NPCs_Update', Admin_NPCs_Update)

local function Admin_NPCs_Delete(data)
    local id = toN(data and data.id)
    if not id then return { ok=false, error='Ungültige ID' } end

    local okQ, affected = pcall(function()
        return MySQL.update.await('DELETE FROM npcs WHERE id = ?', { id })
    end)
    if not okQ then
        print(('[NPC] Delete error for id %s: %s'):format(id, tostring(affected)))
        return { ok=false, error='DB-Fehler (siehe Server)' }
    end
    local okDel = (affected or 0) > 0
    if okDel then loadNPCs(); sendAll() end
    return { ok=okDel, error = okDel and nil or 'Kein Datensatz gelöscht' }
end
exports('Admin_NPCs_Delete', Admin_NPCs_Delete)
