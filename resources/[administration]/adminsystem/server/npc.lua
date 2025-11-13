-- resources/adminsystem/server/npc.lua
-- Thin proxy: leitet alle NPC-Adminaktionen an npcmanager (SSOT) weiter

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

local function NM()
    if GetResourceState('npcmanager') == 'started' then return exports['npcmanager'] end
    if GetResourceState('lcv-npcmanager') == 'started' then return exports['lcv-npcmanager'] end
    return nil
end

-- ================== NPCs ==================

lib.callback.register('LCV:ADMIN:Npcs:GetAll', function(source)
    if not hasAdminPermission(source, 10) then
        return { ok=false, error='Keine Berechtigung', npcs={} }
    end
    local nm = NM()
    local rows = nm and nm:Admin_NPCs_GetAll() or {}
    return { ok=true, npcs=rows or {} }
end)

lib.callback.register('LCV:ADMIN:Npcs:Add', function(source, data)
    if not hasAdminPermission(source, 10) then
        return { ok=false, error='Keine Berechtigung' }
    end
    local nm = NM()
    local res = nm and nm:Admin_NPCs_Add(data) or { ok=false, error='NPCManager offline' }
    return res
end)

lib.callback.register('LCV:ADMIN:Npcs:Update', function(source, data)
    if not hasAdminPermission(source, 10) then
        return { ok=false, error='Keine Berechtigung' }
    end
    local nm = NM()
    local res = nm and nm:Admin_NPCs_Update(data) or { ok=false, error='NPCManager offline' }
    return res
end)

lib.callback.register('LCV:ADMIN:Npcs:Delete', function(source, data)
    if not hasAdminPermission(source, 10) then
        return { ok=false, error='Keine Berechtigung' }
    end
    local nm = NM()
    local res = nm and nm:Admin_NPCs_Delete(data) or { ok=false, error='NPCManager offline' }
    return res
end)

-- ================== Teleport (lokal) ==================
RegisterNetEvent('LCV:ADMIN:Npcs:Teleport', function(id, x, y, z)
    local src = source
    if not hasAdminPermission(src, 10) then return end
    x, y, z = tonumber(x), tonumber(y), tonumber(z)
    if not x or not y or not z then return end
    local ped = GetPlayerPed(src)
    if ped ~= 0 then
        SetEntityCoords(ped, x, y, z, false, false, false, true)
        TriggerClientEvent('LCV:ADMIN:Interactions:NotifyTeleport', src, { x=x, y=y, z=z })
    end
end)
