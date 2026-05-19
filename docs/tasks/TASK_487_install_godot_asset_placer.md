# TASK_487 - Install Godot Asset Placer

## Status: IMPLEMENTIERT

## Ziel / Problem
- Der TASK_486-Spike empfiehlt einen Godot-nativen Asset-Placer-artigen Workflow fuer Props, Gebaeude und freie 3D-Objekte.
- Der Godot-Asset-Library-Eintrag ist im Editor schwer auffindbar, deshalb soll das Plugin kontrolliert direkt ins Projekt installiert werden.

## Sinnhaftigkeit / Ursache
- Der bestehende Map Editor bleibt fuer schoene Karten zaeh, besonders bei Vorschau, Rotation und freiem Platzieren.
- Ein installiertes Editor-Plugin erlaubt den naechsten echten Sichttest im Godot-Editor, ohne unsere Gameplay-Wahrheit umzubauen.
- Die stabile Version 1.4.0 unterstuetzt Godot 4.3+ und nutzt in Godot 4.6 das neue EditorDock, waehrend 1.5.x noch als Pre-Release gefuehrt wird.

## Umfang
- Godot Asset Placer 1.4.0 aus dem offiziellen GitHub-Repository unter `addons/asset_placer` installieren.
- Das Plugin in `project.godot` aktivieren.
- Eine lokale Godot-4.6.2-Kompatibilitaetsbremse fuer headless Editor-Import setzen: sichtbare Editor-Sessions nutzen weiter `EditorDock`, headless Verifier/Import ueberspringen den Dock-/Panel-UI-Aufbau.
- Die TASK_486-Tooling-Entscheidung dokumentieren und die Installation headless pruefen.

## Nicht-Ziele
- Kein Umbau des bestehenden Map Editors.
- Keine MeshLibrary-Erzeugung und keine automatische Asset-Katalog-Synchronisierung.
- Keine Gameplay-Interpretation von Asset-Placer-Collections, Nodes oder Plugin-State.
- Keine Aenderung an Runtime-, Mission- oder Terrain-Wahrheit.

## Relevante Contracts / Dokumente
- `docs/dev/map_builder_tooling_spike_contract.md`
- `docs/dev/map_editor_asset_workflow_contract.md`
- `docs/tasks/TASK_486_map_builder_tooling_spike.md`
- Godot Asset Placer Asset-Library-Eintrag: https://godotengine.org/asset-library/asset/4244
- Godot Asset Placer GitHub: https://github.com/levinzonr/godot-asset-placer

## Akzeptanzkriterien
- `addons/asset_placer/plugin.cfg` existiert und meldet Version `1.4.0`.
- Das Plugin ist in `project.godot` unter `editor_plugins/enabled` eingetragen.
- Headless Editor-Import darf nicht am Godot-4.6.2-`EditorDock`-Layout crashen.
- Die Plugin-Lizenz bleibt im installierten Addon erhalten.
- Der Verifier prueft Installation, Aktivierung, Dokumentation und den Source-/Version-Vertrag.
- Die TASK_486-Importer-Regression bleibt gruen.

## Betroffene Dateien
- `addons/asset_placer/**`
- `project.godot`
- `docs/tasks/TASK_487_install_godot_asset_placer.md`
- `docs/dev/map_builder_tooling_spike_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `scripts/tests/task_487_install_godot_asset_placer.gd`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_487_install_godot_asset_placer.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_486_map_builder_tooling_spike.gd`
- `godot_console.exe --headless --path . --import`
- `git diff --check`

## Risiken / offene Punkte
- Der echte Godot-Editor-Sichttest bleibt offen: Dock sichtbar, Asset-Folder synchronisieren, ein kleines Authoring-Szenario bauen und per TASK_486-Importer kompilieren.
- Die lokale headless EditorDock-Abzweigung ist bewusst klein gehalten, aber sie ist eine Vendor-Abweichung von Upstream 1.4.0.
- Asset Placer speichert seine Asset-Bibliothek standardmaessig unter `user://asset_library.json`; fuer Team-Sharing muesste spaeter bewusst ein Projektpfad eingestellt werden.
- Das Plugin ist Editor-Tooling. Asset-Placer-State darf nicht als Runtime- oder Gameplay-Wahrheit gelesen werden.
