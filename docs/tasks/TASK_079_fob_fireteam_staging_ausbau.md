# TASK_079 – FOB: Fireteam-Management, Respawn-/Loadout-Staging und Dropship-Wartezone

## Ziel
Die FOB soll von der bisherigen kompakten Fireteam-Zuordnung zu einem klaren Mehrspalten-Screen ausgebaut werden: verfuegbare Operators links, Fireteam-Bildung in der Mitte, Respawn-/Loadout-Staging daneben und rechts eine Dropship-Wartezone.

## Pflicht vor Beginn
- Lies `docs/PROJECT_BRIEF.md`
- Lies `docs/ARCHITECTURE.md`
- Lies `docs/CODEX_RULES.md`
- Lies `docs/IMPLEMENTATION_STATUS.md`
- Lies `docs/tasks/TASK_076_meta_ui_kenney_grau.md`
- Lies `docs/tasks/TASK_077_fob_fireteam_auswahl.md`
- Lies `docs/tasks/TASK_078_meta_navigation_map_ansicht.md`
- Pruefe den Git-Status

## Abhaengigkeit
- TASK_078 muss implementiert sein.
- Die Homebase -> FOB -> Mission-Kette darf funktional erhalten bleiben.

## Ist-Zustand (nach TASK_078)
- Die FOB kennt bereits einen kleinen Fireteam-Prep-Schritt.
- Es gibt aber noch keine explizite Fireteam-Liste mit anlegbaren/loeschbaren Teams, kein eigenes Respawn-/Loadout-Staging pro Fireteam und keine Dropship-Wartezone.

## Aufgabe

### 1. FOB strukturell an Homebase-Muster annähern
- Fuehre oben einen Header im Stil des Mission Brief ein.
- Lege darunter vier klar lesbare Spalten an.

### 2. Fireteam-Management ausbauen
- `FT1` existiert immer.
- Weitere Fireteams koennen ueber `+` erzeugt und ueber `-` wieder entfernt werden.
- Der Fireteam-Name soll editierbar sein.
- Operators aus der linken Spalte muessen klar einem Fireteam zuordenbar sein.

### 3. Respawn-/Loadout-Staging einfuehren
- Fuer das aktuell fokussierte Fireteam soll ein kleiner stagingnaher Bereich fuer FOB-Respawn gesetzt oder geloescht werden koennen.
- Im selben Bereich soll optional ein einfacher Loadout-Preset pro Fireteam vorbereitet werden koennen.
- Der Pfad bleibt read-only/staging-first und muss noch keine tiefe Missionswirkung erhalten.

### 4. Dropship-Wartezone einfuehren
- Rechts soll eine Warteposition fuer das Dropship den aktuellen Zustand lesbar machen.
- Wenn ein Dropship kommt oder bereit ist, soll ein kleiner Timer-/Boarding-Zustand sichtbar werden.
- Keine echte Fahrzeug-Simulation einfuehren.

## Architekturhinweise
- Die FOB bleibt Meta-UI und nicht Gameplay-Wahrheit.
- Fireteam-, Respawn- und Loadout-Werte duerfen als klarer Meta-State gefuehrt werden, aber nicht als versteckte Simulationslogik.
- Kein neues grosses Squad- oder Inventarsystem bauen.

## Nicht-Ziele
- keine echte Dropship-Physik oder Transport-Simulation
- keine tiefe Ausruestungslogik
- keine unbegrenzten Teamgroessen
- keine Homebase-Rollenverlagerung zurueck in die FOB

## Akzeptanzkriterien
- Die FOB zeigt den neuen Mehrspaltenaufbau.
- `FT1` ist immer vorhanden; weitere Fireteams sind anleg- und loeschbar.
- Respawn- und Loadout-Staging pro Fireteam sind lesbar und bedienbar.
- Die Dropship-Wartezone zeigt einen nachvollziehbaren Timer-/Boarding-Zustand.

## Git-Schritte nach lokaler Pruefung
- `git status`
- `git add` nur relevante Dateien
- `git commit -m "Expand FOB into multi-column fireteam staging screen (TASK_079)"`
- `git push`
- `docs/IMPLEMENTATION_STATUS.md` erst nach Umsetzung aktualisieren