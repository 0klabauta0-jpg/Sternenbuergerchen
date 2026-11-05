# Fortsetzung: Befehlsruckler und sieben rote Alt-Gates

## Ziel / Problem und Basis
Der Nutzer fordert nach dem Vollbild-, UX- und Grafikpass die Fortsetzung.
Synchrone Move-/GO-Aufrufe kosten noch 212-331 ms; sieben historische Gates
waren bereits auf dem damaligen Main rot. Bestaetigte Ursachen werden
korrigiert, veraltete Erwartungen gegen aktuelle Vertraege eingeordnet.

Basis: Main `01ab595a7b89632629eee0ad3523281e542148a0`; neuer Branch
`task/continue-perf-legacy-20261105`. Kein alter Taskbranch wird fortgeschrieben.

## Ursache / Umfang / Nicht-Ziele
Der native 38-s-Vorlauf misst drei Move-/GO-Paare mit 215.350, 215.291 und
256.692 ms. Beide Aufrufe bauen unmittelbar dieselben abgeleiteten
HUD-Flaechen auf. Auch Bound-/Waypointwechsel wiederholen diese UI-Arbeit.
Nur diese erfolgreichen Waypoint-/GO-/Phase-Execution-Publikationen erhalten
sofortiges Spielerfeedback plus einen gebuendelten Auftrag im bestehenden
350-ms-UI-Takt. Jeder intervenierende volle UI-Pass uebernimmt eine
anstehende Forceanforderung. Geoeffnete Details zeigen aktuelle Quellen.

Zusaetzlich werden die belegten Facing-, Drop-/FoW- und A5-Geometriefehler
korrigiert. Keine alte Overwatch-/Flankregel wird produktiv reaktiviert.
Keine Qualitaets-, Einheiten-, Tempo- oder Workloadreduktion; keine Actor-,
HP-, Positions- oder Timerpatches als physischer Spielbeweis. Kein neuer
Release-, EXE-, LAN- oder WAN-Umfang.

## Dokumente / Contracts
AGENTS, PROJECT_BRIEF, ARCHITECTURE, CODEX_RULES, IMPLEMENTATION_STATUS,
TASK_ROADMAP; PLAYTEST_2026_11_05_performance; fireteam_behavior_modes_contract,
unit_facing_visual_contract, flight_altitude_layer_contract,
mission_command_feedback_contract, gm01_frontier_map_contract,
graphics_reference_revision_contract; die drei verlinkten Teil-Audits.

## Akzeptanzkriterien
- Gleicher normaler Weg und 1x im echten Vollbild; aktuelles Display,
  Renderer, Rohdaten, Komponentenmessung und Vergleichsgrenzen dokumentiert.
- Befehle, Targets, Planfolge, Sperren und sichtbares Feedback bleiben korrekt.
  SimulationRoot und die vorhandenen Runtime-Owners behalten ihre Autoritaet.
- Move plus GO wird einmal gebuendelt; Transport-Interleaving verliert keinen
  Auftrag. Aktuelle Details, spaetere Befehle und quiescente Guards bestehen.
- Modell, Waffenrichtung und Orientation nutzen dieselbe aktuelle Quelle.
  Mehrere Syncs desselben Ticks drehen aktive Bewegung nicht zum Fernziel.
- Flugkoerper, LZ, Approach und Cargolabel verwenden eigene Owner-/Anchor-Gates.
  Blackout bleibt geschuetzt; eigene Planung auf bekanntem Terrain bleibt
  vor dem ersten Bodenobserver sichtbar. FoW-Gain/Loss invalidiert gezielt.
- Ganze A5-Karten bleiben erreichbar und getrennt. Einpersonenportraits zeigen
  das vollstaendige Gesicht im unveraenderten Slot und behalten ihre Callbacks.
- Jeder historische Gate wird einzeln bewertet. Fokussierte Regressionen,
  unabhaengiges Nachreview, Mainintegration und normaler Push werden belegt.
- Originalroster, fremde WIP und fruehere Rohdaten bleiben erhalten.

## Betroffene Dateien / Besitz
Root: mission_tactical_sandbox_controller, Performancecapture, isolierter
Runner, neue Command-HUD-Regression, Schlussmatrix und Integration.
Delegiert: terrain_map_3d_view, Facing-/Air-Verifier, historische Taktik-Verifier
und Teil-Audits. Root fuehrt alle Engines seriell aus; frische private Userdaten
und neues Outputnamespace `output/continue_20261105` sind Pflicht.

Teil-Audits:
- `CONTINUE_2026_11_05_legacy_tactics_contract_audit.md`
- `CONTINUE_2026_11_05_facing_sightline_subtask.md`
- `../qa/continue_20261105_air_hud_audit.md`

## Lokale Pruefung und Ergebnis vor Mainintegration
- Schlussmatrix 26/27. Allein die alte 48x48-Oracle von TASK344 war rot;
  nach Abgleich mit dem geltenden 96x98-Vertrag besteht der Nachlauf 40/40.
  Damit sind 27 aktuelle fokussierte Gates geprueft. Die historische rote
  Matrix wird erhalten und nicht nachtraeglich als gruen bezeichnet.
- Native 90 s: 61/61; alle sieben Move-/GO-Paare angenommen. Dieselben drei
  fitten Player bewegen sich auch zwischen 85 und 90 s weiter. Vulkan/Forward+,
  2560x1440 Vollbild, 1x; 5367 Ticks / 90.014 s ergeben 0.993735 Sim/Wand.
- Erste drei synchrone Aufrufpaare: im Mittel 229.111 -> 84.299 ms (-63.2%).
- Native Facing- und Portraitfixture je 135/135; Air 155/155. Alle melden
  Exit 0, keine Fehler und isolierte Userdaten. Kontrollierte Fixtures
  belegen keinen physischen Schuss im normalen Spiel.
- Unabhaengiges Nachreview APPROVED scoped. Beide dort gefundenen P2 sind
  mit Regressionen geschlossen: verlorener Command-Force und falsche
  Gesamtsichtbarkeit eines gemischten Dropcontainers.
- Der historische 24049-Dateipin bleibt unveraendert. final_source_binding
  bindet 1948 aktuelle Codequellen und genau drei Nachlaufdeltas. Nur eine
  Portrait-Samplerzeile unterscheidet den gemessenen Controller vom Schlussstand;
  ihr Ruecktausch ergibt bytegenau dessen SHA. Der letzte HUD-Gate besteht
  40/40 und prueft acht kritische Quellen vor/nach dem Lauf auf Gleichheit.
- Originalroster sowie 38 fremde Dateien und 437 bestehende Rosterdateien
  bleiben nach Bytes, Laenge und Schreibzeit gleich.

## Risiken / offene Grenzen
Eine allgemeine Framezeitverbesserung ist nicht belegt. Im gemeinsamen
0-38-s-Fenster liegen Median/P95 final bei 29.730/77.072 statt
26.777/68.007 ms; Hitches ueber 50 ms sind 158 statt 125. Unterschiedliche
Startpositionen und der zusaetzliche lesende Motiontrace begrenzen die
Kausalitaet. Das Restmaximum von 288.544 ms bei 36.589 s liegt im weiterhin
teuren vollen HUD-Aufbau. Keine allgemeine Fluessigkeitsfreigabe.

QA: `../qa/continue_20261105/README.md`. Native Mainpruefung, Integration
und Push werden separat in `../qa/continue_20261105/main_receipt.json`
quittiert. Gestalterische Nutzerabnahme bleibt offen.
