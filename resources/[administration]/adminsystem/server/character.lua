-- adminsystem/server/character.lua
-- Ab jetzt: KEINE SQL mehr hier. Alles läuft über Exports vom playerManager.

local function getPM()
    -- Bevorzugt 'playerManager' (so heißt deine Resource laut Manifest),
    -- fallback auf 'lcv-playermanager', falls du den Ordner so benennst.
    if GetResourceState('playerManager') == 'started' then
        return exports['playerManager']
    end
    if GetResourceState('lcv-playermanager') == 'started' then
        return exports['lcv-playermanager']
    end
    return nil
end

local function getCharLVL(src)
    local pm = getPM()
    if not pm or not pm.GetPlayerData then return 0 end
    local ok, d = pcall(function() return pm:GetPlayerData(src) end)
    if not ok or not d or not d.character then return 0 end
    return tonumber(d.character.level) or 0
end

local function hasAdminPermission(src, required)
    local lvl = getCharLVL(src)
    required = tonumber(required) or 10
    return lvl >= required
end

-- ================== LIST ==================
lib.callback.register('LCV:ADMIN:Characters:GetAll', function(source, payload)
    if not hasAdminPermission(source, 10) then
        return { ok = false, error = 'Keine Berechtigung', characters = {} }
    end
    local pm = getPM()
    if not pm or not pm.ListCharacters then
        return { ok = false, error = 'playerManager not started', characters = {} }
    end
    local limit = payload and tonumber(payload.limit) or 500
    local res = pm:ListCharacters(limit)
    return res or { ok=false, error='unknown', characters={} }
end)

-- ================== UPDATE FLAGS ==================
-- Erwartet: data = { id=number, is_locked=bool, residence_permit=bool }
lib.callback.register('LCV:ADMIN:Characters:Update', function(source, data)
    if not hasAdminPermission(source, 10) then
        return { ok = false, error = 'Keine Berechtigung' }
    end
    local pm = getPM()
    if not pm or not pm.UpdateCharacterFlags then
        return { ok = false, error = 'playerManager not started' }
    end
    local res = pm:UpdateCharacterFlags(data or {})
    return res or { ok=false, error='unknown' }
end)

-- ================== DELETE BY ID ==================
lib.callback.register('LCV:ADMIN:Characters:Delete', function(source, data)
    if not hasAdminPermission(source, 10) then
        return { ok = false, error = 'Keine Berechtigung' }
    end
    local pm = getPM()
    if not pm or not pm.DeleteCharacterById then
        return { ok = false, error = 'playerManager not started' }
    end
    local id = tonumber(data and data.id)
    if not id then return { ok=false, error='Ungültige ID' } end
    local res = pm:DeleteCharacterById(id)
    return res or { ok=false, error='unknown' }
end)

-- ================== INFO: aktiver Spielerchar ==================
lib.callback.register('LCV:ADMIN:GetPlayerCharacter', function(_, targetId)
    targetId = tonumber(targetId)
    if not targetId then return nil end
    local pm = getPM()
    if not pm or not pm.GetPlayerData then return nil end
    local ok, data = pcall(function() return pm:GetPlayerData(targetId) end)
    if not ok or not data or not data.character then return nil end
    local char = data.character
    return { id = char.id or targetId, name = char.name or '' }
end)
