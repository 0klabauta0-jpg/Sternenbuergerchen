# TASK_823 - Release Singleplayer Visible Findings Polish

## Ziel / Problem
Der sichtbare Release-Capture aus TASK_822 zeigt den ersten Startscreen als funktional, aber noch zu wenig priorisiert. `Einzelspieler` konkurriert visuell mit Multiplayer, Editor, Mission-Slot-Buttons und Team-Werkzeugen, obwohl der naechste Release-Test klar den Singleplayer-Pfad braucht.

## Sinnhaftigkeit / Ursache
Nach den Homebase-Dead-End-Fixes muss der erste Spielergriff sofort lesbar sein. Der Einstieg soll nicht wie ein Debug-/Editor-Menue wirken, sondern wie ein Startscreen mit einem eindeutigen Primaergriff und ruhigerem Sekundaerbereich.

## Umfang
- `Einzelspieler` als primaeren Release-CTA visuell hervorheben.
- Sekundaere Buttons bleiben vorhanden, werden aber niedriger priorisiert.
- Der bestehende Singleplayer-Route-Pfad bleibt unveraendert.
- Read-only Snapshot fuer den Polish-Zustand.
- Headless-Verifier fuer Sichtprioritaet und Architekturgrenzen.

## Nicht-Ziele
- Kein neues Main-Menu-Layout.
- Kein Entfernen von Multiplayer, Editor oder Team-Bibliothek.
- Kein automatischer Singleplayer-Start.
- Keine Gameplay-, Mission-, Roster- oder Multiplayer-Wahrheit im UI.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_822_release_singleplayer_visible_window_findings.md`
- `docs/tasks/TASK_821_release_first_homebase_cta_emphasis.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`

## Akzeptanzkriterien
- Main Menu exposes `get_release_singleplayer_visible_findings_polish_snapshot()`.
- Snapshot ist read-only und erzeugt keine Gameplay-Wahrheit.
- `Einzelspieler` behaelt die bestehende Route zu `res://scenes/meta/meta_layer_test.tscn`.
- `Einzelspieler` traegt `task_823_release_singleplayer_first_play_cta_v1`.
- Primaer-CTA hat groessere Mindesthoehe und groessere Schrift als die Sekundaerbuttons.
- Multiplayer, Editor, Settings und Mission-Slot-Buttons bleiben vorhanden und als secondary/support markiert.
- Bestehende Main-Menu-Route-Regression bleibt gruen.

## Betroffene Dateien
- `scripts/ui/main_menu_screen.gd`
- `scripts/tests/task_823_release_singleplayer_visible_findings_polish.gd`
- `docs/tasks/TASK_823_release_singleplayer_visible_findings_polish.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_823_release_singleplayer_visible_findings_polish.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_199_main_menu_shell_background_image_verifier.gd`
- `git diff --check`

## Risiken / offene Punkte
- Der Task verbessert die Prioritaet auf dem Startscreen, ersetzt aber keinen neuen sichtbaren Release-Capture nach Export.
- Die Team-/Mission-Slot-Werkzeuge bleiben noch im linken Rail; ein spaeterer groesserer UX-Schnitt kann sie in einen klaren Team-/Tools-Bereich verschieben.
