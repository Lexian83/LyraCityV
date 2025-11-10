-- players/server/player.lua

local PlayerData = PlayerData or {}

local function safeName(id)
    return GetPlayerName(id) or ('src:' .. tostring(id))
end

local function sanitizeCharacter(full)
    if not full then return {} end
    -- Beispiel: JSON-Felder robust decoden (falls Strings)
    full.clothes    = type(full.clothes)    == 'string' and (json.decode(full.clothes)    or {}) or (full.clothes or {})
    full.appearance = type(full.appearance) == 'string' and (json.decode(full.appearance) or {}) or (full.appearance or {})
    -- Zahlfelder absichern (nur Beispiele)
    full.gender = tonumber(full.gender) or 0
    return full
end

-- WICHTIG: AddEventHandler reicht für server->server (RegisterNetEvent ist für netzwerk-Events)
AddEventHandler('Manager:Player:PushData', function(data)
    data = data or {}
    -- NIMM DIE ID AUS DEM PAYLOAD, NICHT 'source'
    local src = tonumber(data.pedID or data.playerId or data.src)
    if not src then
        -- print('[PlayerManager][PUSH][WARN] Kein playerId im Payload')
        return
    end

    local clothes   = data.clothes or {}
    local character = sanitizeCharacter(data.character)

    PlayerData[src] = {
        clothes   = clothes,
        character = character,
        updatedAt = os.time()
    }

    print(('[PlayerManager][PUSH] %s (%s) gespeichert'):format(safeName(src), src))
end)

-- Beim Drop aufräumen – ohne tief zu indexen
AddEventHandler('playerDropped', function(reason)
    local src = source
    -- print(('[PlayerManager][Drop] %s (%s) removed | reason: %s'):format(safeName(src), src, tostring(reason or 'unknown')))
    PlayerData[src] = nil
end)

-- Optionaler Getter
exports('GetPlayerData', function(src)
    return PlayerData[tonumber(src or -1)]
end)
