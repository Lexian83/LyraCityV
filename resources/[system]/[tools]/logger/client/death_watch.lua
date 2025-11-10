-- Lightweight Death Watcher (no baseevents required)
local wasDead = false
local lastSent = 0

local function now() return GetGameTimer() end

CreateThread(function()
    while true do
        local ped = PlayerPedId()
        local dead = IsPedFatallyInjured(ped) or IsEntityDead(ped) or GetEntityHealth(ped) <= 0

        if dead and not wasDead then
            -- Transition: alive -> dead
            local pos = GetEntityCoords(ped)
            local killerEnt = GetPedSourceOfDeath(ped)
            local weaponHash = GetPedCauseOfDeath(ped) or 0

            local killerId = nil
            if killerEnt and killerEnt ~= 0 and IsEntityAPed(killerEnt) then
                local killerPed = killerEnt
                if IsPedAPlayer(killerPed) then
                    local netIndex = NetworkGetPlayerIndexFromPed(killerPed)
                    if netIndex then killerId = GetPlayerServerId(netIndex) end
                end
            end

            -- Throttle (falls mehrfach triggert in derselben Sekunde)
            if now() - lastSent > 1000 then
                lastSent = now()
                TriggerServerEvent('lyra:deathlog:report', {
                    pos = { x = pos.x, y = pos.y, z = pos.z },
                    killerId = killerId,
                    weapon = weaponHash
                })
            end
        elseif not dead and wasDead then
            -- Transition: dead -> alive (revived / respawn)
        end

        wasDead = dead
        Wait(200)
    end
end)
