# SimulationRoot Unknown Payload Audit

## TASK_342 Ergebnis

Unbekannte Command- oder Effect-Payloads werden im `SimulationRoot` jetzt sichtbar ignoriert. Kurz: sichtbar ignorieren statt still verschlucken. Der Runtime-Flow bricht nicht hart ab, aber die Payload verschwindet nicht mehr ohne Diagnose.

## Debug-Snapshot

`get_unknown_payload_debug_snapshot()` meldet:

- `unknown_command_count`
- `unknown_effect_count`
- `unknown_total_count`
- `last_unknown_payload`
- `runtime_authority`
- `unknown_payloads_are_ignored_without_crash`

Die letzte Unknown-Payload wird kompakt gespeichert. Der Snapshot enthaelt Payload-Kategorie, Typ, Grund, sortierte Keys und einen kleinen Preview aus Identitaets- und Herkunftsfeldern wie `command_type`, `effect_type`, `origin`, `source_context`, `unit_id`, `team_id`, `fireteam_id`, `asset_id`, `event_id` oder `command_id`.

## Verhalten

Bekannte, aber in `SimulationRoot` bewusst no-op bleibende Command-Intents wie Planungs-, Dropship-, Breakout- oder Air-Asset-Commands werden nicht als Unknown-Payload gezaehlt. Multiplayer-Rejects bleiben getrennte Contract-Rejects: Sie werden nicht enqueued und erhoehen nur die Netzwerk-Reject-Diagnose.

## Risiko

Die Diagnose ist absichtlich zaehlbar und kompakt. Bei einem echten Typo gibt es eine Warnung plus Snapshot-Kontext; bei bekannten Negativtests soll dadurch kein Release- oder Regression-Gate verrauschen.
