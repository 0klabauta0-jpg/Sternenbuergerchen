# Arbeitsanweisung fuer neuen Chat: R4 fertigstellen und auf Main integrieren

Stand: 08.11.2026, nach expliziter Pause fuer einen Rechnerneustart.
Diese Uebergabe wurde nur lesend gegen Git, Dateien und Remote verifiziert.
In diesem Uebergabeschritt wurden keine neuen Tests gestartet.

## Auftrag und Autorisierung

Arbeite in `C:\dev\SternenBuergerchen` mit Godot4.6.2. Setze den bestehenden
R4-Auftrag fort: restliche GPU-/Vollbildtests, Ursachen verbleibender Hitches
belegen und beheben, passende Regressionen und normale Vollbildnachlaeufe,
danach direkt Mainintegration mit frischem Main-Smoke und Push.
Der Nutzer autorisiert das ausdruecklich ohne Zwischenstopps. Keine erneute
Main-/Pushfreigabe einholen. Notwendige Schutz-/Testgrenzen bleiben verbindlich.

Es geht um die Fortsetzung, nicht einen neuen Grafik-/KI-/Releaseumfang.
Der Nutzer ersetzte zuletzt das Weiterarbeiten in diesem Chat durch diese
kopierbare Arbeitsanweisung. Der neue Chat soll nach Einlesen fortsetzen.

## Gitstand und vorhandene Arbeit

- Arbeitsbranch: `task/runtime-hitches-r4-20261107`.
- HEAD und verifizierter Remote-Taskbranch:
  `3345fc573f566cd0927397092eebab8fbde7d524`.
- Darin Produktcodecommit:
  `14a7e9188a0bad8227105ce6ee3d8273adc157a5`.
- Lokales Main und verifiziertes `origin/main` unveraendert:
  `3b12b2878b42d1be0a7a2e8e925cf13835ff1d78`.
- R4 ist **noch nicht auf Main integriert**. Nicht auf Main implementieren.
  Nicht auf `integration/core-foundation` oder einen alten Branch wechseln:
  diese Fortsetzung baut bewusst auf dem noch nicht integrierten Task auf.

Bekannte eigene, noch uncommittete Aenderungen:

1. `scripts/tests/runtime_hitches_r4_20261107_gpu_capture.gd` ist modifiziert.
2. `docs/tasks/RUNTIME_HITCHES_R4_2026_11_08_finish_gpu_main.md` ist neu.
3. `docs/tasks/RUNTIME_HITCHES_R4_2026_11_08_frame_boundaries.md` ist neu.
4. Diese neue Uebergabedatei ist ebenfalls noch uncommittet.
5. Neue eigene Messergebnisse liegen im ungetrackten Output; nicht aufraeumen.

Weitere untracked Dateien sind geschuetzte Altbelege oder fremde WIP, darunter
`builds/`, `export_presets.cfg`, TASK1064/TASK1180, der TASK1180-Script,
alte `output/`-Verzeichnisse, `.import`-Dateien und `__pycache__`.
Kein `reset`, `clean`, `stash`, Loeschen, Restaurieren oder pauschales `git add .`.

## Zuerst lesen und pruefen

1. `AGENTS.md`, `docs/PROJECT_BRIEF.md`, `docs/ARCHITECTURE.md`,
   `docs/CODEX_RULES.md`, `docs/IMPLEMENTATION_STATUS.md`, `docs/TASK_ROADMAP.md`.
2. `docs/tasks/RUNTIME_HITCHES_R4_2026_11_07.md`.
3. Die beiden neuen Fortsetzungs-/Boundarytasks aus der Liste oben.
4. `docs/tasks/RUNTIME_HITCHES_R4_2026_11_08_gpu_frame_diagnostics.md`.
5. `docs/qa/runtime_hitches_r4_20261107/REPORT.md` und die
   `docs/reviews/RUNTIME_HITCHES_R4*`-Reviews.
6. Relevante Contracts, insbesondere
   `docs/dev/mission_hud_projection_authority_contract.md`,
   `docs/dev/unit_facing_visual_contract.md` und Grafikreferenzvertrag.
7. Gitstatus/Remote, aktuelle Prozesse und Sourcehashes frisch pruefen.
   Alte PIDs, Lastzustaende oder Messwerte nicht als aktuellen Rechnerzustand
   behandeln. Keine konkurrierenden nativen Laeufe starten.

## Was bereits umgesetzt und geprueft ist

- HUD: vier begrenzte primitive Jobs ueber den bestehenden UpdateManager,
  hoechstens ein periodischer Job pro Renderframe. Jeder liest frisch;
  Full bleibt synchron, Light sofort; Force/Reentry/Cancel/Lifecycle getestet.
- Redundante LOS-, Presenter-, Style-, Karten- und Quellaufbereitung reduziert.
- Nearest-Walkable: erst unveraenderter Distanz-/Tieguard, dann Livewalkability.
  Keine Cache-/Budget-/Auswahlveraenderung.107/0 Oracle-/Livepruefungen;
  Zaehlfixtures2 statt258 Lookupreads. Die Distanzsuche bleibt linear.
- Kampfdarstellung: echte Muzzleanker, Flash/Icon, aktuelle statt historischer
  Aimquelle, importierter Shoot-Hold und korrekte A/F-Waffenmesh-Achsen.
  Erfolgreiche Humanmodelle werden nicht mehr vom Capsule-Core verdeckt.
- Native Originalbilder belegen Flash/Icon und eine natuerlich niedergeschlagene
  horizontale Originalfigur mit gleicher Model-/Proxyidentitaet.
  Exakte Bodenauflage bleibt unbelegt. Kein Nah-Ausblendungsbug reproduziert;
  beobachtete22 Sichtzustaende passen zu echten LOS-/Tilefreigaben.
- Komplette funktionale Matrix zuletzt **75/75**, errors0, stabile Quellen.
  Das ist keine allgemeine FPS-/Releaseabnahme.

Aktuelle wichtige Produktpins (SHA256):

- Controller: `b247162e46edaca4e5696c9d96242384aca102ff03cb8f2e2c84c103627cddaf`.
- TerrainRegistry: `1aa3b96e1010298d050d1aade5b27c40ddb560dccd17ac4ad1d74223d37974b7`.
- Normaler R4-Capture:
  `6b987e9c33a866b751c40a82f7bb3275fe8162ac83aa9fe7073bff8716aa7832`.
- Basiscapture `playtest_20261105_fullscreen_performance_capture.gd`:
  `99b3526b39376872155387bc7c1b2c8f53d011f4eb5f63aed6b5e7cb46902ce4`.

Alte rote Befunde wurden nicht verschwiegen: TASK174 war schon auf Original-
Main81/2 rot; Meshoracle sachlich korrigiert bei gleichen Richtungsschwellen,
echte Assetkorrektur und85/0 separat belegt. Command-Batch behielt alle43
Fachpraedikate und bekam5 Schedulerpruefungen; historische39/4 bleiben erhalten.

## Offene Leistung und erster echter GPUlauf

Die Gesamtleistungsabnahme ist offen. Ein normaler90-s-Nachlauf erreichte
321.078ms Max, P99=143.812ms, Sim/Wand0.980801 trotz kuerzerer Movementstarts.
Keine allgemeine Verbesserung oder feste177-ms-Grenze behaupten.

Erster GPUdiagnoselauf, unveraenderter alter Harnesspin `cf718bf8...`:

`output/runtime_hitches_r4_20261107/finish_gpu_native_01/20261108T124012Z-9dd1f9a7/`

- `report.json`: exit0/errors0/Source- und Rosterguards gruen.
- `gpu_01.json`: **70/0** Funktionspruefungen.
- `gpu_01_gpu.json`: echte positive Root-/Karten-CPU-/GPUwerte, genauer
 90-s-Fensterfilter, beide Timer aufgeraeumt, keine invaliden Viewportbeobachtungen.
- `gpu_01_performance.json`: grosser Rohtrace, nicht komplett ausgeben.
- Kleine Auswertung:
  `output/runtime_hitches_r4_finish_20261108/gpu_01_analysis.json`.

Karten-GPU: Median2.558ms, P99=7.958ms, Max11ms. Root-GPU maximal3.219ms.
GPUprobe: Median28us, maximal223us. Trotzdem ein359.972-ms-Wallframe bei
70.369270s; nahe gelesene GPUwerte nur ca.0.17/2.5ms. Reine GPU-Rechenlast
ist damit keine bestaetigte Erklaerung. Root-/Kartenwerte, Physics und
verschachtelte Scopes nicht addieren; letzte Framewerte koennen versetzt sein.
GPU-Instrumentierung ist diagnostisch, keine unveraenderte FPSbaseline.

Kein belegter Doppelrender im normalen Homebase->A5-Einstieg gefunden.
Versteckte Homebase/Preview-/Legacy-2D-Pfade sind dort deaktiviert.
Motionprobe maximal1.487ms; der Transportreceipt am Peak war alt und216us.

## Wichtigster neuer Pruefansatz: Messharness selbst

70.369270s minus359.972ms ergibt **70.009298s**. Genau diesen Zeitpunkt
nennt das Originallog als70s-Progresspunkt.

`scripts/tests/playtest_20261105_fullscreen_performance_capture.gd:175-178`
ruft dort `_display_facts()`, JSON-Aufbereitung und `print()` auf, nachdem
das bisherige `probe_usec` schon erfasst ist. `_display_facts` fragt unter
anderem Displayrefreshrate, CPUname und GPUname ab. Die Kosten waren somit
nicht erfasst. **Zeitliche Korrelation, noch kein Kausal-/Millisekundenbeweis.**
Andere lange Frames liegen nicht alle im Zehnsekundenraster.

Deshalb wurde der separate GPUchild lokal erweitert:

- `frame_pre_draw` plus vorhandenes `frame_post_draw`, rohe monotone Zeiten,
  Engineframe-Matching, Status/Unavailable und Pre->Post-Wanddauer.
- `_display_facts()->Dictionary`-Override: exakt ein Superaufruf, unveraenderte
  Rueckgabe, begrenzte64 Timingrecords mit Fensterueberlappung.
- Kein Cache, kein Printshadowing, keine Parent-/Runner-/Produktaenderung;
  maximal16384 GPUrows, Cleanup beider Signale und der eigenen Viewporttimer.

Aktueller **uncommitteter** GPUchild-SHA256:
`68b4f3521a3e8a51b46c27e0d088c822edade1f883f7dc00b89069513c1a9424`.
Dieser neue Stand ist **noch nicht parser- oder nativ getestet**.
70/0 gilt fuer den alten cf718-Lauf, nicht fuer diesen neuen Stand.

## Konkrete naechste Schritte

1. Schutz und Prozesse frisch pruefen. Eigenen uncommitteten Diagnosedelta
   lesen/erhalten und eng parserpruefen, dann Boundary-GPUlauf starten.
2. `display_facts_calls` und Pre/Post-Grenzen mit Processsamples/Peaks
   korrelieren. Wenn Displayfacts lang sind, danach einzelne Unterabfragen
   eingrenzen; JSON/Printkosten sind durch diesen Override noch nicht gemessen.
   Keine Ursache auf Verdacht patchen oder fremde Programme beenden.
3. Bei bestaetigtem Harnessartefakt Messung korrigieren und alte/veränderte
   Messprotokolle klar unterscheiden. Das ist kein Produkt-FPSfix.
   Bei echtem Produkthotspot Task/RED/engen Fix/Paritaet/Nachbarn durchziehen.
4. Abschliessend zwei normale90-s-Vollbildlaeufe ohne zusaetzliche GPUprobe,
   gleiche Kamera22/3440x1440/Vulkan/Forward+/1x/VSync1/Physik60,max8,
   gleiche Route und Unitworkload. Verteilungen, Hitches, Durchsatz/Backlogs
   statt nur Median/Einzelmax dokumentieren. Keine IO/Scans als verschwiegenen
   Messaufwand behandeln. Messfenster sind exklusiv: andere Audits pausieren.
5. Betroffene Verifier/Contracts und unabhaengiges Nachreview; gemeinsame
   Matrix bei relevanter Produkt-/Basisharness-Aenderung neu binden.
6. Neues Fortsetzungspaket unter `docs/qa/runtime_hitches_r4_finish_20261108/`
   anlegen; Originalcheckpoint nicht neu generieren oder ueberschreiben.
7. Nur eigene Dateien committen. Remote/Ancestor pruefen, autorisierten
   Fast-forward auf Main kontrolliert ausfuehren. Frischer privater nativer
   Main-Smoke, normaler Push auf `origin/main`, exakten Remote-HEAD verifizieren.
   Implementierung/Dokureceipts auf Task-/Receiptbranch; keine Main-Direktarbeit.

Beispiel fuer den naechsten Boundarylauf (PowerShell, Repo-CWD):

```powershell
python -B scripts/tests/run_runtime_hitches_r4_20261107.py --script res://scripts/tests/runtime_hitches_r4_20261107_gpu_capture.gd --marker R4_GPU_DIAGNOSTIC_DONE --label finish_gpu_boundaries_02 --native --namespace SternenBuergerchen_UI_Zielbild_Normal_QA --timeout 500 -- --evidence-output='{RUN}/gpu_boundaries_02.json' --profile-seconds=90 --startup-timeout-seconds=260 --ui-size=3440x1440
```

Normale Vergleichslaeufe nutzen denselben Runner mit Script
`res://scripts/tests/runtime_hitches_r4_20261107_native_capture.gd`, Marker
`HUD_CAMERA_AUDIT_DONE`, eigenem Label/Ausgabebasename und gleichen Argumenten.
Funktionale Matrix:

```powershell
python -B scripts/tests/run_runtime_hitches_r4_20261107.py --manifest scripts/tests/runtime_hitches_r4_20261107_regression_manifest.json --label finish_regression_final
```

Nur Root startet Engines seriell. Run gilt nur mit passendem Marker, exit0,
keinen Script-/Parse-/Leakfehlern, stabilen Quellen und funktionierendem
Roster-/Privatprofilguard. Nativebilder oeffnen. Headless-/CPUmetadaten sind
keine Pixel-/GPU-/physischen Gameplaybeweise. Keine Actor-/HP-/Position-/Timer-
Fuelpatches oder Qualitaets-/Sichtweiten-/1x-Reduktion fuer einen gruenen Test.

## Schutz und versiegelte Evidenz

- `output/runtime_hitches_r4_finish_20261108/preflight.json`: letzte Pruefung
  bestand Originalschutz1415 Dateien,502 bestehende Roster und echten Roster;
  ausserdem447 alte Rohdateien und11 versiegelte QA-Dateien.
- Originalschutzpins:
  `output/runtime_hitches_r4_20261107/preserved_untracked.json`,
  `preserved_rosters.json`, `roster_baseline.json`.
- Der echte Spielerroster liegt unter
  `C:\Users\bjoer\AppData\Roaming\Godot\app_userdata\Sternenbuergerchen\profiles\local_player\roster_v1.json`.
  Letzter Schutz-SHA256:
  `de5861ded01505754788bda9be7c69e4e93757fd5152762a34ddedaecdd643dd`.
  Abweichungen untersuchen, nie automatisch restaurieren oder wegbaselinen.
- Versiegeltes Paket: `docs/qa/runtime_hitches_r4_20261107/` mit447
  Originaldateien im ZIP,6 nativen PNGs und2352 gebundenen Quelldateien.
  `raw_evidence.zip` SHA256:
  `191e885b985200ee65e783cf46fe39b63a1a2afa184c6500159edce8a3d29bb7`.
  `native_phase=deferred_by_user` ist historischer Checkpointstatus;
  nach neuem Nutzerstart wieder weiterarbeiten, alten Manifeststatus erhalten.
- Der vorhandene Packager schreibt feste Zielnamen und verweigert Overwrite.
  Nicht einfach erneut in den alten QA-Pfad laufen lassen. Fortsetzung neu
  paketieren; Rawlogs/JSON/PNGs bytegenau erhalten, Git-EOLfilter kontrollieren.
- Letzter Pausenvermerk:
  `output/runtime_hitches_r4_finish_20261108/PAUSED_FOR_RESTART_20261108.md`.
  HWiNFO/Steam wurden nicht als Ursache bestaetigt; alte Lastdaten sind keine
  aktuellen Prozessbelege und keine Erlaubnis, andere Programme zu beenden.

## Grenzen des Auftrags

SimulationRoot/Runtimekomponenten besitzen Gameplay; Registries sind Lookup-
Wahrheit, UI/Visuals lesen und senden Commands. Keine zweite Gameplaywahrheit,
keine Hotpath-SceneTree-Vollscans/per-frame Controlrebuilds.
Patrouillen-/Angriffs-KI bleibt separater Folgepunkt. Homebase-/Kamera-/2D-
Annaeherung ist R3; kein neuer Art-/Portraet-/Blender-/Multiplayer-/EXEumfang.
Endbericht trennt belegte Gewinne, Messartefakte, verbleibende Framegrenzen,
native Sicht und Git/Main/Push. Nicht als komplett ruckelfrei ausgeben,
solange die Daten das nicht tragen. Innerhalb des autorisierten Auftrags bis
zum konkreten Main-/Pushabschluss autonom durcharbeiten.
