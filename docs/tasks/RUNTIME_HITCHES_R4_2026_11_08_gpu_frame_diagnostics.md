# R4: separate native GPU-/Renderzeitdiagnose

## Ziel / Problem / Sinnhaftigkeit

Der erste native Nearest-Nachlauf bleibt ein negativer Leistungsbeleg:
321.078ms Maximalframe bei ungefaehr38.6ms Engine-Process und41ms Physics.
Die vorhandenen Controller-/Fog-/Terrain-/Simulationsscopes decken diesen
Walltimeabstand nicht als additive Zeitleiste ab. Daraus folgt weder eine
bestaetigte GPUursache noch eine Schuld eines parallel beobachteten Programms.
Der normale Capturepfad hat bisher ausdruecklich keine GPUframezeiten.

Ziel ist ein gesonderter diagnostischer normaler90-s-Lauf mit echten vorhandenen
RenderingServer-Viewporttimern und den bereits lokal verwendeten billigen
Performancezaehlern. Das ist kein fairer neuer FPS-Vergleich und keine
Produktoptimierung. Root besitzt Engine-/Git-/Integrationsaktionen.

## Umfang / Nicht-Ziele / betroffene Dateien

Nur diese neue Task und
`scripts/tests/runtime_hitches_r4_20261107_gpu_capture.gd`, abgeleitet vom
unveraenderten `runtime_hitches_r4_20261107_native_capture.gd`.
Keine Produkt-, normale Harness-, Runner-, Gameplay-, Actor-, Sichtweiten-,
Qualitaets-, Zeitraten- oder Fensterkonfigurationsaenderung. Der geerbte
regulaere Start-/Roster-/Dropship-/Unload-/Move-/GO-Pfad bleibt bestehen.
Keine automatische Prozessbeendigung, kein Rendererwechsel und kein
neuer RenderingStats-/Runtimeowner. Keine GPUreadbacks, `sync`, `force_draw`,
Screenshots oder vollstaendige Render-/Nodebudgetscans im Diagnosecallback.

## Dokumente / APIvertrag

AGENTS, PROJECT_BRIEF, ARCHITECTURE, CODEX_RULES, IMPLEMENTATION_STATUS,
R4-Haupttask, R4-periodic_hud_queue, R4-nearest_walkable,
`mission_hud_projection_authority_contract.md`,
`performance_deep_pass_research_notes.md` und der lokale Skill
`godot-performance-workflows` gelten.

Root hat die offizielle Godot4.6-Dokumentation geprueft:
https://docs.godotengine.org/en/4.6/classes/class_renderingserver.html#class-renderingserver-method-viewport-get-measured-render-time-gpu
`viewport_set_measure_render_time(rid,true)` ist erforderlich;
`viewport_get_measured_render_time_cpu/gpu` liefern letzte Framewerte in
Millisekunden und ersetzen insbesondere keine Script-CPU-Zeit.
`get_frame_setup_time_cpu` ist global und ebenfalls in Millisekunden.
Root- und Kartenviewportwerte koennen ueberlappen und werden nicht addiert.
Vorhandene aktuelle Engineframe-/Physics-/Controllerzeiten bleiben getrennt.

## Akzeptanzkriterien

1. Die neue Subclass aktiviert nur die Messflags des vorhandenen Root- und
   Kartenviewport-RIDs vor dem geerbten Warmup. Native Renderer-/Methoden-
   Verfuegbarkeit, Node-/RIDidentitaet und wirklich positive Messwerte werden
   getrennt protokolliert. Fehlende/Nullmesswerte sind keine GPUabnahme.
2. Ein vorhandenes `RenderingServer.frame_post_draw`-Signal liefert je Draw
   genau einen begrenzten Samplecallback: monotone Uhr, Engineframe,
   Viewport-CPU/GPUms, globales CPUsetup, die fuenf Pipelinecompilation-
   Monitore und billige Draw/Object/Primitive/Memorymonitore. Callbackkosten
   werden in usec erfasst. Maximal16384 Rohzeilen, kein unbeschraenktes Wachstum.
3. Signal und Messflags werden nach Rueckkehr des Superpfads beendet.
   Sceneexit raeumt ebenfalls auf. Nur noch lebende eigene Viewports mit
   unveraenderter RIDidentitaet werden deaktiviert; keine Zugriffe auf
   freigegebene Nodes oder geerbte fremde RIDs.
4. Das tatsaechliche Messfenster wird nach dem geerbten Lauf aus dessen
   `_profile_start_usec` und `fullscreen_performance.summary.duration_usec`
   bestimmt. Nur Samplezeitpunkte innerhalb dieses Intervalls gelten als
   Messfenster. Eine eventuell noetige Argumentdauer ist explizit als
   ungenauer Fallback markiert. Warmup/Nachlauf/Datei-I/O werden ausgeschlossen.
5. Erst nach dem vollstaendigen Superpfad entsteht ein neues separates
   `*_gpu.json`; vorhandene Datei wird nicht ueberschrieben. Darin stehen
   API-/Renderer-/Lifecycle-/Kapazitaets-/Fensterstatus, Rohzeilen und
   ausdrueckliche Grenzen. Keine neue Millisekunden-/FPS-PASSschwelle.
6. Der normale Harness und aktuelle funktionale75-Gate-Produktpins bleiben
   unveraendert. Autor startet keine Engine/Git und behauptet keinen nativen
   Verfuegbarkeits-/GPU-/Ursachennachweis vor Roots Lauf.

## Lokale Pruefung / Risiken / offener Status

Statischer Source-/Lifecycle-/Diffreview, neue Dateien und Pins an Root.
Root startet danach ausschliesslich den neuen ausgewaehlten Diagnoseharness
mit frischem privatem Profil/Output und unveraenderter normaler Route.
Die Zeitabfrage selbst kann Overhead oder RenderingServer-Threadwartezeit
erzeugen; deshalb sind Samples diagnostisch und nicht als unveraenderte
FPSbaseline ausgewiesen. Letzte Framewerte koennen versetzt sein; Engineframe
und monotone Abfragezeit bezeichnen den Beobachtungszeitpunkt. Pipeline-
Compilations sind Zaehler, keine kompilierten Millisekunden. Ein grosser
Walltimeabstand bei kleinen CPU/GPUwerten klaert Present-/OS-/Scheduling-
Wartezeit nicht allein. Native Verfuegbarkeit, Lauf und Ursache bleiben offen.

## Statischer Freeze zur Rootpruefung

Neuer Harness SHA256
`cf718bf89758f027ab8fb679b4fad1f836144386bd78b83e13d65a17320690ee`.
Das Source-Selbstreview prueft begrenzten Ringpuffer, Frischfensterfilter,
WeakRef-/RID-Lifecycle, Messflagcleanup und fehlende verbotene Draw-/Readback-/
Fullsnapshotaufrufe. Kein lokaler GDScriptparser ist installiert; der Autor
startete keine Engine und behauptet weder Parse- noch native GPUabnahme.
Root muss die erste echte Verfuegbarkeit samt positiven In-window-Werten
und eventuellen Callbackkosten separat belegen. Erst diese Task, danach
ausschliesslich der neue Harness wurden geschrieben. Alle anderen Dateien
blieben durch den Autor unberuehrt.

## Root-Parsercheck und Nutzerdeferral

Root prueft den unveraenderten Harness mit Godot4.6.2 `--headless
--check-only` in einem frischen privaten Projekt-/Userpfad:
`output/runtime_hitches_r4_20261107/gpu_parser/20261108T105722Z-70c54c05/`.
Exit0, keine Parser-/Scriptfehler, stabile Quellen und echter Roster unveraendert.
Dies ist nur ein Parsercheck, keine GPU-Verfuegbarkeits- oder Runtimeabnahme.
Der fehlende Runtimecanary ist im Check-only-Modus ausdruecklich erwartet.

Der Nutzer waehlt am08.11. zunaechst Bericht und Code-Abschluss. Die weiteren
nativen Leistungs-/GPUlaeufe und anschliessende Mainintegration bleiben offen.
