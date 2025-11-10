# 🗂️ Lyra City V – Projektstatus & To-Do

**Stand:** 1. November 2025

---

## 1️⃣ Basis / Framework

- ✅ Server läuft stabil
- ✅ OXLib + OXMySQL eingebunden
- ✅ Alle Ressourcen auf „LyraCityV“-Prefix umgestellt
- ⚙️ FXServer-Version / Build prüfen → Update bei Gelegenheit

---

## 2️⃣ Auth & Charakter-System

- ✅ Authentifizierung (Discord/DB-Verknüpfung) funktioniert
- ✅ Charakter-Datenbank mit Gender-Fix korrigiert
- ✅ Charakter-Spawn / Position-Save nach Auth-Load passt
- ⚙️ Kameraposition + PlayerFreeze → später Feintuning

---

## 3️⃣ Inventar-System _(aktueller Schwerpunkt)_

- ✅ AxisGe0-Basis läuft (DB-Fix + Tabellen-Rename)
- ⚙️ Item-Vergabe (`/giveitem`) getestet
- ⚙️ Brillen-Item (meta drawable/texture) in Arbeit
- ⬜ Drag-&-Drop-Mapping für Equip-Slots (Eyes, Torso, Legs …)
- ⬜ Rucksack-Slot (Stash) dynamisch je nach Tasche
- ⬜ Welt-Container (Radius-Scan / Open-World-Loot)

**Nächster Schritt:**  
Sonnenbrillen-Item fertigstellen + Equip-Slot-UI anzeigen

---

## 4️⃣ UI / Frontend

- ✅ Grundlayout vorhanden
- ⚙️ Style / Optik = CityV-Farbwelt bleibt
- ⬜ Waffen-Spalte links (Long/Short/Melee)
- ⬜ Equip-Spalte rechts
- ⬜ Welt-Slot-Anzeige (bei Container in Nähe)
- ⬜ Gewichtsanzeige / Kapazität

**Nächster Schritt:**  
Drag-&-Drop-Handler mit Server verkoppeln

---

## 5️⃣ Welt / Gameplay

- ✅ Welt-Sync (Zeit/Wetter) läuft – benötigt später Feintuning
- ⬜ Respawn/Koma-System (UI + Timer)
- ⬜ Unendliche Ausdauer checken
- ⬜ Fahrzeuge / Jobs → später

**Nächster Schritt:**  
Koma-Timer als eigene Resource aufbauen

---

## 6️⃣ Branding & Organisation

- ✅ Rebranding → **Lyra City V**
- ✅ Farbwelt beibehalten
- ✅ Discord-Bot umbenannt
- ⬜ Start-Screen Logo / Text aktualisieren
- ⬜ txAdmin-Servername prüfen

---

## 🧭 Zusammenfassung

Lyra City V läuft stabil und entwickelt sich stetig weiter.  
Nächster Meilenstein: **Inventar-System** mit sichtbaren Equip-Slots,  
funktionierendem Drag-&-Drop und Brillen-Item als Prototyp für das Outfit-System.
