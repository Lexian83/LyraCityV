-- resources/playerManager/server/playerManager.lua

LCV            = LCV or {}
LCV.Util       = LCV.Util or {}
LCV.DB         = LCV.DB or {}
LCV.Characters = LCV.Characters or {}

local json = json

local function log(level, msg)
    if LCV.Util and LCV.Util.log then
        LCV.Util.log(level, ('[PlayerManager] %s'):format(tostring(msg)))
    else
        print(('[PlayerManager][%s] %s'):format(level, tostring(msg)))
    end
end

-- Session: pro Quelle Account + aktiver Charakter
local Session    = {}
-- PlayerData: Cache mit vollständigen Daten & Appearance
local PlayerData = {}

-- ========== Helpers ==========

local function safeName(id)
    return GetPlayerName(id) or ('src:' .. tostring(id))
end

local function toNumberOr(val, default)
    local n = tonumber(val)
    if n == nil then return default end
    return n
end

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

    full.gender            = toNumberOr(full.gender, 0)
    full.dimension         = toNumberOr(full.dimension, 0)
    full.health            = toNumberOr(full.health, 200)
    full.thirst            = toNumberOr(full.thirst, 100)
    full.food              = toNumberOr(full.food, 100)
    full.residence_permit  = toNumberOr(full.residence_permit, 0)
    full.past              = toNumberOr(full.past, 0)

    full.pos_x             = toNumberOr(full.pos_x, 0.0)
    full.pos_y             = toNumberOr(full.pos_y, 0.0)
    full.pos_z             = toNumberOr(full.pos_z, 0.0)
    full.heading           = toNumberOr(full.heading, 0.0)

    full.appearance        = decodeJsonField(full.appearance, {})
    full.clothes           = decodeJsonField(full.clothes, {})

    return full
end

local function applyDefaultClothes(gender, clothes)
    clothes = clothes or {}
    -- Wir setzen NUR Defaults, wenn nichts oder Unsinn drin steht.
    -- So bleiben existierende Charaktere unverändert.

    local function isEmptyOrNil(v)
        return v == nil or v == -1
    end

    if gender == 1 then
        -- Männlicher Freemode
        if isEmptyOrNil(clothes.top) then
            clothes.top      = 11  -- simples Shirt
            clothes.topcolor = 0
        end
        if isEmptyOrNil(clothes.torso) then
            clothes.torso = 15
        end
        if isEmptyOrNil(clothes.pants) then
            clothes.pants      = 21
            clothes.pantsColor = 0
        end
        if isEmptyOrNil(clothes.shoes) then
            clothes.shoes      = 34
            clothes.shoesColor = 0
        end
        if isEmptyOrNil(clothes.undershirt) then
            clothes.undershirt      = 15
            clothes.undershirtColor = 0
        end
    else
        -- Weiblicher Freemode
        if isEmptyOrNil(clothes.top) then
            clothes.top      = 14
            clothes.topcolor = 0
        end
        if isEmptyOrNil(clothes.torso) then
            clothes.torso = 15
        end
        if isEmptyOrNil(clothes.pants) then
            clothes.pants      = 15
            clothes.pantsColor = 0
        end
        if isEmptyOrNil(clothes.shoes) then
            clothes.shoes      = 35
            clothes.shoesColor = 0
        end
        if isEmptyOrNil(clothes.undershirt) then
            clothes.undershirt      = 14
            clothes.undershirtColor = 0
        end
    end

    return clothes
end

local function buildSpawnData(full)
    full = sanitizeCharacter(full)
    if not full then return nil end

    local dim      = full.dimension or 0
    local permit   = full.residence_permit or 0
    local past     = full.past or 0

    local x, y, z, heading

    if permit >= 1 then
        x = full.pos_x
        y = full.pos_y
        z = full.pos_z
        heading = full.heading
    elseif permit == 0 and past == 0 then
        x, y, z, heading = -1111.24, -2843.37, 14.89, 267.78
    elseif permit == 0 and past == 1 then
        x, y, z, heading = 1690.70, 2606.72, 45.56, 281.05
    else
        x, y, z, heading = 0.0, 0.0, 0.0, 0.0
    end

    local g = full.gender
    if type(g) == "boolean" then g = g and 1 or 0 end
    g = toNumberOr(g, 0)

    local clothes    = full.clothes or {}
    local appearance = full.appearance or {}

    -- 👉 Hier: Defaults anwenden, wenn neu/leer
    clothes = applyDefaultClothes(g, clothes)

    return {
        id               = full.id,
        name             = full.name,
        gender           = g,
        health           = full.health,
        thirst           = full.thirst,
        food             = full.food,
        pos              = { x = x, y = y, z = z },
        heading          = heading,
        dimension        = dim,
        clothes          = clothes,
        appearances      = appearance,
        residence_permit = permit,
        past             = past,
    }
end

local function jenc(v)
    if not v then return nil end
    if type(v) == "string" then return v end
    if not json or not json.encode then return nil end
    local ok, res = pcall(json.encode, v)
    if ok then return res end
    return nil
end

-- ========== Session Binding ==========

local function bindAccount(src, accountId)
    src = tonumber(src)
    accountId = tonumber(accountId)
    if not (src and accountId) then return end

    Session[src] = Session[src] or {}
    Session[src].account_id = accountId

    log("DEBUG", ("Account gebunden: src=%s account_id=%s"):format(src, accountId))
end

exports('BindAccount', bindAccount)

local function clearSession(src)
    Session[src]    = nil
    PlayerData[src] = nil
end

AddEventHandler('playerDropped', function()
    local src = source
    clearSession(src)
end)

-- ========== Character Selection ==========

RegisterNetEvent('LCV:Player:SelectCharacter', function(a, b)
    local src, charId

    if b ~= nil then
        src    = tonumber(a)
        charId = tonumber(b)
    else
        src    = source
        charId = tonumber(a)
    end

    if not src or not charId then
        return
    end

    local s = Session[src]
    if not s or not s.account_id then
        return TriggerClientEvent('LCV:error', src, "Kein Account gebunden. Bitte neu verbinden.")
    end

    local accountId = s.account_id

    if not (LCV.Characters and LCV.Characters.selectOwned and LCV.Characters.getFull) then
        log("ERROR", "LCV.Characters.* nicht definiert. Prüfe SQL-Resource.")
        return
    end

    LCV.Characters.selectOwned(charId, accountId, function(row)
        if not row or not row.id then
            return TriggerClientEvent('LCV:error', src, "Ungültige Charakter-ID oder nicht dein Charakter.")
        end

        s.char_id = row.id

        LCV.Characters.getFull(row.id, accountId, function(full)
            if not full or not full.id then
                return TriggerClientEvent('LCV:error', src, "Charakterdaten nicht gefunden.")
            end

            local spawnData = buildSpawnData(full)
            if not spawnData then
                return TriggerClientEvent('LCV:error', src, "Fehler beim Vorbereiten der Spawn-Daten.")
            end

            local dim = tonumber(spawnData.dimension or 0) or 0
            if SetPlayerRoutingBucket then
                SetPlayerRoutingBucket(src, dim)
            end

            PlayerData[src] = {
                account_id  = accountId,
                char_id     = full.id,
                character   = full,
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
    end)
end)

-- ========== Character Create / Delete / Rename ==========

RegisterNetEvent('LCV:Player:CreateCharacter', function(data)
    local src = source
    local s = Session[src]
    if not s or not s.account_id then
        return TriggerClientEvent('LCV:error', src, "Kein Account gebunden.")
    end

    data = data or {}
    local name = tostring(data.name or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if #name < 3 or #name > 60 then
        return TriggerClientEvent('LCV:error', src, "Ungültiger Name.")
    end

    if not (LCV.Characters and LCV.Characters.create) then
        log("ERROR", "LCV.Characters.create nicht definiert.")
        return TriggerClientEvent('LCV:error', src, "Charaktererstellung nicht verfügbar.")
    end

    data.account_id = s.account_id

    LCV.Characters.create(s.account_id, data, function(newId)
        if not newId then
            return TriggerClientEvent('LCV:error', src, "Fehler beim Erstellen des Charakters.")
        end

        log("INFO", ("Charakter erstellt: account_id=%s char_id=%s name=%s")
            :format(s.account_id, newId, name))

        TriggerClientEvent('LCV:charCreated', src, { id = newId, name = name })
    end)
end)

RegisterNetEvent('LCV:Player:DeleteCharacter', function(charId)
    local src = source
    local s = Session[src]
    if not s or not s.account_id then
        return TriggerClientEvent('LCV:error', src, "Kein Account gebunden.")
    end

    charId = tonumber(charId)
    if not charId then return end

    if not (LCV.Characters and LCV.Characters.deleteOwned) then
        log("ERROR", "LCV.Characters.deleteOwned nicht definiert.")
        return TriggerClientEvent('LCV:error', src, "Charakter-Löschen nicht verfügbar.")
    end

    LCV.Characters.deleteOwned(charId, s.account_id, function(ok)
        if not ok then
            return TriggerClientEvent('LCV:error', src, "Charakter konnte nicht gelöscht werden.")
        end

        if Session[src] and Session[src].char_id == charId then
            Session[src].char_id = nil
            PlayerData[src] = nil
        end

        log("INFO", ("Charakter gelöscht: account_id=%s char_id=%s"):format(s.account_id, charId))
        TriggerClientEvent('LCV:charDeleted', src, charId)
    end)
end)

RegisterNetEvent('LCV:Player:RenameCharacter', function(charId, newName)
    local src = source
    local s = Session[src]
    if not s or not s.account_id then
        return TriggerClientEvent('LCV:error', src, "Kein Account gebunden.")
    end

    charId   = tonumber(charId)
    newName  = tostring(newName or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if not charId or #newName < 3 or #newName > 60 then
        return TriggerClientEvent('LCV:error', src, "Ungültige Eingabe.")
    end

    if not (LCV.Characters and LCV.Characters.renameOwned) then
        log("ERROR", "LCV.Characters.renameOwned nicht definiert.")
        return TriggerClientEvent('LCV:error', src, "Charakter-Umbenennung nicht verfügbar.")
    end

    LCV.Characters.renameOwned(charId, s.account_id, newName, function(ok)
        if not ok then
            return TriggerClientEvent('LCV:error', src, "Charakter konnte nicht umbenannt werden.")
        end

        if PlayerData[src] and PlayerData[src].char_id == charId and PlayerData[src].character then
            PlayerData[src].character.name = newName
        end

        log("INFO", ("Charakter umbenannt: account_id=%s char_id=%s name=%s")
            :format(s.account_id, charId, newName))

        TriggerClientEvent('LCV:charRenamed', src, { id = charId, name = newName })
    end)
end)

-- ========== State Sync / Autosave ==========

RegisterNetEvent('LCV:Player:SyncState', function(state)
    local src = source
    local s = Session[src]
    if not s or not s.account_id or not s.char_id then
        return
    end

    state = state or {}

    local pd = PlayerData[src] or {}
    pd.account_id = s.account_id
    pd.char_id    = s.char_id
    pd.updatedAt  = os.time()
    pd.character  = pd.character or {}

    if state.pos then
        pd.character.pos_x = tonumber(state.pos.x) or pd.character.pos_x or 0.0
        pd.character.pos_y = tonumber(state.pos.y) or pd.character.pos_y or 0.0
        pd.character.pos_z = tonumber(state.pos.z) or pd.character.pos_z or 0.0
    end

    if state.heading then
        pd.character.heading = tonumber(state.heading) or pd.character.heading or 0.0
    end

    if state.dimension then
        pd.character.dimension = tonumber(state.dimension) or pd.character.dimension or 0
    end

    if state.health then
        pd.character.health = tonumber(state.health) or pd.character.health or 200
    end

    if state.thirst then
        pd.character.thirst = tonumber(state.thirst) or pd.character.thirst or 100
    end

    if state.food then
        pd.character.food = tonumber(state.food) or pd.character.food or 100
    end

    if state.appearance then
        pd.appearances = state.appearance
    end

    if state.clothes then
        pd.clothes = state.clothes
    end

    PlayerData[src] = pd

    if LCV.Characters and LCV.Characters.updateState then
        LCV.Characters.updateState(s.char_id, s.account_id, state, function(ok)
            if not ok then
                log("WARN", ("StateSync DB-Update fehlgeschlagen für src=%s char_id=%s"):format(src, s.char_id))
            end
        end)
    end
end)

-- ========== Legacy PushData (Kompat) ==========

AddEventHandler('Manager:Player:PushData', function(data)
    data = data or {}
    local src = tonumber(data.pedID or data.playerId or data.src)
    if not src then return end

    local clothes   = data.clothes or {}
    local character = sanitizeCharacter(data.character)

    PlayerData[src] = {
        clothes    = clothes,
        character  = character,
        updatedAt  = os.time(),
    }

    log("DEBUG", ("[Compat] PushData für %s (%s) übernommen."):format(safeName(src), src))
end)

-- ========== Exports ==========

exports('GetSession', function(src)
    src = tonumber(src)
    return Session[src]
end)

exports('GetAccountId', function(src)
    src = tonumber(src)
    return Session[src] and Session[src].account_id or nil
end)

exports('GetActiveCharacterId', function(src)
    src = tonumber(src)
    return Session[src] and Session[src].char_id or nil
end)

exports('GetPlayerData', function(src)
    src = tonumber(src)
    return PlayerData[src]
end)

exports('CreateCharacter', function(accountId, data, cb)
    if not (LCV.Characters and LCV.Characters.create) then
        if cb then cb(nil) end
        return
    end
    LCV.Characters.create(accountId, data, cb)
end)

exports('DeleteCharacter', function(accountId, charId, cb)
    if not (LCV.Characters and LCV.Characters.deleteOwned) then
        if cb then cb(false) end
        return
    end
    LCV.Characters.deleteOwned(charId, accountId, cb)
end)

exports('RenameCharacter', function(accountId, charId, newName, cb)
    if not (LCV.Characters and LCV.Characters.renameOwned) then
        if cb then cb(false) end
        return
    end
    LCV.Characters.renameOwned(charId, accountId, newName, cb)
end)
