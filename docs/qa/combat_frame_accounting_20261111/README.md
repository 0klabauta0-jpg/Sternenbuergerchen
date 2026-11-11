# B-Gefecht: nachvollziehbare Framekosten

11.11.2026; isolierter Branch `task/native-glut-maps-20261110`, auf
`6651ca47910b9fe8596d3edcc75d05643f259217`. Nach delegierter Implementierung
und Source-Review selektiv auf dem Taskbranch gesichert.
[Task](../../tasks/COMBAT_FRAME_ACCOUNTING_2026_11_11.md).

## Problem und Änderung

Die bisherige B-Probe las am Anfang eines Processframes den letzten einzelnen
Simulationstick und den vorherigen View-Process-Snapshot. Catch-up-Ticks
fehlten dadurch in der ausgewiesenen Summe. Der neue opt-in Debugpfad sammelt
je `Engine.get_process_frames()` alle Simulationsticks mit Anzahl, Summe,
Maximum, Tickspanne sowie Summen/Maxima der bestehenden Scopes. Eine kleine
Receipt-Historie bleibt auf acht Frames begrenzt. Getter lesen defensiv und
konsumieren nichts. Frames ohne Physiktick tragen null Arbeit.

View-Prozessarbeit erhält Scopes für FoW-Batches, regionale Chunks und
Flugvisuals; externe FoW-Aufrufe und die regionale Publikation bleiben separat
sichtbar. MetaLayerFlow unterscheidet Services, Kampagnenbeobachtung,
Checkpoint und Tutorial. Die separate Basis-Simulation wird über ihren
bestehenden Ownerverweis erfasst. Keine SceneTree-Suche oder Gameplay-Wahrheit
entsteht durch die Diagnose.

Der Sampler friert die CPU-Receipts vor dem Renderdispatch in `frame_pre_draw`
ein. `frame_post_draw` verbindet die gespeicherte FIFO-Receipt und ihre ID,
statt dessen möglicherweise spätere Engine-ID zu verwenden. Render-CPU/GPU
sind ausdrücklich **latest_available**: Godot aktualisiert die Timestamps nach
dem Post-Draw-Signal. Die ältere Controller-Receipt besitzt noch keine Frame-ID;
sie steht separat unter `controller_latest_available` und wird nicht zu
gleichzeitigen CPU-Kosten addiert. Verschachtelte Scopes sind nicht additiv.

Die einzige fachliche Bereinigung ist eine Zeile im Tutorial: Der
Checkpointguard wird aus dem bereits im selben synchronen Refresh gelesenen
Owner-Snapshot verwendet. Dazwischen liegen keine Commands, Runtime-Mutatoren
oder `await`. Anleitung, Sichtbarkeitsregeln und Kapiteltexte bleiben erhalten.

## Reale B-Probe

Beide nativen Läufe erfolgten erst nach expliziter CPU/GPU-Fensterfreigabe des
koordinierenden Agenten. Währenddessen liefen keine weiteren eigenen
Tests/Importe/Renderer. Godot 4.6.2.stable.official.71f334935, D3D12 Forward+,
RTX 4070 Ti SUPER, Fenster 1280×720, Terrainviewport 1920×1080, `time_scale=1`.
Versteckter nativer Host; kein headless Renderer. Beide Läufe starten über
normales Continue aus einer bytegleichen privaten Kopie des echten
Post-A-Checkpoints; anschließend reguläre Reise/Landung und GO zur realen
B-Wache. Je acht Schussereignisse und tatsächlich abgeschlossenes Kampfziel.
Map-SHA-256 für A/B/C, Checkpoint und relevante Quellen sind gebunden.
Die geladenen Rüstungsassets wurden während A/B nicht ausgetauscht.
Benutzerstände wurden nicht verwendet oder verändert.

| Enger Nachweis | Vorher | Nachher |
| --- | ---: | ---: |
| Native Funktionsprüfungen |37/0|37/0|
| Gesammelte Frames |9510|12770|
| Fehler bei Framezuordnung |0|0|
| Tutorial-Projektionen je Refresh |2|1|
| Tutorial-Refresh Median während Annäherung |0,882 ms|0,387 ms|
| Tutorial-Refresh Median während Gefecht |1,138 ms|0,378 ms|
| Erster physischer Move nach GO |2236,0 ms|2251,8 ms|

Die Reduktion von zwei vollständigen Owner-Projektionen auf eine ist im echten
Lauf nachgewiesen. Die Timingdifferenz enthält zusätzlich Laufstreuung.

Die Gesamtframereihen sind **keine allgemeine FPS-Freigabe und kein kausaler
Nachweis eines entsprechend großen Gewinns durch diesen Einzeilenfix**:
Gefecht P95/Maximum lag bei 98,892/201,450 ms und 20,516/48,718 ms. Gleichzeitig
ändern sich auch unveränderte Pfade deutlich: Kampagnenbeobachtung Median
9,422→6,380 ms, GPU-Median 3,933→1,623 ms und Catch-up-Maximum 8→2 Ticks.
Die Gefechtsausschnitte enthalten nur 140 beziehungsweise 515 Renderframes,
bei weiterhin acht echten Schüssen. Ursachen dieser Laufstreuung sind offen.
Ein pre_draw-zu-pre_draw-Wallintervall enthält vorherige Render-/Samplerarbeit
und aktuelle CPU-Arbeit; es ist kein exakt addierbarer Scope-Gesamttimer.

## Verbleibende konkrete Kosten

- Die Baseline enthält acht Simulationsticks in einem Renderframe, bis 36,385ms
  kumulierte Simulationsarbeit; der frühere letzte-Tick-Wert unterschlug dies.
- Der Abschluss einer regionalen Chunkanforderung braucht 36,613ms in der
  Baseline und 27,490ms im Nachlauf. Er baut die sichtbare FoW-Projektion neu;
  dies liegt zusätzlich zum weichen Chunkbaubudget. Nächster enger Kandidat:
  diese Publikation stufenweise vorbereiten und den vollständigen Ausschnitt
  erst mit gültigem FoW freigeben. Hier noch nicht geändert.
- Die unveränderte quartalssekündliche Kampagnenbeobachtung benötigt weiter
  rund 6–11ms und fordert die vollständige versteckte Basis-Operationsprojektion
  an. Dafür wäre ein gezielter Folgetask mit einer schmalen Owner-Projektion
  sinnvoll. Kampagnenbeobachtung nicht auslassen oder verlangsamen.
- Andere CPU-/Render-/HUDanteile bleiben teilweise ungemessen. Die nativen
  Testpolls sind separat sichtbar; im Gefecht maximal 0,165/0,153ms. Pre-Draw-
  Samplerarbeit liegt maximal bei 0,224/0,098ms. Debug-Snapshotbau bleibt als
  eigener Simulationsscope sichtbar.

Keine Details, Kartenflächen, tatsächlichen Personen, Gegner, Balance,
Bewegungskosten oder Simulationstempi wurden für diesen Schritt reduziert.
Die eigentliche umfassende Hitch-/Framerateabnahme bleibt offen.

## Lokale Verifikation und bekannte Grenzen

Die drei neuen Verifier wurden bei der abschließenden Integration in einem
weiteren privaten Profil erneut ausgeführt:11/0,7/0,7/0, Exit0. Dabei nur die
beiden bereits dokumentierten UID-Fallbackwarnungen, keine Scriptfehler.

- Neuer Accountingtest: zuerst erwarteter fehlender-Feature-Fail; abschließend
  11/0. Drei echte SimulationRoot-Calls in einem Frame, Nulltick-Folgeframe,
  exakte künstliche Scopewerte, defensive Getter und begrenzte Historie.
- Neue View-/Meta-Pipeline 7/0, einschließlich Frameidentität, zuvor unbenannter
  Scopes, unveränderter Kampagnen-/Supply-/Reisewahrheit und Debug-off.
- Tutorial-Einmallesen RED 7/4→GREEN 7/0: kohärenter Guard, aktuelle B-Anleitung,
  unveränderter Controlbaum, Debug-off und Skirmish-Ausblendung.
- Bestehende regionale Navigation 15/0 und Streaming 3/0. Keine Script-/Compile-
  oder Enginefehler in diesen gezielten Laufzeitprüfungen.
- Bestehender `campaign_tutorial_presenter_test.gd`: 31 Checks, 7 veraltete
  Kapitel-Erwartungen scheitern. Genau dieselben sieben Fehler wurden mit dem
  unveränderten HEAD-Tutorial nachgewiesen: satellite_completed, satellite_home,
  trade_departed, trade_used, bought, refueled, trade_home. Nicht geändert.
- Die beiden vorhandenen UID-Fallbackwarnungen in homebase_test_screen.tscn
  erscheinen auch in beiden nativen Läufen. Der Editorimport beendet Exit0
  mit einer ObjectDB-Leakwarnung; kein vollständiger Editor-/Release-PASS.
- Unabhängiges Source-Review von Framebindung und Einzeilenfix ohne konkreten
  Blocker. Keine Mainintegration, EXE, breite Framerate- oder Stilabnahme.

## Rohdaten und Wiederholung

[Vorherquelle](before_source.json), [Nachherquelle](after_source.json),
[Vergleich](comparison.json), [Originalframes](raw_frames.zip),
[Archivmanifest](raw_manifest.json), [Baseline-Log](frame-accounting-before.log),
[Nachlauf-Log](frame-accounting-after.log). Die unveränderten JSON-Dateien
liegen komprimiert im Archiv. `analyze_profiles.py` liest sie direkt dort.

`run_hidden_battle.ps1` ist aus dem bestehenden versteckten GPU-Runner
abgeleitet und ergänzt nur die Startargumente `continue-chapter` und `1x`.
SourceRoot/ProjectPath/EvidenceRoot/ProfileRoot müssen explizit auf den
isolierten Worktree beziehungsweise dessen QA-/Outputverzeichnisse zeigen.
Vor jedem nativen Wiederholungslauf erneut ein freies CPU/GPU-Fenster
vereinbaren und eine neue private Kopie desselben Post-A-Checkpoints verwenden.
