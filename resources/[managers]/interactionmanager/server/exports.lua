-- interactionmanager/server/exports.lua
print('interactionmanager/server/exports.lua live = 2025-11-12-SSOT-CRUD-B')

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
    -- Erwartete Spalten: id, name, description, type, x, y, z, radius, enabled, data
    row.id          = toN(row.id)
    row.name        = tostring(row.name or '')
    row.description = tostring(row.description or '')
    row.type        = tostring(row.type or 'generic')
    row.x           = toN(row.x, 0.0)+0.0
    row.y           = toN(row.y, 0.0)+0.0
    row.z           = toN(row.z, 0.0)+0.0
    row.radius      = math.max(0.1, toN(row.radius, 1.5)+0.0)
    row.enabled     = toB(row.enabled) and 1 or 0

    local jd = row.data
    if type(jd) == 'table' then
        row.data = json.encode(jd)
    elseif jd == nil or jd == '' then
        row.data = '{}'
    else
        row.data = tostring(jd)
    end
    return row
end

-- ============== READ ==============
local function IM_GetAll()
    local rows = MySQL.query.await([[
        SELECT id, name, description, type, x, y, z, radius, enabled, data
        FROM interaction_points
        ORDER BY id ASC
    ]]) or {}
    for i=1,#rows do
        rows[i] = normalize_row(rows[i])
    end
    return rows
end
exports('GetAll', IM_GetAll)

-- ============== CREATE ==============
local function IM_Add(data)
    if type(data) ~= 'table' then
        return { ok=false, error='invalid_payload' }
    end
    local r = normalize_row(data)
    local id = MySQL.insert.await([[
        INSERT INTO interaction_points (name, description, type, x, y, z, radius, enabled, data)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], { r.name, r.description, r.type, r.x, r.y, r.z, r.radius, r.enabled, r.data })
    if not id or id <= 0 then
        return { ok=false, error='insert_failed' }
    end
    TriggerEvent('lcv:interaction:server:reloadPoints')
    return { ok=true, id=id }
end
exports('Add', IM_Add)

-- ============== UPDATE ==============
local function IM_Update(data)
    if type(data) ~= 'table' or not data.id then
        return { ok=false, error='invalid_payload' }
    end
    local r = normalize_row(data)
    if not r.id then
        return { ok=false, error='invalid_id' }
    end
    local affected = MySQL.update.await([[
        UPDATE interaction_points
        SET name=?, description=?, type=?, x=?, y=?, z=?, radius=?, enabled=?, data=?
        WHERE id=?
    ]], { r.name, r.description, r.type, r.x, r.y, r.z, r.radius, r.enabled, r.data, r.id })
    local ok = (affected or 0) > 0
    if ok then TriggerEvent('lcv:interaction:server:reloadPoints') end
    return { ok=ok, error=ok and nil or 'no_change' }
end
exports('Update', IM_Update)

-- ============== DELETE ==============
local function IM_Delete(id)
    id = toN(id)
    if not id then
        return { ok=false, error='invalid_id' }
    end
    local okQuery, affected = pcall(function()
        return MySQL.update.await('DELETE FROM interaction_points WHERE id=?', { id })
    end)
    if not okQuery then
        print(('[lcv-interactionmanager] Delete error for id %s: %s'):format(id, tostring(affected)))
        return { ok=false, error='db_error' }
    end
    local ok = (affected or 0) > 0
    if ok then TriggerEvent('lcv:interaction:server:reloadPoints') end
    return { ok=ok, error=ok and nil or 'not_found' }
end
exports('Delete', IM_Delete)
