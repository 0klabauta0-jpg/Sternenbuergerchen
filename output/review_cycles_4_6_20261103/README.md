# Drei weitere Performance-/Architekturrunden, 2026-11-03

Basis: aktueller Main `21bacf0f2`. Drei aufeinanderfolgende Review-/Fix-/Nachreview-
Runden abgeschlossen, vier bestaetigte Probleme minimal korrigiert. Unabhaengige
Slice- und frische Gesamt-Code-Reviews APPROVED.

| Runde | Problem / Ursache / Korrektur | Neue Regression |
| --- | --- | ---: |
| 1 | P2: Roster-Validator verwendete Basisgrenze nach Traits; gueltige effektive Skills bleiben jetzt im Runtime-Vertrag 0..1 speicherbar, ohne Clamping oder Balancingaenderung | 34/34 |
| 1 | P1: Reset ueberschrieb trotz fehlgeschlagenem Pflichtarchiv; Store und echter MainMenu-Button erhalten Save, Anzeige, Editor, Fehlermeldung und Resetgeneration bis zum Erfolg | 65/65 |
| 2 | P2: HPA-Cache-Hits materialisierten alle Tiles fuer deren Anzahl; direkter Registry-Zaehler bei gleichem Cache-/Rebuild-/Legacy-Verhalten | 38/38 |
| 3 | P2: unvollstaendiger Waffen-/Vital-Cache unterdrueckte Badge-Updates; eigene abgeleitete Anzeige-Signatur aktualisiert Label und Redraw bei Kontakt/Status/Timer/Declutter/Sichtwechsel | 36/36 |

Alle vier zuerst korrekt RED, danach GREEN. Der Reset-Consumer wurde im
unabhaengigen Nachreview bis zum echten verbundenen Button verfolgt und durch
zusaetzliches RED/GREEN abgesichert. Keine Tests fuer Produktfixes abgeschwaecht.

## Gemeinsamer Quellstand und Tests

Commit `48f96221b807fb2971207f3ec9133b91a0f785a2`: **85 strenge Gates,
84 PASS, 1 bestaetigter unveraenderter Baselinefehler**. Die 84 gruenen Gates
enthalten **2747/2747 Assertions**, darunter alle **173/173** der vier neuen
Regressionen. Einschliesslich TASK839 sind es 2776 bestandene und 2 fehlgeschlagene
Assertions. Kein allgemeiner All-green- oder Release-Status.

TASK839 liefert 29/2: Meta-/Tactical-Gesamtgate scheitert an
`source_findings_polish_passes` aus TASK838. Ein isolierter Vergleich mit den
Original-Main-Bytes aller sechs Produktdateien liefert exakt dasselbe 29/2 und
dieselben Fehlerlabels; Rohlogs ausser dem Userdata-Pfad identisch. Direkte
Primary3D-Declutter-Pruefungen bestehen. TASK839 bleibt unveraendert in der
Abschlussmatrix; eine tiefere Ursache ist hier nicht geklaert. Der schon frueher
bekannte TASK348-Baselinefehler bleibt separat und wurde hier nicht erneut getestet.

Rohreport: `final_suite/20261103T044414Z-5b8b1e6c/report.json`.
Index: `verification_summary.json`; 95 Source-/Test-/Harness-/Projektfingerprints
in `final_source_snapshot.json`, alle identisch mit Testcommit und Arbeitsdateien.
Nach dem Gesamtlauf werden nur Dokumentation und Evidence ergaenzt.

## Performance und Grenzen

Acht warme HPA-Abfragen auf 128x128/256x256: **131072/524288 materialisierte
Tile-Referenzen -> 0/0**, bei identischem 17-Zellen-Pfad und Graphidentitaet.
Runtime-Tuer, Revision, Kartenwechsel, Leerzustand und Legacy-Fallback geprueft.

Reine Badge-Aenderungen verursachen keine erneute Aim-/Skeleton-/Vitalarbeit
oder Proxy-/Label-Neubauten. Sie erfordern aber zusaetzliche lesende Badge-
Pruefungen pro Sync. TASK1188, je 28 Units / 8696 Frames / rund 60 Sekunden:
p99 **3370 -> 4904 us** (+45.5%), beide unter dem bestehenden **8000-us-Budget**.
Das ist gemessener Mehraufwand; ein einzelnes Paar isoliert weder Ursache noch
Streuung. Der spaetere gemeinsame Lauf erreicht **4346 us** und 31/31 Assertions;
er ersetzt das erste Vergleichspaar nicht. Maschine: Ryzen 7 7800X3D,
Godot 4.6.2 official `71f334935`, headless. Keine native Bild-, FPS- oder GPU-Abnahme.

## Nutzerdaten, Historie und betroffene Dateien

Bis zum gemeinsamen Lauf **129 protokollierte Checklaeufe mit 129 frischen,
eindeutigen Userdata-Verzeichnissen**. Separater Appname/Projektkonfiguration,
erster synchroner Pfadguard und Canary. Originalroster vor/nach jedem Kind:
SHA256, 221426 Bytes und Nanosekunden-Schreibzeit unveraendert. Private
Sicherheitskopie ausserhalb des Repos, nie restauriert oder committed.

Produktdateien: `scripts/meta/start_roster_generator.gd`,
`scripts/meta/player_roster_store.gd`, `scripts/ui/main_menu_screen.gd`,
`scripts/core/simulation_root.gd`, `scripts/terrain/terrain_registry.gd`,
`scripts/terrain/terrain_map_3d_view.gd`. Vier neue Verifier und Manifest unter
`scripts/tests/review46_20261103_*`; owning Contracts, TASK1188 und dieser Task
aktualisiert. Vorhandene ungetrackte Assets und andere Arbeiten unangetastet.

Rohhistorie bleibt erhalten: erste Windows-Archiv-Diagnoseannahme korrigiert;
keinen problematischen Generator-Seed ausgetauscht, stattdessen echten Skill-
Domainfehler separat bewiesen; Badge-Fixture auf erkannte feste Postur gebracht;
erfolgreiches Button-Retry-Archiv am echten Store statt ueberschriebener
Last-Store-UI-Metadaten geprueft. Keine Produktkorrektur fuer reine Fixtureannahmen.

```powershell
python scripts/tests/run_review2_isolated.py --manifest scripts/tests/review46_20261103_checks.json --baseline output/review_cycles_4_6_20261103/roster_baseline.json --output output/review_cycles_4_6_20261103/repeat
python output/review_cycles_4_6_20261103/summarize_evidence.py
```

## Main-Abschluss

Main-Fast-forward, anschliessender isolierter Smoke und Push folgen nach der
abschliessenden Evidence-Gegenpruefung. Der bekannte TASK839-Altfehler wird
ausdruecklich mitgegeben.
