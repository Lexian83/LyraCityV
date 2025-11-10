-- ==========================================
-- LyraCityV - Auth & Commands (nutzt LCV.Accounts/Characters)
-- ==========================================
local U, log = LCV.Util, LCV.Util.log

-- ==== Session-State ====
local Active = {}
local function setActiveAccount(src, accountId)
    Active[src] = Active[src] or {}
    Active[src].account_id = accountId
end
local function setActiveCharacter(src, charId)
    Active[src] = Active[src] or {}
    Active[src].char_id = charId
end
AddEventHandler('playerDropped', function() Active[source] = nil end)

-- ==== Player Connecting (Discord, Cache, DB-Write) ====
AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
    local src = source
    deferrals.defer()
    U.step(deferrals, "initialisiere Verbindungsprüfung ...")

    local token, guildId, blockedRoleId
    local ok, err = pcall(function()
        token = U.getConvarOrFail("LCV_discord_token")
        guildId = U.getConvarOrFail("LCV_guild_id")
        blockedRoleId = U.getConvarOrFail("LCV_blocked_role_id")
    end)
    if not ok then
        print("ERROR", ("Config Error: %s"):format(err))
        return U.fail(deferrals, "Serverkonfiguration unvollständig. Bitte später erneut versuchen.")
    end

    local ids = GetPlayerIdentifiers(src)
    local discord = U.extractIdentifier(ids, "discord")
    local steam   = U.extractIdentifier(ids, "steam")
    local tokenHw = GetPlayerToken(src, 0) or nil

    -- print("INFO", ("Connect: %s | discord=%s | steam=%s | token=%s"):format(name, tostring(discord), tostring(steam), tostring(tokenHw)))

    if not discord then
        U.step(deferrals, "Discord nicht erkannt")
        return U.fail(deferrals, "Discord nicht erkannt. Bitte Discord & FiveM neu starten und Accounts verknüpfen.")
    end

    -- Cache?
    local cached = LCV.getCachedRoles(discord)
    if cached then
        -- print("INFO", ("Discord roles aus Cache (%d Sek. TTL): %s"):format(LCV.DISCORD_CACHE_TTL, json.encode(cached)))
        for _, r in ipairs(cached) do
            if r == blockedRoleId then
                return U.fail(deferrals, "Zugang verweigert: Dein Discord-Rang ist 'Ausgebürgert'.")
            end
        end
        -- DB-Write
        local now = os.date('%Y-%m-%d %H:%M:%S')
        LCV.Accounts.getByDiscord(discord, function(acc)
            if acc and acc.id then
                LCV.Accounts.updateLastLogin(acc.id, now, function()
                    U.finish(deferrals, "Prüfungen abgeschlossen. Willkommen zurück!")
                end)
            else
                LCV.Accounts.insert(steam, discord, tokenHw, now, function()
                    U.finish(deferrals, "Konto erstellt. Viel Spaß auf LyraCityV!")
                end)
            end
        end)
        return
    end

    -- Discord API
    U.step(deferrals, "prüfe deinen Discord-Status ...")
    local url = ("https://discord.com/api/v10/guilds/%s/members/%s"):format(guildId, discord)
    U.httpRequest("GET", url, { ["Authorization"] = ("Bot %s"):format(token) }, nil, function(status, body)
        if status ~= 200 then
            print("ERROR", ("Discord API Fehler: status=%s body=%s"):format(tostring(status), tostring(body)))
            local msg
            if status == 401 or status == 403 then
                msg = "Discord-Token/Berechtigung fehlerhaft. Bitte Bot-Token und Bot-Einladung prüfen."
            elseif status == 404 then
                msg = "Nicht auf unserem Discord-Server gefunden. Bitte Server beitreten und erneut verbinden."
            elseif status == 429 then
                msg = "Discord-Rate-Limit erreicht. Bitte kurz warten und erneut versuchen."
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

        -- DB-Write
        local now = os.date('%Y-%m-%d %H:%M:%S')
        LCV.Accounts.getByDiscord(discord, function(acc)
            if acc and acc.id then
                LCV.Accounts.updateLastLogin(acc.id, now, function()
                    U.finish(deferrals, "Prüfungen abgeschlossen. Willkommen zurück!")
                end)
            else
                LCV.Accounts.insert(steam, discord, tokenHw, now, function()
                    U.finish(deferrals, "Konto erstellt. Viel Spaß auf LyraCityV!")
                end)
            end
        end)
    end)
end)

-- Nach Verbindungsaufbau: Account binden & Onboarding-Text
AddEventHandler('playerJoining', function()
    local src = source
    local ids = GetPlayerIdentifiers(src)
    local discord = LCV.Util.extractIdentifier(ids, "discord")
    if not discord then return end

    LCV.Accounts.getByDiscord(discord, function(acc)
        if not acc or not acc.id then
            print("WARN", ("playerJoining ohne Account? discord=%s"):format(tostring(discord)))
            return
        end
        setActiveAccount(src, acc.id)
    end)
end)


RegisterNetEvent('LCV:playerSpawned', function()
        local src = source
        local S = Active[src]
        if not S or not S.account_id then return end
        TriggerEvent('LCV:charselect:load', src, S.account_id)
        -- print('CHARSELECT:','Char Selector Open for ID', S.account_id )
end)


-- ==========================================================
-- LyraCityV - Character Events (statt Chatcommands)
-- ==========================================================



-- Client wählt Charakter
RegisterNetEvent('LCV:selectCharacterX', function(charId)
    local src = source
    local S = Active[src]
    if not S or not S.account_id or not charId then return end

    LCV.Characters.selectOwned(charId, S.account_id, function(row)
        if not row or not row.id then
            return TriggerClientEvent('LCV:error', src, "Ungültige Charakter-ID.")
        end

        -- Char als aktiv markieren
        setActiveCharacter(src, row.id)

        -- Vollständigen Datensatz laden (Position etc.)
        LCV.Characters.getFull(row.id, S.account_id, function(full)
            if not full then
                return TriggerClientEvent('LCV:error', src, "Charakterdaten nicht gefunden.")
            end

            -- Optional: Routing Bucket/Dimension auf Server setzen
            local dim = tonumber(full.dimension or 0) or 0
            if SetPlayerRoutingBucket then
                SetPlayerRoutingBucket(src, dim)
            end

            local g = full.gender
            if type(g) == 'boolean' then g = g and 1 or 0 end
            g = tonumber(g) or 0  -- 0 = weiblich, 1 = männlich



-- JSON robust decoden
local clothes     = type(full.clothes)     == 'string' and (json.decode(full.clothes)     or {}) or (full.clothes     or {})
local appearances = type(full.appearance)  == 'string' and (json.decode(full.appearance)  or {}) or (full.appearance  or {})

-- Zahlen hart absichern
local permit = tonumber(full.residence_permit) or 0
local past   = tonumber(full.past)             or 0
local thirst = tonumber(full.thirst)           or 100
local food   = tonumber(full.food)             or 100
local health = tonumber(full.health)           or 200


            -- Spawn-Daten an den Client schicken
            TriggerClientEvent('LCV:spawn', src, {
  id        = full.id,
  name      = full.name,
  gender    = g,
  health    = health,
  thirst    = thirst,
  food      = food,
  pos       = { x = full.pos_x, y = full.pos_y, z = full.pos_z },
  heading   = full.heading or 0.0,
  dimension = dim,
  clothes   = clothes,
  appearances = appearances,
  residence_permit = permit,
  past = past,
})
           -- print('auth.lua : Permit :',full.residence_permit)
           -- print('[LCV][charui] Trigger Spawn event:' ,full.id,charId)
             -- Essen und Trinken level setze im Inventar
            TriggerClientEvent('LCV:ui:setStomach',src, full.thirst, full.food)
            -- UI sauber schließen (falls noch offen)
            TriggerClientEvent('LCV:characterSelected', src, { id = full.id, name = full.name })

            TriggerEvent('Manager:Player:PushData',{
                playerId = src,
                clothes = clothes,
                character = full,
            })
            
        end)
    end)
end)


