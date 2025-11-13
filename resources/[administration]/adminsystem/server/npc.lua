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
-- ================== NPCs ==================

lib.callback.register('LCV:ADMIN:Npcs:GetAll', function(source)
    if not hasAdminPermission(source, 10) then
        return { ok = false, error = 'Keine Berechtigung', npcs = {} }
    end

    local rows = MySQL.query.await([[
        SELECT id, name, model, x, y, z, heading, scenario, interactionType,
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

    return { ok = true, npcs = rows }
end)

lib.callback.register('LCV:ADMIN:Npcs:Add', function(source, data)
    if not hasAdminPermission(source, 10) then
        return { ok = false, error = 'Keine Berechtigung' }
    end
    if not data or not data.name or not data.model then
        return { ok = false, error = 'Ungültige Daten' }
    end

    local name  = tostring(data.name)
    local model = tostring(data.model)
    local x     = tonumber(data.x) or 0.0
    local y     = tonumber(data.y) or 0.0
    local z     = tonumber(data.z) or 0.0
    local h     = tonumber(data.heading) or 0.0

    local scenario        = data.scenario and tostring(data.scenario) or nil
    local interactionType = data.interactionType and tostring(data.interactionType) or nil
    local interactable    = data.interactable and 1 or 0
    local autoGround      = data.autoGround and 1 or 0
    local groundOffset    = tonumber(data.groundOffset) or 0.1
    local zOffset         = tonumber(data.zOffset) or 0.0

    local id = MySQL.insert.await([[
        INSERT INTO npcs
            (name, model, x, y, z, heading, scenario, interactionType,
             interactable, autoGround, groundOffset, zOffset)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        name, model, x, y, z, h,
        scenario, interactionType,
        interactable, autoGround, groundOffset, zOffset
    })

    if not id or id <= 0 then
        return { ok = false, error = 'Insert fehlgeschlagen' }
    end

    TriggerEvent('npc_reload')

    return { ok = true, id = id }
end)

lib.callback.register('LCV:ADMIN:Npcs:Update', function(source, data)
    if not hasAdminPermission(source, 10) then
        return { ok = false, error = 'Keine Berechtigung' }
    end
    if not data or not data.id then
        return { ok = false, error = 'Ungültige Daten' }
    end

    local id = tonumber(data.id)
    if not id then
        return { ok = false, error = 'Ungültige ID' }
    end

    local name  = tostring(data.name or '')
    local model = tostring(data.model or '')
    local x     = tonumber(data.x) or 0.0
    local y     = tonumber(data.y) or 0.0
    local z     = tonumber(data.z) or 0.0
    local h     = tonumber(data.heading) or 0.0

    local scenario        = data.scenario and tostring(data.scenario) or nil
    local interactionType = data.interactionType and tostring(data.interactionType) or nil
    local interactable    = data.interactable and 1 or 0
    local autoGround      = data.autoGround and 1 or 0
    local groundOffset    = tonumber(data.groundOffset) or 0.1
    local zOffset         = tonumber(data.zOffset) or 0.0

    local affected = MySQL.update.await([[
        UPDATE npcs
        SET name = ?, model = ?, x = ?, y = ?, z = ?, heading = ?,
            scenario = ?, interactionType = ?,
            interactable = ?, autoGround = ?, groundOffset = ?, zOffset = ?
        WHERE id = ?
    ]], {
        name, model, x, y, z, h,
        scenario, interactionType,
        interactable, autoGround, groundOffset, zOffset,
        id
    })

    local okUpdate = (affected or 0) > 0

    if okUpdate then
        TriggerEvent('npc_reload')
    end

    return {
        ok = okUpdate,
        error = okUpdate and nil or 'Kein Datensatz geändert'
    }
end)

lib.callback.register('LCV:ADMIN:Npcs:Delete', function(source, data)
    if not hasAdminPermission(source, 10) then
        return { ok = false, error = 'Keine Berechtigung' }
    end

    local id = tonumber(data and data.id)
    if not id then
        return { ok = false, error = 'Ungültige ID' }
    end

    local okQuery, affected = pcall(function()
        return MySQL.update.await('DELETE FROM npcs WHERE id = ?', { id })
    end)

    if not okQuery then
        print(('[LCV:ADMIN] NPC Delete error for id %s: %s'):format(id, tostring(affected)))
        return { ok = false, error = 'DB-Fehler (siehe Server-Konsole)' }
    end

    local okDelete = (affected or 0) > 0

    if okDelete then
        TriggerEvent('npc_reload')
    end

    return {
        ok = okDelete,
        error = okDelete and nil or 'Kein Datensatz gelöscht'
    }
end)
-- ================== NPCs: TELEPORT ==================

RegisterNetEvent('LCV:ADMIN:Npcs:Teleport', function(id, x, y, z)
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
