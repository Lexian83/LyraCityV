# LyraCityV – Module & Resource Übersicht

Ziel dieser Datei:

- Übersicht aller relevanten Module/Resources im aktuellen Repo-Stand
- Kurzbeschreibung der Funktion
- Welche Events / Exports sie anbieten (faktische API)
- Welche Dependencies sie haben
- Wie sie in den Core-Flow passen

> Hinweis: Diese Übersicht basiert auf dem aktuellen Stand des Repos `Lexian83/LyraCityV` und den darin enthaltenen Kern-Ressourcen (`auth`, Charselect, Character-Editor) sowie den SQL-Schemata. Einige globale Hilfen (z. B. `LCV.Util`, `LCV.Accounts`) liegen als eigene Module vor, werden hier aber nur soweit beschrieben, wie sie aus der Verwendung ersichtlich sind.

---

## 0. Projektstruktur (Top-Level)

**Verzeichnisse (lt. Repo):**

- `DATABASE/`
- `DOCS/`
- `cache/` (bzw. `cache/ files`)
- `resources/`
- `.gitignore`
- sonstige Meta-Files

Die funktionale Logik sitzt hauptsächlich in:

- `DATABASE` (DB-Schema)
- `resources` (FiveM-Resources)
- plus globale `LCV.*`-Hilfsstrukturen, die von mehreren Ressourcen verwendet werden.

---

## 1. Core Auth – `auth`

**Datei:** `resources/.../auth.lua` :contentReference[oaicite:0]{index=0}  
**Rolle:** Einstiegspunkt beim Connect, Discord-Check, Account-Verwaltung.

### Aufgaben

- Verarbeitet `playerConnecting`:

  - Liest Convars für Discord-Bot/Guild.
  - Fragt Discord-API ab bzw. nutzt Cache (`LCV.getCachedRoles`).
  - Prüft Rollen / Bann-Rollen.
  - Legt bei Bedarf neue Accounts in `accounts` an (`LCV.Accounts.insert`).
  - Aktualisiert `last_login` (`LCV.Accounts.updateLastLogin`).

- Verarbeitet `playerJoining`:

  - Mappt den Spieler auf seinen `accounts.id` (Active-Session-State).

- Öffnet nach dem ersten vollständigen Spawn den Charselect:

  - `LCV:playerSpawned` → `TriggerEvent('LCV:charselect:load', src, account_id)`.

- Bietet Event-basierte Character-Selection:
  - `LCV:selectCharacterX`:
    - prüft Besitz via `LCV.Characters.selectOwned`
    - lädt Full-Data via `LCV.Characters.getFull`
    - setzt Routing Bucket
    - sendet `LCV:spawn` mit vollständigen Character-Daten an den Client. :contentReference[oaicite:1]{index=1}

### Wichtige Dependencies

- `LCV.Util` (Logging, HTTP, JSON, Identifier-Parsing).
- `LCV.Accounts` (DB-Abstraktion für `accounts`).
- `LCV.Characters` (DB-Abstraktion für `characters`).
- Discord API (über HTTP-Requests).
- `oxmysql` (indirekt über `LCV.*`-Module).

### Öffentliche API (Events)

**Server Events (wird von außen aufgerufen / relevant):**

- `LCV:playerSpawned`

  - Wird typischerweise vom Client nach Network-Ready ausgelöst.
  - Öffnet Charselect für den aktiven Account.

- `LCV:selectCharacterX (charId)`
  - Aus Charselect-UI.
  - Setzt aktiven Charakter & triggert Spawn-Daten (`LCV:spawn`).

**Client Events (gesendet von auth):**

- `LCV:error (msg)`

  - Generische Fehlermeldung an UI.

- `LCV:spawn (data)`
  - Enthält: Char-ID, Name, Gender, Stats, Position, Clothes, Appearance etc.
  - Wird vom Spawn-/Core-System auf Clientseite verarbeitet.

### Exports

- Aktuell **keine FiveM-`exports`** in `auth`.
- Integration läuft **ausschließlich über Events** und globale `LCV.*`-Helper.

---

## 2. Charselect – `charselect`

**Dateien (aus Repo & Chat):**

- `resources/.../charselect/fxmanifest.lua`
- `resources/.../charselect/server.lua` :contentReference[oaicite:2]{index=2}
- `resources/.../charselect/client.lua` :contentReference[oaicite:3]{index=3}
- `resources/.../charselect/ui/index.html`, `app.js`, `styles.css`, etc.

### Aufgaben

- Zeigt eine NUI-Übersicht aller Charaktere eines Accounts.
- Steuert:
  - Character-Liste
  - „Neuen Charakter erstellen“-Button (solange `accounts.new = 1` und < Max-Slots)
  - Char-Auswahl und Übergabe an das Spawn-/Core-System.

### Server-seitige Logik / API

**Event:** `LCV:charselect:load (targetSrc, accountId)`

- Einstiegs-Event aus `auth` oder dem Character-Editor.
- Ermittelt `src` (korrekt auch, wenn intern `TriggerEvent` genutzt wird).
- Ruft `buildPayload`:
  - Holt `accounts.new` aus `accounts`.
  - Lädt alle `characters` mit `account_id = accounts.id`. :contentReference[oaicite:4]{index=4}
- Sendet:
  - `LCV:charselect:show (payload, accountId)` an den Client.
- Setzt optional `SetPlayerRoutingBucket(src, accountId)`.

**Event:** `LCV:charselect:reload ()`

- Baut Payload für den aufrufenden Spieler neu.
- Schickt erneut `LCV:charselect:show`.

**Event:** `LCV:charselect:close ()`

- Schließt NUI (Server → Client).

**Event:** `LCV:charselect:select (charId)`

- Validiert:
  - Charakter existiert.
  - `is_locked == 0`.
- Bei Erfolg:
  - `LCV:charselect:close`.
  - `TriggerEvent('LCV:charselect:spawn', src, charId)` → Hook für dein Spawn-System.

### Client-seitige Logik / API

**Event:** `LCV:charselect:show (payload, accountId)`

- Öffnet das UI:
  - `exports.inputmanager:LCV_OpenUI('charselect')`
  - `SendNUIMessage({ action = 'setData', payload })`
  - `SendNUIMessage({ action = 'open' })`
  - Setzt NUI-Fokus, beendet Loading-Screen.

**Event:** `LCV:charselect:close`

- Schließt UI, gibt Fokus & Steuerung frei.

**NUI Callbacks:**

- `createCharacter`

  - Schließt Charselect.
  - `TriggerServerEvent('character:Edit', _, accountId)`
  - → Öffnet Character-Editor.

- `selectCharacter`

  - Schließt Charselect.
  - `TriggerServerEvent('LCV:selectCharacterX', data.id)`
  - → Übergibt an `auth` / Character-System.

- `close`
  - Nur UI zu, Event `LCV:charselect:closed`.

### Exports

- **Keine eigenen `exports`**.
- Externe Integration ausschließlich über:

  - `LCV:charselect:load`
  - `LCV:charselect:reload`
  - `LCV:charselect:select`
  - `LCV:charselect:spawn` (Hook, von anderen Ressourcen zu implementieren)

---

## 3. Character Editor – `chareditor` (oder `charactereditor`)

**Dateien (aus Repo/Chat):**

- `resources/.../chareditor/fxmanifest.lua`
- `resources/.../chareditor/startup.lua` (Server) :contentReference[oaicite:5]{index=5}
- `resources/.../chareditor/editor.lua` (Client)
- `resources/.../chareditor/ui/index.html`, `app.js`, `style.css`, etc.

### Aufgaben

- NUI-basierter Editor für:
  - Aussehen (Heritage, Gesichtsstruktur, Overlays, Haare, etc.)
  - Identität (Name, Geburtsdatum, Herkunft, Background/Past)
  - Start-Kleidung
- Persistiert neuen Charakter in `characters`.
- Führt nach Speichern zurück in das Charselect.

### Server-seitige API (`startup.lua`)

**Event:** `character:Edit (oldData, account_id)`

- Öffnet Editor beim Spieler:
  - `TriggerClientEvent('character:Edit', src, oldData, account_id)`

**Event:** `character:Done (data, account_id)`

- Erwartet Struktur:
  - `data.data` → Aussehen
  - `data.identity` → fname, sname, birthdate, country, past
  - `data.clothes` → Kleider-Objekt
- Schreibt in `characters`:
  - `account_id = account_id`
  - `name = "Nachname,Vorname"`
  - `gender = data.data.sex`
  - `heritage_country = data.identity.country`
  - Defaults für Health/Needs/Pos/etc.
  - `appearance` = JSON
  - `clothes` = JSON
  - `past`, `residence_permit`, `created_at` etc. :contentReference[oaicite:6]{index=6}
- On success:
  - `TriggerClientEvent('character:SaveSuccess', src, id)`
  - `TriggerEvent('LCV:charselect:load', src, account_id)` → zurück zur Auswahl.

**Event:** `character:AwaitModel (characterSex)`

- Wählt passendes Freemode-Modell.
- Sendet:
  - `character:SetModel`
  - `character:FinishSync`

**Event:** `character:Sync (data, clothes)`

- Wird während der Bearbeitung aufgerufen.
- Parsed Daten und schickt:
  - `character:SetModel`
  - `character:Sync` (Client) zur Live-Vorschau.

### Client-seitige API (`editor.lua`)

**Event:** `character:Edit (oldData, account_id)`

- Öffnet Editor-NUI:
  - `exports.inputmanager:LCV_OpenUI('chareditor')`
  - Setzt Kamera, freeze, blendet Map aus etc.

**Event:** `character:SetModel (model)`
**Event:** `character:Sync (data, clothes)`
**Event:** `character:FinishSync`

**NUI Callbacks:**

- `character:Done`

  - Sendet finalen Datensatz an `character:Done` (Server).
  - Schließt Editor.

- `character:Sync`

  - Periodische Live-Updates.

- `character:Cancel`
  - Aktuell: sollte nur Editor schließen; (im Code bitte sicherstellen, dass hier kein Dummy-Char gespeichert wird).

### Exports

- Keine FiveM-`exports`.
- API ist Event-basiert (`character:*` + Rückgabe via `LCV:charselect:load`).

---

## 4. Datenbank – `DATABASE/`

### 4.1 `accounts.sql` :contentReference[oaicite:7]{index=7}

**Tabelle `accounts`**

- `id` (INT, PK, AI)
- `username` (aktuell NOT NULL; in der Praxis ggf. anpassen)
- `discord_id` (UNIQUE)
- `hwid`
- `steam_id`
- `password_hash` (Legacy)
- `last_login` (DATETIME, default `CURRENT_TIMESTAMP`)
- `created_at` (DATETIME, default `CURRENT_TIMESTAMP`)
- `new` (TINYINT(1), default `1`)

**Verwendet von:**

- `auth` (Anlage/Update)
- `charselect` (Steuerung `canCreate`)
- `chareditor` (setzt `new = 0` nach Creation)

### 4.2 `characters.sql` :contentReference[oaicite:8]{index=8}

**Tabelle `characters`**

- `id` (INT, PK, AI)
- `account_id` (FK → `accounts.id`, ON DELETE CASCADE)
- `name`
- `gender`
- `heritage_country`
- `health`, `thirst`, `food`
- `pos_x`, `pos_y`, `pos_z`, `heading`, `dimension`
- `created_at`
- `level`
- `birthdate`
- `type`
- `is_locked`
- `appearance` (JSON)
- `clothes` (JSON)
- `residence_permit`
- `past`

**Verwendet von:**

- `charselect` (Anzeige + Auswahl)
- `chareditor` (Insert)
- `auth` / `LCV.Characters` (Full-Load & Spawn-Daten)

---

## 5. Weitere Elemente / Helpers

### 5.1 `LCV.Util`, `LCV.Accounts`, `LCV.Characters`

Diese sind im Repo als globale Hilfs-/Core-Module angelegt (aus `auth.lua` und Co. ersichtlich). Kernverhalten:

- `LCV.Util`

  - Logging (`LCV.Util.log`)
  - Identifier-Parsing (`extractIdentifier`)
  - HTTP Requests
  - kleine Helfer (JSON, Deferrals-Flow)

- `LCV.Accounts`

  - `getByDiscord(discord_id)`
  - `insert(steam, discord, hwid, now, cb)`
  - `updateLastLogin(id, now, cb)`

- `LCV.Characters`
  - `selectOwned(charId, accountId, cb)`
  - `getFull(charId, accountId, cb)`

Diese fungieren als interne API-Schicht; sie werden über das globale `LCV`-Objekt genutzt und nicht als FiveM-`exports` im klassischen Sinne (soweit aus dem Code ersichtlich).

### 5.2 `inputmanager`

Wird mehrfach referenziert:

- `exports.inputmanager:LCV_OpenUI('charselect')`
- `exports.inputmanager:LCV_CloseUI('charselect')`
- `exports.inputmanager:LCV_OpenUI('chareditor')`

Das ist eine externe/zusätzliche Resource, die:

- NUI-Fokus & Z-Stack verwaltet,
- sauberes Öffnen/Schließen von UIs mit einheitlicher API anbietet.

Die konkrete Doku dazu kannst du ergänzen, sobald das Modul final ist.

### 5.3 `cache/`

Das `cache/`-Verzeichnis im Repo wirkt aktuell wie ein technischer Ablageort (z. B. generierte Files, temporäre Inhalte).  
Es stellt nach jetzigem Stand **keine API** nach außen bereit.

---

## 6. Integration & Exports – Zusammenfassung

### Events als primäre Schnittstelle

Dein Projekt nutzt konsequent Events als modulare API:

- Login → `LCV:charselect:load`
- Charselect → `LCV:selectCharacterX` → `LCV:spawn`
- Charcreate → `character:Edit` / `character:Done` → `LCV:charselect:load`

### FiveM-Exports

Im aktuellen Stand der Kernmodule:

- **auth** – keine eigenen Exports
- **charselect** – keine eigenen Exports
- **chareditor** – keine eigenen Exports

Verwendete Fremd-Exports:

- `exports.inputmanager:LCV_OpenUI(...)`
- `exports.inputmanager:LCV_CloseUI(...)`
- `exports.oxmysql:*` (DB)

Wenn du möchtest, können wir in einem nächsten Schritt eine klare Export-Schicht für z. B. `LCV.Accounts` und `LCV.Characters` definieren (`exports['lcv_core']:GetAccountByDiscord(...)` etc.), damit externe Ressourcen nicht direkt auf globale Tabellen zugreifen müssen.

---
