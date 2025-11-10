-- c-weather.lua (client) v0.2.0
-- Applies weather from GlobalState; guards missing natives between artifacts.

local currentWeather = nil

local function safeCall(fn, ...)
    if type(fn) == "function" then return fn(...) end
    return nil
end

local function applyWeather(w)
    if not w or w == "" then return end
    if currentWeather == w then return end
    currentWeather = w

    ClearOverrideWeather()
    ClearWeatherTypePersist()
    safeCall(SetWeatherOwnedByNetwork, true)
    safeCall(SetRandomWeatherTypeDisabled, true)

    SetWeatherTypeOvertimePersist(w, 10.0)
    Wait(10000)
    SetWeatherTypePersist(w)
    SetWeatherTypeNow(w)
    SetWeatherTypeNowPersist(w)
    if type(SetWind) == "function" then SetWind(0.0) end
end

AddStateBagChangeHandler("LCV_weather", nil, function(_, _, value)
    applyWeather(value)
end)

-- safety loop
CreateThread(function()
    while true do
        local w = GlobalState.LCV_weather
        if w then applyWeather(w) end
        Wait(1000)
    end
end)

-- init
CreateThread(function()
    Wait(500)
    if GlobalState.LCV_weather then applyWeather(GlobalState.LCV_weather) end
end)
