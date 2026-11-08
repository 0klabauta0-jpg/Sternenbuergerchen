# R4: einmalige frische Frontier-Quelle im OneScreen-Presenter

Untertask zu `RUNTIME_HITCHES_R4_2026_11_07.md`. Root besitzt Engine, Git
und Produktfreigabe. Der enge Controllerhunk ist nach repariertem echtem RED
exklusiv an den Commandwriter delegiert.

## Problem / bestaetigter lokaler Befund
`_build_frontier_probe_one_screen_playability_readout` baut einen frischen
NextInteraction-Snapshot und anschliessend einen Handoff-Snapshot. Dieser
baut denselben NextInteraction-Snapshot nochmals. Jede NextInteraction liest
die echten Runtime-Gate- und Cargo-Snapshots erneut. Strategic RAW baut ausser
seinem OneScreen-Aufruf noch eigene NextInteraction/Handoff-Linien, insgesamt
mindestens vier gleichartige NextInteraction-Builds in einer RAW-Assembly.
Der gemessene ganze RAW-Scope liegt laut Rootprofil bei9-13ms; der Anteil
dieses einzelnen Untergraphs ist noch nicht gemessen.

## Warum kein Hidden-RAW-Skip
Die nicht sichtbaren Quellen speisen weiter den A5-Details-Popup und echte
Legacy-Action-Adapter. TASK964 prueft Textpraesenz und liefert ueber Polish/
ExecutionHook Runtime-Button-/Choice-Gates. Raw-/Label-/Metadaten-Auslassung
wuerde deren Semantik veraendern. Dieser Task belaesst alle Texte und Gates.

## Engster Umfang / Nicht-Ziele
Nur im einzelnen OneScreen-Aufruf den dort bereits frisch gebauten
NextInteraction-Dict mit dessen Handoff-Projektion teilen. Neuer expliziter
`_build_frontier_probe_debrief_handoff_feel_snapshot_from_next_interaction`
Helper; bestehender nullargumentiger Handoff bleibt ein
frisch lesender Wrapper. Keine globale-/Framecache, keine Weitergabe ueber
RAW-/Matrix-Reentrygrenzen und keine Aenderung an R3-Loop2-Depthguards oder
`MissionHudReadModel.project`-Reentryschutz. Kein Hidden-Presenter-Skip, keine
Task-Gate-/Command-/Callback-/Runtimeaenderung. Groessere RAW-Assemblies und
F6-Mehrfachprojektionen bleiben getrennte Folgeideen.

## Akzeptanz / realer RED und Oracle
- Echter Controller-Superpfad in der authored Mission: ein OneScreen-Aufruf
  liest NextInteraction genau einmal. Die realen Gate-/Cargo-Unterabfragen
  werden vorher direkt pro NextInteraction und pro OneScreen-Szenariokontext
  gemessen; ihre fachlich notwendigen Reads bleiben erhalten.
- Eigenstaendige OneScreen-/Handoff-Aufrufe lesen immer neu. Eine synchron
  verschachtelte OneScreen-Abfrage sieht ihre eigenen aktuellen Eingaben;
  die aeussere behaelt ihre lokale Stichprobe. Kein globaler Shared-State.
- Exakte vollstaendige Readout-/Handoff-Ausgabe gegen den vor Produktpatch
  real aufgenommenen Oracle; RAW bleibt byte-identisch, wenn an Stelle des
  jetzigen Readouts der eingefrorene Oracle-Readout in denselben realen RAW-
  Builder eingespeist wird. Keine Legacy-Implementierung im Test nachbauen.
- Reine Gate-/Cargo-UI-Fixtures decken AA/Computer/Cargo/Debrief ab; ein
  zusaetzlicher Fall liest die echten unveraenderten Runtimequellen.
- Actors, HP, Positionen, Tick, Plaene sowie Command-/Effectqueue bleiben
  unveraendert. Keine physische Spiel-/FPS-Abnahme aus diesem Komponentenfall.

## Dateien / Pruefung / Sourceuebergabe
Verifier: `scripts/tests/runtime_hitches_r4_20261107_strategic_source_verifier.gd`,
Marker `R4_STRATEGIC_SOURCE_PASS`. Der echte RED druckt einen einzigen
`R4_STRATEGIC_SOURCE_ORACLE`-JSON-Datensatz. Root pinnt danach ausschliesslich
diesen unveraenderten Prepatch-Istoutput als neue Testfixture
`scripts/tests/runtime_hitches_r4_20261107_strategic_source_oracle.json`,
bevor ein Produktpatch freigegeben wird. Die Verifierquelle bleibt dabei
unveraendert. Der Runner muss diese zusaetzliche Oracle-Datei beim GREEN
mitpinnen; der ausgewaehlte Verifier selbst wird bereits automatisch gepinnt.
Vorhandene R3-Strategic-/Controller-/ReadModel-Nachbarn bleiben.
Produkt erst nach Root-RED im Controller, exklusiver Writer wird von Root
benannt. Vorschlag an Commandwriter ist uebermittelt. Contracts: AGENTS,
ARCHITECTURE, CODEX_RULES und mission_hud_projection_authority_contract.

## Risiken / Status
Leere explizite Quelle darf keinen versteckten Runtime-Fallback ausloesen.
Standalone-/Reentry-Aufrufe duerfen keine vorherige lokale Quelle erben.
Der Oracle darf ausschliesslich aus dem gebundenen echten RED stammen,
nicht spaeter passend zur Implementierung erzeugt werden. RED/GREEN,
zugeordnete Millisekunden und native Leistungswirkung sind PENDING.

## Erster Root-RED / Testpraezisierung vor Produktfreigabe
- Root-RED `output/runtime_hitches_r4_20261107/strategic_source_red/20261107T094842Z-a985b516`:
  **20 PASS / 8 RED**, keine Enginefehler. Sieben REDs betreffen den gewuenschten
  einmaligen NextInteraction-Build/Reentry und den noch fehlenden Helper.
  Ein zusaetzlicher Standalone-RED war eine zu enge Testannahme: Der echte
  NextInteraction liest Gate direkt und ueber `_should_sync...` erneut.
  OneScreen hat ausserdem einen eigenen legitimen Szenariokontext-Gateread.
- Korrigierter Verifier misst die direkten Unterabfragen zuerst lokal: echter
  NextInteraction Gate2/Cargo1, OneScreen-Kontext Gate1; damit erwarteter
  optimierter OneScreen Gate3 und Standalone-Handoff Gate2. Die UI-Fixtures
  bleiben bei Gate1. Erwartete eigentliche Count-/Helper-REDs bleiben bestehen.
- Der echte Prepatch-Oracle wurde von Root vor Produktaenderung unveraendert
  gepinnt: `runtime_hitches_r4_20261107_strategic_source_oracle.json`, SHA256
  `f7d3e591d2c30c2d5e798979fc829f0a1935793d57cf90b75c11a8362c81a13d`.
  Die Testpraezisierung veraendert diese Datei nicht.
- Reparierter Root-RED vor Produktpatch:
  `strategic_source_red_repaired/20261107T095122Z-1e61f5ee`,22/7 ohne
  Enginefehler und mit stabilen Quellen. Exakt einmalige Source/Reentry und
  neuer expliziter Helper fehlen; vor Produktpatch gepinnter Goldenvergleich
  besteht. Rootfreigabe: nur lokaler OneScreen->Handoff-from-Next-Helper,
  Standalonewrapper frisch und explizit leer ohne Fallback; keine RAW-/Gate-
  oder Cacheaenderung.
- Enger Patch: unveraenderter Handoff-Projektionsbody im expliziten Helper,
  Standalonewrapper liest frisch; OneScreen reicht nur seinen lokalen Next
  weiter. Controller-SHA256 nach diesem Schritt
  `0706cc526e0021d500be7750599fa0b74b66a30d7c4d8b339375444fa1ff4523`.
  Verifier unveraendert`f45bafa0...`, Golden weiter`f7d3e591...`.
- Root meldet Strategic-GREEN exit0 ohne Enginefehler und anschliessend
  R3-Strategic- sowie Command-Nachbarn gruen. Unabhaengiges Produktreview des
  Minihunks: APPROVED scoped, keine P1/P2. Gesamt-Runtime-/GPUgewinn wird aus
  diesem Komponentenpass nicht abgeleitet; native Resthitches bleiben offen.
