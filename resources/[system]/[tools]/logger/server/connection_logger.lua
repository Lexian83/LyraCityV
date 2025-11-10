-- server/connection_logger.lua
local admin_list = { "license:xxxxxxxxxxxxxxxxxxxx", "steam:1100001xxxxxxx" } -- optional: erlaubte Admins für Abfragen

local function findIdentifier(identifiers, prefix)
  for _,id in ipairs(identifiers) do
    if id:sub(1, #prefix) == prefix then return id end
  end
  return nil
end

AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
  local src = source
  local ip = GetPlayerEndpoint(src) or 'unknown'
  local ids = GetPlayerIdentifiers(src) or {}
  local license = findIdentifier(ids, 'license:') or nil
  local steam   = findIdentifier(ids, 'steam:') or nil
  local discord = findIdentifier(ids, 'discord:') or nil

  -- optional: weitere Daten in extra JSON
  local extra = { clientName = name }

  -- Insert über oxmysql (callback)
  MySQL.insert('INSERT INTO connection_logs (identifier_license, identifier_steam, identifier_discord, ip, name, extra) VALUES (?, ?, ?, ?, ?, ?)',
    { license, steam, discord, ip, name, json.encode(extra) },
    function(insertId)
      -- optional: log to server console
      -- print(('[ConnLog] %s connected (%s) -> id=%s'):format(name, ip, tostring(insertId)))
    end
  )
end)

-- Beispiel: Update last row for identifier with disconnect time
AddEventHandler('playerDropped', function(reason)
  local src = source
  local ids = GetPlayerIdentifiers(src) or {}
  local license = findIdentifier(ids, 'license:') or nil
  if not license then return end

  -- Setze disconnect_time auf NOW() für letzten Connect-Eintrag dieses Lizenz-IDs
  MySQL.update('UPDATE connection_logs SET disconnect_time = NOW() WHERE identifier_license = ? ORDER BY connect_time DESC LIMIT 1', { license })
end)

AddEventHandler('onResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    LCV.Util.log("INFO", " Connection Logger geladen.")
end)