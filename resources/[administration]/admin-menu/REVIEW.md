# Admin-Menü – Review & Härtung (v1.0.1)

**Ziele:** server‑autorisierte Rechte, Rate‑Limit, Zustandsverwaltung, saubere Events, Labels‑Cache.

## Wichtige Fixes
- **Open-Flow:** neuer Request `LCV:menu:requestOpen` (Server prüft → öffnet).
- **Permissions:** ACE (`adminmenu.open`) bevorzugt; Fallback: `playerManager.character.level >= 100`.
- **Rate‑Limit:** 600ms pro Event/Spieler.
- **States:** serverseitig für `invis/god/fly/label` + Cleanup bei Disconnect.
- **Labels:** Snapshot-Cache (2.5s), Name‑Sanitizing, interner Refresh‑Event.

## Client Änderungen
- Menütoggles senden nur noch **Server‑Events** (`LCV:admin:set…`). Anwendung erfolgt via `LCV:admin:update…` Events.
- F12 Bind (`lcv_adminmenu`) triggert `LCV:menu:requestOpen`.

## Integration
- In `server.cfg` ACE eintragen:
  ```
  add_ace resource.lyracityv-adminmenu command.adminmenu allow
  add_ace group.adminmenu adminmenu.open allow
  add_principal identifier.license:YOURLICENSE group.adminmenu
  ```

Viel Spaß beim Testen!