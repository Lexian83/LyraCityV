-- =====================================================
-- Lyra City V - Overhead Labels Server (HARDENED)
-- =====================================================
-- Snapshot cache + sanitized names
-- =====================================================

local SNAPSHOT = {}
local LAST_BUILD = 0
local TTL_MS = 2500

local function ms() return math.floor(os.clock()*1000) end

local function safeName(s)
    if type(s) ~= 'string' then return 'Player' end
    s = s:gsub("[%c\r\n\t]", "")
    if #s > 48 then s = s:sub(1,48) .. "…" end
    return s
end

local function buildSnapshot()
    local now = ms()
    if (now - LAST_BUILD) < TTL_MS and #SNAPSHOT > 0 then
        return SNAPSHOT
    end

    local out = {}
    for _, sidStr in ipairs(GetPlayers()) do
        local sid = tonumber(sidStr)
        local pdata = exports['playerManager'] and exports['playerManager']:GetPlayerData(sid) or nil
        local charId, charName

        if pdata and pdata.character then
            charId  = tonumber(pdata.character.id) or 0
            charName = pdata.character.name or GetPlayerName(sid)
        else
            charName = GetPlayerName(sid)
        end

        table.insert(out, {
            sid     = sid,
            name    = safeName(charName or ('Player ' .. sid)),
            charId  = charId or 0
        })
    end

    SNAPSHOT = out
    LAST_BUILD = now
    return SNAPSHOT
end

RegisterNetEvent('lcv:labels:request', function()
    -- [LCV] require admin level 10
    local _src = source or -1
    if not LCV or not LCV.Perms or not LCV.Perms.hasLevel or not LCV.Perms.hasLevel(_src, 10) then return end

    TriggerClientEvent('lcv:labels:snapshot', src, buildSnapshot())
end)

-- internal server request used by admin toggle to push fresh snapshot
RegisterNetEvent('lcv:labels:requestSnapshot', function(targetSrc)
    -- [LCV] require admin level 10
    local _src = source or -1
    if not LCV or not LCV.Perms or not LCV.Perms.hasLevel or not LCV.Perms.hasLevel(_src, 10) then return end

    local ts = targetSrc or source
    TriggerClientEvent('lcv:labels:snapshot', ts, buildSnapshot())
end)
