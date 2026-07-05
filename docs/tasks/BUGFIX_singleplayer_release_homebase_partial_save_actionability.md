# BUGFIX - Singleplayer Release Homebase Partial Save Actionability

## Ziel / Problem
Der exportierte Einzelspieler-Start kann trotz bestehendem Bootstrap in einer blockierten Homebase landen, wenn ein alter oder halbvoller lokaler Save bereits Roster-/Fireteam-Daten enthaelt, aber Pilot, Dropship oder Flightdeck-Payload fehlen.

## Ursache
Der bisherige Bootstrap repariert nur komplett leere Roster. Ein teilgueltiger User-Save verhindert den Preset-Fallback, kann aber trotzdem keinen Dropship-Start liefern. Ausserdem wurde der Flightdeck-Payload immer mit der statischen Bootstrap-Fireteam-ID gesetzt, auch wenn die sichtbare Homebase ein anderes/normalisiertes Fireteam als erstes spielbares Team fuehrt.

## Umfang
- Lokale Singleplayer-Saves fuer den Release-Start idempotent auffuellen, wenn Pilot oder spielbare Fireteam-Mindestdaten fehlen.
- Fehlende Preset-Operatoren additiv ergaenzen, ohne bestehende User-Operatoren zu ueberschreiben.
- Flightdeck-Payload mit dem tatsaechlich gestagten Bootstrap-Fireteam seeden.
- Regressionstest fuer einen halbkaputten lokalen Startzustand ergaenzen.

## Nicht-Ziele
- Kein Save-Reset.
- Kein neues Kampagnen-/Roster-System.
- Keine UI als Gameplay-Wahrheit; die Reparatur bleibt in der Meta-Flow-Schicht.

## Relevante Contracts / Dokumente
- `docs/ARCHITECTURE.md`
- `docs/tasks/BUGFIX_singleplayer_release_homebase_start_bootstrap.md`

## Akzeptanzkriterien
- Ein halbvoller Startzustand ohne Pilot wird mit einem Preset-Pilot ergaenzt.
- Der Einzelspieler-Start zeigt nach Bootstrap ein Dropship, Payload-Operatoren, geboardete Operatoren und einen aktiven `Start Mission`-Button.
- Der bestehende Main-Menu-Pfad bleibt gruen.

## Betroffene Dateien
- `scripts/meta/meta_layer_flow.gd`
- `scripts/tests/bugfix_singleplayer_release_homebase_start_bootstrap.gd`
- `docs/tasks/BUGFIX_singleplayer_release_homebase_partial_save_actionability.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/bugfix_singleplayer_release_homebase_start_bootstrap.gd`
- `git diff --check`

## Risiken / offene Punkte
- Bestehende kaputte Saves werden nur fuer den Startpfad additiv aufgefuellt. Ein spaeterer Kampagnenmodus braucht eine bewusste Save-Migration und ein besseres Onboarding.
