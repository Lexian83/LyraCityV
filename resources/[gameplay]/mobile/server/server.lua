RegisterNetEvent('LCV:Phone:Server:Show', function()
    print('[PHONE][SERVER] Get trigger to Show')
    local src = source
TriggerClientEvent('LCV:Phone:Client:Show',src)
print('[PHONE][SERVER] Trigger Client Show')
end)