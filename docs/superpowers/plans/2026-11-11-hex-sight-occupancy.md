# Hexsicht, Erkennung und Feldreservierung Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Sicht und Erkennung auf verbindlichen Hexpositionen vereinfachen und
genau einen Ground-NPC pro Feld mit tatsächlich ausgeführter Engpassreservierung
bei weiterhin flüssiger Darstellung ermöglichen.

**Architecture:** SimulationRoot besitzt den logischen Ground-State und committet
Bewegung/Reservierungen. Bestehende Terrain-, LOS-, Cache-, Kontakt-, FTL- und
Commandpfade werden angeschlossen; reine Resolver liefern Vorschläge.
Sicht und Bewegung nutzen dieselben Rampenanschlüsse und Standhöhen.

**Tech Stack:** Godot 4.6.2, GDScript, vorhandene Python-Isolationshelfer,
versionierte Map-/Save-Daten. Keine neue Engine oder Bibliothek.

**Spec:** [Entwurfsgrundlage](../specs/2026-11-11-hex-sight-occupancy-design.md)
und [Task](../../tasks/HEX_SIGHT_OCCUPANCY_2026_11_11_PLAN.md).

## Global Constraints

- Die Berechnung verwendet das logische Hexfeld; Figuren bewegen sich sichtbar flüssig.
- Ein am Boden befindlicher NPC belegt genau ein Hexfeld, teamübergreifend.
- Bewegungsschüsse bleiben möglich; ihr Trefferabzug hängt vom Skill ab.
- Selbstständiges Reagieren auf Geräusche hängt von Skill und Auftrag ab.
- `SimulationRoot` committet State; UI und Visuals bleiben Leseschichten.
- `hex_axial_v1`, sechs Nachbarn, keine SceneTree-Vollscans oder Vollkartenjobs pro Frame.
- `terrain_height_rules = "explicit_hex_ramps_v1"`; H0/H1-Plateaukante gesperrt,
  Rampenstandhöhe H+0,5, längs in beide Richtungen begehbar; seitliche Enden
  H+0,5 verbinden nur passende Rampen, keine normalen Plateaus.
- A/B/C bleiben 512×256; Sternkarte bleibt 256×256.
- Neue Produktlogik nach `scripts/core/`, `scripts/mission/` oder `scripts/tactical/`;
  keine neue Produktlogik unter `scripts/tests/` oder `scripts/simulation/`.
- Jetzt nur Planung. Bei späterer Umsetzung kleine isolierte Checks pro Paket;
  große Tests ausschließlich im zurückgestellten AP9 nach späterem Nutzerauftrag.
- Kein Mainmerge, keine EXE und keine behauptete Performancefreigabe durch diesen Plan.

## Review Focus

1. Langsame/festgehaltene Figur vor einer Kolonne: kein Folgender betritt ihr Feld;
   erlaubte nachfolgende Schritte werden trotzdem atomar und flüssig gestartet (AP4/5).
2. Tür, Rampe oder Höhenprofil ändert sich bei aktiver Sicht/Bewegung: kein veralteter
   Treffer, kein regelwidriger Seitenwechsel und kein abgeschnittenes H+0,5 (AP2/4/5).
3. Aussteigen/Respawn/Continue mit belegter Fläche: alle IDs bleiben erhalten,
   keine doppelte Zelle, keine fingierte vollständige Einsetzung (AP6/7).
4. Gegner verborgen, nur gehört oder per Relay gemeldet: kein bestätigtes Ziel,
   keine versteckten IDs/Reservierungen im Client-Snapshot (AP3/7).
5. Auftragswechsel, Verwundung oder Teardown im halben Schritt: genau ein Owner,
   keine fremde Positionskorrektur und keine hängenden Reservierungen (AP5/6).

## Arbeitsbasis und Prüfpolitik

Dieser Doku-Branch basiert bewusst auf dem noch nicht integrierten
Kampagnenstand `e4b407fe0598f1f601b40177c7fec408fd73618c`.
Zusätzlich gelesen: nativer Kartenstand
`4e44521fd1c0e512d725d28e58fc910d4948e56b` und dessen weiterhin uncommitteter
Rampenvertrag einschließlich breiter Rampenbänder und gemeinsamer Eckprofile.
Die in diesem Branch fehlenden Rampen-APIs sind **Eingaben von AP0**, kein
Auftrag, fremde uncommittete Dateien zu kopieren. Vor Runtime-Arbeit den dann
gemeinsam integrierten Stand prüfen und einen frischen Taskbranch davon anlegen.
Nicht auf einem alten August-Integrationsstand oder fremder WIP weiterbauen.

Die Zahlen der bisherigen Diagnose sind Motivation, keine Zielabnahme:
Erkennungsprüfung ca.15 ms/Tick und Sicherung ca.13–15 ms/Aufruf im älteren
16v12-Square-Fixture; initiale Zielsuche ca.26 ms, später meist ca.0,5 ms.
Der vorhandene Zielindex darf nicht durch eine erneute Vollsuche ersetzt werden.

Alle folgenden Checkbefehle sind **für die spätere Umsetzung**, jetzt nicht
auszuführen. Der in AP1 angelegte Runner startet exakt eine ausgewählte kleine
Fixture in einem frischen Privatprofil. Keine automatische 90-Gate-Matrix,
kein Vollbildlauf, keine A/B/C-Gefechte und keine Testwiederholungsschleife.
PASS bedeutet Exit0, passender Marker, keine Script-/Leakfehler und unverändertes
echtes Profil; FAIL/alte Baselinefehler werden getrennt ausgewiesen.

## Dateien und Verantwortlichkeiten

| Datei | Verantwortung |
|---|---|
| `scripts/core/hex_ground_runtime.gd` (neu) | Ein logischer Ground-State, Belegungsindex und committed Segmente/Reservierungen; nur über SimulationRoot mutiert |
| `scripts/core/hex_visibility_query.gd` (neu) | Reine Hexreichweiten-/Kegel-/Terrainabfrage |
| `scripts/core/hex_detection_state.gd` (neu) | Eine Erkennungsepisode je Beobachter/Ziel mit festen Fälligkeitsticks |
| `scripts/core/simulation_root.gd` | Configure, Commandannahme, atomarer Bewegungscommit, Lifecycle und Authority |
| `scripts/mission/combat_visibility_cache.gd` | Bestehenden Cache um langlebige Hexgeometrie ergänzen, kein Kontaktwissen |
| `scripts/core/los_system.gd`, `scripts/core/fog_of_war_system.gd` | Gemeinsame Queryadapter und vorhandene begrenzte FoW-Publikation |
| `scripts/tactical/bottleneck_reservation_resolver.gd` | Begrenzte reine Hex-Planung und Korridor-/Vorfahrtsvorschläge |
| `scripts/tactical/fireteam_movement_controller.gd`, `scripts/tactical/fireteam_security_controller.gd` | Bestehende Befehle/Sicherung mit logischer Bewegung/Blickrichtung verbinden |
| `scripts/tests/mission_combat_loop_driver.gd` | Nur vorhandene Orchestrierung auf gemeinsame Runtimehelper umstellen |
| `scripts/tactical/combat_fire_decision_resolver.gd`, `scripts/tactical/contact_tracker.gd` | Schusszulässigkeit und bestehendes Kontaktwissen erhalten |
| `scripts/terrain/terrain_map_data.gd` | Explizite neue Taktikkennung erhalten/validieren, keine Topologieumdeutung |
| `scripts/core/base_personnel_runtime.gd`, `scripts/meta/singleplayer_runtime_adapter.gd` | Basis-/Transport-/Checkpointadapter, keine zweite Belegung |
| `scripts/mission/hex_ground_admission.gd` (neu) | Reine begrenzte Gruppenplatzierung aus bestehendem Anker |
| `scripts/tests/run_hex_tactical_check.py` (neu) | Ein-Case-Runner mit bestehendem `create_overlay` und frischem Schutzbaseline |
| `scripts/tests/hex_*_verifier.gd` (neu, je AP benannt) | Kleine isolierte Fixtures; große Laufzeitmessung erst AP9 |

---

### AP0: Rampenabhängigkeit und konkreten Startstand sichern

**Files:** Lesen: `docs/dev/explicit_hex_ramps_contract.md`,
`scripts/terrain/terrain_tile_data.gd`, `scripts/terrain/terrain_registry.gd`,
`scripts/terrain/terrain_pathfinder.gd`, `scripts/terrain/hpa_navigation_graph.gd`,
`scripts/terrain/hpa_pathfinder.gd`. Dokumentieren: diese Task-/Spec-/Plan-Dateien.

**Interfaces:** Eingabe: `TerrainTileData.allows_step(from_tile, to_tile) -> bool`,
`endpoint_height(tile, neighbor_grid: Vector2i) -> float`, `stand_height(tile) -> float`;
`TerrainRegistry.get_stand_height_at(grid: Vector2i) -> float`;
`TerrainPathfinder.can_traverse_step(from_grid, to_grid, registry) -> bool`.
Ausgabe: ein benannter gemeinsam integrierter Startcommit und API-Abgleich.

- [x] Relevante Regeln, Git-/Worktreestatus und den dann aktuellen Rampencommit lesen.
- [x] Prüfen, dass Version/Richtung serialisiert und revisioniert sind, beide
  Längsenden und passende seitliche Rampenanschlüsse legal sind und A*/HPA/
  Bewegung denselben Übergangspfad verwenden. Breiten-/Eck-/Editorregeln
  gehören dem Kartentask; hier keine alternative Rampenimplementierung anlegen.
- [x] Den Startcommit, eigene Dateigrenzen und ggf. konkrete APIabweichungen in
  der Taskdatei festhalten. Bei fehlender Rampenbasis keine alternative Rampe bauen.
- [x] Nur Dokument-/Diffprüfung ausführen; keine eigene große Rampenmatrix starten.
- [x] Den abgeglichenen Dokumentationsstand separat committen, falls verändert.

### AP1: Versionierter logischer Ground-State und kleine Prüfgrundlage

**Files:** Neu: `scripts/core/hex_ground_runtime.gd`,
`scripts/tests/hex_ground_state_verifier.gd`, `scripts/tests/run_hex_tactical_check.py`.
Ändern: `scripts/core/simulation_root.gd`, `scripts/terrain/terrain_map_data.gd`.
Vertrag: `docs/dev/hex_tactical_runtime_contract.md` (neu, aus dieser Spec ableiten).

**Interfaces:** `HexGroundRuntime.configure(registry: Node, map_id: String, tick: int) -> void`;
`admit_units(placements: Array[Dictionary]) -> Dictionary`;
`read_unit(unit_id: String) -> Dictionary`; `build_planning_snapshot() -> Dictionary`;
`release_unit(unit_id: String, reason: String) -> void`; `clear() -> void`.
Placement: `{unit_id, grid: Vector2i, facing_dir: int, posture_key: String}`.
Read: zusätzlich `stand_height_steps2`, `state_revision`, `movement_state`.
SimulationRoot: `configure_hex_ground_runtime(map_data, terrain_registry) -> Dictionary`
und `get_hex_unit_state(unit_id: String) -> Dictionary` als Read-Einstieg.
MapData: `get_tactical_grid_rules() -> String`, `set_tactical_grid_rules(value: String) -> void`.

- [ ] Runner mit genau den Cases `ground`, `visibility`, `detection`, `reservation`,
  `movement`, `lifecycle`, `save_network`, `slice` anlegen. Vorhandenes
  `run_review2_isolated.create_overlay` verwenden; keine alte eingefrorene
  QA-Rosterbaseline voraussetzen. Quellen-/Profilzustand neu read-only erfassen.
- [ ] RED-Fixture schreiben: doppelte Zellzulassung lässt alle bisherigen
  Platzierungen unverändert; eine erlaubte Rampenzelle liefert bei H=2 den
  Höhenwert `5` in halben Stufen. Kennung roundtrippt; ohne Kennung Legacy.
- [ ] `python scripts/tests/run_hex_tactical_check.py --case ground` ausführen;
  nur die neue fehlende Schnittstelle/Invariante darf RED verursachen.
- [ ] State, Indizes und Versionsgate implementieren. Unbekannte Kennung oder
  Kennung mit `square8` meldet einen Load-Issue. Keine Karte jetzt aktivieren.
- [ ] Denselben Check GREEN ausführen; genau betroffene Dateien und Vertrag
  committen: `feat: add authoritative hex ground state`.

### AP2: Hexsicht und tickübergreifende Geometriewiederverwendung

**Files:** Neu: `scripts/core/hex_visibility_query.gd`,
`scripts/tests/hex_visibility_verifier.gd`. Ändern:
`scripts/mission/combat_visibility_cache.gd`, `scripts/core/los_system.gd`.

**Interfaces:** `HexVisibilityQuery.evaluate(observer: Dictionary, target: Dictionary,
terrain_registry: Node, profile: Dictionary) -> Dictionary` liefert
`{in_range, in_arc, terrain_clear, visible, reason}`. Profil:
`{range_hex: int, arc_degrees: float}` plus vorhandene Höhen-/Haltungsparameter.
`CombatVisibilityCache.query_hex_visibility(observer, target, terrain_registry, profile) -> Dictionary`
verwendet diese Regeln; die alten booleschen LOS-Einstiege bleiben kompatibel.
Die Aufnahme neuer Profilfelder erfordert einen Key-/Invalidierungscheck.

- [x] RED-Fixture: sechs Rotationen, Rand bei ±60 Grad, sichtbare Linie und
  Vollblocker, Rampenhöhe H+0,5 ohne int-Verlust; vorhandene Legacy-Wandgrenze.
  Gleiche logische Abfrage in zwei Ticks erzeugt genau eine Terrainprüfung;
  reine Renderbewegung keine zusätzliche, Tür-/Rampenrevision eine neue.
- [x] `python scripts/tests/run_hex_tactical_check.py --case visibility` RED prüfen.
- [x] Zuerst Hexdistanz/Blickkegel filtern, dann kanonische Hexlinie auswerten.
  Reine Geometrie nach Spec cachen; `begin_tick` leert nur Legacy-Tickdaten.
  Karte/Registryidentität berücksichtigen, Key-Höhen als halbe Stufen führen.
  Cache auf 16.384 Beziehungen begrenzen; keine Weltkartenmaske je NPC anlegen.
- [x] Denselben Check GREEN ausführen und maximal den unmittelbar betroffenen
  vorhandenen LOS-Nachbarn prüfen. Keine neue Sicht-/Deckungsbalance einführen.
- [x] Commit: `perf: reuse hex visibility geometry across unchanged ticks`.

### AP3: Gemeinsame Sicht für Erkennung, Sicherung, Schussprüfung und FoW

**Files:** Neu: `scripts/core/hex_detection_state.gd`,
`scripts/tests/hex_detection_verifier.gd`. Ändern:
`scripts/tests/mission_combat_loop_driver.gd`, `scripts/core/fog_of_war_system.gd`,
`scripts/tactical/contact_tracker.gd`, `scripts/tactical/combat_fire_decision_resolver.gd`,
`scripts/tactical/fireteam_security_controller.gd`, `scripts/tactical/overwatch_controller.gd`,
`scripts/tactical/flank_vulnerability_resolver.gd`; bei nötig enger Auftragsadapter
`scripts/tactical/fireteam_behavior_resolver.gd`. Neue Fachlogik bleibt in core/tactical.

**Interfaces:** `HexDetectionState.observe_pair(observer_id: String, target_id: String,
visible: bool, now_tick: int, delay_ticks: int) -> Dictionary` liefert
`{episode_started, ready_tick, detection_complete, lost}`;
`forget_unit(unit_id: String) -> void`, `clear() -> void`.
Driver konsumiert AP1/AP2 statt separater Weltpositions-/LOS-Rekonstruktionen.
SimulationRoot ergänzt `queue_hex_facing_intent(unit_id: String, direction: int,
command_id: String, reason: String, ready_tick: int = -1) -> Dictionary` für
zulässige interne Runtimeabsichten. Kleiner zusätzlicher Delayparameter dient
dem vorhandenen skillabhängigen Reaktionszeitwert.

- [ ] RED-Fixture: wiederholtes Observe im selben Tick erzeugt keine zweite
  Episode; ein Deadlinewert bleibt bei unveränderter Sicht stabil; echte
  Sichtlücke setzt gemäß Kontaktvertrag zurück. Hörhinweis/Relay bestätigt
  keinen Feind. Ein Sicherungsauftrag darf nicht durch freien Nachsehauftrag
  ersetzt werden. Zwei Queryverbraucher teilen Terrainprüfung.
- [ ] `python scripts/tests/run_hex_tactical_check.py --case detection` RED prüfen.
- [ ] Erkennungsfortschritt in genau einen Helper überführen, bestehende
  Timer-/Cooldownkadenz und beobachteten Zielindex erhalten. Direkte Sicht,
  Kontaktwissen und Schusszulässigkeit separat behandeln. Sichtfilter vor
  Geometrie anwenden; bestehende 126-Grad-Sicherung zentral auf den vorgeschlagenen
  konfigurierbaren V1-Wert abstimmen, keine zweite Winkeltabelle behalten.
  Entfernung, Deckungsseite, Flankierung und Overwatch lesen dieselben logischen
  Zellen; Kompatibilitätshelper bekommen daraus abgeleitete Zellmitten statt
  kontinuierlicher Actorpositionen. Gruppensicherung bleibt die Summe der
  zugewiesenen individuellen Sektoren, kein allsehender Einzel-NPC.
- [ ] Vorhandene Geräusch-/Feuerereignisse auf ein einmaliges, durch Skill und
  Auftrag erlaubtes Facing-/Meldeereignis abbilden. Falls ein Geräuschproducer
  fehlt, das offen dokumentieren und als gesonderten Eventhook behandeln;
  keine neue Schallphysik oder pro-Frame-Zufallsprobe. Bewegungsschüsse bleiben
  zulässig; vorhandene Bewegungs-/Skillmodifikatoren verwenden. Fehlt ein
  konkreter Abzugswert, diesen vor Aktivierung als Balanceentscheidung markieren.
- [ ] Denselben Check GREEN und nur den direkt betroffenen Kontaktvertrag-
  Nachbarn prüfen; Commit: `refactor: share hex perception across combat readers`.

AP3-Kernanschluss ergänzt: Facing24/0, Security34/0, Consumer39/0, Owner39/0,
Ground25/0. Geräuschproducer fehlt als Gameplayquelle; adressierter Hook steht,
kein Kontakt aus einem Geräusch. Konkreter skillabhängiger Bewegungsschussabzug
bleibt vor AP5-Aktivierung als Balancepunkt offen. Keine Karte umgestellt;
Sandboxhooks statisch geprüft, kombinierter Check-only bei Integration.
QA docs/qa/hex_facing_security_20261111.

### AP4: Zeitfenster und faire Engpassplanung

**Files:** Ändern: `scripts/tactical/bottleneck_reservation_resolver.gd`,
`scripts/core/hex_ground_runtime.gd`. Neu: `scripts/tests/hex_reservation_verifier.gd`.

**Interfaces:** `BottleneckReservationResolver.build_hex_plan(requests: Array,
ground_snapshot: Dictionary, terrain_registry: Node, options: Dictionary = {}) -> Dictionary`.
Request: `{unit_id, command_id, priority, path_grid_points, duration_ticks_by_step}`.
Plan: `{expected_revision, terrain_revision, accepted_steps, waits, blocked,
pending_requests, corridor_grants}`. Schritte enthalten die in der Spec benannten
Segmentzeiten. `HexGroundRuntime.commit_plan(plan: Dictionary, expected_revision: int) -> Dictionary`
validiert und committet alles oder nichts. Alte MAPF-Light-Einstiege bleiben Legacyadapter.

- [ ] RED-Fixture auf höchstens zwölf Feldern: gleichgerichtete Kolonne,
  überlappende Gegenkante, besetzter Ausgang, langsamere Führungsfigur,
  Auftragspriorität mit Wartezeit, sechsfach gedrehte Rampen und fehlender
  Ausweichraum. Passende Seitenrampen verbinden ein zweispuriges Band;
  Plateau-/Höhenfehlanschlüsse bleiben gesperrt. Das Band darf nicht allein
  wegen seines Tiletyps als einspuriger Gang gelten. Über 16 Anfragen dürfen
  pending bleiben, keine verschwinden.
- [ ] `python scripts/tests/run_hex_tactical_check.py --case reservation` RED prüfen.
- [ ] Feld- und Kantenintervalle einschließlich stehender Figuren planen;
  zugesagte Freigaben nur mit gemeinsam committetem Folgeschritt nutzen.
  Dauerhafte Zusagen hält der Ground-Owner, nicht ein lokales Resolverdictionary.
- [ ] Korridore mit sechs Nachbarn und gemeinsamer Terrainprüfung erkennen,
  pro Terrainrevision cachen; breite Rampenbänder und Kurven nach ihrem legalen
  Übergangsgraph behandeln, ohne pauschale Einspurensperre. Drei Übergänge
  voraus, 16 neue Anfragen/Tick,
  Rücksetzsuche maximal 64 Felder. Belegte Passage räumen lassen, dann
  abgeschlossene Gruppen fair durchlassen; `blocked/no_passing_space` ruhig erhalten.
- [ ] GREEN einschließlich Revisionskonflikt/keiner Teilmutation prüfen;
  Commit: `feat: plan exclusive hex cells and corridor reservations`.

### AP5: Reservierungen in die tatsächliche Bewegung übernehmen

**Files:** Ändern: `scripts/core/simulation_root.gd`,
`scripts/core/hex_ground_runtime.gd`, `scripts/tactical/fireteam_movement_controller.gd`,
`scripts/terrain/terrain_map_3d_view.gd`. Neu: `scripts/tests/hex_movement_verifier.gd`.

**Interfaces:** `HexGroundRuntime.advance_tick(tick: int) -> Array[Dictionary]`
liefert committed Feldwechsel/Ankünfte;
`get_motion_projection(unit_id: String, interpolation_fraction: float) -> Dictionary`
liefert nur `{position_world, stand_height_world, facing_angle, moving}`.
SimulationRoot ergänzt `has_hex_destination_arrived(unit_id: String, command_id: String) -> bool`.
Schrittdauer stammt aus vorhandener effektiver Bewegungsgeschwindigkeit und
Terrainfaktoren; physisches Hexmaß, keine projizierte Bildschirmdistanz.

- [ ] RED-Fixture: zwei folgende NPCs durch mehrere Felder, keine Gleichbelegung
  an der Handoffgrenze, Gegenverkehr wartet, alle sechs Richtungen gleich schnell.
  Rampe längs auf/ab legal, seitlich nur zu passender Rampe gleicher Endpunkthöhe;
  seitlicher Plateauanschluss gesperrt. Gerade und geknickte Rampenbandnaht
  verwenden dieselbe Übergangsquelle. Revisionswechsel vor Eintritt
  verhindert ihn. Auftragswechsel/Verwundung lässt keine fremde Reservierung stehen.
- [ ] `python scripts/tests/run_hex_tactical_check.py --case movement` RED prüfen.
- [ ] Neue Commands über Resolver und atomaren Commit führen, Feldwechsel vor
  Sicht-/Effectverbrauch des Ticks publizieren. Folgeschritte ohne Halt an
  jeder Feldmitte starten. Aktive Segmente aus bestehendem Tickdelta ableiten;
  Renderframes dürfen weder Feldwechsel noch Wahrnehmungswürfe auslösen.
- [ ] Für aktive Hex-NPCs kontinuierliches positionsmutierendes Avoidance/
  Minimum-Spacing aus dem alten Pfad ausschließen; für Legacy-NPCs erhalten.
  Projektion, Animation und Picking lesen den neuen Zustand. Türblockierung
  während zugesagter Passage beim bestehenden Terrain-/Türmutationsowner ablehnen
  oder bis zur Freigabe warten lassen; keine Teleports oder unpassierbaren Cuts.
- [ ] GREEN mit räumlicher Exklusivität und tatsächlicher Zielankunft prüfen;
  Commit: `feat: execute reserved hex movement with continuous projection`.

### AP6: Einsetzen, Aussteigen, Basisaktionen und Entfernen

**Files:** Neu: `scripts/mission/hex_ground_admission.gd`,
`scripts/tests/hex_ground_lifecycle_verifier.gd`. Ändern:
`scripts/core/simulation_root.gd`, `scripts/core/base_personnel_runtime.gd`,
`scripts/tests/mission_test_setup.gd` (nur bestehender Setupadapter),
`scripts/tests/mission_combat_loop_driver.gd` (nur bestehender Deployadapter),
`docs/ARCHITECTURE.md`, `docs/dev/base_automatic_rest_contract.md`.

**Interfaces:** `HexGroundAdmission.plan_group(unit_ids: PackedStringArray,
anchor_grid: Vector2i, terrain_registry: Node, ground_snapshot: Dictionary,
max_expansions: int = 64) -> Dictionary` liefert
`{ok, placements, waiting_unit_ids, reason}` ohne Stateänderung.
Placement-/Commitpfad aus AP1; Ankunft aus AP5, keine neue Basiswegwahrheit.

- [ ] RED-Fixture: vier Personen/vier legale Felder, nur drei freie Felder,
  Rampe neben Anker, Person an Bord ohne Groundclaim, Verwundeter mit Claim,
  Missionwechsel und zweimaliges Entfernen. Kein verlorener NPC/keine Teilzulassung.
- [ ] `python scripts/tests/run_hex_tactical_check.py --case lifecycle` RED prüfen.
- [ ] Legale Gruppenfelder begrenzt aus vorhandenem Anker entlang zulässiger
  Terrainübergänge vergeben. Bereits vom Transportowner festgelegte Ausstieg-
  und Ladephasen erhalten. Bei Platzmangel warten statt Personen verschwinden
  oder auf dem Anker stapeln lassen; fremde Schiffsfootprints berücksichtigen.
- [ ] Basis-`_walk` weiter Absichten senden lassen; `_on_tick` liest wirkliche
  Ankunft/Abbruch. Boarding, Bettbelegung und Auto-Ruhen bleiben bei ihren
  vorhandenen Ownern. Tod/Despawn/Abbruch räumen Claims und Zusagen genau einmal.
- [ ] GREEN und höchstens den unmittelbar betroffenen Basis-/Deploy-Nachbarn
  prüfen; Commit: `feat: preserve hex occupancy through ground unit lifecycle`.

### AP7: Save-/Restore- und Authoritygrenzen

**Files:** Neu: `scripts/tests/hex_ground_save_network_verifier.gd`. Ändern:
`scripts/core/hex_ground_runtime.gd`, `scripts/core/simulation_root.gd`,
`scripts/meta/singleplayer_runtime_adapter.gd`, `scripts/core/base_personnel_runtime.gd`;
`scripts/mission/mission_combat_authority_contract.gd` als Payloadadapter.
Verträge: `docs/dev/hex_tactical_runtime_contract.md`,
`docs/dev/multiplayer_snapshot_replication_contract.md`.

**Interfaces:** `HexGroundRuntime.export_state() -> Dictionary` liefert
`{schema: "hex_ground_v1", map_id, units, active_segments}`;
`restore_state(state: Dictionary) -> Dictionary` validiert atomar und baut
erforderliche Zusagen neu auf. Keine Cache-/Queue-Dictionaries serialisieren.
Bestehende Checkpoints erhalten optional `hex_ground`, ohne alte Pflichtkeys zu entfernen.

- [ ] RED-Fixture: Legacy ohne Kennung bleibt Legacy, neuer Stand roundtrippt
  Zelle/Facing/Segmentfortschritt, doppelte Restorezelle wird ohne Teilmutation
  abgelehnt. Verdeckter Gegner erscheint weder als ID noch als Reservierung
  im Peerpayload; vom Client gesendete Belegung/Sicht wird abgelehnt.
- [ ] `python scripts/tests/run_hex_tactical_check.py --case save_network` RED prüfen.
- [ ] Neue Komponente versionieren; bekannte Map-/Rampenmetadaten erhalten.
  Bestehende Reise-/Mehrort-Savegates nicht lockern und alte Dateien nicht
  automatisch überschreiben. Pending Legacy-Conversion nur ausdrücklich anbieten.
- [ ] Sichtbare Unitprojektion an bestehende hostautoritative Snapshots anbinden;
  private Reservations-/Belegungslisten bleiben beim Host. Unbekannte neue
  Version beim Laden/Verbinden vor Aktivierung eindeutig zurückweisen.
- [ ] GREEN in kleinen Fixturepayloads prüfen; Commit:
  `feat: version hex ground restore and authoritative snapshots`.

### AP8: Kleinen integrierten Kandidaten vorbereiten

**Files:** Neu: `scripts/tests/hex_tactical_slice_verifier.gd`;
`docs/qa/hex_tactical_runtime_20261111/README.md` zur späteren Evidenz.
Ändern: `docs/IMPLEMENTATION_STATUS.md`, `docs/TASK_ROADMAP.md`,
`docs/dev/hex_tactical_runtime_contract.md`; der kleine private Fixture-Setupadapter.

**Interfaces:** Verbindet AP1–7 auf einer höchstens zwölf Felder großen
Hex-Fixture. Neue Kartenkennung wird nicht global oder mitten im Lauf gesetzt.

- [ ] RED-Fixture für den vollständigen kleinen Ablauf: zwei NPCs warten vor
  einer Rampe/Tür, passieren nacheinander, ein Ziel wird beim logischen
  Blick-/Feldwechsel erkannt, Schussprüfung liest aktuelle Sicht, Ankunft wird gemeldet.
- [ ] `python scripts/tests/run_hex_tactical_check.py --case slice` RED prüfen.
- [ ] Besitzer-/Setupadapter zusammenführen; die kleine Fixture nach
  Platzierungsprüfung opt-in aktivieren. Große A/B/C-Karten bleiben im
  bisherigen Modus; ihre Aktivierung und Lifecycle-/Placementmigration gehören AP9.
- [ ] Nur diesen kleinen Check GREEN ausführen; Doku nennt Code-/Terrain-/
  Datenstand, Aktivierungsgrenze und fehlende große/native Abnahme. Kein breites Gate.
- [ ] Kandidatencommit: `feat: wire hex tactical runtime candidate`.
  Keine Mainintegration, EXE oder Ablösung des Legacywegs vor AP9.

### AP9: Größere Abnahme — ausdrücklich später, derzeit gesperrt

**Files:** Später erweitern: `scripts/tests/tactical_map_frame_budget_harness.gd`,
passende vorhandene native Capture-/Battle-Proben und
`docs/qa/hex_tactical_runtime_20261111/`.

**Interfaces:** Gleiche Quell-/Karten-/Renderer-/Profil-/Routenbedingungen für
Baseline und Kandidat; aktive tatsächliche Arbeit und Fallzahlen protokollieren.

- [ ] Erst nach späterem Nutzerauftrag: repräsentative native Hexroute vor/nach
  dem Umbau mit identischen NPCs, Commands, Kamera und Qualitätswerten aufnehmen.
- [ ] Idle, Kolonne, Gegenverkehr, belegter Ausgang, Rampe, Türwechsel, erster
  Kontakt, laufender Kampf, Boarding, Verwundung und Continue gezielt prüfen.
- [ ] Sicht-/Cache-/Such-/Queuezähler, CPU-Scopezeiten, echte Frameintervalle,
  Eingabelatenz und verfügbare GPUzeiten getrennt auswerten. Instrumentierung
  separat kontrollieren; verschachtelte Scopes/Perzentile nicht addieren.
- [ ] A/B/C512×256, relevante kleine Alt-/Basiskarten, Save- und Host/Client-
  Nachbarn seriell prüfen. Kurzproben nicht zu stabilen P99-/FPS-Aussagen erklären.
- [ ] Erst auf dieser Evidenz Aktivierungsumfang und mögliche Integration
  entscheiden. Bleibt etwas rot oder ungemessen, Kandidatenstatus erhalten;
  Testgrenzen, Akteurzahl oder Grafik nicht zum Erreichen eines grünen Werts ändern.

## Planung und nachfolgender Ausführungsstand

Die ursprüngliche Planungsrunde änderte nur Dokumente und startete keine
Engine. Der danach geprüfte direkte Nutzerauftrag erlaubt die paketweise
Ausführung mit kleinen Contractchecks, weiterhin ohne große Testreihen.
AP0 ist auf97e00aba1 übernommen. AP2s isolierte Query-/Cachebausteine sowie
Ground-State und Erkennungsepisoden sind im Foundation-Task belegt.
AP1-Owner-/Versionsanbindung ist mit39/0 kleinen Checks ergänzt. AP3-Verbraucher
für Contact, Schussprüfung, FoW und Hex-Erkennung sind als Zwischenschritt mit
30/0 Consumerchecks und25/0 Helperchecks ergänzt. Weiterer AP3-Kernanschluss
mit Facing24/0, Security34/0, Consumer39/0, Owner39/0 und Ground25/0 gesichert;
Bewegungsschussbalance und AP4–AP9 bleiben offen. Keine Karte ist aktiviert.
Frischer Read-only-Review ohne Engine-/Dateiänderung und ohne Blocker.
