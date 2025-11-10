-- ==========================================
-- LyraCityV - Accounts (Funktionen)
-- ==========================================
local log, DB = LCV.Util.log, LCV.DB

LCV.Accounts = LCV.Accounts or {}

-- SQL (inline, ohne externe Dateien)
local SQL_SELECT_BY_DISCORD   = "SELECT id, `new` FROM accounts WHERE discord_id = ? LIMIT 1"
local SQL_INSERT_ACCOUNT      = [[
    INSERT INTO accounts (steam_id, discord_id, hwid, registered_at, last_login)
    VALUES (?, ?, ?, ?, ?)
]]
local SQL_UPDATE_LAST_LOGIN   = "UPDATE accounts SET last_login = ? WHERE id = ?"
local SQL_MARK_NOT_NEW        = "UPDATE accounts SET `new` = 0 WHERE id = ?"

function LCV.Accounts.getByDiscord(discordId, cb)
    DB.single(SQL_SELECT_BY_DISCORD, { discordId }, function(row) cb(row) end)
end

function LCV.Accounts.insert(steam, discord, hwid, now, cb)
    DB.insert(SQL_INSERT_ACCOUNT, { steam, discord, hwid, now, now }, function(newId)
        cb(newId)
    end)
end

function LCV.Accounts.updateLastLogin(id, now, cb)
    DB.update(SQL_UPDATE_LAST_LOGIN, { now, id }, function(affected) cb(affected) end)
end

function LCV.Accounts.markNotNew(id, cb)
    DB.update(SQL_MARK_NOT_NEW, { id }, function(affected) cb(affected) end)
end
