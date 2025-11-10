-- ==========================================
-- LyraCityV - Bootstrap (Basis/Helper)
-- ==========================================
LCV = LCV or {}
LCV.Util = LCV.Util or {}
LCV.DB   = LCV.DB or {}

-- ==== CONFIG HELPERS ====
function LCV.Util.getConvarOrFail(name)
    local val = GetConvar(name, "")
    if not val or val == "" then
        error(("Missing convar: %s"):format(name))
    end
    return val
end

-- ==== IDENTIFIER ====
function LCV.Util.extractIdentifier(identifiers, prefix)
    for _, id in ipairs(identifiers) do
        if string.sub(id, 1, #prefix + 1) == (prefix .. ":") then
            return string.sub(id, #prefix + 2)
        end
    end
    return nil
end

-- ==== DEFERRALS ====
function LCV.Util.step(deferrals, text)
    deferrals.update(("LyraCityV: %s"):format(text))
    Wait(300)
end

function LCV.Util.finish(deferrals, text)
    if text and text ~= "" then
        deferrals.update(("LyraCityV: %s"):format(text))
        Wait(500)
    end
    deferrals.done()
end

function LCV.Util.fail(deferrals, text)
    deferrals.done(text or "Unbekannter Fehler.")
end

-- ==== HTTP (Discord) ====
function LCV.Util.httpRequest(method, url, headers, body, cb)
    local data = body and json.encode(body) or nil
    local hdrs = headers or {}
    if not hdrs["Content-Type"] then
        hdrs["Content-Type"] = "application/json"
    end
    PerformHttpRequest(url, function(status, text, responseHeaders)
        cb(status, text, responseHeaders or {})
    end, method, data, hdrs)
end

function LCV.Util.tryJson(text)
    if not text or text == "" then return nil end
    local ok, obj = pcall(function() return json.decode(text) end)
    if ok then return obj end
    return nil
end

-- ==== DISCORD CACHE ====
LCV.DiscordCache = LCV.DiscordCache or {}
LCV.DISCORD_CACHE_TTL = 60

function LCV.getCachedRoles(discordId)
    local e = LCV.DiscordCache[discordId]
    if not e then return nil end
    if e.expires < os.time() then
        LCV.DiscordCache[discordId] = nil
        return nil
    end
    return e.roles
end

function LCV.setCachedRoles(discordId, roles)
    LCV.DiscordCache[discordId] = { roles = roles, expires = os.time() + LCV.DISCORD_CACHE_TTL }
end

-- Info beim Start
local function LOG(level, msg)
  if LCV and LCV.Util and LCV.Util.log then
    LCV.Util.log(level, msg)
  else
    -- print(("[LyraCityV][%s] %s"):format(level, tostring(msg)))
  end
end

AddEventHandler('onResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    -- mini Delay, falls Dep noch initialisiert
    SetTimeout(0, function()
        LOG("INFO", "AUTH Bootstrap geladen.")
    end)
end)

