-- client/faction/c-lspd.lua
-- Bridge zwischen NUI (LSPD UI) und generischem PC-Core (server.lua)

local FACTION = 'LSPD'

local function ensureFaction(data)
    data = data or {}
    if not data.faction or data.faction == '' then
        data.faction = FACTION
    end
    return data
end

-- NUI -> SERVER (PC-Core)

RegisterNUICallback('lspd_searchPerson', function(data, cb)
    local payload = ensureFaction({
        query = data and data.query or nil
    })

    TriggerServerEvent('LCV:PC:Server:SearchPerson', payload)
    if cb then cb({ ok = true }) end
end)

RegisterNUICallback('lspd_createPerson', function(data, cb)
    local payload = ensureFaction(data or {})
    TriggerServerEvent('LCV:PC:Server:CreatePerson', payload)
    if cb then cb({ ok = true }) end
end)

RegisterNUICallback('lspd_updatePerson', function(data, cb)
    local payload = ensureFaction(data or {})
    TriggerServerEvent('LCV:PC:Server:UpdatePerson', payload)
    if cb then cb({ ok = true }) end
end)

-- SERVER (PC-Core) -> NUI (LSPD spezifische Actions)

RegisterNetEvent('LCV:PC:Client:SearchPersonResult', function(payload)
    if not payload or payload.faction ~= FACTION then return end

    SendNUIMessage({
        action = 'lspd:searchPersonResult',
        data = payload
    })
end)

RegisterNetEvent('LCV:PC:Client:CreatePersonResult', function(payload)
    if not payload or payload.faction ~= FACTION then return end

    SendNUIMessage({
        action = 'lspd:createPersonResult',
        data = payload
    })
end)

RegisterNetEvent('LCV:PC:Client:UpdatePersonResult', function(payload)
    if not payload or payload.faction ~= FACTION then return end

    SendNUIMessage({
        action = 'lspd:updatePersonResult',
        data = payload
    })
end)
