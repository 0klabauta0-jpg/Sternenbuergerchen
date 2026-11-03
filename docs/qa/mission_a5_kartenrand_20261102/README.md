# Mission A5 / Kartenrand – Nachweise

Die13 ausgewählten Engine-Gates, beide normalen Vulkan-Starts und der zusätzliche tatsächliche Westmarsch sind bestanden. Separate Vulkan-Fixtures prüfen sämtliche FoW-Maskenslots und die nachgelagert korrigierten UI-Eingabefilter. Die neue Bildserie ist direkt gegen A5 geprüft; die fertige HTML-Workbench besteht10/10Offline-VM-Prüfungen einschließlich JSON-Export/Import. Das gestalterische Nutzerurteil bleibt offen. Diese getrennten Belegarten werden unten einzeln ausgewiesen.

Root führt sämtliche Engineprozesse ausschließlich nacheinander aus. Jeder Aufruf verwendet neue UTC-Ausgabeordner und eine eigene Test-Userdir. `project.godot` wird nach jedem Prozess, Fehler oder Timeout bytegenau wiederhergestellt. Vorhandene eigene Userdir bedeutet Abbruch statt verschachtelter Engineprozesse. GDExtensions bleiben aktiv; nur der Import deaktiviert temporär Editorplugins.

Die Runde arbeitet auf `task/mission-a5-kartenrand-20261102`, bewusst auf unintegriertem `a6802ea5c`. Alte Karten-/UI-Bilder, Logs und Quellenpins bleiben erhalten. Der spätere Git-Abschluss umfasst nur die ausdrücklich ausgewählten Taskquellen und Nachweise; Quellenhashes und echte Indexblobs werden davor getrennt geprüft. Hauptcheckout/Main, fremdes WIP, Saves und alte Baselines gehören nicht zu diesem Integrationsumfang.

## Abschließende technische Gate-Ergebnisse

Godot `4.6.2.stable.official.71f334935`: **13/13 Gates, 1398 Assertions, 0 Fehler**, jeweils Exit0, erwarteter Marker und keine gemeldeten Script-/Leakfehler. Gewählter Bericht: `headless/20261102T192409_938300Z/checks/20261102T192410Z-pid142844/metadata/report.json`. Die zugehörige `profile_isolation.json` bestätigt eigene Userdir und bytegenau wiederhergestellte Projektkonfiguration. Der frühere11/11-Lauf bleibt historisch erhalten.

| Gate | Bestandene Assertions |
|---|---:|
| Kartenabhängiger Cover-/Kompatibilitätspfad | 29 |
| Kartenabhängiger Missionsstart-/Kompatibilitätspfad | 28 |
| Stabile A*-Frontier / gerichteter Kostenkontext | 114 |
| Exakte alte/neue HPA-Pfade / Pruning / Cacheverträge | 331 |
| Tatsächlicher Kartenrand und gespeicherte Bodenabdeckung | 51 |
| GM01-Neuaufbau / Roundtrip | 77 |
| FoW-CPU-State und Lebenszyklus | 52 |
| Hex-Minimap | 13 |
| Natives A5-HUD | 356 |
| Referenzgruppen / Portraits / Transportdetails / Protokoll / Tooltipfilter | 112 |
| R2-Missionsfeedback | 86 |
| R3-Readout | 116 |
| Exakte Cutlassidentität | 33 |

Die größere Karte legte hohe Kosten im vorhandenen HPA-/A*-Pfad offen. Das begrenzte Hex-Pruning verwendet konservative Schrittkostenuntergrenzen; Gleichstände und nichtendliche Eingaben behalten die bisherige Auswertung. Die stabile Priorityqueue erhält die bisherige Einfügereihenfolge einschließlich Decrease-Key und Reopen; NaN fällt auf den alten linearen Vergleich zurück. Die Verifier vergleichen vollständige geordnete Pfadarrays und Status gegen separat geladene, bytegepinnt alte HPA-/TerrainPathfinderquellen.

Gerichtete Schrittkosten und Begehbarkeit sowie fünf reine Zielzellkomponenten werden innerhalb eines synchronen öffentlichen HPA-Aufrufs in einem frischen typgeprüften Kontext wiederverwendet. Die Aufruferoptionen werden flach kopiert, Registryidentität und Terrainrevision vor Wiederverwendung geprüft; Änderung leert alle drei Querycaches. Vor-/Rückrichtung, gemischte Höhenzugänge, Hex-/Legacydiagonalen, Runtimeoverride und neue Registry werden separat geprüft. Dieser Arbeitskontext wird weder Instanzzustand noch Teil des Ergebnisses/Snapshots. Die bisherige Reihenfolge Surface/Höhe → Coverclamp → Corridor → Lane → Clearance → Legacydiagonalfaktor bleibt erhalten.

Eine danach gemessene Häufung identischer vollständiger Abfragen begründet zusätzlich den ausdrücklich im Task ergänzten abgeleiteten **HPA-Ergebniscache mit maximal64 FIFO-Einträgen**. Er bindet sich an identische Registry und identischen Graph per WeakRef sowie beide Integerrevisionen; Wechsel invalidiert den ganzen Scope. Der verlustfreie Variantbytes-Schlüssel enthält Start/Ziel und sämtliche Optionen außer dem rein diagnostischen Top-Level-Eintrag und dem ohnehin ersetzten privaten Querykontext. Nahe Floatwerte, verschachtelte Kostenmaps und Arrayreihenfolgen bleiben verschieden; nichtendliche, nicht unterstützte, objektbasierte oder zyklische/zu tiefe Eingaben gehen am Ergebniscache vorbei. Vor Store werden beide Revisionen erneut geprüft. Nur erfolgreiche nichtleere `hpa`-/`same_component`-Pfade werden gespeichert, Fehler nicht; Store und jede Rückgabe sind tiefe Kopien. Verifier sichern Miss-/Hit-Aliasing,64erFIFO ohne Hit-Promotion, Registry-/Graphidentität und Revisionen, Schlüsselvollständigkeit und Fehlerbypass gegen die alten Quellen ab.

Der aktuelle HPA-Verifierlauf protokolliert2849 alte gegenüber1264 neuen lokalen A*-Auswertungen,1252 sicher verworfene Kandidaten sowie180965 Schritt-,199834 Traversability- und13301 Zielzellentreffer. Diese Zähler gelten für genau seine erweiterte Fallauswahl; sie sind kein Gesamt-FPS- oder Langzeitnachweis.

## Begrenzte Kostenmessung

`PERFORMANCE_SCOPED.json` verknüpft je einen passenden Opt-in-Headlesslauf vor/nach dem Ergebniscache (`diagnostic_r3/20261102T190213_065310Z/` und `20261102T191223_877001Z/`). Im gleichen GO-Abschnitt mit16Processframes und8Physikticks jeFrame wurden96Abfragen über32beobachtete Queryticks aufgezeichnet. Ihre summierte Wallclockzeit einschließlich kaltem Graphsetup sank von **7,429780s auf1,558615s**; der ganze beobachtete Abschnitt von **10,191s auf4,400s**. Beide Diagnosefälle haben null Fehler. Das ist ein einzelnes Paar derselben begrenzten Fixturesequenz, keine Messverteilung, native FPS-Aussage oder Freigabe der Gesamtperformance.

## FoW: CPU-State und tatsächliche Vulkan-Slots

Der Headlesslauf prüft alle 9408 finalen Zellenzustände, unabhängige Zähler, aktuelle Revision, Kontakt-/Eventfilter und den Maskenlebenszyklus. Während der Initialisierung werden in jedem Frame vollständige Sicht-/Erkundungssnapshots mit Revisionssprüngen publiziert; frühe bereits gebaute sowie späte noch offene Slots wechseln. Known/Alpha, Unknown/Alpha und Unknown/Beta schließen jeweils **genau einen Aufbau in19Frames** innerhalb der unveränderten48Framegrenze ab. Der512erCursor bleibt erhalten. Reine Kontaktänderungen starten die Bodenmaske weder während noch nach dem Aufbau neu. Known bekommt keinen schwarzen Schutzkasten; Unknown behält seinen Schutz bis zur fertigen Maske.

Headless verwendet hier Dummy-Readback: GPU-Transforms werden als null und Farben als Standardalpha1 zurückgegeben. Deshalb meldet der Headlessbericht den tatsächlichen Slot-Readback ausdrücklich als `FOW_RENDERED_SLOTS_SKIPPED` mit `rendered_evidence:false`; CPU-State und Zähler werden vollständig weiter geprüft.

Der zusätzliche Lauf unter `rendered_fow/20261102T183817_216973Z/` verwendet **Vulkan Forward+ auf NVIDIA GeForce RTX4070TiSUPER**, eigene Userdir und `--require-rendered-slots`, ohne `--headless`. `process.json` und `fow.log` belegen **56/56 Prüfungen**, Exit0, keine erkannten Fehler sowie `GM01_HEX_FOW_RENDERED_ALL_PASS`. Das sind die52 wiederholten CPU-Prüfungen plus drei echte Prüfungen aller Slot-Alpha-/Transformwerte und eine explizite Backendprüfung. Auch dort dauern die drei kontinuierlich aktualisierten Aufbauten je19Frames. Dies ist ein eigener Renderer-State-Fixturebeleg ohne Runtimeakteure, kein normaler Transport- oder Truppmarsch.

## Aufbewahrte Fehlvorläufe und Einordnung

- Der Gruppenlauf `172912` meldete vier LZ-/Fokusfehler. Echte Layoutframes zwischen Popupschließen, öffentlicher Hydrierung und erneutem Öffnen korrigierten die Fixture-Sequenzierung; die Prüfung wurde beibehalten. Separat zeigte die R3-Diagnose `180648` tatsächlich vorhandenen sichtbaren Transporttext mit nur1px Höhe und null zeichnbaren Zeilen im leeren NoPreview-Zustand. Der Fontmetrikfix bestand die Empty-Prüfung bei1920/1280 in `181042`. Der Gruppenlauf `181409` scheiterte anschließend am neuen langen Klassentitel: der DTO fehlte `craft_type` und der Formatierer erhielt kein `role="dropship"`, sodass die Cutlassklasse im Titel entfiel. Ein Rollenfallback wie im Texturpfad stellt Klasse plus Originalname wieder her. Die unveränderte Zweizeilenprüfung sowie zusätzliche Klassen-/Namensassertions bestanden zunächst80/80 und sind im nun erweiterten112/112-Gruppenlauf erhalten. Keine kanonische Namenskürzung wurde als Ursache unterstellt.
- Frühe R3-Läufe überschritten ihre Zeitgrenze. Die großen wiederholten HPA-Kosten wurden gezielt untersucht und wie oben begrenzt korrigiert. Diagnoseprofile unter `diagnostic_r3/` sind eng umrissene Fixturemessungen und keine native Gesamtperformanceabnahme.
- `normal_start/20261102T181951_188271Z/1920x1080/` wurde mit59 bestandenen und4 fehlgeschlagenen Checks verworfen: Detailszugriff, ausstehender FoW-Aufbau nach Entladung, Portraitzugriff und Startvoraussetzung der Randprobe. Die FoW-Ursache war ein erneuter Aufbau ab Cursor0 bei neuen Sichtzuständen bewegter Trupps. Der neue vollständige Snapshotabgleich hält den Fortschritt bei gleichbleibendem Modus/Team/Overlay; Modus-/Teamwechsel behalten den ursprünglichen vollständigen Aufbau.
- Runde2 unter `normal_start/20261102T183831_403205Z/1920x1080/` bestand den ursprünglichen Transport-/Details-/FoW-/GO-Pfad, verfehlte jedoch beide zusätzlichen Randmarschassertions nach60,009s (83Pass/2Fail). Die drei Originalakteure wurden weiter unverändert beobachtet, waren aber noch östlich der alten Grenze. Die teuren realen Navigationsabfragen wurden anschließend wie oben beschrieben korrigiert; Zeitlimit und Akteurs-/Zielkriterien blieben gleich. Der akzeptierte dritte Lauf ist getrennt unten belegt.
- `headless/20261102T183200_850827Z/` und `headless/20261102T183333_175250Z/` enthalten jeweils drei rote kombinierte State-/GPU-Slotprüfungen. Die ergänzten Diagnosen zeigen korrekte CPU-Zustände/Zähler bei den beschriebenen Dummy-Rückgabewerten. Die Assertions für echte Render-Slots wurden beibehalten und im separaten Vulkanlauf tatsächlich bestanden; Headless wird dafür nicht als Renderbeleg ausgegeben.

Die QA-Wurzel besitzt `.gdignore`, damit alte/neue Nachweis-PNGs keine großen zusätzlichen Godot-Importläufe auslösen. Raw-PNG-/JSON-Belege werden weiterhin direkt per Dateizugriff gelesen und in HTML verlinkt; sie werden dadurch nicht zu importierten Runtimeassets.

## Ausführen

```powershell
python docs/qa/mission_a5_kartenrand_20261102/import_once.py
python docs/qa/mission_a5_kartenrand_20261102/run_isolated_checks.py --skip-import
python docs/qa/mission_a5_kartenrand_20261102/rendered_fow.py
python docs/qa/mission_a5_kartenrand_20261102/rendered_groups.py
python docs/qa/mission_a5_kartenrand_20261102/startup_a5.py --verbose-engine
python docs/qa/mission_a5_kartenrand_20261102/build_report.py
node docs/qa/mission_a5_kartenrand_20261102/html_qa.cjs
```

`--skip-import` nur nach erfolgreichem Import desselben unveränderten Quellstands. Der Checksrunner verwendet den installierten `godot-game-verification`-Skill mit bounded sequentiellen Läufen; Marker, Exit0 und fehlende Script-/Leakfehler sind erforderlich. Kleinste passende Auswahl per `--filter <Teilstring>`. Ergebnis liegt unter `headless/<UTC>/checks/<Runner-UTC>/metadata/report.json`; Runnerlog und Profilwiederherstellung daneben. Die aktuelle Auswahl steht in `checks_final.json`. Der Referenzgruppen-Verifier sichert Portrait-ID, fehlenden Doppelstreifen, Transportdetails, mehrere Schiffe, Popup-/Lightrefresh-Verhalten und Protokollfilter ab. `rendered_fow.py` verlangt anschließend zusätzlich einen tatsächlichen Vulkanlauf des FoW-Verifiers und seinen eigenen Render-Marker.

## Normaler Start und zusätzlicher Randmarsch

Akzeptierte Runde3: `normal_start/20261102T191425_077481Z/capture_results.json`, **155/155 Harnesschecks**:1920×1080 mit84/84 und1280×720 mit71/71, jeweils Windows/Vulkan, Exit0, eigene Userdir, bytegenaue Projektwiederherstellung und keine erkannten Engine-/Leakfehler. Beide zeigen die echte normale Menü-/Heimatbasis-/Transfer-/LZ-/Cutlass-/Auslade-/GO-Route sowie erreichbare Transport- und Charakterdetails.

Nur bei1920 folgte der zusätzliche tatsächliche Westmarsch. Alle drei ursprünglichen IDs blieben beobachtet; zwei überschritten x<−0,05, einer erreichte die festgelegte Nähe von2physischen Einheiten zu Hex(−8,12). Gemessen wurden **39,839s und1088Simulationsticks**, innerhalb derselben60sGrenze. `facts.edge_walk_probe` enthält die vollständigen tatsächlichen Vorher-/Nachherpositionen und den begehbaren gespeicherten Zielhex. Bei1280 ist diese Zusatzprobe ausdrücklich nicht angefordert; dort wird kein zweiter Randmarsch behauptet.

`startup_a5.py` rendert echte logische und physische 1920×1080 und 1280×720 mit Vulkan. Bestehender normaler Pfad: Menü → Heimatbasis → gespeicherte GM01 → echter zeitgesteuerter Transport → LZ → Cutlassanflug → Ausladen → Move/GO. Die bisherigen Transfer-/Auslade-/initialen GO-Zeitfenster bleiben bestehen. Keine Actor-, HP-, Fog-, Positions- oder Simulationstimerpatches; keine Zeitbeschleunigung.

Nach03 öffnet der vorhandene Dropship-Detailsbutton seine wirkliche native Popupfläche (`03b_dropship_details`) und schließt sie über den vorhandenen Closebutton vor der weiteren normalen Droproute. Nach05 öffnet ein echter `gui_input`-Doppelklickcallback eines sichtbaren Portraits den bestehenden Charakterbogen derselben Original-Unit-ID (`05b_character_details`) und schließt ihn über den bestehenden Controllerpfad. Keine Pause, keine Actor- oder Timerwrites; dies ist ein GUI-Callback-/Sichtbeleg, kein Betriebssystem-Maustest.

Vor jeder Missionaufnahme wartet der Adapter rein lesend bis zum Abschluss des tatsächlichen initialen FoW-Batchaufbaus, höchstens48Frames. Er setzt weder Sichtmodus noch Maske; Warteframes stehen proCapture in den Facts.

Nach `06_go_movement` folgen die vergleichbaren Kamerabilder07 Außenposten,08 Ostversorgung und09 zentraler erweiterter Ausschnitt.09 ist **keine Gesamtansicht der neuen Karte**. Zusätzlich bei1920:10 `all_saved_hexes` liest alle tatsächlichen gespeicherten Zellen und zeigt deren vollständige Bounds mit reiner Kameraänderung.

Standard `--edge-walk auto` führt nur bei1920 anschließend einen weiteren echten Move/GO auf Hex(-8,12) aus, physisch westlich der früheren x=0-Grenze. Der eigens zusätzliche Auftrag erhält nach Bestehen der ursprünglichen Route maximal60Wallclocksekunden. Mindestens zwei der ursprünglichen tatsächlich ausgeladenen Akteure müssen die alte Westgrenze passieren; mindestens einer muss in Zielnähe sein. Die aufgezeichneten realen Vorher-/Nachherpositionen und der gespeicherte walkable Zielhex werden in `facts.edge_walk_probe` festgehalten.11 `old_border_crossed` zeigt das tatsächliche Ergebnis. Die Prozessobergrenze300s umfasst diese zusätzliche Probe; sie lockert keine zuvor bestandenen ursprünglichen Schritte.

`--edge-walk off` prüft nur den unveränderten Normalstart; `--edge-walk on` aktiviert die Zusatzprobe auch bei1280. In jedem Fall sind ausgeführte und nicht ausgeführte Randmärsche im Manifest getrennt gekennzeichnet. `--sizes 1280x720` ist ein zulässiger Teilaufruf.350ms Audiofreigabe erfolgen ausschließlich nach Freigabe der Spielszene, wie in der vorigen Runde nachgewiesen.

Captures bleiben unter `normal_start/<UTC>/<Größe>/startup_captures/`. Das jeweils zugehörige `capture_results.json` und `startup.json` enthalten Maße, SHA-256, echte Kamera-/Render-/Boundsbeobachtungen und Prozessstatus. Der HTML-Builder verweigert ältere Erfolgsbilder, wenn ein neuerer Prozessversuch derselben Auflösung nicht akzeptiert wurde.

## Nachgelagerter Tooltip-Eingabefix: eigener Quellenstand

Die akzeptierten PNGs und Normalstarts beziehen sich auf Controller-SHA `43fc11daa4b28048d5d95ff9251ff510231edb457042504a61029cc1e9784d3c`, unverändert gesichert in `before/controller_before_tooltip.gd.txt`. Danach wurde exakt ein vorhandener Styleaufruf hinter den rekursiven Legacy-`MOUSE_FILTER_IGNORE`-Aufruf verschoben, damit Volltextnamenslabels tatsächlich `MOUSE_FILTER_PASS` behalten. Der aktuelle Controller besitzt SHA `aca669d0674e1d18657aae29ec9421f8b7db88ddeb8b6efaeb0ff8d090300595`. `POST_CAPTURE_INPUT_FIX.json` belegt die einzelne Aufrufverlagerung; Geometrie, Texte, Assets, Renderer und Gameplay wurden dafür nicht geändert. Die früheren PNGs werden nicht mit dem späteren Controllerhash versehen.

Der aktuelle Quellenstand besteht den oben genannten112/112-Headless-Gruppencheck. Zusätzlich bestätigt `rendered_groups/20261102T192710_063100Z/` unter Windows/Vulkan **113/113** mit zusätzlicher expliziter Backendprüfung, Exit0, keinen erkannten Fehlern und `A5_REFERENCE_GROUPS_RENDERED_ALL_PASS`. `process.json` fixiert aktuelle Controller-/Presenter-/Verifierhashes und bestätigt unveränderte Quellen während des Laufs. Die GUI-Fixtures prüfen native Rects/Schrift, echte Callbacks, Fokus, Scroll und Tooltip-Hitfilter über Refreshes. Das ist ein separater Input-/UI-Statebeleg, kein erneut gestarteter vollständiger Transportmarsch und kein Betriebssystem-Hovernachweis.

## Workbench

`docs/reports/STERNENBUERGERCHEN_MISSION_A5_2026-11-02.html` ist aus dem bestehenden Workbench-Template erzeugt: Übersicht, Original/Engine-Vergleich, Prüfung/Notizen. A5-Original, unveränderter vorheriger Stand und neue echte Aufnahme bei beiden Auflösungen; Vollkarte und tatsächlich ausgeführter Randmarsch separat. Alle Bildhashes und echte Kartengröße stammen aus den Nachweisen. Keine externen Laufzeitabhängigkeiten. JSON exportiert ausschließlich Arbeitsnotizen, keine Spielwahrheit.

`html_qa.cjs` führt das wirkliche Template-JavaScript mit synthetischem DOM in Node aus und prüft Tabs, Bild-/Metadatenhashes, Unicode-Notizen, Import, Kopieren und Download-/Textfallback. Das ist keine Browserlayout-, echte Browserdownload- oder Godotprüfung.

`html_export_qa.json` bestätigt **10/10 PASS** für den fertigen Report mit SHA `bd29eb307e0385123c67dbe25d02c2aa75771c86a6caa2bc0247b12484ec7745`. Export/Import mit19Bedienfeldern erhält auch Notizen versteckter Tabs, Unicode und offene manuelle Urteile; Import verändert keine technischen Nachweise. Der dokumentierte Status ist ausdrücklich `NOT_RUN_OFFLINE_DOM_ONLY`: tatsächliches Browserlayout, Betriebssystemablage und echte Browserdownloads wurden damit nicht geprüft.

## Direkte Bildprüfung und offene gestalterische Urteile

Direkt geöffnet wurden das A5-Original sowie jeweils `06_go_movement`, `03b_dropship_details` und `05b_character_details` bei1280/1920 aus der akzeptierten Runde3. Keine sichtbare Panelüberlappung oder abgeschnittene Close-/LZ-/Feuerregelcontrols. Das Band beginnt links unten, die echte3/3-Portraitkarte sitzt darüber und der NPC-Doppelstreifen fehlt. Cutlass/Ziel oben rechts und Protokoll über dem Band folgen der A5-Komposition erkennbar näher. Die Hexlinien reichen sichtbar bis zur tatsächlichen Bodenaußenkante; ein inneres Rasterende oder schwarzes Maskenquadrat ist in diesen Aufnahmen nicht vorhanden. Die Transportdetailkarten füllen ihre Popupbreite; der1280-Charakterbogen nutzt die volle Viewporthöhe mit sichtbarem Closebutton und Scrollbar.

Der verbleibende Abstand ist deutlich: Die Weltkamera steht weiter entfernt, große Sandflächen dominieren stärker, Felsen und Portraits folgen weiterhin der Lowpoly-/Pixelsprache. Das Raster wirkt kräftig gepunktet statt sehr dezent. Technische/englische Detailköpfe wie `#19`, `CHARACTER OVERLAY` und `Passengers/ETA` bleiben sichtbar. Deshalb wird keine vollständige stilistische Zieltreue behauptet. Das folgende Raster und die Workbenchfelder dienen weiterhin dem eigenständigen Nutzerurteil.

| Schwerpunkt | Sichtbar prüfen | Getrennter Funktionsnachweis |
|---|---|---|
| Tatsächlicher Kartenrand | Freier sichtbarer Sand gehört bis zur Außenkante zur gespeicherten Hexunion. Im Spielausschnitt kein inneres Rasterende vor weiterer sichtbarer Dekofläche. | Groundmesh-Polygone entsprechen gespeicherten Zellen; Picker, negative Koordinaten, sechs Nachbarn, A*/HPA, FoW, Roundtrip. Der echte Westmarsch belegt genau diesen Weg. |
| Fireteams links unten | Teamkennung/echte Belegung, große zusammengehörige Portraitreihe, ein kurzer bestätigter Zustand. Über dem Band und kein zusätzlicher NPC-Streifen quer über die Karte. | Auswahl, mehrere tatsächlich vorhandene Teams, Doppelklick zur ursprünglichen Unit-ID und vollständig erreichbarer Charakterbogen. Keine Konzeptpersonen erfinden. |
| Kompakte Cutlass oben rechts | Ganze echte Cutlasssilhouette, lesbarer Hauptzustand und Lande-/Dropaktion; Primärkarte nimmt möglichst wenig Kartenfläche ein. | Unveränderte Gates/Callbacks; mehr Schiffe, Richtung und zusätzliche Werkzeuge im nativen Details-Popup. Fokus, LZ-Routing und Close über Refreshes geprüft. |
| Protokoll rechts über dem Band | Kurzer Kopf und wenige lesbare reale Ereigniszeilen; ruhige Petrolfläche, keine technischen IDs als Haupttitel. | Filter und vollständige lange Meldung in Tooltip/Detail/Scroll bleiben vorhanden. Keine erfundenen Zeitstempel oder Erfolge. |
| Schmale Haltung/Feuerregel | Vollständige Wörter Vorsichtig/Normal/Offensiv als engere Gruppe direkt unter Teamidentität; keine Überlappung mit Ziel-/Befehlsblock. | Bestätigte Regel, Pending/Reject/Timeout und gemischte Auswahl bleiben korrekt und lesbar; keine erfolgreiche Änderung vortäuschen. |

Die Workbench enthält je Bereich ein eigenes offenes Urteil mit Notiz sowie getrennte Gesamtfelder für HUD und Kartenrand. Alle Werte bleiben Arbeitsnotizen und ändern keine Spielwahrheit.

## Offene Belegpfade vor Report-/Quellenfreigabe

- `normal_start/<UTC>/capture_results.json` muss akzeptierte Einträge beider echten Auflösungen enthalten. Das zugehörige `startup.json` muss zum **aktuellen** Karten-SHA passen; ein neuerer abgelehnter Prozessversuch verhindert stillen Rückgriff auf ältere Bilder.
- Pflichtbilder in beiden Größen: `03b_dropship_details`, `05b_character_details`, `06_go_movement`, `07_outpost_overview`, `08_eastern_supply`, `09_expanded_map`. Zusätzlich1920: `10_all_saved_hexes`; bei angefordertem tatsächlichem Randmarsch `11_old_border_crossed` und bestandene Positionsbeobachtung.
- Headless-Nachweise entstehen unter `headless/<UTC>/checks/<Runner-UTC>/metadata/report.json`; der Builder liest die letzte Meldung je aktuellem Manifestgate, einschließlich neuer HPA-/eventueller Queue-Gates. Fehlende oder rote Gates bleiben sichtbar. Der Quellen-Snapshot verweigert das Einfrieren, solange die gewählte Auswahl nicht vollständig grün ist.
- Der separate Vulkan-FoW-Nachweis benötigt zusätzlich `rendered_fow/<UTC>/process.json` mit bestätigtem echtem Backend und das dazugehörige `fow.log` mit `GM01_HEX_FOW_RENDERED_ALL_PASS`. Er wird als eigener State-Fixturebeleg referenziert und zusammen mit `rendered_fow.py` ausdrücklich in den finalen Quellen-/Nachweisumfang aufgenommen.
- Der vollständige Offline-HTML-VM-Test ist für die tatsächlich erzeugte neue HTML10/10grün und wird über `html_export_qa.json` mit dem passenden Reporthash eingefroren. Eine Browserprüfung und das eigenständige gestalterische Nutzerurteil sind davon getrennt.

## Quellen einfrieren

Erst nach endgültiger Dokumentation und akzeptierten neuen Nachweisen:

```powershell
python docs/qa/mission_a5_kartenrand_20261102/source_snapshot.py --record --normal-result <normal_start/.../capture_results.json> --report docs/reports/STERNENBUERGERCHEN_MISSION_A5_2026-11-02.html
python docs/qa/mission_a5_kartenrand_20261102/source_snapshot.py
```

`--record` ist ausdrücklich nötig und verweigert existierende Snapshotdateien. Der Standardaufruf prüft nur die eingefrorenen Hashes. Neben den festen Gameplay-/Karten-/Cutlassquellen und gewählten Captures werden betroffene tracked Quellen und neue GDScript-/Shaderquellen aus `scripts/` sowie die tatsächlich gewählten Gateberichte erfasst; kein rekursiver Assetscan. Zusätzliche Belege/Assets mit `--source <Pfad>` explizit auswählen. Nach selektivem Staging prüft `check_index.py` alle eingefrorenen Dateien gegen echte Git-Blobbytes und erzeugt `INDEX_PROOF.json`; es verändert keine Pins.

## Grenzen

Neue technische Grünmeldungen sind keine gestalterische Nutzerfreigabe. Vollständiges Lesen/Anklicken der A5-Karten, mehrere Teams/Schiffe, alle Zoomstufen und sichtbare Rasterdezenz brauchen gezielte native/menschliche Prüfung. Ein zusätzlicher Marsch beweist genau diesen realen Weg, keine vollständige Kampagne oder jedes Randhex. Keine allgemeine Performance-, Balance-, Multiplayer-, EXE-, Release- oder Mainintegrationsabnahme.
