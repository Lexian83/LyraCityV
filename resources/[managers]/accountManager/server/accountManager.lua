-- resources/accountManager/server/accountManager.lua

LCV          = LCV or {}
LCV.Util     = LCV.Util or {}
LCV.Accounts = LCV.Accounts or {}

local function log(level, msg)
    if LCV.Util and LCV.Util.log then
        LCV.Util.log(level, ('[AccountManager] %s'):format(tostring(msg)))
    else
        print(('[AccountManager][%s] %s'):format(level, tostring(msg)))
    end
end

if not LCV.Accounts or not LCV.Accounts.getByDiscord then
    log("ERROR", "LCV.Accounts ist nicht verfügbar. Stelle sicher, dass das SQL-Resource korrekt geladen wird.")
end

LCV.AccountManager = LCV.AccountManager or {}
local AM = LCV.AccountManager

function AM.ensureByDiscord(discordId, steamId, hwid, now, cb)
    if not (discordId and LCV.Accounts and LCV.Accounts.getByDiscord) then
        if cb then cb(nil) end
        return
    end

    LCV.Accounts.getByDiscord(discordId, function(acc)
        if acc and acc.id then
            if LCV.Accounts.updateLastLogin then
                LCV.Accounts.updateLastLogin(acc.id, now, function()
                    if cb then cb(acc) end
                end)
            else
                if cb then cb(acc) end
            end
        else
            if not LCV.Accounts.insert then
                log("ERROR", "LCV.Accounts.insert nicht definiert.")
                if cb then cb(nil) end
                return
            end

            LCV.Accounts.insert(steamId, discordId, hwid, now, function()
                LCV.Accounts.getByDiscord(discordId, function(newAcc)
                    if cb then cb(newAcc) end
                end)
            end)
        end
    end)
end

function AM.getByDiscord(discordId, cb)
    if not (discordId and LCV.Accounts and LCV.Accounts.getByDiscord) then
        if cb then cb(nil) end
        return
    end
    return LCV.Accounts.getByDiscord(discordId, cb)
end

function AM.updateLastLogin(accountId, now, cb)
    if not (accountId and LCV.Accounts and LCV.Accounts.updateLastLogin) then
        if cb then cb(false) end
        return
    end
    return LCV.Accounts.updateLastLogin(accountId, now, function()
        if cb then cb(true) end
    end)
end

-- ===== Exports =====

exports('EnsureAccountByDiscord', function(discordId, steamId, hwid, now, cb)
    AM.ensureByDiscord(discordId, steamId, hwid, now, cb)
end)

exports('GetAccountByDiscord', function(discordId, cb)
    AM.getByDiscord(discordId, cb)
end)

exports('UpdateLastLogin', function(accountId, now, cb)
    AM.updateLastLogin(accountId, now, cb)
end)
