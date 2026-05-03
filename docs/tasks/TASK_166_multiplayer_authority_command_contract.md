# TASK_166 - Multiplayer Authority Command Contract

## Ziel
Multiplayer bekommt zuerst einen harten Authority- und Command-Vertrag: Clients senden nur erlaubte Commander-/FTL-Commands, der Server validiert und committed ueber `SimulationRoot`.

## Status: IMPLEMENTIERT

## Pflicht vor Beginn
- Lies `docs/PROJECT_BRIEF.md`
- Lies `docs/ARCHITECTURE.md`
- Lies `docs/CODEX_RULES.md`
- Lies `docs/IMPLEMENTATION_STATUS.md`
- Lies `docs/tasks/TASK_050_server_simulation_root.md`
- Lies `docs/tasks/TASK_052_befehle_netzwerk.md`
- Lies `docs/reviews/strategic_review_ui_assets_multiplayer_2026_05_03.md`
- Pruefe den Git-Status

## Kontext
- `SimulationRoot.request_command()` existiert bereits als `@rpc("any_peer", "reliable")`.
- Server-authoritative Mode ist im Code angelegt.
- Was fehlt, ist ein expliziter Multiplayer-Command-Contract mit Validation und Peer-Rechten.

## Umfang
1. Command-Whitelist definieren:
   - Move
   - Defend/Hold
   - Take
   - Attack Area
   - Defend Area
   - Ad-hoc Orders
   - Dropship/LZ nur soweit im aktuellen Gameplay erlaubt
2. Peer-Rechte definieren:
   - Host/Server
   - Commander
   - Fireteam-Zuordnung
   - Spectator/Observer spaeter nur geplant
3. Validation in oder vor `SimulationRoot.request_command()`:
   - command_type bekannt
   - fireteam/unit ownership erlaubt
   - target/payload plausibel
   - keine LZ aus Szenario-/Editor-Daten
   - keine Client-Setzung von Damage, Objective, Vital, Position als Wahrheit
4. Ablehnungen sichtbar loggen und testbar machen.

## Nicht-Ziele
- Kein Lobby-Redesign.
- Keine Snapshot-Replikation.
- Kein Prediction-System.
- Kein Matchmaking.

## Architekturregeln
- Server verarbeitet Commands/Effects.
- Clients halten keine Gameplay-Wahrheit.
- UI darf keine autoritativen Positions-/Combat-/Objective-Werte setzen.

## Akzeptanzkriterien
- Remote-Commands laufen durch eine dokumentierte Whitelist.
- Ungueltige oder fremde Commands werden abgelehnt.
- Gueltige Commands werden serverseitig enqueued.
- Singleplayer-Pfad bleibt unveraendert nutzbar.
- Verifier prueft mindestens erlaubten Move und abgelehnten Fremd-/State-Mutation-Command.

## Ergebnis
- `scripts/multiplayer/multiplayer_command_contract.gd` definiert den Multiplayer-Command-Vertrag fuer Unit-, Commander-, Area-, Ad-hoc- und Dropship-Commands.
- `SimulationRoot.request_command()` validiert im server-authoritativen Modus jetzt ueber diesen Vertrag, enqueued nur akzeptierte Payloads und fuehrt Reject-Zaehler plus letzten Ablehnungsgrund im Contract-Snapshot.
- Peer-Rechte sind fuer Host, Commander, Fireteam-Zuordnung und Spectator vorbereitet. Team- und Fireteam-Zuweisungen bleiben in `SimulationRoot` und koennen von TASK_167 angebunden werden.
- `docs/dev/multiplayer_authority_command_contract.md` dokumentiert Whitelist, Rollen, harte Rejects und die Trennung zu Snapshot-Replikation.

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_166_multiplayer_authority_command_contract_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_160_tactical_playability_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_117_verifier.gd`
- [x] `git diff --check`

## Risiken
- Zu fruehe UI-Arbeit ohne Contract erzeugt spaeter Sicherheits- und Desync-Schulden.
- Bestehende Testpayloads duerfen nicht versehentlich als Netzwerkpayloads erlaubt werden.
