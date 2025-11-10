-- Disable GTA idle cinematic camera
CreateThread(function()
    while true do
        -- verhindert, dass die CinematicCam anspringt
        InvalidateIdleCam()             -- „verwirft“ den Idle-Timer
        InvalidateVehicleIdleCam()      -- auch im Fahrzeug
        Wait(10000) -- alle 10 Sekunden reicht
    end
end)
CreateThread(function()
    while true do
        DisableIdleCamera(true)  -- (älteres Native, schadet aber nicht)
        Wait(60000)              -- alle 60 Sekunden erneut
    end
end)
