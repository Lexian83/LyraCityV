-- ==========================================
-- LyraCityV - Characters (Funktionen)
-- ==========================================
local DB = LCV.DB
LCV.Characters = LCV.Characters or {}

-- Alte SQLs mit JSON_* raus. Neue, simple SELECT:
local SQL_LIST_BY_ACCOUNT = [[
  SELECT id, name, gender, health, pos_x, pos_y, pos_z
  FROM characters
  WHERE account_id = ?
  ORDER BY id ASC
]]

local SQL_INSERT_CHARACTER = [[
  INSERT INTO characters (
    account_id, name, gender,
    pos_x, pos_y, pos_z,
    health, thirst, food,
    created_at
  ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
]]


-- Vollständigen Charakter (inkl. Position/Heading/Dimension/HP) laden
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


function LCV.Characters.getFull(charId, accountId, cb)
    LCV.DB.single(SQL_SELECT_FULL, { charId, accountId }, function(row)
        cb(row) -- row kann nil sein
    end)
end

local SQL_SELECT_OWNED = "SELECT id, name FROM characters WHERE id = ? AND account_id = ? LIMIT 1"

function LCV.Characters.listByAccount(accountId, cb)
    LCV.DB.query(SQL_LIST_BY_ACCOUNT, { accountId }, function(rows)
        -- rows ist bereits ein Lua-Array von Zeilen; wir geben es direkt weiter
        cb(rows or {})
    end)
end

function LCV.Characters.create(accountId, name, gender, cb)
    local now = os.date('%Y-%m-%d %H:%M:%S')
    local spawn = { x = -1037.5, y = -2737.8, z = 20.2 }
    LCV.DB.insert(SQL_INSERT_CHARACTER, {
    accountId, name, gender or 1,
    spawn.x, spawn.y, spawn.z,
    100, 100, 100,
    now
}, function(newId) cb(newId) end)
end

function LCV.Characters.selectOwned(charId, accountId, cb)
    LCV.DB.single(SQL_SELECT_OWNED, { charId, accountId }, function(row) cb(row) end)
end
