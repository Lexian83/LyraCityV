-- blipmanager/server/exports.lua
print('blipmanager/server/exports.lua live = 2025-11-12-SSOT-GETALL-B')

local function toN(v, d)
    if v == nil then return d end
    local n = tonumber((type(v)=='string') and v:gsub(',', '.') or v)
    if n == nil then return d end
    return n
end

local function toB(v)
    return v == true or v == 1 or v == "1" or v == "true"
end

local function normalize_row(row)
    row.id         = toN(row.id)
    row.name       = tostring(row.name or ('Blip #'..tostring(row.id)))
    row.x          = toN(row.x, 0.0)+0.0
    row.y          = toN(row.y, 0.0)+0.0
    row.z          = toN(row.z, 0.0)+0.0
    row.sprite     = toN(row.sprite, 1)
    row.color      = toN(row.color or row.colour, 0)
    row.scale      = math.max(0.01, toN(row.scale, 1.0)+0.0)
    row.shortRange = toB(row.shortRange) and 1 or 0
    row.display    = toN(row.display, 2)
    row.category   = (row.category and row.category ~= '') and tostring(row.category) or nil
    row.visiblefor = toN(row.visiblefor, 0)
    row.enabled    = toB(row.enabled) and 1 or 0
    return row
end

-- ============== READ ==============
local function BM_GetAll()
    local rows = MySQL.query.await('SELECT * FROM blips ORDER BY id ASC') or {}
    for i=1,#rows do rows[i] = normalize_row(rows[i]) end
    return rows
end
exports('GetAll', BM_GetAll)

-- ============== CREATE ==============
local function BM_Add(data)
    if type(data) ~= 'table' then
        return { ok=false, error='invalid_payload' }
    end
    local r = normalize_row(data)
    local id = MySQL.insert.await([[
        INSERT INTO blips
          (name, x, y, z, sprite, color, scale, shortRange, display, category, visiblefor, enabled)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        r.name, r.x, r.y, r.z, r.sprite, r.color, r.scale, r.shortRange, r.display, r.category, r.visiblefor, r.enabled
    })
    if not id or id <= 0 then
        return { ok=false, error='insert_failed' }
    end
    TriggerEvent('blip_reload')
    return { ok=true, id=id }
end
exports('Add', BM_Add)

-- ============== UPDATE ==============
local function BM_Update(data)
    if type(data) ~= 'table' or not data.id then
        return { ok=false, error='invalid_payload' }
    end
    local r = normalize_row(data)
    if not r.id then
        return { ok=false, error='invalid_id' }
    end
    local affected = MySQL.update.await([[
        UPDATE blips
        SET name=?, x=?, y=?, z=?, sprite=?, color=?, scale=?,
            shortRange=?, display=?, category=?, visiblefor=?, enabled=?
        WHERE id=?
    ]], {
        r.name, r.x, r.y, r.z, r.sprite, r.color, r.scale,
        r.shortRange, r.display, r.category, r.visiblefor, r.enabled,
        r.id
    })
    local ok = (affected or 0) > 0
    if ok then TriggerEvent('blip_reload') end
    return { ok=ok, error=ok and nil or 'no_change' }
end
exports('Update', BM_Update)

-- ============== DELETE ==============
local function BM_Delete(id)
    id = toN(id)
    if not id then
        return { ok=false, error='invalid_id' }
    end
    local okQuery, affected = pcall(function()
        return MySQL.update.await('DELETE FROM blips WHERE id=?', { id })
    end)
    if not okQuery then
        print(('[lcv-blip] Delete error for id %s: %s'):format(id, tostring(affected)))
        return { ok=false, error='db_error' }
    end
    local ok = (affected or 0) > 0
    if ok then TriggerEvent('blip_reload') end
    return { ok=ok, error=ok and nil or 'not_found' }
end
exports('Delete', BM_Delete)
