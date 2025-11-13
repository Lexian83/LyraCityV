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
-- ================== ADMIN PERMISSION SYSTEM ==================

local function getAllFactionPerms()
    local rows = MySQL.query.await([[
        SELECT id, perm_key, label, allowed_factions, sort_index, is_active
        FROM faction_permission_schema
        ORDER BY sort_index ASC, id ASC
    ]]) or {}

    for _, r in ipairs(rows) do
        r.sort_index = tonumber(r.sort_index) or 100
        r.is_active = (r.is_active == 1 or r.is_active == true)

        if r.allowed_factions and r.allowed_factions ~= '' then
            local ok, parsed = pcall(json.decode, r.allowed_factions)
            if ok and type(parsed) == 'table' then
                r.allowed_text = table.concat(parsed, ",")
            else
                r.allowed_text = r.allowed_factions
            end
        else
            r.allowed_text = ""
        end
    end

    return rows
end

lib.callback.register('LCV:ADMIN:FactionPerms:GetAll', function(source, _)
    if not hasAdminPermission(source, 10) then
        return { ok = false, error = 'Keine Berechtigung', perms = {} }
    end

    local perms = getAllFactionPerms()
    return { ok = true, perms = perms }
end)

lib.callback.register('LCV:ADMIN:FactionPerms:Save', function(source, data)
    if not hasAdminPermission(source, 10) then
        return { ok = false, error = 'Keine Berechtigung' }
    end

    if not data or not data.perm_key or data.perm_key == '' or not data.label or data.label == '' then
        return { ok = false, error = 'perm_key und label sind erforderlich.' }
    end

    local perm_key   = tostring(data.perm_key)
    local label      = tostring(data.label)
    local sort_index = tonumber(data.sort_index) or 100
    local is_active  = data.is_active and 1 or 0

    local allowed_json = nil
    if data.allowed_text and data.allowed_text ~= '' then
        local list = {}
        for token in string.gmatch(data.allowed_text, '([^,%s]+)') do
            list[#list+1] = token
        end
        if #list > 0 then
            allowed_json = json.encode(list)
        end
    end

    if data.id then
        local id = tonumber(data.id)
        if not id then
            return { ok = false, error = 'Ungültige ID' }
        end

        local okQ, res = pcall(function()
            return MySQL.update.await([[
                UPDATE faction_permission_schema
                SET perm_key = ?, label = ?, allowed_factions = ?, sort_index = ?, is_active = ?
                WHERE id = ?
            ]], { perm_key, label, allowed_json, sort_index, is_active, id })
        end)

        if not okQ then
            print('[LCV:ADMIN:FactionPerms] Update-Fehler:', res)
            return { ok = false, error = 'DB-Fehler beim Update (Konsole prüfen)' }
        end
    else
        local okQ, res = pcall(function()
            return MySQL.insert.await([[
                INSERT INTO faction_permission_schema (perm_key, label, allowed_factions, sort_index, is_active)
                VALUES (?, ?, ?, ?, ?)
            ]], { perm_key, label, allowed_json, sort_index, is_active })
        end)

        if not okQ or not res or res <= 0 then
            print('[LCV:ADMIN:FactionPerms] Insert-Fehler:', res)
            return { ok = false, error = 'DB-Fehler beim Insert (Key evtl. bereits vorhanden)' }
        end
    end

    local perms = getAllFactionPerms()
    return { ok = true, perms = perms }
end)

lib.callback.register('LCV:ADMIN:FactionPerms:Delete', function(source, data)
    if not hasAdminPermission(source, 10) then
        return { ok = false, error = 'Keine Berechtigung' }
    end

    local id = tonumber(data and data.id)
    if not id then
        return { ok = false, error = 'Ungültige ID' }
    end

    local okQ, res = pcall(function()
        return MySQL.update.await('DELETE FROM faction_permission_schema WHERE id = ?', { id })
    end)

    if not okQ then
        print('[LCV:ADMIN:FactionPerms] Delete-Fehler:', res)
        return { ok = false, error = 'DB-Fehler beim Löschen (Konsole prüfen)' }
    end

    local perms = getAllFactionPerms()
    return { ok = true, perms = perms }
end)