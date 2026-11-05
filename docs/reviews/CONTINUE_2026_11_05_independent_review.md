# Unabhaengiges Nachreview: Command-HUD und Legacy-Gates

## Ergebnis und Grenze

**APPROVED, begrenzt auf den aktuell gelesenen Code und die unten genannten Headless-/nativen Fixturebelege.** Keine offenen P1/P2 in den geprueften Produkt-Hunks. Normale Bewegungs-/Schuss-/Facing- und Performancegates, finale Run-Quellenbindung sowie Abschlussintegration bleiben beim Root offen. Dieser Review ist keine allgemeine FPS-, Multiplayer-, EXE- oder Releaseabnahme.

Basis: `task/continue-perf-legacy-20261105`, HEAD `01ab595a7b89632629eee0ad3523281e542148a0`. Geprueft wurden die aktuellen uncommitteten Aenderungen, Pflichtdokumente, Haupttask und die drei Subaudits. Keine Engine gestartet, keine Produkt-/Testdatei veraendert, keine Gitmutation. Ein separater lesender Testoracle-Review wurde einbezogen; seine Ergebnisse wurden an aktuellen Quellen und Logs gegengeprueft.

## Geschlossene Befunde

1. **P2, verlorener Command-Force bei interleavtem Vollpass.** Ein erfolgreicher Move setzte pending; ein Transportpass `_update_ui(true, false)` konnte pending loeschen, waehrend die unveraenderte Craftsignatur die commandabhaengigen Controls uebersprang. `_update_ui` uebernimmt pending jetzt vor dem Loeschen in `force_heavy_surfaces` (`mission_tactical_sandbox_controller.gd:4061`). Die Regression prueft Move, unforced Vollpass und anschliessenden normalen Takt: genau eine Anwendung, kein verlorener oder doppelter Flush. `batch_interleave_green/20261105T143242Z-24bba994`: **40/0**, Exit0, Error0, isoliert.
2. **P2, zugelassene gemischte Dropkinder vom Parent versteckt.** Der bisherige Gesamtowner konnte aktuell sichtbare fremde Aircraft oder eigene Planmarker unter einem fremden/neutralen Parent unsichtbar machen. `_refresh_drop_visual_visibility_for_fow_delta` laesst den Container jetzt sichtbar; jedes Aircraft, Surface-Element und Cargo-Label wird vorher am eigenen Owner/Anker zugelassen (`terrain_map_3d_view.gd:6218`, `:6245`, `:10332`). Die Admission-Signatur erfasst auch den Surface-Cargo-Fallback am Schiff statt nur dessen entferntem Target. Die Tests pruefen echte `is_visible_in_tree`-Zustaende, Parentwechsel, Sichtgewinn/-verlust und unverwandte Tile-Deltas. `air_visibility_green/20261105T143239Z-efc173fa`: **120/0**, Exit0, Error0, isoliert; finale Matrix **127/0**.

## Weitere gepruefte Grenzen

- Der HUD-Sofortpfad folgt erst nach erfolgreicher synchroner Command-/Orderpublikation. Simulation, Authority, Planersetzung und Completion werden nicht verzoegert. Schwere abgeleitete Flaechen werden im vorhandenen 350-ms-Takt zusammengefuehrt; frisch geoeffnete Details flushen pending, bereits offene Details lesen aktuelles Feedback. Der neue Verifier ist eine synthetisch getaktete Schedulerprobe am echten Controller, kein nativer Latenz- oder Bewegungsbeleg.
- Facing nutzt dieselbe aufgeloeste Richtung fuer Proxy, Modell/Hips und Waffenlinie. Bei wiederholtem Sync ohne neuen Positionstick bleibt aktives Root-Move-/Engage-Facing massgeblich. Aktiver FireEvent/sichtbarer Contact, echte Bewegung, Security und explizites Facing behalten den dokumentierten Rang. Keine Gameplay-, Animations- oder Modellachsenmutation durch den View.
- `known_terrain` gestattet eigene geplante LZ-/Approachabsicht vor dem ersten Bodenobserver; fremde/neutrale Surface-Marker brauchen aktuelle Sicht. `unexplored_blackout` bleibt fuer Surface-Marker streng. Die bisherige Aircraft-Ausnahme wird nicht zur Terrainfreigabe. FoW-Updates bauen Dropvisuals nur bei geaenderter Admission neu; irrelevante Deltas behalten den Skippfad.
- Die niedrigere A5-Karte wurde nicht durch einen schwaecheren Reachabilitytest akzeptiert. Der Test prueft vollstaendige Viewport-/Clippingancestor-Einschliessung und getrennte Nachbarkarten. Der Controller gleicht alte uebergrosse Karten an ihre neue Mindestgroesse an. Finale TASK401: **125/0**. Direkter `_gui_input`-Aufruf bleibt eine separate Callbackprobe und belegt keinen nativen Mauspfad.
- TASK111 prueft den aktuellen DEF-Vertrag; historisches Overwatch bleibt produktiv aus. TASK113 aktiviert Flank nur im ausdruecklich synthetischen Legacyfixture. TASK436 liest das tatsaechliche Parentprofil und aktuelle A5-Controls. TASK468 trennt Queuebeobachtung von wirklicher autoritativer Physics-Commitphase und erhaelt Fire-/Stale-Requeuepruefungen. Keine produktive Wiederaktivierung alter Taktiken und keine blind gelockerten Combatassertions.
- TASK344 besitzt nach der finalen Matrix nur eine feste Oraclekorrektur von 48x48 auf **96x98**. `gm01_frontier_map_contract.md` und aktuelle MapJSON bestaetigen `grid_size={x:96,y:98}`, `grid_topology=hex_axial_v1`. Die 39 Enemy-/Facing-/Aim-/Socket-/Pose-/VFX-/Dokumentchecks bleiben erhalten. Der fokussierte Nachlauf `final_344/20261105T144201Z-d8a198f3` ist **40/0**, Exit0/Error0, isoliert.
- Die einzelne Portraitkonstruktorzeile `mission_tactical_sandbox_controller.gd:5991` nutzt jetzt `STRETCH_KEEP_ASPECT_CENTERED` statt Covered. Der vorhandene Slot, Textur-/Member-ID-/Tooltip-/Doppelklickpfad bleiben unveraendert. Die tatsaechlichen nativen `01_authored_stand.png` vor/nach wurden angesehen: vorher fehlten die oberen Kopf-/Augenpartien beider Einpersonen-Teams, nachher sind beide Koepfe vollstaendig sichtbar. Keine neue Gameplay-Wahrheit oder Actoraenderung.

## Evidenz und Quellenbindung

`output/continue_20261105/final_headless/20261105T143549Z-f6e59562/report.json`: **26/27 Gates gruen**. Einziger roter Gate ist TASK344, ausschliesslich die alte 48x48-Assertion (**39/1** vor deren Berichtigung). Alle 27 Prozesse melden kein Timeout und verifizierte Userdaten-/Outputisolation; die Rosterbytes/-laenge/-mtime bleiben vorher/nachher gleich.

Die Overlays teilen Ressourcenverzeichnisse ueber Junctions mit dem Arbeitsbaum. Sie sind keine eingefrorenen Sourcekopien: Ein nachtraeglicher Overlayhashvergleich belegt daher keine ausgefuehrte historische Quellversion. Die folgende Tabelle pinnt die aktuell gelesenen Quellen. Fuer eine unabhaengige abschliessende Run-Quellenbindung sind Roots vor/nach dem Lauf erfasste Sourcepins/Freezeaufzeichnung erforderlich; der Runnerreport selbst pinnt nur `project.godot` und die beiden Arten unveraenderlicher Captureeingaben. Die historischen 120- und aktuellen 127-Airassertions bleiben entsprechend getrennt.

Relevante finale Counts: HUD40/0, Air127/0, Facing125/0, Firesector49/0, Orientation17/0, RuntimeCombat48/0, TASK11132/0, TASK11330/0, TASK43659/0, TASK46823/0. Headless- oder synthetische FireEvent-/Contactbilder ersetzen keine normale physische Schussbeobachtung.

Native Fixture-Nachlaeufe: `native_facing/20261105T144209Z-b71af821` **135/0**, `native_air/20261105T144221Z-729690d1` **155/0**, nach der Portraitzeile `native_portrait_final/20261105T144652Z-3e167e13` **135/0**. Alle drei Reports: Exit0, Error0, kein Timeout, isoliert. Facing-/Portraitmetadata verzeichnet Windows, Mode3 und uebereinstimmende Screen-/Window-/Viewport-/PNG-Groesse **2560x1440**. `source=synthetic_fixture` und `normal_mission_physical_fire_proof=false` grenzen den Nachweis korrekt ab. Native Fixturebilder sind hiermit belegt; ein echter Schuss im normalen Spiel ist daraus nicht abgeleitet.

SHA256 der gelesenen Quellen:

| Datei | SHA256 |
| --- | --- |
| `scripts/tests/mission_tactical_sandbox_controller.gd` (aktuell nach Portraitzeile) | `144b88b2afa3a530e04c402e17a4bb9dbd44b86544243901d861406128430e6a` |
| Controller-Vorlaeufer fuer Headlessmatrix/HUD-Interleave (vor Portraitzeile) | `d24fae1e4122871ce308da68e87815994543438660ce1bc244330a2aa119eb32` |
| `scripts/terrain/terrain_map_3d_view.gd` | `469e5d7920ddf82970c03b92ae992a332fcb6b82b37e5bdaaafca7f8e7498b54` |
| `scripts/tests/continue_20261105_command_hud_batch_verifier.gd` | `c3121ef171464d010f7ff24c32eb203ddcfa74e4bb822317bca9489c3b35ce48` |
| `scripts/tests/task_230_flight_altitude_layer_and_air_visibility_audit.gd` | `6fa20d44faabfced4b43d92a15f30dc04ab3d8501ff8b72b6fd48dcdd8deedf3` |
| `scripts/tests/task_401_facing_sightline_debug_map.gd` | `023604fb4d6d7fc2d11b68eb94727b011d2eb81d65ea1d984f436b5de7b1218b` |
| `scripts/tests/task_344_ground_mission_default_enemy_visuals.gd` (nach Oraclekorrektur) | `071f982dd929cc99b7c4ff058648b89b03c9380edb5a5f217bf02aa59e284fb7` |

Noch offene Gates werden mit ihren eigenen Rohbelegen abgenommen: finale Run-/Quellenbindung, normale 1x-Bewegung nach wiederholten Commands, echter Schuss-/Facingpfad, vergleichbare Hitch-/Backlog-/Throughputmessung und Main-Smoke vor/nach Integration. Historische Aufloesungen oder synthetische Fixturecaptures sind dafuer kein Ersatz.
