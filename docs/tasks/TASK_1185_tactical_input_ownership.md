# TASK_1185 - Tactical Input Ownership

## Ziel / Problem

Im taktischen Viewport konkurrieren Kamera, Tactical Controller und einzelne
UI-Features um direkte Tastatur- und Mausereignisse. Das macht Eingaben
kontextabhaengig unklar und kann einen Command, eine Auswahl oder eine
Kamerabewegung gleichzeitig ausloesen.

## Ursache

`MissionMapCameraController` liest Bewegungs- und Drehtasten direkt mit
`Input.is_key_pressed`, waehrend `MissionTacticalSandboxController` dieselben
Tasten ueber `physical_keycode` als taktische Aktionen behandelt. Die rechte
Maustaste wird im 3D-Kamerapfad ausserdem als Drag-Eingabe konsumiert.

## Festgelegte Owner-Matrix

| Eingabe | Aktiver Kontext | Einzige Live-Aktion |
| --- | --- | --- |
| WASD / Pfeile | Tactical Viewport | Kamera verschieben |
| Mausrad | Pointer nicht ueber UI | Kamera zoomen |
| Q / E | Tactical Viewport | Kamera links / rechts drehen |
| MMB-Drag | Tactical Viewport | Kamera drehen |
| LMB / Drag / Ctrl+LMB | Tactical Map | Auswahl, Box-Select, additiv |
| RMB Klick/Drag | Tactical Map | Waypoint-/Area-Order |
| Shift+RMB | Tactical Map | Order anhaengen |
| Tab / Shift+Tab | Tactical-Viewport-Fokus | Fireteam vor / zurueck |
| G | Tactical Viewport | geplante Orders ausfuehren |
| Enter / Space | fokussiertes UI-Control | Karte oder Button aktivieren, niemals GO |
| Delete | Tactical Viewport | fokussierte Order loeschen |
| 1 / 2 / 3 / 4 | Tactical Viewport | Move / Defend / Flank / Take |
| B | Tactical Viewport | Breach |
| C / L | Tactical Viewport | Fire-Sector / LOS umschalten |
| T | Tactical Viewport | Fireteam sortieren |
| V halten | global, remapbar | NPC-Gedanken anzeigen |
| R / F | nur Phase Planning | Phase zurueck / vor |

Bei UI-Fokus behalten Tab und Shift+Tab die Standardaktionen
`ui_focus_next` und `ui_focus_prev`. Ausserhalb der Planungsphase loesen R und
F keine Aktion aus.

## Umfang und Nicht-Ziele

- Alle genannten taktischen Eingaben werden als InputMap-Actions beschrieben
  und von genau einem Owner verarbeitet.
- Der Owner markiert ein akzeptiertes Ereignis als behandelt.
- Der Kameracontroller konsumiert keine rechte Maustaste.
- HUD-Legende und Settings verwenden dieselben Action-IDs.
- Keine Command-, Combat-, Missions- oder Multiplayer-Semantik wird geaendert.
- Kein Umbau der allgemeinen UI-Navigation ausser dem Schutz des vorhandenen
  Tab-Fokusverhaltens.

## Relevante Dokumente

- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/dev/runtime_script_layout_contract.md`
- `docs/dev/tactical_command_rules_contract.md`
- `docs/dev/dropship_lz_target_accuracy_contract.md`
- `docs/dev/comic_bubble_manual_smoke_checklist.md`

## Akzeptanzkriterien

- Der Verifier belegt pro Owner-Matrix-Eintrag genau einen semantischen Owner.
- Q/E aendern keinen Command und keine Auswahl; RMB dreht keine Kamera.
- T aktiviert keine Gedanken, V sortiert keine Fireteams, G wechselt kein
  Fireteam und Enter/Space fuehren kein GO aus.
- Tab respektiert UI-Fokus; entfernte Alias-Tasten Q fuer Fireteam, E fuer GO
  und T fuer Gedanken bleiben unwirksam.
- Die bestehenden Verifier TASK_315 und TASK_406 bleiben gruen.

## Betroffene Dateien

- `project.godot`
- `scripts/tests/mission_map_camera_controller.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/ui/comic_bubble_runtime_gate.gd`
- `scripts/ui/comic_bubble_settings.gd`
- `scripts/ui/game_settings_contract.gd`
- `scripts/tests/task_1185_tactical_input_ownership.gd`

## Lokale Pruefung

```powershell
godot_console.exe --headless --path . --script scripts/tests/task_1185_tactical_input_ownership.gd
godot_console.exe --headless --path . --script scripts/tests/task_315_mission_grid_tile_selection_command_gate.gd
godot_console.exe --headless --path . --script scripts/tests/task_406_mission_lz_click_input_guard.gd
git diff --check
```

## Risiken / offene Punkte

Der Headless-Verifier kann die vollstaendige Betriebssystem-Fokusweitergabe an
ein echtes Control nicht pixelgenau beweisen. Die Owner-Grenzen, das
UI-Fokus-Gate und die Action-Matrix werden deshalb automatisiert geprueft; die
vollstaendige Tabelle bleibt anschliessend ein gezielter manueller Fenstercheck.
