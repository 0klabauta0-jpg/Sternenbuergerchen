# Playtest- und Task-Konsistenz-Audit - 2026-05-10

## Scope
Geprueft wurden die aktuellen Editor-, Mission-, Meta-/FOB-, Dropship-, Taktik-, Help- und Performance-Tasks gegen das bestehende Design: Spieler ist Commander, Steuerung laeuft ueber Fireteam Leader, UI zeigt und delegiert, Runtime-Wahrheit bleibt bei SimulationRoot, und die Drop-Light-/Meta-Fenster sollen feste Groessen behalten.

Der Audit kombiniert:
- Headless-Godot-Verifier in drei Playtest-Bloecken.
- MCP-Sichtcheck des laufenden Godot-Debugfensters.
- Code-/Task-/Review-Abgleich.
- Web-Recherche in Godot-Doku und Godot-Forum zu UI-Containern, ItemList/Selection und Performance-Messung.

## Kurzfazit
Der Editor-/Terrain-Block ist aktuell gruen und deutlich stabiler als in den Screenshots zuvor. Insgesamt liefen 100 von 107 Verifiern gruen. Die roten Stellen liegen vor allem in der Mission-HUD-/Command-Matrix, im FOB-Loadout nach der kompakten Fireteam-Migration, in der Help-ID-Abdeckung fuer kompakte Waffen-Previews und in einer echten taktischen Semantik-Luecke: `take` wird nicht sauber zu `sector`-Security, weil Defaults den Fallback ueberstimmen.

Wichtig: Mehrere Tests sind nicht einfach "kaputt", sondern zeigen echte Konzept-Kollisionen. Die naechsten Fixes sollten deshalb nicht nur die Tests umbiegen, sondern die fachliche Entscheidung festziehen.

## Ausgefuehrte Playtests

### Editor / Terrain / Hill / Grid
Ergebnis: 18/18 gruen.

Abgedeckt:
- Editor-Hill-Authoring, Height/Edge/Surface-Anker.
- Hill-Visuals, Cliff-/Slope-/Grid-Depth.
- Nature Kit Props, Scale, Cover, Visibility.
- Toolbar, Palette-Taxonomie, Inspector-Panels.
- Mission Grid Tile Selection Command Gate.

Interpretation:
- Die groben Huegel-/Grid-/Selection-Fixes sind automatisiert stabil.
- Die fruehere Sorge "Boden uebermalt Objekt/Deckung" scheint fuer den aktuellen Catalog-Pfad adressiert: `TerrainTileCatalog._apply_surface_brush_to_tile()` setzt Surface/Type, loescht aber `object_type_id` nicht.
- Ein kleiner Testvertrag im Playability-Audit widerspricht der neuen gruppierten Palette, siehe Befund P3.

### Meta / Homebase / FOB / Dropship
Ergebnis: 37/39 gruen.

Fehler:
- `task_180_mission_drop_light_fixed_hud_layout_verifier.gd`
- `task_181_drop_light_fixed_window_audit_verifier.gd`

Beide laufen auf denselben Kern hinaus: `CommandPanel` ist in der Mission tatsaechlich 308 px breit, der Fixed-Layout-Vertrag erwartet 304 px.

### Taktik / Performance / Playability / Help
Ergebnis: 45/50 gruen.

Fehler:
- `task_258_fixed_window_clipping_scrollbar_playability_audit.gd`
- `task_259_character_card_roster_switching_playability.gd`
- `task_267_contextual_help_coverage_layout_verifier.gd`
- `task_270_commander_to_fireteam_leader_delegation_contract.gd`
- `task_275_command_button_hierarchy_arrangement_overhaul.gd`

Performance-Gates `task_215` bis `task_222` laufen gruen. Kein aktueller Blocker aus den Benchmarks.

## MCP-Sichtcheck
Godot liess sich per MCP in den Vordergrund holen. Sichtbar war die Multiplayer-Lobby mit Hintergrundbild, Host-/Join-Feldern, Roster-Auswahl, FoW-Hinweis und Zurueck-Button. Kein sichtbarer Reload-from-disk-Dialog in Godot/VS Code in diesem Check.

Einschraenkung: Das Setup ist Multi-Monitor/Mehrfenster-lastig; ein weiterer App-Switch sprang auf ein anderes laufendes Spiel-/Desktopfenster. Das ist kein Sternenbuergerchen-Bug, aber fuer kuenftige MCP-Playtests sollte ein dediziertes Godot-Testfenster auf einem Display mit fester Position gestartet werden.

## Befunde und Patch-Reihenfolge

### P1 - Mission Command Matrix waechst trotz Fixed-Window-Vertrag
Betroffen:
- `scripts/meta/drop_light_layout_contract.gd:80` bis `scripts/meta/drop_light_layout_contract.gd:89`
- `scripts/tests/mission_tactical_sandbox_controller.gd:4523` bis `scripts/tests/mission_tactical_sandbox_controller.gd:4580`
- `scenes/tests/mission_reactivity_test.tscn:422` bis `scenes/tests/mission_reactivity_test.tscn:449`
- Tests: `task_180`, `task_181`, `task_258`

Symptom:
- Erwartet: `command_matrix = Rect2i(24, 808, 304, 248)`.
- Ist: `CommandPanel actual pos=(24.0, 808.0) size=(308.0, 248.0)`.

Warum das wichtig ist:
- Feste Fenstergroessen sind eine harte Designvorgabe.
- Godot-Container kontrollieren Kinder-Controls und koennen manuelle Position/Size beim naechsten Sort/Resize wieder ueberschreiben. Die Godot-Doku nennt genau dieses Verhalten fuer Container-Kinder.

Empfohlener Patch:
1. `CommandPanel`, `FireteamPanel`, `StrategicPanel` aus dem `HBoxContainer`-Sizing-Druck herausloesen oder einen dedizierten Fixed-HUD-Host verwenden, der die drei Panels absolut setzt.
2. `custom_minimum_size` nicht als alleinigen Wahrheitsanker nutzen, wenn Container noch mitsortieren.
3. Nach Layout-Apply einen Snapshot pruefen: `drop_light_rect`, `global_position`, `size`, `custom_minimum_size`, `size_flags_horizontal`.
4. Tests `task_180`, `task_181`, `task_258` erst danach wieder gruen machen, nicht durch Anpassung auf 308.

Designentscheidung:
- 304 bleibt vorerst richtig, weil "feste Fenster" mehr Gewicht hat als "Container darf etwas ausgleichen".

### P1 - Command-Hierarchy und Dropship-GO widersprechen sich
Betroffen:
- `docs/tasks/TASK_275_command_button_hierarchy_arrangement_overhaul.md`
- `docs/tasks/TASK_312_dropship_command_matrix_lz_go_layout.md`
- `scripts/ui/mission_command_hierarchy_contract.gd`
- Test: `task_275`

Symptom:
- `TASK_275` sagt: #16 kurze Zielbefehle, #17 Regeln/Details, #18 Gesamtplan/GO/Air.
- `TASK_312` sagt explizit: Go-Button aus Fenster 17 heraus und in #16 Command Matrix.
- Testfehler: `#16 command grid uses three columns for fixed hierarchy rows`.

Warum das wichtig ist:
- Das ist kein reiner Testfehler. Zwei Task-Entscheidungen ziehen fachlich an derselben Stelle.
- User-Vorgabe war zuletzt konkret: Go-Button in #16 Command Matrix. Das sollte gewinnen, aber nicht als heimliche Layout-Aufweichung.

Empfohlener Patch:
1. Neues Mini-Task/Fix: `TASK_327_command_matrix_go_contract_reconciliation`.
2. `mission_command_hierarchy_contract.gd` aktualisieren: Plan-GO und Dropship-GO klar trennen.
3. #16 darf Go aufnehmen, aber als kurze Action und innerhalb der 304px-Flaeche.
4. Wenn #16 weiter drei Spalten haben soll, muss Go in bestehende kurze Button-Reihe passen oder per Kontext einen bestehenden Air/LZ-Slot ersetzen.
5. `task_275` so aktualisieren, dass er die entschiedene Hierarchie prueft statt den alten #18-GO-Vertrag zu konservieren.

Designentscheidung:
- "Go in #16" ist fachlich okay, weil der Spieler dort den Befehl final ausloest. Aber #18 bleibt Mission-Control/Preview/Warnings, nicht ein zweites Wahrheitsfenster.

### P1 - FOB Loadout verliert klickbare Charakterkarte
Betroffen:
- `scripts/tests/task_259_character_card_roster_switching_playability.gd:163` bis `:170`
- `scripts/tests/task_316_fob_fireteam_staging_migration.gd`
- `scripts/meta/fob_screen.gd:2088` bis `:2117`

Symptom:
- `task_316` ist gruen: Fireteam-Karte migriert kompakt nach #13 Loadout, Member-Rows bleiben klein.
- `task_259` ist rot: Es gibt keine `loadout_staging`-NPC-Karte mehr, die Character Overlay oeffnet und Assignment/Loadout synchron zeigt.

Warum das wichtig ist:
- Der Userology-Grundsatz war: ueberall an Charakterkarte kommen, gerade bei Loadout, Traits, Gewicht, Rang, Skills.
- Kompaktheit ist gut, darf aber nicht die Identitaets-/Charakterzugriffe entfernen.

Empfohlener Patch:
1. In jeder kompakten Loadout-Member-Row eine kleine klickbare Operator-ID einbauen: Portrait/Name oder Mini-NPC-Card.
2. Diese Mini-Karte muss `card_open_requested` oder denselben Overlay-Pfad wie Fireteam-Karten ausloesen.
3. `source_context = "loadout_staging"` beibehalten, damit Tests/Help/Overlay wissen, woher der Klick kam.
4. Overlay nach Reassignment synchron halten: "Assigned to FT3" muss sichtbar bleiben.
5. `task_259` und `task_316` zusammen laufen lassen, damit Kompaktheit und Charakterzugriff nicht wieder gegeneinander arbeiten.

Designentscheidung:
- Playability/Charakterzugriff gewinnt gegen reine Kompaktheit.

### P2 - Kompakte Waffen-Previews haben keine Help-IDs
Betroffen:
- `scripts/meta/fob_screen.gd:2178` bis `:2191`
- Vergleich: volle Preview setzt Help-ID in `scripts/meta/fob_screen.gd:2738` bis `:2751`
- Test: `task_267`

Symptom:
- Rot: `Required visible control carries loadout.weapon_preview`.
- Rot: `Required visible control carries loadout.weapon_none`.
- Die kompakte Preview setzt `weapon_id` und `weapon_preview_path`, aber keinen `help_id`.

Empfohlener Patch:
1. In `_build_compact_weapon_preview()` ebenfalls `_apply_help_id(preview_rect, "loadout.weapon_none" if none else "loadout.weapon_preview")` setzen.
2. Bei `none` entscheiden, ob der `TextureRect` unsichtbar bleiben darf. Wenn er unsichtbar ist, braucht ein sichtbarer Empty-Slot-Anker denselben Help-Text.
3. `task_265`, `task_267`, `task_268` zusammen laufen lassen.

Designentscheidung:
- Help-Abdeckung ist nicht nur Katalogarbeit. Sichtbare Controls brauchen die IDs direkt am Control oder an einem sichtbaren Ersatzanker.

### P1 - Take-Intent mappt nicht zu Sector-Security
Betroffen:
- `scripts/command/commander_intent.gd:168` bis `:196`
- `scripts/command/commander_intent.gd:225` bis `:257`
- `scripts/tactical/fireteam_execution_plan.gd:433` bis `:477`
- Docs: `docs/reviews/tactical_decision_branch_integrity_review.md`
- Test: `task_270`

Symptom:
- Rot: `Take intent maps to sector security`.
- Ursache: `CommanderIntent` serialisiert `security_mode` default auf `facing`. `FireteamExecutionPlan._map_security_mode()` sieht dadurch eine explizite Security und erreicht den Verb-Fallback fuer `take -> sector` nicht.
- Aehnlich riecht `cover_priority = normal`, wodurch Risk-/Tempo-Fallbacks fuer Cover schwer erreichbar werden.

Warum das wichtig ist:
- Der Commander soll Absicht geben, der Fireteam Leader interpretiert. Wenn stille Defaults alles ueberstimmen, wirkt die Taktik flacher und UI/Simulation koennen auseinanderlaufen.

Empfohlener Patch:
1. In `CommanderIntent` zwischen "explizit gewaehlt" und "Default" unterscheiden.
2. `security_mode` und `cover_priority` nur dann in `to_dict()` serialisieren, wenn sie wirklich vom Spieler/Scenario gesetzt wurden, oder Metadaten wie `security_mode_explicit` einfuehren.
3. `FireteamExecutionPlan` Fallbacks fuer `take`, `engage`, `support`, `hold`, `risk`, `tempo` wieder erreichbar machen.
4. Normalization-Warnings fuer unbekannte Werte beibehalten/erweitern.
5. `task_270` und `task_285` zusammen laufen lassen.

Designentscheidung:
- Delegationslogik gewinnt gegen starre UI-Defaults. Defaults duerfen die Fireteam-Leader-Interpretation nicht heimlich blockieren.

### P2 - Editor-Palette: alter Scroll-Test passt nicht sauber zur neuen Gruppenpalette
Betroffen:
- `scripts/editor/map_editor.gd:4882` bis `:4964`
- Test: `task_258`

Symptom:
- Rot: `Editor palette exposes a long ItemList with built-in scrolling`.
- Aktuell filtert `_populate_tile_palette()` sofort auf die erste Gruppe. Dadurch kann `TileTypeList.item_count < 12` sein, obwohl die Palette insgesamt lang ist.

Bewertung:
- Die gruppierte Palette entspricht dem Userwunsch nach besserer Uebersicht.
- Der Test stammt aus der Zeit "lange Liste muss scrollbar sein" und ist teilweise veraltet.
- Trotzdem: User hatte mehrfach "Tileauswahl sieht man nicht" und "Select sehe ich nicht" gemeldet. Also nicht einfach Test loeschen.

Empfohlener Patch:
1. Entweder eine Gruppe "Alle" einfuehren, die genug Items enthaelt und scrollbar ist.
2. Oder `task_258` aktualisieren: prueft `PaletteGroups` plus jede Gruppe mit Overflow/Scroll, nicht pauschal `item_count >= 12`.
3. In `_refresh_palette_selection_visual()` nach `select(selected_index)` `ensure_current_is_visible()` nutzen.
4. `allow_reselect = true` fuer die TileTypeList pruefen, damit erneutes Klicken sichtbar/reaktiv bleibt.
5. Selection-Farben weiter beibehalten, aber im hellen und dunklen UI kontrastpruefen.

Designentscheidung:
- Gruppenpalette bleibt. Der Testvertrag muss die neue Bedienlogik abbilden, aber Sichtbarkeit/Scrollbarkeit bleibt Pflicht.

### P2 - `TASK_316` existiert als Test, aber ohne Task-Dokument/Roadmap-Anker
Betroffen:
- `scripts/tests/task_316_fob_fireteam_staging_migration.gd`
- `docs/tasks/` hat aktuell nur bis `TASK_315`.
- `docs/TASK_ROADMAP.md` und `docs/IMPLEMENTATION_STATUS.md` enthalten keinen sichtbaren `TASK_316`-Anker.

Warum das wichtig ist:
- Ein gruener Test ohne Task-Dokument ist schwer einzuordnen, besonders wenn er mit `TASK_259` kollidiert.

Empfohlener Patch:
1. Task-Dokument fuer `TASK_316` nachziehen oder Test in eine bestehende Taskreihe integrieren.
2. In der Task explizit festhalten: Kompakte Fireteam-Migration darf Character-Overlay-Zugang nicht entfernen.
3. Roadmap/Implementation-Status synchronisieren.

### P3 - Mission-/Help-Katalog hat viele Ready-IDs, aber nicht alle sind sichtbar
Betroffen:
- `task_267` Warnungen fuer weitere IDs, u.a. mehrere `mission.command.group.*` und `loadout.weapon.*`.

Bewertung:
- Harte Fehler sind nur `loadout.weapon_preview` und `loadout.weapon_none`.
- Die Warnliste ist trotzdem nuetzlich: Sie zeigt, wo Help schon im Katalog existiert, aber noch nicht im echten sichtbaren UI landet.

Empfohlener Patch:
1. Erst die zwei roten Loadout-IDs fixen.
2. Danach eine kleine "visible help anchor" Review fuer Command-Gruppen machen: Gruppenlabel, Panel oder erster Button muss die Gruppen-Hilfe tragen.
3. Keine langen Tooltip-Texte in Buttons; kurze `help_id`, Detail im Popup.

## Task-Widersprueche nach Designgewichtung

### 1. Fixed Windows vs Container/Responsive Verhalten
Prioritaet: Fixed Windows gewinnt.

Begruendung:
- User hat feste Fenstergroessen mehrfach als harte Vorgabe genannt.
- Godot-Container sind gut fuer interne Inhalte, aber Hauptfenster duerfen nicht durch Content/SizeFlags wachsen.
- Innerhalb fester Fenster: ScrollContainer, kleine Buttons, kompakte Karten.

### 2. Kompakte FOB-Loadout-UI vs Charakterzugriff
Prioritaet: Charakterzugriff gewinnt.

Begruendung:
- Charakterbogen, Rang, Loadout, Gewicht, Skill-Erklaerung und Teamprogress sind Kernspiel.
- Kompakt ja, aber nicht "nur Dropdowns ohne Person".

### 3. TASK_275 Command-Hierarchie vs TASK_312 Go in #16
Prioritaet: Neuere konkrete User-Vorgabe gewinnt, aber sauber dokumentiert.

Begruendung:
- Der User sagte konkret: Go-Button in 16, Command Matrix.
- `TASK_275` muss diese Entscheidung nachziehen und #18 als Status/Preview/Warnings definieren.
- #16 darf trotzdem nicht ueberladen werden.

### 4. Gruppenpalette vs alter Langlisten-Test
Prioritaet: Gruppenpalette gewinnt, Scroll-/Selection-Sichtbarkeit bleibt Pflicht.

Begruendung:
- Bei vielen Assets ist eine lange Einzel-Liste schlechter bedienbar.
- Automatisierte Tests muessen Gruppen plus Scroll pruefen, nicht alte Rohlaenge.

### 5. UI-Defaults vs Fireteam-Leader-Delegation
Prioritaet: Delegationsmodell gewinnt.

Begruendung:
- Das Design will keine Mikromanagement-Wahrheit in der UI.
- Defaults duerfen nur fallbacken, wenn nichts explizit gesetzt wurde.

## Empfohlene naechste Patchtasks

### TASK_326 - Mission Fixed Window Contract Repair
Ziel: #16/#17/#18 absolut stabil bei 1920x1080 halten.

Akzeptanz:
- `task_180`, `task_181`, `task_258` gruen.
- `CommandPanel.size == Vector2(304, 248)`.
- Kein Container sortiert die drei Hauptfenster breiter/enger.
- Interne Inhalte scrollen statt Fenster zu vergroessern.

### TASK_327 - Command Matrix Go/Hierarchy Reconciliation
Ziel: TASK_275 und TASK_312 zusammenfuehren.

Akzeptanz:
- Go/LZ-Flow fachlich in #16 oder sauber begruendete Ausnahme.
- `task_275`, `task_312`, `task_315` gruen.
- Gruppenrollen in `docs/dev/mission_command_button_hierarchy.md` stimmen mit Code.

### TASK_328 - FOB Loadout Character Access Restore
Ziel: Kompakte #13 Loadout-Rows behalten, aber klickbare Operator-Mini-Karte/Overlay-Zugang wiederherstellen.

Akzeptanz:
- `task_259`, `task_316`, `task_260`, `task_265` gruen.
- Jede Person im Loadout kann Character Overlay oeffnen.
- Assignment-Text bleibt synchron.

### TASK_329 - Compact Loadout Help-ID Fix
Ziel: Hilfe fuer kompakte Waffen-Previews/None-Slots sichtbar machen.

Akzeptanz:
- `task_267`, `task_268` gruen.
- `loadout.weapon_preview` und `loadout.weapon_none` sind an sichtbaren Controls vorhanden.

### TASK_330 - CommanderIntent Explicit Defaults Patch
Ziel: Security/Cover-Fallbacks wieder erreichbar machen.

Akzeptanz:
- `task_270`, `task_285`, relevante tactical smoke tests gruen.
- `take -> bounding + sector`, sofern Spieler nicht explizit anderes gesetzt hat.
- Cover-Risk-/Tempo-Map funktioniert bei nicht expliziter Cover-Priority.

### TASK_331 - Editor Palette Group Scroll/Selection Contract
Ziel: Gruppierte Palette als neues Konzept festziehen und alte Langlistenannahme ersetzen.

Akzeptanz:
- `task_258` gruen mit Gruppenlogik.
- TileTypeList nutzt `ensure_current_is_visible()`.
- Selection bleibt optisch eindeutig in dunklem und hellem UI.
- Optional "Alle"-Gruppe, falls fuer schnelle Suche sinnvoll.

### TASK_332 - Followup Documentation Consistency Check
Ziel: Nach dem TASK_317-TASK_325-Backfill pruefen, ob neue Tests, Roadmap und Status weiter zusammenbleiben.

Akzeptanz:
- `docs/tasks/TASK_316_...md` und `docs/tasks/TASK_317_...md` bis `TASK_325_...md` existieren oder Tests sind eindeutig bestehenden Tasks zugeordnet.
- Roadmap und Implementation Status verweisen auf denselben Stand.

## Performance-Einschaetzung
Die Performance-Tasks laufen im aktuellen Headless-Stand gruen. Trotzdem sollte der naechste grosse Playtest-Pass nicht "optimieren auf Verdacht" machen. Die Godot-Doku empfiehlt zuerst Bottlenecks zu messen, dann gezielt zu optimieren; CPU-Profiler, Godot-Profiler und manuelle Timing-Messungen sind dafuer die passenden Werkzeuge.

Konkreter Folge-Check:
- Editor 8x8, 32x32 und 64x64 Map mit Grid, Selection, Palette offen.
- Mission mit mehreren Fireteams, Gegnern, FoW, LOS, Bubbles.
- FOB mit 20-30 Operators, mehreren Fireteams, Loadout-Dropdowns, Help-Popups.
- Messen: Framezeit, Node Count, Draw Calls, worst frame spikes, UI rebuild frequency.

## Quellen aus der Web-Recherche
- Godot Docs, Using Containers: Container-Kinder geben eigene Positionierung auf; Container/Size Flags bestimmen Layout. https://docs.godotengine.org/en/stable/tutorials/ui/gui_containers.html
- Godot Docs, Control SizeFlags und MouseFilter: Expand/Fill und Event-Verhalten sind relevant fuer feste HUD-Fenster und durchklickbare Map-Bereiche. https://docs.godotengine.org/en/stable/classes/class_control.html
- Godot Docs, ItemList: ItemList bietet Selection, Reselect, Scroll-Hints, `ensure_current_is_visible()` und separate Selected-Styles. https://docs.godotengine.org/en/stable/classes/class_itemlist.html
- Godot Docs, General Optimization: erst messen, dann Bottlenecks optimieren. https://docs.godotengine.org/en/stable/tutorials/performance/general_optimization.html
- Godot Docs, CPU Optimization: Godot-Profiler und manuelles Timing helfen, echte Engpaesse zu finden. https://docs.godotengine.org/en/stable/tutorials/performance/cpu_optimization.html
- Godot Forum, HBox/GridContainer Layout: Community-Beispiel bestaetigt die praktische Richtung `custom_minimum_size`/GridContainer fuer feste Spalten, aber als Sekundaerquelle. https://forum.godotengine.org/t/hboxcontainer-align/71381

## Abschlussbewertung
Das Projekt ist nicht "verloraufen"; der Grossteil der neuen Systeme ist testbar und viele Chains sind gruen. Die roten Stellen zeigen aber genau die Art von Drift, die bei diesem Projekt gefaehrlich waere: UI-Layout wird doch dynamisch, kompakte Meta-UI entfernt Charakterzugriff, und tactical defaults machen Entscheidungen unsichtbar.

Die naechste sinnvolle Reihenfolge ist:
1. Mission fixed windows reparieren.
2. Command-Hierarchy/Go-Entscheidung sauber zusammenfuehren.
3. FOB Loadout Character Access wiederherstellen.
4. Help-ID fuer kompakte Loadout-Controls fixen.
5. CommanderIntent Defaults semantisch korrigieren.
6. Palette-Testvertrag auf Gruppenlogik aktualisieren.
7. TASK_316 dokumentieren.
