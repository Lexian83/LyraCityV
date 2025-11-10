RegisterNetEvent('LCV:Tablet:Server:Show', function()
    print('[TABLET][SERVER] Get trigger to Show')
    local src = source
TriggerClientEvent('LCV:Tablet:Client:Show',src)
print('[TABLET][SERVER] Trigger Client Show')
end)