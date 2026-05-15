# TASK_433 - Install Third Party Godot Plugins

## Ziel / Problem

- Vier externe Godot-Erweiterungen sollen lokal ins Projekt geholt werden: `godot-open-rts`, `Terrain3D`, `limboai` und `netfox`.
- Die Installation soll nachvollziehbar bleiben und bestehende Runtime-/UI-Architektur nicht still umbauen.

## Sinnhaftigkeit / Ursache

- Die Plugins erweitern potenziell RTS-Steuerung, Terrain, Verhalten/BT und Netzwerkfunktionalitaet.
- Ohne dokumentierten Installationsschritt waeren neue Addons schwer zu pruefen und spaeter schwer sauber zu aktualisieren.

## Umfang

- Repositories aus den angegebenen GitHub-Quellen herunterladen.
- Projektkompatible Addon-Dateien unter `addons/` installieren.
- Godot-Plugin-Aktivierung in `project.godot` nur fuer Addons eintragen, die eine gueltige `plugin.cfg` liefern.
- Lizenz-/Versionsherkunft pro installiertem Plugin dokumentieren, wenn die Quellen diese Informationen enthalten.

## Nicht-Ziele

- Keine Gameplay-Integration der Plugin-APIs.
- Keine Migration bestehender Terrain-, Navigation-, AI- oder Multiplayer-Systeme.
- Keine Architekturentscheidung, welches Plugin spaeter autoritative Gameplay-Wahrheit fuehrt.
- Keine Aenderung an bestehenden Mission-, UI- oder Runtime-Pfaden.

## Relevante Contracts / Dokumente

- `AGENTS.md`
- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Akzeptanzkriterien

- [x] Die vier Plugin-Quellen wurden lokal heruntergeladen oder nachvollziehbar eingebunden.
- [x] Installierte Addons liegen unter `addons/` und behalten ihre projektseitig notwendigen Ressourcen.
- [x] `project.godot` aktiviert nur vorhandene Godot-Editorplugins mit gueltiger `plugin.cfg`.
- [x] Kein bestehender Gameplay-Code nutzt die neuen Plugins automatisch.
- [x] Lokaler Godot-Import/Headless-Start wurde ausgefuehrt oder ein Blocker ist dokumentiert.
- [x] `git diff --check` meldet keine Whitespace-Fehler fuer die eigenen Aenderungen.

## Installationsbefund

- `Terrain3D` wurde aus Release `v1.0.1` nach `addons/terrain_3d/` installiert und als EditorPlugin aktiviert.
- `LimboAI` wurde aus Release `v1.7.0` / `gdextension-4.6` nach `addons/limboai/` installiert. Das Paket liefert keine `plugin.cfg`; die GDExtension wird ueber `addons/limboai/bin/limboai.gdextension` geladen.
- `netfox` wurde aus dem aktuellen `main`-Branch nach `addons/netfox/` und `addons/netfox.internals/` installiert und aktiviert. Das stabile Release `v1.35.3` wurde geprueft, kompiliert aber im Godot-4.6.2-Headless-Import nicht sauber; die aktuelle Repo-Version `1.43.4` importiert nach einmaligem Autoload-Setup sauber.
- `godot-open-rts` wurde als inaktives Referenzpaket nach `addons/godot_open_rts_reference/` eingebunden. Upstream ist ein Godot-4.3-Beispielprojekt ohne `plugin.cfg`; der Ordner ist per `.gdignore` neutralisiert und wird nicht als Plugin aktiviert.

## Betroffene Dateien

- `addons/`
- `project.godot`
- `docs/tasks/TASK_433_install_third_party_godot_plugins.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung

- `godot_console.exe --headless --path . --import`
- `godot_console.exe --headless --path . --quit`
- `git diff --check`

Ausgefuehrt:

- `godot_console.exe --version` -> `4.6.2.stable.official.71f334935`
- `godot_console.exe --headless --path . --import` -> erfolgreich; Warnung: `addons/godot_open_rts_reference` enthaelt ein eigenes `project.godot` und wird ignoriert.
- `godot_console.exe --headless --path . --quit` -> erfolgreich; netfox gibt eine Debug-Zeile fuer Performance-Monitor-Registrierung aus.
- `git diff --check -- project.godot docs/tasks/TASK_433_install_third_party_godot_plugins.md docs/IMPLEMENTATION_STATUS.md addons/terrain_3d addons/limboai addons/netfox addons/netfox.internals addons/godot_open_rts_reference` -> erfolgreich.

## Risiken / offene Punkte

- Native/GDExtension-Plugins koennen Godot-Version-spezifische Binaries benoetigen.
- Externe Plugins koennen Importzeiten, Exportgroesse oder Editorstart beeinflussen, auch ohne Gameplay-Integration.
- Der aktuelle Arbeitsstand baut auf einem noch nicht integrierten Fireteam-Task-Branch mit vorhandenen uncommitted Aenderungen auf.
