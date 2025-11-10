-- ==========================================
-- LyraCityV - Bootstrap (Basis/Helper)
-- ==========================================
LCV = LCV or {}
LCV.Util = LCV.Util or {}
LCV.DB   = LCV.DB or {}


-- ==== SQL WRAPPER (oxmysql vorwärts-/rückwärtskompatibel) ====
function LCV.DB.single(query, params, cb)
    if MySQL and MySQL.single then
        return MySQL.single(query, params, cb)
    else
        return exports.oxmysql:single(query, params, cb)
    end
end

function LCV.DB.update(query, params, cb)
    if MySQL and MySQL.update then
        return MySQL.update(query, params, cb)
    else
        return exports.oxmysql:update(query, params, cb)
    end
end

function LCV.DB.insert(query, params, cb)
    if MySQL and MySQL.insert then
        return MySQL.insert(query, params, cb)
    else
        return exports.oxmysql:insert(query, params, cb)
    end
end

function LCV.DB.query(query, params, cb)
    if MySQL and MySQL.query then
        return MySQL.query(query, params, cb)
    else
        return exports.oxmysql:query(query, params, cb)
    end
end


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
        LOG("INFO", "SQL Bootstrap geladen.")
    end)
end)
