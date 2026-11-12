# AP7 Movement Hostsave - Produktfreeze

25/0 inklusive privatem Godot4.6.2 Import/Compile, Exit0/saubere Logs,
Originalprofil und Quellsha unveraendert, privateCanary vorhanden:
movement_save-d09012c87e264814b082ddda12ea0459/
RED0/1 fehlende APIs: movement_save-37bc00436e794c6e9cb30ab9327b9ae0/

Schema und Grenzen: siehe docs/tasks/HEX_MOVEMENT_ACCEPTED_INTENT_SAVE_2026_11_12.md.
Runtime nur additive neue APIs/Helfer/Handleklasse/2Variablen und genau eine
Epochenzeile in clear; stage_move/tick/readout und andere Produktdateien unberuehrt.

API:
export_state()->Dictionary
prepare_restore_state(state:Dictionary,target_ground=null)->{ok,prepared}
validate_prepared_restore(prepared:RefCounted)->{ok,prepared_id}
publish_prepared_restore(prepared:RefCounted)->Dictionary
_publish_prepared_restore(prepared:RefCounted,validation:Dictionary)->Dictionary

Handle ist leer, inprocess und nicht aus JSON ableitbar. Private Records enthalten
detached normalisierte Patches; max32/weakref/Epochenbindung. Keine Authoritybools.
Alle Bindungen vor erstem Write pruefen; private Tails nur fuer validierte synchrone
Roottransaktion. Publicpublish verweigert anderen TargetGround. Gemeinsamer Case
benutzt echte neue Groundprepare/get/validate und Groundtail -> Movementtail ohne
spaete Getter/Callbacks. Kein Rootcheckpointanschluss, keine Actorcommandmutation.

Probe nutzt echte BasePersonnelActors, UnitRegistry, Ground, Movement und Planner;
Owner ist kontrolliertes Envelope mit echten Registrylookups, keine NPCfakes.
Echte Navigation erzeugt Backoff; reales waiting_clearance und echte Groundevents
beweisen Passage. Seen bleibt erhalten, Watcher werden neu abgeleitet, beide
Originalziele nach Restore erreicht. Weitere Cases: Midcellweltziel, IDs,
Commandabsicht, Waitage/Retrydeadline, Detach, atomare Ablehnung, Ground-/Root-/
Actor-/Configurestaleness, Pendingstop und vorbereiteter TargetGround.

Zwischenlauf c70455e8a5004016af5aeb0f4089a310:23/0, Runner erwartete24 (Metadatenfehler).
Zwischenlauf 81496da644de42a8bb8367ca69b82b46:24/1; schneller einfacher Swap passierte
vor waiting_clearance. Fixture fuer beabsichtigte Wartephase auf langsameren
FarGoalverkehr umgestellt, kein Produktfix dafuer. Frueherer23/0 verwendete
kontrolliertes seen-Event; finaler25/0 ausschliesslich echte Groundevents.

python output/native_glut_maps/hex_movement_save_state_20261112/run.py
Keine Hauptszene/GPU/grosse Matrix/Gitaktionen; keine Gesamtfreigabe.

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
