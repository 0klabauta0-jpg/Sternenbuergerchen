# R4-Fortsetzung: GPUdiagnose, Resthitches und Main

## Ziel / Problem / Basis
Der Nutzer gibt den Rechner fuer die restlichen GPU-/Vollbildtests frei und
autorisiert erneut direkte Mainintegration samt Push ohne Zwischenstopps.
Arbeitsbranch `task/runtime-hitches-r4-20261107`, Checkpoint
`3345fc573f566cd0927397092eebab8fbde7d524`, Main/Remote bisher
`3b12b2878b42d1be0a7a2e8e925cf13835ff1d78`.
Der letzte normale Lauf hat trotz lokal kuerzerer Movement-Scopes321.078ms
Maximalframe, P99=143.812ms und Sim/Wand0.980801. Eine GPU-/OSursache ist
nicht bestaetigt; GPUzeiten fehlen bisher.75 funktionale Gates sind gruen.

## Umfang / Ursache / Nicht-Ziele
Zuerst vorhandenen separaten GPUharness nativ bei unveraenderter normaler
Route pruefen. Viewportzeiten, Pipelinezaehler, Script-/Physics-/HUDzeiten und
Wandzeit getrennt korrelieren. Erst belegte Ursachen erhalten einen engen
Untertask/RED und Produktpatch. Keine spekulativen Render-/Gameplayumbauten,
Qualitaets-/Sichtweiten-/Actor-/Budget-/1x-Reduktion oder Actor-/HP-/Timer-
Patches. Patrouillen-/Attack-KI, EXE und WAN bleiben eigene Aufgaben.

## Akzeptanz und lokale Pruefung
1. Aktuelle Quellen, privateProfile-/Rosterguards und Schutz der fremden WIP
   pruefen. Der versiegelte Checkpoint unter
   `docs/qa/runtime_hitches_r4_20261107/` und seine447 Rohdateien bleiben
   unveraendert. Neue Laufordner duerfen nur hinzugefuegt werden.
2. Echtes Vollbild3440x1440, Vulkan/Forward+, normale Kamera22 und1x.
   GPUdiag muss echte positive Werte je vorhandener Viewportrolle getrennt
   belegen; sein zusaetzlicher Instrumentierungsaufwand bleibt markiert.
3. Fixes brauchen Ergebnis-/Owner-/Freshnessparitaet und passende Nachbarn.
   Root bleibt einziger Engine-/Gitrunner, genau ein Writer pro Produktdatei.
   Keine parallelen Audits/Benchmarks im nativen Messfenster.
4. Abschliessend wiederholter unveraenderter normaler90-s-Vollbildpfad mit
   Verteilungen, Hitches, Durchsatz und Backlogs; technische/visuelle Grenzen
   offen benennen. Kein isolierter Median oder Maxwert als Gesamtfreigabe.
5. Bericht/Sourcebindung/neue Evidenz in eigenem Fortsetzungspaket. Gepruefte
   Commits per Fast-forward auf Main, frischer Main-Vollbildsmoke, normaler
   Push und Remotevergleich. Fremde Dateien/Saves bleiben unveraendert.

## Dateien / Dokumente / Risiken
AGENTS, PROJECT_BRIEF, ARCHITECTURE, CODEX_RULES, IMPLEMENTATION_STATUS,
TASK_ROADMAP, R4-Haupttask, GPUdiagnosetask und bisheriges QA-REPORT gelten.
Produktdateien werden erst nach Befund benannt. Bestehender GPUharness,
isolierter Runner und Nachbarmanifest werden wiederverwendet. Rendertimer
koennen Overhead/Threadwartezeit erzeugen; Werte sind letzte Framewerte,
keine additive komplette Timeline. Fremde Prozesse/Systemeinstellungen
werden nicht veraendert. Main- und Gesamtleistungsfreigabe stehen noch aus.
