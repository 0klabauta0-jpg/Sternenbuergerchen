# Strategic Review: Code, UI-Assets und Multiplayer-Vorbereitung

Datum: 2026-05-03

## Zweck
Diese Review sammelt Code-Befunde, Optimierungs- und Designvorschlaege, externe Recherche und lokale Asset-Vorschlaege fuer die naechsten kleinen Tasks nach `TASK_160`.

Sie ist keine Implementierungsfreigabe fuer einen Grossumbau. Die Vorschlaege sind bewusst in kleine Task-Slices heruntergebrochen, damit die bestehende Architektur nicht driftet.

## Gelesener Projektkontext
- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/DESIGN_NOTES.md`
- `docs/DECISIONS.md`
- `docs/mission_editor_authoring_audit.md`
- alle Task-Dateien unter `docs/tasks/` wurden ueber Bestand, Nummern, Status und relevante Ueberschriften geprueft.

## Kurzfazit
Das Projekt hat nach `TASK_159`/`TASK_160` eine gute Richtung: 2.5D ist jetzt der primare sichtbare Pfad, Szenario-Authoring ist testbar, und Fallbacks sind im kritischen 3D-Pfad sichtbar statt still. Der groesste technische Druck liegt jetzt nicht bei mehr Features, sondern bei Grenzziehung:

1. Die produktive Missionssteuerung steckt weiter zu stark in sehr grossen Skripten unter `scripts/tests`.
2. Multiplayer ist konzeptionell angelegt, braucht aber vor sichtbarer UI einen harten Command-/Authority-Vertrag.
3. UI-Polish sollte als Theme-/Komponentenarbeit laufen, nicht als weitere Einmal-Layouts in Homebase/FOB/Mission.
4. Lokale Assets sind reichlich vorhanden; der naechste Schritt ist Kuratierung und Importvertrag, nicht Massendrop in `Assets/`.
5. Optimierung sollte Messpunkte bekommen: Godot-Warnungen, Render-Snapshots, Navigation-Budgets und zwei schnelle Playability-Smokes.

## Code-Review-Befunde

### Hoch: Produktive Mission steckt noch in `scripts/tests`
Betroffene Schwerpunkte:
- `scripts/tests/mission_tactical_sandbox_controller.gd`: ca. 6860 Zeilen, `class_name TacticalInputController`, verarbeitet Input, Auswahl, HUD, Dropship, Fireteam-Karten, Area Orders, Meta-Transfer-Visuals und Snapshots.
- `scripts/tests/mission_combat_loop_driver.gd`: ca. 1758+ Zeilen, Combat-/Objective-/Wave-/Snapshot-Driver mit RPCs und Playability-Snapshot.
- `scripts/tests/lobby_test_screen.gd`: ENet-Host/Join und Start-Mission-Flow liegen noch im Testpfad.

Warum kritisch:
- `scripts/tests` wirkt wie Testcode, enthaelt aber produktive Runtime.
- Multiplayer braucht stabile Produktivpfade fuer Session, Command-Ingress, Snapshot-Outbound und Validation.
- Der aktuelle Zustand erschwert Review: Aenderungen an UI, Runtime und Test-Harness landen im selben Riesendiff.

Empfehlung:
- `TASK_161` und `TASK_162` vor weiterem Multiplayer-Feature-Start ausfuehren.

### Hoch: Multiplayer darf nicht ueber UI-Wahrheit starten
Der Code hat bereits wichtige Bausteine:
- `SimulationRoot.is_server_authoritative`
- `SimulationRoot.request_command()`
- `SimulationRoot._receive_tick_state()`
- Unit-Snapshots und Vital-State-Updates
- `RespawnManager` achtet bereits auf server-authoritative Mode.

Was fehlt:
- Whitelist fuer erlaubte Remote-Commands.
- Peer-zu-Fireteam-/Commander-Rechte.
- klare Unterscheidung zwischen Command-Input, authoritativer Simulation und Render-Snapshot.
- Headless-/lokaler Zwei-Client-Smoke.

Empfehlung:
- Erst `TASK_166` Command Contract, dann `TASK_167` Session/Lobby, dann `TASK_168` Snapshot Contract, danach `TASK_169` Playability-Smoke.

### Hoch: Monolithische UI-Skripte bremsen Design-Iteration
Hotspots:
- `scripts/meta/fob_screen.gd`: ca. 2258+ Zeilen, viele `_build_*` UI-Erzeuger.
- `scripts/meta/homebase_screen.gd`: ca. 1333+ Zeilen, Shipcards, Charakterbogen, Transferdarstellung.
- `scripts/meta/meta_layer_flow.gd`: ca. 1526+ Zeilen, Flow, Transfer, Missionsstart, Missionsdefinitionen.
- `scripts/editor/map_editor.gd`: ca. 3308+ Zeilen, Terrain-Tools, Scenario-Panel, Marker, Patrols, 2.5D-Bridge.

Empfehlung:
- Nicht sofort "schoener machen", sondern erst Komponenten-/Theme-Schnitt: gemeinsame Card-/Button-/Status-/Progress-Komponenten, dann Kenney-Asset-Skin.

### Mittel: Fallback-Politik ist gut, aber braucht einen Warnungs-Gate
Nach der letzten Arbeit sind Missing-Asset-Marker im 2.5D-Primary-Pfad sichtbar. Das ist gut. Jetzt sollte daraus ein Budget werden:
- Keine RID/ObjectDB-Leaks im Verifier-Output.
- Keine stillen Sprite3D-/Box-/Capsule-Fallbacks im Primary-Pfad.
- Snapshot-Zaehler fuer fehlende Asset-Mappings bleiben testbar.

Empfehlung:
- `TASK_170` als Warning-/Performance-Gate schneiden.

### Mittel: Map-Editor braucht Modulgrenzen vor weiteren Authoring-Features
Der Editor kann sehr viel, aber weitere Tools wuerden `map_editor.gd` weiter aufblasen. Sinnvolle Schnitte:
- Terrain Brush Tool
- Height/Edge Tool
- Marker/Patrol Tool
- Mission Scenario Panel
- 2.5D View Adapter
- File Dialog / Load Save Controller

Empfehlung:
- `TASK_163` als verhaltensneutraler Split, bevor neue Authoring-Features folgen.

## Optimierungsvorschlaege
1. Warnungsbudget: Godot-Headless-Smokes sollen RID/ObjectDB-Leaks und fehlende Primary-Assets als harte Fehler behandeln.
2. Snapshot-Budget: `TerrainMap3DView.get_render_snapshot()` als Messpunkt fuer Asset-Zaehler, Render-Dauer und fehlende Mappings weiter nutzen.
3. Navigation-Budget: bestehende HPA-/Budget-Snapshots in einen schnellen Regression-Smoke aufnehmen, nicht nur in einzelne Task-Verifier.
4. Asset-Instancing: GLB-Modelle und Materialien nicht pro Tile neu teuer erzeugen, sondern Mappings/Scenes/Materials cachen und nur Snapshot-bedingt neu spiegeln.
5. UI-Build-Kosten: grosse UI-Screens nicht bei jedem kleinen State-Update komplett neu bauen; stattdessen Komponenten mit `set_data()` und Dirty-Flags.
6. Test-Suite trennen: kleine Smoke-Gruppe fuer jeden Commit, grosse Regression-Gruppe fuer Integrationspunkte.

## Designvorschlaege
Die Reise passt am besten zu einer kompakten taktischen Kommandooberflaeche, nicht zu einer dekorativen Sci-Fi-Landingpage. Gute Zielrichtung:

- Mission: Karte bleibt Hauptflaeche; links/oben Status und Phase, unten oder rechts Befehlsmatrix, Kontakt-/Objective-Alerts nah an der Karte.
- Selected Fireteam: klare State-Zeile mit Auftrag, Haltung, Kontakt, Unterdrueckung, Verwundung, ETA.
- Objective: persistente kleine Leiste statt grosser Textflaeche.
- Dropship: als taktisches Asset mit LZ/ETA/Boarding-Progress, nicht nur als Deko.
- Homebase/FOB: dicht, scanbar, konsistent; wenige visuelle Hero-Elemente, dafuer klare Roster-/Transfer-/Loadout-Panels.
- Icons: fuer wiederkehrende Befehle und Status lieber Kenney-/UI-Icons plus Tooltip als lange Buttontexte.

## Lokale Assets: Bestand und Nutzungsvorschlaege
Quelle: `C:\Users\bjoer\Pictures\Sternenbürger`

### Inventar in Zahlen
- 8110 PNG
- 2185 SVG
- 978 GLB
- 960 FBX
- 898 OBJ/MTL-Paare
- 576 DAE
- 576 STL
- 18 TTF und 14 OTF
- 6 OGG

### Groesste relevante Ordner
| Ordner | Dateien | Vorschlag |
| --- | ---: | --- |
| `kenney_input-prompts_1.4.1` | 4099 | Tastatur-/Controller-Glyphen fuer Tooltips, Keybinds, Tutorial-Hints |
| `kenney_ui-pack` | 1315 | Basis fuer Buttons, Panels, Slider, Frames |
| `kenney_ui-pack-space-expansion` | 1117 | Sci-Fi-/Space-Variante fuer Mission/FOB, vorher Lizenz/Quelle lokal pruefen |
| `kenney_space-kit` | 1692 | Bestehender Terrain-/Space-Kit-Pfad, weiter primaer fuer kalibrierte Map-Assets |
| `Space Kit` / `3d` | je 924 | Alternative/duplizierte 3D-Modelle, vor Import deduplizieren |
| `Space Station Kit` | 738 | Homebase/FOB/Hangar-Hintergrund, Dropship-Bay, Raum-Panels |
| `Modular Space Kit` | 214 | modulare Homebase-/FOB-Setpieces, Spaeter 3D-Staging |
| `Prototype Kit` | 740 | neutrale Blocking-/Calibration-Assets, nicht als finaler Stil erzwingen |
| `kenney_ranks-pack` | 644 | FTL/Rang/Rollen/Status-Badges |
| `kenney_cursor-pixel-pack` | 227 | Editor- und Tactical-Cursor-Zustaende |
| `kenney_particle-pack` | 195 | LZ, Kontakt, Objective, Suppression-VFX als reine Visuals |
| `Blaster Kit` / `Weapon Pack` | 211 / 287 | Waffenvisuals und Loadout-Preview, an `WeaponData` binden |
| `Animated Characters Bundle`, `Soldier`, `Top_Down_Survivor` | 237+ | spaetere Unit-Animation-Prototypen; aktuell nicht vor 3D-Unit-Primary-Pfad ueberfrachten |
| `Char` und Root-Portraits | 88+ | Portrait-Pool fuer NPC-Karten, Character Sheet, Roster-Varianten |
| `Valkyrie_in_space_*` | 6+ | Dropship-/Transportcraft-Identity fuer Karten, Briefing, Meta-Flugroute |

### Konkrete Asset-Entscheidung
Kurzfristig:
- Kenney UI Pack + UI Pack Sci-Fi/Space fuer ein gemeinsames Theme.
- Ranks Pack fuer FTL-/Unit-Badges.
- Input Prompts fuer Tooltips/Shortcuts.
- Cursor Pack fuer Editor-/Tactical-Tools.
- Valkyrie-Bilder fuer Dropship-/Transportcraft-Card und Debrief.

Nicht sofort:
- Massenimport der 900+ GLB/FBX/OBJ-Dateien.
- Portraetbilder ohne Zuschnitt-/Namens-/Lizenzmetadaten.
- FBX als Primaerformat, solange GLB verfuegbar ist.

## Externe Recherche

### Godot Multiplayer
- Godot High-level Multiplayer: Godot nutzt fuer die High-Level-API UDP; Host/Join laeuft ueber `MultiplayerPeer`/ENet, und Nicht-LAN-Hosts brauchen UDP-Portfreigabe. Quelle: https://docs.godotengine.org/en/stable/tutorials/networking/high_level_multiplayer.html
- `ENetMultiplayerPeer`: ENet ist UDP-basiert; fuer Internet-Hosting muss der UDP-Port erreichbar sein. Quelle: https://docs.godotengine.org/en/stable/classes/class_enetmultiplayerpeer.html
- `MultiplayerSynchronizer`: synchronisiert konfigurierte Properties von der Authority zu Remote-Peers, aber keine `Object`-/`Resource`-/RID-artigen Werte. Quelle: https://docs.godotengine.org/en/stable/classes/class_multiplayersynchronizer.html
- `MultiplayerSpawner`: spawnt replizierbare Nodes von der Authority zu anderen Peers. Quelle: https://docs.godotengine.org/en/stable/classes/class_multiplayerspawner.html

Schluss fuer dieses Projekt:
- Synchronizer/Spawner sind nuetzlich fuer sichtbare, einfache Node-Replikation.
- Fuer Sternenbuergerchen sollte der Kern trotzdem command-/snapshot-basiert bleiben, weil `SimulationRoot` die Wahrheit sein muss und UI/3D-View nur spiegeln.

### Forum-/Community-Learnings
- Godot-Forum zu RPC-Setup empfiehlt, RPC-Argumente explizit zu setzen, `any_peer` nur fuer Client-Input zu nutzen und Transfer-Modi bewusst zu waehlen. Quelle: https://forum.godotengine.org/t/im-trying-to-understand-the-logic-and-use-cases-of-rpcs-in-relation-to-server-authoritative-gameplay-on-a-dedicated-server/86218/10
- Reddit/Godot-Diskussionen laufen auf denselben Trade-off hinaus: mehr serverseitige Wahrheit bedeutet korrektere Zustandsfuehrung, braucht aber Interpolation/Korrektur fuer fluessige Clients. Quelle: https://www.reddit.com/r/godot/comments/1ru9jxg/multiplayer_synchronisation/

Schluss fuer dieses Projekt:
- Keine Client-Autoritaet fuer Positions-, Combat-, Objective- oder Dropship-State.
- Clients senden Commander-/FTL-Commands.
- Server validiert und repliziert kompakte Snapshots.
- Client-Interpolation ist Darstellung, keine Gameplay-Wahrheit.

### UI-/Asset-Recherche
- Kenney UI Pack: 430 Dateien, CC0, Buttons/Panels/Slider/Interface. Quelle: https://kenney.nl/assets/ui-pack
- Kenney UI Pack Sci-Fi: 130 Dateien, CC0, Space/Sci-Fi UI-Elemente. Quelle: https://kenney.nl/assets/ui-pack-sci-fi
- Kenney Ranks Pack: 70 Dateien, CC0, Rank/Medal/Interface. Quelle: https://kenney.nl/assets/ranks-pack
- Kenney Cursor Pack: 180 Dateien, CC0, Cursor/Icon/Interface. Quelle: https://kenney.nl/assets/cursor-pack
- Kenney Input Prompts: ueber 1280 Icons fuer Controller/Keyboard. Quelle: https://kenney-assets.itch.io/input-prompts/devlog/692303/content-update-11
- OpenGameArt UI Pack Sci-Fi beschreibt dieselbe Kenney-Sci-Fi-Erweiterung als Space/modern GUI-Pack mit PNG, Vektor und Fonts, CC0. Quelle: https://opengameart.org/content/ui-pack-space-extension

Designreferenzen:
- Into the Breach nutzt kompakte In-Game-, Overlay-, Quest-, Progress- und Stats-Patterns. Quelle: https://interfaceingame.com/games/into-the-breach/
- XCOM 2 zeigt gute Trennung aus Tactical HUD, Stats, Inventory, Move/Fire/Objective-Screens. Quelle: https://interfaceingame.com/games/xcom-2/
- Baymard zu Dashboard-Cards: Konsistenz und vorsichtiger Einsatz von Bildern verbessern Scanbarkeit. Quelle: https://baymard.com/blog/cards-dashboard-layout

## Task-Empfehlung
Neue Task-Dateien:
- `TASK_161 - Mission Runtime Boundary Cleanup`
- `TASK_162 - Combat Loop Authority Split`
- `TASK_163 - Map Editor Module Split`
- `TASK_164 - UI Theme and Component Library`
- `TASK_165 - Local Asset Curation and Import Plan`
- `TASK_166 - Multiplayer Authority Command Contract`
- `TASK_167 - Multiplayer Session and Lobby Extraction`
- `TASK_168 - Multiplayer Snapshot Replication Contract`
- `TASK_169 - Multiplayer Two-Client Playability Smoke`
- `TASK_170 - Performance and Warning Budget Gate`

Empfohlene Reihenfolge:
1. `TASK_161`, `TASK_162`, `TASK_170` fuer technische Grenzen und Warnungsbudget.
2. `TASK_164`, `TASK_165` fuer UI-/Asset-Basis.
3. `TASK_166`, `TASK_167`, `TASK_168`, `TASK_169` fuer Multiplayer-Vorbereitung.
4. `TASK_163`, sobald wieder Editor-Feature-Arbeit ansteht.

## Scope-Grenzen
- Kein Multiplayer-PvP-Persistenzsystem.
- Kein Matchmaking.
- Kein grosser Fahrzeug-Simulator.
- Kein Import aller lokalen Assets.
- Kein Refactor von SimulationRoot nur zur Schoenheit.
- Keine UI als Gameplay-Wahrheit.
