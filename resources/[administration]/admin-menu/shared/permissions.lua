
-- LyraCityV (LCV) - Admin Permissions (No ACE)
-- Levels: 0..10 (10 = Oberster Administrator, 0 = normaler Spieler)
-- Source of truth: CURRENT CHARACTER level from playerManager:GetPlayerData().character.level

LCV = LCV or {}
LCV.Perms = LCV.Perms or {}

local function clampLevel(n)
    n = tonumber(n) or 0
    if n < 0 then n = 0 end
    if n > 10 then n = 10 end
    return n
end

-- Primary: Use playerManager:GetPlayerData().character.level (your current API)
local function getCharLVL(src)
    local ok, d = pcall(function()
        return exports['playerManager'] and exports['playerManager']:GetPlayerData(src) or nil
    end)
    if not ok or not d or not d.character then return 0 end
    return clampLevel(d.character.level or 0)
end

-- Fallbacks for resilience
local function tryStateBag(src)
    local ok, state = pcall(function()
        local p = Player(src)
        return p and p.state
    end)
    if ok and state and state.admin_level ~= nil then
        return clampLevel(state.admin_level)
    end
    return nil
end

local function tryPlayerManagerAlt(src)
    if GetResourceState('playerManager') == 'started' then
        local ok, lvl = pcall(function()
            local exp = exports['playerManager']
            if exp and exp.GetAdminLevel then
                return exp:GetAdminLevel(src)
            end
        end)
        if ok and lvl ~= nil then return clampLevel(lvl) end

        local ok2, ch = pcall(function()
            local exp = exports['playerManager']
            if exp and exp.GetCurrentCharacter then
                return exp:GetCurrentCharacter(src)
            end
        end)
        if ok2 and type(ch) == "table" then
            local lvl = ch.admin_level or ch.level or 0
            return clampLevel(lvl)
        end
    end
    return nil
end

function LCV.Perms.getLevel(src)
    -- 1) Jens' canonical path
    local lvl = getCharLVL(src)
    if lvl and lvl > 0 then return lvl end

    -- 2) Statebag fallback (if you choose to mirror into state.admin_level somewhere)
    lvl = tryStateBag(src)
    if lvl ~= nil then return lvl end

    -- 3) Alternate playerManager exports (if present)
    lvl = tryPlayerManagerAlt(src)
    if lvl ~= nil then return lvl end

    return 0
end

function LCV.Perms.hasLevel(src, required)
    required = tonumber(required) or 1
    return LCV.Perms.getLevel(src) >= required
end

exports('GetAdminLevel', function(src) return LCV.Perms.getLevel(src) end)
exports('HasAdminLevel', function(src, required) return LCV.Perms.hasLevel(src, required) end)

RegisterNetEvent('lcv:admin:requestLevel', function()
    local src = source
    TriggerClientEvent('lcv:admin:receiveLevel', src, LCV.Perms.getLevel(src))
end)
