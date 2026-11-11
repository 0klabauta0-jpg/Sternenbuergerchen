# Weltraumkampf Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Steuerbarer Rottenkampf mit 1–6 Schiffen, gemeinsamen Aufträgen, gekoppeltem/ausgekoppeltem Flug und sichtbarer Pilotenausführung in lokalen Orbitbereichen; strategische Sternkarte 256×256.

**Architecture:** SimulationRoot committet Commands, Bewegung und Kampf; Reise und Kampf referenzieren denselben pro-Schiff-Flugzustand. Reine Resolver liefern Vorschläge, Registries nur Lookup, UI und Effekte lesen Snapshots. Bestehende Supply-, Personen-, Reise- und Checkpointowner bleiben in ihrem Bereich zuständig.

**Tech Stack:** Godot 4.6.2, GDScript, vorhandene axiale Hexprojektion, JSON-Kataloge, vorhandener isolierter PowerShell-Prüfpfad.

**Spec:** [Bestätigtes Weltraumkampf-Konzept](../../dev/space_combat_contract.md)
**Task:** [SPACE_COMBAT_2026_11_11_PLAN](../../tasks/SPACE_COMBAT_2026_11_11_PLAN.md)
**Status 11.11.:** AP00 und AP01 begrenzt umgesetzt und geprüft. AP02 und AP04
besitzen erste isolierte Bausteine; ihre Produktanbindung und AP03/AP05–AP20
bleiben offen. Details: [Ausführungstask](../../tasks/SPACE_COMBAT_EXECUTION_2026_11_11.md).
**Quellbasis:** `84dd481b187299d3832ded3596bbc01dfd62abe9` auf `task/native-glut-maps-20261110`. Bewusst noch nicht integrierter nativer Taskstand, nicht Main.

**Abgleich 11.11.:** Parallelstand b67b307b0 wurde als 1ced3be19 übernommen.
Er enthält bereits `singleplayer_ship_equipment_state.gd`, Katalog,
Supply-/Servicepfad und Checkpointvalidierung für einen wirksamen Warp-Slot.
AP09/15/16 erweitern diesen Owner und seine Verträge; keinen zweiten
Schiffskomponentenowner anlegen. Die bisherige Warp-Bilanz und
Installationshistorie bleiben kompatibel und prüfbar.

## Global Constraints

- Eine taktische Kampfebene, 2,5D-Darstellung.
- Eine Rotte besteht aus **1 bis 6 Schiffen**, ähnlich wie ein Fireteam zusammenstellbar.
- Jedes fliegende Schiff, einschließlich Dropship/Cutlass, gehört genau einer Rotte an; Einzelflug entspricht einer Einerschiffsrotte.
- Ein Orbitbereich je Stern/Planet/Mond: 512×256 Hexfelder, Warpankunft unten, oben mittig 256 Felder breiter und etwa vier Felder tiefer Saum; Oberflächenanflug nur am Saum.
- Mehrere Rotten können gemeinsam einen Auftrag erhalten und darin Rollen übernehmen.
- Der Kampf läuft in Echtzeit ohne Pause.
- Schaden bleibt datenbasiert. Friendly Fire bleibt gemäß Projektgrundsatz aktiv.
- Ein gemeinsamer pro-Schiff-Flugzustand wird von Reise und Kampf referenziert, nicht kopiert.
- Waffen, Schildgeneratoren und Kraftwerke sind austauschbare Komponenten mit tatsächlicher Wirkung.
- Bestehende Heimatcheckpoint-Grenze bleibt.
- Keine SceneTree-Vollscans oder kompletten HUD-Rebuilds pro Frame; räumliche Queries und VFX bleiben begrenzt.
- Keine Änderung der Boden-Combat-/LOS-/Höhenregeln, keine freie 3D-Kampfebene und keine parallele Reise-/Kampfsimulation für denselben Orbitbereich.
- Neues Gameplay in `scripts/core/`, reine Resolver in `scripts/tactical/`, Contracts/Bridges in `scripts/mission/`; kein produktiver Neucode unter `scripts/tests/`.
- Zahlen dieses Plans sind reproduzierbare Start-/Testparameter, keine endgültig freigegebene Balance.

## Review Focus

1. Reise und Kampf dürfen denselben Spielerakteur nicht doppelt bewegen; NPCs dürfen nicht Spieler-Supply oder Savegate verunreinigen → AP01/AP17.
2. Kontinuierliche Bewegung und Drehung eines Mehrhexrumpfs dürfen belegten Raum zwischen freien Endpunkten nicht durchqueren → AP03.
3. Verlorene Gruppenmitglieder, Schutzzyklen und widersprüchliche Feuerregeln müssen verständlich enden und dürfen keine freie Jagd erzeugen → AP04/AP06/AP10.
4. Replay, Save/Restore und Ansichtswechsel dürfen Komponenten, Schadensereignisse oder Pilotenerfahrung nicht vervielfachen → AP00/AP08/AP13/AP15/AP16.
5. Kamera, FPS, VFX-Budget und fremde Clientpayloads dürfen weder Treffer noch Fortschritt entscheiden → AP14/AP18/AP19/AP20.

## Abfolge und handhabbare Meilensteine

| AP | Ergebnis | Voraussetzung |
| --- | --- | --- |
| 00 | Quellbasis, Commandschema und kleiner Prüfweg | – |
| 01 | Gemeinsamer Flugzustand und eindeutiger Tick | 00 |
| 02 | Gekoppelter und ausgekoppelter Flug | 01 |
| 03 | Sichere Hexbelegung und Mehrhexrümpfe | 02 |
| 04 | Rotten 1–6 und eindeutige Pilotenzuordnung | 01 |
| 05 | Rotten zusammenstellen und auf Sternkarte wählen | 03,04 |
| 06 | Fliegen, Patrouillieren, Sichern und Rückzug | 03,04,05 |
| 07 | Bekannte Kontakte, Ziele und Feuerwinkel | 01,03 |
| 08 | Repeater, Hüllentreffer und Friendly Fire | 07 |
| 09 | Wirksame Ausrüstung, Schild und Energie | 02,08 |
| 10 | Angriffs-/Schutzaufträge und gemeinsame Rollen | 06,08,09 |
| 11 | J-Hook, Ausweichstoß und Feuerziehen | 10 |
| 12 | Schere, Roll-/Strafemanöver und Doppelangriff | 11 |
| 13 | Pilotenskill, Freischaltungen und Erfahrung | 12 |
| 14 | Laser, Schubspuren, Treffer, Explosionen und Licht | 09,12 |
| 15 | Versionierte Heimatcheckpoints | 04,09,13 |
| 16 | Komponenten über bestehenden Service tauschen | 09,15 |
| 17 | Kampagnenbegegnung und echter Rückweg | 10,13,15,16 |
| 18 | Hostautorität und Clientprojektion | 17 |
| 19 | Native Bedien-/Sichtabnahme | 14,17 |
| 20 | Begrenzte Performance- und Abschlussprüfung | 18,19 |

**M1/AP05:** Rotten sichtbar, sichere Flugbewegung; noch kein fertiger Kampf.
**M2/AP10:** Erstes funktionierendes Eskortengefecht mit Repeatern/Schilden.
**M3/AP14:** Sichtbare Manöver, Skill und Effekte.
**M4/AP17:** Ausrüstung, Heimatcheckpoint und Kampagnenweg zusammenhängend.
**M5/AP18–20:** Geprüfte Authority, Bedienung, Sicht und Leistung; getrennte Nachweise.

Unabhängige reine Helper dürfen parallel entstehen. Änderungen an Root,
RuntimeAdapter, StarMapScreen, CheckpointStore und MetaLayerFlow werden
sequenziell integriert. Kein AP startet blind vom alten Hauptcheckout.
Die parallel laufenden Ground-/Lifecycle-Arbeiten sind bei AP00 abzugleichen.

## Datei- und Schnittstellenkarte

**Bestehende Anschlussstellen, am Quellstand geprüft:**

- `scripts/core/simulation_root.gd`: `request_singleplayer_command(command: Dictionary, authority_context: Dictionary = {}) -> Dictionary`, `configure_singleplayer_owners(...)`, `configure_space_encounter(owner)`.
- `scripts/meta/singleplayer_runtime_adapter.gd`: `request_operation(operation, payload = {})`, `advance_space_travel(delta)`, `export_campaign_checkpoint()`, `get_world_checkpoint_guard()`.
- `scripts/core/singleplayer_space_travel_state.gd`: `apply_command(command, authority_context = {})`, `get_snapshot()`.
- `scripts/core/singleplayer_fleet_travel_state.gd`: Spielerreiseindex, `register_craft`, `get_snapshot`, `all_grounded`; keine Gegneraufnahme über `sync_crafts`.
- `scripts/ui/star_map_screen.gd`: `configure(snapshot_provider: Callable, command_handler: Callable)`, `refresh(snapshot = {})`, `_send(operation, payload = {})`.
- `scripts/ui/star_map_canvas.gd`: `screen_to_hex`, `map_to_screen`, `screen_to_map`; `star_map_world_view.gd` projiziert Schiffe.
- `scripts/meta/campaign_checkpoint_store.gd`: `validate_payload(payload)`.
- `scripts/meta/mission_progression_resolver.gd`: `apply_mission_result(roster, mission_result, options = {})`; heutiges `pilot_action` steigert Awareness, noch nicht Fighter-Piloting.
- `scripts/core/campaign_space_encounter.gd`, `scripts/meta/campaign_space_encounter_presenter.gd`: vorhandene begrenzte Kampagnenbegegnung.

**Neue begrenzte Zuständigkeiten:** Die nachstehenden Pfade sind geplant, nicht
vorhanden behauptet. Wenn ein anderer Task denselben fachlichen Owner inzwischen
implementiert hat, bei AP00 diesen erweitern und die Pfadkarte aktualisieren.

| Pfad | Zuständigkeit |
| --- | --- |
| `scripts/mission/space_combat_command_contract.gd` | Envelope, IDs, Typen, Phasen, Rechte |
| `scripts/core/space_flight_state.gd` | Ein gemeinsamer Bewegungsdatensatz je Schiff |
| `scripts/core/space_combat_state.gd` | Begegnung, Hülle/Schild/Reserve, Schussereignisse, laufende Manöver und Auftragsfortschritt |
| `scripts/core/space_ship_registry.gd` | Referenzen und räumlicher Index, keine Gameplaymutationen |
| `scripts/core/space_wing_state.gd` | Rottenmitgliedschaft, Führer, Gruppenaufträge |
| `scripts/core/singleplayer_ship_equipment_state.gd` | Bestehender Owner für installierte Slot-/Item-IDs und Revision; um Kampfkomponenten erweitern |
| `scripts/tactical/space_flight_resolver.gd` | Schub/Assistenz/Integration als reiner Vorschlag |
| `scripts/tactical/space_navigation_resolver.gd` | Sweeps, Belegung, Ausweich-/Reservierungsvorschlag |
| `scripts/tactical/space_order_resolver.gd` | Auftrag → Mitgliederabsichten |
| `scripts/tactical/space_targeting_resolver.gd` | Bekannte Kontakte, Kandidaten, LOS/Feuerkegel |
| `scripts/tactical/space_weapon_resolver.gd` | Reproduzierbare Schüsse und Schadenvorschläge |
| `scripts/tactical/space_maneuver_resolver.gd` | Phasen, Abbruch, Rückkehr zum Auftrag |
| `scripts/tactical/space_pilot_resolver.gd` | Profil → begrenzte Ausführungsfaktoren |
| `scripts/ui/space_wing_panel.gd` | Bestand/Rotten/Mehrfachauswahl, reine Command-UI |
| `scripts/visuals/space_combat_effects.gd` | Begrenzte Effekte aus Snapshots/Ereignissen |
| `data/space/ship_hulls.json`, `ship_components.json`, `maneuvers.json` | Validierte eigene Startkataloge |

### Gemeinsame Datenformen

Alle Namen unten sind verbindliche **geplante Schnittstellen**; keine Rückschlüsse
auf schon vorhandene Implementierung. Nutzerdaten verwenden kanonische Craft-
und Personen-IDs, Fixture-IDs erhalten Präfix `space_fixture_`.

- Command: `contract_category="space_combat"`, `operation:String`,
  `request_id:String`, `expected_revision:int`, `payload:Dictionary`.
  Absender-/Hostrechte stammen aus dem vertrauenswürdigen Aufrufkontext.
- Ergebnis: `{ok:bool, reason:String, revision:int, replayed:bool}`.
  Gleiche ID/gleicher Inhalt liefert Replay, anderer Inhalt lehnt ab.
- FlightSnapshot: `craft_id, position_plane:Vector2, velocity_plane:Vector2,
  heading_rad:float, angular_velocity:float, assist_mode:String, motion_mode:String,
  mass:float, revision:int, tick:int`. Ebene in Hex-Plane-Einheiten;
  normalisierte Alt-API ausschließlich über `GRID.EXTENT` umrechnen.
- `assist_mode`: `coupled|decoupled`; `motion_mode`:
  `grounded|travel|tactical`. Reisephase/Orbit/Ort verbleiben im Travelowner.
- WingSnapshot: `wing_id, craft_ids:Array[String], leader_craft_id,
  order_id, group_order_id, revision`. Unzugewiesen ist kein leeres aktives Wing.
- Order: `order_id, wing_ids, verb, target_kind, target_id, target_hex,
  area_hexes, waypoints, stance, fire_rule, contact_response, protect_radius, pursuit_limit,
  roles, status, revision`; nur zum Verb passende Zielfelder zulassen.
- `contact_response`: `avoid|observe|engage`; Passivpreset setzt `avoid+hold`.
  `avoid` mit anderer Feuerregel wird als `incompatible_rules` abgelehnt,
  nicht still normalisiert. Kontaktreaktion wird gespeichert und repliziert.
- WorldSnapshot: `tick, ships, wings, orders, contacts_by_faction, blockers,
  revision`; interner autoritativer Readsnapshot, keine mutierbaren Node-/UIreferenzen.
  UI/Clients erhalten ausschließlich `build_faction_snapshot(faction_id: String)
  -> Dictionary` aus Combatstate: eigene Schiffe/Aufträge und bekannte Kontakte,
  keine fremden Kontaktlisten, verdeckten IDs/Positionen oder gegnerischen Loadouts.
- ShotEvent: `event_id, tick, shooter_id, weapon_slot_id, intended_target_id,
  actual_hit_id, outcome, shield_damage, hull_damage, muzzle_position_plane,
  impact_position_plane, shot_direction, visual_weapon_id`. Die Geometrie
  stammt aus dem autoritativen Schusszeitpunkt; ein Fehlschuss endet am
  berechneten freien Endpunkt, nicht an einer später nachgeschlagenen Zielpose.
- ManeuverState im Combatowner: `craft_id, maneuver_id, order_id, phase,
  phase_elapsed_seconds, partner_ids, started_tick, timeout_tick,
  cooldown_until_tick, revision`. Root committet Resolvervorschläge über
  `commit_maneuver(proposal: Dictionary, tick: int) -> Dictionary`.
  Neubefehl, Abbruch, Verlust und Partnerausfall invalidieren die alte Phase.
- Resolver-Ausgaben sind Vorschläge. Root prüft Revision/Phase und committet
  pro Tick atomar; Rendering und UI dürfen keinen Resolver-Commit auslösen.

### Reihenfolge eines autoritativen Kampfticks

Commands/Revisionsprüfung → effektive Ausrüstung und verfügbare Leistung →
bekannte Kontakte/Aufträge/Manöver → begrenzte Flugvorschläge/Sweeps →
gemeinsamer Motioncommit → aktuelle LOS/Waffenwinkel → Schussbatch mit
Reserveverbrauch → gemeinsamer Schild-/Hüllenschaden → zeitabhängige
Wiederaufladung und Ereignissnapshot. Neu erlittene Schildtreffer starten
die Erholungsverzögerung vor Wiederaufladung. Die Leistung aus AP09 wird
einmal budgetiert; der Schadensbatch verwendet denselben Ticksnapshot.

## Prüf- und Commitablauf je Paket

Jeder AP erhält `scripts/tests/space_combat_apNN_verifier.gd`.
Geprüft wird jeweils **ein kleiner neuer Fall** plus die unten genannte
betroffene bestehende Regression. Keine vollständige Spielsuite pro Helper.
Neue Checks melden `SPACE_COMBAT_APNN passed=<n> failed=0` und Exit0.

Vorhandener fensterloser Starter, aus dem jeweiligen Implementierungsworktree:

```powershell
$spaceRunName = 'space-combat-ap02-' + [guid]::NewGuid().ToString('N')
& ./scripts/tests/run_orbit_quantum_checks.ps1 -Scripts @('space_combat_ap02_verifier.gd') -RunName $spaceRunName -TimeoutSeconds 60
```

AP02 durch die jeweilige Nummer ersetzen. Der Runner setzt privates APPDATA
je Script und prüft Exitcode/Fehlermarker. Falls das aktuelle Projekt durch
Custom-Userdir/Override diese Isolation umgeht, **vor** einem schreibenden
Check den vorhandenen `run_review2_isolated.py` samt aktuellem Roster-Hashguard
verwenden; kein echter Spielstand als beschreibbare Fixture. AP00 weist dies
an der aktuellen project.godot-Konfiguration nach.

Für jeden AP: beobachteten roten Fall festhalten, minimalen Code ändern,
denselben Fall grün prüfen, betroffene Regression prüfen, `git diff --check`,
frischen begrenzten Review durchführen, nur Paketdateien committen.
Der Plan verlangt keine Testausführung während dieses reinen Dokuauftrags.

## AP00 — Quellstand, Commandgrenze und Prüfweg

**Dateien:** Neu `scripts/mission/space_combat_command_contract.gd`,
`scripts/tests/space_combat_ap00_verifier.gd`; ändern diesen Plan/Task nach
dem aktuellen Integrationsabgleich.
**Interface:** `validate(command: Dictionary, context: Dictionary) -> Dictionary`;
normalisierte Commanddaten oder stabiler Rejectgrund. Reine Prüfung ohne Mutation.

- [x] Native Karte, Ground-/Lifecycle-, Komponenten- und Checkpointarbeiten gegen aktuellen Gitstand abgleichen; exakten Implementierungsbasiscommit festhalten. Bestehende Contracts lesen, doppelte Owner ausschließen.
- [x] Rote Tests: `unknown_operation`, NaN/Infinity, falsche Payloadtypen, ungültige ID/Zelle, fremdes Schiff, UI-gefälschtes `runtime_authorized`, veraltete Revision; jeder Reject lässt Ausgangsstate unverändert.
- [x] Validator implementieren; erlaubte Operationen: `wing_create`, `wing_assign`, `wing_remove`, `wing_rename`, `wing_leader_set`, `order_issue`, `order_cancel`, `fire_rule_set`, `assist_preference_set`, `maneuver_request`. Umbenennen braucht `wing_id+name`, Führerwahl `wing_id+leader_craft_id` eines vorhandenen Mitglieds, Manöveranforderung `wing_ids+maneuver_id+target` als Absicht. Ownership/Revision gelten für alle. Interne Admit/Tick/Damage/Finalize-Operationen niemals als UIbefehle zulassen.
- [x] AP00 grün; Isolationspfad mit temporärer Fixturedatei nachweisen und reale Profildateien unverändert lassen. Commit `feat: define validated space command boundary`.

**Abnahme:** Typ-/Rechteprüfung und Testisolation funktionieren; noch kein neuer Produktpfad aktiviert.

## AP01 — Gemeinsamer Flugzustand, Admission und Tickzuständigkeit

**Dateien:** Neu `space_flight_state.gd`, `space_combat_state.gd`,
`space_ship_registry.gd` unter `scripts/core/`; ändern
`singleplayer_space_travel_state.gd`, `singleplayer_fleet_travel_state.gd`,
`simulation_root.gd`, `scripts/meta/singleplayer_runtime_adapter.gd`,
`scripts/meta/meta_layer_flow.gd`; AP01-Verifier.
**Interfaces:** Flight `configure(craft_id: String, pose: Dictionary) -> Dictionary`,
`get_snapshot() -> Dictionary`, `commit_motion(proposal: Dictionary, tick: int) -> Dictionary`.
Travel `get_flight_state() -> RefCounted`, Fleet
`get_flight_state(craft_id: String) -> RefCounted`: nur Root/Registry erhalten
die vorhandene Instanz, UI ausschließlich Snapshots. Travel erzeugt seinen
Flightstate genau einmal bei Registrierung; NPC-Admission erzeugt genau eine
weitere Instanz außerhalb des Spieler-Fleetindex.
Root `admit_space_actor(definition: Dictionary, authority_context: Dictionary) -> Dictionary`.
Root `set_space_runtime_tick_enabled(enabled: bool) -> void` und
`advance_space_runtime(delta: float) -> void`, ausschließlich intern aufgerufen.
Registry `get_actor(craft_id: String) -> RefCounted`, `query_cells(cells: Array[Vector2i]) -> Array[String]`.

- [x] Travel- und Combatreader referenzieren dieselbe Objektinstanz, nicht nur gleiche Posewerte; doppelter Tick wird abgewiesen; taktischer Modus stoppt Quantumfortschritt; NPC-Admission erzeugt kein Spielerpad, Fuelkonto oder Roster.
- [x] Vorhandene Travel-Position/Heading in gemeinsame Flightinstanz überführen, normalisierte Snapshot-API erhalten. Root routet einen Tick an genau einen Bewegungsmodus. Gegner über separate Registry-Admission mit gültiger Startpose/Fraktion aufnehmen, nicht über `sync_crafts`.
- [x] Den Renderaufruf `MetaLayerFlow._process -> advance_space_travel` als Zeittreiber ablösen. CampaignSimulationRoot bekommt einen Raumtick-Callback in `_physics_process`. **Korrektur 11.11.: kein früher Rücksprung vor der Bodenlogik**: BasePersonnelRuntime benutzt denselben Root und muss weiterlaufen. Bisheriges pauschales `set_physics_process(false)` im Adapter dafür ersetzen; normale Bodenroots unverändert lassen. Renderpfad darf nur Feedback projizieren. Ansichtwechsel stoppen den Raumtick nicht.
- [x] Tatsächlichen Adapter-/Rootpfad bei30/60/144Renderbegrenzung und verdeckter Sternkarte prüfen: Warpfortschritt folgt den Physikticks. Synthetischer Vergleich gleicher Tickzahlen ergänzt den tatsächlichen Ansichtswechsel. Raumkampf bleibt bis AP17 ausdrücklich Fixture-/Opt-in-Pfad.
- [x] AP01 und `space_travel_state_verifier.gd`, `playtest_20261110_fleet_travel_verifier.gd` grün; Commit `feat: share authoritative space motion state`.

**Abnahme:** Ein Motionobjekt und ein Commit pro Schiff/Tick; alte Reiseaktionen behalten Verhalten.

## AP02 — Schub, Trägheit und beide Flugarten

**Dateien:** Neu `scripts/tactical/space_flight_resolver.gd`,
`data/space/ship_hulls.json`; ändern Flightstate; AP02-Verifier.
**Interface:** `step(flight: Dictionary, intent: Dictionary, hull: Dictionary, power: Dictionary, dt: float) -> Dictionary`
liefert Motionvorschlag samt tatsächlichen Schubanteilen.

- [ ] Rote numerische Tests: ausgekuppelt mit Geschwindigkeit (2,0) ohne Schub nach1s um(2,0) versetzt; Moduswechsel bei gleichem Tick ändert Geschwindigkeit nicht; doppelte Masse halbiert Beschleunigung bei gleichem Schub.
- [ ] Gekoppelte Assistenz und ausgekoppelten Schub mit Vorwärts-/Brems-/Seitenschub, Drehmoment, Trägheit und gemeinsamen Leistungsgrenzen implementieren. Fester Root-Tick, keine Abhängigkeit von Renderdelta.
- [ ] Fälle für begrenztes Bremsen, 180°-Bugwechsel bei weiterlaufender Bahn, kombinierte Achsen ohne Gratisleistung und 30/60/144 Render-FPS bei identischem Simulationstick grün prüfen.
- [ ] AP02 und AP01 grün; Commit `feat: implement coupled and decoupled space flight`.

**Abnahme:** Jetartige Assistenz und echter Drift unterscheiden sich nachvollziehbar. Testhüllen sind bezeichnete Fixtures, keine SC-Meterimporte.

## AP03 — Flugkorridore, Belegung und große Rümpfe

**Dateien:** Neu `scripts/tactical/space_navigation_resolver.gd`; ändern Registry,
Flightcommit und Hullkatalog; AP03-Verifier.
**Interface:** `resolve_motion(flights: Array[Dictionary], proposals: Array[Dictionary], world: Dictionary) -> Dictionary`
liefert zugelassene Vorschläge und Konfliktgründe, keine Mutation.

- [ ] Rote Fälle: zwei Jäger kreuzen gleichzeitig, tauschen Plätze, treffen auf stationären Blocker; Mehrhexrumpf dreht mit freiem Anfang/Ende, aber blockierter Zwischenfläche.
- [ ] Zeitlich überstrichene Rumpfflächen prüfen, nahe Raumzellen indizieren und frühzeitige Ausweich-/Bremsvorschläge erzeugen. Stabile Craft-ID entscheidet Gleichstand. Kein Hex-Teleport oder Rammenschaden.
- [ ] Sonderfall blockierte Formation löst sich geordnet und sammelt neu; Kartenrand und zu enger Wendebereich liefern sichtbaren Grund. Einzelfeld-Anker und tatsächlicher Sweep widersprechen sich nicht.
- [ ] AP03/AP02 grün; Commit `feat: enforce swept space occupancy`.

**Abnahme:** Kein Tunneln durch Blocker, Schiffe oder beim Drehen ausgeschwenkten Rumpf. Unvermeidbare numerische Überlappung wird konservativ verhindert und diagnostiziert, nicht als Physikschaden versteckt.

## AP04 — Rottenbestand und Pilotenbindung

**Dateien:** Neu `scripts/core/space_wing_state.gd`; ändern Root/Adapter;
AP04-Verifier.
**Interface:** `apply_command(command: Dictionary, context: Dictionary) -> Dictionary`,
`get_snapshot() -> Dictionary`; Commandpfad aus AP00, vorhandene Craft-/Pilot-IDs lesen.

- [ ] Rote Tests: Größen1 und6 zulässig,7 abgelehnt; dasselbe Schiff nicht in zwei Rotten; ein Pilot nicht gleichzeitig in zwei aktiven Schiffen; leere Rotte wird inaktiv/aufgelöst.
- [ ] Erstellen, Umbenennen, Zuordnen, Entfernen und Führerwahl atomar implementieren. Mitgliedertransfer wird entweder vollständig angenommen oder ohne Nebenwirkung abgelehnt.
- [ ] Verlust des Führers bestimmt einen vorhandenen einsatzfähigen Nachfolger mit stabiler ID-Reihenfolge; fehlender Pilot blockiert Teilnahme mit Grund.
- [ ] Flugaufnahme und Umgruppierung atomar: jedes fliegende eigene oder fremde Schiff ist genau einer Rotte zugeordnet, auch Dropship/Cutlass und Einzelschiff. Geerdete Bestandsschiffe dürfen vor Flug unzugeordnet sein; Legacy-Stand beim ersten Flug berücksichtigen. Mehrere Rotten bleiben getrennte Ownerobjekte.
- [ ] AP04/AP00 grün; Commit `feat: add flexible one-to-six ship wings`.

**Abnahme:** Einzelflieger und Sechserrotte gleichwertig bedienbar; Personen-/Boardingwahrheit bleibt beim vorhandenen Owner.

## AP04a — Lokaler Orbitbereich und Übergang (neue Festlegung)

- [ ] Vor gemeinsamem Produktcode Zuständigkeiten und Dateibesitz mit dem Orbitkarten-Chat abstimmen. `SpaceWingState` besitzt Rotten; Reiseowner besitzt Reisephase, Orbitzuordnung und Anfluggate; `SimulationRoot` und derselbe `SpaceFlightState` committen die lokale Pose. Keine zweite Simulation oder zweite Positionswahrheit.
- [ ] Gemeinsame API für Bereichs-ID, lokalen 512×256-Raumindex, atomaren Übergang strategischer/localer Pose, Ankunft unten und tatsächliche Saumlage vertraglich festlegen. Bestehendes `StrategicHexGrid` bleibt 256×256; keine stille globale Vergrößerung.
- [ ] Ein Orbitziel pro Körper statt dreier Marker; Oberflächenanflug nur bei tatsächlicher Saumposition und gültiger Landeberechtigung. Bestehende Marker-/Save-/Warpdaten ausdrücklich migrieren und Legacy-Verhalten prüfen.
- [ ] Testfälle: Einerschiffsrotte auch für Dropship beim Flug; kein unzugeordnetes oder doppelt zugeordnetes fliegendes Schiff; zwei lokale Bereiche ohne Positions-/Belegungskollision; Warpankunft unten; Anflug außerhalb des Saums abgewiesen, im Saum erlaubt; Raumblockade bleibt tatsächlich umflieg-/kämpfbar.

**Stand:** Architektur-/Akzeptanzvorgabe, nicht implementiert. Die bisherige AP01-Abnahme bezog sich auf das strategische Raster und bestätigt noch keinen lokalen Bereichswechsel.

## AP05 — Rottenpanel, Kartenwahl und erster sichtbarer Flug

**Dateien:** Neu `scripts/ui/space_wing_panel.gd`; ändern
`star_map_screen.gd`, `star_map_canvas.gd`, `star_map_world_view.gd`
unter `scripts/ui/`; AP05-Verifier.
**Interface:** Panel `configure(snapshot_provider: Callable, command_handler: Callable) -> void`,
`refresh(snapshot: Dictionary) -> void`; Auswahl bleibt UIstate, Mitgliedschaft nicht.

- [ ] Rote UIchecks: Ein- und Sechserrotte aus Bestand zusammenstellen, Transfer ablehnen/anzeigen, Mehrfachauswahl und leere Auswahl korrekt behandeln.
- [ ] Bestehende Kartenprojektion/Zoom-/Pickfunktionen nutzen. Modelle anhand Craft-ID darstellen, einheitliche Hexgröße und großen Rumpf-Footprint zeigen. Auswahlmarker/Flugvektor/Bugrichtung aus AP01 lesen.
- [ ] Kleine native Fixture mit zwei Schiffen: Kurve und Drift aus tatsächlicher Motion sichtbar, Schiffsmitte/Hex-Pick bleiben nach Pan/Zoom deckungsgleich.
- [ ] AP05 plus `star_map_camera_verifier.gd` und `star_map_ui_verifier.gd` grün; Commit `feat: expose wing setup on the star map`.

**Abnahme M1:** Rottenbildung und korrekter Raumflug auf derselben Karte sichtbar. Kein vollständiges Gefecht behaupten.

## AP06 — Grundaufträge und Verhaltensregeln

**Dateien:** Neu `scripts/tactical/space_order_resolver.gd`; ändern Wingstate,
Root und Panel; AP06-Verifier.
**Interface:** `resolve(order: Dictionary, world: Dictionary, dt: float) -> Dictionary`
liefert pro Craft Bewegungsabsicht, Status und nächste Auftragsphase.

- [ ] Rote Tests für Fliegen, Wegpunktpatrouille, Ort sichern, Sammeln und Rückzug; Abbruch ersetzt den Auftrag genau einmal und beendet alte Mitgliederabsichten.
- [ ] Haltungen `cautious/normal/aggressive`, Feuerregeln `hold/return/free` und Kontaktreaktion getrennt verarbeiten. Passiv setzt `contact_response=avoid` und `fire_rule=hold`; ansonsten folgt `observe/engage` der expliziten Auftragsdoktrin. Auftrag behält Ziel/Radius; Haltung verändert keine Berechtigung. Passivauftrag hier im Snapshot und später in AP15 nach Restore unverändert prüfen.
- [ ] Ankunft, blockierter Weg und unerreichbarer Sammelpunkt melden. Patrouille läuft bis Abbruch; Rückzug ist erst bei tatsächlicher Ankunft fertig.
- [ ] AP06/AP03/AP04 grün; Commit `feat: execute bounded wing navigation orders`.

**Abnahme:** Alle Grundaufträge ohne Kampf funktionieren, kein stiller Infanterie-Kontakthalt.

## AP07 — Kontakte, Schussbahn und Zielzulässigkeit

**Dateien:** Neu `scripts/tactical/space_targeting_resolver.gd`; ändern Combatstate,
Registry und Hullkatalog; AP07-Verifier.
**Interface:** `collect_contacts(world: Dictionary, faction_id: String) -> Dictionary`,
`evaluate_target(shooter: Dictionary, target: Dictionary, weapon: Dictionary, order: Dictionary, world: Dictionary) -> Dictionary`.

- [ ] Rote Tests: unbekanntes Ziel nicht angreifen, Neutraler kein Autoziel, Blocker unterbricht LOS, Ziel außerhalb Reichweite/Feuerkegel gesperrt.
- [ ] Begrenzte Sensor-/Kontaktquery aus Raumindex erstellen; keine Kopie des Boden-FoW. Startregel: Kontakt durch Sensorreichweite und freie 2D-LOS, Verlust nach Überschreiten der Grenze im nächsten Kontakttick. Dunkelheit ändert dies nicht.
- [ ] `build_faction_snapshot` für UI einführen; unbekannte Gegner und fremde Kontakt-/Loadoutdaten fehlen bereits in der Projektion, nicht erst als ausgeblendete Controls.
- [ ] Feste Waffenwinkel und begrenztes Turretschwenken prüfen; `hold` bleibt absolut, Antwortfeuer schützt auch explizites Schutzobjekt. Kandidaten stabil sortieren.
- [ ] AP07/AP06 grün; Commit `feat: resolve known space contacts and fire arcs`.

**Abnahme:** UI/AI kennen dieselben erlaubten Ziele; sichtbare Block-/Feuergründe.

## AP08 — Repeater, Schaden und Friendly Fire

**Dateien:** Neu `scripts/tactical/space_weapon_resolver.gd`,
`data/space/ship_components.json`; ändern Combatstate; AP08-Verifier.
**Interface:** `resolve_shot(request: Dictionary, world: Dictionary, rng_state: Dictionary) -> Dictionary`
liefert ShotEvent/Schadensvorschlag und nächsten reproduzierbaren RNGstate.
Combatstate `commit_shot(event: Dictionary) -> Dictionary`.

- [ ] Rote Tests: gleicher Seed/State ergibt gleichen Schuss; Event-ID doppelt schadet nur einmal; eigener Rumpf vor Gegner fängt den Schuss ab; ungültiger Feuerwinkel erzeugt keinen Schaden.
- [ ] S1–S5-Repeater mit eigenen Werten, Feuerrate und datenbasierten Trefferentscheidungen anlegen. Zielstabilität/relative Bewegung berücksichtigen, keine physikalischen Laserprojektile.
- [ ] Schussbahn trifft deterministisch ersten Rumpf/Blocker, auch freundlich. Gleichzeitige Treffer aus gleichem Ticksnapshot sammeln, dann gemeinsam committen; gegenseitige Zerstörung bleibt möglich.
- [ ] AP08/AP07 grün; Commit `feat: resolve authoritative repeater combat`.

**Abnahme:** Erster kleiner Schusswechsel mit Hüllenschaden/Verlust; VFX noch austauschbare Debugdarstellung.

## AP09 — Installierte Waffen, Schildgenerator und Kraftwerk

**Dateien:** Ändern `scripts/core/singleplayer_ship_equipment_state.gd`,
`scripts/mission/ship_equipment_catalog.gd`, Komponenten-/Hullkatalog,
Combatstate, Root und Flug-/Waffenresolver; AP09-Verifier.
**Interfaces:** Equipment `get_effective_stats(craft_id: String) -> Dictionary`,
`validate_loadout(craft_id: String, slots: Dictionary) -> Dictionary`.
Combatstate `advance_systems(dt: float, equipment: Dictionary) -> void` nur aus Root.

- [ ] Rote Tests: falsche Slotgröße abweisen; mehr Komponentenmasse senkt Beschleunigung; Schild absorbiert vor Hülle; Feuer entleert Reserve; Kraftwerkswechsel verändert tatsächlich Reserve-/Schildaufladung.
- [ ] Rumpfslots und installierte IDs validieren; gemeinsame effektive Werte an Verbraucher liefern. Ein Schildpool, Erholungsverzögerung nach Treffer und begrenzte Reserve.
- [ ] Bestehende Warp-Slots, signierte Prepare/Commit-Transaktionen und
  Checkpoint-/Supply-Quittungen erhalten. Die bisher Warp-spezifische
  Komponentenbilanz vor Erweiterung versioniert und verlustfrei auf die
  neuen Komponentenklassen erweitern; keine parallele Ausrüstungswahrheit.
- [ ] Leistung deterministisch verteilen: benötigter sicherer Flugschub, danach Waffenreserve, danach Schilde; ausgeschöpfte Leistung erzeugt sichtbaren Grund. Keine freie UI-Energieerfindung.
- [ ] AP09/AP02/AP08 grün; Commit `feat: connect ship equipment shields and power`.

**Abnahme:** Alle drei Komponententypen haben nachweisbare Wirkung. Noch kein Verkauf/Einbau über Produktservice vor Savepaket.

## AP10 — Beschützen, Angreifen und gemeinsame Rottenaufträge

**Dateien:** Ändern Wingstate, Order-/Targetingresolver, Root und Panel;
AP10-Verifier.
**Interface:** Wingstate `issue_group_order(order: Dictionary, context: Dictionary) -> Dictionary`;
ein Order besitzt mehrere `wing_ids` und explizite Rollen `escort/intercept/attack`.

- [ ] Rote Fälle: Schutz von Ort/Schiff/Rotte, Ziel- und Bereichsangriff; offensive Eskorte folgt Köder nicht außerhalb pursuit_limit; Schutzzyklus und verlorenes Ziel.
- [ ] Gemeinsame Aufträge mit stabilen IDs, Schutzradius, Verfolgungsgrenze und Rückkehr implementieren. Einzelne Rotte ablösen ohne Abbruch der anderen. Bei zerstörtem Schutzobjekt: zum letzten zulässigen Sammelpunkt, „Auftrag benötigt neues Ziel“.
- [ ] Unterschiedlich schnelle/unvollständige Rotten: keine unendliche Synchronisationswartezeit; nach3s Starttimeout als Testwert sichtbarer Teilauftrag mit verfügbaren Rotten, bei0Teilnehmern Abbruch. Angriff+`hold` meldet „Feuerfreigabe fehlt“ ohne stilles Überschreiben.
- [ ] AP10/AP06/AP09 grün; kleine Fixture zwei eigene Rotten+Großschiff gegen zwei Rotten. Commit `feat: coordinate wing attack and escort orders`.

**Abnahme M2:** Durchgehendes Eskortengefecht; Rollen und Rückkehr funktionieren, keine magische Aggro.

## AP11 — J-Hook, Ausweichstoß und Feuerziehen

**Dateien:** Neu `scripts/tactical/space_maneuver_resolver.gd`,
`data/space/maneuvers.json`; ändern Orderresolver; AP11-Verifier.
**Interface:** `step_maneuver(actor: Dictionary, maneuver: Dictionary, world: Dictionary, dt: float) -> Dictionary`
liefert Phase, Flug-/Feuerabsicht und Rückkehrgrund.

- [ ] Rote Tests: J-Hook dreht Bug bei weiterlaufendem Drift; Ausweichstoß verändert Bahn; Feuerziehen lässt auftragsgebundenen Gegner seinen Schutzauftrag behalten.
- [ ] Für jedes Manöver Eintritt, Phasen, Maximaldauer, Blocker-/Schild-/Auftragsabbruch und Rückkehr festlegen. Combatstate besitzt ManeuverState, Root committet dessen Fortschritt; Resolver bleiben zustandslos. Start-Testwerte: maximal8s pro Soloablauf, keine erneute Auswahl während aktiver Phase. Neubefehl/Partnerverlust invalidieren alte Phasen; Snapshot behält den tatsächlich committeten Fortschritt.
- [ ] Schutzgrenzen und Feuer halten in jeder Phase erneut anwenden; beschädigtes/ungültiges Schiff setzt ab. Rückwärtsfeuer benötigt gültigen Waffenwinkel und Vorhalt.
- [ ] AP11/AP03/AP10 grün; Commit `feat: add drift hooks evasion and diversion maneuvers`.

**Abnahme:** Taktische Wirkung stammt aus echter Bewegung; J-Hook bleibt gekoppelt an gültigen Auftrag.

## AP12 — Erweiterte Manöver und Partnerkoordination

**Dateien:** Ändern Manöverkatalog/-resolver und Orderresolver; AP12-Verifier.
**Interface:** `resolve_partner_maneuver(order: Dictionary, world: Dictionary) -> Dictionary`
liefert Teilnehmer/Phasen/Startbedingungen an denselben Manöverresolver.

- [ ] Rote Tests: Schere, rollendes Ausweichen, Strafe-Adaption und Doppelangriff; Partnerverlust beendet Wartephase; nie Höhenvorteil oder kostenloser Schub.
- [ ] Seitliche Plane-Manöver plus rein optischen `roll_visual`-Wert implementieren. Reine Rotation mit unveränderter Bahn ergibt dieselbe Trefferentscheidung.
- [ ] Doppelangriff mit maximal3s Synchronisationswartezeit als Startwert; danach vorhandenen Soloauftrag fortsetzen und Grund melden. Keine zweite Schiffszuteilung.
- [ ] AP12/AP11 grün; Commit `feat: coordinate planar advanced space maneuvers`.

**Abnahme:** Alle bestätigten Manövernamen haben konkrete, begrenzte Abläufe auf einer Ebene.

## AP13 — Pilotenskill, Freischaltungen und einmalige Erfahrung

**Dateien:** Neu `scripts/tactical/space_pilot_resolver.gd`; ändern
`scripts/meta/mission_progression_resolver.gd`, `scripts/npc/unit_profile_math.gd`,
Manöverresolver/-katalog, Combatresult; AP13-Verifier.
**Interfaces:** `derive_flight_factors(profile: Dictionary) -> Dictionary`,
`build_space_progression_result(encounter: Dictionary) -> Dictionary`;
bestehendes `apply_mission_result` bleibt der Roster-Progressionspfad.

- [ ] Rote Tests: gleiche Hülle, Anfänger/Experte unterscheiden Timing/Stabilisierung, nicht Schubmaximum; beide können gekoppelt/ausgekoppelt fliegen und ausweichen; Duplikatergebnis vergibt keine zweite XP.
- [ ] Kanonisches `platform_values.fighter_piloting` (0–1) konsumieren. Teststart: Reaktionszeit0,6→0,2s und Zielstabilisierungszeit0,8→0,3s über Skill0→1; keine versteckten direkten Schadensboni.
- [ ] Grundmanöver verfügbar; koordinierter Doppelangriff abSkill0,6 pro ausführendem Piloten als tunbarer Startwert. Darunter versetzter normaler Angriff mit verständlichem Hinweis, kein fehlender Grundbefehl.
- [ ] Flugskill über belegte Beiträge steigern, vorhandenes Einsatzlimit maximal0,018 berücksichtigen. Dauerhafte Quittung `encounter_id+pilot_id` vor erneutem Ergebnis prüfen; Manöver im leeren Raum gibt0.
- [ ] AP13 und `task_237_mission_progression_xp_morale_frustration.gd` grün; Commit `feat: progress pilot skill through space combat`.

**Abnahme:** Bestehende Personen werden besser und zeigen warum; keine zweite Pilotenkartei.

## AP14 — Effekte, Schweife und Licht

**Dateien:** Neu `scripts/visuals/space_combat_effects.gd`,
`data/space/combat_visuals.json`; ändern WorldView; AP14-Verifier.
**Interface:** `sync_snapshot(snapshot: Dictionary, events: Array[Dictionary]) -> void`;
nur Darstellung, keine Rootcommands.

- [ ] Rote Checks: doppelte Event-ID erzeugt keinen zweiten Effekt; ausgekoppeltes Gleiten ohne Schub zeigt Hauptstrahl0; Trailpunkte bleiben im Raum und altern aus; nach dem Schuss bewegtes/zerstörtes Ziel verändert gespeicherte Laser-/Treffergeometrie nicht.
- [ ] Repeaterimpulse, Schildeinschlag/Hüllentreffer, klassenabhängige Explosion und Trümmer, Haupt-/Seitendüsen und kurze Trails anbinden. Ereignisse bei Offscreen-Nachladen nicht als vergangene Explosion nachspielen.
- [ ] Startbudgets in `combat_visuals.json`:64sichtbare Lasersegmente,128Düsenemitter,8Explosionssysteme und32Trailpunkte je sichtbarem Schiff; wiederverwendete Pools. Bei Überlauf nur Darstellung nach Entfernung/Alter reduzieren, niemals Schussereignisse oder Simulation verwerfen. AP20 bewertet/tunt diese ausdrücklich vorläufigen Werte.
- [ ] Bestehende Grafikreferenzregel anwenden: eigenes zugeordnetes Effektziel/Manifest, Referenz und echte Aufnahme kennzeichnen. Gleiches Manöver bei Sonne/Schatten mit identischer Kamera aufnehmen; Konturen/Marker bleiben lesbar.
- [ ] AP14 grün; Effektqualität aus/niedrig/normal bei gleichem Seed liefert identischen Simulationshash. Commit `feat: visualize authoritative space combat events`.

**Abnahme M3:** J-Hook/Drift sind an Bug, Bahn und Düsen erkennbar; Rollen verleiht keinen Bonus.

## AP15 — Heimatcheckpoint und Legacydefaults

**Dateien:** Ändern `scripts/meta/campaign_checkpoint_store.gd`,
`singleplayer_runtime_adapter.gd`, `scripts/mission/inventory_transfer_contract.gd`,
`scripts/core/singleplayer_supply_state.gd`, Wing-/Equipment-/Combatstate;
AP15-Verifier.
**Interfaces:** Wing/Equipment `export_state() -> Dictionary`,
`validate_restore(data: Dictionary) -> Dictionary`,
`restore_validated(data: Dictionary) -> void`; Checkpointvalidierung vor jeder Mutation.

- [ ] Rote Tests: alter gültiger Checkpoint ohne neue Felder lädt mit expliziten Defaults; doppelte Craft-/Pilot-/Slotbelegung wird vor Mutation abgelehnt; aktiver Kampf/Awaystate bleibt savegesperrt.
- [ ] Passivdoktrin (`contact_response=avoid`, `fire_rule=hold`) bleibt nach Heimat-Roundtrip erhalten; laufende Kampfaufträge werden nicht als außerhalb der Heimat speicherbar ausgegeben.
- [ ] Heimatcheckpointversion erweitern; Rotten, installierte Teile und Progressionsquittungen speichern. Ohne Alt-Wingfelder bleiben Schiffe unzugewiesen; alte Loadouts bekommen kanonische Rumpfdefaults, keine extern geratenen Werte.
- [ ] Komponenten als kataloggebundene Stückware in bestehenden `items[item_id]=quantity`-Containern zulassen; `known`/Containervalidierung und Supply-Restore gemeinsam erweitern. Installierte Slots speichern `item_id`, keine neue Iteminstanzverwaltung. Legacydefaults erzeugen keine zusätzlichen losen Teile. Große Schiffsteile sind nur in Basis-/Schiffs-/Servicecontainern zulässig, nicht in Personenwaffenslots/Rucksäcken.
- [ ] Bestehendes `all_grounded` nur für Spielerfahrzeuge verwenden; NPC-Registryeinträge blockieren Heimatcheckpoint nicht. Aktive Begegnung separat prüfen. Roster-/Craft-/Itemreferenzen gesamthaft validieren.
- [ ] AP15 plus Fleettravel-Verifier grün; Commit `feat: persist space wings equipment and progression safely`.

**Abnahme:** Echter Heimcheckpoint kann neuen Zustand behalten, korrupter Restore ist atomar; kein Midcombat-Save.

## AP16 — Komponenten über den bestehenden Service tauschen

**Dateien:** Ändern Equipmentstate, `scripts/core/singleplayer_supply_state.gd`,
`scripts/mission/inventory_transfer_contract.gd`,
`scripts/mission/singleplayer_supply_command_contract.gd`, RuntimeAdapter,
`scripts/ui/polisa_station_screen.gd`,
`scripts/meta/singleplayer_services_presenter.gd`;
AP16-Verifier und `docs/dev/polisa_ship_equipment_contract.md`.
**Interface:** Adapteroperation `ship_component_install` mit
`craft_id, slot_id, item_id, source_container_id, quantity=1,
expected_equipment_revision, request_id`;
Root führt Supply/Equipment-Transaktion aus.

- [ ] Rote Tests: falsche Größe, fehlender Bestand, Schiff nicht am Service,
  veraltete Revision, Doppelrequest und fehlgeschlagener Consumer lassen Geld/Bestand/Loadout unverändert.
- [ ] Reale gelandete Craft-/Servicebindung prüfen; Altkomponente in denselben berechtigten Quellcontainer zurückgeben, neue Stückware verbrauchen, effektive Stats atomar ändern. Die komplette Vorher/Nachher-Belegung vor Commit prüfen; fehlender Rückgabeplatz lehnt ohne Teile-/Geldverlust ab. Kein UI-lokaler Bestand und keine vorausgesetzten Iteminstanz-IDs.
- [ ] Waffen-, Schild- und Kraftwerkstausch je einmal mit anschließend geändertem Runtimeverhalten und Heim-Save/Restore nachweisen.
- [ ] AP16/AP09/AP15 grün; Commit `feat: install functional ship components through supply`.

**Abnahme:** Komponententausch ist kauf-/bestands-/savewirksam und idempotent.
Der bereits funktionierende Warp-Slot und dessen Beleg-/Bestandsbilanz bleiben
erhalten; AP16 erweitert den bestehenden Installationspfad für Kampfkomponenten.

## AP17 — Kampagnenbegegnung, Rückzug und Ergebnis

**Dateien:** Ändern `campaign_space_encounter.gd`, RuntimeAdapter,
`campaign_space_encounter_presenter.gd`, `meta_layer_flow.gd`;
AP17-Verifier.
**Interface:** Combatstate `begin_encounter(definition: Dictionary, context: Dictionary) -> Dictionary`,
`get_completed_result() -> Dictionary`; Ergebnis trägt stabile Begegnungs-ID.

- [ ] Rote Tests: Begegnung startet nur einmal aus tatsächlicher Ankunft;
  Gegner/Neutraler starten an validen Kartenpositionen; Quantum/Anflug/Landung während Kampf abgelehnt; Rückzug beendet erst bei realem Austritt.
- [ ] Bisherigen festen Schadentick durch allgemeinen Owner ersetzen, bestehende Rettungs-/Neutralitäts-/Ergebnisfolge erhalten. Legacy-Encounter darf nicht parallel Schaden oder Zeit fortschreiben.
- [ ] Root bestätigt Eintritt/Austritt atomar, behält tatsächliche Exitpose, Schäden und Reserven. Kein Teleport zum Startorbit, keine Schildheilung durch Ansichtwechsel. Fuel und Missionsergebnis jeweils einmal buchen.
- [ ] Bestehende Besatzungs-/Schiffsverlustpfade ausdrücklich anschließen; keine neue Respawnökonomie. Progressionsresultat aus AP13 über bestehenden Rosterpfad anwenden.
- [ ] AP17 plus `campaign_space_encounter_verifier.gd`, `space_travel_state_verifier.gd` grün; Commit `feat: integrate tactical space combat into campaign travel`.

**Abnahme M4:** Abflug → Begegnung → Sieg/Rückzug/Verlust → zulässige Heimkehr →
Komponententausch → Heimcheckpoint → Continue. Fremdort-/Kampfcheckpoint bleibt gesperrt.

## AP18 — Hostautorität und Clientprojektion

**Dateien:** Ändern `scripts/multiplayer/multiplayer_command_contract.gd`,
`scripts/multiplayer/multiplayer_snapshot_contract.gd`,
`scripts/multiplayer/multiplayer_session.gd`, Root/Space-Commandvertrag;
AP18-Verifier.
**Interface:** Bestehenden Netzwerk-Envelope für `space_combat` adaptieren;
Hostzustand und Readsnapshots aus AP01/AP04/AP08 übertragen, keine Client-Ticks.

- [ ] Rote Fälle: Client versucht fremde Rotte, internen Damage-/Tickcommand,
  veralteten Auftrag oder forged Skillwert; Host lehnt ohne Mutation ab.
- [ ] Negativer Snapshottest: Host serialisiert pro berechtigter Fraktion den AP07-Filter. Unbekannte Gegner-IDs/Positionen, gegnerische Orders/Loadouts und fremde Kontaktlisten fehlen im tatsächlichen Payload. Ereignisgeometrie/IDs werden ebenfalls entsprechend Kontaktberechtigung gefiltert, nicht erst clientseitig versteckt.
- [ ] Ownership aus Hostverbindung beziehen, Requestreplays idempotent halten,
  Ereignis-/Snapshotrevisionen und ManeuverState stabil übertragen. Lokale Kamera bleibt lokal.
- [ ] Kleiner Zwei-Prozess-Test mit Befehl, Schaden, Rotte ablösen und Verbindungsausfall; ein weiterlaufender Host, kein doppelter Schaden beim Wiederholen.
- [ ] AP18 plus bestehender `task_166_multiplayer_authority_command_contract_verifier.gd` grün; Commit `feat: enforce host authority for space orders`.

**Abnahme:** Lokale Host/Client-Grenze belegt. LAN/WAN und allgemeine Multiplayerfreigabe benötigen eigene Evidenz.

## AP19 — Native Bedien- und Sichtabnahme

**Dateien:** Neu `scripts/tests/space_combat_native_fixture.gd`,
`scenes/tests/space_combat_native_fixture.tscn`,
`docs/qa/space_combat_native/README.md`; nur gezielte Produktkorrekturen.
**Interface:** Fixture erzeugt normale Rootcommands und echte Snapshots;
Capturesteuerung setzt keine Siege, Treffer oder Pilotenwerte im Produktpfad.

- [ ] Feste Fixture auf derselben Sternkarte: zwei eigene Rotten zu je2Jägern,
  Großschiff, zwei Gegnerrotten; separate Varianten mit1 und6Mitgliedern.
- [ ] Normale Mausbedienung: zusammenstellen, Mehrfachauftrag, Schutz,
  Ziel-/Bereichsangriff, Feuer halten/frei, Rückzug, Rotte ablösen;
  Prüfung bei1280×720 und1920×1080.
- [ ] Kurze native Clips von gekoppelt/Drift/J-Hook/Rolle/Strafe und Explosion
  unter Sonne/Schatten öffnen und beurteilen. Modell, Bug, Flugbahn, Treffer,
  kritischer Schild und Auftrag müssen unterscheidbar sein.
- [ ] Sichtbare Fehler gezielt beheben und nur betroffene Probe wiederholen.
  Nutzerurteil/ausstehende Stilabnahme ausdrücklich dokumentieren; Commit
  `test: document native space combat usability evidence`.

**Abnahme:** Echte Bedienung und tatsächlich importierte Darstellung belegt;
Screenshots/Headlesschecks allein belegen keine Bewegungsqualität.

## AP20 — Performance, Fortlaufen außerhalb der Ansicht und Abschluss

**Dateien:** Neu `scripts/tests/space_combat_performance_probe.gd`,
`docs/qa/space_combat_performance/README.md`; gegebenenfalls gezielte
Index-/VFXkorrekturen mit kleinem Verifier.
**Interface:** Probe liest Tick-/Query-/Event-/Framecounter, schreibt keine Kampfergebnisse.

- [ ] Fixierte Seeds/Szenario/Kamera/Renderer/Hardware messen: Basis9Schiffe
  (8Jäger+Großschiff), Last25Schiffe (4Rotten×6+Großschiff), jeweils60s nach Warmup.
- [ ] VFX an/aus und Karte sichtbar/verdeckt vergleichen: identische Gameplay-
  Resultate; keine SceneTree-Vollscans, begrenzte Spatialqueries und Effektobjekte.
  Simtickverlust, CPU/GPU, P50/P95/P99 und Maximalhitches getrennt berichten.
- [ ] Vorläufiges Ziel für den Referenz-PC: bei1920×1080 P95Framezeit≤33,3ms,
  keine verlorenen autoritativen Ticks; Quoten nur bei dokumentiert gleicher
  Last/Bedingung werten. Bei Fehlschlag Ursache und kleinen Folge-AP benennen,
  nicht Simulation/Schiffsanzahl unbemerkt reduzieren.
- [ ] Nur betroffene Regressionen und finalen Heim-Continue-/Authority-Smoke
  laufen lassen. F01–F16 anhand echter Belege schließen, offene Stil-/Netz-/
  Leistungsgrenzen ausweisen; Commit `test: record bounded space combat acceptance`.

**Abnahme M5:** Konzeptumfang technisch und nativ belegt oder ausdrücklich
offen markiert. Kein automatischer Mainmerge, Release oder EXE durch diesen Plan.

## Festlegungen → Pakete

| Konzept | Zuständige AP |
| --- | --- |
| F01 Ebene/2,5D | 01,03,05,12,14,19 |
| F02 Hexgrößen/Mehrhexrümpfe | 02,03,05 |
| F03 Rotten1–6 | 04,05,15,19 |
| F04 gemeinsame Aufträge | 10,12,18 |
| F05 Befehle | 06,10,17,19 |
| F06 Beschützen | 07,10 |
| F07 Haltung/Feuerregel | 06,07,10 |
| F08 beide Flugarten | 01,02,11,19 |
| F09 Masse/Schub/Trägheit | 02,09 |
| F10 Manöver | 11,12,13,19 |
| F11 Feuerziehen | 10,11 |
| F12 Skill/Progression | 13,15,17 |
| F13 Repeater/Slots | 08,09,16 |
| F14 Komponenten | 09,15,16 |
| F15 Effekte | 14,19,20 |
| F16 Licht/Schatten | 07,14,19 |

## Offene Balance und begrenzte Folgearbeit

Exakte Rumpf-/Waffenwerte, Sensorreichweiten, Schutzradien, Skillkurven und
Effektbudgets werden in den kleinen Fixtures abgestimmt. Die Verträge, Grenzen
und Verbraucher sind festgelegt; Werte werden vor dem jeweiligen grünen Test
im Katalog konkret dokumentiert. Eine Framerate-/Stilabnahme wird nicht aus
einem bestandenen Domaincheck abgeleitet.

Nicht Teil dieser ersten Umsetzung: Raketen/Torpedos, echtes räumliches
Quadstrafe/Höhenkampf, Rammen, aktive Stealth-/Nacht-Sensorik, Energiemanagement-
Cockpit, neue Schiffmodellserien, neue Versicherungs-/Rettungsökonomie,
Midcombat-/Away-Saves oder Matchmaking.

Für die spätere Durchführung ist paketweises Implementieren mit frischem
Review sinnvoll: insbesondere AP01, AP03, AP10, AP15–18 besitzen gemeinsame
Owner-/Lifecyclegrenzen. Der aktuelle Auftrag endet beim geprüften Plan.
