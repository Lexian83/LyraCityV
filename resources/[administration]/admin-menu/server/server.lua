-- =====================================================
-- Lyra City V – Admin Menu Server (HARDENED, FIXED)
-- =====================================================

local STATES = {}      -- [src] = { invis=false, god=false, fly=false, label=false }
local LASTCALL = {}    -- [src][event] = timestamp (ms)
local RL_WINDOW_MS = 600 -- cooldown in ms

local function now_ms() return math.floor(os.clock() * 1000) end

local function log(level, msg)
    if LCV and LCV.Util and LCV.Util.log then
        LCV.Util.log(level, msg)
    else
        print(("[LCV-ADMIN][%s] %s"):format(level, msg))
    end
end

local function getCharLVL(src)
    local ok, d = pcall(function()
        return exports['playerManager'] and exports['playerManager']:GetPlayerData(src) or nil
    end)
    if not ok or not d or not d.character then return 0 end
    return tonumber(d.character.level) or 0
end

-- === FIX: ACE vollständig entfernt, nur Charakter-Level (0–10) zählt ===
local function hasAdminPermission(src, required)
    local lvl = getCharLVL(src)
    required = tonumber(required) or 10
    return lvl >= required
end

local function getState(src)
    if not STATES[src] then
        STATES[src] = { invis=false, god=false, fly=false, label=false }
    end
    return STATES[src]
end

local function rateLimited(src, ev)
    LASTCALL[src] = LASTCALL[src] or {}
    local last = LASTCALL[src][ev] or 0
    local t = now_ms()
    if (t - last) < RL_WINDOW_MS then
        return true
    end
    LASTCALL[src][ev] = t
    return false
end

AddEventHandler('playerDropped', function()
    local src = source
    STATES[src] = nil
    LASTCALL[src] = nil
end)

-- ---- Open flow ----
RegisterNetEvent('LCV:menu:requestOpen', function()
    local src = source
    if not hasAdminPermission(src, 10) then
        log('WARN', ('Denied admin menu for %s'):format(src))
        return
    end
    TriggerClientEvent('LCV:menu:open:admin', src)
end)

-- Legacy open kept for compatibility (now gated)
RegisterNetEvent('LCV:menu:open:admin', function()
    local src = source
    if not hasAdminPermission(src, 10) then
        log('WARN', ('Denied legacy open for %s'):format(src))
        return
    end
    TriggerClientEvent('LCV:menu:open:admin', src)
end)

-- ---- Toggles ----
RegisterNetEvent('LCV:admin:setInvis', function(state)
    local src = source
    if rateLimited(src, 'invis') then return end
    if not hasAdminPermission(src, 10) then return end
    local st = getState(src)
    st.invis = state and true or false
    TriggerClientEvent('LCV:admin:updatePlayerInvis', -1, src, st.invis)
end)

RegisterNetEvent('LCV:admin:setGod', function(state)
    local src = source
    if rateLimited(src, 'god') then return end
    if not hasAdminPermission(src, 10) then return end
    local st = getState(src)
    st.god = state and true or false
    TriggerClientEvent('LCV:admin:updatePlayerGod', src, st.god)
end)

RegisterNetEvent('LCV:admin:setFly', function(state)
    local src = source
    if rateLimited(src, 'fly') then return end
    if not hasAdminPermission(src, 10) then return end
    local st = getState(src)
    st.fly = state and true or false
    TriggerClientEvent('LCV:admin:updatePlayerFly', src, st.fly)
end)

-- Labels toggle
RegisterNetEvent('lcv:labels:toggle', function(state)
    local src = source
    if rateLimited(src, 'labels') then return end
    if not hasAdminPermission(src, 10) then return end
    local st = getState(src)
    st.label = state and true or false
    TriggerClientEvent('lcv:labels:state', src, st.label)
    if st.label then
        TriggerEvent('lcv:labels:requestSnapshot', src)
    end
end)

-- Export current state for other resources
exports('GetAdminState', function(src)
    return STATES[src] or {invis=false, god=false, fly=false, label=false}
end)
