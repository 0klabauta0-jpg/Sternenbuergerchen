# Review 2 - Fix- und Regressionsnachweis

Alle sieben Befunde auf Basis `a7e883f1f` behoben, P1 zuerst separat in
`13bcaf3fb`, Terrain in `c822b9376`, Runtime/Netzwerk in `287ab48f1`.
Unabhaengige Slice-, Gesamt- und Harness-Nachreviews: APPROVED ohne wichtige
offene Befunde. Dieser Fix-Abschluss erfolgte zunaechst ohne Main-Integration.
Die anschliessend separat beauftragte Main-Uebernahme ist unter
`output/review2_main_integration_20261102/README.md` dokumentiert: frischer
sequenzieller Main-Lauf 55/55 Gates und 1650/1650 Assertions ohne Retries.
Keine allgemeine Release-Abnahme.

| Neue Regression | Finale Assertions |
| --- | ---: |
| Aktive Mission hinter Homebase/FOB | 60/60 |
| Indizierter Hoehenlookup | 9/9 |
| Raeumliches Minimum-Spacing | 19/19 |
| Begrenztes Editor-Picking / Kameragesten | 50/50 |
| Mehrere Kontaktbeobachter | 22/22 |
| Faellige Kontakt-Relays | 28/28 |
| Jittertolerante Chunk-Reassembly / Ablauf | 14/14 |

Alle sieben zuerst RED; neue Tests zusammen 202/202. Die effektive Abschluss-
auswahl umfasst 55 unterschiedliche strenge Gates mit 1650/1650 numerischen
Assertions. Darin ist ein Canary-Gate ohne numerische Assertions enthalten.
Die Ergebnisse werden nicht durch mehrfaches Zaehlen von Wiederholungen erhoeht.

## Abschlusslaeufe und Grenzen

- `final_suite/20261102T211240Z-a27fe165/report.json`: 53/55. HUD 26/27 wegen
  fehlender Icon-Importmetadaten im isolierten Overlay; Terrain 33/33 Exit0,
  aber falscher Erfolgsmarker im neuen Manifest.
- `final_retries/20261102T211752Z-bb5c77cb/report.json`: HUD 27/27 nach Kopie
  benachbarter Importmetadaten, keine Assertions geaendert.
- `final_retries/20261102T211823Z-9fd5ee68/report.json`: Terrain 33/33 mit dem
  tatsaechlichen Marker `FRONTIER_HEX_RENDER`.
- TASK_348 bleibt separat baseline-identisch 14/17. Die drei gleichen Fehler
  sind im unveraenderten Basisstand reproduziert; Test nicht abgeschwaecht.
- TASK_510: echte besessene Index-/Readmodel-Fixture beseitigt die Leakwarnung
  des Standalone-Testaufbaus; alle 23 Assertions bleiben erhalten.
- Rohhistorik einschliesslich REDs, weiterer Picking-Grenz-/Idle-Ablauf-REDs,
  erster Canary-Timeouts und Leakwarnungen bleibt hier erhalten.
- Godot 4.6.2 headless. Operationszaehler und Zustandsregressionen sind keine
  nativen FPS-/GPU-Messungen und keine gesamte Release-Abnahme.

## Nutzerdaten

Jeder Runtime-Lauf startet mit eigener Projektdatei und eindeutigem Appnamen,
frischen Nutzerdaten und zuerst konstruiertem synchronem Pfadguard. Auch
`output` und `tmp` sind pro Overlay privat. Resource-Verzeichnisse und
Importcache werden geteilt. Der Originalroster bleibt in Bytes, Laenge und
Schreibzeit unveraendert; `project.godot` ebenfalls. Profilinhalt und private
Sicherheitskopie sind nicht Teil dieses Reports.

Der vollstaendige maschinenlesbare Index samt Originalreports, effektiver
Gate-Auswahl, Quellhashes, Rostervergleich und Operationen steht in
`verification_summary.json`. Das Manifest ist
`scripts/tests/review2_20261102_checks.json`.

```powershell
python scripts/tests/run_review2_isolated.py --manifest scripts/tests/review2_20261102_checks.json --output output/review2_fixes_20261102/repeat
```

Der Runner verweigert Laeufe, wenn der geschuetzte Roster vom aufgezeichneten
Ausgangsstand abweicht. Er stellt niemals automatisch ein Profil wieder her.
