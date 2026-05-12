# Architektur-, Task- und Code-Audit 2026-05-10

Stand: 2026-05-10
Branch: `task/manual-playtest-followups`
Basis laut Git: `origin/task/manual-playtest-followups`
Lokaler Godot-Runner: `4.6.2.stable.official.71f334935`
Projektvorgabe laut Docs/AGENTS nach Fix: Godot `4.6.2`

Nachtrag 2026-05-11: Die offenen Entscheidungsfragen aus diesem Audit sind fuer den aktuellen Arbeitsstand geklaert. Godot 4.6.2 ist die bindende Projektversion, `sternenbuerger-gdd.docx` bleibt Alt-GDD/Design-Inspiration bis einzelne Inhalte in Markdown ueberfuehrt werden, Multiplayer V1 bleibt ENet Direct-IP/UPnP, die Editor-Palette bekommt eine Gruppe `Alle`, FOB-Loadout nutzt kompakte Name/Portrait-Karten zum Oeffnen des Character Sheets, und alle geplanten Dropship-LZs bleiben sichtbar.

## Kurzfassung

Die Kernarchitektur steht im Code groesstenteils noch auf der urspruenglichen Linie: `SimulationRoot` als autoritative Simulationsstelle, `EventRouter`/Registries als Vermittler, UI als Anzeige und nicht als Wahrheit. Die grossen Architektur-Gates fuer Gameplay Truth, Multiplayer Authority, Performance und Editor-Save-Vertraeglichkeit laufen gruen.

Die aktuelle Arbeitsbranch ist trotzdem nicht merge-reif. Die roten Stellen sitzen nicht in einem kompletten Architekturbruch, sondern in den neueren Playtest-Schichten: Dropship-Visualisierung/Sequencing, RMB-Order-Ziele, Feedback-Bubble-Filterung, FOB-Loadout-Charakterzugriff und Lobby-/Palette-Layout. Das ist genau die Art von "zweiter Wahrheit", die nicht als separate Gameplay-State-Wahrheit im UI auftaucht, aber als stale Visual-/Interaktionsvertrag sehr aehnliche Symptome erzeugt.

Der wichtigste konkrete Codefehler ist in `scripts/terrain/terrain_map_3d_view.gd:3055`: `_build_drop_visual_static_signature()` formatiert fuenf Platzhalter mit sechs Werten. Das erzeugt wiederholt Godot-String-Format-Errors und kann Dropship-Dirty-Signaturen, Marker und Kartenstatus aus dem Tritt bringen.

Die grosse HUD-/UI-Umstellung hat nachweislich einige alte Themen wieder beruehrt. Einige alte rote Punkte sind inzwischen behoben, aber nicht alle: `task_259` Loadout-Charakterzugriff und `task_258` Layout/Palette bleiben offen. Dazu kommen neue rote Playtest-Verifier aus `TASK_320`, `TASK_327` und `TASK_328`-Nahe.

## Arbeitsbericht

Gelesen und abgeglichen:

- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/DESIGN_NOTES.md`
- `docs/DECISIONS.md`
- `docs/ROADMAP.md`
- `docs/TASK_ROADMAP.md`
- Task-Dokumente `TASK_317` bis `TASK_328`
- bestehende Reports unter `docs/reports/`, besonders `playtest_task_consistency_audit_2026_05_10.md` und `manual_playtest_session_backfill_2026_05_10.md`
- `sternenbuerger-gdd.docx` als Design-Paper/alter GDD-Entwurf
- relevante Tests unter `scripts/tests/`
- relevante Codepfade in `scripts/terrain/terrain_map_3d_view.gd`, `scripts/ui/multiplayer_lobby_screen.gd`, `scenes/ui/multiplayer_lobby.tscn`, `scripts/core/simulation_root.gd`

Zusaetzlich geprueft:

- lokaler Godot-Binary-Stand via `godot_console.exe --version`
- aktueller Branch-/Diff-Umfang gegen `integration/core-foundation`
- Godot 4.6-Dokumentation zu Physics Tick, Containern/ScrollContainer, High-Level-Multiplayer, UPnP und Performance
- Godot-Release-Stand 4.6.2

Keine Runtime-Codeaenderungen wurden in diesem Audit vorgenommen. Diese Datei ist der Arbeitsbericht.

## Bindende Designlinie

Aus den aktuellen Repo-Docs ergibt sich weiter diese Linie:

- Der Spieler fuehrt keine einzelnen Soldaten direkt, sondern kommandiert ueber Commander/FTL-Strukturen.
- Gameplay-Zustand liegt nicht im HUD und nicht in UI-Skripten.
- `SimulationRoot` ist die autoritative Simulationsstelle.
- `EventRouter` ist Signal-Drehscheibe, nicht zweite Logikinstanz.
- Registries liefern Lookup; Hotpaths sollen keine SceneTree-Vollscans machen.
- Dirty-/Batch-Updates laufen ueber kontrollierte Aktualisierung statt per-frame Vollaufbau.
- Multiplayer V1 ist Godot/ENet Direct-IP/Host-Join, kein Matchmaking/Relay als Kernannahme.
- UI darf vorbereiten, darstellen und erklaeren, aber nicht den Wahrheitszustand halten.

Diese Linie passt auch zur aktuellen Godot-Dokumentation: feste, spielentscheidende Arbeit gehoert in den Physics-/Simulationstick, waehrend variable Frame-UI nur Anzeige/Interaktion liefern sollte.

## GDD-DOCX gegen aktuelle Docs

Die Datei `sternenbuerger-gdd.docx` wirkt wie ein aelterer oder groesserer Designentwurf. Sie beschreibt:

- 15 bis 100 NPCs
- Befehle nur an Teamleader
- 5 Ebenen: Deep Space, Orbit, Atmosphaere, Planet, Interior
- Teamleader mit 4 bis 15 NPCs
- Befehlsarten wie Angriff, Sichern, Vorruecken, Halten, Rueckzug, Infiltration, Support
- NPC-Werte wie Mut, Loyalitaet, XP, Treffsicherheit, Reaktion, Technik, Medizin, Pilotierung
- Traits, Sympathie-Matrix und Arbeitsplatzrollen auf Schiffen

Das passt in der Grundidee gut zur aktuellen Commander/FTL-Richtung.

Es gibt aber klare Konflikte:

- GDD sagt Phase 1 ohne Multiplayer; aktuelle Repo-Entscheidungen haben Multiplayer-V1 bereits als Direct-IP/ENet-Prototyp.
- GDD nennt spaeter Node.js WebSocket-Server; aktuelle Architekturentscheidung ist Godot High-Level Multiplayer/ENet.
- GDD nutzt teils IP-/Universumsbezug, der im Repo nicht als bindende technische Vorgabe auftaucht.
- GDD beschreibt groessere Teamleader-Slices; aktuelle Tasks arbeiten V1-artig mit kleineren Fireteam-/Dropship-Payloads.

Empfehlung: Die DOCX sollte als "Design-Inspiration/Alt-GDD" markiert oder in aktuelle Markdown-Docs ueberfuehrt werden. Solange sie unmarkiert neben den bindenden Docs liegt, ist sie eine potentielle zweite Wahrheit fuer neue Tasks.

## Task-Historie und aktueller Stand

Der bestehende Audit `playtest_task_consistency_audit_2026_05_10.md` meldete frueher 100 von 107 Verifiern gruen und offene Fehler in:

- `task_180`
- `task_181`
- `task_258`
- `task_259`
- `task_267`
- `task_270`
- `task_275`

Aktueller Re-Run der damaligen Problemgruppe:

| Bereich | Ergebnis | Bewertung |
| --- | ---: | --- |
| `task_180` Drop-Light Fixed HUD | 99 passed, 0 failed | behoben |
| `task_181` Drop-Light Fixed Window Audit | 45 passed, 0 failed | behoben |
| `task_258` Fixed Window / Scrollbar | 66 passed, 2 failed | offen |
| `task_259` Character Card / Loadout | 47 passed, 4 failed | offen |
| `task_267` Help Coverage | 12350 passed, 0 failed | behoben, Warnungen bleiben |
| `task_270` Commander to FTL Contract | 87 passed, 0 failed | behoben |
| `task_275` Command Button Hierarchy | 150 passed, 0 failed | behoben |
| `task_316` FOB Fireteam Staging Migration | 17 passed, 0 failed | gruen |

Das ist insgesamt positiv: Die alte GO-/Command-Hierarchie, CommanderIntent-Defaults und Help-ID-Themen sind groesstenteils wieder stabil. Die Altlasten sitzen jetzt vor allem in UI-Layout und Character Access.

Aktuelle Playtest-/Followup-Tests:

| Test | Ergebnis | Bewertung |
| --- | ---: | --- |
| `bugfix_mission_fireteam_fob_payload_and_bubbles.gd` | 12 passed, 0 failed | gruen |
| `bugfix_debrief_background_and_main_menu_team_library.gd` | 49 passed, 0 failed | gruen |
| `bugfix_fob_second_dropship_assignment_and_scale.gd` | 18 passed, 0 failed | gruen |
| `bugfix_mission_multi_dropship_cards.gd` | 26 passed, 7 failed | rot |
| `bugfix_dropship_mission_flow_verifier.gd` | 111 passed, 2 failed | rot |
| `bugfix_map_editor_station_floor_structure_undo.gd` | 84 passed, 0 failed | gruen |
| `bugfix_map_editor_asset_rotation_context_menu.gd` | 41 passed, 0 failed | gruen |
| `bugfix_mission_fire_sector_overlay.gd` | 21 passed, 0 failed | gruen |
| `bugfix_character_team_editor_usability_pass.gd` | 50 passed, 0 failed | gruen, mit Exit-Leak-Warnung |
| `bugfix_multiplayer_lobby_setup_and_asset_catalog_followup.gd` | 29 passed, 0 failed | gruen |
| `bugfix_multiplayer_enet_connectivity_smoke.gd` | 3 passed, 0 failed | gruen |
| `bugfix_mission_right_click_order_flow.gd` | 19 passed, 2 failed | rot |
| `bugfix_mission_dropship_plans_and_facing.gd` | 8 passed, 1 failed | rot |

Architektur-/Regressions-Gates:

| Gate | Ergebnis | Bewertung |
| --- | ---: | --- |
| `task_284_gameplay_truth_architecture_boundary_audit.gd` | 64 passed, 0 failed | gruen |
| `task_286_ui_feedback_truth_regression_review.gd` | 79 passed, 2 failed | rot |
| `task_287_editor_save_multiplayer_contract_regression_review.gd` | 56 passed, 0 failed | gruen |
| `task_288_regression_gate_coverage_gap_audit.gd` | 161 passed, 0 failed | gruen |
| `task_222_performance_regression_gate_and_manual_profile_checklist.gd` | 82 passed, 0 failed | gruen |
| `task_281_tactical_command_multiplayer_authority_snapshot.gd` | 33 passed, 0 failed | gruen |

Die gute Nachricht: Autoritaet, Performance und Save-/Multiplayer-Vertrag sind nicht breit gebrochen. Die schlechte Nachricht: Die aktuelle Branch hat rote, spielbare Oberflaechenvertraege genau in den Bereichen, die beim manuellen Playtest sichtbar sind.

## Befunde

### 1. Dropship-Visual-Signatur hat einen konkreten Formatfehler

Datei: `scripts/terrain/terrain_map_3d_view.gd:3047` bis `3063`
Konkret: `parts.append("%s:%s:%s:%s:%s" % [...])` an Zeile `3055` bekommt sechs Werte, aber nur fuenf Platzhalter.

Auswirkung:

- Godot meldet wiederholt `String formatting error: not all arguments converted during string formatting`.
- Die statische Dropship-Visual-Signatur kann nicht sauber gebaut werden.
- Dirty-/Refresh-Erkennung fuer Dropship-Marker, Approach Lines, LZ-Marker und Cards kann dadurch stale werden.
- Das korreliert direkt mit roten Dropship-Tests.

Das ist der erste Fix-Kandidat, weil er klein, eindeutig und wahrscheinlich ursachennah ist.

### 2. Multi-Dropship-Zustand ist noch nicht stabil

Betroffene Tests:

- `bugfix_mission_multi_dropship_cards.gd`: 7 Failures
- `bugfix_dropship_mission_flow_verifier.gd`: 2 Failures
- `bugfix_mission_dropship_plans_and_facing.gd`: 1 Failure

Symptome:

- Inbound-Karte zeigt Transfer-Fortschritt nicht, obwohl das Schiff noch off-map sein soll.
- Reselect von Dropship 1 stellt seine LZ nicht sauber wieder her.
- Drop-Sequenz/Handoff zwischen Dropship 1 und 2 ist nicht konsistent.
- RTB-Tracking nach Deployment bleibt nicht stabil.
- Dropship-Marker fehlt im Live-Mission-Render waehrend Route/Return.
- Beide geplanten LZ-Tiles bleiben nicht sichtbar.

Bewertung:

Das ist kein Beweis fuer eine zweite Gameplay-Wahrheit, aber fuer einen gebrochenen Visual-/State-Mirror. Besonders riskant ist, dass mehrere Craft-Zustaende offenbar nicht sauber pro Craft getrennt bleiben. Hier muss strikt gelten: Server/Simulation/Planpayload ist Wahrheit; UI-Karten und Marker sind reine Projektionen pro `dropship_id`.

### 3. RMB-Order-Flow verliert oder verfremdet Zielpositionen

Betroffener Test: `bugfix_mission_right_click_order_flow.gd`, 2 Failures

Symptome:

- Zweiter RMB ersetzt den alten Next-Waypoint, aber Zielposition stimmt nicht mit dem zweiten RMB-Tile ueberein.
- Shift+RMB appended, aber das gespeicherte Ziel entspricht nicht dem Shift-Ziel.

Bewertung:

Das ist spielerisch kritisch. Genau hier entsteht schnell das Gefuehl, dass das HUD etwas anderes zeigt als der Auftrag meint. Der Fix sollte nicht im HUD "nachmalen", sondern die Command-Pipeline klaeren:

- Input-Ziel normalisieren
- Preview nur aus normalisiertem Pending Intent
- Server-/Simulation-Order aus demselben Intent
- Shift Append vs Plain Replace als expliziter Modus im Intent
- Test gegen gespeicherten Command-Payload, nicht nur gegen Marker

### 4. Feedback-Bubble-Filterung dedupliziert vor der Wahrheitsschranke

Betroffener Test: `task_286_ui_feedback_truth_regression_review.gd`, 2 Failures

Relevant:

- Test legt drei Bubble-Payloads auf denselben Anchor: `non_visual`, `wrong_type`, `valid`.
- `scripts/terrain/terrain_map_3d_view.gd:3215` ruft `_select_feedback_bubbles_for_visuals(...)`.
- `_select_feedback_bubbles_for_visuals()` ab `3234` dedupliziert nach Anchor/Prioritaet.
- Die eigentliche Filterung auf `display_type == "comic_bubble"` und `visual_only == true` passiert erst in `_add_feedback_bubble_visual()` ab `3752`.

Wahrscheinliche Folge:

- Ein nicht sichtbarer oder falscher Bubble-Payload kann den Anchor fuer den spaeter gueltigen Payload belegen.
- Danach filtert `_add_feedback_bubble_visual()` den falschen Payload weg und der gueltige kommt nie an.

Das ist architektonisch genau die falsche Reihenfolge: Erst Wahrheitsschranke, dann Auswahl/Dedupe. Der Fix sollte visuelle Kandidaten vor der Dedupe-Funktion filtern oder die Dedupe-Funktion nur akzeptierte Visual-Payloads aufnehmen lassen.

### 5. FOB Loadout #13 hat weiter keinen sauberen Character-Access

Betroffener Test: `task_259_character_card_roster_switching_playability.gd`, 4 Failures

Symptome:

- Nach Staging eines Fireteams im Loadout existiert keine erwartete Slot Card fuer das Mitglied.
- Card oeffnet kein Character Overlay.
- Overlay haelt Character-Sheet-Sektionen nicht sichtbar.
- Reassignment synchronisiert das Overlay nicht sauber.

`task_316` ist trotzdem gruen, weil die kompakte FOB-Migration fuer Member Rows/Badges/Dropdowns funktioniert. Das heisst: Die Migration hat den Staging-Vertrag geloest, aber nicht den alten Character-Access-Vertrag aus dem Playability-Test.

Designbewertung:

Character-Details duerfen UI sein, aber Auswahl und Zuordnung muessen aus dem Roster-/Staging-Model kommen. Der Fix sollte eine klare kleine Interaktion liefern: Name/Portrait/Button im Loadout oeffnet dasselbe Character Sheet wie in Library/Team Editor, ohne eigene Loadout-Wahrheit.

### 6. Fixed-Window-/Palette-Audit ist noch rot

Betroffener Test: `task_258_fixed_window_clipping_scrollbar_playability_audit.gd`, 2 Failures

Symptome:

- Lobby Panel bleibt nicht innerhalb des 1280x720-Zielviewports.
- Editor Palette erfuellt die alte Erwartung "long ItemList with built-in scrolling" nicht.

Codehinweis:

- `scripts/ui/multiplayer_lobby_screen.gd:361` fuegt dynamisch `LobbySetupPanel` in `Panel/Margin/VBox` ein.
- `scenes/ui/multiplayer_lobby.tscn` nutzt ein zentriertes Panel mit fixem Innenraum.
- Die neue Setup-Sektion vergroessert den Inhalt, ohne dass ein ScrollContainer/angepasstes Layout die Hoehe absichert.

Bewertung:

Die Lobby-Seite ist ein echter Layout-Bug. Die Palette kann entweder ein echter Bug sein oder ein veralteter Test, falls die gruppierte Palette bewusst die alte lange Liste ersetzt. Das sollte explizit entschieden werden.

### 7. Godot-Version im Arbeitskontext driftet

Im Audit war eine Versionsdrift sichtbar: Lokal war `4.6.2.stable.official.71f334935` aktiv, waehrend einzelne Projekt-Docs noch auf die vorige Patchversion zeigten.

Aktueller offizieller Stand: Godot 4.6.2 ist seit 2026-04-01 stable. Laut Godot-Release-Post enthaelt 4.6.2 122 Fixes gegen die vorherige Stable-Patchversion und keine bekannten Inkompatibilitaeten zum direkten Vorgaenger.

Bewertung:

Das ist wahrscheinlich okay, aber es ist eine Versionswahrheit, die dokumentiert werden musste. Die Entscheidung ist gefallen:

- Docs werden auf 4.6.2 aktualisiert und die Verifier/Imports gelten ab jetzt fuer 4.6.2.

Gerade bei UI-/Rendering-/Import-Fragen sollte nicht unklar sein, welche Version der Referenzstand ist.

### 8. Branch-Scope ist deutlich groesser als die Task-Regel erlaubt

Diff gegen `integration/core-foundation`: 797 Files changed, ca. 49k Insertions, ca. 4.6k Deletions.

Enthalten sind viele neue Assets, Maps, UI-/Mission-/Editor-Aenderungen und eine geloeschte/ersetzte Map-Datei. Das erklaert, warum "fast 100 Tasks in einer Nacht" schwer integrierbar wurden: selbst wenn viele Einzeltests gruen sind, ist die Branch kein kleiner, sauber isolierter Task-Schnitt.

Empfehlung:

Vor Merge in Integration nicht noch mehr Feature-Flanken oeffnen. Erst rote Verifier stabilisieren, dann branchweise oder commitweise aufteilen/zusammenfassen.

### 9. Implementierungsstatus ist teilweise optimistischer als der Re-Run

`docs/IMPLEMENTATION_STATUS.md` und die Taskdateien melden viele neue Tasks als implementiert/im Arbeitsstand. Das ist als Verlauf nicht falsch, aber der aktuelle Re-Run zeigt rote Nachfolge-Verifier.

Empfehlung:

Nach den Fixes sollte `IMPLEMENTATION_STATUS.md` nicht nur "implementiert" sagen, sondern fuer die Playtest-Followups kurz nennen:

- welche Verifier final gruen sind
- welche Tests bewusst angepasst wurden
- welche Punkte als Designentscheidung offen bleiben

## Sync-, Tick- und Multiplayer-Einschaetzung

Die Simulationsbasis sieht gut aus:

- `SimulationRoot` arbeitet im Physics-Kontext.
- Es gibt Navigations-/Path-Query-Budgets, z.B. `navigation_max_new_path_queries_per_tick`.
- Debug-Snapshots koennen neue, fallback, unreachable und delayed Path Queries sichtbar machen.
- Multiplayer-Authority-Gate ist gruen.
- Performance-Gate ist gruen, inklusive UI-Node-Counts und Snapshot-Groessen.

Das passt zu Godots Modell: `_physics_process()` laeuft fixed-rate, waehrend `_process()` frameabhaengig ist. Fuer Multiplayer-Sync bleibt damit richtig:

- Entscheidungen in Simulation/Server-Tick.
- UI zeigt Snapshots/Events, fragt aber nicht als Gameplay-Wahrheit.
- Client-Preview ist klar als Preview markiert.
- Command-Intent wird einmal normalisiert und dann als derselbe Payload fuer Preview und authoritative Order verwendet.
- Dirty-Signaturen duerfen nicht durch UI-Formatfehler kaputtgehen.

Optimierbare Stellen:

- Dropship-Visuals brauchen eine stabile pro-Craft-Signatur mit `dropship_id`, `state`, `requested_lz`, `resolved_lz`, `visible`, `team_id`.
- RMB-Orders brauchen einen expliziten Pending-Intent-Snapshot mit Tick/Phase/Append-Modus.
- Feedback-Bubbles sollten vor Dedupe nach `visual_only`, `display_type`, Kanal und FoW gefiltert werden.
- UI-Refresh sollte mit letzten Signaturen arbeiten, aber Signaturfehler muessen als Testfail sichtbar sein.
- Multiplayer-Smoke sollte neben ENet-Verbindung auch einen minimalen Order-Roundtrip und Dropship-State-Roundtrip abdecken.

## Godot-Recherche

Relevante offizielle Quellen:

- Godot 4.6 Idle/Physics Processing: `_physics_process()` ist fixed-rate, `_process()` frameabhaengig. Das stuetzt eure Architekturregel, Simulation nicht an HUD/Frame-UI zu haengen.
  https://docs.godotengine.org/en/4.6/tutorials/scripting/idle_and_physics_processing.html

- Godot 4.6 UI Containers: `ScrollContainer` ist genau fuer Inhalte gedacht, die groesser als ihr Container werden; `VBoxContainer` als Kind ist der Standardweg. Das stuetzt den Lobby-Fix.
  https://docs.godotengine.org/en/4.6/tutorials/ui/gui_containers.html

- Godot 4.6 High-Level Multiplayer: Godots High-Level-Multiplayer nutzt UDP/ENet; Internet-Hosting braucht UDP-Port-Forwarding, nicht nur TCP. Das passt zu Direct-IP/Port-7777-V1.
  https://docs.godotengine.org/en/4.6/tutorials/networking/high_level_multiplayer.html

- Godot UPnP: UPnP kann Port-Mappings setzen, blockiert aber synchron und muss Fehler, Konflikte, fehlende Router-Unterstuetzung und periodische Refreshes behandeln. Das passt zu "komfortabel, aber nicht garantiert".
  https://docs.godotengine.org/en/stable/classes/class_upnp.html

- Godot Performance: Messen/Profiling ist zentral; Hypothesen sollen per Timing/Profiler geprueft werden. Das passt zum bestehenden Performance-Gate.
  https://docs.godotengine.org/en/4.6/tutorials/performance/general_optimization.html

- Godot 4.6.2 Release: Stable seit 2026-04-01, 122 Fixes gegen die vorherige Stable-Patchversion, keine bekannten Inkompatibilitaeten zum direkten Vorgaenger laut Release-Post.
  https://godotengine.org/article/maintenance-release-godot-4-6-2/

Forum-/Community-Recherche war fuer diesen Bericht nicht ausschlaggebend, weil die offiziellen 4.6-Dokumente die relevanten Architekturfragen ausreichend klar beantworten. Fuer konkrete Engine-Bugs nach einem Repro waere der naechste Schritt Godot GitHub Issues oder Godot Forum mit exakter Version und minimalem Projekt.

## Empfohlene naechste Arbeitspakete

### FIX-001: Dropship-Signatur und Multi-Craft-Rendervertrag

Scope:

- `scripts/terrain/terrain_map_3d_view.gd`
- Dropship-Card-/Payload-Code nur soweit noetig

Akzeptanz:

- keine `String formatting error` mehr
- `bugfix_mission_multi_dropship_cards.gd` gruen
- `bugfix_dropship_mission_flow_verifier.gd` gruen
- `bugfix_mission_dropship_plans_and_facing.gd` gruen

### FIX-002: RMB Order Intent Replace/Append

Scope:

- Controller-/Mission-Input-Pipeline fuer RMB
- Pending Waypoint/Area Payload

Akzeptanz:

- `bugfix_mission_right_click_order_flow.gd` gruen
- Plain RMB ersetzt eindeutig
- Shift+RMB appended eindeutig
- Preview und gespeicherter Intent verwenden dieselbe Zielposition

### FIX-003: Feedback-Bubble-Wahrheitsschranke vor Dedupe

Scope:

- `scripts/terrain/terrain_map_3d_view.gd`

Akzeptanz:

- `task_286_ui_feedback_truth_regression_review.gd` gruen
- Nicht-visual und falsche Display-Typen koennen keinen Anchor gegen gueltige Visuals blockieren

### FIX-004: FOB Loadout Character Access

Scope:

- FOB Loadout #13 UI
- bestehender Character Overlay/Sheet Code wiederverwenden

Akzeptanz:

- `task_259_character_card_roster_switching_playability.gd` gruen
- kein neuer Loadout-eigener Charakterzustand

### FIX-005: Lobby Fixed Window und Palette-Entscheidung

Scope:

- `scenes/ui/multiplayer_lobby.tscn`
- `scripts/ui/multiplayer_lobby_screen.gd`
- ggf. Map-Editor-Palette oder Testdefinition

Akzeptanz:

- Lobby bleibt in 1280x720 spielbar
- lange Inhalte liegen in ScrollContainer oder werden responsive reduziert
- fuer die Palette wird entschieden: echte lange Liste wieder anbieten oder Test auf Gruppierung aktualisieren

### DOC-001: Version und GDD-Wahrheit klaeren

Scope:

- `docs/PROJECT_BRIEF.md`
- `docs/DECISIONS.md`
- `docs/IMPLEMENTATION_STATUS.md`
- ggf. neues `docs/GDD_STATUS.md`

Akzeptanz:

- Godot-Version ist eindeutig: 4.6.2 ist uebernommen
- DOCX ist als Alt-GDD/Inspiration markiert oder in aktuelle Docs migriert
- Multiplayer-Entscheidung ENet vs WebSocket ist nicht doppelt dokumentiert

## Geklaerte Entscheidungen nach Fix-Pass

1. `sternenbuerger-gdd.docx` bleibt Alt-GDD/Design-Inspiration und wird nicht direkt bindend.
2. Das Projekt verwendet ab jetzt offiziell Godot 4.6.2.
3. Multiplayer V1 bleibt bei Godot ENet Direct-IP/UPnP; Relay/STUN/TURN bleibt ein eigener Zukunftsentscheid.
4. Die Editor-Palette behaelt Gruppen und bekommt zusaetzlich eine `Alle`-Langliste.
5. Im FOB Loadout reicht ein kompakter Name/Portrait-Button, der das Character Sheet oeffnet.
6. Bei mehreren Dropships bleiben alle geplanten LZs sichtbar.

## Merge-Einschaetzung

Nicht in `integration/core-foundation` mergen, bevor mindestens diese Tests gruen sind:

- `bugfix_mission_multi_dropship_cards.gd`
- `bugfix_dropship_mission_flow_verifier.gd`
- `bugfix_mission_dropship_plans_and_facing.gd`
- `bugfix_mission_right_click_order_flow.gd`
- `task_286_ui_feedback_truth_regression_review.gd`
- `task_259_character_card_roster_switching_playability.gd`
- `task_258_fixed_window_clipping_scrollbar_playability_audit.gd` oder explizite Testentscheidung fuer Palette

Danach sollte die grosse Branch in kleinere, nachvollziehbare Integrationspakete zerlegt werden:

1. Mission/Dropship-Stabilisierung
2. Order-/Command-Flow
3. UI/FOB/Loadout
4. Map Editor/Asset Catalog
5. Docs/Status/Version

Das haelt die urspruengliche Regel "kleine, integrierbare Schritte" wieder ein und verhindert, dass alte Playtest-Probleme in der naechsten HUD-/UI-Runde erneut verschuettet werden.
