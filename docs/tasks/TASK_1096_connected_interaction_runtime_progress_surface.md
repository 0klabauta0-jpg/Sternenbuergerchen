# TASK_1096 - Connected Interaction Runtime Progress Surface

## Ziel / Problem
Host-Pending und Host-OK sind lesbar, aber replizierter Hold-Fortschritt erscheint noch nicht als ruhige gemeinsame Host-/Client-Zeile.

## Umfang
- Progress aus `mission_interactions` read-only darstellen.
- COM/DOOR als Prozent plus Sekunden, Hold-Zones als `HALTEN`.
- Complete als `<TOKEN> FERTIG`.
- Fingerprint verhindert identische Label-Updates und komplette HUD-Rebuilds.

## Akzeptanzkriterien
- Replizierter Progress erzeugt eine kurze Zeile.
- Identischer Snapshot erzeugt kein zweites Update.
- Neuer Prozent-/Sekunden-Bucket aktualisiert genau die Command-Feedback-Zeile.
- Kein Command und keine Gameplay-Wahrheit entstehen.

## Risiken / offene Punkte
Ein sichtbarer Zwei-Fensterlauf bleibt fuer Farbe, Abstand und Ueberlagerung sinnvoll.

## Ergebnis
- 10/10: COM-Prozent, Cargo-Hold und Complete-Zeilen sind kompakt und read-only.
- Laufende Interactions haben Vorrang vor frueheren abgeschlossenen Route-States.
- Identische Snapshots erzeugen kein weiteres Label-Update.
- Der Command-Feedback-Label wird per Textdelta statt vollem HUD-Rebuild aktualisiert.
- Naechster Schritt: TASK_1097 - Connected Interaction Feedback Two-Window Visual Evidence.
