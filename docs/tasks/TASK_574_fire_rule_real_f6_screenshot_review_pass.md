# TASK_574 - Fire Rule Real F6 Screenshot Review Pass

## Ziel / Problem
TASK_573 hat eine exportierbare Arbeitsflaeche fuer Fire-Rule-/ROE-Screenshot-Notizen geschaffen. Jetzt braucht der Block eine echte, reproduzierbare Evidence-Basis: ein FullHD-F6-Bild mit sichtbaren `HF`/`RF`/`FW`/`SUP`-Controls, aktivem Fireteam und einem Manifest, das die wichtigsten Readability-Gates und den offenen menschlichen Review klar dokumentiert.

## Sinnhaftigkeit / Ursache
Automatisierte Layout-Pruefungen sind nuetzlich, aber visuelle Reibungen werden erst im Bild offensichtlich. Der Capture darf keine Gameplay-Entscheidung treffen; er soll nur beweisen, dass der reale F6-Zustand erfassbar ist und dem HTML-Bericht eine konkrete Datei plus Status liefert.

## Umfang
- Reproduzierbarer Fire-Rule-F6-Capture fuer `1920x1080`.
- `tmp/fire_rule_f6_real_review.png` als Screenshot/Evidence-Datei.
- `tmp/fire_rule_f6_real_review.json` als Manifest mit Readability-Gate, aktiver Rule, Button-Zahlen, Viewport-Readback-Status und offenem manuellen Review.
- HTML-Zwischenbericht zeigt Evidence-Pfad und markiert TASK_574 als erledigten Evidence-Capture, nicht als abgeschlossenen menschlichen Geschmackstest.
- Statischer und runtime-basierter Verifier prueft Doku, Manifest und Capture.

## Nicht-Ziele
- Kein neues Fire-Rule-, Combat-, Movement-, Suppression- oder Command-System.
- Kein behaupteter menschlicher Hover-/Geschmackstest.
- Kein HUD-Redesign ohne belegten Folgefund.
- Keine Runtime- oder Gameplay-Wahrheit im HTML-Bericht oder Manifest.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/html_report_workbench_contract.md`
- `docs/tasks/TASK_572_fire_rule_f6_readability_smoke.md`
- `docs/tasks/TASK_573_fire_rule_manual_screenshot_notes_pass.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Akzeptanzkriterien
- Der TASK_574-Verifier erzeugt PNG und JSON-Manifest unter `tmp/`.
- Der TASK_572-F6-Readability-Gate bleibt im Capture-Zustand gruen.
- Das Manifest meldet `read_only = true`, `ui_sets_gameplay_truth = false`, `manual_review_required = true` und `manual_review_done = false`.
- Bei nicht-headless Lauf muss `viewport_readback_available = true` sein; Headless darf nur ein markiertes Evidence-Board erzeugen.
- Der HTML-Bericht nennt PNG/Manifest und empfiehlt als naechsten Schritt nur belegten Polish aus der Evidence.

## Betroffene Dateien
- `scripts/tests/task_574_fire_rule_real_f6_screenshot_review_pass.gd`
- `docs/tasks/TASK_574_fire_rule_real_f6_screenshot_review_pass.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Lokale Pruefung
- `godot_console.exe --path . --script scripts/tests/task_574_fire_rule_real_f6_screenshot_review_pass.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_573_fire_rule_manual_screenshot_notes_pass.gd`
- `git diff --check`

## Risiken / offene Punkte
- Der Capture kann automatisch belegen, dass ein echter Viewport-Readback existiert und der Zustand nicht leer ist. Er ersetzt weiterhin keinen User-Playtest zur Frage, ob sich die ROE-Bedienung gut anfuehlt.
- Ein moeglicher TASK_575 sollte nur konkrete Findings aus Screenshot/Manifest/Workbench-Export anwenden.
