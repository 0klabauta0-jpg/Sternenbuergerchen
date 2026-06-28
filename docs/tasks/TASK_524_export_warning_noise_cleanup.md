# TASK_524 - Export Warning Noise Cleanup

## Ziel / Problem
Godot-Test- und Exportlaeufe waren funktional gruen, aber zwei bekannte Warnquellen machten die Ausgabe unnoetig laut: das inaktive `godot-open-rts`-Referenzprojekt wurde wegen eines eingebetteten `project.godot` als verschachteltes Projekt erkannt, und ein lokaler Godot-Cache enthielt eine alte Factory-`colormap.png`-UID.

## Sinnhaftigkeit / Ursache
Wenn bekannte, harmlose Warnungen in jedem Lauf auftauchen, gehen echte Export-, Import- oder Runtime-Probleme leichter unter. Fuer Release- und Playtestarbeit soll die Konsole moeglichst nur noch neue, relevante Probleme melden.

## Umfang
- `addons/godot_open_rts_reference/project.godot` als `project.godot.reference` behalten, damit die Referenz nicht mehr als aktives Godot-Projekt erkannt wird.
- Referenzpaket-Doku aktualisieren.
- Factory-GLBs und Importdaten auf den korrekten relativen `Textures/colormap.png`-Pfad und fehlende alte UID pruefen.
- Lokalen Godot-Filesystem-Cache auf die alte UID pruefen und bereinigen.
- HTML-Zwischenbericht, Status und Roadmap aktualisieren.

## Nicht-Ziele
- Kein Reimport aller Factory-Assets.
- Kein Entfernen des `godot-open-rts`-Referenzpakets.
- Kein Runtime-Export-Contract-Rewrite.
- Keine Aenderung an Gameplay, UI-Truth oder Asset-Skalierung.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_511_export_runtime_package_hygiene.md`
- `docs/dev/html_report_workbench_contract.md`
- `data/export_runtime_package_contract.json`
- `addons/godot_open_rts_reference/INSTALL_NOTE.md`

## Akzeptanzkriterien
- Im Referenzpaket existiert kein aktives `project.godot` mehr.
- `project.godot.reference` bleibt als dokumentierte Referenz erhalten.
- Factory-Modelle `building-a`, `building-d`, `chimney-medium` und `detail-tank` enthalten keinen alten `uid://dsxohkhemn17r`-Verweis.
- Die Factory-GLBs behalten `Textures/colormap.png` als relativen Texturpfad.
- Lokaler Godot-Filesystem-Cache enthaelt die alte UID nicht mehr.
- Bestehende Export-Hygiene- und aktuelle Multiplayer-/Cargo-Smokes bleiben gruen.

## Betroffene Dateien
- `addons/godot_open_rts_reference/project.godot.reference`
- `addons/godot_open_rts_reference/INSTALL_NOTE.md`
- `docs/tasks/TASK_524_export_warning_noise_cleanup.md`
- `scripts/tests/task_524_export_warning_noise_cleanup.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_524_export_warning_noise_cleanup.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_511_export_runtime_package_hygiene.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_523_pvp_team_readability_ui_pass.gd`
- `git diff --check`

## Risiken / offene Punkte
- Die Bereinigung verhindert nicht jede zukuenftige Importwarnung, sondern nur die aktuell bekannten lauten Quellen.
- Wer das Referenzprojekt separat oeffnen will, muss `project.godot.reference` ausserhalb dieses Repos wieder zu `project.godot` kopieren oder umbenennen.

## Status: IMPLEMENTIERT
