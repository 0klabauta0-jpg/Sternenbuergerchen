# Vollbild-Hakeln: Reproduktion und Ursachenbeleg

## Ziel / Problem
Der Nutzer sieht bei der Figurenbewegung etwa alle zwei Sekunden einen Ruck.
Der normale GM01-Pfad soll im echten Vollbild bei unveraendertem 1x-Spieltempo
gemessen werden, bevor eine konkrete Runtime- oder Navigationsursache korrigiert wird.

## Sinn / Umfang / Nicht-Ziele
Der Messhelper erbt den echten Menue-/Homebase-/Transport-/Move-/GO-Pfad von
`ui_zielbild_normal_capture.gd` und behaelt dessen exakten privaten
QA-Verzeichnisguard. Nach natuerlichem Deployment folgen drei Sekunden Warmup
und 90 Sekunden reale Messzeit. Alle zwoelf Sekunden wird derselbe kurze,
autoritative, begehbare Pfad per vorhandener Move-/GO-Aktion hin/zurueck geplant.
Keine direkte Actor-, HP-, Zeit-, Transportphasen-, Navigationsbudget- oder
Spieltempoaenderung. Keine Grafikqualitaetssenkung. Kein allgemeines FPS-/Releasegate.

## Dokumente / Contracts
AGENTS, PROJECT_BRIEF, ARCHITECTURE, CODEX_RULES, IMPLEMENTATION_STATUS,
TASK_ROADMAP; `performance_manual_profile_checklist.md`, Simulation-/Navigation-
Profilberichte und Haupttask `PLAYTEST_2026_11_05_fullscreen_ux_visuals.md`.

## Akzeptanz
- Window-/DisplayServer-Modus ist echtes Vollbild; aktive Displaygroesse,
  Window-/Viewportgroesse, Engine, Renderer, CPU/GPU und Sourcepins werden erfasst.
- Rohdaten enthalten Wall-Frametimes mit Zeitstempeln, Scopezeiten fuer Simulation,
  Navigation, Combat, FoW, Figuren-/HUD-Updates und Queue-/Backlogwerte.
- P50/P90/P95/P99/Maximum, Hitches ueber 33/50/100/250 ms sowie deren Abstaende
  werden erfasst. Diagnosesnapshotkosten werden eigens ausgewiesen.
- Vorher/Nachher bleiben Workload, Kamera, 1x, Route und Dauer vergleichbar.
- Erst belegte Ursache als Akzeptanz/Regression ergaenzen, danach Produktfix.

## Dateien / lokale Pruefung
Neuer Helper `scripts/tests/playtest_20261105_fullscreen_performance_capture.gd`.
Optionale, standardmaessig deaktivierte FoW-Timingdiagnose in
`scripts/tests/mission_test_setup.gd`; vorhandene Meta-Transportdiagnose wird
nur vom Helper aktiviert. Analysehelper im eigenen Outputnamespace.
Engineprozesse ausschliesslich seriell durch Root. Start mit `--fullscreen`,
dem bereits isoliert vorbereiteten QA-Projekt und `--script` auf den Helper;
Argumente `--evidence-output=<neuer Pfad> --profile-seconds=90`.
Marker `PLAYTEST_PERF_START`, `PLAYTEST_PERF_PROGRESS`, `PLAYTEST_PERF_DONE`.
Rohdaten im separaten `<evidence-basename>_performance.json`.

## Risiken / offene Punkte
CPU-Instrumentierung kostet selbst Zeit und ist als `probe_usec` gemessen.
GPU-Framezeit ist ohne GPU-Timer nicht verfuegbar; Render-/Draw-Monitore sind
kein GPU-Zeitersatz. Normale Combat-/Vitalereignisse koennen den Workload waehrend
90 Sekunden veraendern und werden als Unit-/Queuezaehler sichtbar gehalten.
Beide Laeufe brauchen dieselbe isolierte Profilprovenienz und Sourcepins.

## Status
Erste Vollbildmessung 59/59 Normalpfad-Gates: 90,07 s /462 Frames,
p50/p95/p99/max 144,93/915,95/1063,00/1138,31 ms; 33 Frames ueber 250 ms.
1x-Simulationsdurchsatz 0,665; Navigation immer ohne Backlog.
Native Evidenz `output/playtest_20261105/baseline/20261105T061938Z-341212ca/`.
Die ersten Hitches liegen bei etwa 1,93/4,27/6,21/8,21/10,33 s.
Sim/Combat (je acht Catch-up-Ticks), HUD und Terrain erklaeren die einsekundigen
Spitzen zusammen nicht. Hypothesen: unprofilierter FoW-Owner oder Meta-Timer.
Zweite native Ownerprobe 59/59, 30,57 s, im eigenen Ordner
`output/playtest_20261105/owner_diagnosis/20261105T062714Z-70f433c0/`.
Sie bestaetigt die periodische Ursache: 16 Meta-Transporttimerereignisse kosten
jeweils 744-1070 ms. Davon entfallen 477-645 ms auf den kompletten, verdeckten
Homebase-Refresh und 262-425 ms auf `_refresh_map_screen`, der den vollen Plan
an die aktive Mission zurueckschreibt. Die eigentliche Transportfeldarbeit
liegt bei 65-96 us. FoW-Owner maximal 56,01 ms, Advance maximal 35,63 ms.
Navigation bleibt ohne Backlog. Die Probe selbst liegt p99 bei 0,158 ms.

### Belegter Fixauftrag an den Root-UI-/Meta-Owner
Verdeckte Basisoberflaechen bei laufender Mission nur als dirty markieren und
beim naechsten Anzeigen aus den bestehenden Owners aktualisieren. Laufende
Transportdaten weiter rechtzeitig fortschreiben; deren Uebergang in die
Mission braucht einen passenden Delta-Pfad statt erneutem Vollplan-/UIaufbau.
Auch ein normaler Move/GO-Befehl darf keinen unveraenderten kompletten Plan
nochmals teuer anwenden. Keine zweite Transport-/Rosterwahrheit einfuehren.
Regression: fortlaufender normaler Recovery-/Transferstatus mit korrekter ETA,
identischen Identitaeten, erreichbarer aktueller Basis nach Rueckkehr und
keinen versteckten Basisrebuilds pro Tick. Danach identischer nativer 90-s-Lauf.
Simulation-/Navigationsbudgets sind nach diesen Belegen kein geeigneter Fix.

### Weitere Last, getrennt vom periodischen Hauptfehler
Combat hat in der ersten Messung auf Decisionticks etwa 14,4 ms fuer Enemy-
Taktik und 12,1 ms fuer Overwatch/Security. Der Profiler zeigt acht Catch-up-
Ticks in fast jedem Renderframe. Nach dem Meta-Fix ist erneut zu beurteilen,
welche Last bei normalem Durchsatz bleibt; kein spekulativer Runtimefix.

### Umsetzung und Regression
Root hat den exklusiven Besitz fuer `meta_layer_flow.gd` und den abgegrenzten
Controllerconsumer freigegeben. Die normale Loop-Regressionsprobe
`playtest_20261105_meta_transport_hitch_verifier.gd` reproduziert vor dem Fix
63 PASS /6 FAIL: reale Timer-/Transfer-/ETA-/Orderpruefungen bestehen;
verdeckte Control-Neuerstellung und erneuter No-op-HUDaufbau schlagen fehl.
Evidenz `output/playtest_20261105/meta_red/20261105T063901Z-f9711b68/`.

Der Meta-Owner markiert jetzt nur die verdeckte Basisdarstellung dirty. Deren
vorhandener Anzeigeweg aktualisiert sie beim Anzeigen; ID-Normalisierung,
Transferfortschritte, Abschluss und Recovery bleiben im bestehenden Owner.
Der Timer vergleicht unmittelbar die Transportfelder vor/nach dem vorhandenen
Sync und sendet die Aenderung an `apply_meta_transport_planning_delta`.
Dieser Consumer weist fremde Plankeys vor jeder Mutation zurueck und laedt
weder Phasen noch Orderplaene neu. Er aktualisiert nur vorhandene Transport-
Scalars/Cards/Routes/Payloadmetadaten und die zugehoerigen Lesedarstellungen.
Unveraenderte Owner-Snapshots werden nicht an denselben Missioncontroller
zurueckgeschrieben. Kein zusaetzlicher persistenter Plan- oder Gameplaycache.
Voller Altpfad bleibt fuer echte andere Planaenderungen und Legacyconsumer.

Native GREEN-Probe 75/75 ohne Fehler, einschliesslich echter Vollbildmodi
(Window und DisplayServer jeweils 3, Window/Display/Viewport 3440x1440),
atomarem Reject fremder Orderkeys und unveraenderter Liveexecution.
Evidenz `output/playtest_20261105/meta_green/20261105T064446Z-ea641b71/`.
Der echte Timer kostet im gemessenen Sample jetzt 3,141 ms: verdeckte Basis
8 us, Missiontransportdelta 2,926 ms, Transportfeldsync 179 us. Gleichzeitig
fallen ETA 18->16 s und Progress 0->11,11 % fuer dieselben drei Operatoren an.
Am Ende der normalen Drop-/GO-Route: 22 Transportdeltas, 18 No-op-Skips,
0 komplette Planrueckanwendungen. `git diff --check` besteht.
Die native 90-s-Nachhermessung besteht 59/59, gleiche Displaygroesse, 1x,
3-s-Warmup, Kameraroute, 11 registrierte Units und zwoelfsekuendliche Move-/GO-
Aktionen. Evidenz `output/playtest_20261105/perf_after_meta/20261105T064613Z-fae033c9/`.
P50/P95/P99/max betragen 175/297/482/584 ms statt 145/916/1063/1138 ms.
Der Mittelwert aendert sich 194,93->187,54 ms, Simulationsdurchsatz 0,665->0,708.
50 statt 33 Frames liegen ueber 250 ms. Die periodischen einsekundigen
Metahitches sind damit beseitigt, das Spiel bleibt in diesem Vollbildworkload
bei etwa 5,3 Renderframes/s und ist ausdruecklich NICHT als fluessig bestanden.
P50 verschlechtert sich; die Tailverbesserung ist keine allgemeine FPS-Abnahme.

Meta-Timer maximal 16,08 ms, verdeckte Basis maximal 18 us; Navigation hat
weiter keinen Backlog. Dauerlast: fast immer acht Catch-up-Ticks pro Frame,
Simulation im Schnitt 14,10 ms/Tick, insbesondere Enemy-Taktik und Security;
FoW-Owner 33,76 ms/Frame im Mittel, P99 61,66 ms; HUD P99 171,56 ms.
Move/GO hinterlaesst einzelne etwa 0,54-s-Spitzen. Eine weitere kurze reine
Diagnose erfasst die vorhandenen inneren Combat-Hotspots sowie echte Move-/GO-
Aufrufkosten; weitere Produktkorrekturen erst nach dieser Eingrenzung.

### Zweiter bestaetigter Engpass: vollstaendige Kartenabfrage fuer Deckung
Die kurze native Scopeprobe besteht 59/59, unter
`output/playtest_20261105/combat_scope_diagnosis/20261105T065216Z-16c673f3/`.
245 Combat-Decisions verbringen 3,96 s in Enemy-Taktik-Zielwahl, davon 2,93 s
in 1960 Deckungsradiusabfragen (je etwa 1,495 ms). Der gegenwaertige Registry-
Query scannt dabei pro Aufruf alle 9408 `world_position`-Werte. Die native
Move-/GO-Aktion selbst benoetigt 171/143 ms trotz 0 Meta-Vollplanrueckanwendungen.

Root hat TerrainRegistry und die vorhandenen GM01-Radius-/Scorertests zugewiesen.
Neue Regression `playtest_20261105_cover_query_spatial_verifier.gd` vergleicht
gegen den exakten bisherigen Query und zaehlt reale Worldpositionzugriffe an
3000 Eintraegen. Nach Warmup darf eine lokale Abfrage hoechstens 32 nahe Werte
lesen. Beide Topologien, unabhaengige gespeicherte Worldpositionen, inklusive
Randwerte/negative Radien, Insertionreihenfolge, Replacements, Liveeligibility,
Overrides, Notify nach Worldpositionsaenderung und Clear/Re-register bleiben
objekt- und reihenfolgenidentisch. Bestehende GM01-Verifier bleiben unveraendert.
Geplant ist ein begrenzter, rein abgeleiteter Worldposition-Bucketindex im
Registry-Owner; keine Aenderung an Radius, Kandidatenergebnis oder Spielregeln.
Die neue Regression ist vor dem Patch 16/2 RED und danach 18/18 GREEN unter
`output/playtest_20261105/registry_base_homebase_red/20261105T071206Z-24452be9/`.
Die warme lokale Abfrage liest in beiden Topologien sieben statt 3000
Worldpositionen. Der Index verwendet tatsaechliche gespeicherte Worldpositionen
in 256er Buckets und sortiert Kandidaten nach alten Dictionary-Insertionindices.
Register/Clear/`notify_tile_data_changed` invalidieren ihn; Live-Walkability und
Coverwerte samt Overrides werden weiter pro Kandidat gelesen. Breite oder
nichtfinite Queries behalten den bisherigen Scan als unveraenderten Fallback.
Die beiden bestehenden GM01-Verifier sowie TASK409 sind als Nachbarn angefordert.
Diese unveraenderten Nachbarn bestehen anschliessend 29/29, 51/51 und 18/18
unter `output/playtest_20261105/registry_security_hud_red/20261105T072325Z-58ac2f54/`.
Die native 15-s-Probe nach Registryfix besteht 59/59 und misst warme
Deckungsabfragen mit 0,110 statt 1,495 ms (unterschiedliche Anzahl echter
Decisions); Frame-P50 92,60 ms, Mittel 104,29 ms, 1x-Durchsatz 0,941.
Das ist eine weitere Verbesserung, weiterhin keine Fluessigkeitsabnahme.

### Security: Diagnose vor naechster Korrektur
Der vorhandene Securityrefresh enthaelt Runtime-State/Facing, Badges,
Ordervisuals und Statuspanel in einem gemeinsamen Pfad. Der optional vorhandene
Frame-Debugflag erfasst diese vier Kosten nun getrennt, ohne Verhaltensaenderung.
Die geplante Regression `playtest_20261105_security_visual_batch_verifier.gd`
verwendet den echten Security-State-/Facing-Code mit gezaehlten Visualsinks:
acht Combatupdates muessen State/Facing/Badges/Revisions sofort aktualisieren,
waehrend die bestehende 0,20-s-Prozessaktualisierung genau einen Visualbatch
flusht. Manuelle Refreshs bleiben sofortig; Inaktivierung entfernt Runtime-
State und Facing sofort und die Darstellung im naechsten vorhandenen Batch.
Produktcoalescing erst nach Kostenbeleg und gezieltem RED, keine Ticksenkung.
Der RED-Verifier bestaetigt 19 PASS/5 FAIL bei unveraenderter korrekter
State-/Facing-/Badge-/Revisionsverarbeitung. Die native Kostenprobe unter
`output/playtest_20261105/security_scope/20261105T072613Z-0d68a564/` bestaetigt
412 Securitycalls: State/Facing 214,40 ms, Badges 18,53 ms, Ordervisuals
3823,25 ms und Statuspanel 783,58 ms. 95,2 % dieser Arbeit sind Darstellung.

Darauf folgt der gezielte Patch: Combat verwendet den neuen Entry
`refresh_fireteam_security_state_for_combat`, der State/Facing/Badges und
Revisionen sofort weiterfuehrt. Nur die zugehoerige Ordervisual-/Statuspanel-
Projektion wird dirty gesammelt. Der unveraenderte 0,20-s-Prozessrefresh und
alle manuellen Aufrufe ueber den bestehenden Defaultentry flushen sofort.
Eine pending Entfernung wird auch dann verarbeitet, wenn der folgende State
schon unveraendert leer ist. Waffen-/Schussereignisse, Lebenszeiten, normale
Command-/Pendingfeedbackpfade und das taktische Regeltempo werden nicht geaendert.
Die Securityregression besteht danach 24/24. Kontakte TASK112 14/14 und
Hotpath TASK479 25/25 bestehen ebenfalls. Die angeforderten alten Nachbarn
TASK111 13/8, TASK113 22/4, TASK436 52/2, Fire-Sector-Overlay 22/1 und TASK230
25/2 zeigen auf dem unveraenderten Original-Main `90e1f373` dieselben Ergebnisse;
keine Regel-/Testanpassung, um diese Altannahmen in diesem Performancefix zu
kaschieren. Root fuehrt die Baselines isoliert unter
`output/playtest_20261105/main90_neighbor_baseline/` aus und erhaelt die roten
Originaldiagnosen. Current-GREEN-/Nachbarlogs unter
`output/playtest_20261105/targeted_regressions/`.
Eine abschliessende native 90-s-Messung nach den abgestimmten HUD-/Meta-/Basis-
Quellfreezes bleibt erforderlich. Bis dahin keine Fluessigkeitsbehauptung.

### 90-s-Security-/HUD-Nachherprobe und aktive Last
Der native normale Basis-/Mission-/Inputpfad besteht 81/81 unter
`output/playtest_20261105/native_homebase_performance/20261105T073815Z-49ce2971/`.
0-30 s: 971 Frames, Mittel 30,89 ms, P50/P95/P99 28,44/64,72/135,44 ms,
Maximum 297,68 ms, 1x-Durchsatz 0,988. 30-90 s: 4715 Frames, Mittel 12,72 ms,
P50/P95/P99 8,18/31,34/49,78 ms, Maximum 284,02 ms, Durchsatz 0,992.
Gesamtdurchsatz 0,9904. Alle sieben wiederholten Move-/GO-Aktionen werden
angenommen; die Akteure bleiben laut Combat-Audit durchgehend 3 fit Friendly
und 8 fit Enemy, ohne aufgeloesten Combat. Ein Down-/Missionsende erklaert den
spaeteren Lastabfall also nicht. Die Command-Queue faellt im spaeten Abschnitt
aber median auf null und die FoW-Revision bleibt bei 322. Fortgesetzte echte
Bewegung ist fuer diesen schnellen Abschnitt damit noch nicht belegt.
Die fruehen 30 Sekunden werden gesondert berichtet, kein allgemeiner 85-FPS-
Spielbeleg aus dem spaeten Median. Verbleibende grosse Spitzen fallen weiter
auf die normalen Move-/GO-Projektionsaufrufe mit etwa 88-142/94-105 ms.

#### Vergleich der aktiven fruehen Beobachtung
Gleicher nativer Vollbild-/1x-/Map-/11-Unit-/Kameraprotokollpfad; je zwei
angenommene, gleiche Move-/GO-Ziele bei etwa 12 und 24 realen Sekunden.
Frametimings werden nach Ende-Zeitstempel `<30 s` gruppiert: dadurch decken
vollstaendig beendete Messframes 29,904 bzw. 29,999 s ab. Der ueber die Grenze
reichende Folgeframe wird keiner abgeschnittenen kuenstlichen Verteilung
hinzugefuegt. Unterschiedlicher echter Simulationsfortschritt bleibt sichtbar.

| Metrik | Vorher | Nachher |
| --- | ---: | ---: |
| Vollstaendige Frames / abgedeckte reale Sekunden | 104 /29,904 | 971 /29,999 |
| Frametime Mittel /P50 | 287,54 /162,00 ms | 30,89 /28,44 ms |
| Frametime P90 /P95 /P99 | 1028,23 /1058,00 /1112,97 ms | 51,06 /64,72 /135,44 ms |
| Groesster Frame | 1138,31 ms | 297,68 ms |
| Frames ueber 50 /100 /250 ms | 104 /100 /16 | 102 /21 /2 |
| Renderdurchsatz dieser fruehen Beobachtung | 3,48 Frames/s | 32,37 Frames/s |
| Wirkliche Simulationsticks /Simulationssekunden | 825 /13,75 | 1778 /29,63 |
| Simulationssekunden pro realer Sekunde | 0,460 | 0,988 |
| Registrierte Units /maximaler Navbacklog | 11 /0 | 11 /0 |

Rohwerte und die Fensterdefinition stehen in
`native_homebase_performance/20261105T073815Z-49ce2971/active_0_30_comparison.json`.
Dieser gleiche reale Eingabeablauf ist wegen des vorherigen grossen Simulations-
rueckstands keine Behauptung identischer Simulationszustandsfolge. Die spaeten
ruhend wirkenden Frames werden fuer diese fruehe Bewegungsbewertung nicht genutzt.

Root genehmigt eine ausschliesslich lesende Zusatzprobe im neuen abgeleiteten
Helper `playtest_20261105_motion_order_capture.gd`: alle 0,25 realen Sekunden
Registrypositionen/Vitals/Sichtbarkeit, aktuelle Commands, serialisierte
Orderplaene und Movement-/Nav-/FoW-Snapshots erfassen. Keine Actor-, Order-,
Zeit- oder Budgetpatches. Sie soll angenommene, aber wartende Orders von
wirklicher Bewegung und einem unabhaengigen FoW-Signaturproblem unterscheiden.

### Motionprobe: spaeter Stillstand ist ein eigener Gameplayfehler

Der native 50-s-Lauf unter
`output/playtest_20261105/motion_trace/20261105T080031Z-13cf75d8/`
ist abgeschlossen; die unveraenderten Rohdateien `motion_motion.json` und
`motion_performance.json` sind in `motion_analysis.json` per SHA256 referenziert.
193 Samples insgesamt, davon 182 im Messfenster; die anderen elf stammen aus
dem unveraenderten dreisekuendigen Warmup.

| Echte Unit | Letzte Positionsaenderung im Messfenster | Position danach | Delta nach 35 s |
| --- | ---: | --- | ---: |
| player_sternenbuergerchen_01 | 34,900542 s | (-246,681610; 463,022827) | 0 |
| player_sternenbuergerchen_02 | 31,166559 s | (-170,256287; 469,128143) | 0 |
| player_sternenbuergerchen_03 | 28,152723 s | (-321,401672; 461,105865) | 0 |

Bei 34,901 s endet wp_0003 regulaer: Plan und Phase-Execution sind leer, alle
drei aktuellen Runtimecommands sind untokenisierte `hold_position` aus
`auto_defend`. Alle elf registrierten Units bleiben fit. Der neue Move/GO bei
36 s aktiviert wp_0004 und neue individuelle Movementtargets; die Runtime-
commands bleiben jedoch bis 49,810 s exakt Auto DEF. Contact-Halt ist false,
keine Unit erreicht die neuen Targets. GO bei 48 s fuegt wp_0005 pending hinzu.
Es handelt sich deshalb um einen reproduzierten Wiederanlauffehler nach
Auto DEF; eine angenommene GO-Rueckgabe belegt hier keine ausgefuehrte Bewegung.

Der lesende Sourceabgleich grenzt ihn auf den Tokencommit in SimulationRoot
ein: untokenisierter autoritativer Hold behaelt dort den alten nichtleeren
committed Move-Token. Der neue Move trifft dadurch vor Status-/Navanwendung auf
den Stale-Token-Guard. Gezielt native RED, Korrektur und Nachbarn werden separat
in `PLAYTEST_2026_11_05_move_after_auto_defend.md` gefuehrt. Sourcefreeze bleibt
bis Root-RED; keine Actor-/HP-/Timerpatches.

Der 50-s-Gesamtwert (P50 11,944 /P95 62,681 /P99 128,278 /Max 312,820 ms;
4 Frames ueber 250 ms; 0,985 Simulationssekunden je reale Sekunde) enthaelt
diesen Stillstand. Er ist ebenfalls kein allgemeiner Bewegungs-FPS-Beleg.

### Finale 90-s-Motionprobe nach dem Tokenfix

Native Normalroute 61/61, Godot 4.6.2 / Forward+ / Vulkan / 1x, unter
`output/playtest_20261105/final_motion_90/20261105T084901Z-ad9f7065/`.
`final_motion_analysis.json` referenziert die drei unveraenderten Rohdateien
mit SHA256 und trennt 340 Motionreads in elf Warmup- und 329 Messsamples.
Das physische Display, Window und Renderbuffer sind jetzt 2560x1440; alle
zehn Displaysnapshots bestaetigen Vollbildmodus 3 und Zeitfaktor 1.
Der fruehere 3440x1440-Monitor ist nicht mehr angeschlossen. Dieser Lauf ist
deshalb kein direktes Ultrawide-Vorher-/Nachherpaar und keine FPS-Steigerungsquote.

Kein erneuter gemeinsamer Stillstand: Alle elf registrierten Akteure bleiben
in jedem Messsample fit, dieselben drei Spieler-IDs sind durchgehend vorhanden.
Sie bewegen sich auch nach 35 s und im Abschnitt 80-90 s tatsaechlich weiter.
Die folgende Wegsumme addiert nur gesampelte projizierte Weltpositionssegmente;
sie ist keine exakte physische Hex-Weglaenge.

| Unit-ID-Ende | Gesampelte Wegsumme ab 35 s | Letzte Positionsaenderung | Zustand am letzten Sample |
| --- | ---: | ---: | --- |
| 01 | 1125,53 | 89,849676 s | Move weiterhin unterwegs |
| 02 | 1175,09 | 89,849676 s | Move weiterhin unterwegs |
| 03 | 541,07 | 87,724222 s | Aktuelles Slotziel bis auf 0,000009 erreicht |

Das letzte Motionread liegt bei 89,849676 s; das Framefenster endet bei
90,036748 s. Die kurze stationaere Schlussphase von Unit 03 ist Zielankunft,
kein Wiederanlauffehler. Alle sieben wiederholten Move-/GO-Paare wurden
angenommen. Pending-Waypoints maximal eins und zuletzt null; ein aktiver
Waypoint am Ende. Nav-Pending und Nav-Delay sind in 3869 Frame- und 5318
Tickrecords immer null. Die normale Command-Queue hat P50 2 / Maximum 7,
die Effect-Queue bleibt null. FoW-Revision 31->709, gemessenes Pendingalter
maximal 173 ms; kein dauerhaft eingefrorener Sichtstand.

90,036748 reale Sekunden / 3869 Frames / 5317 wirkliche Tickfortschritte:
88,6167 Simulationssekunden, somit 0,98423 Simulationssekunden je reale
Sekunde. Frame-Mittel/P50/P95/P99/Maximum betragen
23,268/17,308/54,207/111,590/391,848 ms. Hitches ueber 33/50/100/250 ms:
981/236/56/7. Motionread-P99/Maximum 1,186/1,209 ms bei rund 4 Hz;
Frameprobe-P99/Maximum 0,112/0,327 ms und Tickprobe 0,077/0,137 ms.
Diese Loggerkosten sind gemessen, nicht aus den Framezeiten herausgerechnet.

Alle sieben Frames ueber 250 ms enthalten die echten periodischen Move-/GO-
Aufrufe bei 12/24/36/48/60/72/84 s. Deren separat gemessene synchrone Kosten
von zusammen 212,491-331,077 ms erklaeren 76,6-86,0 Prozent dieser Frames.
Der groesste Frame bei 72,395031 s kostet 391,848 ms, davon Move/GO 331,077 ms.
Weitere Spitzen liegen in `execution_updates_usec`: beispielsweise 147,503 ms
im 240,829-ms-Frame bei 24,588302 s. Deren innere Ursache und der restliche
Frameanteil sind damit noch nicht eindeutig aufgeloest. Simulationsgesamtzeit
enthaelt Combat-Signalsubscriber; beide duerfen nicht addiert werden. Gecachte
Owner-Snapshots werden ebenfalls nicht erneut als aktuelle Framekosten summiert.
GPU-Framezeit bleibt unverfuegbar. Fortgesetzte Bewegung ist fuer diesen Lauf
belegt; die verbliebenen Hitches sind keine allgemeine Fluessigkeitsfreigabe.
