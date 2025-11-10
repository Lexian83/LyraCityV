-- server/faction_manager.lua

local FactionCache = {}
local RankCache = {}        -- [faction_id] = { [rank_id] = row, byLevel = { [level] = row } }
local MemberCache = {}      -- optional: für schnelle Lookups; hier minimal genutzt

local FactionPermissionSchema = {}

----------------------------------------------------------
-- UNIVERSAL MEMBER FETCHER
-- Liefert Fraktions-Mitglied + Rang + Meta auf Basis charId.
-- Optional kann eine Fraktion gefiltert werden (ID oder Name).
----------------------------------------------------------

---@param charId number          -- Charakter-ID aus der Tabelle `characters`
---@param factionFilter any      -- optional: faction_id (number) oder faction name (string)
---@return table|nil
function _getMemberWithRank(charId, factionFilter)
    if not charId or tonumber(charId) == nil then
        return nil
    end

    local baseQuery = [[
        SELECT
            fm.id              AS member_id,
            fm.faction_id      AS faction_id,
            fm.char_id         AS char_id,
            fm.rank_id         AS rank_id,
            fm.active          AS active,

            f.name             AS faction_name,
            f.label            AS faction_label,
            f.duty_required    AS duty_required,
            f.is_gang          AS is_gang,

            r.name             AS rank_name,
            r.level            AS rank_level,
            r.permissions      AS rank_permissions,

            c.name             AS char_name
        FROM faction_members fm
        INNER JOIN factions f       ON f.id = fm.faction_id
        INNER JOIN faction_ranks r  ON r.id = fm.rank_id
        INNER JOIN characters c     ON c.id = fm.char_id
        WHERE fm.char_id = ?
          AND fm.active = 1
    ]]

    local params = { charId }

    if factionFilter then
        if type(factionFilter) == "number" then
            baseQuery = baseQuery .. " AND fm.faction_id = ?"
            params[#params + 1] = factionFilter
        elseif type(factionFilter) == "string" then
            baseQuery = baseQuery .. " AND f.name = ?"
            params[#params + 1] = factionFilter
        end
    end

    baseQuery = baseQuery .. " ORDER BY r.level DESC LIMIT 1"

    local row = MySQL.single.await(baseQuery, params)
    if not row then
        return nil
    end

    return {
        member_id        = row.member_id,
        char_id          = row.char_id,
        char_name        = row.char_name,

        faction_id       = row.faction_id,
        faction_name     = row.faction_name,
        faction_label    = row.faction_label,
        duty_required    = row.duty_required == 1,
        is_gang          = row.is_gang == 1,

        rank_id          = row.rank_id,
        rank_name        = row.rank_name,
        rank_level       = row.rank_level,
        rank_permissions = row.rank_permissions and json.decode(row.rank_permissions) or {}
    }
end

----------------------------------------------------------
-- PERMISSION-SCHEMA
----------------------------------------------------------

local function buildDefaultPermissionSchema()
    return {
        manage_faction = { label = 'Fraktion bearbeiten' },
        manage_ranks   = { label = 'Ränge verwalten' },
        invite         = { label = 'Mitglieder einladen' },
        kick           = { label = 'Mitglieder entfernen' },
        set_rank       = { label = 'Rang zuweisen' },
        view_logs      = { label = 'Logs einsehen' },
    }
end

local function loadPermissionSchemaFromDB()
    local rows = MySQL.query.await([[
        SELECT perm_key, label, allowed_factions, sort_index, is_active
        FROM faction_permission_schema
        WHERE is_active = 1
        ORDER BY sort_index ASC, perm_key ASC
    ]]) or {}

    local schema = {}

    for _, row in ipairs(rows) do
        if row.perm_key and row.label then
            local entry = {
                label = row.label
            }

            if row.allowed_factions and row.allowed_factions ~= '' then
                local ok, parsed = pcall(json.decode, row.allowed_factions)
                if ok and type(parsed) == 'table' then
                    entry.factions = parsed
                end
            end

            schema[row.perm_key] = entry
        end
    end

    if not next(schema) then
        print('[factionManager] faction_permission_schema leer oder fehlerhaft, nutze Defaults.')
        schema = buildDefaultPermissionSchema()
    else
        print(('[factionManager] Loaded %d faction permissions from database.'):format(#rows))
    end

    FactionPermissionSchema = schema
end

function GetFactionPermissionSchema()
    return FactionPermissionSchema
end
exports('GetFactionPermissionSchema', GetFactionPermissionSchema)

CreateThread(function()
    loadPermissionSchemaFromDB()
end)

RegisterCommand('faction_perms_reload', function(src)
    if src ~= 0 then
        return
    end
    loadPermissionSchemaFromDB()
    print('[factionManager] Permission-Schema neu geladen.')
end, true)

----------------------------------------------------------
-- HELPER
----------------------------------------------------------

local function debug(msg)
    -- print(('[FactionManager] %s'):format(msg))
end

local function GetCharIdFromSource(srcOrChar)
    if not srcOrChar then return nil end

    if type(srcOrChar) ~= 'number' then
        srcOrChar = tonumber(srcOrChar)
        if not srcOrChar then
            return nil
        end
    end

    if GetResourceState('playerManager') == 'started' then
        local ok, data = pcall(function()
            return exports['playerManager']:GetPlayerData(srcOrChar)
        end)

        if ok and data and data.character and data.character.id then
            return tonumber(data.character.id)
        end
    end

    return srcOrChar
end

----------------------------------------------------------
-- LOADERS
----------------------------------------------------------

local function LoadFaction(id)
    local rows = MySQL.query.await('SELECT * FROM factions WHERE id = ?', { id })
    local row = rows and rows[1]
    if row then
        FactionCache[row.id] = row
        return row
    end
    return nil
end

local function LoadFactionByName(name)
    local rows = MySQL.query.await('SELECT * FROM factions WHERE name = ?', { name })
    local row = rows and rows[1]
    if row then
        FactionCache[row.id] = row
        return row
    end
    return nil
end

local function LoadRanksForFaction(factionId)
    local rows = MySQL.query.await('SELECT * FROM faction_ranks WHERE faction_id = ?', { factionId }) or {}
    RankCache[factionId] = { byId = {}, byLevel = {} }

    for _, r in ipairs(rows) do
        if type(r.permissions) == 'string' then
            local ok, decoded = pcall(json.decode, r.permissions)
            r.permissions = ok and decoded or {}
        elseif type(r.permissions) ~= 'table' then
            r.permissions = {}
        end
        RankCache[factionId].byId[r.id] = r
        RankCache[factionId].byLevel[tonumber(r.level)] = r
    end

    return RankCache[factionId]
end

local function EnsureFactionRanks(factionId)
    local ranks = RankCache[factionId] or LoadRanksForFaction(factionId)

    if not ranks or (next(ranks.byId) == nil) then
        debug(("Erstelle Default-Ränge für Faction %d"):format(factionId))

        local default = {
            { name = 'Leader',   level = 100, perms = {
                manage_faction = true,
                manage_ranks = true,
                invite = true,
                kick = true,
                set_rank = true,
                view_logs = true
            }},
            { name = 'Officer',  level = 50, perms = {
                invite = true,
                kick = true,
                set_rank = false,
                view_logs = true
            }},
            { name = 'Member',   level = 10, perms = {
                invite = false,
                kick = false,
                view_logs = false
            }},
            { name = 'Recruit',  level = 1, perms = {} },
        }

        for _, r in ipairs(default) do
            local id = MySQL.insert.await(
                'INSERT INTO faction_ranks (faction_id, name, level, permissions) VALUES (?, ?, ?, ?)',
                { factionId, r.name, r.level, json.encode(r.perms) }
            )
            if id then
                r.id = id
            end
        end

        LoadRanksForFaction(factionId)
    end
end

----------------------------------------------------------
-- EXPORTS: FETCH
----------------------------------------------------------

function GetAllFactions(search)
    local sql = [[
        SELECT
            f.*,
            c.name AS leader_name,
            (
                SELECT COUNT(*)
                FROM faction_members fm
                WHERE fm.faction_id = f.id AND fm.active = 1
            ) AS member_count
        FROM factions f
        LEFT JOIN characters c ON c.id = f.leader_char_id
    ]]

    local params = {}
    if search and search ~= '' then
        search = string.lower(tostring(search))
        sql = sql .. " WHERE LOWER(f.name) LIKE ? OR LOWER(f.label) LIKE ?"
        local like = '%' .. search .. '%'
        params[#params+1] = like
        params[#params+1] = like
    end

    sql = sql .. " ORDER BY f.id"

    local rows = MySQL.query.await(sql, params) or {}
    for _, r in ipairs(rows) do
        r.member_count = tonumber(r.member_count) or 0
    end

    return rows
end
exports('GetAllFactions', GetAllFactions)

function GetFactionById(id)
    id = tonumber(id)
    if not id then return nil end
    if FactionCache[id] then return FactionCache[id] end
    return LoadFaction(id)
end
exports('GetFactionById', GetFactionById)

function GetFactionByName(name)
    if not name then return nil end
    for _, f in pairs(FactionCache) do
        if f.name == name then
            return f
        end
    end
    return LoadFactionByName(name)
end
exports('GetFactionByName', GetFactionByName)

local function _getPrimaryFactionForChar(charId)
    local rows = MySQL.query.await([[
        SELECT fm.*, f.*, fr.name AS rank_name, fr.level AS rank_level
        FROM faction_members fm
        JOIN factions f ON f.id = fm.faction_id
        JOIN faction_ranks fr ON fr.id = fm.rank_id
        WHERE fm.char_id = ? AND fm.active = 1
        ORDER BY fr.level DESC
        LIMIT 1
    ]], { charId })

    return rows and rows[1] or nil
end

local function IsDutyRequiredForFaction(faction)
    if not faction then return false end
    return tonumber(faction.duty_required) == 1
end

function GetPlayerFaction(src)
    local charId = GetCharIdFromSource(src) or tonumber(src)
    if not charId then return nil end
    return _getPrimaryFactionForChar(charId)
end
exports('GetPlayerFaction', GetPlayerFaction)

function GetPlayerFactions(src)
    local charId = GetCharIdFromSource(src) or tonumber(src)
    if not charId then return {} end

    local rows = MySQL.query.await([[
        SELECT fm.*, f.name AS faction_name, f.label AS faction_label,
               fr.name AS rank_name, fr.level AS rank_level
        FROM faction_members fm
        JOIN factions f ON f.id = fm.faction_id
        JOIN faction_ranks fr ON fr.id = fm.rank_id
        WHERE fm.char_id = ? AND fm.active = 1
        ORDER BY fr.level DESC
    ]], { charId })

    return rows or {}
end
exports('GetPlayerFactions', GetPlayerFactions)

function GetFactionMembers(factionId)
    factionId = tonumber(factionId)
    if not factionId then return {} end

    local rows = MySQL.query.await([[
        SELECT fm.*, c.name as char_name,
               fr.name AS rank_name, fr.level AS rank_level
        FROM faction_members fm
        JOIN characters c ON c.id = fm.char_id
        JOIN faction_ranks fr ON fr.id = fm.rank_id
        WHERE fm.faction_id = ? AND fm.active = 1
        ORDER BY fr.level DESC, c.name ASC
    ]], { factionId })

    return rows or {}
end
exports('GetFactionMembers', GetFactionMembers)

function GetFactionRanks(factionId)
    factionId = tonumber(factionId)
    if not factionId then return {} end

    local cache = RankCache[factionId]
    if not cache or not cache.byId or not next(cache.byId) then
        cache = LoadRanksForFaction(factionId)
    end
    if not cache or not cache.byId then return {} end

    local list = {}
    for _, r in pairs(cache.byId) do
        list[#list+1] = r
    end

    table.sort(list, function(a, b)
        return (tonumber(a.level) or 0) > (tonumber(b.level) or 0)
    end)

    return list
end
exports('GetFactionRanks', GetFactionRanks)

function GetFactionLogs(factionId, limit)
    factionId = tonumber(factionId)
    if not factionId then return {} end
    limit = tonumber(limit) or 50

    local rows = MySQL.query.await([[
        SELECT
            l.*,
            ac.name AS actor_name,
            tc.name AS target_name
        FROM faction_logs l
        LEFT JOIN characters ac ON ac.id = l.actor_char_id
        LEFT JOIN characters tc ON tc.id = l.target_char_id
        WHERE l.faction_id = ?
        ORDER BY l.created_at DESC
        LIMIT ?
    ]], { factionId, limit })

    return rows or {}
end
exports('GetFactionLogs', GetFactionLogs)

----------------------------------------------------------
-- DUTY (persistent via faction_duty + Logging)
----------------------------------------------------------

local function _canUseDuty(charId, factionId)
    charId = tonumber(charId)
    factionId = tonumber(factionId)
    if not charId or not factionId then return false end

    local row = MySQL.single.await([[
        SELECT f.id
        FROM factions f
        INNER JOIN faction_members fm
            ON fm.faction_id = f.id
           AND fm.char_id = ?
           AND fm.active = 1
        WHERE f.id = ?
          AND f.duty_required = 1
        LIMIT 1
    ]], { charId, factionId })

    return row ~= nil
end

local function _closeOpenDutyLog(charId, factionId)
    MySQL.update.await([[
        UPDATE faction_duty_log
        SET duty_off = NOW(),
            duration_seconds = TIMESTAMPDIFF(SECOND, duty_on, NOW())
        WHERE char_id = ?
          AND faction_id = ?
          AND duty_off IS NULL
        ORDER BY duty_on DESC
        LIMIT 1
    ]], { charId, factionId })
end

local function _setDutyPersistent(charId, factionId, state)
    charId = tonumber(charId)
    factionId = tonumber(factionId)
    if not charId or not factionId then
        return false, 'invalid_params'
    end

    if state then
        -- vorhandene aktive Sessions schließen
        _closeOpenDutyLog(charId, factionId)

        -- alten Status löschen
        MySQL.update.await([[
            DELETE FROM faction_duty
            WHERE char_id = ?
              AND faction_id = ?
        ]], { charId, factionId })

        -- neuen aktiven Status setzen
        MySQL.insert.await([[
            INSERT INTO faction_duty (char_id, faction_id)
            VALUES (?, ?)
        ]], { charId, factionId })

        -- Log-Eintrag für neue Session
        MySQL.insert.await([[
            INSERT INTO faction_duty_log (char_id, faction_id, duty_on)
            VALUES (?, ?, NOW())
        ]], { charId, factionId })
    else
        -- aktiven Status entfernen
        MySQL.update.await([[
            DELETE FROM faction_duty
            WHERE char_id = ?
              AND faction_id = ?
        ]], { charId, factionId })

        -- offene Log-Session schließen
        _closeOpenDutyLog(charId, factionId)
    end

    return true
end

function SetDuty(srcOrChar, factionIdOrName, state)
    local charId = GetCharIdFromSource(srcOrChar) or tonumber(srcOrChar)
    if not charId then
        return false, 'no_char'
    end

    local faction
    if type(factionIdOrName) == 'string' and not tonumber(factionIdOrName) then
        faction = GetFactionByName(factionIdOrName)
    else
        faction = GetFactionById(factionIdOrName)
    end
    if not faction then
        return false, 'no_faction'
    end

    if IsDutyRequiredForFaction(faction) and not _canUseDuty(charId, faction.id) then
        return false, 'not_member_or_not_duty_required'
    end

    local on = (state ~= false)

    local ok, err = _setDutyPersistent(charId, faction.id, on)
    if not ok then return false, err end

    LogFactionAction(faction.id, charId, nil, on and 'duty_on' or 'duty_off', {})

    return true
end
exports('SetDuty', SetDuty)

function IsOnDuty(srcOrChar, factionIdOrName)
    local charId = GetCharIdFromSource(srcOrChar) or tonumber(srcOrChar)
    if not charId then return false end

    local faction
    if type(factionIdOrName) == 'string' and not tonumber(factionIdOrName) then
        faction = GetFactionByName(factionIdOrName)
    else
        faction = GetFactionById(factionIdOrName)
    end
    if not faction then return false end

    if not IsDutyRequiredForFaction(faction) then
        return true
    end

    local exists = MySQL.scalar.await([[
        SELECT 1
        FROM faction_duty
        WHERE char_id = ?
          AND faction_id = ?
        LIMIT 1
    ]], { charId, faction.id })

    return exists ~= nil
end
exports('IsOnDuty', IsOnDuty)

function GetDutyFactions(srcOrChar)
    local charId = GetCharIdFromSource(srcOrChar) or tonumber(srcOrChar)
    if not charId then return {} end

    local rows = MySQL.query.await([[
        SELECT DISTINCT
            f.id,
            f.name,
            f.label,
            CASE
                WHEN d.id IS NOT NULL THEN 1
                ELSE 0
            END AS onDuty
        FROM factions f
        INNER JOIN faction_members fm
            ON fm.faction_id = f.id
           AND fm.char_id = ?
           AND fm.active = 1
        LEFT JOIN faction_duty d
            ON d.char_id = fm.char_id
           AND d.faction_id = f.id
        WHERE f.duty_required = 1
        ORDER BY f.label, f.name
    ]], { charId }) or {}

    for _, f in ipairs(rows) do
        f.id     = tonumber(f.id) or 0
        f.onDuty = (f.onDuty == 1 or f.onDuty == true)
    end

    return rows
end
exports('GetDutyFactions', GetDutyFactions)

----------------------------------------------------------
-- PERMISSIONS
----------------------------------------------------------

local function _fetchMemberRankSimple(charId, factionId)
    local rows = MySQL.query.await([[
        SELECT fm.*, fr.level, fr.permissions
        FROM faction_members fm
        JOIN faction_ranks fr ON fr.id = fm.rank_id
        WHERE fm.char_id = ? AND fm.faction_id = ? AND fm.active = 1
        LIMIT 1
    ]], { charId, factionId })

    local row = rows and rows[1]
    if not row then return nil end

    if type(row.permissions) == 'string' then
        local ok, decoded = pcall(json.decode, row.permissions)
        row.permissions = ok and decoded or {}
    elseif type(row.permissions) ~= 'table' then
        row.permissions = {}
    end

    return row
end

function HasFactionPermission(srcOrChar, factionIdOrName, permKey)
    if not permKey then return false end

    local charId = GetCharIdFromSource(srcOrChar) or tonumber(srcOrChar)
    if not charId then return false end

    local faction
    if type(factionIdOrName) == 'string' and not tonumber(factionIdOrName) then
        faction = GetFactionByName(factionIdOrName)
    else
        faction = GetFactionById(factionIdOrName)
    end
    if not faction then return false end

    local member = _fetchMemberRankSimple(charId, faction.id)
    if not member then return false end

    if IsDutyRequiredForFaction(faction) then
        if not IsOnDuty(charId, faction.id) and not (tonumber(member.level) >= 100) then
            return false
        end
    end

    local perms = member.permissions or {}

    if tonumber(member.level) >= 100 then
        return true
    end

    return perms[permKey] == true
end
exports('HasFactionPermission', HasFactionPermission)

function IsFactionLeader(srcOrChar, factionIdOrName, minLevel)
    minLevel = tonumber(minLevel) or 100

    local charId = GetCharIdFromSource(srcOrChar) or tonumber(srcOrChar)
    if not charId then return false end

    local faction
    if type(factionIdOrName) == 'string' and not tonumber(factionIdOrName) then
        faction = GetFactionByName(factionIdOrName)
    else
        faction = GetFactionById(factionIdOrName)
    end
    if not faction then return false end

    local member = _fetchMemberRankSimple(charId, faction.id)
    if not member then return false end

    return (tonumber(member.level) or 0) >= minLevel
end
exports('IsFactionLeader', IsFactionLeader)

local function _getAllMembershipsWithRank(charId)
    local rows = MySQL.query.await([[
        SELECT
            fm.faction_id,
            f.name        AS faction_name,
            fr.level,
            fr.permissions
        FROM faction_members fm
        JOIN faction_ranks fr ON fr.id = fm.rank_id
        JOIN factions f       ON f.id = fm.faction_id
        WHERE fm.char_id = ? AND fm.active = 1
    ]], { charId }) or {}

    for _, row in ipairs(rows) do
        if type(row.permissions) == 'string' then
            local ok, decoded = pcall(json.decode, row.permissions)
            row.permissions = ok and decoded or {}
        elseif type(row.permissions) ~= 'table' then
            row.permissions = {}
        end
    end

    return rows
end

function HasAnyFactionPermission(srcOrChar, permKey, minLevel)
    if not permKey then return false end
    minLevel = tonumber(minLevel) or 0

    local charId = GetCharIdFromSource(srcOrChar) or tonumber(srcOrChar)
    if not charId then return false end

    local memberships = _getAllMembershipsWithRank(charId)
    if not memberships[1] then return false end

    for _, m in ipairs(memberships) do
        local lvl = tonumber(m.level) or 0

        if lvl >= 100 then
            return true
        end

        if lvl >= minLevel and m.permissions[permKey] == true then
            return true
        end
    end

    return false
end
exports('HasAnyFactionPermission', HasAnyFactionPermission)

----------------------------------------------------------
-- LOGGING
----------------------------------------------------------

function LogFactionAction(factionId, actorCharId, targetCharId, action, details)
    factionId = tonumber(factionId)
    if not factionId or not action then return end

    local payload = details
    if details and type(details) ~= 'string' then
        payload = json.encode(details)
    end

    MySQL.insert.await([[
        INSERT INTO faction_logs (faction_id, actor_char_id, target_char_id, action, details)
        VALUES (?, ?, ?, ?, ?)
    ]], {
        factionId,
        actorCharId or nil,
        targetCharId or nil,
        action,
        payload
    })
end
exports('LogFactionAction', LogFactionAction)

----------------------------------------------------------
-- EXPORTS: MUTATIONEN
----------------------------------------------------------

function UpdateFaction(factionId, data)
    factionId = tonumber(factionId)
    if not factionId or not data then
        return false, 'invalid_params'
    end

    local fields = {}
    local params = {}

    if data.name and data.name ~= '' then
        fields[#fields+1] = 'name = ?'
        params[#params+1] = data.name
    end

    if data.label ~= nil then
        fields[#fields+1] = 'label = ?'
        params[#params+1] = (data.label ~= '' and data.label) or nil
    end

    if data.description ~= nil then
        fields[#fields+1] = 'description = ?'
        params[#params+1] = data.description
    end

    if data.leader_char_id ~= nil then
        local leaderId = tonumber(data.leader_char_id)
        fields[#fields+1] = 'leader_char_id = ?'
        params[#params+1] = leaderId or nil
    end

    if data.duty_required ~= nil then
        local duty = data.duty_required
        if duty == true then duty = 1 end
        if duty == false then duty = 0 end
        duty = tonumber(duty) or 0

        fields[#fields+1] = 'duty_required = ?'
        params[#params+1] = duty
    end

    if data.is_gang ~= nil then
        local gang = data.is_gang
        if gang == true then gang = 1 end
        if gang == false then gang = 0 end
        gang = tonumber(gang) or 0

        fields[#fields+1] = 'is_gang = ?'
        params[#params+1] = gang
    end

    if #fields == 0 then
        return false, 'nothing_to_update'
    end

    local sql = 'UPDATE factions SET ' .. table.concat(fields, ', ') .. ' WHERE id = ?'
    params[#params+1] = factionId

    local affected = MySQL.update.await(sql, params)
    if (affected or 0) > 0 then
        LoadFaction(factionId)
        return true
    end

    return false, 'no_change'
end
exports('UpdateFaction', UpdateFaction)

function CreateFaction(name, label, leaderCharId, description, createdByCharId)
    if not name or name == '' then
        return nil, 'missing_name'
    end

    name = tostring(name)

    local existingId = MySQL.scalar.await('SELECT id FROM factions WHERE name = ?', { name })
    if existingId then
        return tonumber(existingId), 'already_exists'
    end

    local insertId = nil
    local ok, err = pcall(function()
        insertId = MySQL.insert.await([[
            INSERT INTO factions (name, label, leader_char_id, description, created_by)
            VALUES (?, ?, ?, ?, ?)
        ]], {
            name,
            label or name,
            leaderCharId or nil,
            description or nil,
            createdByCharId or leaderCharId or nil
        })
    end)

    if not ok then
        local msg = tostring(err or ''):lower()

        if msg:find('duplicate entry') then
            local dupId = MySQL.scalar.await('SELECT id FROM factions WHERE name = ?', { name })
            if dupId then
                return tonumber(dupId), 'already_exists'
            end
            return nil, 'already_exists'
        end

        print(('[factionManager] CreateFaction DB-Error: %s'):format(err))
        return nil, 'db_error'
    end

    if not insertId or insertId <= 0 then
        local chkId = MySQL.scalar.await('SELECT id FROM factions WHERE name = ?', { name })
        if chkId then
            return tonumber(chkId), 'already_exists'
        end
        return nil, 'db_error'
    end

    insertId = tonumber(insertId)

    local rows = MySQL.query.await('SELECT * FROM factions WHERE id = ?', { insertId })
    local faction = rows and rows[1]
    if faction then
        FactionCache[insertId] = faction
    end

    EnsureFactionRanks(insertId)

    LogFactionAction(insertId, createdByCharId or leaderCharId, nil, 'create_faction', {
        name = name,
        label = label or name
    })

    if leaderCharId then
        local ranks = RankCache[insertId] or LoadRanksForFaction(insertId)
        local leaderRank = ranks and ranks.byLevel and ranks.byLevel[100]
        if leaderRank then
            MySQL.insert.await(
                'INSERT INTO faction_members (faction_id, char_id, rank_id) VALUES (?, ?, ?)',
                { insertId, leaderCharId, leaderRank.id }
            )
        end
    end

    return insertId
end
exports('CreateFaction', CreateFaction)

function DeleteFaction(factionId)
    factionId = tonumber(factionId)
    if not factionId then return false, 'invalid_id' end

    local affected = MySQL.update.await('DELETE FROM factions WHERE id = ?', { factionId })
    FactionCache[factionId] = nil
    RankCache[factionId] = nil

    return affected > 0
end
exports('DeleteFaction', DeleteFaction)

function CreateRank(factionId, name, level, permissions)
    factionId = tonumber(factionId)
    level = tonumber(level) or 1

    if not factionId or not name or name == '' then
        return nil, 'invalid_params'
    end

    local existsName = MySQL.scalar.await(
        'SELECT id FROM faction_ranks WHERE faction_id = ? AND name = ?',
        { factionId, name }
    )
    if existsName then
        return nil, 'name_exists'
    end

    local existsLevel = MySQL.scalar.await(
        'SELECT id FROM faction_ranks WHERE faction_id = ? AND level = ?',
        { factionId, level }
    )
    if existsLevel then
        return nil, 'level_exists'
    end

    local id
    local ok, err = pcall(function()
        id = MySQL.insert.await([[
            INSERT INTO faction_ranks (faction_id, name, level, permissions)
            VALUES (?, ?, ?, ?)
        ]], {
            factionId,
            name,
            level,
            json.encode(permissions or {})
        })
    end)

    if not ok then
        local msg = tostring(err or ''):lower()

        if msg:find('duplicate entry') then
            local dupName = MySQL.scalar.await(
                'SELECT id FROM faction_ranks WHERE faction_id = ? AND name = ?',
                { factionId, name }
            )
            if dupName then
                return nil, 'name_exists'
            end

            local dupLevel = MySQL.scalar.await(
                'SELECT id FROM faction_ranks WHERE faction_id = ? AND level = ?',
                { factionId, level }
            )
            if dupLevel then
                return nil, 'level_exists'
            end

            return nil, 'duplicate'
        end

        print(('[factionManager] CreateRank DB-Error: %s'):format(err))
        return nil, 'db_error'
    end

    if not id or id <= 0 then
        return nil, 'db_error'
    end

    LoadRanksForFaction(factionId)
    return id
end
exports('CreateRank', CreateRank)

function UpdateRankPermissions(rankId, permissions)
    rankId = tonumber(rankId)
    if not rankId then return false, 'invalid_rank' end

    local affected = MySQL.update.await(
        'UPDATE faction_ranks SET permissions = ? WHERE id = ?',
        { json.encode(permissions or {}), rankId }
    )

    RankCache = {}
    return affected > 0
end
exports('UpdateRankPermissions', UpdateRankPermissions)

function UpdateRank(rankId, data)
    rankId = tonumber(rankId)
    if not rankId or not data then
        return false, 'invalid_params'
    end

    local rows = MySQL.query.await('SELECT * FROM faction_ranks WHERE id = ?', { rankId })
    local current = rows and rows[1]
    if not current then
        return false, 'not_found'
    end

    local factionId = tonumber(current.faction_id)
    local fields, params = {}, {}

    if data.name and data.name ~= '' and data.name ~= current.name then
        local existsName = MySQL.scalar.await(
            'SELECT id FROM faction_ranks WHERE faction_id = ? AND name = ? AND id <> ?',
            { factionId, data.name, rankId }
        )
        if existsName then
            return false, 'name_exists'
        end
        fields[#fields+1] = 'name = ?'
        params[#params+1] = data.name
    end

    if data.level and tonumber(data.level) ~= tonumber(current.level) then
        local newLevel = tonumber(data.level) or 1
        local existsLevel = MySQL.scalar.await(
            'SELECT id FROM faction_ranks WHERE faction_id = ? AND level = ? AND id <> ?',
            { factionId, newLevel, rankId }
        )
        if existsLevel then
            return false, 'level_exists'
        end
        fields[#fields+1] = 'level = ?'
        params[#params+1] = newLevel
    end

    if data.permissions then
        fields[#fields+1] = 'permissions = ?'
        params[#params+1] = json.encode(data.permissions or {})
    end

    if #fields == 0 then
        return false, 'nothing_to_update'
    end

    local sql = 'UPDATE faction_ranks SET ' .. table.concat(fields, ', ') .. ' WHERE id = ?'
    params[#params+1] = rankId

    local affected = MySQL.update.await(sql, params)
    if (affected or 0) > 0 then
        LoadRanksForFaction(factionId)
        return true
    end

    return false, 'no_change'
end
exports('UpdateRank', UpdateRank)

function DeleteRank(rankId)
    rankId = tonumber(rankId)
    if not rankId then
        return false, 'invalid_rank'
    end

    local inUse = MySQL.scalar.await(
        'SELECT 1 FROM faction_members WHERE rank_id = ? AND active = 1 LIMIT 1',
        { rankId }
    )

    if inUse then
        return false, 'rank_in_use'
    end

    local ok, res = pcall(function()
        return MySQL.update.await('DELETE FROM faction_ranks WHERE id = ?', { rankId })
    end)

    if not ok then
        local msg = tostring(res or ''):lower()
        if msg:find('foreign key constraint') then
            return false, 'rank_in_use'
        end

        print(('[factionManager] DeleteRank DB-Error: %s'):format(res))
        return false, 'db_error'
    end

    local affected = tonumber(res) or 0
    if affected > 0 then
        RankCache = {}
        return true
    end

    return false, 'not_found'
end
exports('DeleteRank', DeleteRank)

function AddMember(factionId, charId, rankId)
    factionId = tonumber(factionId)
    charId = tonumber(charId)
    rankId = tonumber(rankId)

    if not factionId or not charId or not rankId then
        return nil, 'invalid_params'
    end

    local existing = MySQL.scalar.await(
        'SELECT id FROM faction_members WHERE faction_id = ? AND char_id = ?',
        { factionId, charId }
    )
    if existing then
        MySQL.update.await(
            'UPDATE faction_members SET rank_id = ?, active = 1 WHERE id = ?',
            { rankId, existing }
        )
        return existing
    end

    local id = MySQL.insert.await(
        'INSERT INTO faction_members (faction_id, char_id, rank_id) VALUES (?, ?, ?)',
        { factionId, charId, rankId }
    )

    return id
end
exports('AddMember', AddMember)

function RemoveMember(factionId, charId)
    factionId = tonumber(factionId)
    charId = tonumber(charId)
    if not factionId or not charId then
        return false, 'invalid_params'
    end

    local affected = MySQL.update.await(
        'UPDATE faction_members SET active = 0 WHERE faction_id = ? AND char_id = ? AND active = 1',
        { factionId, charId }
    )

    return affected > 0
end
exports('RemoveMember', RemoveMember)

function SetMemberRank(factionId, charId, newRankId)
    factionId = tonumber(factionId)
    charId = tonumber(charId)
    newRankId = tonumber(newRankId)

    if not factionId or not charId or not newRankId then
        return false, 'invalid_params'
    end

    local affected = MySQL.update.await(
        'UPDATE faction_members SET rank_id = ? WHERE faction_id = ? AND char_id = ? AND active = 1',
        { newRankId, factionId, charId }
    )

    return affected > 0
end
exports('SetMemberRank', SetMemberRank)
