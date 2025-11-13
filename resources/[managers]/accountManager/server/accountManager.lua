-- resources/accountManager/server/accountManager.lua
-- LyraCityV - Account Manager (pure oxmysql)  •  Schema: accounts(discord_id, steam_id, hwid, last_login, ...)
local log = function(level, msg)
  print(('[AccountManager][%s] %s'):format(level, tostring(msg)))
end

if not MySQL then
  log('ERROR', '@oxmysql nicht geladen – prüfe fxmanifest und Startreihenfolge!')
end

-- ============== DB Helpers (Schema-konform: discord_id / steam_id) ==============
local function getByDiscord(discordId)
  if not discordId then return nil end
  return MySQL.single.await('SELECT * FROM accounts WHERE discord_id = ?', { tostring(discordId) })
end

local function insertAccount(steamId, discordId, hwid, now)
  return MySQL.insert.await(
    'INSERT INTO accounts (steam_id, discord_id, hwid, last_login) VALUES (?, ?, ?, ?)',
    { steamId or nil, tostring(discordId) or nil, hwid or nil, now }
  )
end

local function updateLastLogin(accountId, now)
  return MySQL.update.await('UPDATE accounts SET last_login = ? WHERE id = ?', { now, accountId })
end

-- ============== Core Logic ==============
local function ensureByDiscord(discordId, steamId, hwid, now, cb)
  CreateThread(function()
    if not discordId then if cb then cb(nil) end return end

    local acc = getByDiscord(discordId)
    if acc and acc.id then
      updateLastLogin(acc.id, now)
      if cb then cb(acc) end
      return
    end

    local newId = insertAccount(steamId, discordId, hwid, now)
    if not newId or newId == 0 then
      log('ERROR', 'INSERT accounts fehlgeschlagen (ensureByDiscord)')
      if cb then cb(nil) end
      return
    end

    local newAcc = getByDiscord(discordId)
    if cb then cb(newAcc) end
  end)
end

-- ============== Exports ==============
exports('EnsureAccountByDiscord', function(discordId, steamId, hwid, now, cb)
  ensureByDiscord(discordId, steamId, hwid, now, cb)
end)

exports('GetAccountByDiscord', function(discordId, cb)
  CreateThread(function()
    local acc = getByDiscord(discordId)
    if cb then cb(acc) end
  end)
end)

exports('UpdateLastLogin', function(accountId, now, cb)
  local ok = updateLastLogin(tonumber(accountId), now)
  if cb then cb(ok and ok > 0) end
end)

log('INFO', 'AccountManager (oxmysql, schema: discord_id/steam_id) geladen.')
