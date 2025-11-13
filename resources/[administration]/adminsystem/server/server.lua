local function getCharLVL(src)
    local ok, d = pcall(function()
        return exports['playerManager'] and exports['playerManager']:GetPlayerData(src) or nil
    end)
    if not ok or not d or not d.character then return 0 end
    return tonumber(d.character.level) or 0
end

local function getCharId(src)
    local ok, d = pcall(function()
        return exports['playerManager'] and exports['playerManager']:GetPlayerData(src) or nil
    end)
    if not ok or not d or not d.character then return nil end
    return tonumber(d.character.id) or nil
end

local function hasAdminPermission(src, required)
    local lvl = getCharLVL(src)
    required = tonumber(required) or 10
    return lvl >= required
end

-- ================== ADMIN UI ÖFFNEN ==================

RegisterNetEvent('LCV:ADMIN:Server:Show', function()
    local src = source
    if not hasAdminPermission(src, 10) then return end
    TriggerClientEvent('LCV:ADMIN:Client:Show', src)
end)

-- ================== TELEPORT TO WAYPOINT / FREI ==================

RegisterNetEvent('LCV:ADMIN:TeleportToWaypoint', function(x, y, z)
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

RegisterNetEvent('LCV:ADMIN:Teleport:Coords', function(x, y, z)
    local src = source
    if not hasAdminPermission(src, 10) then return end

    x, y, z = tonumber(x), tonumber(y), tonumber(z)
    if not x or not y or not z then return end

    local ped = GetPlayerPed(src)
    if ped ~= 0 then
        SetEntityCoords(ped, x + 0.0, y + 0.0, z + 0.0, false, false, false, true)
        TriggerClientEvent('LCV:ADMIN:Interactions:NotifyTeleport', src, { x = x, y = y, z = z })
    end
end)



-- ===== HOME: DUTY INFO =====

lib.callback.register('LCV:ADMIN:Home:GetDutyData', function(source, _)
    if not hasAdminPermission(source, 1) then
        return { ok = false, error = 'Keine Berechtigung', dutyFactions = {}, currentDuty = {} }
    end

    local charId = getCharId(source)
    if not charId then
        return { ok = false, error = 'Kein Character aktiv.', dutyFactions = {}, currentDuty = {} }
    end

    local dutyFactions = exports['factionManager']:GetDutyFactions(charId) or {}

    local currentDuty = {}
    for _, f in ipairs(dutyFactions) do
        if f.onDuty then
            currentDuty[#currentDuty+1] = {
                id    = f.id,
                name  = f.name,
                label = f.label
            }
        end
    end

    return {
        ok = true,
        dutyFactions = dutyFactions,
        currentDuty  = currentDuty
    }
end)

lib.callback.register('LCV:ADMIN:Home:SetDuty', function(source, data)
    if not hasAdminPermission(source, 1) then
        return { ok = false, error = 'Keine Berechtigung' }
    end

    local charId = getCharId(source)
    if not charId then
        return { ok = false, error = 'Kein Character aktiv.' }
    end

    local factionId = tonumber(data and data.faction_id)
    local turnOn    = data and data.on == true

    if not factionId then
        return { ok = false, error = 'Ungültige Fraktion.' }
    end

    local ok, err, dutyFactions, currentDuty =
        exports['factionManager']:SetDuty(charId, factionId, turnOn)

    if not ok then
        return { ok = false, error = err or 'Fehler beim Setzen des Duty-Status.' }
    end

    return {
        ok = true,
        dutyFactions = dutyFactions or {},
        currentDuty  = currentDuty or {}
    }
end)
