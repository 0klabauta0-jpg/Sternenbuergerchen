# TASK_1085 - Stable First Exchange Visible State

## Status: IMPLEMENTIERT

## Ziel / Problem

Der Release-Direkteinstieg meldet unmittelbar einen bestandenen ersten Feuerwechsel, zeigt im echten Fenster nach dem normalen Capture-Wartefenster aber wieder `NEXT LOS/RANGE KORRIGIEREN`, `NO FIRE NO_LOS` und `CONTACT PRESSURE`. Der fuer 120 Sekunden vorgesehene read-only First-Exchange-Status erreicht die sichtbaren HUD-Flaechen nicht stabil.

## Ursache / Sinnhaftigkeit

TASK_832 prueft den unmittelbaren Deep-Link-Snapshot. Der echte TASK-837-Capture vom aktuellen Release `63667a71` belegt dagegen einen spaeteren sichtbaren Zustand. Damit widersprechen sich automatischer Gate-Snapshot und Spieleroberflaeche.

## Umfang

- Zeitversetzter Regressionstest fuer #17 Selected Fireteam, #18 Mission Control und #19 Event Log.
- Bestehende First-Exchange-Evidence und HUD-Refresh-Reihenfolge untersuchen und reparieren.
- Keine neue Combat-Wahrheit; sichtbare Persistenz bleibt read-only und stammt aus einem echten FireEvent.
- Echter Release-Window-Recapture nach dem Fix.

## Nicht-Ziele

- Kein kuenstliches Erzeugen eines Schusses im HUD.
- Kein dauerhafter Testtext in normalen Missionen.
- Kein Combat-, LOS- oder KI-Rewrite.
- Kein Multiplayer-State aus der UI.

## Akzeptanzkriterien

- Der erste Feuerwechsel ist nach mehreren normalen UI-/Combat-Refreshes weiter in #17 und #18 primaer lesbar.
- #19 zeigt den Feuerwechsel statt ihn durch eine spaetere generische Contact-Pressure-Fallbackzeile zu ersetzen.
- Die persistierte Leseschicht verweist auf ein echtes FireEvent und setzt keine Gameplay-Wahrheit.
- TASK_832, TASK_868, TASK_1084 und die Multiplayer-ROE-Kette bleiben gruen.
- Ein frischer Release-Screenshot zeigt den stabilen Zustand im echten Fenster.

## Betroffene Dateien

- `scripts/tests/mission_tactical_sandbox_controller.gd`
- gegebenenfalls eng begrenzte Meta-/HUD-Refresh-Bindings
- `scripts/tests/task_1085_stable_first_exchange_visible_state.gd`
- Status-, Roadmap-, Contract- und HTML-Berichtsdokumentation

## Lokale Pruefung

- `task_1085_stable_first_exchange_visible_state.gd`
- TASK_832, TASK_868, TASK_1084, TASK_1083, TASK_1082
- echter `capture_release_first_go_firefight_real_window.ps1`-Lauf
- `git diff --check`

## Risiken / offene Punkte

- Der sichtbare Feuerwechsel darf nicht laenger als seine dokumentierte Evidence-Dauer erscheinen.
- Ein spaeterer echter neuer Combat-Zustand muss die alte Evidence geordnet abloesen koennen.

## Ergebnis

- Der Capture wartet auf den vorhandenen Runtime-Trace und nimmt erst nach `deeplink_final / applied` auf. Der aktuelle Release brauchte dabei 51.457 ms bis zur belastbaren Sichtbereitschaft; dieser Wert ist nun explizite Folgearbeit statt versteckter Blind-Timer.
- Der zeitversetzte Verifier haelt #17, #18 und #19 auch nach wiederholten Refreshes auf derselben echten FireEvent-Evidence.
- Die primaere Zeile zeigt jetzt `CONTACT FIRE | FT1 -> PATROL | RIFLE ...` statt technischer `player_*`-/`ground_*`-IDs.
- Der historische TASK-862-Kompatibilitaetsaufruf baute Fireteam- und Strategic-Status im selben Refresh ein zweites Mal. Nach seiner Entfernung sank der isolierte First-Exchange-Sync in vergleichbaren Laeufen von rund 22,6 ms auf rund 0,5 bis 0,6 ms; Textzuweisung nutzt den bestehenden Delta-Helper.
- TASK_1085 ist 15/15 gruen. Der gesamte UI-Refresh schwankt weiter deutlich; Strategic-Status, Mission-Panels und Craft-Controls bleiben gemessene Folgegrenzen.
