-- c-realtime.lua
-- Hartes Einfrieren: Uhr bleibt stehen; Server pusht Zielzeit.
-- Wir setzen regelmäßig erneut auf den Zielwert, damit nichts „anspringt“.

local target = { h = 12, m = 0, s = 0 }
local HARD_LOCK_INTERVAL_MS = 100  -- alle 100 ms erneut einfrieren (anpassbar)

RegisterNetEvent("LCV:realtime:event")
AddEventHandler("LCV:realtime:event", function(h, m, s)
    target.h, target.m, target.s = h or 12, m or 0, s or 0
    -- Setzen + sofort pausieren
    NetworkOverrideClockTime(target.h, target.m, target.s)
    PauseClock(true)
end)

-- Bei Start/Respawn Zeit anfragen
CreateThread(function()
    -- Nach Resource-Start
    Wait(300)
    TriggerServerEvent("LCV:realtime:requestTime")
end)

AddEventHandler("playerSpawned", function()
    -- Nach Respawn
    TriggerServerEvent("LCV:realtime:requestTime")
end)

-- Hard-Lock Loop: hält die Anzeige stur auf der Zielzeit
CreateThread(function()
    while true do
        NetworkOverrideClockTime(target.h, target.m, target.s)
        PauseClock(true)
        Wait(HARD_LOCK_INTERVAL_MS)
    end
end)
