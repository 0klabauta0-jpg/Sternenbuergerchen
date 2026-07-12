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

## Ergebnis
- Status: implementiert und im exportierten Host-/Client-First-Contact-Release sichtbar verifiziert.
- ContactTracker-`lost` erscheint als `1 KONTAKT WEG` beziehungsweise `n KONTAKTE WEG`; bestaetigte, gesichtete und vermutete Kontakte nennen ebenfalls explizit den Kontaktbereich.
- Lange Movement-Readouts wie `BND 1/18 ... move ... cover` werden in der Mini-Card auf den Stilcode gekuerzt. Die vollstaendige Formation-/Stage-Diagnose bleibt im Tooltip und Snapshot erhalten.
- Host zeigt im finalen Capture `BND | 1 KONTAKT WEG | FIT 5/5`; Client zeigt `MARSCHIERT | 1 KONTAKT WEG | FIT 5/5`. Beide Zeilen passen vollstaendig in die Karte.

## Abschlusspruefung
- TASK_1154: 10/10.
- TASK_1132: 15/15.
- TASK_1109: 18/18; TASK_1110: 20/20.
- TASK_1150: 18/18; exportierter Zwei-EXE-Lauf `pass`.
- TASK_222: 82/82.
- TASK_188 meldet in seinem historischen Fixture weiterhin 24 bestandene und 13 fehlgeschlagene Assertions, beendet den Prozess aber faelschlich mit Exit 0. Der Fehler reproduziert isoliert und liegt ausserhalb des geaenderten Formatierpfads; ein separater Testvertrauens-Task ist sinnvoll.

## Naechster sichtbarer Befund
Nach Deboard und Abflug bleiben rechts zwei grosse, weitgehend leere Dropship-Karten sichtbar und verdecken Kartenflaeche. Als naechster Spielbarkeits-Task sollten abgeschlossene leere Transportsurfaces kompakt in einen Verlauf zusammenfallen, waehrend aktive/beladene Dropships unveraendert voll bedienbar bleiben.
