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
-- ================== HOUSE IPL ==================

lib.callback.register('LCV:ADMIN:HousesIPL:GetAll', function(source)
    if not hasAdminPermission(source, 10) then
        return { ok = false, error = 'Keine Berechtigung', ipls = {} }
    end

    local rows = MySQL.query.await([[
        SELECT id, ipl_name, ipl, posx, posy, posz, exit_x, exit_y, exit_z
        FROM house_ipl
        ORDER BY id ASC
    ]]) or {}

    for _, r in ipairs(rows) do
        r.id     = tonumber(r.id) or 0
        r.posx   = tonumber(r.posx) or 0.0
        r.posy   = tonumber(r.posy) or 0.0
        r.posz   = tonumber(r.posz) or 0.0
        r.exit_x = tonumber(r.exit_x) or 0.0
        r.exit_y = tonumber(r.exit_y) or 0.0
        r.exit_z = tonumber(r.exit_z) or 0.0
    end

    return { ok = true, ipls = rows }
end)

lib.callback.register('LCV:ADMIN:HousesIPL:Add', function(source, data)
    if not hasAdminPermission(source, 10) then
        return { ok = false, error = 'Keine Berechtigung' }
    end
    if not data or not data.ipl_name then
        return { ok = false, error = 'ipl_name ist erforderlich' }
    end

    local id = MySQL.insert.await([[
        INSERT INTO house_ipl (ipl_name, ipl, posx, posy, posz, exit_x, exit_y, exit_z)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        tostring(data.ipl_name),
        tostring(data.ipl or ''),
        tonumber(data.posx) or 0.0,
        tonumber(data.posy) or 0.0,
        tonumber(data.posz) or 0.0,
        tonumber(data.exit_x) or 0.0,
        tonumber(data.exit_y) or 0.0,
        tonumber(data.exit_z) or 0.0
    })

    if not id or id <= 0 then
        return { ok = false, error = 'Insert fehlgeschlagen' }
    end

    return { ok = true, id = id }
end)

lib.callback.register('LCV:ADMIN:HousesIPL:Update', function(source, data)
    if not hasAdminPermission(source, 10) then
        return { ok = false, error = 'Keine Berechtigung' }
    end

    local id = tonumber(data and data.id)
    if not id then
        return { ok = false, error = 'Ungültige ID' }
    end

    MySQL.update.await([[
        UPDATE house_ipl
        SET ipl_name = ?, ipl = ?, posx = ?, posy = ?, posz = ?, exit_x = ?, exit_y = ?, exit_z = ?
        WHERE id = ?
    ]], {
        tostring(data.ipl_name or ''),
        tostring(data.ipl or ''),
        tonumber(data.posx) or 0.0,
        tonumber(data.posy) or 0.0,
        tonumber(data.posz) or 0.0,
        tonumber(data.exit_x) or 0.0,
        tonumber(data.exit_y) or 0.0,
        tonumber(data.exit_z) or 0.0,
        id
    })

    -- EXIT_HOUSE aktualisieren für verknüpfte Häuser
    local houses = MySQL.query.await('SELECT id FROM houses WHERE ipl = ?', { id }) or {}
    if #houses > 0 then
        for _, h in ipairs(houses) do
            MySQL.update.await([[
                UPDATE interaction_points
                SET x = ?, y = ?, z = ?
                WHERE name = 'EXIT_HOUSE' AND JSON_EXTRACT(data, '$.houseid') = ?
            ]], {
                tonumber(data.exit_x) or 0.0,
                tonumber(data.exit_y) or 0.0,
                tonumber(data.exit_z) or 0.0,
                tonumber(h.id)
            })
        end
        TriggerEvent('lcv:interaction:server:reloadPoints')
    end

    return { ok = true }
end)

lib.callback.register('LCV:ADMIN:HousesIPL:Delete', function(source, data)
    if not hasAdminPermission(source, 10) then
        return { ok = false, error = 'Keine Berechtigung' }
    end

    local id = tonumber(data and data.id)
    if not id then
        return { ok = false, error = 'Ungültige ID' }
    end

    local okQ, affected = pcall(function()
        return MySQL.update.await('DELETE FROM house_ipl WHERE id = ?', { id })
    end)

    if not okQ or (affected or 0) <= 0 then
        return { ok = false, error = 'Kein Datensatz gelöscht' }
    end

    return { ok = true }
end)

RegisterNetEvent('LCV:ADMIN:HousesIPL:Teleport', function(id, x, y, z)
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