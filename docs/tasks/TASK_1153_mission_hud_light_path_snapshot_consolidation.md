# TASK_1153 - Mission HUD Light Path Snapshot Consolidation

## Ziel / Problem
TASK_1152 reduziert den periodischen Host-HUD-Pfad von rund 266 auf 68 ms. Davon entfallen im letzten Release-Snapshot etwa 29 ms auf Primary Labels und 40 ms auf Mission Panels. Diese verbleibenden Lesepfade sollen genauer gemessen und ohne verzögertes Kontakt-, Timer- oder Befehlsfeedback konsolidiert werden.

## Ursache / Sinnhaftigkeit
Die aktuellen Profiler-Surfaces fassen mehrere Builder zusammen. Dadurch ist noch nicht belegt, ob Status-/Tooltip-Komposition, Fireteam-/Phase-Panels, Dropship-Panel oder Event-Log den Rest dominiert. Erst nach granularer Messung wird ein einzelner sinnvoller Guard umgesetzt.

## Umfang
- Primary Labels und Mission Panels in stabile Unter-Surfaces messen.
- Den dominanten unveraenderten Unterpfad mit vorhandenen Snapshot-/Signaturmustern guardieren.
- Direktes Befehls-, Kontakt- und Timerfeedback bleibt sichtbar aktuell.
- Zwei-EXE-Release erneut messen.

## Nicht-Ziele
- Kein pauschales Verlangsamen aller HUD-Timer.
- Keine Entfernung sichtbarer Informationen.
- Keine Gameplay-State-Mutation im HUD.
- Kein Umbau von Combat, Movement oder Multiplayer.

## Relevante Contracts / Dokumente
- `docs/ARCHITECTURE.md`
- `docs/tasks/TASK_1152_mission_hud_heavy_refresh_budget_pass.md`
- `docs/performance/ui_hud_comic_bubble_profile_report.md`

## Akzeptanzkriterien
- Release-Evidence nennt einzelne Primary-Label- und Mission-Panel-Kosten.
- Der dominante unveraenderte Unterpfad wird vor seiner teuren Builder-Arbeit uebersprungen.
- Direkte Spieleraktionen erzwingen weiterhin den relevanten sichtbaren Refresh.
- TASK_1043, TASK_1044, TASK_1150, TASK_1151, TASK_1152 und TASK_222 bleiben gruen.
- Zwei exportierte Instanzen erreichen weiterhin gemeinsamen Kontakt und First Fire.

## Betroffene Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- fokussierter TASK_1153-Verifier
- Status, Roadmap und HTML-Handbuch

## Lokale Pruefung
- Fokussierter Headless-Verifier mit Red/Green-Nachweis.
- Bestehende HUD-/Multiplayer-/Performance-Gates.
- Exportierter Zwei-EXE-First-Contact-Lauf.
- `git diff --check` und Release-Startcheck.

## Risiken / offene Punkte
Ein grober Gesamt-Guard koennte legitime Timer- oder Kontaktupdates verschlucken. Deshalb wird erst granular gemessen und danach nur die belegte Unterflaeche angefasst.
