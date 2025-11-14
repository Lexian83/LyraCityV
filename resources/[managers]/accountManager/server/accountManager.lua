-- resources/accountManager/server/accountManager.lua
-- LyraCityV - Account Manager (pure oxmysql)
-- Schema: accounts(id, discord_id, steam_id, hwid, last_login, new, ...)

local log = function(level, msg)
    print(('[AccountManager][%s] %s'):format(level, tostring(msg)))
end

if not MySQL then
    log('ERROR', '@oxmysql nicht geladen – prüfe fxmanifest und Startreihenfolge!')
end

-- ============== DB Helpers ==============

local function getByDiscord(discordId)
    if not discordId then return nil end
    return MySQL.single.await('SELECT * FROM accounts WHERE discord_id = ?', { tostring(discordId) })
end

local function getById(accountId)
    accountId = tonumber(accountId)
    if not accountId then return nil end
    return MySQL.single.await('SELECT * FROM accounts WHERE id = ?', { accountId })
end

local function insertAccount(steamId, discordId, hwid, now)
    return MySQL.insert.await(
        'INSERT INTO accounts (steam_id, discord_id, hwid, last_login) VALUES (?, ?, ?, ?)',
        { steamId or nil, tostring(discordId) or nil, hwid or nil, now }
    )
end

local function updateLastLogin(accountId, now)
    accountId = tonumber(accountId)
    if not accountId then return 0 end
    return MySQL.update.await('UPDATE accounts SET last_login = ? WHERE id = ?', { now, accountId })
end

local function isAccountNewInternal(accountId)
    accountId = tonumber(accountId)
    if not accountId then return false end

    local row = MySQL.single.await('SELECT new FROM accounts WHERE id = ?', { accountId })
    if not row or row.new == nil then
        return false
    end

    local v = row.new
    if type(v) == 'boolean' then
        return v
    end

    local n = tonumber(v) or 0
    return n == 1
end

-- ============== Core Logic ==============

local function ensureByDiscord(discordId, steamId, hwid, now, cb)
    CreateThread(function()
        if not discordId then
            if cb then cb(nil) end
            return
        end

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

-- Asynchron per Callback (wie bisher genutzt)
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
    local ok = updateLastLogin(accountId, now)
    if cb then cb(ok and ok > 0) end
end)

-- Neu: direkter Sync-Export für serverseitige Logik (z.B. CharSelect)
exports('IsAccountNew', function(accountId)
    return isAccountNewInternal(accountId)
end)

-- Optional: Account via ID holen (falls später gebraucht)
exports('GetAccountById', function(accountId, cb)
    CreateThread(function()
        local acc = getById(accountId)
        if cb then cb(acc) end
    end)
end)

log('INFO', 'AccountManager (oxmysql) geladen.')
