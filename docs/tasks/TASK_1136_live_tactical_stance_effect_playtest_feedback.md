# TASK_1136 - Live Tactical Stance Effect Playtest and Feedback

## Ziel / Problem
Die Haltungssteuerung ist nach TASK_1134 lesbar und ihre Runtime-Doctrine nach TASK_1135 eindeutig. Im laufenden Spiel bestaetigt die zentrale Befehlszeile einen Wechsel jedoch noch als technisches `STANCE C LIVE (1)`. Der Spieler erkennt dort weder den ausgeschriebenen Modus noch dessen unmittelbare Wirkung.

## Ursache / Sinnhaftigkeit
Runtime-State, Posture, Speed und Sicht werden korrekt aktualisiert, aber der sichtbare Abschluss des Bediengriffs stammt noch aus dem alten Diagnosepfad. Gerade ein Live-Wechsel muss sofort erklaeren, was das Fireteam nun anders macht.

## Umfang
- Kompaktes, spielsprachliches Feedback fuer vorsichtig, normal und offensiv.
- Live-Wechsel benennt Modus, Tempo, Sicht und Waffenhaltung.
- Feedback wird aus dem bestehenden globalen Stance-Profil abgeleitet und setzt keine zweite Gameplay-Wahrheit.
- Reale Drill-Szene prueft vorsichtigen und offensiven Wechsel waehrend aktiver Bewegung.
- Full-HD-Captures dokumentieren beide sichtbaren Zustande.

## Nicht-Ziele
- Keine Aenderung der TASK_451-/TASK_429-Balancewerte.
- Keine Aenderung an Movement, Fog-of-War, Combat, Commands, RPCs oder Snapshots.
- Kein neues Tutorialfenster und kein dauerhafter weiterer HUD-Block.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_1134_selected_fireteam_stance_control_consistency.md`
- `docs/tasks/TASK_1135_tactical_stance_doctrine_contract_reconciliation.md`
- `docs/dev/fireteam_behavior_modes_contract.md`
- `docs/dev/mission_command_feedback_contract.md`

## Akzeptanzkriterien
- VORS bestaetigt `VORSICHTIG LIVE`, langsames Tempo, volle Sicht und Waffe im Anschlag.
- NORM bestaetigt `NORMAL`, zuegiges Tempo, reduzierte Sicht und gesenkte Waffe.
- OFF bestaetigt `OFFENSIV LIVE`, schnelles Tempo, kurze Sicht und gesenkte Waffe.
- Die reale CommandFeedbackLabel zeigt das Feedback nach dem Klick.
- Runtime-Status zeigt gleichzeitig die erwarteten relativen Speed-/Sicht-/Posture-Unterschiede.
- Full-HD-Captures bleiben innerhalb der HUD-Grenzen und sind ohne Testoverlay lesbar.

## Betroffene Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_1136_live_tactical_stance_effect_playtest_feedback.gd`
- `docs/dev/mission_command_feedback_contract.md`
- Status, Roadmap und HTML-Arbeitsbericht

## Lokale Pruefung
- TASK_1136 headless und Real Window mit zwei PNG-Captures
- TASK_425, TASK_429, TASK_1134 und TASK_1135
- TASK_503, TASK_773 und TASK_222
- `git diff --check`

## Risiken / offene Punkte
Die CommandFeedbackLabel ist dicht. Das Feedback muss kurz bleiben und darf bestehende Combat-/Decision-Zeilen nicht verdraengen. Dauerhafte Detailwerte bleiben im Tooltip; die Klickbestaetigung beschreibt nur die unmittelbare Wirkung.
