-- adminsystem/server/blips.lua
-- Achtung: Dieses File enthält KEINE SQL mehr. DB macht nur noch lcv-blip.

-- ====== Berechtigungen wie gehabt ======
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

-- ====== Hilfsfunktion: sicheres Export-Proxying ======
local function BLIPM()
    return exports['blipmanager']
end

-- ====== Callbacks: nur noch Proxies zum Blip-Manager ======

lib.callback.register('LCV:ADMIN:Blips:GetAll', function(source)
    if not hasAdminPermission(source, 10) then
        return { ok = false, error = 'Keine Berechtigung', blips = {} }
    end
    local rows = BLIPM():GetAll() or {}
    -- rows sind bereits normalisiert; für Admin-UI evtl. bools sauber machen:
    for _, r in ipairs(rows) do
        r.shortRange = (r.shortRange == 1)
        r.enabled    = (r.enabled == 1)
    end
    return { ok = true, blips = rows }
end)

lib.callback.register('LCV:ADMIN:Blips:Add', function(source, data)
    if not hasAdminPermission(source, 10) then
        return { ok = false, error = 'Keine Berechtigung' }
    end
    local res = BLIPM():Add(data or {})
    return res or { ok=false, error='unknown' }
end)

lib.callback.register('LCV:ADMIN:Blips:Update', function(source, data)
    if not hasAdminPermission(source, 10) then
        return { ok = false, error = 'Keine Berechtigung' }
    end
    local res = BLIPM():Update(data or {})
    return res or { ok=false, error='unknown' }
end)

lib.callback.register('LCV:ADMIN:Blips:Delete', function(source, data)
    if not hasAdminPermission(source, 10) then
        return { ok = false, error = 'Keine Berechtigung' }
    end
    local id = data and data.id
    local res = BLIPM():Delete(id)
    return res or { ok=false, error='unknown' }
end)

-- Optional: Teleport bleibt wie gehabt, da reiner Gameplay-Call ohne DB
lib.callback.register('LCV:ADMIN:Blips:GetPlayerPos', function(source)
    local ped = GetPlayerPed(source)
    if not ped or ped == 0 or not DoesEntityExist(ped) then
        return { ok = false, error = 'no_ped' }
    end
    local coords = GetEntityCoords(ped)
    return { ok = true, x = coords.x, y = coords.y, z = coords.z }
end)

RegisterNetEvent('LCV:ADMIN:Blips:Teleport', function(id, x, y, z)
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
