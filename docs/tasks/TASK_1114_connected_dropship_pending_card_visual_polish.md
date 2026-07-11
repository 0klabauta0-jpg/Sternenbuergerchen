# TASK_1114 - Connected Dropship Pending Card Visual Polish

## Status: IMPLEMENTIERT IM ARBEITSSTAND

## Ziel / Problem
Der per-Craft Pending-Guard aus TASK_1113 funktioniert, aber die Kartenzeile nutzt noch keine stabile visuelle Tonalitaet. Nach Reject, Timeout oder erfolgreichem Snapshot verschwindet die Craft-bezogene Rueckmeldung zu schnell beziehungsweise bleibt nur in der globalen Command-Zeile.

## Sinnhaftigkeit / Ursache
Multiplayer-Feedback muss dort lesbar sein, wo der Spieler geklickt hat. Die bestehende Kartenzeile kann dafuer die bereits vorhandenen Theme-Tones verwenden, ohne neue Gameplay-Wahrheit oder weitere UI-Flaechen einzufuehren.

## Umfang
- Pending-Zeile pro Craft in Warning/Gelb.
- Snapshot-bestaetigtes Host-OK pro Craft kurz in Success/Gruen.
- Reject und Timeout pro Craft in Danger/Rot.
- Tone, Text und Farbe im read-only Card-UI-Snapshot exponieren.
- Feedback zeitlich begrenzen, ohne per-frame HUD-Rebuild.
- BLUE-Pending darf GOLD visuell und funktional nicht sperren.

## Nicht-Ziele
- Kein neues Transport-, Command- oder Snapshotmodell.
- Kein Spinner, Popup oder Karten-Redesign.
- Keine Aenderung an Host-Authority oder Command-Validierung.

## Akzeptanzkriterien
- Pending, Success und Blocked/Timeout sind farblich und textlich unterscheidbar.
- Result-Feedback bleibt auf der betroffenen Craft-Karte sichtbar.
- Nur der betroffene Craft zeigt Pending und deaktivierte Actions.
- Feedback-Ablauf erzeugt genau einen UI-Refresh, nicht einen pro Frame.
- Ein gerenderter Full-HD-Screenshot zeigt lesbare Karten ohne Overlap.

## Betroffene Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_1114_connected_dropship_pending_card_visual_polish.gd`
- Status, Roadmap und HTML-Arbeitsbericht

## Lokale Pruefung
- TASK_1114 Visual-Verifier und Screenshot
- TASK_1113 Pending-/Double-Submit-Guard
- TASK_1112 Parallel Lifecycle
- TASK_399 Dropship-Hotpath
- `git diff --check`

## Risiken / offene Punkte
Feedback ist bewusst kurzlebig und read-only. Es darf nicht als bestaetigter Transportstate gelesen oder in Snapshots repliziert werden.

## Ergebnis
- Pending nutzt die vorhandene Warning-Farbe, Snapshot-Erfolg Success und Reject/Timeout Danger.
- Result-Feedback bleibt drei Sekunden auf genau der betroffenen Craft-Karte und laeuft ohne per-frame HUD-Rebuild ab.
- Der Card-UI-Snapshot exponiert Text, Tone, Style-Key und Farbe rein lesend.
- TASK_1114 besteht headless 13/13 und im echten D3D12-Full-HD-Fenster 15/15; der Screenshot zeigt getrennte BLUE-/GOLD-Karten ohne Overlap.
- TASK_1113 16/16, TASK_1112 13/13 und TASK_399 9/9 bleiben gruen.
