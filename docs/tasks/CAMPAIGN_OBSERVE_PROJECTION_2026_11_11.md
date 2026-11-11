# Kampagnenbeobachtung ohne unbenötigte UI-Projektion

## Ziel / Ursache
Bekannte native observe_campaign_progress-Spitzen6–11ms während des
B-Gefechts. Der getaktete Beobachter baut auch fern der Basis eine vollständige
Operations-UI-Projektion, berechnet unbenutzten Service-/Abflugkontext und
liest mehrere vollständige Kampagnensnapshots für dieselben Fortschrittswerte.

## Umfang / Nicht-Ziele
Ein frischer lokaler Fortschrittssnapshot nach unveränderter Chip-Recovery.
Jobstatuswerte derselben Projektion verwenden. Readiness nur lesen, wenn
base_ready überhaupt wahr sein kann: tatsächlich zuhause und erster Auftrag
accepted. Kein persistenter Cache, kein Throttle, keine Verzögerung von
Fortschritt, keine Veränderung an Ownern/Commands/Kampagnenregeln.
Keine UI-/Karten-/Rüstungsänderung in diesem Task.

## Verträge / Quellen
ARCHITECTURE, campaign_onboarding_state, singleplayer_campaign_state,
SingleplayerRuntimeAdapter, docs/qa/combat_frame_accounting_20261111 und
zugehöriger COMBAT_FRAME_ACCOUNTING_2026_11_11-Task. Die UI-Projektion ist
laut bestehendem get_operations_snapshot-Vertrag lesend.

## Akzeptanz / Prüfung
Frische Änderungen werden beim nächsten Observe sofort erfasst.
Identische Observe-Evidence für zuhause/unterwegs/alle Jobstatuswerte,
physisches Boarding und Pilotbereitschaft bleiben Voraussetzung.
Im Gefecht/bei Transit/bei abgeschlossenem Satellitenauftrag kein kompletter
Operationssnapshot und kein unbenutzter Servicekontext. Außerhalb Kampagne
keine Arbeit. Chip-Recovery läuft weiterhin vor Fortschrittslesung.
Gezielter RED/GREEN-Verifier zählt reale Projektionsaufrufe und prüft alle
Evidence-Felder. Bestehende Kampagnen-/Chip-/Boardingregressionen passend
wiederholen. CPU-Messwerte unter Parallelität nur Diagnose; belastbarer
nativer Vorher/Nachher-Lauf erst nach exklusiver CPU/GPU-Freigabe.

## Dateien / Risiken
scripts/meta/singleplayer_runtime_adapter.gd; neuer gezielter Verifier;
eigene QA/Status. Risiko: die physische Basisbereitschaft nicht mit bloßer
UI-Zuweisung verwechseln und keine stale Fortschrittskopie über Calls halten.
Keine Mainintegration/EXE oder breite FPS-Abnahme.
