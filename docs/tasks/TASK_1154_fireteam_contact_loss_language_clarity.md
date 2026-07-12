# TASK_1154 - Fireteam Contact Loss Language Clarity

## Ziel / Problem
Im exportierten First-Contact-Release zeigt die Fireteam-Mini-Card gleichzeitig `1 VERLOREN` und `FIT 5/5`. Technisch sind die Werte korrekt, spielerisch liest sich `VERLOREN` aber wie ein personeller Verlust statt wie ein abgerissener Feindkontakt.

## Ursache / Sinnhaftigkeit
Der ContactTracker liefert den Zustand `lost`; die Mini-Card uebersetzt ihn ohne Bezugswort als `VERLOREN`. Health und Contact sind getrennte Wahrheiten, werden in der kompakten Statuszeile aber direkt nebeneinander dargestellt.

## Umfang
- Kontaktstatus in der Mini-Card immer als Kontaktinformation kennzeichnen.
- `lost` kompakt und eindeutig von Verwundeten oder Ausfaellen unterscheiden.
- Singular und Plural fuer Kontaktzahlen lesbar halten.
- Technische Contact-/Health-Daten und Tooltips unveraendert lassen.
- Host- und Client-Perspektive verwenden dieselbe reine Formatierung.

## Nicht-Ziele
- Keine Aenderung an ContactTracker, Combat, Gesundheit oder Multiplayer-Snapshots.
- Kein Layoutumbau der Fireteam-Karte.
- Keine neue UI- oder Gameplay-Wahrheit.

## Akzeptanzkriterien
- `lost` erscheint als `1 KONTAKT WEG` beziehungsweise `n KONTAKTE WEG`.
- Bestaetigte, gesichtete und vermutete Kontakte nennen ebenfalls das Bezugswort.
- `FIT n/n` bleibt separat und unveraendert.
- Der sichtbare Kontakttext bleibt fuer die Mini-Card kompakt.
- TASK_1132, TASK_1109, TASK_1110 und First-Contact-/Performance-Gates bleiben gruen.

## Betroffene Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_1154_fireteam_contact_loss_language_clarity.gd`
- Status, Roadmap und HTML-Handbuch

## Lokale Pruefung
- TASK_1154 RED/GREEN.
- TASK_1132, TASK_1109, TASK_1110, TASK_1150 und TASK_222.
- Exportierter Host-/Client-First-Contact-Capture.
- `git diff --check`.

## Risiken / offene Punkte
Die Karte hat wenig Breite. Die Formulierungen bleiben deshalb bewusst kurz und werden mit Singular/Plural statt technischen Codes gebaut.
