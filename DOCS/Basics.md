# 🔷 City Live V 🔷

**GTA-V Roleplay Projekt – FiveM / CFX.re**

---

## 🧩 Projektübersicht

| Info               | Inhalt                                                                                                                               |
| ------------------ | ------------------------------------------------------------------------------------------------------------------------------------ |
| **Name**           | LyraCityV                                                                                                                            |
| **Status**         | Planung                                                                                                                              |
| **Version**        | 0.1 (Pre-Alpha)                                                                                                                      |
| **Letztes Update** | 18.10.2025                                                                                                                           |
| **Beschreibung**   | Ein GTA-V Rollenspiel-Server, aufgebaut von Grund auf – ohne fertige Frameworks. Fokus auf Verständnis, Struktur und eigene Systeme. |

---

## ⚙️ Technik-Stack

- **Plattform:** FiveM / CFX.re
- **Datenbank:** MySQL (via XAMPP / PhpMyAdmin)
- **Frontend / UI:** Vite + React
- **Hygiene:** Keine fertigen Frameworks oder Scripte _(Ausnahme: technische Hilfsbibliotheken wie OxSQL)_
- **Editor:** VS Code 2025

---

## 🗂️ Projektstruktur

📁 resources/
├── [system] → Basissysteme (Auth, Configs, Utils)
├── [managers] → Manager für NPCs, Fahrzeuge, Spieler, Fraktionen
├── [gameplay] → Jobs, Housing, Garage, Economy usw.

## 🧮 Datenbankstruktur

| Tabelle              | Beschreibung                                                                                                                    |
| -------------------- | ------------------------------------------------------------------------------------------------------------------------------- |
| **Accounts**         | ID, Steam-ID, Discord-ID, HWID, RegisterDate, LastLogin                                                                         |
| **Characters**       | ID, AccountID, Name, Birthdate, Gender (0=f, 1=m), Dimension, PosX/Y/Z, Health, Thirst, Food, ActiveFraction, Underware, Online |
| **Items**            | ItemID, Name, Weight, Type                                                                                                      |
| **Inventory**        | CharID, ItemID, Quantity                                                                                                        |
| **Vehicel**          | OwnerID, Model, Plate, Position                                                                                                 |
| **Housing**          | OwnerID, Address, InteriorType                                                                                                  |
| **Garage**           | CharID, Slot, VehicleID                                                                                                         |
| **Fractions**        | ID, Name, Type                                                                                                                  |
| **Fraction_Ranks**   | FractionID, RankName, Level                                                                                                     |
| **Fraction_Members** | FractionID, CharID, RankID                                                                                                      |
| **Keybinds**         | CharID, Action, Key                                                                                                             |
| **Blips**            | Name, PosX/Y/Z, Icon, Color                                                                                                     |
| **Doors**            | ID, Pos, Locked, Owner                                                                                                          |
| **NPCs**             | ID, Type, Pos, Dialog                                                                                                           |
| **Files**            | FileID, Type, Path, CreatedAt                                                                                                   |
| **BankAccounts**     | OwnerID, Balance                                                                                                                |
| **BankLog**          | AccountID, Action, Amount, Timestamp                                                                                            |
| **SystemLog**        | Event, Message, Timestamp                                                                                                       |
| **Task**             | ID, Description, Priority, Done                                                                                                 |

**Beziehungen (Beispiele):**

- `Characters.AccountID → Accounts.ID`
- `Fraction_Members.CharID → Characters.ID`
- `Fraction_Members.FractionID → Fractions.ID`

---

## 🧭 Projektplanung (bisher)

1. GTA-V via Steam installiert ✔️
2. FiveM Client installiert ✔️
3. FiveM Server (Basic Template, ohne ESX) installiert ✔️
4. Server konfiguriert
5. XAMPP installiert ✔️
6. VS Code 2025 installiert ✔️
7. Verbindungstest Server <-> Client ✔️
8. `resources`-Verzeichnis aufgeräumt ✔️
9. Ordnerstruktur angelegt ([system], [managers], [gameplay])
10. Account-Tabelle erstellt
11. Discord-Login (Whitelist-basierend, alle Rollen außer „Ausgebürgert“ erlaubt)

---

## 🧱 Projektregeln

1. Ich bin **absoluter Anfänger**.
2. **Klare, kleine Schritte** von Lyra.
3. **Gut erklärte Anweisungen** – keine Fachbegriffe ohne Erklärung.
4. **Sauberes Coding:** wenig oder keine Dummylösungen.
5. **Große Aufgaben** werden in kleine Teilaufgaben zerlegt.
6. **Motivation ist empfindlich.** Kleine Erfolge sind wichtig!
7. **Klare Ziele** vor jedem neuen Schritt.

---

## ✅ To-Do Liste

- [x] Datenbank anlegen
- [x] Discord-Login implementieren
- [x] Charakter-Auswahlmenü
- [ ] Inventarsystem (DB + UI)
- [ ] Housing & Garage (Owner-System)
- [ ] Fraktionssystem (Ranks + Permissions)
- [ ] Bank / Wirtschaftssystem
- [ ] Server-UI (React + API)

---

### 💬 Anmerkung

> Dieses Projekt wird von Grund auf aufgebaut – mit Geduld, Lernfokus und Spaß.  
> Ziel ist es, jedes System **selbst zu verstehen und zu dokumentieren**, nicht einfach zu kopieren.

---

© 2025 – _LyraCityV by Jens_  
Mit Liebe und Struktur entwickelt 💙
