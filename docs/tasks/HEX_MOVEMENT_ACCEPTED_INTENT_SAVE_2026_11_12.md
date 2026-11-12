# AP7-Teil: akzeptierte Bewegungsabsichten

## Ziel / Ursache
Originalziel, Commandidentitaet, Wartealter und Backoffklarung muessen kanonisch
roundtripbar sein; keine privaten Pfad-/Such-/Watcherzustandsdumps.
## Umfang / Nichtziele
Nur neue Methoden/Helfer in hex_movement_command_runtime.gd. Genau eine neue
Bindungsepochenzeile in clear ist autorisiert; configure ruft bereits clear.
Keine stage_move/tick/readout/Base/Root/Ground-/Sharedrunneraenderung.
Keine Actorcommandmutation, kein Rootcheckpointanschluss oder fullAP7.
## Schema / API
hex_movement_v1: map_id,terrain_revision,tick,serial,accepted_intents. Pro Intent
unit_id,command_id,source_command_id,goal_grid,command_intent,status,reason,
wait_ticks,next_attempt_tick,last_nav_tick,recovery. Recovery: phase,goal_grid,
clearance_grid,waiters mit unit_id/command_id/seen_passage. Originalweltziel
explizit im typisierten command_intent, nur echte bekannte UnitCommand-/Navfelder.
Max64Intents/64Waiter je Recovery,80Commandfelder/256Arraywerte, Strings256,
sichere32bitGrids und endliche Zahlen bis1e12. Unbekannte Felder/Pendingstop
rejecten explizit. Kein stiller Verlust nicht abbildbarer Absichten.

export_state, prepare_restore_state(state,target_ground=null),
validate_prepared_restore, publish_prepared_restore und privater stiller Tail.
Leerer inprocess Handle; max32 private detached Records mit weakref+Bindungsepoche.
Aktuelle Movement-/Root-/Registry-/Groundidentitaet und Revisionen, Tick, echte
RegistryActoridentitaeten und bestehende Intents werden vor Writes erneut geprueft.
Optionaler TargetGround kommt aus echtem Groundprepare/get. Rootreihenfolge:
Groundprepare/get -> Movementprepare(target) -> ALLE validate -> Groundtail ->
Movementtail -> Actorprojektion/Events. Kein Getter/Callback nach erstem Write.
Standalonepublish eines anderen TargetGround verweigert mit joint_publish_required.

Pfade/Search/Indizes/Timing/Cost-/Blockercaches entstehen neu; Status, Wartealter,
Retrydeadline und last_nav_tick bleiben. Watcher aus kanonischen Waitern ableiten.
## Akzeptanz / Pruefung / Ergebnis
Echte Ground/Movement/Planner/UnitRegistry und BasePersonnelActors; kontrolliertes
Ownerenvelope ohne NPCcommandcapabilities. Tatsachlicher Backoff, waiting_clearance,
echte Groundhandoffevents/seen und erfolgreiche Fortsetzung beider Originalziele.
Midcellweltziel/Commandabsicht/IDs, Prepare ohne Verlust, atomare Ablehnung,
Root-/Ground-/Actor-/Configurestaleness, Detach und Pendingstopguard.
RED0/1 fehlende APIs, GREEN25/0 inkl Compile, Exit0 und alle privaten Guards.
QA output/native_glut_maps/hex_movement_save_state_20261112. Produktfreeze.
## Dateien / Risiken / Dokumente
Runtime, neuer hex_movement_save_state_verifier.gd, eigene Task/QA/Runner.
AP7-Hexplan und hex_tactical_runtime_contract. Root muss Actorcommand-/Action-
fortsetzung und Checkpointkoordinator separat anschliessen. Keine grosse Matrix,
GPU oder Gitaktionen; keine volle Root-/Spiel-/Performancefreigabe.

## Reviewkorrekturen / erneuter Produktfreeze
ReverseCoverage: jedes targetGroundunit mit tatsaechlichen route_state-
has_commitments benoetigt passenden acceptedIntent. Leere/ausgelassene Intents
rejecten movement_save_missing_intent ohne Verlust vorhandener Intents und ohne
Groundmutation. Reine Zentrierung nach Stop hat keine Bewegungssegmente und darf
ohne Moveorder restauriert werden (positiver echter Stop/Zentrierungscase).

Actorbindung: echter Owner._get_unit_registry mit eigener Contextidentity;
Registry.get_unit(id) muss exakt Known-resolved Actor sein und dessen get_unit_id
muss id sein. Fehlende Registry failclosed, kein Knownfallback. Fixture priorisiert
Known Rootgetreu vor Registry; Rebind Known=A/Registry=B wird damit echt geprueft.
RED25/3: movement_save-6bdc322d565246e79b9cd9f01323336e/
GREEN30/0 inkl ActorID-/MissingRegistrycases:
movement_save-cd8e50bbbe384056ac8ddb12ef68aeed/
Exit0/Compile/Logs/Profile/Quellen/Canary gruen. Produktfreeze, keine Gitaktionen.
