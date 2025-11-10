local function ts() return os.date('%Y-%m-%d %H:%M:%S') end

local function runCleanup(retentionDays)
    retentionDays = tonumber(retentionDays) or 180

    -- Safety: Index empfehlen (einmalig anlegbar)
    MySQL.query([[
        CREATE INDEX IF NOT EXISTS idx_connect_time ON connection_logs (connect_time);
    ]])

    -- Vorher: Anzahl Kandidaten (optional, nur Log)
    local before = MySQL.scalar.await(
        'SELECT COUNT(*) FROM connection_logs WHERE connect_time < (NOW() - INTERVAL ? DAY)',
        { retentionDays }
    ) or 0

    local affected = MySQL.update.await(
        'DELETE FROM connection_logs WHERE connect_time < (NOW() - INTERVAL ? DAY)',
        { retentionDays }
    ) or 0

    print(('[ConnCleanup][%s] Done: %d deleted (candidates before: %d, retention=%d days)'):format(ts(), affected, before, retentionDays))

    return affected, before
end

-- Nächsten Zielzeitpunkt (heute/ morgen) berechnen
local function secondsUntilNextRun(hour, minute)
    local now = os.date('*t')          -- Serverlokalzeit
    local target = {
        year = now.year, month = now.month, day = now.day,
        hour = hour, min = minute, sec = 0, isdst = now.isdst
    }
    local now_s    = os.time(now)
    local target_s = os.time(target)
    if target_s <= now_s then
        target.day = target.day + 1
        target_s = os.time(target)
    end
    return target_s - now_s
end

-- Hintergrund-Thread: 1x täglich
CreateThread(function()
    -- Initialer Jitter (optional)
    local jitter = 0
    if Config.JitterSecondsMax and Config.JitterSecondsMax > 0 then
        jitter = math.random(0, Config.JitterSecondsMax)
    end

    while true do
        local waitSec = secondsUntilNextRun(Config.DailyRun.hour, Config.DailyRun.minute) + jitter
        print(('[ConnCleanup][%s] next run in ~%ds (at %02d:%02d)')
            :format(ts(), waitSec, Config.DailyRun.hour, Config.DailyRun.minute))
        Wait(waitSec * 1000)

        -- ausführen
        local ok, err = pcall(function()
            runCleanup(Config.RetentionDays)
        end)
        if not ok then
            print(('[ConnCleanup][%s][ERROR] %s'):format(ts(), tostring(err)))
        end

        -- Folgeläufe ohne Jitter (oder erneut berechnen – wie du magst)
        jitter = 0
        -- Warte bis zur nächsten Zielzeit
        Wait(1000) -- kurze Atempause, dann berechnet die Schleife den nächsten waitSec neu
    end
end)

-- Admin/Console-Command: sofort ausführen
RegisterCommand('clv_logs_cleanup_now', function(src, args)
    if src ~= 0 then
        -- Nur Konsole zulassen; bei Bedarf Whitelist ergänzen
        print('[ConnCleanup] Deny: only console can run this command.')
        return
    end
    local days = tonumber(args[1]) or Config.RetentionDays
    print(('[ConnCleanup][%s] Manual run requested (retention=%d days)'):format(ts(), days))
    local ok, err = pcall(function() runCleanup(days) end)
    if not ok then
        print(('[ConnCleanup][%s][ERROR] %s'):format(ts(), tostring(err)))
    end
end, false)
