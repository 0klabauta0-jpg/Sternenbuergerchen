# Movementsave: echter transienter Rootstempel - Produktfreeze

Echte SimulationRoot.enqueue_command erzeugt _hex_lifecycle aus context/lifecycle/
actor. Die vorherige Savewhitelist wies diese normalen Rootcommands als unsupported
ab. Nur _save_pack_command wurde um strikte transiente Behandlung erweitert:
exakt drei Keys, echte TYPE_INT, context/lifecycle>=0, actor>0; danach gebundener
Owner._is_current_hex_payload(command). Erst nach gueltigem Echtheits-/Epochcheck
wird _hex_lifecycle beim kanonischen Packen ausgelassen. Livecommand bleibt gleich.
Kein ObjectID im portablen Hostsave. Stale/malformed/unknownMarker rejecten klar.
Restore bleibt unstamped, bestehende Owner/Actor/Registry/Groundprepared Bindungen
bleiben bestehen. Nachfolgende echte Rootenqueue stempelt Commands selbst frisch.
Normale unbekannte Felder und Marker im restore command_intent bleiben verboten.

Echte Rootprobe: SimulationRoot+TerrainRegistry+UnitRegistry+Ground+Movement,
12 Hexfelder, ein Node2D-Actor mit bestehendem NPCCommandprotokoll. Kein Rootdouble,
keine bereinigte _orders.command-Fixture; Marker stammt aus echter enqueue_command
und gespeichertem echten _physics_process. Rootfile/Stage/Tick/Readout unberuehrt.

RED1/1 (gueltiger echter Rootcommand wird vom Save abgewiesen):
movement_root_stamp-099b2f86c4e2459095b0ce4fede761e7/
GREEN9/0 incl private Import/Compile:
movement_root_stamp-65e725b0e9744eb9b1751509342e4bfc/
Exit0/sauberes Log/Source-/Originalprofilidentitaet/privater Canary gruen.
Cases: Rootgeneration, kanonischer Export, kein Marker/keine Livemutation,
stale Context, unbekannte Stampkeys, Float-ObjectID, unbekannter Hostmarker,
portable Restore ohne Stempel mit echter SourceID, frische spaetere Rootenqueue.

Eigener Runner, privater Projekt-/Userkontext und echte Preloadclosure:
python output/native_glut_maps/hex_movement_transient_root_stamp_20261112/run.py
Keine Hauptszene/GPU/grosse Matrix/Gitaktionen. AP8Jointest beim Parent separat;
keine volle Rootcheckpoint-/Spiel-/Performancefreigabe aus dieser Ownerprobe.
