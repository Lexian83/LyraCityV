-- server.lua
-- Zentrales PC-System (Core) + Show-Handler

local NETWORK_DISABLED = false -- später DB-gestützt machen, aktuell nur Toggle
local PLAYERMANAGER_RES = 'playerManager' -- falls anders benannt, hier anpassen
-- Welche Fraktionen dürfen das System nutzen?
local ALLOWED_FACTIONS = {
    LSPD = true,
    EZ   = true,
    LSMD = true,
    LSFD = true,
    GOV  = true,
    DOJ  = true,
}

-- ===============================
-- Helper
-- ===============================

local function normalizeFaction(f)
    if type(f) ~= "string" then return nil end
    f = f:upper()
    if ALLOWED_FACTIONS[f] then
        return f
    end
    return nil
end

local function sanitize(str)
    if not str then return nil end
    str = tostring(str):match("^%s*(.-)%s*$")
    if str == "" then return nil end
    return str
end

local function toBoolInt(v)
    return (v and v ~= 0 and v ~= "0" and v ~= false) and 1 or 0
end

local function getOfficer(src)
    -- HIER an deinen PlayerManager anpassen
    local ok, data = pcall(function()
        if exports.playerManager and exports.playerManager.GetPlayerData then
            return exports.playerManager:GetPlayerData(src)
        end
        return nil
    end)

    if not ok or not data or not data.character then
        return {
            id = 0,
            name = ("ID %d"):format(src),
        }
    end

    local c = data.character
    local charId = c.id or c.charid or c.charId or c.character_id or 0
    local fname  = c.first_name or c.firstname or c.firstName or c.name or ""
    local lname  = c.last_name or c.lastname or c.lastName or ""
    local name   = (fname ~= "" or lname ~= "") and (fname .. " " .. lname) or ("ID %d"):format(src)

    return {
        id = tonumber(charId) or 0,
        name = name,
    }
end

local function buildStatus(row)
    if row.is_dead == 1 then
        row.status = "Verstorben"
    elseif row.is_wanted == 1 then
        row.status = "Gesucht"
    elseif row.is_exited == 1 then
        row.status = "Ausgereist"
    else
        row.status = "Normal"
    end
end

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
        if ts > 32503680000 then -- sehr groß -> vermutlich ms
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
    dob = tostring(dob):match("^%s*(.-)%s*$")
    if dob == "" then return nil end

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

local function logPcAction(src, faction, officer, action, targetId, meta)
    if not MySQL then return end
    MySQL.insert(
        "INSERT INTO pc_logs (faction, officer_src, officer_char_id, officer_name, action, target_person_id, meta) VALUES (?, ?, ?, ?, ?, ?, ?)",
        {
            faction,
            src,
            officer.id or 0,
            officer.name,
            action,
            targetId or nil,
            meta and tostring(meta) or nil
        }
    )
end

-- ===============================
-- Show / Hide
-- ===============================

RegisterNetEvent("LCV:PC:Server:Show", function(target)
    local src = source
    print("[PC][SERVER] Get trigger to Show")

    target = target or {}
    target.data = target.data or {}

    -- Officer aus playerManager holen (Name als ein Feld)
    local officer = getOfficer(src)
    if officer and officer.name then
        target.data.officerName = officer.name
    end

    if NETWORK_DISABLED then
        target.data.faction = "OFFLINE"
    else
        -- Faction kann vom aufrufenden Script gesetzt werden (z.B. 'LSPD', 'EZ', ...)
    end

    TriggerClientEvent("LCV:PC:Client:Show", src, target)
    print("[PC][SERVER] Trigger Client Show")
    print("[PC][SERVER] officerName:", target.data.officerName)

end)


-- ===============================
-- Search Person
-- ===============================

RegisterNetEvent("LCV:PC:Server:SearchPerson", function(data)
    local src = source
    data = data or {}

    local faction = normalizeFaction(data.faction) or "LSPD"
    local officer = getOfficer(src)
    local query   = sanitize(data.query)

    local like = "%"
    if query and #query >= 2 then
        like = "%" .. query .. "%"
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
        WHERE faction = ?
          AND (
              ? = '%'
              OR first_name LIKE ?
              OR last_name LIKE ?
              OR CONCAT(first_name, ' ', last_name) LIKE ?
              OR phone_number LIKE ?
          )
        ORDER BY last_name, first_name
        LIMIT 100
    ]],
    { faction, like, like, like, like, like },
    function(rows)
        rows = rows or {}
        for _, row in ipairs(rows) do
            buildStatus(row)
            buildDobFields(row)
        end

        logPcAction(src, faction, officer, "search_person", nil,
            ("query=%s, hits=%d"):format(query or "ALL", #rows)
        )

        TriggerClientEvent("LCV:PC:Client:SearchPersonResult", src, {
            ok = true,
            rows = rows,
            faction = faction,
        })
    end)
end)

-- ===============================
-- Create Person
-- ===============================

-- ===============================
-- Create Person
-- ===============================

RegisterNetEvent("LCV:PC:Server:CreatePerson", function(data)
    local src = source
    data = data or {}

    local faction = normalizeFaction(data.faction) or "LSPD"
    local officer = getOfficer(src)

    local first_name = sanitize(data.first_name)
    local last_name  = sanitize(data.last_name)
    local dob        = normalizeDobInput(data.date_of_birth)
    local gender     = sanitize(data.gender)

    if not first_name or not last_name or not dob then
        TriggerClientEvent("LCV:PC:Client:CreatePersonResult", src, {
            ok = false,
            reason = "Vorname, Nachname und Geburtsdatum sind Pflichtfelder.",
            faction = faction,
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

    -- WICHTIG:
    -- pc_persons basiert auf lspd_persons + faction.
    -- Relevante Spalten zum Insert:
    -- faction, created_from, first_name, last_name, date_of_birth, gender,
    -- phone_number, address,
    -- driver_license, weapon_license, pilot_license, boat_license,
    -- is_dead, is_wanted, is_exited,
    -- danger_level, notes, mugshot_url
    -- (id, status, created_at, updated_at sind auto / generated)

        MySQL.insert([[
        INSERT INTO pc_persons
        (faction, created_from, first_name, last_name, date_of_birth, gender,
         phone_number, address,
         driver_license, weapon_license, pilot_license, boat_license,
         is_dead, is_wanted, is_exited,
         danger_level, notes)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]],
    {
        faction,
        officer.id or 0,
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
    },
    function(insertId)
        if not insertId or insertId == 0 then
            TriggerClientEvent("LCV:PC:Client:CreatePersonResult", src, {
                ok = false,
                reason = "Datenbankfehler beim Anlegen.",
                faction = faction,
            })
            return
        end

        MySQL.query("SELECT * FROM pc_persons WHERE id = ? AND faction = ?", { insertId, faction }, function(rows)
            local row = rows and rows[1]
            if not row then
                TriggerClientEvent("LCV:PC:Client:CreatePersonResult", src, {
                    ok = false,
                    reason = "Eintrag nicht gefunden nach Insert.",
                    faction = faction,
                })
                return
            end

            buildDobFields(row)
            buildStatus(row)
            row.faction = faction

            logPcAction(src, faction, officer, "create_person", row.id,
                ("%s %s (%s)"):format(row.first_name, row.last_name, row.dob or "kein DOB")
            )

            TriggerClientEvent("LCV:PC:Client:CreatePersonResult", src, {
                ok = true,
                row = row,
                faction = faction,
            })
        end)
    end)

end)


-- ===============================
-- Update Person
-- ===============================

RegisterNetEvent("LCV:PC:Server:UpdatePerson", function(data)
    local src = source
    data = data or {}

    local faction = normalizeFaction(data.faction) or "LSPD"
    local officer = getOfficer(src)

    local id = tonumber(data.id)
    if not id then
        TriggerClientEvent("LCV:PC:Client:UpdatePersonResult", src, {
            ok = false,
            reason = "Ungültige ID.",
            faction = faction,
        })
        return
    end

    local first_name = sanitize(data.first_name)
    local last_name  = sanitize(data.last_name)
    local dob        = normalizeDobInput(data.date_of_birth)
    local gender     = sanitize(data.gender)

    if not first_name or not last_name or not dob then
        TriggerClientEvent("LCV:PC:Client:UpdatePersonResult", src, {
            ok = false,
            reason = "Vorname, Nachname und Geburtsdatum sind Pflichtfelder.",
            faction = faction,
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
    ]],
    {
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
        faction
    },
    function(affected)
        if not affected or affected < 1 then
            TriggerClientEvent("LCV:PC:Client:UpdatePersonResult", src, {
                ok = false,
                reason = "Eintrag nicht gefunden oder unverändert.",
                faction = faction,
            })
            return
        end

        MySQL.query("SELECT * FROM pc_persons WHERE id = ? AND faction = ?", { id, faction }, function(rows)
            local row = rows and rows[1]
            if not row then
                TriggerClientEvent("LCV:PC:Client:UpdatePersonResult", src, {
                    ok = false,
                    reason = "Eintrag nach Update nicht gefunden.",
                    faction = faction,
                })
                return
            end

            buildDobFields(row)
            buildStatus(row)
            row.faction = faction

            logPcAction(src, faction, officer, "update_person", row.id,
                ("%s %s (%s)"):format(row.first_name, row.last_name, row.dob or "-")
            )

            TriggerClientEvent("LCV:PC:Client:UpdatePersonResult", src, {
                ok = true,
                row = row,
                faction = faction,
            })
        end)
    end)
end)
