RegisterNetEvent('LCV:Housing:Server:Show', function()
    print('[HOUSING][SERVER] Get trigger to Show')
    local src = source
TriggerClientEvent('LCV:Housing:Client:Show',src)
print('[HOUSING][SERVER] Trigger Client Show')
end)