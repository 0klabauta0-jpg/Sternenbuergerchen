# TASK_1127 - Tactical Communication HUD Bubble Event and Mini-Card Anchor Repair

## Status: IMPLEMENTIERT

## Ziel / Problem
TASK_274 erzeugt Tactical-Communication-Events, Eventlogtexte und 3D-Kartenmarker, kann aber keine aktuelle FTL-Bubble einer bekannten Event-ID und der linken Fireteam-Mini-Card zuordnen.

## Sinnhaftigkeit / Ursache
Der Tactical-Communication-Resolver schreibt `tactical_communication_event_id` korrekt. Der Controller speichert danach jedoch global nur die zuletzt eingegangene Bubble. Bei zwei Fireteams und mehreren Feedbackquellen kann eine eventgebundene Bubble durch spaeteres Command-Feedback ersetzt werden, bevor Snapshot und Primary3D sie lesen.

## Umfang
- Zwei-Fireteam-Fixture verfolgt Event-ID, gespeicherte Bubble und gerenderten HUD-Anker.
- Bubble-Speicher behaelt pro Fireteam die relevante aktuelle Bubble statt global nur eine.
- Tactical-Communication-Bubbles bleiben an bekannte Events gebunden.
- HUD-Anker wird aus der existierenden Fireteam-Mini-Card abgeleitet.
- Cooldown, Dauer, globale und pro-Unit-Limits bleiben wirksam.

## Nicht-Ziele
- Kein neues Bubble-System oder Layout-Rewrite.
- Keine Gameplay-, Event-, Mission- oder Multiplayer-Wahrheit im HUD.
- Keine unbegrenzte Bubble-Historie.
- Keine Aenderung der Tactical-Communication-Texte.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_1126_connected_first_contact_local_marker_label_hierarchy.md`
- `docs/dev/tactical_communication_feedback_layer_design.md`
- `docs/ARCHITECTURE.md`

## Akzeptanzkriterien
- Mindestens eine aktuelle FTL-Bubble referenziert eine existierende Tactical-Communication-Event-ID.
- Eventgebundene Bubble besitzt `anchor_space = hud` und `hud_anchor_source = fireteam_mini_card`.
- Zwei Fireteams koennen gleichzeitig je eine aktuelle Bubble behalten.
- Bubble-Anzahl bleibt durch bestehende Settings begrenzt.
- TASK_274 wird vollstaendig gruen.
- Multiplayer- und Performance-Gates bleiben gruen.

## Betroffene Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_1127_tactical_communication_hud_bubble_event_mini_card_anchor_repair.gd`
- gegebenenfalls bestehender Bubble-Resolver/Visualpfad nach Diagnose
- Status-, Roadmap- und HTML-Berichtsdokumentation

## Lokale Pruefung
- TASK_1127 RED/GREEN.
- TASK_274.
- TASK_1126, TASK_1119, TASK_1104 und TASK_222.
- `git diff --check`.

## Risiken / offene Punkte
Mehr als eine Bubble darf nicht zu HUD-Laerm fuehren. Der Speicher bleibt pro Fireteam dedupliziert und respektiert das bestehende Gesamtlimit. Eventgebundene Bubbles bleiben mindestens zwoelf Prozessframes sichtbar, damit schwere Renderframes ihre komplette Anzeigezeit nicht aufzehren.

Der alte TASK_214-Smoke steht unabhaengig von diesem Fix bei 32/36: Er erwartet noch `comms_lines` statt des inzwischen produktiven `command_context`, unterstellt im Minimalmodus keinen bestehenden Command-Context-Ersatzpfad und rendert NPC-Thoughts ohne aktiven Hold-Zustand. Diese drei veralteten Annahmen werden nicht in TASK_1127 umdefiniert.

## Ergebnis
- Tactical Events binden ihre Event-ID an die bereits aktive Command-Bubble desselben Fireteams, ohne deren Text- und Modusvertrag zu ersetzen.
- BLUE und GOLD behalten gleichzeitig jeweils eine deduplizierte aktuelle Bubble.
- HUD- und World-Render-Snapshots transportieren die Tactical-Communication-Event-ID weiter.
- Explizite Test-Prunes bleiben deterministisch; Runtime-Prunes respektieren die Mindestzahl sichtbarer Frames.
- TASK_274 ist wieder vollstaendig 76/76 gruen.

## Lokale Pruefergebnisse
- TASK_1127: 5/5.
- TASK_274: 76/76.
- TASK_431: 19/19.
- TASK_219: 48/48.
- TASK_1126: 13/13.
- TASK_1119: 33/33.
- TASK_1104: 31/31.
- TASK_222: 82/82.
- `git diff --check` ohne Befund.
