# AP7 Basisaktionscheckpoint V2

## Ziel / Ursache
Legacyexport v1 stuft laufende Aktionen auf outside und verliert Token/Zweck/
Sequence/Resttimer. Neuer separater Export erhaelt kanonische Aktionen gemeinsam
mit vorbereiteten Ground-/Movementzielen, ohne zweite Positionswahrheit.
## Umfang / Nichtziele
NUR additive V2/Preparedrestore/Helfer in base_personnel_runtime.gd, plus freigegebener
neuer read-only Movement.get_prepared_restore_state. Legacyexport/configure, Tick/
Walk/Boarding/Remotehandoff/Padmethoden unveraendert. Keine Root/Store/Screen/
Netz-/Sharedrunnerwrites, keine neue Pause-/Gameplayregel oder fullAP7.
## Schema / API
export_checkpoint_state()->{version:2,map_id,topology,grid_frame,sequence,
poll_seconds,rest_elapsed,units}. Unitwerte: status,craft_id,bed_id,action,
auto_rest_enabled,rest_automatic,idle_seconds,manual_priority_seconds. Auf Hex
KEINE Actorposition. action: type,target:[worldx,y],command_token plus sleep-
bed_id/automatic oder terminal_id. Boarding,Boardgroups,Transportcommit und
Admissionpending bleiben expliziter Saveguard.
prepare_restore_state(state,groundPrepared,movementPrepared), validate_prepared_restore,
assignments-only _publish_prepared_restore und finalize_prepared_restore. Opaque
weak bounded Handle, komplette genaue Actor-/Owner-/Root-/Map-/Registrybindung.
TargetGround aus echtem Groundgetter, TargetMovement aus validiertem kopiertem
kanonischem Movementgetter; Baseactions exakt gegen SourceIDs/Worldziel/Gridziel
pruefen. Sequence >=ALLE base:n Tokens auch Archivorders. Schlafbetten und
Reservierungen aus sleeping UND moving-sleep ableiten, Duplikate ablehnen.
## Akzeptanz / Pruefung
Kleine echte Root/Ground/Movement/BaseActors/Baseownerprobe auf12feinen16/8Feldern
mit Bett-/TerminalIDs des Basislayouts. Atomic full validation, keine Actorwrites
im Tail. Nach allen Modellen SourceRootprojektion, dann ein state_changed.
Sleep/Terminal/Waittoken/Sequence/AutoResttimer, Legacyv1 unveraendert,
fehlende/ungueltige Matches/Betten/Boarding/Stale/Noalias/Replay failclosed.
## Dateien / Risiken
Eigene QA output/native_glut_maps/base_action_checkpoint_v2_20261112. Rootcomposite/
CheckpointStore/Startloader separat Sourceowned; neueV2 NIE an altenLoader uebergeben.
Tatsaechliche Navigation384x392/16x8; Map-/Framebinding statt coarseRender64/32.
Keine150528Felder-/Performance-/Netzmatrix oder Gitaktionen.

## Ergebnis / Freeze
30/0 (inklusive enger Finalize-Bindungsfaelle), echte12-Felder16/8-Ownerprobe mit Root/Base/Ground/Movement/BaseActors und
Screen, private Compile/Exit0 und alle Guards gruen. Sleep+Terminalaktionen ueber
wirkliche Base.request_operation erzeugt, gemeinsame Owner-Tails silent, Root-
projektion vor genau einem Basissignal; echteTickfortsetzung erfuellt beide Zwecke.
V1 bleibt unveraendert. Aboardmitgliedschaft gegen echte aktuelle Pilot/Payload-
owner geprueft/stalenessgebunden; Source muss Zieltransport vor Baseprepare laden.
JSONframewerte strikt nach nativerVector2-Normalisierung vergleichen. ExakteAPI,
fehlendeRoot/Store/Startloaderintegration und alleArtefakte im QA README/Manifest.

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
