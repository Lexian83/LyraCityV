-- ==========================================
-- LyraCityV - Characters (Funktionen)
-- ==========================================
LCV.DB = LCV.DB or {}
LCV.Characters = LCV.Characters or {}

local DB  = LCV.DB
local CHR = LCV.Characters

local function log(level, msg)
    if LCV.Util and LCV.Util.log then
        LCV.Util.log(level, ('[Characters] %s'):format(tostring(msg)))
    else
        print(('[Characters][%s] %s'):format(level, tostring(msg)))
    end
end

local function jenc(v)
    if not v then return nil end
    if type(v) == "string" then return v end
    if not json or not json.encode then return nil end
    local ok, res = pcall(json.encode, v)
    if ok then return res end
    return nil
end

-- ========== SQL ==========

local SQL_LIST_BY_ACCOUNT = [[
  SELECT
    id, name, gender,
    COALESCE(health, 100) AS health,
    COALESCE(pos_x, 0)    AS pos_x,
    COALESCE(pos_y, 0)    AS pos_y,
    COALESCE(pos_z, 0)    AS pos_z
  FROM characters
  WHERE account_id = ?
  ORDER BY id ASC
]]

local SQL_INSERT_CHARACTER = [[
  INSERT INTO characters (
    account_id,
    name,
    gender,
    heritage_country,
    type,
    past,
    residence_permit,
    health, thirst, food,
    pos_x, pos_y, pos_z,
    heading, dimension,
    appearance,
    clothes,
    created_at
  )
  VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
]]

local SQL_SELECT_FULL = [[
  SELECT
    id, account_id, name, gender, heritage_country,
    COALESCE(health, 100)           AS health,
    COALESCE(thirst, 100)           AS thirst,
    COALESCE(food, 100)             AS food,
    COALESCE(pos_x, 0)              AS pos_x,
    COALESCE(pos_y, 0)              AS pos_y,
    COALESCE(pos_z, 0)              AS pos_z,
    COALESCE(heading, 0)            AS heading,
    COALESCE(dimension, 0)          AS dimension,
    created_at, level, birthdate, type, is_locked,
    appearance, clothes,
    COALESCE(residence_permit, 0)   AS residence_permit,
    COALESCE(past, 0)               AS past
  FROM characters
  WHERE id = ? AND account_id = ?
  LIMIT 1
]]

local SQL_SELECT_OWNED = [[
  SELECT id, name
  FROM characters
  WHERE id = ? AND account_id = ?
  LIMIT 1
]]

local SQL_RENAME_OWNED = [[
  UPDATE characters
  SET name = ?
  WHERE id = ? AND account_id = ?
  LIMIT 1
]]

local SQL_DELETE_OWNED = [[
  DELETE FROM characters
  WHERE id = ? AND account_id = ?
  LIMIT 1
]]

local SQL_UPDATE_STATE = [[
  UPDATE characters
  SET
    pos_x     = ?,
    pos_y     = ?,
    pos_z     = ?,
    heading   = ?,
    dimension = ?,
    health    = ?,
    thirst    = ?,
    food      = ?,
    appearance = ?,
    clothes    = ?
  WHERE id = ? AND account_id = ?
]]

-- ========== Funktionen ==========

function CHR.listByAccount(accountId, cb)
    DB.query(SQL_LIST_BY_ACCOUNT, { accountId }, function(rows)
        cb(rows or {})
    end)
end

function CHR.getFull(charId, accountId, cb)
    DB.single(SQL_SELECT_FULL, { charId, accountId }, function(row)
        cb(row) -- kann nil sein
    end)
end

function CHR.selectOwned(charId, accountId, cb)
    DB.single(SQL_SELECT_OWNED, { charId, accountId }, function(row)
        cb(row) -- nil = gehört nicht
    end)
end

-- Abwärtskompatibel:
--  CHR.create(accountId, name, gender, cb)
-- Neu:
--  CHR.create(accountId, {
--      name, gender, heritage_country, type, past, residence_permit,
--      pos = {x,y,z}, heading, dimension,
--      health, thirst, food,
--      appearance, clothes
--  }, cb)
function CHR.create(accountId, dataOrName, gender, cb)
    local data = {}

    if type(dataOrName) == "table" then
        data = dataOrName
    else
        data.name   = tostring(dataOrName)
        data.gender = tonumber(gender) or 1
    end

    data.name              = data.name or "New Character"
    data.gender            = tonumber(data.gender) or 1
    data.heritage_country  = data.heritage_country or "US"
    data.type              = tonumber(data.type) or 0
    data.past              = tonumber(data.past) or 0
    data.residence_permit  = tonumber(data.residence_permit) or 0

    local pos = data.pos or { x = -1037.5, y = -2737.8, z = 20.2 }
    local heading   = tonumber(data.heading)   or 0.0
    local dimension = tonumber(data.dimension) or 0

    local health = tonumber(data.health) or 200
    local thirst = tonumber(data.thirst) or 100
    local food   = tonumber(data.food)   or 100

    local appearance = jenc(data.appearance)
    local clothes    = jenc(data.clothes)

    local now = os.date('%Y-%m-%d %H:%M:%S')

    DB.insert(SQL_INSERT_CHARACTER, {
        accountId,
        data.name,
        data.gender,
        data.heritage_country,
        data.type,
        data.past,
        data.residence_permit,
        health, thirst, food,
        tonumber(pos.x) or 0.0,
        tonumber(pos.y) or 0.0,
        tonumber(pos.z) or 0.0,
        heading,
        dimension,
        appearance,
        clothes,
        now
    }, function(newId)
        if cb then cb(newId) end
    end)
end

function CHR.renameOwned(charId, accountId, newName, cb)
    if not newName or newName == "" then
        if cb then cb(false) end
        return
    end
    DB.update(SQL_RENAME_OWNED, { newName, charId, accountId }, function(affected)
        if cb then cb(affected and affected > 0) end
    end)
end

function CHR.deleteOwned(charId, accountId, cb)
    DB.update(SQL_DELETE_OWNED, { charId, accountId }, function(affected)
        if cb then cb(affected and affected > 0) end
    end)
end

function CHR.updateState(charId, accountId, state, cb)
    if not (charId and accountId and state) then
        if cb then cb(false) end
        return
    end

    local pos      = state.pos or {}
    local x        = tonumber(pos.x) or 0.0
    local y        = tonumber(pos.y) or 0.0
    local z        = tonumber(pos.z) or 0.0
    local heading  = tonumber(state.heading)   or 0.0
    local dim      = tonumber(state.dimension) or 0
    local health   = tonumber(state.health)    or 200
    local thirst   = tonumber(state.thirst)    or 100
    local food     = tonumber(state.food)      or 100
    local appear   = jenc(state.appearance)
    local clothes  = jenc(state.clothes)

    DB.update(SQL_UPDATE_STATE, {
        x, y, z,
        heading,
        dim,
        health,
        thirst,
        food,
        appear,
        clothes,
        charId,
        accountId
    }, function(affected)
        if cb then cb(affected and affected > 0) end
    end)
end
