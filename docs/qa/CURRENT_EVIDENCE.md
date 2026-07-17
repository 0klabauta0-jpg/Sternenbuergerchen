# Aktuelle Evidenz

Diese Seite übersetzt das maschinenlesbare [Evidence-Manifest](../../data/project_evidence_manifest.json) in eine kurze menschliche Prüfungssicht. Sie ergänzt den kanonischen Spielstand, ersetzt ihn aber nicht.

## Leseregel

Jeder aktuelle Claim braucht einen Evidence-Record mit Commit, Laufdatum, Typ, Ergebnis, Artefakt, owning paths und Caveat. Historische grüne Verifier bleiben wertvoll, werden ohne frischen Record aber nicht zu einer aktuellen Release-Freigabe.

## Baseline am 17. Juli 2026

| Record | Aussage | Einschränkung |
| --- | --- | --- |
| `task_1179_historical_grid_sweep_18_of_18` | Zwei historische 18/18-Runs decken Homebase bis Debrief auf `grid_sweep` ab. | Der isolierte spätere Rerun endete vor Objective/Debrief; kein frischer Vollnachweis. |
| `task_1180_recovered_candidate` | Ein hashgesicherter Kandidat für einen First-Contact-/Live-Fire-Trace; Quelle und SHA-256 stehen im versionierten Recovery-Manifest. | Nicht integriert, nicht im aktiven Checkout und deshalb keine Evidenz oder aktueller Produktclaim. |
| `task_1181_snapshot_workbench` | Datierte HTML-Workbench dokumentiert damalige Einordnung und lokale Bedienprüfung. | Unveränderlicher Snapshot, kein Build- oder Gameplay-Beweis. |
| `n001_documentation_baseline` | Canonical-Truth- und Manifest-Vertrag werden auf dem N001-Ausgangscommit verankert. | Dokumentationsbeweis, kein Runtime- oder Release-Test. |

## Offene Evidenzgates

- N002: saubere Import-/Start-Evidenz und zwei echte TASK-1179-Ergebnisse.
- N003: sichtbare Command-Producer mit Plan-dann-GO- und Host/Client-Parität.
- N004: öffentliche Missionsszene sowie zweimal frisch integrierter TASK-1180-Trace.
- N007: ein frischer, deeplink-freier First-Ten-Minutes-Release-Gate.

Die vollständigen Feldwerte und Pfade stehen bewusst im JSON-Manifest, damit diese Übersicht kurz und überprüfbar bleibt.
