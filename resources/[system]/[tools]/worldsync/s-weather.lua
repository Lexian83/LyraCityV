-- s-weather.lua (server) v0.2.0
-- Convars:
--   setr LCV_weather "EXTRASUNNY"
-- Commands:
--   LCVsetweather <WEATHERTYPE>

local function readConvarStr(name, default)
    local v = GetConvar(name, default or "")
    if not v or v == "" then return default end
    return tostring(v)
end

local weather = (readConvarStr("LCV_weather", "EXTRASUNNY") .. ""):upper()

-- publish initial weather
GlobalState.LCV_weather = weather

RegisterCommand("LCVsetweather", function(src, args)
    if src ~= 0 then return end -- console only by default
    local w = (args[1] or ""):upper()
    if w == "" then
       -- print("^3Usage:^7 LCVsetweather <WEATHERTYPE>")
        return
    end
    GlobalState.LCV_weather = w
   -- print(("[WorldSync:Weather] Weather set to %s"):format(w))
end, true)

CreateThread(function()
    Wait(300)
    print(("[WorldSync:Weather] Up. Weather=%s"):format(weather))
end)
