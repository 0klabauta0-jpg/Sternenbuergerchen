# TASK 045 – Gegner-Wellen

## Ziel
Enemies sollen in einfachen Wellen erscheinen statt alle gleichzeitig am Anfang zu spawnen, damit die Mission laenger und spannender bleibt.

## Pflicht vor Beginn
- Lies `docs/PROJECT_BRIEF.md`
- Lies `docs/ARCHITECTURE.md`
- Lies `docs/CODEX_RULES.md`
- Lies `docs/IMPLEMENTATION_STATUS.md`
- Pruefe den Git-Status

## Abhaengigkeit
- TASK_043 (Gegner-Positionierung) muss vorher implementiert sein.

## Ist-Zustand (nach TASK_043/044)
- Alle Enemy-Units spawnen bei Missionsstart gleichzeitig.
- Enemies ruecken Richtung Objective vor und reagieren auf Kontakt.
- `RespawnManager` verwaltet Respawns nach Elimination, aber es gibt keine Wave-Logik.

## Aufgabe

### 1. Wave-Controller
- Neuer kleiner Node `EnemyWaveController` unter `res://scripts/tests/enemy_wave_controller.gd`.
- Export-Properties:
  - `wave_count: int` (z.B. 3) – Anzahl der Wellen
  - `units_per_wave: int` (z.B. 2) – Units pro Welle
  - `wave_delay_seconds: float` (z.B. 45.0) – Zeit zwischen Wellen
  - `first_wave_delay_seconds: float` (z.B. 5.0) – Verzoegerung vor erster Welle
- Signale: `wave_started(wave_number: int)`, `all_waves_complete`.

### 2. Spawn-Steuerung
- Bei Missionsstart sind nur die Units der ersten Welle aktiv (sichtbar, registriert, bewegen sich).
- Weitere Enemy-Units bleiben unsichtbar und inaktiv bis ihre Welle startet.
- Wenn eine Welle startet: Units werden sichtbar, an Spawn-Position gesetzt, im `UnitRegistry` registriert und starten den Vormarsch.

### 3. Integration in Testszene
- `MissionTestSetup` bekommt eine Referenz auf den `EnemyWaveController`.
- Die bestehenden Enemy-Units in der Szene werden den Wellen zugeordnet (z.B. EnemyAlpha + EnemyBravo = Wave 1, weitere spaeter hinzufuegbare Units = Wave 2+).
- Fuer V1 reicht es, wenn die Szene nur 2 Wellen mit je 1–2 Units zeigt.

### 4. Sichtbares Feedback
- Kleines Label in der Szene: `"WAVE 1/3"` – aktuelle Welle und Gesamtzahl.
- Bei Wellenstart: kurzer Event-Text wie `"ENEMY REINFORCEMENTS"`.

### 5. Siegbedingung anpassen
- Die Siegbedingung (aus TASK_041) muss beruecksichtigen, dass weitere Wellen kommen.
- Elimination-Sieg erst wenn alle Wellen erschienen sind UND alle Enemies eliminiert sind.

## Nicht-Ziele
- keine dynamische Wellenstaerke basierend auf Spielerleistung
- keine verschiedenen Enemy-Typen pro Welle
- keine Spawn-Richtungswahl
- keine Boss-Wellen

## Akzeptanzkriterien
- Enemies erscheinen in konfigurierbaren Wellen mit Zeitverzoegerung
- Nicht-gespawnte Units sind unsichtbar und inaktiv
- Wave-Nummer ist in der Szene sichtbar
- Elimination-Sieg funktioniert nur nach letzter Welle
- Objective-Capture-Sieg funktioniert unabhaengig von Wellen
- Bestehende Respawn-Logik fuer bereits gespawnte Units bleibt intakt

## Git-Schritte nach lokaler Pruefung
- `git status`
- `git add` nur relevante Dateien
- `git commit -m "Add enemy wave spawning system (TASK_045)"`
- `git push`
- `docs/IMPLEMENTATION_STATUS.md` aktualisieren
