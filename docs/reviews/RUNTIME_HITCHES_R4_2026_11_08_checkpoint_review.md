# R4 Checkpoint: unabhaengiges Source- und Paketdelta-Review

## Ergebnis / Abnahmegrenze

APPROVED scoped: neuer GPU-Diagnoseharness und enger Packager-CLI-/Manifest-
Nachtrag sind fuer den angeforderten Bericht-/Code-Checkpoint source-seitig
freigegeben. Keine offenen P1/P2 in diesem Umfang. Der Reviewer ist weder
Autor des GPUharness noch des Packagernachtrags. Einzige Reviewer-Schreibaktion
ist diese neue Datei; keine Engine-/Git-/Packagingaktion.

Dies ist KEINE native GPU-, Callbackkosten-, FPS-, Fluessigkeits-, Main- oder
Releaseabnahme. Der Nutzer hat weitere Vollbild-/GPUlaeufe zunaechst vertagt.
Produktbasis ist Codecommit `14a7e9188`; Main bleibt als gesonderte offene
Integration auf Referenz `3b12b2878b42d1be0a7a2e8e925cf13835ff1d78`.

## Gepruefte Quellen / Pins

- `scripts/tests/runtime_hitches_r4_20261107_gpu_capture.gd`:
  `cf718bf89758f027ab8fb679b4fad1f836144386bd78b83e13d65a17320690ee`.
- Unveraenderter normaler Basisharness
  `scripts/tests/runtime_hitches_r4_20261107_native_capture.gd`:
  `6b987e9c33a866b751c40a82f7bb3275fe8162ac83aa9fe7073bff8716aa7832`.
- `scripts/tests/package_runtime_hitches_r4_20261107.py`:
  `0d62997fd547308715d1fed55521bf5a18b4b7871a99677778e8bdb47ea6acf4`.
- Von Root bereitgestelltes Delta gegen den Codecheckpoint, mit aktuellem
  Packager abgeglichen:
  `output/runtime_hitches_r4_20261107/checkpoint_packager_delta_20261108.diff.txt`,
  `b16dbe253eb82cfdee76957a6542e36cbd8cf12267584e3dcc1806b182a02b3f`.

R4-Haupttask, Nearest-/HUD-Queue-Vertraege, neue GPU-Diagnosetask sowie die
vorhandene normale Capture-Vererbung wurden einbezogen. Keine ADRreferenz
in den Reviewzielen; kein zusaetzlicher Architektur-/ADRumbau abgenommen.

## GPUharness: Lifecycle, Ressourcen und begrenzte Arbeit

- Neue Subclass laesst normalen Start, Warmup, oeffentliche Commands,
  Gameplayfortschritt und Rendererqualitaet beim unveraenderten Superpfad.
  Der Probe registriert sich vor dessen Warmup und schreibt seinen separaten
  GPUreport erst nach dessen vollstaendiger Rueckkehr.
- Genau zwei feste Viewportrollen, feste API-/Monitorlisten und hoechstens
  16.384 Rohzeilen im Ring. Der Drawcallback liest Timer und elf billige
  Monitore; kein Node-/Renderbudgetscan, Screenshot, Readback, `force_draw`
  oder `sync`. Der gespeicherte `probe_usec` umfasst Zeilenbau und Ablage.
- Viewportreferenzen sind WeakRefs. Jede Messung prueft lebenden Node,
  Treezugehoerigkeit und gleiche RID. Doppelte RIDs werden nicht doppelt
  als Timerowner uebernommen. `stop()` trennt das Signal und deaktiviert
  nur uebernommene Timer auf noch lebender, unveraenderter RID; ein weiterhin
  lebender detached Node kann ebenfalls aufgeraeumt werden. Sceneexit ruft
  denselben Cleanup; die eigene Probenode wird nach Reportbau freigegeben.
- Diese Ownershipabnahme gilt fuer den vorgesehenen frischen isolierten
  Standaloneharness. Es wird kein allgemeines Instrumentierungs-Coownership-
  Protokoll fuer beliebige bereits timerinstrumentierte Editorprozesse behauptet.
- Kein neuer Actor-, Command-, Authority-, Sichtweiten-, Zeitraten- oder
  Qualitaetswrite im Probe. Die geerbten normalen Spielcommands bleiben der
  beabsichtigte Lauf; der neue Observer erzeugt keine zusaetzlichen Spielbefehle.

## Zeitquellen / Interpretation

Die offizielle [Godot-4.6-RenderingServer-Dokumentation](https://docs.godotengine.org/en/4.6/classes/class_renderingserver.html#class-renderingserver-method-viewport-get-measured-render-time-gpu)
wurde fuer Getter, vorherige Messflagaktivierung und Einheiten geprueft:
Viewport-CPU/GPU und globales Render-CPUsetup sind Millisekunden; Script-CPU
ist nicht im Viewport-CPUtimer enthalten. Observerkosten bleiben Mikrosekunden.

Der Bericht bindet das Fenster an den geerbten Start und dessen tatsaechliche
Summarydauer. Warmup und spaetere Beobachtungen werden anhand monotoner Uhr
ausgefiltert; eine Argumentdauer als Fallback ist explizit INEXACT. Ringverlust
wird ausgewiesen. Beobachtungsframe ist keine garantierte GPUframeidentitaet;
letzte Renderframewerte, moegliche Ueberlappung, fehlende/Nullmessungen und
Pipelinezaehler werden entsprechend begrenzt. Keine automatische Addition,
GPUursachenbehauptung oder neue Leistungs-PASSschwelle. Diagnoseabfragen
koennen selbst RenderingServer-Wartezeit verursachen; der Lauf ist ausdruecklich
keine unveraenderte FPSbaseline.

## Packagerdelta und lokale Pruefung

Das Rootdelta enthaelt ausschliesslich Usage/Help, eine erforderliche gegenseitig
ausschliessende Phase `--profile-done` ODER `--native-deferred` sowie die beiden
Manifestfelder `native_phase` und `passed_scope`. Die bestehende Bytekopie,
Hashes, Archive-Readbacks, Quellbindung, Schutzvergleiche und strikte
No-Overwrite-Regeln sind dadurch nicht geaendert. `passed` bleibt explizit auf
Evidencebytes, Quellbindung und Erhalt begrenzt; Deferred behauptet keine
Performance- oder Mainreadiness.

Reviewerpruefung rein im Speicher: Python-AST parsebar; nur die Parser-
Konstruktion aus `main()` ausgefuehrt, keine Paket-/Dateimutation. Vier Faelle
bestehen: keine Phase und beide Phasen werden jeweils mit Exit2 abgelehnt;
jede einzelne Phase wird korrekt angenommen. Der vollstaendige Packager wurde
vom Reviewer nicht gestartet; ein kuenftiges Paket benoetigt seinen eigenen
konkreten Byte-/Readback-/Schutzbeleg.

Roots vorhandener Godot4.6.2-Check-only-Beleg
`output/runtime_hitches_r4_20261107/gpu_parser/20261108T105722Z-70c54c05/parser_report.json`
(SHA256 `e63c0bd4757403021e2f14589f057e8c434b8be52f86a53d0457d8dcfbdb07c0`)
meldet Exit0, Fehler0, gleiche Quellen und unveraenderten echten Roster.
`parser_only=true`, `gpu_runtime_validation=false`: keine ausgefuehrten
GPUassertions und kein nativer Messwert-/Cleanupbeweis. Weitere native
Leistungs-/GPUlaeufe und Mainintegration bleiben offen.
