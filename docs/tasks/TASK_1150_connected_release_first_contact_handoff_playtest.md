# TASK_1150 - Connected Release First Contact Handoff Playtest

## Ziel / Problem
Der echte Release-Multiplayer ist bis Drop, Deboard und erste angenommene Blue-/Gold-Bewegungsentscheidung belegt. Noch nicht als zwei exportierte Prozesse belegt ist der anschliessende Spielerweg bis Ankunft, Kontakt und erstem taktischen Feuer-Handoff.

## Umfang
- Bestehenden Release-Host/Client-Harness nach dem ersten GO zustandsbasiert weiterlaufen lassen.
- Fuer Blue und Gold Ankunft beziehungsweise fortgesetzte Bewegung, ersten Kontakt und Combat-/ROE-Handoff lesen.
- Host-/Client-Konvergenz und lokale Fireteam-Perspektive im Trace festhalten.
- 1600x900-Fensterbilder am ersten verbundenen Kontakt erzeugen.

## Nicht-Ziele
- Kein Combat-, Contact-, Navigation- oder Snapshot-Rewrite.
- Keine neue Testmission und keine automatisierte Balanceentscheidung.
- Keine UI-Wahrheit oder Sonder-RPCs fuer den Harness.

## Akzeptanzkriterien
- Beide Release-Prozesse bleiben verbunden und sehen denselben autoritativen Missionsfortschritt.
- Der lokale Fireteam-Kontext bleibt Blue beim Host und Gold beim Client.
- Kontakt und Feuerentscheidung sind aus vorhandenen Snapshots/Feedback nachvollziehbar.
- Das Gate wartet auf fachliche Zustandsbedingungen statt feste Blind-Wartezeit.

## Betroffene Dateien
- voraussichtlich `scripts/ui/multiplayer_lobby_screen.gd`
- `scripts/tools/capture_release_host_client_entry_playtest.ps1`
- fokussierte Verifier unter `scripts/tests/`
- Status, Roadmap und HTML-Handbuch

## Lokale Pruefung
- TASK_1149 und TASK_1148-Regressionen
- vorhandene Connected-Contact-/Combat-Handoff-Verifier
- TASK_222 Performance Gate
- echter Zwei-EXE-Release-Recapture

## Risiken / offene Punkte
Der erste Kontakt kann je nach Wegdauer und KI-Tick spaeter eintreten. Der Harness braucht deshalb einen fachlichen Timeout und aussagekraeftige Zwischenstufen, darf aber keine Simulation beschleunigen oder Gameplay-State setzen.
