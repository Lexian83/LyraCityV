-- c-stamina.lua
local infinite = true

CreateThread(function()
    local v = GetConvar('LCV_stamina_infinite', 'true')
    v = string.lower(tostring(v or 'true'))
    infinite = (v == 'true' or v == '1' or v == 'yes' or v == 'on')
end)

CreateThread(function()
    while true do
        if infinite then
            RestorePlayerStamina(PlayerId(), 1.0)
        end
        Wait(200)
    end
end)
