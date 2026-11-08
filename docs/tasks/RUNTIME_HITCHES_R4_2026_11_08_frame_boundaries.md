# R4: beobachtete Process-/Draw-Grenzen im separaten GPUharness

## Ziel / Problem / Sinnhaftigkeit

Der erste native GPUdiagnoselauf
`finish_gpu_native_01/20261108T124012Z-9dd1f9a7` besteht70/0. Er enthaelt
einen359.972-ms-Wallframe bei70.369s; die nahe gelesenen Root-/Karten-
GPUwerte liegen ungefaehr bei0.17/2.5ms. Letzte Framewerte und benachbarte
Scopes bilden jedoch keine komplette additive Timeline. Daraus folgt keine
bestaetigte GPU-, Render-, Present- oder OSursache.

Ein zusaetzlicher vorhandener `frame_pre_draw`-Signalzeitpunkt soll mit
`frame_post_draw` und den vorhandenen Processsamples korreliert werden.
Damit kann Root Beobachtungsabschnitte Process -> PreDraw -> PostDraw ->
naechster Process getrennt untersuchen. Die Grenzen benennen Zeitfenster,
keine alleinige Ursache oder vollstaendige Thread-/GPUauslastung.

## Umfang / Nicht-Ziele / betroffene Dateien

Nur diese neue Task und eine enge additive Ergaenzung von
`scripts/tests/runtime_hitches_r4_20261107_gpu_capture.gd`. Der bestehende
Normalharness, Runner, Produkt, Gameflags, Renderqualitaet, normale Commands,
Rate, Kamera und Fensterkonfiguration bleiben unberuehrt. Keine Engine-/
Gitaktion durch den Agenten. Root bleibt einziger nativer Runner.
Kein `force_draw`, `sync`, Readback, neuer SceneTree-Scan oder zusaetzlicher
Render-Snapshot. Die versiegelten elf QA-Dateien und447 bisherigen Rohdateien
sowie die erste GPUserie bleiben unveraendert.

## Dokumente / Contracts

AGENTS, PROJECT_BRIEF, ARCHITECTURE, CODEX_RULES, IMPLEMENTATION_STATUS,
R4-Haupttask, `RUNTIME_HITCHES_R4_2026_11_08_finish_gpu_main.md`,
`RUNTIME_HITCHES_R4_2026_11_08_gpu_frame_diagnostics.md`,
`mission_hud_projection_authority_contract.md` und der vorhandene
godot-performance-workflows-Messvertrag gelten weiter.

## Akzeptanzkriterien

1. Vor dem vorhandenen Warmup verbindet der Probe bei verfuegbarem Signal
   einen reinen PreDrawcallback. Er merkt nur monotone Zeit, Engineframe,
   Sequenz und eigene kurze Callbackkosten; kein Arraywachstum oder Gameplayread.
2. Jede bestehende PostDrawzeile erhaelt additive Pre-Zeit-/Frame-/Sequenzfelder,
   einen expliziten Matching-/Unavailable-Status und `pre_to_post_usec` nur
   bei frischem Pre im selben Engineframe und monotoner Reihenfolge.
   Fehlender, bereits verbrauchter, falscher Frame oder nichtmonotone Quelle
   wird nicht still als gueltige Dauer behandelt. Vorhandene Postzeit,
   GPU-/CPUwerte und16384er-Ringpuffer bleiben erhalten.
3. Der nachtraegliche genaue Fensterfilter bleibt unveraendert am bestehenden
   PostDrawbeobachtungszeitpunkt. Ein zugeordnetes Pre ausserhalb des echten
   Messfensters wird gesondert markiert. In-window-Matchingstatuszaehler werden
   erst nach der Messung aggregiert. Unverifizierte GPUframezuordnung bleibt
   von gleichem beobachtetem Engineframe getrennt.
4. Cleanup und Sceneexit entfernen beide Signalhandler; bisheriger
   WeakRef-/RID-/Messflagcleanup bleibt erhalten. Keine fremden/ersetzten
   Viewports werden deaktiviert. Neue JSON-Ausgabe erfolgt weiter erst nach
   dem Superlauf und ueberschreibt keine vorhandene Datei.
5. Der neue Sourcefreeze wird Root fuer enge Pruefung und einen frischen
   nativen Diagnoselauf uebergeben. Kein alleiniger positiver GPUwert, kleiner
   Median oder neue Boundarydauer wird als FPSgewinn oder Ursachennachweis
   ausgegeben. Alte cf718-GPUevidence wird nicht umgeschrieben.

## Lokale Pruefung / Risiken / offener Status

Statisches Review des additiven Deltas gegen den aktuell nativ gelaufenen
Harnesspin `cf718bf89758f027ab8fb679b4fad1f836144386bd78b83e13d65a17320690ee`.
Root prueft danach frische Nativequelle, Matches/Unavailablezaehler, Cleanup,
Normalroute und gueltige Fenstergrenzen. Der Autor startet keine Engine.

Die Postprobe-Kosten enthalten nicht die separate Preprobe; beide werden
getrennt benannt. Das Pre->Post-Wandintervall kann RenderingServer-/Present-
oder Schedulingwartezeiten einschliessen und ist keine gemessene GPUdauer.
Der naechste Processsample kann auf einer anderen Engineframegrenze liegen;
die Rohzeiten muessen vor einer Interpretation gematcht werden. Neue native
Funktions-/Boundary-/Ursachennachweise stehen bis Roots Lauf aus.

## Zusaetzliche enge Diagnose vor erstem Boundary-Nativlauf

Ein Kollege ordnet den Peak rechnerisch ein:
70.369270s minus359.972ms ergibt70.009298s, den Progresszweig im Originallog.
Der normale Parent ruft dort nach der bisherigen `probe_usec`-Messung
`_display_facts()`, JSONserialisierung und `print` auf. `_display_facts`
enthaelt unter anderem Displayrefreshrate, CPUname und GPUname. Die zeitliche
Nahe ist ein Pruefansatz; andere lange Frames liegen nicht ausschliesslich
im Zehnsekundenraster. Kein weiterer Produktbefund wird daraus abgeleitet.

Root autorisiert vor dem ersten Boundarylauf zusaetzlich nur einen
`_display_facts() -> Dictionary`-Override im bestehenden GPUchild. Er liest
monotone Zeit unmittelbar vor/nach dem echten Superaufruf und merkt dessen
Start-/Ende-/Dauer-/Engineframedaten in maximal64 Records. Der Super-Dictionary
wird unveraendert zurueckgegeben. Kein Cache, kein Schatten von `print` und
keine Parent-/Runner-/Produktanpassung. Wrapper-/Speicheraufwand und verworfene
Records bleiben vom gemessenen Superaufruf abgegrenzt.

Erst nach dem Superprofil werden diese Records der separaten GPUevidence
hinzugefuegt. Jeder Record markiert vollstaendig innerhalb, teilweise
ueberlappend oder ausserhalb des genauen bestehenden Messfensters; Rohzeiten
bleiben erhalten. Eine gemessene Displayfact-Dauer beweist nur den konkreten
Superaufruf und nicht automatisch JSON-/Printkosten oder die Ursache aller
Hitches. Der bisherige Boundarypinfe385 ist noch nicht nativ getestet.

## Statischer Freeze vor Displayfacts-Ergaenzung

Harness SHA256
`fe38527fd8c21818e9815b2b95eec289d2945a18479aaca24f3e10c3e7f19697`.
Im direkten Sourcevergleich bleiben alle bisherigen Zeilen in ihrer
Reihenfolge erhalten; nur der bisher inline gelesene Post-Engineframe wird
einmal lokal erfasst und mit derselben Variable publiziert. Der uebrige Delta
ist additiv: konstanter Prezustand, Signalregistration/-cleanup, rohe
Matchingdaten und Aggregation nach der Messung. Beide Handler besitzen
explizites Disconnect; verbotene Draw-/Readback-/Fullsnapshotaufrufe fehlen.
Normaler R4-Capturepin `6b987e9c...` und Basiscapturepin `99b3526b...` wurden
unveraendert zurueckgelesen. Keine Engine-/Gitaktion oder native Abnahme durch
den Autor. Root prueft die neue Quelle nativ; der alte70/0-Lauf gilt fuercf718.

## Aktueller Freeze inklusive Displayfacts-Timing

Harness SHA256
`68b4f3521a3e8a51b46c27e0d088c822edade1f883f7dc00b89069513c1a9424`.
Der neue aeussere Override ruft den echten Super exakt einmal auf und gibt
denselben Dictionary unveraendert zurueck. Maximal64 Records, keine Cache-
oder Printaenderung. Das separate `display_facts_calls`-Objekt wird erst nach
dem geerbten Profil mit inside/partial/outside beziehungsweise unavailable-
Fensterstatus und exakter Overlapdauer erzeugt. Keine neuen nativen
Ergebnisse oder Ursachenaussagen; Root muss diesen aktuellen Pin erst testen.
