Config = Config or {}

-- Anzahl Tage, nach denen Logs gelöscht werden
Config.RetentionDays = 180

-- Tägliche Ausführungszeit (Serverzeit) im 24h-Format
-- z.B. 03:30 = 3:30 Uhr morgens
Config.DailyRun = { hour = 3, minute = 30 }

-- Optional: zusätzliches Jitter in Sekunden, um gleichzeitige Starts mehrerer Server zu entkoppeln
Config.JitterSecondsMax = 45
