# Door-Runtime-Autoritaet ohne HUD-Abhaengigkeit

## Ziel / Problem
Der effektive Door-Zustand fuer Navigation, LOS, Hoehe und Cover muss aus
dem bestehenden Mission-Interaction-Owner aktualisiert werden, auch ohne
Primary3DView oder HUD-Aufbau. Haupttask: `HUD_ARCHITECTURE_2026_11_06.md`.

## Bestaetigte Ursache / Sinnhaftigkeit
Der bisher einzige produktive Apply-Aufruf liegt in
`MissionTacticalSandboxController._sync_primary_3d_mission_status_visuals()`.
Ein fehlender Primary3DView beendet diesen Pfad vor der Registry-Mutation.
Die vorhandenen TASK693-Tests rufen Apply selbst auf und belegen deshalb keine
Runtime-Unabhaengigkeit. Zusaetzlich schreiben die lesend benannten
CombatLoop-Getter `get_playability_snapshot()` und
`get_objective_countdown_snapshot()` ueber Gate-/Countdown-Updates in
Runtime-Daten. Der regulaere Runtime-Tick besitzt bereits diese Updatepfade.

## Umfang / Nicht-Ziele
- Der vorhandene `MissionCombatLoopDriver` bleibt Interaction-Owner.
- Effektive Door-Overrides sind ein abgeleiteter Registry-Index aus Bindings,
  Markerpositionen und vorhandenem Runtime-State; kein zweiter Door-State.
- Configure, Fortschrittsmutation, Remote-Anwendung und Runtime-Tick besitzen
  die Aktualisierung. Getter lesen fertige Snapshots.
- Die bestehende Oeffnungsgrenze von 85 Prozent wird zentral geteilt und
  beibehalten. Keine Balance-, Zeit-, Bewegungs- oder Gameplaylastreduktion.
- Kein Runtime-Producer sucht oder ruft HUD-/Controller-Nodes auf.
- Kein breiter Runtime-/Multiplayer-Umbau, keine Map-/Save-Mutation und keine
  physischen Missionsbeweise durch gepatchte Actors, HP oder Timer.
- Controller-Hunks bleiben bis zur ausdruecklichen Root-Delegation unberuehrt.

## Relevante Dokumente / Contracts
AGENTS.md, PROJECT_BRIEF, ARCHITECTURE, CODEX_RULES, IMPLEMENTATION_STATUS,
TASK_ROADMAP, runtime_script_layout_contract,
mission_interaction_point_contract, TASK692, TASK693, TASK1091 und TASK1092.

## Akzeptanzkriterien
- Ein echter Komponentenverifier verwendet Runtime-Driver, SimulationRoot,
  TerrainRegistry, TerrainPathfinder und LineOfSightSystem ohne Controller
  oder Primary3DView. Die Fixture ist ausdruecklich synthetisch und kein
  physischer Missions-, UX- oder Performancebeweis.
- Configure erzeugt geschlossene Overrides; Runtime-Fortschritt bei 50 und
  84 Prozent bleibt blockierend, ab 85 Prozent wird der Durchgang frei;
  Completion bleibt offen, Interrupted schliesst einen unfertigen Vorgang.
- Derselbe Registryzustand steuert effektive Walkability, LOS, Object-Height,
  Cover und die echten Pathfinder-/LOS-Ergebnisse. Statische Tiles bleiben gleich.
- Mehrfache Playability-/Countdown- und Door-Snapshot-Leseaufrufe aendern weder
  Gate-/Hold-/Interaction-/Objectivezustand noch Registryrevision oder Commands.
- Ein leeres oder geaendertes repliziertes Interaction-Snapshot aktualisiert
  den abgeleiteten Index ohne lokale Commands oder Effects.
- Gleiche effektive Overrides bumpen keine Registryrevision. Registrytausch
  sowie clear/rebuild mit gleichem Door-Fingerprint werden beim Runtime-Update
  erkannt und erneut angewendet; eigenes Apply erzeugt keine Revisionsschleife.
- Fehlende Marker oder Mapdaten erzeugen keinen erfundenen Nullpunkt-Override.
- Diagnosefelder fuer Quelle, Applygrund, Counts und Registryrevision bleiben
  explizit; Rueckgabedaten sind defensiv kopiert.
- `producer_applied` beschreibt den letzten Runtime-Producerpass. Eine reine
  Leseabfrage behauptet keine neue Anwendung. `producer_apply_count` und
  Registryrevision belegen tatsaechliche Applies; `producer_index_current`
  wird nur in der Rueckgabekopie gegen Registry und echte Marker geprueft.
- Ein vorhandener angewandter Receipt ist die Darstellungsquelle fuer Door-
  Asset, Gap und Label, auch wenn lokales Use-Feedback out-of-range meldet.
- Controller-Kompatibilitaet und Statussync lesen anschliessend den
  Runtime-Snapshot. Reiner HUD-Aufbau erzeugt keine Registrymutation.

## Betroffene Dateien / Besitz
- Child: `scripts/tests/mission_combat_loop_driver.gd`
- Child: `scripts/mission/mission_interaction_door_runtime_collision_los.gd`
- Child: `scripts/mission/mission_interaction_object_reaction.gd` nur gemeinsamer
  reiner Door-State-Helper
- Child: `scripts/tests/hud_architecture_20261106_door_runtime_authority_verifier.gd`
- Child: diese Taskdatei
- Root: Controllerintegration, Enginekoordination, Contract-/Statusintegration,
  native Nachweise und Git

## Lokale Pruefung
Zuerst erstellt Child ausschliesslich Task und Verifier. Root fuehrt RED auf
unveraendertem Produkt und danach GREEN sowie relevante Nachbarn seriell mit
isolierten Userdaten und Rosterguard aus. Child startet keine Engine, schreibt
keine Userdaten und fuehrt keine Gitmutation aus. Native Mission und
Gesamtperformance bleiben getrennte Root-Gates.

## Risiken / offene Punkte
Die alte Visualableitung mischt lokale Bedienbarkeit mit Runtime-Fortschritt.
Der neue Index muss reale Runtimewerte und die bestehende 85-Prozent-Regel
teilen; Teamwahl und Sichtbarkeit duerfen keine Kollisionsquelle werden.
Configure kann vor Runtime-Ready laufen; der Index braucht echte Marker aus
vorhandenem TerrainMapData und darf fehlende Aufloesung nicht als Nullpunkt
interpretieren. Registryrevision ist zugleich Navigation-/LOS-Invalidierung:
nach eigenem Apply muss die gespeicherte Revision aktuell sein. Remote-Apply
besitzt keine lokale Ausfuehrungsautoritaet. Pure Getter muessen First-ready,
Tick-, Completion- und Clientpfade weiterhin mit aktuellen Daten versorgen.

## Beobachtete fokussierte Pruefung
- Root-RED auf unveraendertem Produkt: **35 bestanden, 23 fehlgeschlagen**,
  keine Parser-/Runtimefehler; isolierter Lauf
  `output/hud_architecture_20261106/door_authority_red_runtime/20261106T141404Z-653b671f`.
  Configure, 85-Prozent-/Complete-Access, Getterreinheit, Rebuild und Remote-
  Anwendung scheiterten erwartungsgemaess. Der vorangegangene Fixture-
  Parserfehler ist kein Produkt-RED und bleibt getrennt erhalten.
- Root-GREEN des ersten Produktpatches: **61 bestanden, 0 fehlgeschlagen**,
  Exit 0, Fehlerzahl 0, Quellen stabil; Lauf
  `output/hud_architecture_20261106/door_authority_green/20261106T141827Z-3cc29a92`.
- Root-GREEN mit erweitertem Registry-/Markerguard, verschachtelten Kopien und
  angewandten Visualreceipts: **72 bestanden, 0 fehlgeschlagen**, Exit 0,
  Fehlerzahl 0, Quellen stabil; Lauf
  `output/hud_architecture_20261106/door_authority_extended_green/20261106T142134Z-e828fe1c`.
  Controllerintegration ist durch Root umgesetzt; die serielle Nachbarmatrix
  laeuft zum Zeitpunkt dieser Notiz noch. Keine native/physische Gesamtfreigabe.

## Fokussierter StartupGrace-Nachlauf
Nach dem Pure-Getter-Umbau wird der vorhandene StartupGrace-Zweig separat
geprueft: ein normal konfigurierter synthetischer Scenario-Hold muss bei
echtem Wandzeitablauf und autoritativem Runtime-Tick weitergezaehlt und in den
Countdown publiziert werden. Grace muss dabei Zero-Roster-Kampfaufloesung und
Commands/Effects weiterhin verhindern. Ein echter lokaler ENet-Kontext prueft
zusaetzlich, dass Clients nicht lokal fortschreiben und der Runtimecallback
nach Wechsel zur Host-Autoritaet den bestehenden Countdown aktualisiert.

Der Verifier wartet kurze reale Zeit bei unveraenderter 1x-Enginezeit. Er setzt
keine Uhr-, Timerursprungs-, Actor-, HP- oder Savewerte. In der ENet-Teilfixture
traegt eine kleine Map-Carrier-Grenze das echte TerrainMapData, damit nicht
ein vollstaendiger MissionSetup-Szenenstart ausgefuehrt wird; alle geprueften
Owner-/Gate-/Authoritykomponenten bleiben echt. Der Harness dispatcht den
echten Runtimecallback kontrolliert statt parallel automatische Physikticks
zu erhalten. Das belegt die Callback-Zweige, keinen kompletten Hostmigration-
oder physischen Missionspfad. Produktkorrektur erst nach Root-RED.

- Root bestaetigt StartupGrace-RED: **81 bestanden, 3 fehlgeschlagen**,
  Fehlerzahl 0, isolierte stabile Quellen; Lauf
  `output/hud_architecture_20261106/door_startup_grace_red/20261106T142711Z-904c99fc`.
  Exakt Hold-Fortschritt, Countdownrate und Host-Authority-Uebergang blieben
  stehen; Client-Guard und erhaltene Combat-Grace bestanden.
- Enger Produktpatch nach diesem RED: Der bereits autoritaetsgepruefte
  StartupGrace-Zweig ruft den vorhandenen Runtime-Countdown-/Gatepublisher vor
  der Staginganzeige auf. Frueher Return, Combat-Grace und vorhandene
  Wandzeitrate bleiben erhalten. Root-GREEN steht fuer diesen Nachlauf noch aus.
- Erster GREEN-Versuch blieb **82/2**; der Host-Uebergang bestand bereits.
  Die erste Einzel-Timerwartebedingung wurde darauf als Fixture-Unsicherheit
  isoliert: ein neuer SceneTreeTimer kann bereits akkumuliertes Startframe-
  Delta konsumieren. Der Verifier wartet jetzt explizit mindestens 50 echte
  `Time.get_ticks_msec()`-Millisekunden und druckt Wandzeit, Hold- und Countdown-
  Werte. Die Fortschritts-/Ratenorakel und Client-Negativpruefung bleiben gleich;
  Produktcode wurde fuer diese Diagnose nicht erneut geaendert.
- Root-GREEN mit echter Wandzeit-Vorbedingung: **85 bestanden, 0 fehlgeschlagen**,
  Exit 0, Fehlerzahl 0, stabile Quellen; Lauf
  `output/hud_architecture_20261106/door_startup_grace_wallclock/20261106T143004Z-63731b07`.
- Root hat denselben korrigierten Verifier ohne genau den einen Grace-
  Publisheraufruf erneut geprueft: **82 bestanden, 3 fehlgeschlagen**, Exit 1,
  Fehlerzahl 0, Isolation bestaetigt; Lauf
  `output/hud_architecture_20261106/door_startup_grace_wallclock_red/20261106T143122Z-8ca8d71f`.
  Bei **62 ms** echter Wandzeit blieben Hold und Countdown gleich; dieselben
  drei Fortschritts-/Authorityorakel scheiterten. Der Client-Negativguard blieb
  bestanden. Damit ist der korrigierte Verifier an das echte Produkt-RED gebunden.
- Nach Wiederherstellen des einzelnen Publisheraufrufs bestaetigt Roots
  Schluss-Komponentenlauf erneut **85 bestanden, 0 fehlgeschlagen**, Exit 0,
  Fehlerzahl 0, Isolation bestaetigt; Lauf
  `output/hud_architecture_20261106/final_components/20261106T143141Z-89d3e189`.
  Diagnose: **56 ms** Wandzeit, Hold **0 -> 0.056 s**, Countdown
  **10 -> 9.944 s**, Enginezeit **1x**. Native Gesamtmission bleibt separat.
