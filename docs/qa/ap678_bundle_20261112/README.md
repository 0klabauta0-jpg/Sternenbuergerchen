# AP6–AP8: begrenzter Integrationsabschluss

Die vier erforderlichen kleinen Fälle sind bestanden. Originalberichte und vollständige Logs liegen unverändert in `evidence.zip`, Zuordnung und Hashes in `results.json`.

| Fall | Ergebnis | Tatsächlicher Stand |
| --- | --- | --- |
| RuntimeSelection / Actor / Registry / Leader | 16/0 | 33d0d2350 |
| Baseaktionscheckpoint V2 | 30/0 | 33d0d2350 |
| 12-Felder-Ablauf mit Rootcheckpoint und Host/Receiver | 38/0 | 33d0d2350 |
| Echter Campaign-Save/Continue | 17/0 positiv + 3/0 Legacy-Reject | c73a2ba03 |

Alle Kindprozesse Exit0, vollständige Logs ohne Enginefehler/Leaks; Quell-, Originalprofil- und private Canaryguards sind grün. Der erste Wrapperbericht bleibt historisch `partial_pending`, weil damals die zusätzliche Storeprobe fehlte. Ihr danach tatsächlich bestandener Bericht schließt diese Lücke. Nach dem Dreierlauf wurden nur CampaignStart/Store-Produktpfade geändert; diese prüft der anschließende neue Ownerfall. Es wurde kein einzelner gemeinsamer Lauf am späteren Commit erfunden und keine unnötige unveränderte Testmatrix wiederholt.

Die Kampagnenprobe verwendet echte Flow/Start/Store/Screen/Adapter/Base/Root-Owner. Unterdrückt sind nur unbenutzte UI-Start-/Renderloops. Der Pilot läuft tatsächlich zum Pad und steigt ein; Save und frisches Continue erhalten ihn bereits vor dem ersten Basissignal verborgen und ohne Groundpräsenz. Tick, exakter RNGstring, Baseaktionen und Ground werden in der tatsächlichen persistierten JSONdomain verglichen. Autosave begrenzt Export/Hash/Schreiben, während der tatsächliche Roottick weiterläuft; expliziter Save umgeht nur den Takt.

Nur die private positive Kopie der echten384x392/16x8-Basisnavigation erhält `tactical_grid_rules`; im zweiten Prozess müssen exakte Originalbytes denselben Hexsave vor Flowwrites ablehnen. Originalkarte und Spielerprofil bleiben unverändert. Dies ist kein Save-Aktivator.

AP8 verbindet auf zwölf Feldern Bewegung/Rampe/Tür/Sicht/Facing/Schussprüfung/Ankunft, Rootrestore sowie tatsächliche Sender und Empfänger. Nur der Netzwerktransport ist kontrolliert (`MultiplayerAPIExtension`); keine echten Peers, kein LAN-/Downloadnachweis, keine native Darstellung oder Leistungsaussage. Große A/B/C-Karten und AP9 bleiben im bisherigen Modus. Live-Sternkatalog V2 und ausgeschalteter lokaler Warpautomatismus bleiben erhalten.

Historische Fehlversuche wurden nicht als bestanden gewertet: veraltete Leaderfixture, tatsächlicher RefCounted-Teardownfehler, fehlende reine Fixture-UIunterdrückung, tatsächliche Packed-Member-Eingangsabweichung, Cooldownbeginn vor erstem Export sowie roher Float32/JSON-Vergleich. Die eindeutigen Korrekturen sind in den Tasks und Gitcommits festgehalten; spätere grüne Berichte ersetzen diese nicht rückwirkend.

## Wiederholung bei einem neuen konkreten Anlass

`python scripts/tests/run_ap678_bundle.py` zeigt nur den Plan; `--execute` startet die vier Fälle seriell, `--extended` zusätzlich ältere Nachbarn. Die Referenz für diese Abnahme sind die archivierten tatsächlich ausgeführten Einzelberichte, nicht ein erneuter Lauf des nun um Continue ergänzten Manifests. Der Base-Spezialrunner liegt als vorhandenes lokales QA-Artefakt unter `output/native_glut_maps/base_action_checkpoint_v2_20261112/run.py`; die übrigen Runner sind getrackt. Fehlende Artefakte werden klar abgewiesen.

Keine Mainintegration oder EXE. Vor jedem Export ist die ausdrückliche Nutzerfreigabe erforderlich.
