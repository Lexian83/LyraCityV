local function getCharId(src)
    local d = exports['playerManager']:GetPlayerData(src)
    return d and d.character and tonumber(d.character.id) or nil
end

RegisterNetEvent('lyra:deathlog:report', function(payload)
    local src = source
    local charId = getCharId(src)
    local p = payload and payload.pos or {}
    local killerId = payload and payload.killerId or nil
    local weapon = payload and tostring(payload.weapon or 'unknown') or 'unknown'

    local killerIdent = nil
    if killerId and GetPlayerName(killerId) then
        killerIdent = GetPlayerIdentifier(killerId, 0) or ('player:'..tostring(killerId))
    end

    -- Konsolen-Check
    -- print(('[DeathLog] REPORTED src=%s char=%s killer=%s weapon=%s @ (%.2f, %.2f, %.2f)'):format(src, tostring(charId), tostring(killerIdent or '-'), weapon, p.x or 0.0, p.y or 0.0, p.z or 0.0))

    MySQL.insert('INSERT INTO death_logs (character_id, killer_identifier, reason, pos_x, pos_y, pos_z) VALUES (?, ?, ?, ?, ?, ?)', {
        charId, killerIdent, weapon, p.x or 0.0, p.y or 0.0, p.z or 0.0
    })
end)
