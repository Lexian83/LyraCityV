-- LCV Character Select - Server Side (manager-only)
-- Hängt jetzt ausschließlich am playerManager

local MAX_CHARACTERS = 6
local function fmtBirthdate(val, mode)
  -- mode: 'iso' -> YYYY-MM-DD, 'de' -> DD.MM.YYYY
  mode = mode or 'de'
  if not val then return '' end
  if type(val) == 'table' and val.year then
    -- falls oxmysql mal als table liefert (selten)
    local y,m,d = val.year, val.month, val.day
    return (mode=='iso') and (('%04d-%02d-%02d'):format(y,m,d)) or (('%02d.%02d.%04d'):format(d,m,y))
  end
  if type(val) == 'string' then
    local y,m,d = val:match('^(%d%d%d%d)%-(%d%d)%-(%d%d)$')  -- DATE 'YYYY-MM-DD'
    if y and m and d then
      y,m,d = tonumber(y), tonumber(m), tonumber(d)
      return (mode=='iso') and (('%04d-%02d-%02d'):format(y,m,d)) or (('%02d.%02d.%04d'):format(d,m,y))
    end
  end
  return ''
end

local function slog(level, msg)
  level = level or "info"
  if LCV and LCV.Util and LCV.Util.log then
    return LCV.Util.log(level, ('[LCV-CharSelect] %s'):format(tostring(msg)))
  else
    print(("[LCV-CharSelect][%s] %s"):format(level:upper(), tostring(msg)))
  end
end

local function PM()
  if GetResourceState('playerManager') == 'started' then
    return exports['playerManager']
  end
  if GetResourceState('lcv-playermanager') == 'started' then
    return exports['lcv-playermanager']
  end
  return nil
end

-- Lädt alle Charaktere eines Accounts über playerManager-Export
local function loadCharactersForAccount(accountId, cb)
  local pm = PM()
  if not pm or not pm.ListCharactersByAccount then
    slog("error", "playerManager Export ListCharactersByAccount nicht verfügbar")
    return cb({ canCreate=false, maxCharacters=MAX_CHARACTERS, characters={} })
  end

  local ok, res = pcall(function()
    return pm:ListCharactersByAccount(tonumber(accountId))
  end)

  if not ok or not res or res.ok ~= true or type(res.characters) ~= "table" then
    slog("error", "ListCharactersByAccount fehlgeschlagen")
    return cb({ canCreate=false, maxCharacters=MAX_CHARACTERS, characters={} })
  end

  local characters = {}
  for _, r in ipairs(res.characters) do
    local bdIso = fmtBirthdate(r.birthdate, 'iso')  -- "YYYY-MM-DD"
local bdDe  = fmtBirthdate(r.birthdate, 'de')   -- "DD.MM.YYYY"

characters[#characters + 1] = {
  id        = r.id,
  accountid = r.account_id,
  name      = r.name or ("Char #" .. r.id),
  gender    = r.gender,
  -- 👇 liefere mehrere Keys, damit die UI garantiert was findet:
  birthdate        = bdIso,  -- falls UI "birthdate" erwartet
  birthday         = bdDe,   -- falls UI "birthday" erwartet
  birthdateDisplay = bdDe,   -- explizites Anzeige-Feld
  birthdate_raw    = r.birthdate, -- debugging/kompat
  type      = r.type or 0,
  is_locked = (r.is_locked == true),
  status    = r.status,
  portrait  = r.portrait,
}
  end

  local canCreate = (#characters < MAX_CHARACTERS)
  cb({ canCreate = canCreate, maxCharacters = MAX_CHARACTERS, characters = characters })
end

-- Baut Payload auf Basis accountId oder via playerManager
local function buildPayload(src, rawAccountId, cb)
  src = tonumber(src)
  if not src or src <= 0 then
    return cb({ canCreate=false, maxCharacters=MAX_CHARACTERS, characters={} }, nil)
  end

  local accountId = tonumber(rawAccountId)
  if not accountId then
    local pm = PM()
    if pm and pm.GetAccountId then
      local ok, acc = pcall(function() return pm:GetAccountId(src) end)
      if ok and acc then accountId = tonumber(acc) end
    end
  end

  if not accountId then
    slog("warn", ("buildPayload: kein accountId für src=%s"):format(src))
    return cb({ canCreate=false, maxCharacters=MAX_CHARACTERS, characters={} }, nil)
  end

  loadCharactersForAccount(accountId, function(payload)
    cb(payload, accountId)
  end)
end

-- =========================
-- Charselect öffnen (von auth)
-- =========================
AddEventHandler("LCV:charselect:load", function(targetSrc, accountId)
  local eventSource = source
  local src = tonumber(eventSource) or 0
  if src == 0 and targetSrc ~= nil then
    local t = tonumber(targetSrc)
    if t and t > 0 then src = t end
  end
  if src <= 0 then
    slog("warn", ("charselect:load invalid src (source=%s target=%s)"):format(tostring(eventSource), tostring(targetSrc)))
    return
  end

  buildPayload(src, accountId, function(payload, resolvedAccountId)
    TriggerClientEvent("LCV:charselect:show", src, payload, resolvedAccountId or accountId)
    slog("info", ("CharSelect opened for %s (acc=%s chars=%d canCreate=%s)")
      :format(GetPlayerName(src) or src, tostring(resolvedAccountId or accountId), #(payload.characters or {}), tostring(payload.canCreate)))
  end)
end)

RegisterNetEvent("LCV:charselect:reload", function()
  local src = tonumber(source) or 0
  if src <= 0 then return end
  buildPayload(src, nil, function(payload, resolvedAccountId)
    TriggerClientEvent("LCV:charselect:show", src, payload, resolvedAccountId)
    slog("info", ("CharSelect reload for %s (acc=%s chars=%d canCreate=%s)")
      :format(GetPlayerName(src) or src, tostring(resolvedAccountId), #(payload.characters or {}), tostring(payload.canCreate)))
  end)
end)

RegisterNetEvent("LCV:charselect:close", function()
  local src = tonumber(source) or 0
  if src > 0 then TriggerClientEvent("LCV:charselect:close", src) end
end)

-- Auswahl → Übergabe an playerManager, UI wird in client.lua geschlossen
RegisterNetEvent("LCV:charselect:select", function(charId)
  local src = tonumber(source) or 0
  if src <= 0 then return end
  local id = tonumber(charId)
  if not id then
    TriggerClientEvent("ox_lib:notify", src, { type = "error", description = "Ungültige Charakter-ID." })
    return
  end
  TriggerEvent("LCV:Player:SelectCharacter", src, id)
  slog("info", ("Selected char %d for %s (weiter an PlayerManager)"):format(id, GetPlayerName(src) or src))
end)

AddEventHandler("playerDropped", function() end)
