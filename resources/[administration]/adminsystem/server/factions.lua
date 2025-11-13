-- adminsystem/server/factions.lua
-- Ab jetzt: KEINE SQL-Zugriffe mehr hier. Nur Proxy zu factionManager & playerManager.

-- ===== Helpers & Permission =====
local function getPM()
    if GetResourceState('playerManager') == 'started' then
        return exports['playerManager']
    end
    if GetResourceState('lcv-playermanager') == 'started' then
        return exports['lcv-playermanager']
    end
    return nil
end

local function getFM()
    if GetResourceState('factionManager') == 'started' then
        return exports['factionManager']
    end
    if GetResourceState('lcv-factionmanager') == 'started' then
        return exports['lcv-factionmanager']
    end
    return nil
end

local function getCharLVL(src)
    local pm = getPM()
    if not pm or not pm.GetPlayerData then return 0 end
    local ok, d = pcall(function() return pm:GetPlayerData(src) end)
    if not ok or not d or not d.character then return 0 end
    return tonumber(d.character.level) or 0
end

local function getCharId(src)
    local pm = getPM()
    if not pm or not pm.GetPlayerData then return nil end
    local ok, d = pcall(function() return pm:GetPlayerData(src) end)
    if not ok or not d or not d.character then return nil end
    return tonumber(d.character.id) or nil
end

local function hasAdminPermission(src, required)
    local lvl = getCharLVL(src)
    required = tonumber(required) or 10
    return lvl >= required
end

-- ===== Characters (Simple List for selects) via playerManager (keine SQL hier)
lib.callback.register('LCV:ADMIN:Factions:GetCharactersSimple', function(source, _)
    if not hasAdminPermission(source, 10) then
        return { ok = false, error = 'Keine Berechtigung', characters = {} }
    end
    local pm = getPM()
    if not pm or not pm.ListCharacters then
        return { ok = false, error = 'playerManager not started', characters = {} }
    end

    local res = pm:ListCharacters(500) or { ok = true, characters = {} }
    local out = {}
    if res.ok and res.characters then
        for _, r in ipairs(res.characters) do
            out[#out+1] = {
                id = r.id,
                label = ("%s%s"):format(r.name or ("#"..tostring(r.id)),
                                        (r.birthdate and (" ("..r.birthdate..")") or ""))
            }
        end
    end
    return { ok = true, characters = out }
end)

-- ===== Permission-Schema via factionManager-Export (keine SQL hier)
lib.callback.register('LCV:ADMIN:Factions:GetPermissionSchema', function(source, _)
    if not hasAdminPermission(source, 10) then
        return { ok = false, error = 'Keine Berechtigung' }
    end
    local fm = getFM()
    if not fm or not fm.GetFactionPermissionSchema then
        -- Fallback auf Default-Schema, falls Resource nicht läuft
        return {
            ok = true,
            schema = {
                manage_faction = { label = 'Fraktion bearbeiten' },
                manage_ranks   = { label = 'Ränge verwalten' },
                invite         = { label = 'Mitglieder einladen' },
                kick           = { label = 'Mitglieder entfernen' },
                set_rank       = { label = 'Rang zuweisen' },
                view_logs      = { label = 'Logs einsehen' },
            }
        }
    end
    local schema = fm:GetFactionPermissionSchema() or {}
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

-- ===== Details (Members / Ranks / Logs)
lib.callback.register('LCV:ADMIN:Factions:GetDetails', function(source, data)
    if not hasAdminPermission(source, 10) then
        return { ok = false, error = 'Keine Berechtigung' }
    end
    local factionId = tonumber(data and data.id)
    if not factionId then
        return { ok = false, error = 'Ungültige Faction ID' }
    end

    local fm = getFM()
    if not fm then return { ok = false, error = 'factionManager not started' } end

    local members = fm:GetFactionMembers(factionId) or {}
    local ranks   = fm:GetFactionRanks(factionId)   or {}
    local logs    = fm:GetFactionLogs(factionId, 100) or {}

    return { ok = true, members = members, ranks = ranks, logs = logs }
end)

-- ===== CRUD: Members
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

    local fm = getFM()
    if not fm then return { ok = false, error = 'factionManager not started' } end

    local id, err = fm:AddMember(factionId, charId, rankId)
    if not id then return { ok = false, error = err or 'Fehler beim Hinzufügen' } end

    local actorCharId = getCharId(source)
    pcall(function() fm:LogFactionAction(factionId, actorCharId, charId, 'add_member', { rank_id = rankId }) end)

    local members = fm:GetFactionMembers(factionId) or {}
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

    local fm = getFM()
    if not fm then return { ok = false, error = 'factionManager not started' } end

    local okSet, err = fm:SetMemberRank(factionId, charId, rankId)
    if not okSet then return { ok = false, error = err or 'Fehler beim Aktualisieren des Rangs' } end

    local actorCharId = getCharId(source)
    pcall(function() fm:LogFactionAction(factionId, actorCharId, charId, 'set_member_rank', { rank_id = rankId }) end)

    local members = fm:GetFactionMembers(factionId) or {}
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

    local fm = getFM()
    if not fm then return { ok = false, error = 'factionManager not started' } end

    local okRem, err = fm:RemoveMember(factionId, charId)
    if not okRem then return { ok = false, error = err or 'Fehler beim Entfernen' } end

    local actorCharId = getCharId(source)
    pcall(function() fm:LogFactionAction(factionId, actorCharId, charId, 'remove_member', {}) end)

    local members = fm:GetFactionMembers(factionId) or {}
    return { ok = true, members = members }
end)

-- ===== CRUD: Ranks
lib.callback.register('LCV:ADMIN:Factions:DeleteRank', function(source, data)
    if not hasAdminPermission(source, 10) then
        return { ok = false, error = 'Keine Berechtigung' }
    end
    local rankId    = tonumber(data and data.id)
    local factionId = tonumber(data and data.faction_id)
    if not rankId or not factionId then
        return { ok = false, error = 'Ungültige Daten' }
    end

    local fm = getFM()
    if not fm then return { ok = false, error = 'factionManager not started' } end

    local okDel, reason = fm:DeleteRank(rankId)
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

    local ranks = fm:GetFactionRanks(factionId) or {}
    return { ok = true, ranks = ranks }
end)

-- ===== LIST/CREATE/UPDATE Factions
lib.callback.register('LCV:ADMIN:Factions:GetAll', function(source, data)
    if not hasAdminPermission(source, 10) then
        return { ok = false, error = 'Keine Berechtigung', factions = {} }
    end
    local fm = getFM()
    if not fm then return { ok = false, error = 'factionManager not started', factions = {} } end
    local query    = data and data.query or ''
    local factions = fm:GetAllFactions(query) or {}
    return { ok = true, factions = factions }
end)

lib.callback.register('LCV:ADMIN:Factions:Create', function(source, data)
    if not hasAdminPermission(source, 10) then
        return { ok = false, error = 'Keine Berechtigung' }
    end
    if not data or not data.name or data.name == '' then
        return { ok = false, error = 'Fraktionsname (Key) ist erforderlich.' }
    end

    local fm = getFM()
    if not fm then return { ok = false, error = 'factionManager not started' } end

    local actorCharId  = getCharId(source)
    local leaderCharId = tonumber(data.leader_char_id) or nil
    local name         = tostring(data.name)
    local label        = (data.label and tostring(data.label) ~= '' and tostring(data.label)) or name
    local description  = data.description or ''

    local id, reason = fm:CreateFaction(name, label, leaderCharId, description, actorCharId)
    if not id then
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
            fm:UpdateFaction(id, { duty_required = duty_required, is_gang = is_gang })
        end)
    end

    local faction = fm:GetFactionById(id)
    return { ok = true, faction = faction }
end)

lib.callback.register('LCV:ADMIN:Factions:Update', function(source, data)
    if not hasAdminPermission(source, 10) then
        return { ok = false, error = 'Keine Berechtigung' }
    end
    if not data or not data.id then
        return { ok = false, error = 'Ungültige ID' }
    end

    local fm = getFM()
    if not fm then return { ok = false, error = 'factionManager not started' } end

    local factionId = tonumber(data.id)
    if not factionId then return { ok = false, error = 'Ungültige ID' } end

    local updateData = {
        name           = data.name,
        label          = data.label,
        description    = data.description,
        leader_char_id = data.leader_char_id,
        duty_required  = data.duty_required and 1 or 0,
        is_gang        = data.is_gang and 1 or 0,
    }

    local okUpdate, err = fm:UpdateFaction(factionId, updateData)
    if not okUpdate then
        return { ok = false, error = err or 'Keine Änderung vorgenommen' }
    end

    local faction     = fm:GetFactionById(factionId)
    local actorCharId = getCharId(source)
    pcall(function() fm:LogFactionAction(factionId, actorCharId, nil, 'update_faction', { fields = updateData }) end)

    return { ok = true, faction = faction }
end)
