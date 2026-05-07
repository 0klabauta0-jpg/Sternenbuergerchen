# TASK_287 - Editor Save Multiplayer Contract Regression Review

## Ziel
Editor-, Save/Load-, Szenario- und Multiplayer-Vertraege sollen nach den Tactical- und AirAsset-Erweiterungen nochmal gezielt geprueft werden. Authoringdaten, Runtime-State, persistenter Meta-State und Netzwerk-Snapshot duerfen nicht vermischt werden.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_155 - Mission Scenario Data Contract
- TASK_156 - Mission Editor Scenario Panel MVP
- TASK_228 - Multiplayer Editor Map Manifest Download Consent
- TASK_240 - Multiplayer Player Roster Ownership Contract
- TASK_280 - Tactical Profile Editor Scenario Authoring
- TASK_281 - Tactical Command Multiplayer Authority Snapshot
- TASK_284 - Gameplay Truth Architecture Boundary Audit

## Kontext
Taktikprofile und Air-Asset-Risiken werden authorbar und multiplayerrelevant. Das ist ein klassischer Ort fuer schiefe Pfade: Editor speichert Runtime-State, Savegame schreibt Map-Authoring um, Snapshot enthaelt private Characterdaten, oder Client darf Dinge setzen, die nur Host/Server duerfen.

## Umfang
1. Editor/Scenario:
   - MissionScenarioData enthaelt Authoringdaten.
   - Keine LZ-Runtime-Mutation im Szenario.
   - Taktikprofile validiert und fallbackfaehig.
2. Save/Load:
   - Roster, Character-Progression, AirAssetMeta und Settings getrennt.
   - Map-/Scenario-Dateien werden nicht durch laufende Mission ueberschrieben.
3. Multiplayer:
   - Command-Whitelist fuer Tactical/AirAsset.
   - Snapshot-Felder klein und deterministisch.
   - Ownership/Privacy fuer Roster/FTL-Skills.
4. Downloaded Maps:
   - Fremde Maps koennen Taktikprofile enthalten, aber nicht unsichere Pfade/Skripte.
   - Consent/Manifest bleibt gueltig.
5. Report:
   - contract mismatch, unsafe persistence, snapshot leak, editor-runtime bleed.

## Nicht-Ziele
- Kein Online-Security-Audit ueber Dateipfad-/Manifestschutz hinaus.
- Kein neuer Map-Download-Flow.
- Kein vollstaendiges Savegame-System, falls noch nicht umgesetzt.

## Akzeptanzkriterien
- [x] Editor-/Scenario-Daten enthalten keine laufende Runtime-Wahrheit.
- [x] Save/Load trennt Meta-, Roster-, Settings-, Map- und Mission-State.
- [x] Multiplayer-Snapshot enthaelt keine unnoetigen privaten Characterdaten.
- [x] Clients koennen Tactical/AirAsset-State nicht direkt setzen.
- [x] Downloaded Maps validieren Taktikprofile und Projekt-/User-Pfade sicher.
- [x] Report und Verifier decken Roundtrip- und Reject-Faelle ab.

## Erwartete Dateien
- `docs/reviews/editor_save_multiplayer_contract_regression_review.md`
- `scripts/tests/task_287_editor_save_multiplayer_contract_regression_review.gd`
- `docs/tasks/TASK_287_editor_save_multiplayer_contract_regression_review.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_287_editor_save_multiplayer_contract_regression_review.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_281_tactical_command_multiplayer_authority_snapshot.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_228_multiplayer_editor_map_manifest_download_consent.gd`
- [x] `git diff --check`

## Risiken
- Save-/Scenario-Grenzen koennen subtil sein; Report muss Datenbesitzer und Lebensdauer je Feld benennen.
- Multiplayer-Privacy darf Playability nicht so stark begrenzen, dass Teamstatus unklar wird.

## Ergebnis
- `docs/reviews/editor_save_multiplayer_contract_regression_review.md` dokumentiert die Boundary-Pruefung fuer Scenario/Editor, Local Saves, Settings, AirAssetMeta, Multiplayer-Commands, Snapshots und heruntergeladene Maps.
- `GameSettingsContract` persistiert nur noch bekannte Settings-Keys, damit Roster-/Map-/Runtime-Daten nicht versehentlich in die lokale Config laufen.
- `MultiplayerMapManifest` prueft heruntergeladene Map-Payloads rekursiv auf unsichere Script-/Pfad-Keys und validiert `enemy_team_configs`.
- `scripts/tests/task_287_editor_save_multiplayer_contract_regression_review.gd` deckt Roundtrip- und Reject-Faelle fuer alle Akzeptanzkriterien ab.

## Naechster Schritt
TASK_288 prueft, ob die Regression-Gates die gefundenen Risiken wirklich abdecken.
