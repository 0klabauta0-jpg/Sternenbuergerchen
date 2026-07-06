# TASK_828 - Release Ultrawide Canvas Stretch

## Ziel / Problem
Im sichtbaren Release kann die UI auf breiten Fenstern wie ein 1920px-Spiel links oben wirken, waehrend rechts eine grosse tote Flaeche bleibt. Das macht Homebase und Mission trotz funktionierendem Startpfad unpoliert und schlecht lesbar.

## Sinnhaftigkeit / Ursache
`project.godot` definierte nur `viewport_width=1920` und `viewport_height=1080`, aber keinen Stretch-Vertrag. Bei Fenstern oberhalb der Basisgroesse darf Godot deshalb den Basisviewport statt einer erweiterten Canvas-Flaeche zeigen. Fuer UI-first-Screens ist `canvas_items` + `expand` der passende Release-Vertrag: FullHD bleibt die Basiskomposition, breitere Fenster bekommen aber nutzbare Canvas-Breite.

## Umfang
- Projekt-Stretch auf `canvas_items` setzen.
- Stretch-Aspect auf `expand` setzen.
- Verifier fuer Projektsetting und fullscreen-geankerte App-Shell-/MetaLayer-Screens.

## Nicht-Ziele
- Kein Redesign einzelner Homebase-Panels.
- Kein Umbau des Mission-HUDs.
- Kein Entfernen der FullHD-Minimum-Layouts.
- Keine Aenderung an Gameplay-, MetaLayer- oder Multiplayer-Wahrheit.

## Relevante Contracts / Dokumente
- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/tasks/TASK_822_release_singleplayer_visible_window_findings.md`
- `docs/tasks/TASK_827_release_homebase_save_override_guard.md`

## Akzeptanzkriterien
- `project.godot` enthaelt `display/window/stretch/mode = canvas_items`.
- `project.godot` enthaelt `display/window/stretch/aspect = expand`.
- Main Menu und Homebase bleiben fullscreen-geankerte Controls, damit die erweiterte Canvas-Flaeche tatsaechlich nutzbar ist.
- Der Verifier benennt den Task und prueft die Settings ohne Gameplay-State zu mutieren.

## Betroffene Dateien
- `project.godot`
- `scripts/tests/task_828_release_ultrawide_canvas_stretch.gd`
- `docs/tasks/TASK_828_release_ultrawide_canvas_stretch.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_828_release_ultrawide_canvas_stretch.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_199_main_menu_shell_background_image_verifier.gd`
- `git diff --check`

## Risiken / offene Punkte
Der Stretch-Vertrag verhindert die grobe rechte Leerflaeche, ersetzt aber keinen echten Ultrawide-Screenshot auf deinem Monitor. Falls einzelne Panels danach zu breit oder zu luftig wirken, ist das ein separater Layout-Polish-Task pro Screen.
