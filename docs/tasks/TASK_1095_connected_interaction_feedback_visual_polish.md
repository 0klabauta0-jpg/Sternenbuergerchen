# TASK_1095 - Connected Interaction Feedback Visual Polish

## Ziel / Problem
Der Client-GO-Handoff funktioniert, zeigt aber technische Interaction-IDs und rohe Reject-Codes. Das ist korrekt, aber nicht angenehm lesbar.

## Umfang
- Stabile Tokens: AA, DOOR, COM, CARGO.
- Kurze Primaerzeilen fuer Pending, Accepted und Blocked.
- Verstaendliche deutsche Reject-Texte und separate Detailzeile.
- Tone-Metadaten fuer ruhige visuelle Differenzierung.

## Akzeptanzkriterien
- Keine rohe Interaction-ID in der sichtbaren Kompaktzeile.
- Pending, Success und Blocked sind auf einen Blick unterscheidbar.
- Falsches Team und fehlende Fireteam-Zuweisung sind menschlich lesbar.
- Netzwerk-/Gameplay-Wahrheit bleibt unveraendert.

## Risiken / offene Punkte
Ein echter Zwei-Fenster-Screenshot bleibt fuer Abstand, Farbe und HUD-Overlap sinnvoll.

## Ergebnis
- 8/8: AA, DOOR, COM und CARGO besitzen stabile kurze Tokens.
- Pending, Success und Blocked liefern kompakte Zeile, Detailtext und Tone.
- Rohe Interaction-IDs und Reject-Codes verschwinden aus der sichtbaren Zeile.
- TASK_1094 bleibt 6/6 gruen.
- Naechster Schritt: TASK_1096 - Connected Interaction Feedback Runtime Progress Surface fuer replizierten Hold-Fortschritt in beiden Fenstern.
