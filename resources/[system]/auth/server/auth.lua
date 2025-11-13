-- resources/auth/server/auth.lua
-- ==========================================
-- LyraCityV - Auth Gateway (manager-only, no SQL)
--  - prüft Discord / Rollen
--  - stellt sicher, dass ein Account existiert
--  - bindet Account an Session im playerManager
--  - triggert Charselect / Characterwahl-Flow
-- ==========================================

local U = LCV.Util
local log = (LCV.Util and LCV.Util.log) or function(level, msg)
    print(('[AUTH][%s] %s'):format(level, tostring(msg)))
end

-- ===== Manager-Locator (robust für Ordnernamen) =====
local function PM()
    if GetResourceState('playerManager') == 'started' then return exports['playerManager'] end
    if GetResourceState('lcv-playermanager') == 'started' then return exports['lcv-playermanager'] end
    return nil
end

local function AM()
    if GetResourceState('accountManager') == 'started' then return exports['accountManager'] end
    if GetResourceState('lcv-accountmanager') == 'started' then return exports['lcv-accountmanager'] end
    return nil
end

-- ===== Helpers =====

local function getRequiredConvars()
    local token         = U.getConvarOrFail("LCV_discord_token")
    local guildId       = U.getConvarOrFail("LCV_guild_id")
    local blockedRoleId = U.getConvarOrFail("LCV_blocked_role_id")
    return token, guildId, blockedRoleId
end

local function ensureAccount(discord, steam, hwid, now, cb)
    local accm = AM()
    if not accm or not accm.EnsureAccountByDiscord then
        log("ERROR", "accountManager nicht verfügbar (EnsureAccountByDiscord).")
        if cb then cb(nil) end
        return
    end
    local ok, err = pcall(function()
        accm:EnsureAccountByDiscord(discord, steam, hwid, now, cb)
    end)
    if not ok then
        log("ERROR", "EnsureAccountByDiscord Export-Fehler: " .. tostring(err))
        if cb then cb(nil) end
    end
end

local function getAccountByDiscord(discord, cb)
    local accm = AM()
    if not accm or not accm.GetAccountByDiscord then
        log("ERROR", "accountManager nicht verfügbar (GetAccountByDiscord).")
        if cb then cb(nil) end
        return
    end
    local ok, err = pcall(function()
        accm:GetAccountByDiscord(discord, cb)
    end)
    if not ok then
        log("ERROR", "GetAccountByDiscord Export-Fehler: " .. tostring(err))
        if cb then cb(nil) end
    end
end

local function bindAccountToSession(src, accountId)
    local pm = PM()
    if not pm or not pm.BindAccount then
        log("ERROR", "playerManager nicht verfügbar (BindAccount).")
        return
    end
    local ok, err = pcall(function()
        pm:BindAccount(src, accountId)
    end)
    if not ok then
        log("ERROR", "BindAccount Export-Fehler: " .. tostring(err))
    end
end

-- ===== playerConnecting =====

AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
    local src = source
    deferrals.defer()
    U.step(deferrals, "initialisiere Verbindungsprüfung ...")

    -- Convars prüfen
    local token, guildId, blockedRoleId
    local ok, err = pcall(function()
        token, guildId, blockedRoleId = getRequiredConvars()
    end)
    if not ok then
        log("ERROR", ("Config Error: %s"):format(err))
        return U.fail(deferrals, "Serverkonfiguration unvollständig. Bitte später erneut versuchen.")
    end

    local ids     = GetPlayerIdentifiers(src)
    local discord = U.extractIdentifier(ids, "discord")
    local steam   = U.extractIdentifier(ids, "steam")
    local tokenHw = GetPlayerToken(src, 0) or nil

    if not discord then
        U.step(deferrals, "Discord nicht erkannt")
        return U.fail(deferrals, "Discord nicht erkannt. Bitte Discord & FiveM neu starten und Accounts verknüpfen.")
    end

    -- Cache prüfen (gebannte Rolle)
    local cached = LCV.getCachedRoles(discord)
    if cached then
        for _, r in ipairs(cached) do
            if r == blockedRoleId then
                return U.fail(deferrals, "Zugang verweigert: Dein Discord-Rang ist 'Ausgebürgert'.")
            end
        end

        local now = os.date('%Y-%m-%d %H:%M:%S')
        ensureAccount(discord, steam, tokenHw, now, function(acc)
            if not acc or not acc.id then
                return U.fail(deferrals, "Konto konnte nicht erstellt/gefunden werden.")
            end
            U.finish(deferrals, "Prüfungen abgeschlossen. Willkommen zurück!")
        end)
        return
    end

    -- Kein Cache → Discord API Abfrage
    U.step(deferrals, "prüfe deinen Discord-Status ...")

    local url = ("https://discord.com/api/v10/guilds/%s/members/%s"):format(guildId, discord)
    U.httpRequest("GET", url, { ["Authorization"] = ("Bot %s"):format(token) }, nil, function(status, body)
        if status ~= 200 then
            log("ERROR", ("Discord API Fehler: status=%s body=%s"):format(tostring(status), tostring(body)))
            local msg
            if status == 401 or status == 403 then
                msg = "Discord-Token/Berechtigung fehlerhaft. Bitte Bot-Token und Bot-Einladung prüfen."
            elseif status == 404 then
                msg = "Nicht auf unserem Discord-Server gefunden. Bitte Server beitreten und erneut verbinden."
            elseif status == 429 then
                msg = "Discord-Rate-Limit erreicht. Bitte kurz versuchen."
            else
                msg = ("Unerwarteter Discord-Fehler (%s). Bitte später erneut versuchen."):format(tostring(status))
            end
            return U.fail(deferrals, msg)
        end

        local member = U.tryJson(body)
        if not member then
            return U.fail(deferrals, "Ungültige Antwort von Discord. Bitte später erneut versuchen.")
        end

        local roles = member.roles or {}
        LCV.setCachedRoles(discord, roles)

        for _, r in ipairs(roles) do
            if r == blockedRoleId then
                return U.fail(deferrals, "Zugang verweigert: Dein Discord-Rang ist 'Ausgebürgert'.")
            end
        end

        local now = os.date('%Y-%m-%d %H:%M:%S')
        ensureAccount(discord, steam, tokenHw, now, function(acc)
            if not acc or not acc.id then
                return U.fail(deferrals, "Konto konnte nicht erstellt/gefunden werden.")
            end
            U.finish(deferrals, "Prüfungen abgeschlossen. Willkommen auf LyraCityV!")
        end)
    end)
end)

-- ===== playerJoining: Account → playerManager =====

AddEventHandler('playerJoining', function()
    local src = source
    local ids = GetPlayerIdentifiers(src)
    local discord = LCV.Util.extractIdentifier(ids, "discord")
    if not discord then return end

    getAccountByDiscord(discord, function(acc)
        if not acc or not acc.id then
            log("WARN", ("playerJoining ohne Account? discord=%s"):format(tostring(discord)))
            return
        end
        bindAccountToSession(src, acc.id)
    end)
end)

-- ===== Nach erstem Spawn: Charselect öffnen =====

RegisterNetEvent('LCV:playerSpawned', function()
    local src = source
    local pm = PM()
    if not pm or not pm.GetAccountId then return end
    local ok, accountId = pcall(function() return pm:GetAccountId(src) end)
    if not ok or not accountId then return end

    TriggerEvent('LCV:charselect:load', src, accountId)
end)

-- ===== Bridge: alte Charselect-Events → playerManager =====

RegisterNetEvent('LCV:selectCharacterX', function(charId)
    local src = source
    charId = tonumber(charId)
    if not charId then return end
    -- Wir rufen das Server-Event im playerManager mit (src, charId) auf:
    TriggerEvent('LCV:Player:SelectCharacter', src, charId)
end)
