-- c-minimap.lua
-- Hides the minimap (radar) when the player is on foot.
-- Shows it only when the player is in any vehicle (car, bike, bicycle, boat, heli, plane, etc.).

local lastState = nil  -- 'shown' or 'hidden'
local CHECK_INTERVAL_MS = 250  -- polling interval

local function setRadarVisible(visible)
    local newState = visible and 'shown' or 'hidden'
    if newState == lastState then return end
    DisplayRadar(visible)
    lastState = newState
end

CreateThread(function()
    setRadarVisible(false)
    while true do
        local ped = PlayerPedId()
        local inVeh = IsPedInAnyVehicle(ped, false)

        if IsPauseMenuActive() then
            setRadarVisible(false)
        else
            setRadarVisible(inVeh)
        end

        Wait(CHECK_INTERVAL_MS)
    end
end)

AddEventHandler('playerSpawned', function()
    setRadarVisible(false)
end)
