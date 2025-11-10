-- server/faction/s-lspd.lua
-- LSPD Modul auf Basis des generischen PC-Systems
-- Nutzt pc_persons / pc_logs mit faction = 'LSPD'

local PLAYERMANAGER_RES = 'playerManager' -- ggf. anpassen
local FACTION = 'LSPD'

-- ========= Hilfsfunktionen =========

local function sanitize(str)
    if not str then return nil end
    str = tostring(str):match('^%s*(.-)%s*$')
    if str == '' then return nil end
    return str
end

local function toBoolInt(v)
    return (v and v ~= 0 and v ~= "0") and 1 or 0
end

local function getPlayerFromManager(src)
    local ok, data = pcall(function()
        return exports[PLAYERMANAGER_RES]:GetPlayerData(src)
    end)
    if not ok or not data or not data.character then return nil end

    local c = data.character
    local charId = c.id or c.charid or c.charId or c.character_id or 0
    local fname  = c.first_name or c.firstname or c.firstName or c.name or ''
    local lname  = c.last_name or c.lastname or c.lastName or ''

    return {
        id = tonumber(charId) or 0,
        first = fname,
        last = lname,
        raw = c
    }
end

local function buildStatus(row)
    if row.is_dead == 1 then
        row.status = 'Verstorben'
    elseif row.is_wanted == 1 then
        row.status = 'Gesucht'
    elseif row.is_exited == 1 then
        row.status = 'Ausgereist'
    else
        row.status = 'Normal'
    end
end

-- Baut aus date_of_birth:
-- row.date_iso = 'YYYY-MM-DD' (für <input type="date">)
-- row.dob      = 'DD.MM.YYYY' (für Anzeige)
local function buildDobFields(row)
    local v = row.date_of_birth

    if v == nil then
        row.dob = "unbekannt"
        row.date_iso = nil
        return
    end

    local y, m, d

    if type(v) == "number" then
        local ts = v
        if ts > 32503680000 then
            ts = ts / 1000
        end
        local t = os.date("*t", ts)
        if not t then
            row.dob = "unbekannt"
            row.date_iso = nil
            return
        end
        y, m, d = t.year, t.month, t.day
    else
        local s = tostring(v)
        y, m, d = s:match("^(%d%d%d%d)%-(%d%d)%-(%d%d)")
        if not (y and m and d) then
            y, m, d = s:match("(%d%d%d%d)%D?(%d%d)%D?(%d%d)")
        end
        if y then
            y = tonumber(y)
            m = tonumber(m)
            d = tonumber(d)
        end
    end

    if not (y and m and d) then
        row.dob = "unbekannt"
        row.date_iso = nil
        return
    end

    row.date_iso = string.format("%04d-%02d-%02d", y, m, d)
    row.dob      = string.format("%02d.%02d.%04d", d, m, y)
end

local function normalizeDobInput(dob)
    if not dob then return nil end
    dob = tostring(dob):match('^%s*(.-)%s*$')
    if dob == '' then return nil end

    local d, m, y = dob:match("^(%d%d)%.(%d%d)%.(%d%d%d%d)$")
    if d and m and y then
        return string.format("%04d-%02d-%02d", tonumber(y), tonumber(m), tonumber(d))
    end

    d, m, y = dob:match("^(%d%d)/(%d%d)/(%d%d%d%d)$")
    if d and m and y then
        return string.format("%04d-%02d-%02d", tonumber(y), tonumber(m), tonumber(d))
    end

    local yy, mm, dd = dob:match("^(%d%d%d%d)%-(%d%d)%-(%d%d)$")
    if yy and mm and dd then
        return string.format("%04d-%02d-%02d", tonumber(yy), tonumber(mm), tonumber(dd))
    end

    return dob
end

local function logPcAction(src, officer, action, targetId, meta)
    if not MySQL then return end
    MySQL.insert(
        'INSERT INTO pc_logs (faction, officer_src, officer_char_id, officer_name, action, target_person_id, meta) VALUES (?, ?, ?, ?, ?, ?, ?)',
        {
            FACTION,
            src,
            officer and officer.id or 0,
            officer and (officer.first .. ' ' .. officer.last) or nil,
            action,
            targetId or nil,
            meta and tostring(meta) or nil
        }
    )
end

local function send(src, event, payload)
    TriggerClientEvent(event, src, payload)
end

-- ========= PERSONEN SUCHE =========

RegisterNetEvent('LCV:LSPD:Server:SearchPerson', function(payload)
    local src = source
    local query = sanitize(payload and payload.query)

    local like = '%'
    if query and #query >= 2 then
        like = '%' .. query .. '%'
    end

    MySQL.query([[
        SELECT
            id,
            faction,
            first_name,
            last_name,
            date_of_birth,
            gender,
            phone_number,
            address,
            driver_license,
            weapon_license,
            pilot_license,
            boat_license,
            is_dead,
            is_wanted,
            is_exited,
            danger_level,
            notes,
            created_from
        FROM pc_persons
        WHERE
            faction = ?
            AND (
                first_name LIKE ?
                OR last_name LIKE ?
                OR CONCAT(first_name, ' ', last_name) LIKE ?
                OR phone_number LIKE ?
            )
        ORDER BY last_name, first_name
        LIMIT 100
    ]], { FACTION, like, like, like, like }, function(rows)
        rows = rows or {}

        for _, row in ipairs(rows) do
            buildStatus(row)
            buildDobFields(row)
        end

        local officer = getPlayerFromManager(src)
        local logQuery = query or 'ALL'
        logPcAction(src, officer, 'search_person', nil,
            ('query=%s, hits=%d'):format(logQuery, #rows))

        send(src, 'LCV:LSPD:Client:SearchPersonResult', {
            ok = true,
            rows = rows
        })
    end)
end)

-- ========= PERSON ANLEGEN =========

RegisterNetEvent('LCV:LSPD:Server:CreatePerson', function(data)
    local src = source
    local officer = getPlayerFromManager(src)

    local first_name = sanitize(data.first_name)
    local last_name  = sanitize(data.last_name)
    local dob        = normalizeDobInput(data.date_of_birth)
    local gender     = sanitize(data.gender)

    if not first_name or not last_name or not dob then
        send(src, 'LCV:LSPD:Client:CreatePersonResult', {
            ok = false,
            reason = 'Vorname, Nachname und Geburtsdatum sind Pflichtfelder.'
        })
        return
    end

    local phone          = sanitize(data.phone_number)
    local address        = sanitize(data.address)
    local danger_level   = tonumber(data.danger_level) or 0
    local notes          = sanitize(data.notes)
    local driver_license = toBoolInt(data.driver_license)
    local weapon_license = toBoolInt(data.weapon_license)
    local pilot_license  = toBoolInt(data.pilot_license)
    local boat_license   = toBoolInt(data.boat_license)
    local is_dead        = toBoolInt(data.is_dead)
    local is_wanted      = toBoolInt(data.is_wanted)
    local is_exited      = toBoolInt(data.is_exited)
    local created_from   = officer and officer.id or 0

    MySQL.insert([[
        INSERT INTO pc_persons
        (faction, created_from, first_name, last_name, date_of_birth, gender,
         phone_number, address,
         driver_license, weapon_license, pilot_license, boat_license,
         is_dead, is_wanted, is_exited,
         danger_level, notes)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        FACTION,
        created_from,
        first_name,
        last_name,
        dob,
        gender,
        phone,
        address,
        driver_license,
        weapon_license,
        pilot_license,
        boat_license,
        is_dead,
        is_wanted,
        is_exited,
        danger_level,
        notes
    }, function(insertId)
        if not insertId or insertId == 0 then
            send(src, 'LCV:LSPD:Client:CreatePersonResult', {
                ok = false,
                reason = 'Datenbankfehler beim Anlegen.'
            })
            return
        end

        MySQL.query('SELECT * FROM pc_persons WHERE id = ?', { insertId }, function(rows)
            local row = rows and rows[1]
            if not row then
                send(src, 'LCV:LSPD:Client:CreatePersonResult', {
                    ok = false,
                    reason = 'Eintrag nicht gefunden nach Insert.'
                })
                return
            end

            buildDobFields(row)
            buildStatus(row)

            logPcAction(src, officer, 'create_person', row.id,
                ('%s %s (%s)'):format(row.first_name, row.last_name, row.dob or 'kein DOB'))

            send(src, 'LCV:LSPD:Client:CreatePersonResult', {
                ok = true,
                row = row
            })
        end)
    end)
end)

-- ========= PERSON BEARBEITEN =========

RegisterNetEvent('LCV:LSPD:Server:UpdatePerson', function(data)
    local src = source
    local officer = getPlayerFromManager(src)

    local id = tonumber(data.id)
    if not id then
        send(src, 'LCV:LSPD:Client:UpdatePersonResult', {
            ok = false,
            reason = 'Ungültige ID.'
        })
        return
    end

    local first_name = sanitize(data.first_name)
    local last_name  = sanitize(data.last_name)
    local dob        = normalizeDobInput(data.date_of_birth)
    local gender     = sanitize(data.gender)

    if not first_name or not last_name or not dob then
        send(src, 'LCV:LSPD:Client:UpdatePersonResult', {
            ok = false,
            reason = 'Vorname, Nachname und Geburtsdatum sind Pflichtfelder.'
        })
        return
    end

    local phone          = sanitize(data.phone_number)
    local address        = sanitize(data.address)
    local danger_level   = tonumber(data.danger_level) or 0
    local notes          = sanitize(data.notes)
    local driver_license = toBoolInt(data.driver_license)
    local weapon_license = toBoolInt(data.weapon_license)
    local pilot_license  = toBoolInt(data.pilot_license)
    local boat_license   = toBoolInt(data.boat_license)
    local is_dead        = toBoolInt(data.is_dead)
    local is_wanted      = toBoolInt(data.is_wanted)
    local is_exited      = toBoolInt(data.is_exited)

    MySQL.update([[
        UPDATE pc_persons
        SET
            first_name      = ?,
            last_name       = ?,
            date_of_birth   = ?,
            gender          = ?,
            phone_number    = ?,
            address         = ?,
            driver_license  = ?,
            weapon_license  = ?,
            pilot_license   = ?,
            boat_license    = ?,
            is_dead         = ?,
            is_wanted       = ?,
            is_exited       = ?,
            danger_level    = ?,
            notes           = ?
        WHERE id = ? AND faction = ?
    ]], {
        first_name,
        last_name,
        dob,
        gender,
        phone,
        address,
        driver_license,
        weapon_license,
        pilot_license,
        boat_license,
        is_dead,
        is_wanted,
        is_exited,
        danger_level,
        notes,
        id,
        FACTION
    }, function(affected)
        if not affected or affected < 1 then
            send(src, 'LCV:LSPD:Client:UpdatePersonResult', {
                ok = false,
                reason = 'Eintrag nicht gefunden oder unverändert.'
            })
            return
        end

        MySQL.query('SELECT * FROM pc_persons WHERE id = ? AND faction = ?', { id, FACTION }, function(rows)
            local row = rows and rows[1]
            if not row then
                send(src, 'LCV:LSPD:Client:UpdatePersonResult', {
                    ok = false,
                    reason = 'Eintrag nach Update nicht gefunden.'
                })
                return
            end

            buildDobFields(row)
            buildStatus(row)

            logPcAction(src, officer, 'update_person', row.id,
                ('%s %s (%s)'):format(row.first_name, row.last_name, row.dob))

            send(src, 'LCV:LSPD:Client:UpdatePersonResult', {
                ok = true,
                row = row
            })
        end)
    end)
end)
