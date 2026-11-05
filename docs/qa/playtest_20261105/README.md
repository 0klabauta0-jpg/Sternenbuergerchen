# QA-Paket: Vollbild-Spielpass 05.11.2026

**Main-Quellstand integriert und nativ nachgeprüft. Gestalterische Nutzerabnahme offen.**

Die Git-Fassung enthält ausgewählte unveränderte Rohbelege. Der [lesbare Bericht](../../reports/PLAYTEST_2026-11-05.md) ordnet Ergebnisse und Grenzen ein. Historische Aufnahmen belegen 3440×1440 zur damaligen Laufzeit. Aktuell ist laut Root nur 2560×1440 angeschlossen; der 3440-Monitor ist inzwischen getrennt. Daraus folgt kein Verlust des historischen Nachweises und kein aktueller 3440-Nachweis.

## Umfang und Integrität

177 kopierte Rohdateien, 22 native Original-PNGs, 70,83 MiB an Rohkopien (rund 71 MiB einschließlich Index/Prüfhilfe). Kein Bild wurde verkleinert, beschnitten oder anderweitig bearbeitet. Genau ein Vorher-/Nachherpaar der Baseline-Missionsansicht ist enthalten. Wiederholte Menü-/Missionsbilder und vollständige große Performance-Frame-JSONs werden nicht dupliziert.

Die vollständige frühere Fassung mit 218 Rohkopien / 402,58 MiB bleibt unverändert lokal unter `output/playtest_20261105/evidence_archive/full_qa_bundle` erhalten. Vor dem Verschieben wurden Quelle und absolutes Ziel im Workspace geprüft; alle 218 Hashes wurden verifiziert. Auch der frühere Bericht bleibt daneben als `PLAYTEST_2026-11-05_before_lean.md` erhalten. Nichts wurde gelöscht.

- [manifest.json](manifest.json): Paketpfad, Originalpfad, SHA-256, Größe und Bilddimensionen jeder Kopie; externe Referenzen und Archivherkunft.
- [external_index.md](external_index.md): bestehende Repository-Assets und ausgelassene lokale Rohdaten mit Originalpfad, Größe und SHA-256.
- [SHA256SUMS.txt](SHA256SUMS.txt): Hashindex der Rohkopien und des Manifests.
- [verify_bundle.py](verify_bundle.py): ausschließlich lesende Prüfung, ohne Engine.

```powershell
python docs/qa/playtest_20261105/verify_bundle.py
python docs/qa/playtest_20261105/verify_bundle.py --check-originals --check-archive
```

Die erste Variante prüft die schlanken Kopien und bereits vorhandene Repository-Referenzen. Die zweite prüft zusätzlich alle Originale und das erhaltene vollständige Archiv; sie benötigt lokale Output- und Isolationsverzeichnisse. Roh-JSONs behalten ihre eingebetteten Originalpfade unverändert. Das Manifest hasht sich nicht selbst; sein SHA steht im separaten Hashindex. Neu verfasste Dokumente und Prüfskript sind keine Laufbelege.

## Pfadindex

| Paket / direkte Referenz | Aussage / Grenze |
|---|---|
| [Heimatbasisziel](../../reports/assets/ui-2026-11-01/menu_heimatbasis.png), [Loadoutziel](../../reports/assets/ui-2026-11-01/menu_fob_loadout.png), [A5-Ziel](../../reports/assets/ui-2026-11-01/mockup_a5_mission_zweireihig.png) | Bestehende originale 2D-Referenzen direkt verlinkt; kein Runtimebeleg. |
| [Originalmenü](../../../Assets/curated/main_menu/sternenbuerger_main_menu_bg.jpeg), [Herkunft](main_menu/provenance/source.json) | Exaktes ursprüngliches TASK199-Bild. |
| [native_base_controls](native_base_controls/controls.json) | 86/86; historische 3440×1440-Vollbildroute. Vier damalige Harness-Mauswarnungen bleiben im Log. |
| [native_visual_3440](native_visual_3440/visual.json) | 77/77; echte Flugphasen. Normaler Schuss im 20-s-Fenster unbeobachtet. |
| [NPC-Fixture](npc_controlled_fixture/npc_visual_fixture_2677746.json) | 23/23 + 19/19; kontrolliert und synthetisch, kein physischer Combatnachweis. |
| [Vorheranalyse](performance/baseline/before_analysis.json), [früher Vergleich](performance/before_token_fix/active_0_30_comparison.json), [Nachheranalyse](performance/before_token_fix/final_analysis.json) | Aktives 0–30-s-Fenster; volle Rohframe-Dateien extern gehasht. Keine finale 90-s-FPS-Abnahme. |
| [Token-Diagnose](performance/token_diagnosis/motion_analysis.json) | Diagnose vor Fix; vollständige Motion-/Frame-Rohdaten extern. |
| [Finale 90-s-Analyse](performance/final_motion_90/final_motion_analysis.json), [Normalbericht](performance/final_motion_90/final.json) | 61/61; Bewegung bis 89,85 s bei 0,984×, physisch 2560×1440. Sieben große Move-/Go-Hitches bleiben offen; kein direkter 3440-Vergleich. |
| [Responsive-Nativ](responsive_final/layouts.json), [Headless62/62](final_followups/homebase_narrow_green.log) | 19/19; logisch 1280/1600/1920 auf physischem 2560×1440-Vollbild, neue schmale Ansicht lesbar. |
| [Mission in zwei logischen Größen](mission_logical_sizes/report.json) | Je 77/77 für 1280/1920. Alte 1280-Homebaseaufnahme ist ersetzter RED und keine finale UI-Abnahme. |
| [REDs](red/) | Ursprüngliche fehlgeschlagene Checks und Logs bleiben unverändert. |
| [Token-Headless-GREEN](token_headless_green/report.json) | Token 15/15; TASK501 10/10. |
| [Move nach Auto-DEF](move_autodefend_green/move_autodefend.json) | 87/87; dieselben drei Units physisch wieder bewegt. |
| [MP Erstversuch](multiplayer/first_console_attempt/report.json) | FAIL: Netzwerk konvergent, Fenster- und normaler Exitnachweis fehlten. |
| [MP GUI-Retry 2](multiplayer/gui_retry_2/report.json) | FAIL: Netzwerk konvergent und Exit 0; Vollbildfehler und Client-Cleanupdiagnostik. |
| [MP GUI-Retry 3](multiplayer/gui_retry_3/report.json) | FAIL: benötigtes 3440-Display inzwischen nicht angeschlossen; kein Netzwerk-/Vollbild-PASS ableiten. |
| [MP Retry4 extern](external_index.md) | FAIL bleibt unverändert erhalten; vor finalem Clock-/Disconnectfix. |
| [Clock-/Disconnect-Owner](multiplayer/clock_owner_green/report.json) | 16/16 gezieltes GREEN; finaler Zweipeerlauf zusätzlich PASS, 10/10. |
| [Finaler nativer MP-Paarlauf](multiplayer/final_pair/report.json), [Sourcepins](multiplayer/final_pair/source_pins_before.json) | Alle 10 Checks PASS; acht identische deployed IDs, beide regulär Exit 0, Enginefehler 0, stabile Sourcepins. Native Probe/Renderbuffer/PNG exakt 2560×1440, Win32-Overscan +2 px dokumentiert. |
| [Abschließende gezielte Matrix](final_checks/report.json) | 34/34 ausgewählte Gates ohne Enginefehler; keine allgemeine All-tests-PASS-Aussage. |
| [Porträtmanifest](portraits/provenance/manifest.json), [aktive Assets](../../../Assets/curated/portraits/frontier_20261105/) | 11 Bögen / 44 Regionen / 42 IDs / 2 Reserven; Assets direkt verlinkt statt dupliziert. |
| [Review](reviews/independent_review.md) | Scoped Source-Review; keine Releasefreigabe. |

## Ausgewählte native Bilder

| Motiv | Roh-PNG |
|---|---|
| Originalmenü im normalen Start | [01_main_menu.png](native_base_controls/controls_captures/01_main_menu.png) |
| Operationsansicht und vollständiges Fokusporträt | [02_homebase.png](native_base_controls/controls_captures/02_homebase.png) |
| Begehbare Basis | [02a_base_walkable.png](native_base_controls/controls_captures/02a_base_walkable.png) |
| HUD und realer Missionsauftrag | [06_go_movement.png](native_visual_3440/visual_captures/06_go_movement.png) |
| Außenpostenübersicht | [07_outpost_overview.png](native_visual_3440/visual_captures/07_outpost_overview.png) |
| Östliche Versorgung | [08_eastern_supply.png](native_visual_3440/visual_captures/08_eastern_supply.png) |
| Fernsicht / Grid | [09_expanded_map.png](native_visual_3440/visual_captures/09_expanded_map.png) |
| Realer Abstieg | [10_real_descent.png](native_visual_3440/visual_captures/10_real_descent.png) |
| Realer Bodenkontakt | [11_real_ground_contact.png](native_visual_3440/visual_captures/11_real_ground_contact.png) |
| Realer Start | [12_real_takeoff.png](native_visual_3440/visual_captures/12_real_takeoff.png) |
| Baseline-Mission vorher | [03_default_mission.png](performance/baseline/before_captures/03_default_mission.png) |
| Passendes Nachher-Missionsbild, vor Tokenfix | [03_default_mission.png](performance/before_token_fix/native_homebase_captures/03_default_mission.png) |
| Move nach Auto-DEF, neuer nativer Tokenlauf | [06_go_movement.png](move_autodefend_green/move_autodefend_captures/06_go_movement.png) |
| Kontrolliertes Down | [03_down.png](npc_controlled_fixture/captures/03_down.png) |
| Kontrolliertes Bleedout | [06_bleedout.png](npc_controlled_fixture/captures/06_bleedout.png) |
| Synthetischer Schuss früh | [09_synthetic_shot_early.png](npc_controlled_fixture/captures/09_synthetic_shot_early.png) |
| Synthetischer Schuss 120-ms-Ziel | [10_synthetic_shot_120ms.png](npc_controlled_fixture/captures/10_synthetic_shot_120ms.png) |
| Synthetischer Schuss abgelaufen | [11_synthetic_shot_expired.png](npc_controlled_fixture/captures/11_synthetic_shot_expired.png) |

| Neue schmale Basis, 1280 | [homebase_1280.png](responsive_final/captures/homebase_1280.png) |
| Vier Spalten, 1600 | [homebase_1600.png](responsive_final/captures/homebase_1600.png) |

Die ältere 1280-Homebaseaufnahme `output/playtest_20261105/native_logical_sizes/20261105T085433Z-a588f435/visual_1280_captures/02_homebase.png` ist als **SUPERSEDED_RED** extern gehasht. Ihr ursprünglicher Befund bleibt erhalten. Die neue 19/19-Serie ersetzt diesen UI-Kandidaten; die darin damaligen 77/77-Missionschecks bleiben separat gültig.

| Finaler MP-Host | [host_display_mission.png](multiplayer/final_pair/host_display_mission.png) |
| Finaler MP-Client | [client_display_mission.png](multiplayer/final_pair/client_display_mission.png) |

## Offene Schlussgates

Main-Integration und der anschließende native Smoke sind **bestätigt: 86/86**. Finale Sourcepins sind stabil; 34/34 gezielte Gates und der native MP-Paarlauf mit 10/10 sind bestätigt. Der 90-s-Bewegungsnachweis und die nativen logischen UI-Größen sind bestätigt. Move-/Go-Klickkosten von 212–331 ms bleiben offen; die MP-Rohlogs enthalten weiterhin Netfox-Stall-Debugmeldungen bis 2,755 s. Keine allgemeine FPS-/Jitterfreigabe. Keine EXE-/LAN-/WAN-/Mehrrechner- oder stilistische Nutzerabnahme.

Sieben gegen Original-Main bestätigte historische Altgates (sechs bekannte plus TASK468 mit 13 PASS / 1 FAIL) werden getrennt geführt und nicht als neue Regressionen ausgegeben. Alle RED-/FAIL-Rohbelege bleiben erhalten.

## Main-Abschluss

[Integrationsnachweis](main/integration.json), [frischer nativer Main-Smoke](main/main_smoke.json) und [Runnerbericht](main/report.json): 86/86, keine Enginefehler oder Warnungen. 1846 Quellpins ohne Drift; 38 fremde Dateien und 437 alte Rosterdateien unverändert. Der Quellcommit ist `4abd830bad56154444bbfccf376d216221a152d8`; danach nur Doku/Evidenz. Große Rohdaten und historische Fehlläufe bleiben lokal erhalten.
