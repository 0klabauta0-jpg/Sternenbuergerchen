# Drei Performance-/Architekturrunden, 2026-11-03

Basis: aktueller Main `8eaeadd27e`. Drei aufeinanderfolgende Review-/Fix-/Retest-
Runden mit getrennten Commits und unabhaengigen Nachreviews. Fuenf bestaetigte
Befunde behoben; keine pauschalen Refactors oder neuen Gameplay-Systeme.

| Runde | Bestaetigter Fehler und Ergebnis | Neue Regression |
| --- | --- | ---: |
| 1 | P1: behauptete Fireteam-ID ueberstimmte bekannte Unit-Zuordnung; Runtime-Rechte und konsistente Hinweise jetzt zwingend | 22/22 |
| 2 | P2: Decision-Throttle verlaengerte Cooldowns um Faktor drei; Ablauf wieder pro Simulationstick, Decision-Kadenz erhalten | 19/19 |
| 3 | P2: kleines Area-Rechteck projizierte alle Tiles; begrenzte Kandidaten bei unveraenderter exakter Auswahl und Quellreihenfolge | 18/18 |
| 3 | P2: Map-Rebuild loeschte Heatmap-Meshes trotz gueltigem Cache; abgeleiteten Layer wiederherstellen | 22/22 |
| 3 | P2: zu fruehes Sichtbarschalten zeigte alte FoW-Zellen waehrend des Throttles; erst aktuelle sichere Zellen freigeben | 20/20 |

Alle fuenf zuerst korrekt RED. Slice-Gates: Runde 1 effektiv 7/7 mit 151
Assertions, Runde 2 6/6 mit 191, Runde 3 12/12 mit 301. Diese ueberlappenden
Teilmengen werden nicht zusaetzlich in die Abschlusszahl eingerechnet.

## Gemeinsamer gepruefter Stand

Auf `75f2e6ef399c5b27f92202650aea7ede0cdf45a3` bestehen **69/69 strenge Gates
und 1990/1990 numerische Assertions** in einem vollstaendigen sequenziellen Lauf.
Darin 101 Assertions der fuenf neuen Regressionen und ein Canary ohne numerische
Assertions. Exitcodes 0, Erfolgsmarker vorhanden, keine Engine-/Scriptfehler oder
Leakwarnungen. Unabhaengige Gesamt- und Fixture-Nachreviews APPROVED.

Rohreport: `final_verified_suite/20261102T235303Z-b661a934/report.json`.
Maschinenlesbarer Gesamtindex: `verification_summary.json`; Sourcefingerprints
und Testcommit: `final_source_snapshot.json`.

Die anschliessende Main-Uebernahme verwendet denselben geprueften Code per
Fast-forward; auf Main werden die fuenf neuen Regressionen und der Canary erneut
isoliert ausgefuehrt. Nach den Tests nur Doku-/Evidence-Commits.

## Messung und Grenzen

Kleine Area-Auswahl auf 128x128/256x256: 16384/65536 -> jeweils 25 projizierte
Tilezentren; 32769/131073 -> je 51 Tile-Positionslesungen. Square/Hex, H0-H2,
vier Kamera-Yaws, exakte Grenzen, Hoehenedit und Quellreihenfolge mit eingefrorenem
exhaustivem Oracle verglichen. Grosse/degenerierte Auswahlen behalten Fallbacks.
Keine Gesamt-FPS-, GPU- oder Release-Abnahme. Streaming-Komplettrebuilds bleiben
ein gesonderter Profiling-Kandidat.

## Nutzerdaten und erhaltene Historik

Jeder Lauf nutzt vor Prozessstart einen eindeutigen Appnamen, eine eigene
Projektdatei und frische Nutzerdaten. Erster Autoload prueft den Pfad synchron.
Originalroster vor/nach jedem Lauf: SHA256, 221426 Bytes und Schreibzeit gleich.
Die private Sicherheitskopie bleibt ausserhalb des Repos und wurde nie restauriert.

Der erste gemeinsame Lauf war 68/69: TASK570 hatte bereits auf Originalsource
30/4, weil sein Queue-Fake direkte Unit-Mutation erwartete. Reale Authority-
Fixture behaelt alle Erwartungen, prueft zusaetzlich Vor-Tick-Grenze und Bewegung:
54/54 auch auf Originalsource. TASK377 war mit alter Refresh-Fixture original
20/3; nach normalem Refresh zum oeffentlichen Intervall 23/23 auch auf Originalview.
Keine Produktionskorrektur fuer diese Testfixturefehler. Urspruengliche Reports,
REDs, Typ-/Timer-Fixturefehler und Source-Baselinevergleiche bleiben erhalten.
Der bekannte TASK348-Baselinebericht bleibt separat; dies ist keine gesamte
Projekt- oder Release-Freigabe.

```powershell
python scripts/tests/run_review2_isolated.py --manifest scripts/tests/review_cycles_20261103_checks.json --baseline output/review_cycles_20261103/roster_baseline.json --output output/review_cycles_20261103/repeat
```
