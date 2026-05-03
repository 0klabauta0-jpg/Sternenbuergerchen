# Multiplayer Authority Command Contract

## Zweck
Dieser Vertrag begrenzt Multiplayer-Eingaben auf erlaubte Commands. Clients senden keine autoritative Gameplay-Wahrheit. `SimulationRoot` validiert eingehende RPC-Payloads und enqueued nur akzeptierte Commands auf der Authority.

## Authority
- `SimulationRoot.request_command()` bleibt der RPC-Einstieg fuer Netzwerk-Commands.
- Im server-authoritativen Modus darf nur die Authority Commands committen.
- Akzeptierte Commands werden ueber die bestehende `SimulationRoot.command_queue` verarbeitet.
- Abgelehnte Commands werden gezaehlt und mit Grund im Contract-Snapshot sichtbar.

## Peer-Rollen
- `host`: darf serverseitig alle gueltigen Contract-Commands ausfuehren.
- `commander`: darf Commands fuer sein zugewiesenes Team ausfuehren.
- `fireteam`: darf nur Commands fuer zugewiesene Fireteams ausfuehren.
- `spectator`: ist vorbereitet, darf aber keine Commands ausfuehren.

Peer-Zuweisungen liegen bewusst in `SimulationRoot`:
- `set_peer_team(peer_id, team_id)`
- `set_peer_role(peer_id, role_id)`
- `set_peer_fireteams(peer_id, fireteam_ids)`
- `get_network_command_contract_snapshot()`

## Erlaubte Command-Kategorien
- `unit_command`: bestehende `UnitCommand`-Typen wie `move_to_position`, `hold_position` und `engage_area`.
- `commander_command`: bestehende Commander-Typen `move`, `engage`, `take`, `defend`, `flank`.
- `area_order`: fuer Multiplayer V1 nur `engage` und `defend`.
- `ad_hoc_order`: bestehende gueltige `AdHocOrder`-Payloads.
- `dropship_command`: `set_lz`, `clear_lz`, `call_dropship`, soweit die Payload vom Client kommt und nicht aus Scenario-/Editor-Daten gesetzt wird.

## Harte Rejects
Der Contract lehnt Payloads ab, die Client-State als Wahrheit setzen wollen, unter anderem:
- Damage-/Health-/Vital-State
- Objective-/Capture-State
- Runtime-State
- Position/global_position ausser expliziten Zielpositionen wie `target_position` oder `lz_position`
- Dropship-/LZ-Runtime-State
- LZ-Payloads mit `source_context`/`source` aus `scenario`, `mission_scenario`, `editor` oder `map_editor`

## Testbarkeit
`scripts/tests/task_166_multiplayer_authority_command_contract_verifier.gd` prueft:
- erlaubter Move wird serverseitig enqueued
- fremdes Team wird abgelehnt
- State-Mutation wird abgelehnt
- Fireteam-Rollen duerfen nur zugewiesene Fireteams kommandieren
- Area-/Ad-hoc-/Dropship-Whitelist greift

## Folge-Tasks
`TASK_167` soll Session/Lobby-Zuweisungen an diese Peer-Team-/Rollen-/Fireteam-API anbinden. `TASK_168` soll Snapshot-Replikation getrennt davon halten: Snapshots sind Anzeigezustand vom Server, keine Command- oder Client-Wahrheit.
