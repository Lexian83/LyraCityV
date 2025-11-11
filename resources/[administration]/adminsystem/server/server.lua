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

local function hmJsonEncode(tbl)
    if not tbl then return '{}' end
    if type(tbl) == 'string' then return tbl end
    local ok, res = pcall(json.encode, tbl)
    return ok and res or '{}'
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

-- ================== CHARACTERS: HELPERS ==================

local function getOnlineCharacterIds()
    local online = {}

    if not exports['playerManager'] or not exports['playerManager'].GetPlayerData then
        return online
    end

    for _, sid in ipairs(GetPlayers()) do
        local src = tonumber(sid)
        if src then
            local ok, data = pcall(function()
                return exports['playerManager']:GetPlayerData(src)
            end)

            if ok and data and data.character and data.character.id then
                local cid = tonumber(data.character.id)
                if cid then
                    online[cid] = true
                end
            end
        end
    end

    return online
end

-- ================== CHARACTERS: GET ALL ==================

lib.callback.register('LCV:ADMIN:Characters:GetAll', function(source, _)
    if not hasAdminPermission(source, 10) then
        return { ok = false, error = 'Keine Berechtigung', characters = {} }
    end

    local rows = MySQL.query.await([[
        SELECT
            id,
            account_id,
            name,
            level,
            birthdate,
            type,
            is_locked,
            residence_permit,
            past
        FROM characters
        ORDER BY id DESC
        LIMIT 500
    ]]) or {}

    local online = getOnlineCharacterIds()

    for _, r in ipairs(rows) do
        r.id               = tonumber(r.id) or 0
        r.account_id       = tonumber(r.account_id) or 0
        r.level            = tonumber(r.level) or 0
        r.type             = tonumber(r.type) or 0
        r.is_locked        = (r.is_locked == 1 or r.is_locked == true)
        r.residence_permit = (r.residence_permit == 1 or r.residence_permit == true)
        r.past             = (r.past == 1 or r.past == true)
        r.online           = online[r.id] == true

        if r.birthdate and type(r.birthdate) == "string" then
            local y, m, d = r.birthdate:match("^(%d%d%d%d)%-(%d%d)%-(%d%d)$")
            if y and m and d then
                r.birthdate = string.format("%s-%s-%s", y, m, d)
            else
                r.birthdate = nil
            end
        end
    end

    return { ok = true, characters = rows }
end)

-- ================== CHARACTERS: UPDATE ==================

lib.callback.register('LCV:ADMIN:Characters:Update', function(source, data)
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

    local is_locked      = data.is_locked and 1 or 0
    local residence_perm = data.residence_permit and 1 or 0

    local affected = MySQL.update.await([[
        UPDATE characters
        SET is_locked = ?, residence_permit = ?
        WHERE id = ?
    ]], { is_locked, residence_perm, id })

    if not affected or affected <= 0 then
        return { ok = false, error = 'Keine Änderung vorgenommen' }
    end

    local row = MySQL.single.await([[
        SELECT
            id,
            account_id,
            name,
            level,
            birthdate,
            type,
            is_locked,
            residence_permit,
            past
        FROM characters
        WHERE id = ?
    ]], { id })

    if row then
        row.id               = tonumber(row.id) or 0
        row.account_id       = tonumber(row.account_id) or 0
        row.level            = tonumber(row.level) or 0
        row.type             = tonumber(row.type) or 0
        row.is_locked        = (row.is_locked == 1 or row.is_locked == true)
        row.residence_permit = (row.residence_permit == 1 or row.residence_permit == true)
        row.past             = (row.past == 1 or row.past == true)

        if row.birthdate and type(row.birthdate) == "string" then
            local y, m, d = row.birthdate:match("^(%d%d%d%d)%-(%d%d)%-(%d%d)$")
            if y and m and d then
                row.birthdate = string.format("%s-%s-%s", y, m, d)
            else
                row.birthdate = nil
            end
        end
    end

    return { ok = true, row = row }
end)

-- ================== CHARACTERS: DELETE ==================

lib.callback.register('LCV:ADMIN:Characters:Delete', function(source, data)
    if not hasAdminPermission(source, 10) then
        return { ok = false, error = 'Keine Berechtigung' }
    end

    local id = tonumber(data and data.id)
    if not id then
        return { ok = false, error = 'Ungültige ID' }
    end

    local online = getOnlineCharacterIds()
    if online[id] then
        return { ok = false, error = 'Character ist aktuell online und kann nicht gelöscht werden.' }
    end

    local okQ, affected = pcall(function()
        return MySQL.update.await('DELETE FROM characters WHERE id = ?', { id })
    end)

    if not okQ then
        print(('[LCV:ADMIN] CHAR Delete error for id %s: %s'):format(id, tostring(affected)))
        return { ok = false, error = 'DB-Fehler beim Löschen (Konsole prüfen)' }
    end

    if not affected or affected <= 0 then
        return { ok = false, error = 'Kein Datensatz gelöscht' }
    end

    return { ok = true }
end)

-- ================== ADMIN UI ÖFFNEN ==================

RegisterNetEvent('LCV:ADMIN:Server:Show', function()
    local src = source
    if not hasAdminPermission(src, 10) then return end
    TriggerClientEvent('LCV:ADMIN:Client:Show', src)
end)

-- ================== INTERACTIONS ==================

lib.callback.register('LCV:ADMIN:Interactions:GetAll', function(source)
    if not hasAdminPermission(source, 10) then
        return { ok = false, error = 'Keine Berechtigung', interactions = {} }
    end

    local rows = MySQL.query.await([[
        SELECT id, name, description, type, x, y, z, radius, enabled, data
        FROM interaction_points
        ORDER BY id
    ]]) or {}

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

-- ================== FACTIONS ADMIN ==================

lib.callback.register('LCV:ADMIN:Factions:GetCharactersSimple', function(source, _)
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

-- ================== HOUSING SYSTEM ==================

lib.callback.register('LCV:ADMIN:Houses:GetAll', function(source)
    if not hasAdminPermission(source, 10) then
        return { ok = false, error = 'Keine Berechtigung', houses = {} }
    end

    local rows = MySQL.query.await([[
        SELECT 
            h.*,
            i.radius AS interaction_radius
        FROM houses h
        LEFT JOIN interaction_points i
          ON i.name = 'HOUSE'
         AND JSON_EXTRACT(i.data, '$.houseid') = h.id
        ORDER BY h.id ASC
    ]]) or {}

    for _, h in ipairs(rows) do
        h.id                 = tonumber(h.id) or 0
        h.ownerid            = tonumber(h.ownerid) or 0
        h.entry_x            = tonumber(h.entry_x) or 0.0
        h.entry_y            = tonumber(h.entry_y) or 0.0
        h.entry_z            = tonumber(h.entry_z) or 0.0
        h.garage_trigger_x   = tonumber(h.garage_trigger_x) or nil
        h.garage_trigger_y   = tonumber(h.garage_trigger_y) or nil
        h.garage_trigger_z   = tonumber(h.garage_trigger_z) or nil
        h.garage_x           = tonumber(h.garage_x) or nil
        h.garage_y           = tonumber(h.garage_y) or nil
        h.garage_z           = tonumber(h.garage_z) or nil
        h.price              = tonumber(h.price) or 0
        h.rent               = tonumber(h.rent) or 0
        h.ipl                = tonumber(h.ipl) or nil
        h.lock_state         = (tonumber(h.lock_state) == 1) and 1 or 0

        h.hotel              = tonumber(h.hotel) or 0
        h.apartments         = tonumber(h.apartments) or 0
        h.garage_size        = tonumber(h.garage_size) or 0

        h.allowed_bike       = tonumber(h.allowed_bike) == 1
        h.allowed_motorbike  = tonumber(h.allowed_motorbike) == 1
        h.allowed_car        = tonumber(h.allowed_car) == 1
        h.allowed_truck      = tonumber(h.allowed_truck) == 1
        h.allowed_plane      = tonumber(h.allowed_plane) == 1
        h.allowed_helicopter = tonumber(h.allowed_helicopter) == 1
        h.allowed_boat       = tonumber(h.allowed_boat) == 1

        h.maxkeys            = tonumber(h.maxkeys) or 0
        -- h.keys bleibt JSON / wird im UI nicht direkt genutzt
        h.pincode            = h.pincode

        local rs = h.rent_start
        if rs == "0000-00-00 00:00:00" or rs == "" then
            h.rent_start = nil
        end

        local hasOwner     = h.ownerid and h.ownerid > 0
        local hasRentStart = h.rent_start ~= nil

        if not hasOwner then
            h.status = "frei"
        elseif hasOwner and not hasRentStart then
            h.status = "verkauft"
        else
            h.status = "vermietet"
        end

        h.interaction_radius = tonumber(h.interaction_radius) or 0.5
    end

    return { ok = true, houses = rows }
end)

lib.callback.register('LCV:ADMIN:Houses:Add', function(source, data)
    if not hasAdminPermission(source, 10) then
        return { ok = false, error = 'Keine Berechtigung' }
    end

    if not data or not data.name or not data.entry_x or not data.entry_y or not data.entry_z then
        return { ok = false, error = 'Name + Eingang sind erforderlich.' }
    end

    local name    = tostring(data.name)
    local ownerid = tonumber(data.ownerid) or 0
    local radius  = tonumber(data.radius) or 0.5

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

    local id = MySQL.insert.await([[
        INSERT INTO houses
            (name, ownerid,
             entry_x, entry_y, entry_z,
             garage_trigger_x, garage_trigger_y, garage_trigger_z,
             garage_x, garage_y, garage_z,
             price, rent, ipl, lock_state,
             hotel, apartments, garage_size,
             allowed_bike, allowed_motorbike, allowed_car,
             allowed_truck, allowed_plane, allowed_helicopter, allowed_boat,
             maxkeys, `keys`, pincode)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1,
        ?, ?, ?,
        ?, ?, ?,
        ?, ?, ?, ?,
        ?, ?, ?)

    ]], {
        name,
        ownerid > 0 and ownerid or nil,
        tonumber(data.entry_x) or 0.0,
        tonumber(data.entry_y) or 0.0,
        tonumber(data.entry_z) or 0.0,
        tonumber(data.garage_trigger_x) or nil,
        tonumber(data.garage_trigger_y) or nil,
        tonumber(data.garage_trigger_z) or nil,
        tonumber(data.garage_x) or nil,
        tonumber(data.garage_y) or nil,
        tonumber(data.garage_z) or nil,
        tonumber(data.price) or 0,
        tonumber(data.rent) or 0,
        tonumber(data.ipl) or nil,
        hotel,
        apartments,
        garage_size,
        allowed_bike, allowed_motorbike, allowed_car,
        allowed_truck, allowed_plane, allowed_helicopter, allowed_boat,
        maxkeys,
        nil, -- `keys`
        pincode
    })

    if not id or id <= 0 then
        return { ok = false, error = 'Insert fehlgeschlagen' }
    end

    local houseId  = id
    local dataJson = json.encode({ houseid = houseId })

    -- ENTRY Interaction
    MySQL.insert.await([[
        INSERT INTO interaction_points
            (name, description, type, x, y, z, radius, enabled, data)
        VALUES ('HOUSE', ?, 'house', ?, ?, ?, ?, 1, ?)
    ]], {
        name,
        tonumber(data.entry_x) or 0.0,
        tonumber(data.entry_y) or 0.0,
        tonumber(data.entry_z) or 0.0,
        radius,
        dataJson
    })

    -- GARAGE Interaction
    if data.garage_trigger_x and data.garage_trigger_y and data.garage_trigger_z then
        MySQL.insert.await([[
            INSERT INTO interaction_points
                (name, description, type, x, y, z, radius, enabled, data)
            VALUES ('HOUSE_GARAGE', ?, 'garage', ?, ?, ?, ?, 1, ?)
        ]], {
            name,
            tonumber(data.garage_trigger_x) or 0.0,
            tonumber(data.garage_trigger_y) or 0.0,
            tonumber(data.garage_trigger_z) or 0.0,
            radius,
            dataJson
        })
    end

    -- EXIT Interaction via IPL
    if data.ipl then
        local ipl = MySQL.single.await('SELECT exit_x, exit_y, exit_z FROM house_ipl WHERE id = ?', { tonumber(data.ipl) })
        if ipl then
            MySQL.insert.await([[
                INSERT INTO interaction_points
                    (name, description, type, x, y, z, radius, enabled, data)
                VALUES ('EXIT_HOUSE', ?, 'house_exit', ?, ?, ?, ?, 1, ?)
            ]], {
                name,
                tonumber(ipl.exit_x) or 0.0,
                tonumber(ipl.exit_y) or 0.0,
                tonumber(ipl.exit_z) or 0.0,
                radius,
                dataJson
            })
        end
    end

    TriggerEvent('lcv:interaction:server:reloadPoints')
    TriggerEvent('LCV:house:forceSync')

    return { ok = true }
end)

lib.callback.register('LCV:ADMIN:Houses:Update', function(source, data)
    if not hasAdminPermission(source, 10) then
        return { ok = false, error = 'Keine Berechtigung' }
    end

    local id = tonumber(data and data.id)
    if not id then
        return { ok = false, error = 'Ungültige ID' }
    end

    local name = tostring(data.name or '')
    if name == '' then
        return { ok = false, error = 'Name ist erforderlich.' }
    end

    local ownerid = tonumber(data.ownerid) or 0
    local radius  = tonumber(data.radius) or 0.5

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

    local affected = MySQL.update.await([[
        UPDATE houses
        SET name = ?, ownerid = ?,
            entry_x = ?, entry_y = ?, entry_z = ?,
            garage_trigger_x = ?, garage_trigger_y = ?, garage_trigger_z = ?,
            garage_x = ?, garage_y = ?, garage_z = ?,
            price = ?, rent = ?, ipl = ?,
            hotel = ?, apartments = ?, garage_size = ?,
            allowed_bike = ?, allowed_motorbike = ?, allowed_car = ?,
            allowed_truck = ?, allowed_plane = ?, allowed_helicopter = ?, allowed_boat = ?,
            maxkeys = ?, pincode = ?
        WHERE id = ?
    ]], {
        name,
        ownerid > 0 and ownerid or nil,
        tonumber(data.entry_x) or 0.0,
        tonumber(data.entry_y) or 0.0,
        tonumber(data.entry_z) or 0.0,
        tonumber(data.garage_trigger_x) or nil,
        tonumber(data.garage_trigger_y) or nil,
        tonumber(data.garage_trigger_z) or nil,
        tonumber(data.garage_x) or nil,
        tonumber(data.garage_y) or nil,
        tonumber(data.garage_z) or nil,
        tonumber(data.price) or 0,
        tonumber(data.rent) or 0,
        tonumber(data.ipl) or nil,
        hotel,
        apartments,
        garage_size,
        allowed_bike, allowed_motorbike, allowed_car,
        allowed_truck, allowed_plane, allowed_helicopter, allowed_boat,
        maxkeys,
        pincode,
        id
    })

    if not affected or affected < 1 then
        return { ok = false, error = 'Update fehlgeschlagen.' }
    end

    local dataJson = hmJsonEncode({ houseid = id })

    -- ENTRY
    MySQL.update.await([[
        UPDATE interaction_points
        SET description = ?, x = ?, y = ?, z = ?, radius = ?
        WHERE name = 'HOUSE' AND JSON_EXTRACT(data, '$.houseid') = ?
    ]], {
        name,
        tonumber(data.entry_x) or 0.0,
        tonumber(data.entry_y) or 0.0,
        tonumber(data.entry_z) or 0.0,
        radius,
        id
    })

    -- GARAGE
    MySQL.update.await([[
        UPDATE interaction_points
        SET description = ?, x = ?, y = ?, z = ?, radius = ?
        WHERE name = 'HOUSE_GARAGE' AND JSON_EXTRACT(data, '$.houseid') = ?
    ]], {
        name,
        tonumber(data.garage_trigger_x) or 0.0,
        tonumber(data.garage_trigger_y) or 0.0,
        tonumber(data.garage_trigger_z) or 0.0,
        radius,
        id
    })

    -- EXIT via IPL
    if data.ipl then
        local ipl = MySQL.single.await('SELECT exit_x, exit_y, exit_z FROM house_ipl WHERE id = ?', { tonumber(data.ipl) })
        if ipl and ipl.exit_x and ipl.exit_y and ipl.exit_z then
            MySQL.update.await([[
                UPDATE interaction_points
                SET description = ?, x = ?, y = ?, z = ?, radius = ?
                WHERE name = 'EXIT_HOUSE' AND JSON_EXTRACT(data, '$.houseid') = ?
            ]], {
                name,
                tonumber(ipl.exit_x) or 0.0,
                tonumber(ipl.exit_y) or 0.0,
                tonumber(ipl.exit_z) or 0.0,
                radius,
                id
            })
        end
    end

    TriggerEvent('lcv:interaction:server:reloadPoints')
    TriggerEvent('LCV:house:forceSync')
    return { ok = true }
end)

lib.callback.register('LCV:ADMIN:Houses:Delete', function(source, data)
    if not hasAdminPermission(source, 10) then
        return { ok = false, error = 'Keine Berechtigung' }
    end

    local id = tonumber(data and data.id)
    if not id then
        return { ok = false, error = 'Ungültige ID' }
    end

    MySQL.update.await([[
        DELETE FROM interaction_points
        WHERE JSON_EXTRACT(data, '$.houseid') = ?
    ]], { id })

    local okQ, affected = pcall(function()
        return MySQL.update.await('DELETE FROM houses WHERE id = ?', { id })
    end)

    if not okQ or (affected or 0) <= 0 then
        return { ok = false, error = 'Kein Datensatz gelöscht' }
    end

    TriggerEvent('lcv:interaction:server:reloadPoints')
    TriggerEvent('LCV:house:forceSync')
    return { ok = true }
end)

lib.callback.register('LCV:ADMIN:Houses:ResetPincode', function(source, data)
    if not hasAdminPermission(source, 10) then
        return { ok = false, error = 'Keine Berechtigung' }
    end

    local id = tonumber(data and data.id)
    if not id then
        return { ok = false, error = 'Ungültige ID' }
    end

    MySQL.update.await('UPDATE houses SET pincode = NULL WHERE id = ?', { id })
    return { ok = true }
end)

-- Teleport vom Client (NUI ruft Client, Client triggert dieses Event)
RegisterNetEvent('LCV:ADMIN:Houses:Teleport', function(id, x, y, z)
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

-- ================== INTERACTIONS: TELEPORT ==================

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

-- ================== BLIPS ==================

lib.callback.register('LCV:ADMIN:Blips:GetAll', function(source)
    if not hasAdminPermission(source, 10) then
        return { ok = false, error = 'Keine Berechtigung', blips = {} }
    end

    local rows = MySQL.query.await([[
        SELECT id, name, x, y, z, sprite, color, scale,
               shortRange, display, category, visiblefor, enabled
        FROM blips
        ORDER BY id
    ]]) or {}

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
        return { ok = false, error = 'DB-Fehler beim Löschen (Konsole prüfen)' }
    end

    local okDelete = (affected or 0) > 0
    if okDelete then
        TriggerEvent('blip_reload')
    end

    return { ok = okDelete, error = okDelete and nil or 'Kein Datensatz gelöscht' }
end)

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

-- ================== TELEPORT TO WAYPOINT / FREI ==================

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

RegisterNetEvent('LCV:ADMIN:Teleport:Coords', function(x, y, z)
    local src = source
    if not hasAdminPermission(src, 10) then return end

    x, y, z = tonumber(x), tonumber(y), tonumber(z)
    if not x or not y or not z then return end

    local ped = GetPlayerPed(src)
    if ped ~= 0 then
        SetEntityCoords(ped, x + 0.0, y + 0.0, z + 0.0, false, false, false, true)
        TriggerClientEvent('LCV:ADMIN:Interactions:NotifyTeleport', src, { x = x, y = y, z = z })
    end
end)

-- ================== FACTIONS: PANEL MAIN ==================

lib.callback.register('LCV:ADMIN:Factions:GetAll', function(source, data)
    if not hasAdminPermission(source, 10) then
        return { ok = false, error = 'Keine Berechtigung', factions = {} }
    end

    local query    = data and data.query or ''
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
                is_gang       = is_gang
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

    local faction     = exports['factionManager']:GetFactionById(factionId)
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

-- ===== HOME: DUTY INFO =====

lib.callback.register('LCV:ADMIN:Home:GetDutyData', function(source, _)
    if not hasAdminPermission(source, 1) then
        return { ok = false, error = 'Keine Berechtigung', dutyFactions = {}, currentDuty = {} }
    end

    local charId = getCharId(source)
    if not charId then
        return { ok = false, error = 'Kein Character aktiv.', dutyFactions = {}, currentDuty = {} }
    end

    local dutyFactions = exports['factionManager']:GetDutyFactions(charId) or {}

    local currentDuty = {}
    for _, f in ipairs(dutyFactions) do
        if f.onDuty then
            currentDuty[#currentDuty+1] = {
                id    = f.id,
                name  = f.name,
                label = f.label
            }
        end
    end

    return {
        ok = true,
        dutyFactions = dutyFactions,
        currentDuty  = currentDuty
    }
end)

lib.callback.register('LCV:ADMIN:Home:SetDuty', function(source, data)
    if not hasAdminPermission(source, 1) then
        return { ok = false, error = 'Keine Berechtigung' }
    end

    local charId = getCharId(source)
    if not charId then
        return { ok = false, error = 'Kein Character aktiv.' }
    end

    local factionId = tonumber(data and data.faction_id)
    local turnOn    = data and data.on == true

    if not factionId then
        return { ok = false, error = 'Ungültige Fraktion.' }
    end

    local ok, err, dutyFactions, currentDuty =
        exports['factionManager']:SetDuty(charId, factionId, turnOn)

    if not ok then
        return { ok = false, error = err or 'Fehler beim Setzen des Duty-Status.' }
    end

    return {
        ok = true,
        dutyFactions = dutyFactions or {},
        currentDuty  = currentDuty or {}
    }
end)
