-- adminsystem/server/interaction.lua
-- Keine SQL mehr hier – nur Proxy zum Interaction-Manager.

local function getCharLVL(src)
    local ok, d = pcall(function()
        return exports['playerManager'] and exports['playerManager']:GetPlayerData(src) or nil
    end)
    if not ok or not d or not d.character then return 0 end
    return tonumber(d.character.level) or 0
end

local function hasAdminPermission(src, required)
    local lvl = getCharLVL(src)
    required = tonumber(required) or 10
    return lvl >= required
end

local function IM()
    return exports['interactionmanager']
end

-- ===== READ
lib.callback.register('LCV:ADMIN:Interactions:GetAll', function(source)
    if not hasAdminPermission(source, 10) then
        return { ok = false, error = 'Keine Berechtigung', interactions = {} }
    end
    local rows = IM():GetAll() or {}
    -- enabled/short booleans hübsch machen
    for _, r in ipairs(rows) do
        r.enabled = (r.enabled == 1 or r.enabled == true)
        if type(r.data) == 'string' and r.data ~= '' then
            local ok, decoded = pcall(json.decode, r.data)
            if ok and decoded ~= nil then r.data = decoded end
        end
    end
    return { ok = true, interactions = rows }
end)

-- ===== CREATE
lib.callback.register('LCV:ADMIN:Interactions:Add', function(source, data)
    if not hasAdminPermission(source, 10) then
        return { ok = false, error = 'Keine Berechtigung' }
    end
    return IM():Add(data or {}) or { ok=false, error='unknown' }
end)

-- ===== UPDATE
lib.callback.register('LCV:ADMIN:Interactions:Update', function(source, data)
    if not hasAdminPermission(source, 10) then
        return { ok = false, error = 'Keine Berechtigung' }
    end
    return IM():Update(data or {}) or { ok=false, error='unknown' }
end)

-- ===== DELETE
lib.callback.register('LCV:ADMIN:Interactions:Delete', function(source, data)
    if not hasAdminPermission(source, 10) then
        return { ok = false, error = 'Keine Berechtigung' }
    end
    local id = data and data.id
    return IM():Delete(id) or { ok=false, error='unknown' }
end)

-- ===== Optional: Teleport bleibt lokal (kein DB-Bezug)
RegisterNetEvent('LCV:ADMIN:Interactions:Teleport', function(id, x, y, z)
    local src = source
    if not hasAdminPermission(src, 10) then return end
    x, y, z = tonumber(x), tonumber(y), tonumber(z)
    if not x or not y or not z then return end
    local ped = GetPlayerPed(src)
    if ped ~= 0 then
        SetEntityCoords(ped, x, y, z, false, false, false, true)
        TriggerClientEvent('LCV:ADMIN:Interactions:NotifyTeleport', src, { x = x, y = y, z = z })
    end
end)
