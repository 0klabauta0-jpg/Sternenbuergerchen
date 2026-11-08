# R4: restliche Framehitches und Kampfdarstellung

## Ziel und Basis
Nutzerauftrag vom07.11.2026: verbleibende Spitzen bis177ms architektonisch
untersuchen und abbauen; erneut echtes Vollbild und anschliessende direkte
Mainintegration mit Push ohne Zwischenfreigaben. Ausgangspunkt Main
`3b12b2878b42d1be0a7a2e8e925cf13835ff1d78`, neuer Taskbranch
`task/runtime-hitches-r4-20261107`. Kein konkurrierender aktiver Writer im
gleichen Projekt in der aktuellen Chat-Inventur; fremde Worktrees bleiben.

## Reproduktionsfragen / gewuenschtes Verhalten
- Restliche lange Frames: Ursache und synchronen Datenfluss messen, bevor
  Workbudget, Scheduler oder Cache geaendert werden. Eine Runtimequelle,
  aktuelle Ownerdaten, keine zweite UI-/Combat-/Sichtwahrheit.
- Sichtbares Muendungsfeuer folgt tatsaechlichen bestaetigten Fire-Events.
  Ohne Fire-Event wird kein Schiessen erfunden. Sichtbare Figuren muessen
  bei vorhandenem Modell Menschen bleiben, statt auf Pillen zurueckzufallen.
- Nahe Gegner duerfen durch Entfernungseinheiten, veraltete Sicht- oder
  Snapshotdaten nicht verschwinden. Echte LOS-Hindernisse und Team-FoW gelten
  weiter; keine pauschale Sichtweitenvergroesserung oder Enthuellung.
- Das beobachtete Hin-und-her-Laufen / direkte Angriffsverhalten wird als
  gesonderter KI-Folgeauftrag festgehalten, nicht still in dieser Runde neu
  balanciert. Ein normaler oeffentlicher Kampfpfad darf fuer VFX geprueft werden.

## Umfang / Nicht-Ziele
Betroffene Runtime-/HUD-/Fog-/Visualpfade nach aktuellem Befund. Erst kleine
Untertasks/AC und echter RED; Root ist einziger Engine-/Git-/Integrationsrunner.
Agentenaudits sind zuerst lesend. Gemeinsame Controller-/TerrainView-Hunks
bekommen genau einen Writer. Keine Rendererqualitaets-, Actorzahl-, Sichtweiten-
oder1x-Reduktion als Performancegewinn. Kein Actor-/HP-/Timer-/Fuel-/Position-
Patch fuer physische Spielbeweise. Kein unautorisierter KI-Neuentwurf,
Multiplayerausbau, EXE-/Releaseumfang oder HTMLreport.

## Dokumente / Contracts
AGENTS, PROJECT_BRIEF, ARCHITECTURE, CODEX_RULES, IMPLEMENTATION_STATUS,
TASK_ROADMAP, mission_hud_projection_authority_contract,
combat_loop_authority_contract, fog_of_war_modes_contract,
unit_facing_visual_contract, graphics_reference_revision_contract und
docs/qa/reference_polish_r3_20261106/REPORT.md. Alte Belege sind historische
Hinweise; neue Ursachen und Vergleiche werden frisch gebunden.

## Akzeptanz / lokale Pruefung
1. Frische Schutzpins fuer vorhandene ungetrackte Arbeit, Roster und den echten
   Spielerroster; ausschliesslich neue private Engineprofile und Outputs.
2. Frischer normaler90-s-Vollbildvorlauf auf Produktkamera22 mit unveraenderter
   Qualitaet/Rate/Route und separaten Frame-/Tick-/UI-/Fog-/Rendererzaehlern.
   Vorhandene177ms-Belege selektiv untersuchen; keine verschachtelten Zeiten
   addieren. Gleichartige Nachlaeufe, Wiederholung bei relevanter Streuung.
3. Enger Verifier gegen bestaetigte Ursache; Source-/Owner-/Commandparitaet,
   begrenzte Cachelebensdauer, Invalidation und interleavte Befehle sichern.
4. Figuren-/Muendungs-/Sichtbefund zuerst reproduzieren; passende CPU-/native
   temporale Nachweise mit echten Quellen und vorhandenen Identitaeten.
   Vergleichsbilder in realem Spielabstand oeffnen; Bildstatus kenntlich machen.
5. Betroffene Nachbargates und unabhaengiges Nachreview; klares Ergebnis samt
   verbleibenden harten Grenzen. R3 und andere historische Ausgaben bleiben.
6. Getestete Quellen per Fast-forward auf Main, frischer Main-Vollbildsmoke,
   normaler Push und Remoteabgleich; Source-/Roster-/WIP-Schutz erneut pruefen.

## Betroffene Dateien / Risiken
Konkrete Produktdateien erst nach aktuellem Audit im jeweiligen Untertask.
Wahrscheinliche Grenzen sind synchrone HUD-/Runtimeprojektionen,
Fog-/LOS-/Hex-Koordinaten und Unitmodell-/Fire-Event-Zulassung.
Caches duerfen weder sichtbares Feedback noch echte Gameplayfortschritte
verzoegern. CPU-/GPU-/Hintergrundlast und neue Diagnosekosten getrennt halten.
