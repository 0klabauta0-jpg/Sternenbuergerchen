# Base action checkpoint V2 - Produktfreeze

Ausschliesslich additive Methoden/Helfer/Felder in base_personnel_runtime.gd und
freigegebener read-only get_prepared_restore_state in HexMovement. Bestehendes
export_state/configure bleiben V1, ebenso Walk/Tick/Board/Remotehandoff/Padregeln.
Keine Root/CheckpointStore/Screen/Netz-/Sharedrunnerwrites oder Produktaktivierung.

API:
export_checkpoint_state()->Dictionary
prepare_restore_state(state:Dictionary,ground_prepared:RefCounted,movement_prepared:RefCounted)
 -> {ok,prepared:RefCounted}
validate_prepared_restore(prepared:RefCounted)->{ok,prepared_id}
_publish_prepared_restore(prepared:RefCounted,validation:Dictionary)->{ok}
finalize_prepared_restore(prepared:RefCounted)->Dictionary
Movement.get_prepared_restore_state(prepared:RefCounted)->Dictionary
 -> exakter validierter canonicalV1State detached, sonst{}; kein privater Patch.

V2: version/map_id/topology/grid_frame/sequence/poll_seconds/rest_elapsed/units.
Gridframe=actual Registryorigin/q/r Vektoren, kein Erraten von coarse64erWerten.
JSONpaare nach Finite-/Boundspruefung in denselben nativen Vector2-Werteraum
normalisieren, dann strikt vergleichen; keine Epsilontoleranz oder neue Positionen.
Units: status/craft_id/bed_id/action/auto_rest_enabled/rest_automatic/idle_seconds/
manual_priority_seconds. Keine zweite Actorposition. Namen/Rollen aus bestehendem
Rosterkontext behalten; last_result ist abgeleitetes Feedback und wird geleert.
Action: move/sleep/terminal mit originalem WORLDtarget und command_token;
Sleep bed_id/automatic, Terminal terminal_id. Keine internen MovementIDs duplizieren.
Sequence >=ALLEN base:n SourceIDs, auch angekommenen/abgebrochenen Archivorders.

Opaque private weak Records max32. Aktuelle Root/Base/Flow/Screen/Registry/Terrain-
Identitaet, Rootweltkontext, Groundrevision, ActorRegistry/Known/Parentidentitaet,
Layouts und alle Basemodelle vor Writes binden. ZielGround kommt aus echtem
Groundprepare/get, Movement aus exaktem validiertem Zielgetter; existierender
Movementvalidator beweist kanonischen Zustand zusaetzlich am selben Zielground.
SourceID/Worldziel/Gridziel/Unit/Sourcecommandtype exakt gegen Baseaktion pruefen.
Bettreservierungen aus sleeping UND moving-sleep ableiten; Doppelnutzung ablehnen.
Bereits angekommen/canceled mit noch nicht vom BaseTick konsumierter moving-Aktion
bleibt erhaltbar. Archivorders brauchen kein neues Aktionsobjekt.

Transport: keine zweite Crewtruth. Aboard verlangt aktuelles existentes Heimschiff,
expliziten grounded-Beleg und echte Screenpilot- oder PayloadFTmitgliedschaft.
Zielrelevante Pilot/Team/Memberwerte sind Prepare-Stalenessbindung. Sourcecomposite
muss tatsaechliche gespeicherte Transportowner vor Baseprepare aufgebaut haben;
kein zukuenftiger unbekannter Transport wird hier behauptet. Boarding/statusboarding,
crew_board/pilot_board, _board_groups, _committing_transport und Admissionpending
sind klare Saveguards; weder Gruppen-/Queue-/Admissiontickets werden serialisiert.
Home-only/Awaygates beim Rootcoordinator bleiben bestehen.

Commit: ALLE Ground/Movement/Base validate VOR erstem Write. Dann Groundtail,
Movementtail, Basetail (nur _states/_beds/_sequence/_poll_seconds/_rest_elapsed und
Bridgephase/epoch), keine Actors/Signals/Commands im Tail. Root projektiert danach
Actors aus Ground; erst dann finalize_prepared_restore emittiert ein state_changed.
Mark-before-emit, Replay safe; geaenderte Postmodel-/Actor-/Rootkontexte oder
Transportmitgliedschaft erzeugen keine alte Abschlussmeldung. Keine Terminal-
oder Schlafwirkung im Restore; normale spaetere _on_tick fuehrt sie einmal aus.

RED0/1 fehlende APIs: base_checkpoint-8c748beed4d440c28f36f0319e09334e/
Historischer erster GREEN23/0 incl private Compile/Import (aktueller Freeze30/0 unten):
base_checkpoint-823c02aab9eb40c1a641acdb9c40e49f/
Exit0, saubere Logs, Quelle/Originalprofil identisch, privater Canary.

Echte Base/Root/Ground/Movement/UnitRegistry/BaseActors und echte Screenklasse.
Nur Flow-/Travelumgebung kontrollierte Lesedaten; kein FakeRoot/GruppenrestoreAPI.
12 bestehende Testfelder auf feinem16/8-Frame, Mapdescriptor384x392 mit tatsaechlichen
Basis-Bett-/TerminalIDs. Kein150528-Felder-Aufbau. Base.request_operation erzeugt
beide Aktionen wirklich; echter Roottick commitet Bewegung. Gemeinsame private
Ownerpublikation benutzt echte Prepare/Validate/Tails; Rootprojektion und spaetere
Tickfortsetzung belegen sleeping sowie genau1terminal_ready. Dies ersetzt NICHT
SourceRoot-Store-/Startloaderintegration oder grosse/native Tests.

Weitere Cases: LegacyV1, echteJSONpaare, Version/Token/Sequence/Originalworldtarget/
coarseFrame/Boardpending/Admissionpending, gefaelschtesAboard trotzHomecraft wird
gegen reale Screenmitgliedschaft abgewiesen; echterPilot positiv und Wechselstale,
Bettkonflikt, Noalias, Zustandstale, silentModeltail/Actorprojektionsreihenfolge,
reentranteSignale/Replay und Archivorders.

Zwischenfehler: a9b0d589999d453babb6b49274f4f138 war Fixtureparse (Environment
verdeckt nativen Klassennamen), kein ProduktRED. 98760ea5c726488391a148f144374005
und cbe21b40854249eb8cd4ccfb4276f68b belegen4/1 im JSONframevergleich:
10.928199768066406 wurde alsJSONfloat64 zu10.928199768066399; native Vector2-
Normalisierung korrigiert die Werteraumgrenze ohne fuzzy Vergleich. Frueherer
23/0:4d5043c830824110929eea670f826977; finaler Lauf enthaelt Actorpostbindguard.

python output/native_glut_maps/base_action_checkpoint_v2_20261112/run.py
Keine Hauptszene/GPU/grosse Matrix/Gitaktionen. Kein fullAP7.

## Finalizebindung: Reviewfix / erneuter Freeze
Finalize prueft nun exakte urspruengliche Flow-/ScreeninstanceIDs, unveraenderte
Treezugehoerigkeit und Scopeobjekte nicht queued. Dabei wird Treepraesenz nicht
zur neuen Spielberechtigung: eine von Anfang an offTree vorhandene echte
Screen-Datenprojektion bleibt eine gueltige Projectionquelle; ihr Austausch/
Lifecyclewechsel kann aber keinen historischen Abschluss mehr erhalten.
Gemeinsamer _checkpoint_live_actor prueft in Candidate UND Finalizebindung:
lebend, inside_tree, nicht queued, exaktes BaseActorscript/Parent, get_unit_id==Key
und Registry/Knownpointeridentitaet. Kein NPCcommandprotokoll wird erfunden.

GUELTIGER APIBOUNDARY-RED24/6:
base_checkpoint-c6fb417118d84ddcb621506ec454d363/
Nur private Projektkopie benutzt den unveraenderten alten23/0-Produktstand aus
base_checkpoint-823c02aab9eb40c1a641acdb9c40e49f/project; baseline.json haelt den
DateiSHA fest. Keine Originalproduktdatei dafuer zurueckgepatcht.
FINAL GREEN30/0:
base_checkpoint-309d4429ead849f8b5d6c129c01f5fe3/
Compile/Exit0/Logs/Quelle/Originalprofil/Canary gruen. Produktfreeze.

Zwei enge Fallgruppen: Flow-/Screenersatz/Flowexit sowie Actorqueue/UnitIDwechsel/
Actorexit. Echter Snapshot midmove, echter Roottick bewegt Actor an anderen Punkt,
echte vorbereitete Tails und Root-Rueckprojektion auf Savedpose werden geprueft.
DANACH kontrollierte Mutation explizit zwischen Rootprojektion und Finalize.
Kein manuelles Actorpositionieren, keine gefaelschten Rootmodelle, KEIN Nachweis
eines nativen Canvascallbacks. Historische Abschlussmeldungen bleiben aus,
committete Modelle werden nicht zurueckgerollt. Neuer Candidate rejectet queued
Actor auch bei unveraendertem Registry-/Knownpointer. SourceRootcoordinator/
Store-/Startloaderanschluss bleibt unverdrahtet und separat.

HARNESSFEHLER, NICHT ALS PRODUKTRED VERWENDEN:
base_checkpoint-32f3fc72e7ba4840bac4fc3ffa17be55/ (23/5) sowie die folgenden
Canvaswatch-Zwischenlaeufe b1c7fd4451eb4942b672447e2082d929/Debug-POSTCASE:
Observer wurde nicht ausgeloest. Diese rot markierten Assertions belegen nur
die falsche Harnessannahme, keinen Produktbefund. Obiger APIboundary-RED24/6
ersetzt ausschliesslich diese Evidenz, keine Nativecallbackbehauptung.

Optionaler reproduzierbarer privater RED:
python output/native_glut_maps/base_action_checkpoint_v2_20261112/run.py --binding-baseline
Kein weiterer Testlauf nach Freeze, keine Gitaktionen.
