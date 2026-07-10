# TASK_1057 - Controlled Dropship Inbound to Deboard Trace

## Ziel / Problem

Den Homebase-zu-Mission-Transport mit mehreren Direkt-Dropships kontrolliert bis zum Deboarding verfolgen. Der bestehende Mehr-Dropship-Regressionstest zeigt, dass ein spaet gestartetes zweites Dropship seinen vollstaendigen Fireteam-Payload nicht sicher in den aktiven MissionSetup-Vertrag uebernimmt.

## Ursache / Sinnhaftigkeit

Ein frueher Trace belegt fuer einen einzelnen Transfer den korrekten Pending-/Sequence-Payload nach Ankunft. TASK_396 zeigt dagegen 10/12 gruen: Bei Alpha plus Beta fehlt mindestens ein Beta-Operator in der Missionsauswahl. Bevor eine Korrektur erfolgt, muss die Datenkette Homebase-Card -> Meta-Planning -> MissionSetup sichtbar verglichen werden.

## Umfang

- Read-only Grenzschicht-Trace fuer das zweite Direkt-Dropship im bestehenden Reproduktionstest.
- Isolierte Korrektur ausschliesslich in der autoritativen Meta-/Planning-Uebergabe, falls der Trace den Verlust dort belegt.
- Danach Test von MissionSetup, Runtime-Slots, Karten, Inbound und Deboarding.

## Nicht-Ziele

- Kein Rewrite des Dropship-Systems.
- Keine UI-eigene Payload-Wahrheit.
- Keine Aenderung der Combat- oder Deboard-Logik, falls der Payload davor bereits fehlt.

## Relevante Contracts

- `docs/dev/homebase_direct_dropship_flow_contract.md`
- `docs/dev/combat_loop_authority_contract.md`
- `docs/tasks/TASK_1056_active_mission_transport_payload_consumer_repair.md`

## Akzeptanzkriterien

- Alpha und Beta liefern jeweils alle zugeordneten Unit-IDs und Fireteam-IDs in den MissionSetup-Vertrag.
- Beide Payloads erzeugen ausschliesslich freundliche Runtime-Slots.
- Jede Dropship-Karte behaelt ihren eigenen LZ-/Inbound-/Deboard-Zustand.
- `task_396_mission_dropship_lz_drop_hotfix.gd` ist vollstaendig gruen.

## Ergebnis

- Die Testfixture referenziert nun die reale 8-Slot-Station-Outpost-Map. Der fruehere 3-Slot-Default hatte den vierten Operator bereits vor dem Boarding entfernt.
- `_apply_homebase_direct_setup_selection_from_drop_cards()` baut die kombinierte Unit-/Fireteam-Auswahl jetzt primaer aus payloadtragenden Missionskarten. Der Einzel-Dropship-Snapshot bleibt nur noch Fallback.
- Die kombinierte Auswahl wird in `mission_setup_*` und `selected_*` gespiegelt. Ein spaeter Start kann die aktive Mission damit nicht mehr auf ein Teilteam oder veraltete Fireteam-Paare zuruecksetzen.
- TASK_396 prueft 17/17: vier Units, ft1/ft2-Paare, getrennte LZs, parallelen Inbound, vollstaendiges Deboarding und beide aktiven Runtime-Fireteams.

## Betroffene Dateien

- `scripts/meta/meta_layer_flow.gd`
- `scripts/meta/homebase_screen.gd` nur falls dort die Quelle nachweislich fehlerhaft ist
- `scripts/tests/task_396_mission_dropship_lz_drop_hotfix.gd`
- diese Task-Datei

## Lokale Pruefung

- `godot_console.exe --headless --path . --script res://scripts/tests/task_396_mission_dropship_lz_drop_hotfix.gd`
- einschlaegige Dropship-/Mission-Regressionen nach der Korrektur
- `git diff --check`

## Risiken / offene Punkte

Die bestehende globale Auswahl ist historisch ein Single-Mission-Payload. Eine Korrektur darf nicht versehentlich bereits deboardete oder rueckkehrende Karten wieder einsteigen lassen und muss spaeter mit Multiplayer-Ownership vereinbar bleiben.
