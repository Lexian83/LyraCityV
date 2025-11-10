local function getCharLVL(src)
    local ok, d = pcall(function()
        return exports['playerManager'] and exports['playerManager']:GetPlayerData(src) or nil
    end)
    if not ok or not d or not d.character then return 0 end
    return tonumber(d.character.level) or 0
end

local function getCharId(src)
    local ok, d = pcall(function()
        return exports['playerManager'] and exports['playerManager']:GetPlayerData(src) or nil
    end)
    if not ok or not d or not d.character then return nil end
    return tonumber(d.character.id) or nil
end

local function hasAdminPermission(src, required)
    local lvl = getCharLVL(src)
    required = tonumber(required) or 10
    return lvl >= required
end

-- ================== ADMIN PERMISSION SYSTEM ==================

local function loadFactionPermissionSchemaFromDB()
    local rows = MySQL.query.await([[
        SELECT perm_key, label, allowed_factions, sort_index, is_active
        FROM faction_permission_schema
        WHERE is_active = 1
        ORDER BY sort_index ASC, perm_key ASC
    ]]) or {}

    local schema = {}

    for _, r in ipairs(rows) do
        if r.perm_key and r.label then
            local entry = {
                label = r.label
            }

            if r.allowed_factions and r.allowed_factions ~= '' then
                local ok, parsed = pcall(json.decode, r.allowed_factions)
                if ok and type(parsed) == 'table' then
                    entry.factions = parsed
                end
            end

            schema[r.perm_key] = entry
        end
    end

    return schema
end

local function reloadFactionPermSchemaExternal()
    if GetResourceState('factionManager') == 'started' then
        pcall(function()
            if exports['factionManager'].ReloadFactionPermissionSchema then
                exports['factionManager']:ReloadFactionPermissionSchema()
            end
        end)
    end
end

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

-- ================== ADMIN UI ÖFFNEN ==================

RegisterNetEvent('LCV:ADMIN:Server:Show', function()
    local src = source
    if not hasAdminPermission(src, 10) then return end
    TriggerClientEvent('LCV:ADMIN:Client:Show', src)
end)

-- ================== GET ALL (für NUI-Tabelle) ==================

lib.callback.register('LCV:ADMIN:Interactions:GetAll', function(source)
    if not hasAdminPermission(source, 10) then
        return { ok = false, error = 'Keine Berechtigung', interactions = {} }
    end

    local rows = MySQL.query.await([[
        SELECT id, name, description, type, x, y, z, radius, enabled, data
        FROM interaction_points
        ORDER BY id
    ]], {}) or {}

    for _, row in ipairs(rows) do
        row.enabled = row.enabled == 1 or row.enabled == true

        if row.data and type(row.data) == 'string' and row.data ~= '' then
            local ok, decoded = pcall(json.decode, row.data)
            if ok and decoded ~= nil then
                row.data = decoded
            end
        end
    end

    return { ok = true, interactions = rows }
end)

-- ================== ADD ==================

lib.callback.register('LCV:ADMIN:Interactions:Add', function(source, data)
    if not hasAdminPermission(source, 10) then
        return { ok = false, error = 'Keine Berechtigung' }
    end

    if not data or not data.name then
        return { ok = false, error = 'Ungültige Daten' }
    end

    local name        = tostring(data.name or '')
    local description = tostring(data.description or '')
    local type_       = tostring(data.type or 'generic')
    local x           = tonumber(data.x) or 0.0
    local y           = tonumber(data.y) or 0.0
    local z           = tonumber(data.z) or 0.0
    local radius      = tonumber(data.radius) or 1.0
    local enabled     = data.enabled and 1 or 0

    local jsonData = data.data
    if type(jsonData) == 'table' then
        jsonData = json.encode(jsonData)
    elseif jsonData == nil or jsonData == '' then
        jsonData = '{}'
    else
        jsonData = tostring(jsonData)
    end

    local id = MySQL.insert.await([[
        INSERT INTO interaction_points (name, description, type, x, y, z, radius, enabled, data)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], { name, description, type_, x, y, z, radius, enabled, jsonData })

    if not id or id <= 0 then
        return { ok = false, error = 'Insert fehlgeschlagen' }
    end

    TriggerEvent('lcv:interaction:server:reloadPoints')

    return { ok = true, id = id }
end)

-- ================== UPDATE ==================

lib.callback.register('LCV:ADMIN:Interactions:Update', function(source, data)
    if not hasAdminPermission(source, 10) then
        return { ok = false, error = 'Keine Berechtigung' }
    end

    if not data or not data.id then
        return { ok = false, error = 'Ungültige Daten' }
    end

    local id          = tonumber(data.id)
    if not id then
        return { ok = false, error = 'Ungültige ID' }
    end

    local name        = tostring(data.name or '')
    local description = tostring(data.description or '')
    local type_       = tostring(data.type or '')
    local x           = tonumber(data.x) or 0.0
    local y           = tonumber(data.y) or 0.0
    local z           = tonumber(data.z) or 0.0
    local radius      = tonumber(data.radius) or 1.0
    local enabled     = data.enabled and 1 or 0

    local jsonData = data.data
    if type(jsonData) == 'table' then
        jsonData = json.encode(jsonData)
    elseif jsonData == nil or jsonData == '' then
        jsonData = '{}'
    else
        jsonData = tostring(jsonData)
    end

    local affected = MySQL.update.await([[
        UPDATE interaction_points
        SET name = ?, description = ?, type = ?, x = ?, y = ?, z = ?, radius = ?, enabled = ?, data = ?
        WHERE id = ?
    ]], { name, description, type_, x, y, z, radius, enabled, jsonData, id })

    local okUpdate = (affected or 0) > 0

    if okUpdate then
        TriggerEvent('lcv:interaction:server:reloadPoints')
    end

    return { ok = okUpdate, error = okUpdate and nil or 'Kein Datensatz geändert' }
end)

-- ================== DELETE ==================

lib.callback.register('LCV:ADMIN:Interactions:Delete', function(source, data)
    if not hasAdminPermission(source, 10) then
        return { ok = false, error = 'Keine Berechtigung' }
    end

    local id = tonumber(data and data.id)
    if not id then
        return { ok = false, error = 'Ungültige ID' }
    end

    local okQuery, affected = pcall(function()
        return MySQL.update.await('DELETE FROM interaction_points WHERE id = ?', { id })
    end)

    if not okQuery then
        print(('[LCV:ADMIN] Delete error for id %s: %s'):format(id, tostring(affected)))
        return { ok = false, error = 'DB-Fehler (siehe Server-Konsole)' }
    end

    local okDelete = (affected or 0) > 0

    if okDelete then
        TriggerEvent('lcv:interaction:server:reloadPoints')
    end

    return { ok = okDelete, error = okDelete and nil or 'Kein Datensatz gelöscht' }
end)

-- ================== NPCs: GET ALL ==================

lib.callback.register('LCV:ADMIN:Npcs:GetAll', function(source)
    if not hasAdminPermission(source, 10) then
        return { ok = false, error = 'Keine Berechtigung', npcs = {} }
    end

    local rows = MySQL.query.await([[
        SELECT id, name, model, x, y, z, heading, scenario, interactionType,
               interactable, autoGround, groundOffset, zOffset
        FROM npcs
        ORDER BY id
    ]], {}) or {}

    for _, r in ipairs(rows) do
        r.interactable = (r.interactable == 1 or r.interactable == true)
        r.autoGround = (r.autoGround == 1 or r.autoGround == true)
        r.groundOffset = tonumber(r.groundOffset) or 0.1
        r.zOffset = tonumber(r.zOffset) or 0.0
        r.x = tonumber(r.x) or 0.0
        r.y = tonumber(r.y) or 0.0
        r.z = tonumber(r.z) or 0.0
        r.heading = tonumber(r.heading) or 0.0
    end

    return { ok = true, npcs = rows }
end)

-- ================== NPCs: ADD ==================

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

-- ================== NPCs: UPDATE ==================

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

-- ================== NPCs: DELETE ==================

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

-- ========== PLAYER INFO FÜR NAMETAGS ==========

lib.callback.register('LCV:ADMIN:GetPlayerCharacter', function(_, targetId)
    targetId = tonumber(targetId)
    if not targetId then return nil end

    local ok, data = pcall(function()
        return exports['playerManager'] and exports['playerManager']:GetPlayerData(targetId)
    end)

    if not ok or not data or not data.character then
        return nil
    end

    local char = data.character
    return {
        id = char.id or targetId,
        name = char.name or ''
    }
end)

-- ========== FACTION STUFF ==========

lib.callback.register('LCV:ADMIN:Factions:GetCharactersSimple', function(source, data)
    if not hasAdminPermission(source, 10) then
        return { ok = false, error = 'Keine Berechtigung', characters = {} }
    end

    local rows = MySQL.query.await([[
        SELECT id, name, birthdate
        FROM characters
        ORDER BY name ASC
        LIMIT 500
    ]]) or {}

    local list = {}
    for _, r in ipairs(rows) do
        list[#list+1] = {
            id = r.id,
            label = ("%s%s"):format(r.name, r.birthdate and (" (" .. r.birthdate .. ")") or "")
        }
    end

    return { ok = true, characters = list }
end)

lib.callback.register('LCV:ADMIN:Factions:GetDetails', function(source, data)
    if not hasAdminPermission(source, 10) then
        return { ok = false, error = 'Keine Berechtigung' }
    end

    local factionId = tonumber(data and data.id)
    if not factionId then
        return { ok = false, error = 'Ungültige Faction ID' }
    end

    local members = exports['factionManager']:GetFactionMembers(factionId) or {}
    local ranks   = exports['factionManager']:GetFactionRanks(factionId) or {}
    local logs    = exports['factionManager']:GetFactionLogs(factionId, 100) or {}

    return {
        ok = true,
        members = members,
        ranks = ranks,
        logs = logs
    }
end)

lib.callback.register('LCV:ADMIN:Factions:AddMember', function(source, data)
    if not hasAdminPermission(source, 10) then
        return { ok = false, error = 'Keine Berechtigung' }
    end

    local factionId = tonumber(data and data.faction_id)
    local charId    = tonumber(data and data.char_id)
    local rankId    = tonumber(data and data.rank_id)

    if not factionId or not charId or not rankId then
        return { ok = false, error = 'Ungültige Daten' }
    end

    local id, err = exports['factionManager']:AddMember(factionId, charId, rankId)
    if not id then
        return { ok = false, error = err or 'Fehler beim Hinzufügen' }
    end

    local actorCharId = getCharId(source)
    exports['factionManager']:LogFactionAction(factionId, actorCharId, charId, 'add_member', {
        rank_id = rankId
    })

    local members = exports['factionManager']:GetFactionMembers(factionId) or {}
    return { ok = true, members = members }
end)

lib.callback.register('LCV:ADMIN:Factions:SetMemberRank', function(source, data)
    if not hasAdminPermission(source, 10) then
        return { ok = false, error = 'Keine Berechtigung' }
    end

    local factionId = tonumber(data and data.faction_id)
    local charId    = tonumber(data and data.char_id)
    local rankId    = tonumber(data and data.rank_id)

    if not factionId or not charId or not rankId then
        return { ok = false, error = 'Ungültige Daten' }
    end

    local okSet, err = exports['factionManager']:SetMemberRank(factionId, charId, rankId)
    if not okSet then
        return { ok = false, error = err or 'Fehler beim Aktualisieren des Rangs' }
    end

    local actorCharId = getCharId(source)
    exports['factionManager']:LogFactionAction(factionId, actorCharId, charId, 'set_member_rank', {
        rank_id = rankId
    })

    local members = exports['factionManager']:GetFactionMembers(factionId) or {}
    return { ok = true, members = members }
end)

lib.callback.register('LCV:ADMIN:Factions:RemoveMember', function(source, data)
    if not hasAdminPermission(source, 10) then
        return { ok = false, error = 'Keine Berechtigung' }
    end

    local factionId = tonumber(data and data.faction_id)
    local charId    = tonumber(data and data.char_id)

    if not factionId or not charId then
        return { ok = false, error = 'Ungültige Daten' }
    end

    local okRem, err = exports['factionManager']:RemoveMember(factionId, charId)
    if not okRem then
        return { ok = false, error = err or 'Fehler beim Entfernen' }
    end

    local actorCharId = getCharId(source)
    exports['factionManager']:LogFactionAction(factionId, actorCharId, charId, 'remove_member', {})

    local members = exports['factionManager']:GetFactionMembers(factionId) or {}
    return { ok = true, members = members }
end)

lib.callback.register('LCV:ADMIN:Factions:CreateRank', function(source, data)
    if not hasAdminPermission(source, 10) then
        return { ok = false, error = 'Keine Berechtigung' }
    end

    local factionId = tonumber(data and data.faction_id)
    local name      = tostring(data and data.name or '')
    local level     = tonumber(data and data.level) or 1

    if not factionId or name == '' then
        return { ok = false, error = 'Ungültige Daten' }
    end

    local id, reason = exports['factionManager']:CreateRank(factionId, name, level, {})

    if not id then
        local msg = 'Fehler beim Anlegen des Rangs'
        if reason == 'name_exists' then
            msg = 'Ein Rang mit diesem Namen existiert in dieser Fraktion bereits.'
        elseif reason == 'level_exists' then
            msg = 'Dieses Rang-Level ist in dieser Fraktion bereits vergeben.'
        elseif reason == 'invalid_params' then
            msg = 'Ungültige Daten für Rang-Erstellung.'
        elseif reason == 'db_error' then
            msg = 'Datenbankfehler beim Anlegen des Rangs.'
        end

        return { ok = false, error = msg }
    end

    local ranks = exports['factionManager']:GetFactionRanks(factionId) or {}
    return { ok = true, ranks = ranks }
end)

lib.callback.register('LCV:ADMIN:Factions:UpdateRank', function(source, data)
    if not hasAdminPermission(source, 10) then
        return { ok = false, error = 'Keine Berechtigung' }
    end

    local rankId    = tonumber(data and data.id)
    local factionId = tonumber(data and data.faction_id)

    if not rankId or not factionId then
        return { ok = false, error = 'Ungültige Daten' }
    end

    local update = {
        name        = data.name,
        level       = data.level and tonumber(data.level) or nil,
        permissions = data.permissions or {},
    }

    local okUp, reason = exports['factionManager']:UpdateRank(rankId, update)
    if not okUp then
        local msg = 'Fehler beim Aktualisieren des Rangs'
        if reason == 'name_exists' then
            msg = 'Ein Rang mit diesem Namen existiert bereits.'
        elseif reason == 'level_exists' then
            msg = 'Dieses Level ist in dieser Fraktion bereits vergeben.'
        elseif reason == 'not_found' then
            msg = 'Rang nicht gefunden.'
        elseif reason == 'nothing_to_update' or reason == 'no_change' then
            msg = 'Keine Änderungen vorgenommen.'
        elseif reason == 'db_error' then
            msg = 'Datenbankfehler beim Aktualisieren des Rangs.'
        end

        return { ok = false, error = msg }
    end

    local ranks = exports['factionManager']:GetFactionRanks(factionId) or {}
    return { ok = true, ranks = ranks }
end)

lib.callback.register('LCV:ADMIN:Factions:DeleteRank', function(source, data)
    if not hasAdminPermission(source, 10) then
        return { ok = false, error = 'Keine Berechtigung' }
    end

    local rankId    = tonumber(data and data.id)
    local factionId = tonumber(data and data.faction_id)

    if not rankId or not factionId then
        return { ok = false, error = 'Ungültige Daten' }
    end

    local okDel, reason = exports['factionManager']:DeleteRank(rankId)
    if not okDel then
        local msg = 'Fehler beim Löschen des Rangs'
        if reason == 'rank_in_use' then
            msg = 'Rang kann nicht gelöscht werden: Es gibt noch Mitglieder mit diesem Rang.'
        elseif reason == 'not_found' then
            msg = 'Rang nicht gefunden.'
        elseif reason == 'db_error' then
            msg = 'Datenbankfehler beim Löschen des Rangs.'
        end

        return { ok = false, error = msg }
    end

    local ranks = exports['factionManager']:GetFactionRanks(factionId) or {}
    return { ok = true, ranks = ranks }
end)

-- ================== ADMIN: Permissions ==================

lib.callback.register('LCV:ADMIN:Factions:GetPermissionSchema', function(source, _)
    if not hasAdminPermission(source, 10) then
        return { ok = false, error = 'Keine Berechtigung' }
    end

    local schema = loadFactionPermissionSchemaFromDB()

    if not next(schema) then
        schema = {
            manage_faction = { label = 'Fraktion bearbeiten' },
            manage_ranks   = { label = 'Ränge verwalten' },
            invite         = { label = 'Mitglieder einladen' },
            kick           = { label = 'Mitglieder entfernen' },
            set_rank       = { label = 'Rang zuweisen' },
            view_logs      = { label = 'Logs einsehen' },
        }
    end

    return { ok = true, schema = schema }
end)

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

-- ================== TELEPORT ==================

RegisterNetEvent('LCV:ADMIN:Interactions:Teleport', function(id, x, y, z)
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

-- ================== BLIPS: GET ALL ==================

lib.callback.register('LCV:ADMIN:Blips:GetAll', function(source)
    if not hasAdminPermission(source, 10) then
        return { ok = false, error = 'Keine Berechtigung', blips = {} }
    end

    local rows = MySQL.query.await([[
        SELECT id, name, x, y, z, sprite, color, scale,
               shortRange, display, category, visiblefor, enabled
        FROM blips
        ORDER BY id
    ]], {}) or {}

    for _, r in ipairs(rows) do
        r.id         = tonumber(r.id) or 0
        r.x          = tonumber(r.x) or 0.0
        r.y          = tonumber(r.y) or 0.0
        r.z          = tonumber(r.z) or 0.0
        r.sprite     = tonumber(r.sprite) or 1
        r.color      = tonumber(r.color) or 0
        r.scale      = tonumber(r.scale) or 1.0
        r.shortRange = (r.shortRange == 1 or r.shortRange == true)
        r.display    = tonumber(r.display) or 4
        r.visiblefor = tonumber(r.visiblefor) or 0
        r.enabled    = (r.enabled == 1 or r.enabled == true)
    end

    return { ok = true, blips = rows }
end)

-- ================== BLIPS: ADD ==================

lib.callback.register('LCV:ADMIN:Blips:Add', function(source, data)
    if not hasAdminPermission(source, 10) then
        return { ok = false, error = 'Keine Berechtigung' }
    end
    if not data or not data.name then
        return { ok = false, error = 'Name ist erforderlich' }
    end
    if not data.x or not data.y or not data.z then
        return { ok = false, error = 'Koordinaten fehlen' }
    end

    local name       = tostring(data.name or '')
    local x          = tonumber(data.x) or 0.0
    local y          = tonumber(data.y) or 0.0
    local z          = tonumber(data.z) or 0.0
    local sprite     = tonumber(data.sprite) or 1
    local color      = tonumber(data.color) or 0
    local scale      = tonumber(data.scale) or 1.0
    local shortRange = data.shortRange and 1 or 0
    local display    = tonumber(data.display) or 4
    local category   = (data.category and data.category ~= '') and tostring(data.category) or nil
    local visiblefor = tonumber(data.visiblefor) or 0
    local enabled    = data.enabled and 1 or 0

    local id = MySQL.insert.await([[
        INSERT INTO blips
            (name, x, y, z, sprite, color, scale,
             shortRange, display, category, visiblefor, enabled)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        name, x, y, z,
        sprite, color, scale,
        shortRange, display,
        category, visiblefor, enabled
    })

    if not id or id <= 0 then
        return { ok = false, error = 'Insert fehlgeschlagen' }
    end

    TriggerEvent('blip_reload')

    return { ok = true, id = id }
end)

-- ================== BLIPS: UPDATE ==================

lib.callback.register('LCV:ADMIN:Blips:Update', function(source, data)
    if not hasAdminPermission(source, 10) then
        return { ok = false, error = 'Keine Berechtigung' }
    end
    if not data or not data.id then
        return { ok = false, error = 'Ungültige Daten' }
    end

    local id         = tonumber(data.id)
    if not id then
        return { ok = false, error = 'Ungültige ID' }
    end

    local name       = tostring(data.name or '')
    local x          = tonumber(data.x) or 0.0
    local y          = tonumber(data.y) or 0.0
    local z          = tonumber(data.z) or 0.0
    local sprite     = tonumber(data.sprite) or 1
    local color      = tonumber(data.color) or 0
    local scale      = tonumber(data.scale) or 1.0
    local shortRange = data.shortRange and 1 or 0
    local display    = tonumber(data.display) or 4
    local category   = (data.category and data.category ~= '') and tostring(data.category) or nil
    local visiblefor = tonumber(data.visiblefor) or 0
    local enabled    = data.enabled and 1 or 0

    local affected = MySQL.update.await([[
        UPDATE blips
        SET name = ?, x = ?, y = ?, z = ?, sprite = ?, color = ?, scale = ?,
            shortRange = ?, display = ?, category = ?, visiblefor = ?, enabled = ?
        WHERE id = ?
    ]], {
        name, x, y, z,
        sprite, color, scale,
        shortRange, display,
        category, visiblefor, enabled,
        id
    })

    local okUpdate = (affected or 0) > 0
    if okUpdate then
        TriggerEvent('blip_reload')
    end

    return { ok = okUpdate, error = okUpdate and nil or 'Kein Datensatz geändert' }
end)

-- ================== BLIPS: DELETE ==================

lib.callback.register('LCV:ADMIN:Blips:Delete', function(source, data)
    if not hasAdminPermission(source, 10) then
        return { ok = false, error = 'Keine Berechtigung' }
    end

    local id = tonumber(data and data.id)
    if not id then
        return { ok = false, error = 'Ungültige ID' }
    end

    local okQuery, affected = pcall(function()
        return MySQL.update.await('DELETE FROM blips WHERE id = ?', { id })
    end)

    if not okQuery then
        print(('[LCV:ADMIN] BLIP Delete error for id %s: %s'):format(id, tostring(affected)))
        return { ok = false, error = 'DB-Fehler (siehe Server-Konsole)' }
    end

    local okDelete = (affected or 0) > 0
    if okDelete then
        TriggerEvent('blip_reload')
    end

    return { ok = okDelete, error = okDelete and nil or 'Kein Datensatz gelöscht' }
end)

-- ================== BLIPS: GET PLAYER POS ==================

lib.callback.register('LCV:ADMIN:Blips:GetPlayerPos', function(source)
    local ped = GetPlayerPed(source)
    if not ped or ped == 0 or not DoesEntityExist(ped) then
        return { ok = false, error = 'no_ped' }
    end

    local coords = GetEntityCoords(ped)
    return {
        ok = true,
        x = coords.x,
        y = coords.y,
        z = coords.z
    }
end)

-- ================== BLIPS: TELEPORT ==================

RegisterNetEvent('LCV:ADMIN:Blips:Teleport', function(id, x, y, z)
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

-- ================== TELEPORT TO WAYPOINT ==================

RegisterNetEvent('LCV:ADMIN:TeleportToWaypoint', function(x, y, z)
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

-- ================== FACTIONS: ADMIN PANEL ==================

lib.callback.register('LCV:ADMIN:Factions:GetAll', function(source, data)
    if not hasAdminPermission(source, 10) then
        return { ok = false, error = 'Keine Berechtigung', factions = {} }
    end

    local query = data and data.query or ''
    local factions = exports['factionManager']:GetAllFactions(query) or {}

    return { ok = true, factions = factions }
end)

lib.callback.register('LCV:ADMIN:Factions:Create', function(source, data)
    if not hasAdminPermission(source, 10) then
        return { ok = false, error = 'Keine Berechtigung' }
    end

    if not data or not data.name or data.name == '' then
        return { ok = false, error = 'Fraktionsname (Key) ist erforderlich.' }
    end

    local actorCharId  = getCharId(source)
    local leaderCharId = tonumber(data.leader_char_id) or nil
    local name         = tostring(data.name)
    local label        = (data.label and tostring(data.label) ~= '' and tostring(data.label)) or name
    local description  = data.description or ''

    local id, reason = exports['factionManager']:CreateFaction(
        name,
        label,
        leaderCharId,
        description,
        actorCharId
    )

    if not id then
        local chkId = MySQL.scalar.await('SELECT id FROM factions WHERE name = ?', { name })
        if chkId then
            local faction = exports['factionManager']:GetFactionById(chkId)
            return {
                ok = true,
                faction = faction,
                info = 'Fraktion wurde angelegt (Auto-Recovery nach Rückgabefehler).'
            }
        end

        local msg = 'Fehler beim Anlegen der Fraktion'
        if reason == 'already_exists' then
            msg = 'Eine Fraktion mit diesem Namen existiert bereits.'
        elseif reason == 'missing_name' then
            msg = 'Fraktionsname (Key) ist erforderlich.'
        elseif reason == 'db_error' then
            msg = 'Datenbankfehler beim Anlegen der Fraktion.'
        end

        return { ok = false, error = msg }
    end

    local duty_required = data.duty_required and 1 or 0
    local is_gang       = data.is_gang and 1 or 0

    if duty_required == 1 or is_gang == 1 then
        pcall(function()
            exports['factionManager']:UpdateFaction(id, {
                duty_required = duty_required,
                is_gang = is_gang
            })
        end)
    end

    local faction = exports['factionManager']:GetFactionById(id)

    return { ok = true, faction = faction }
end)

lib.callback.register('LCV:ADMIN:Factions:Update', function(source, data)
    if not hasAdminPermission(source, 10) then
        return { ok = false, error = 'Keine Berechtigung' }
    end

    if not data or not data.id then
        return { ok = false, error = 'Ungültige ID' }
    end

    local factionId = tonumber(data.id)
    if not factionId then
        return { ok = false, error = 'Ungültige ID' }
    end

    local updateData = {
        name           = data.name,
        label          = data.label,
        description    = data.description,
        leader_char_id = data.leader_char_id,
        duty_required  = data.duty_required and 1 or 0,
        is_gang        = data.is_gang and 1 or 0,
    }

    local okUpdate, err = exports['factionManager']:UpdateFaction(factionId, updateData)
    if not okUpdate then
        return { ok = false, error = err or 'Keine Änderung vorgenommen' }
    end

    local faction = exports['factionManager']:GetFactionById(factionId)

    local actorCharId = getCharId(source)
    exports['factionManager']:LogFactionAction(factionId, actorCharId, nil, 'update_faction', {
        fields = updateData
    })

    return { ok = true, faction = faction }
end)

lib.callback.register('LCV:ADMIN:Factions:Delete', function(source, data)
    if not hasAdminPermission(source, 10) then
        return { ok = false, error = 'Keine Berechtigung' }
    end

    local id = tonumber(data and data.id)
    if not id then
        return { ok = false, error = 'Ungültige ID' }
    end

    local okDel, err = exports['factionManager']:DeleteFaction(id)
    if not okDel then
        return { ok = false, error = err or 'Fehler beim Löschen' }
    end

    return { ok = true }
end)

-- ===== HOME: DUTY HELFER =====

local function getDutyFactionsForChar(charId)
    if not charId then return {} end

    local rows = MySQL.query.await([[
        SELECT DISTINCT f.id, f.name, f.label
        FROM factions f
        INNER JOIN faction_members m ON m.faction_id = f.id
        WHERE f.duty_required = 1
          AND m.char_id = ?
        ORDER BY f.label, f.name
    ]], { charId }) or {}

    return rows
end

local function buildCurrentDutyList(charId, dutyFactions)
    local current = {}
    if not charId or not dutyFactions then return current end

    for _, f in ipairs(dutyFactions) do
        local ok, on = pcall(function()
            return exports['factionManager']:IsOnDuty(charId, f.id)
        end)

        if ok and on then
            current[#current+1] = {
                id = f.id,
                name = f.name,
                label = f.label
            }
        end
    end

    return current
end

-- ===== CALLBACK: GET DUTY DATA =====

lib.callback.register('LCV:ADMIN:Home:GetDutyData', function(source, _)
    if not hasAdminPermission(source, 1) then
        return { ok = false, error = 'Keine Berechtigung', dutyFactions = {}, currentDuty = {} }
    end

    local charId = getCharId(source)
    if not charId then
        return { ok = false, error = 'Kein Character aktiv.', dutyFactions = {}, currentDuty = {} }
    end

    local dutyFactions = getDutyFactionsForChar(charId)
    local currentDuty  = buildCurrentDutyList(charId, dutyFactions)

    return {
        ok = true,
        dutyFactions = dutyFactions,
        currentDuty  = currentDuty
    }
end)

-- ===== CALLBACK: SET DUTY =====

lib.callback.register('LCV:ADMIN:Home:SetDuty', function(source, data)
    if not hasAdminPermission(source, 1) then
        return { ok = false, error = 'Keine Berechtigung' }
    end

    local charId = getCharId(source)
    if not charId then
        return { ok = false, error = 'Kein Character aktiv.' }
    end

    local factionId = tonumber(data and data.faction_id)
    local on        = data and data.on == true

    if not factionId then
        return { ok = false, error = 'Ungültige Fraktion.' }
    end

    local row = MySQL.single.await([[
        SELECT f.id, f.name, f.label
        FROM factions f
        INNER JOIN faction_members m ON m.faction_id = f.id
        WHERE f.id = ?
          AND f.duty_required = 1
          AND m.char_id = ?
    ]], { factionId, charId })

    if not row then
        return { ok = false, error = 'Nicht Mitglied oder Fraktion nicht Duty-pflichtig.' }
    end

    local okSet, res = pcall(function()
        return exports['factionManager']:SetDuty(charId, factionId, on)
    end)

    if not okSet then
        print('[LCV:ADMIN:Home:SetDuty] Fehler in SetDuty:', res)
        return { ok = false, error = 'Duty konnte nicht gesetzt werden (Log prüfen).' }
    end

    local dutyFactions = getDutyFactionsForChar(charId)
    local currentDuty  = buildCurrentDutyList(charId, dutyFactions)

    return {
        ok = true,
        currentDuty = currentDuty
    }
end)
