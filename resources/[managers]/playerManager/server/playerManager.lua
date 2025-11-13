-- resources/playerManager/server/playerManager.lua
-- LyraCityV - Player / Character Lifecycle & Autosave
-- Version 1.3.0 (pure oxmysql)

local json = json

local Session    = {}  -- [src] = { account_id, char_id }
local PlayerData = {}  -- [src] = { account_id, char_id, character = {...}, clothes = {...}, appearances = {...}, updatedAt }

-- =========================================================
-- Utils / Guards
-- =========================================================
local function log(level, msg)
    print(('[PlayerManager][%s] %s'):format(level, tostring(msg)))
end

if not MySQL then
    log('ERROR', 'MySQL ist nil. Stelle sicher, dass @oxmysql vor diesem Script geladen wird!')
end

local function safeName(src) return GetPlayerName(src) or ('src:' .. tostring(src)) end
local function toN(v, d) local n = tonumber(v); return n ~= nil and n or d end

local function decodeJsonField(value, fallback)
    if not value then return fallback or {} end
    if type(value) == "table" then return value end
    if type(value) ~= "string" then return fallback or {} end
    local ok, res = pcall(function() return json.decode(value) end)
    if ok and res then return res end
    return fallback or {}
end

local function sanitizeCharacter(full)
    if not full then return nil end

    local function b2n(v, d)
        if type(v) == 'boolean' then return v and 1 or 0 end
        local n = tonumber(v)
        return n ~= nil and n or (d or 0)
    end

    full.gender            = b2n(full.gender, 0)
    full.dimension         = b2n(full.dimension, 0)
    full.health            = b2n(full.health, 200)
    full.thirst            = b2n(full.thirst, 100)
    full.food              = b2n(full.food, 100)

    -- 👇 Wichtig: TinyInt(1) kommt als boolean rein → korrekt nach Zahl mappen
    full.residence_permit  = b2n(full.residence_permit, 0)
    full.past              = b2n(full.past, 0)
    full.is_locked         = (full.is_locked == 1 or full.is_locked == true) and 1 or 0

    full.pos_x             = b2n(full.pos_x, 0.0)
    full.pos_y             = b2n(full.pos_y, 0.0)
    full.pos_z             = b2n(full.pos_z, 0.0)
    full.heading           = b2n(full.heading, 0.0)

    full.appearance        = decodeJsonField(full.appearance, {})
    full.clothes           = decodeJsonField(full.clothes, {})
    return full
end


local function buildSpawnData(full)
    full = sanitizeCharacter(full)
    if not full then return nil end
print(('[DEBUG][playerManager][playerManager.lua - Server - buildSpawnData] Residence Permit: %s | Past: %s'):format(full.residence_permit,full.past))
    local x, y, z, heading
    if (full.residence_permit or 0) >= 1 then
        x, y, z, heading = full.pos_x, full.pos_y, full.pos_z, full.heading --Letze Spieler Position weil eingereist
    elseif full.residence_permit == 0 and (full.past or 0) == 0 then -- Flughafen weil nicht eingereist und legaler weg
        x, y, z, heading = -1111.24, -2843.37, 14.89, 267.78
    elseif full.residence_permit == 0 and (full.past or 0) == 1 then -- Prison weil nicht eingereist und Illegaler weg
        x, y, z, heading = 1690.70, 2606.72, 45.56, 281.05
    else
        x, y, z, heading = 0.0, 0.0, 0.0, 0.0
    end

    local g = full.gender
    if type(g) == "boolean" then g = g and 1 or 0 end
    g = toN(g, 0)

    return {
        id               = full.id,
        name             = full.name,
        gender           = g,
        health           = full.health,
        thirst           = full.thirst,
        food             = full.food,
        pos              = { x = x, y = y, z = z },
        heading          = heading,
        dimension        = toN(full.dimension, 0),
        clothes          = full.clothes or {},
        appearances      = full.appearance or {},
        residence_permit = toN(full.residence_permit, 0),
        past             = toN(full.past, 0),
    }
end

-- =========================================================
-- DB Helpers (pure oxmysql)
-- =========================================================
local function db_getCharacterOwned(charId, accountId)
    return MySQL.single.await('SELECT id FROM characters WHERE id=? AND account_id=?', { charId, accountId })
end

local function db_getCharacterFull(charId, accountId)
    return MySQL.single.await([[
        SELECT
            id, account_id, name, gender, level, birthdate, type,
            is_locked,
            CAST(residence_permit AS SIGNED) AS residence_permit,
            CAST(past AS SIGNED)             AS past,
            dimension, health, thirst, food,
            pos_x, pos_y, pos_z, heading,
            appearance, clothes
        FROM characters
        WHERE id=? AND account_id=?
    ]], { charId, accountId })
end


local function db_updateState(charId, accountId, state)
    local pos   = state.pos or {}
    local app   = state.appearance and json.encode(state.appearance) or nil
    local cloth = state.clothes and json.encode(state.clothes) or nil

    return MySQL.update.await([[
        UPDATE characters
        SET pos_x=?, pos_y=?, pos_z=?, heading=?,
            dimension=?, health=?, thirst=?, food=?,
            appearance=COALESCE(?, appearance),
            clothes=COALESCE(?, clothes)
        WHERE id=? AND account_id=?
    ]], {
        toN(pos.x, 0.0), toN(pos.y, 0.0), toN(pos.z, 0.0),
        toN(state.heading, 0.0),
        toN(state.dimension, 0),
        toN(state.health, 200),
        toN(state.thirst, 100),
        toN(state.food, 100),
        app, cloth,
        charId, accountId
    })
end

local function db_createCharacter(accountId, data)
    local name     = tostring(data.name or ''):gsub('^%s+', ''):gsub('%s+$', '')
    local gender   = tonumber(data.gender) or 0
    local past     = tonumber(data.past) or 0
    local permit   = tonumber(data.residence_permit) or 0
    local dim      = tonumber(data.dimension) or 0
    local health   = tonumber(data.health) or 200
    local thirst   = tonumber(data.thirst) or 100
    local food     = tonumber(data.food) or 100
    local hx       = tonumber(data.pos and data.pos.x) or 0.0
    local hy       = tonumber(data.pos and data.pos.y) or 0.0
    local hz       = tonumber(data.pos and data.pos.z) or 0.0
    local heading  = tonumber(data.heading) or 0.0

    -- WICHTIG: beide Felder mitschreiben (Spalten ohne Default!)
    local birthdate        = tostring(data.birthdate or '2000-01-01')         -- DATE 'YYYY-MM-DD'
    local heritage_country = tostring(data.heritage_country or '')            -- z.B. 'DE'

    local appearance = json.encode(data.appearance or {})
    local clothes    = json.encode(data.clothes or {})

    return MySQL.insert.await([[
        INSERT INTO characters
            (account_id, name, gender, level, type,
             is_locked, residence_permit, past,
             dimension, health, thirst, food,
             pos_x, pos_y, pos_z, heading,
             appearance, clothes,
             birthdate, heritage_country)
        VALUES (?, ?, ?, 1, 0,
                0, ?, ?,
                ?, ?, ?, ?,
                ?, ?, ?, ?,
                ?, ?,
                ?, ?)
    ]], {
        tonumber(accountId), name, gender,
        permit, past,
        dim, health, thirst, food,
        hx, hy, hz, heading,
        appearance, clothes,
        birthdate, heritage_country
    })
end


local function db_deleteCharacterOwned(charId, accountId)
    return MySQL.update.await('DELETE FROM characters WHERE id=? AND account_id=?', { charId, accountId })
end

local function db_renameCharacterOwned(charId, accountId, newName)
    return MySQL.update.await('UPDATE characters SET name=? WHERE id=? AND account_id=?', { newName, charId, accountId })
end

-- =========================================================
-- Session Handling
-- =========================================================
local function bindAccount(src, accountId)
    src       = tonumber(src)
    accountId = tonumber(accountId)
    if not (src and accountId) then return end
    Session[src] = Session[src] or {}
    Session[src].account_id = accountId
    log('DEBUG', ("Account gebunden: src=%s account_id=%s"):format(src, accountId))
end
exports('BindAccount', bindAccount)

local function clearSession(src)
    Session[src]    = nil
    PlayerData[src] = nil
end

-- =========================================================
-- Save / Autosave
-- =========================================================
local function buildStateForSave(src)
    src = tonumber(src)
    local s  = Session[src]
    local pd = PlayerData[src]
    if not s or not s.account_id or not s.char_id or not pd then return nil end

    local ped = GetPlayerPed(src)
    local px, py, pz, heading, dim, health
    if ped and ped ~= 0 then
        local coords = GetEntityCoords(ped)
        px, py, pz   = coords.x or coords[1], coords.y or coords[2], coords.z or coords[3]
        heading      = GetEntityHeading(ped)
        dim          = GetPlayerRoutingBucket and GetPlayerRoutingBucket(src) or 0
        health       = GetEntityHealth(ped)
    end

    local char = pd.character or {}
    return {
        pos = {
            x = px or char.pos_x or 0.0,
            y = py or char.pos_y or 0.0,
            z = pz or char.pos_z or 0.0,
        },
        heading   = heading or char.heading or 0.0,
        dimension = dim or char.dimension or 0,
        health    = health or char.health or 200,
        thirst    = char.thirst or 100,
        food      = char.food or 100,
        appearance = pd.appearances or char.appearance or {},
        clothes    = pd.clothes or char.clothes or {},
    }
end

local function saveCharacter(src, reason, cb)
    src = tonumber(src)
    local s = Session[src]
    if not s or not s.account_id or not s.char_id then if cb then cb(false) end return end

    local state = buildStateForSave(src)
    if not state then if cb then cb(false) end return end

    local affected = db_updateState(s.char_id, s.account_id, state)
    if affected and affected >= 0 then
        log("DEBUG", ("Autosave (%s): src=%s acc=%s char=%s"):format(reason or "auto", src, s.account_id, s.char_id))
        if cb then cb(true) end
    else
        if cb then cb(false) end
    end
end
exports('SaveCharacter', function(src, cb) saveCharacter(src, 'manual-export', cb) end)

AddEventHandler('playerDropped', function(_)
    local src = source
    if Session[src] and Session[src].char_id then
        saveCharacter(src, 'drop', function() clearSession(src) end)
    else
        clearSession(src)
    end
end)

CreateThread(function()
    local minutes = tonumber(GetConvar('lcv_autosave_minutes', '5')) or 5
    if minutes < 1 then log("INFO", "Autosave deaktiviert."); return end
    local interval = minutes * 60 * 1000
    log("INFO", ("Autosave aktiv: alle %d Minuten."):format(minutes))
    while true do
        Wait(interval)
        for src, s in pairs(Session) do
            if s and s.account_id and s.char_id then
                saveCharacter(src, 'interval')
            end
        end
    end
end)

-- =========================================================
-- Charakter auswählen / erstellen / löschen / umbenennen
-- =========================================================
RegisterNetEvent('LCV:Player:SelectCharacter', function(a, b)
    local src, charId
    if b ~= nil then src = toN(a); charId = toN(b) else src = source; charId = toN(a) end
    if not src or not charId then return end

    local s = Session[src]
    if not s or not s.account_id then
        return TriggerClientEvent('LCV:error', src, "Kein Account gebunden. Bitte neu verbinden.")
    end

    local owned = db_getCharacterOwned(charId, s.account_id)
    if not owned or not owned.id then
        return TriggerClientEvent('LCV:error', src, "Ungültige Charakter-ID oder nicht dein Charakter.")
    end

    s.char_id = charId
    local full = db_getCharacterFull(charId, s.account_id)
    if not full or not full.id then
        return TriggerClientEvent('LCV:error', src, "Charakterdaten nicht gefunden.")
    end

    local spawnData = buildSpawnData(full)
    if not spawnData then
        return TriggerClientEvent('LCV:error', src, "Fehler beim Vorbereiten der Spawn-Daten.")
    end

    local dim = toN(spawnData.dimension, 0)
    if SetPlayerRoutingBucket then SetPlayerRoutingBucket(src, dim) end

    PlayerData[src] = {
        account_id  = s.account_id,
        char_id     = full.id,
        character   = sanitizeCharacter(full),
        clothes     = spawnData.clothes,
        appearances = spawnData.appearances,
        updatedAt   = os.time(),
    }

    log("INFO", ("Charakter gewählt: src=%s (%s) char_id=%s name=%s")
        :format(src, safeName(src), full.id, tostring(full.name)))

    TriggerClientEvent('LCV:ui:setStomach', src, spawnData.thirst, spawnData.food)
    TriggerClientEvent('LCV:characterSelected', src, { id = full.id, name = full.name })
    TriggerClientEvent('LCV:spawn', src, spawnData)
end)

RegisterNetEvent('LCV:Player:CreateCharacter', function(data)
    local src = source
    local s = Session[src]
    if not s or not s.account_id then return TriggerClientEvent('LCV:error', src, "Kein Account gebunden.") end

    data = data or {}
    local name = tostring(data.name or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if #name < 3 or #name > 60 then return TriggerClientEvent('LCV:error', src, "Ungültiger Name.") end

    local newId = db_createCharacter(s.account_id, data)
    if not newId then return TriggerClientEvent('LCV:error', src, "Fehler beim Erstellen des Charakters.") end

    log("INFO", ("Charakter erstellt: account_id=%s char_id=%s name=%s"):format(s.account_id, newId, name))
    TriggerClientEvent('LCV:charCreated', src, { id = newId, name = name, gender = data.gender or 0 })
end)

RegisterNetEvent('LCV:Player:DeleteCharacter', function(charId)
    local src = source
    local s = Session[src]
    if not s or not s.account_id then return TriggerClientEvent('LCV:error', src, "Kein Account gebunden.") end
    charId = toN(charId)
    if not charId then return end

    local affected = db_deleteCharacterOwned(charId, s.account_id)
    if not affected or affected <= 0 then
        return TriggerClientEvent('LCV:error', src, "Charakter konnte nicht gelöscht werden.")
    end

    if Session[src] and Session[src].char_id == charId then
        Session[src].char_id = nil
        PlayerData[src] = nil
    end
    log("INFO", ("Charakter gelöscht: account_id=%s char_id=%s"):format(s.account_id, charId))
    TriggerClientEvent('LCV:charDeleted', src, charId)
end)

RegisterNetEvent('LCV:Player:RenameCharacter', function(charId, newName)
    local src = source
    local s = Session[src]
    if not s or not s.account_id then return TriggerClientEvent('LCV:error', src, "Kein Account gebunden.") end

    charId  = toN(charId)
    newName = tostring(newName or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if not charId or #newName < 3 or #newName > 60 then
        return TriggerClientEvent('LCV:error', src, "Ungültige Eingabe.")
    end

    local affected = db_renameCharacterOwned(charId, s.account_id, newName)
    if not affected or affected <= 0 then
        return TriggerClientEvent('LCV:error', src, "Charakter konnte nicht umbenannt werden.")
    end

    if PlayerData[src] and PlayerData[src].char_id == charId and PlayerData[src].character then
        PlayerData[src].character.name = newName
    end

    log("INFO", ("Charakter umbenannt: account_id=%s char_id=%s name=%s"):format(s.account_id, charId, newName))
    TriggerClientEvent('LCV:charRenamed', src, { id = charId, name = newName })
end)

-- =========================================================
-- State Sync / Autosave Input
-- =========================================================
RegisterNetEvent('LCV:Player:SyncState', function(state)
    local src = source
    local s = Session[src]
    if not s or not s.account_id or not s.char_id then return end

    state = state or {}
    local pd = PlayerData[src] or {}
    pd.account_id = s.account_id
    pd.char_id    = s.char_id
    pd.updatedAt  = os.time()
    pd.character  = pd.character or {}

    if state.pos then
        pd.character.pos_x = toN(state.pos.x, pd.character.pos_x or 0.0)
        pd.character.pos_y = toN(state.pos.y, pd.character.pos_y or 0.0)
        pd.character.pos_z = toN(state.pos.z, pd.character.pos_z or 0.0)
    end
    if state.heading   then pd.character.heading   = toN(state.heading,   pd.character.heading or 0.0) end
    if state.dimension then pd.character.dimension = toN(state.dimension, pd.character.dimension or 0) end
    if state.health    then pd.character.health    = toN(state.health,    pd.character.health or 200) end
    if state.thirst    then pd.character.thirst    = toN(state.thirst,    pd.character.thirst or 100) end
    if state.food      then pd.character.food      = toN(state.food,      pd.character.food or 100) end
    if state.appearance then pd.appearances = state.appearance end
    if state.clothes    then pd.clothes     = state.clothes end

    PlayerData[src] = pd
end)

-- =========================================================
-- Legacy Kompat PushData
-- =========================================================
AddEventHandler('Manager:Player:PushData', function(data)
    data = data or {}
    local src = tonumber(data.pedID or data.playerId or data.src)
    if not src then return end
    PlayerData[src] = {
        clothes    = data.clothes or {},
        character  = sanitizeCharacter(data.character),
        updatedAt  = os.time(),
    }
    log("DEBUG", ("[Compat] PushData für %s (%s) übernommen."):format(safeName(src), src))
end)

-- =========================================================
-- Exports (bestehend)
-- =========================================================
exports('GetSession', function(src) src = tonumber(src); return Session[src] end)
exports('GetAccountId', function(src) src = tonumber(src); return Session[src] and Session[src].account_id or nil end)
exports('GetActiveCharacterId', function(src) src = tonumber(src); return Session[src] and Session[src].char_id or nil end)
exports('GetPlayerData', function(src) src = tonumber(src); return PlayerData[src] end)

exports('CreateCharacter', function(accountId, data, cb)
    local id = db_createCharacter(accountId, data or {})
    if cb then cb(id) end
end)

exports('DeleteCharacter', function(accountId, charId, cb)
    local affected = db_deleteCharacterOwned(toN(charId), toN(accountId))
    if cb then cb(affected and affected > 0) end
end)

exports('RenameCharacter', function(accountId, charId, newName, cb)
    local ok = db_renameCharacterOwned(toN(charId), toN(accountId), tostring(newName or ''):gsub('^%s+',''):gsub('%s+$',''))
    if cb then cb(ok and ok > 0) end
end)

-- =========================================================
-- >>> ADMIN CRUD: Characters (pure oxmysql)
-- =========================================================
local function getOnlineCharIdSet()
    local set = {}
    for _, pd in pairs(PlayerData) do
        if pd and pd.character and pd.character.id then
            set[ tonumber(pd.character.id) ] = true
        elseif pd and pd.char_id then
            set[ tonumber(pd.char_id) ] = true
        end
    end
    return set
end

local function normalizeRow(r)
    r.id               = toN(r.id, 0)
    r.account_id       = toN(r.account_id, 0)
    r.level            = toN(r.level, 0)
    r.type             = toN(r.type, 0)
    r.is_locked        = (r.is_locked == 1 or r.is_locked == true)
    r.residence_permit = (r.residence_permit == 1 or r.residence_permit == true)
    r.past             = (r.past == 1 or r.past == true)
    if r.birthdate and type(r.birthdate) == "string" then
        local y, m, d = r.birthdate:match("^(%d%d%d%d)%-(%d%d)%-(%d%d)$")
        if not (y and m and d) then r.birthdate = nil end
    end
    return r
end

local function listCharacters(limit)
    limit = toN(limit, 500)
    if limit < 1 or limit > 2000 then limit = 500 end

    local rows = MySQL.query.await(([[
        SELECT
            id, account_id, name, level, birthdate, type,
            is_locked, residence_permit, past
        FROM characters
        ORDER BY id DESC
        LIMIT %d
    ]]):format(limit)) or {}

    local onlineSet = getOnlineCharIdSet()
    for i=1,#rows do
        rows[i] = normalizeRow(rows[i])
        rows[i].online = (onlineSet[ rows[i].id ] == true)
    end
    return { ok = true, characters = rows }
end
exports('ListCharacters', listCharacters)

local function updateCharacterFlags(data)
    if type(data) ~= 'table' or not data.id then
        return { ok=false, error='Ungültige Daten' }
    end
    local id = toN(data.id)
    if not id then return { ok=false, error='Ungültige ID' } end

    local is_locked      = (data.is_locked and 1 or 0)
    local residence_perm = (data.residence_permit and 1 or 0)

    local affected = MySQL.update.await([[
        UPDATE characters
        SET is_locked=?, residence_permit=?
        WHERE id=?
    ]], { is_locked, residence_perm, id })

    if not affected or affected <= 0 then
        return { ok = false, error = 'Keine Änderung vorgenommen' }
    end

    local row = MySQL.single.await([[
        SELECT id, account_id, name, level, birthdate, type, is_locked, residence_permit, past
        FROM characters WHERE id=?
    ]], { id })

    if row then
        row = normalizeRow(row)
        local onlineSet = getOnlineCharIdSet()
        row.online = (onlineSet[row.id] == true)
    end

    return { ok = true, row = row }
end
exports('UpdateCharacterFlags', updateCharacterFlags)

local function deleteCharacterById(id)
    id = toN(id)
    if not id then return { ok=false, error='Ungültige ID' } end

    local onlineSet = getOnlineCharIdSet()
    if onlineSet[id] then
        return { ok=false, error='Character ist aktuell online und kann nicht gelöscht werden.' }
    end

    local okQ, affected = pcall(function()
        return MySQL.update.await('DELETE FROM characters WHERE id=?', { id })
    end)

    if not okQ then
        log('ERROR', ('Admin-Delete error for id %s'):format(id))
        return { ok=false, error='DB-Fehler beim Löschen' }
    end

    if not affected or affected <= 0 then
        return { ok=false, error='Kein Datensatz gelöscht' }
    end
    return { ok=true }
end
exports('DeleteCharacterById', deleteCharacterById)

-- === Admin/Utility: Liste der Charaktere eines Accounts ===
local function listCharactersByAccount(accountId)
  accountId = tonumber(accountId)
  if not accountId then
    return { ok=false, error='invalid_account' }
  end

  local rows = MySQL.query.await([[
    SELECT id, account_id, name, gender, birthdate, type, is_locked
    FROM characters
    WHERE account_id = ?
    ORDER BY id ASC
  ]], { accountId }) or {}

for i=1,#rows do
    rows[i].is_locked = (rows[i].is_locked == 1 or rows[i].is_locked == true)

    -- Datum hübsch & garantiert als String
    local bd = rows[i].birthdate
    if bd ~= nil then
        if type(bd) == 'number' then
            -- Unix-Timestamp -> YYYY-MM-DD
            rows[i].birthdate = os.date('%d.%m.%Y', bd)

        elseif type(bd) == 'string' then
            -- 20250123 oder 2025-01-23 -> YYYY-MM-DD
            local y, m, d = bd:match('^(%d%d%d%d)[%-/]?(%d%d)[%-/]?(%d%d)$')
            if y and m and d then
                rows[i].birthdate = string.format('%s-%s-%s', y, m, d)
            elseif bd:match('^%d+$') and #bd >= 10 then
                -- Millisek.-Timestamp als String -> umrechnen
                local ts = math.floor(tonumber(bd) / 1000)
                rows[i].birthdate = os.date('%Y-%m-%d', ts)
            else
                -- Unbekanntes Format: so lassen
            end
        end
    end
    -- Fallback: nie nil an die UI geben
    if rows[i].birthdate == nil or rows[i].birthdate == '' then
        rows[i].birthdate = ''   -- oder '-' wenn du lieber einen Bindestrich willst
    end
end



  return { ok = true, characters = rows }
end
exports('ListCharactersByAccount', listCharactersByAccount)
