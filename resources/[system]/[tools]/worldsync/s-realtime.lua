-- s-realtime.lua
-- Convars (server.cfg):
--   setr LCV_ws_tick_ms "1000"       -- Server-Tick für Zeit-Push
--   setr LCV_clock_mode "minute"     -- "minute" oder "second"

local function readStr(name, default)
    local v = GetConvar(name, default or "")
    return (v == nil or v == "") and default or tostring(v)
end
local function readNum(name, default)
    local v = tonumber(GetConvar(name, tostring(default or 0)))
    return v or default
end

local tickMs    = readNum("LCV_ws_tick_ms", 1000)
local clockMode = (readStr("LCV_clock_mode", "minute") or "minute"):lower()
if clockMode ~= "second" then clockMode = "minute" end

-- Sofortige Antwort auf Client-Request (z. B. bei Join/Respawn/Resource-Start)
RegisterNetEvent("LCV:realtime:requestTime")
AddEventHandler("LCV:realtime:requestTime", function()
    local src = source
    local t = os.date("*t")
    -- Sekunden nur im second-Mode senden; im minute-Mode 0 setzen
    local s = (clockMode == "second") and t.sec or 0
    TriggerClientEvent("LCV:realtime:event", src, t.hour, t.min, s)
end)

-- Regelmäßiger Push an alle, damit Anzeige nachzieht
CreateThread(function()
    local lastH, lastM, lastS = -1, -1, -1
    while true do
        local t = os.date("*t")
        if clockMode == "second" then
            if t.sec ~= lastS or t.min ~= lastM or t.hour ~= lastH then
                TriggerClientEvent("LCV:realtime:event", -1, t.hour, t.min, t.sec)
                lastH, lastM, lastS = t.hour, t.min, t.sec
            end
        else -- minute
            if t.min ~= lastM or t.hour ~= lastH then
                TriggerClientEvent("LCV:realtime:event", -1, t.hour, t.min, 0)
                lastH, lastM, lastS = t.hour, t.min, 0
            end
        end
        Wait(tickMs)
    end
end)

-- Optional: Live-Switch (Konsole)
RegisterCommand("LCVsetclockmode", function(src, args)
    if src ~= 0 then return end
    local m = (args[1] or ""):lower()
    if m ~= "minute" and m ~= "second" then
       -- print("^3Usage:^7 LCVsetclockmode minute|second")
        return
    end
    clockMode = m
   -- print(("[Realtime] Clock mode set to %s"):format(m))
end, true)
