# TASK_509 - Combined Preview Overlay

## Ziel / Problem
Ghost, Pfad, Gefahrenfarbe und Line-of-Fire sollen in einer gemeinsamen Anzeige sichtbar werden.

## Umfang
- `FireteamOrderVisualizer` zeichnet Risk-Farben und Line-of-Fire-Debuglinien aus dem Preview-Payload.
- `TerrainMap3DView` zeichnet Ghost-Marker, Pfadlinien, Threat-Linien und ein kurzes Label in der Primary View.
- Render-Snapshot bekommt Preview-Zaehler.

## Nicht-Ziele
- Keine neue HUD-Wahrheit.
- Keine per-frame Komplett-Rebuilds.

## Akzeptanzkriterien
- Ein Preview mit Threat-Daten erzeugt Path-Line und Threat-Line-Zaehler.
- Die Anzeige nutzt Gruen/Gelb/Rot/Grau/Orange gemaess Contract.

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_506_tactical_decision_clarity_contract.gd`
- `git diff --check`

## Risiken / offene Punkte
- Finale Art-Direction und manuelle F6-Sichtpruefung bleiben sinnvoll.
