# Prepared Actor Respawn - Produktfreeze

NUR additive neue APIs/Helfer/Handlefelder in scripts/npc/test_unit.gd.
Legacy begin_respawn/respawn/activate_for_wave, Weapon/AI/Runtime/Ready unveraendert.
Kein neues Healthmodell: dieselben echten UnitVitalStatus-/UnitRuntimeStatus-
Builder und Felder wie vorhandene Methoden. Root/Ground/Manageranschluss separat.

API:
prepare_actor_respawn(owner:Node,transition:String,world_position:Vector2=Vector2.ZERO)
 -> {ok,prepared:RefCounted}
validate_prepared_actor_respawn(prepared:RefCounted)->{ok,prepared_id}
_publish_prepared_actor_respawn(prepared:RefCounted,validation:Dictionary)->{ok}
finalize_actor_respawn(prepared:RefCounted)->Dictionary

transition begin: down/bleedout -> respawning, aktuelleHP/Bleedticks bleiben,
idleRuntime, Command/Contact leer, LastDamage/Weltposition bleiben.
transition complete: down/bleedout/respawning -> fit/maxHP/0, idleRuntime,
Command/Contact/LastDamage leer. COMPLETE WORLDziel ist ein Rootwert, keine neue
Actorpositionswahrheit. Poseprojektion global_position erst in Finalize.

Handle leer/inprocess; max32 private Records mit weakref und Konsumepoche.
Prepare/Validate pruefen Root/UnitRegistry/Known==dieserActor, Rootlifecycle,
Actor-/Unit-/Team-/FTidentitaet, Parent-/Welttransform, echte Vitals-/Runtime-/
Commandobjekte und deren Werte, MaxHP/Contact/LastDamage, Manager/Terrainbindung.
Keine Actorconfigureepoch oder andere bestehende Bodies geaendert. Vorhandene
Vitals-/Runtimeobjektwechsel und RootLifecycle dienen als bestehende Resetbelege.

Root muss ALLE Teilnehmer vor erstem Write validieren, Ground/Ticket/Manager/
Actormodelle still publizieren und erst danach Actorfinalize aufrufen. Privater
Actortail nur Modellzuweisungen und Bridgephase/epoch, keinerlei Canvas-/Visual-
setter, Callback oder Signals. Finalize markiert vor Pose-/Visualcallbacks
konsumiert; Lifetime/gebundenenActor/Owner/Postmodelwerte nach jedem Callback
erneut pruefen. Veraenderter Kontext stoppt Restereignisse/Visualupdates mit
ok/context_changed (kein spaeter Transaktionsreject). Medizinische Reihenfolge
unveraendert: BEGIN runtime -> vital, COMPLETE vital -> runtime; alle Modelle
sind bereits vor beiden Ereignissen vollstaendig. BEGIN-Weltposition bleibt,
vorhandener Down28/Respawning45Grad-Visualwinkel wird per echtem Visualweg gesetzt;
dies ist keine neue logische Facing-/Groundpose-Regel.

RED0/1 fehlende APIs:
actor_respawn-1789dc73b403493a8e23e2480e5c6789/
GREEN20/0 inklusive privatem Import/Compile:
actor_respawn-92db2e269f314f56b96a661a3e50e832/
Exit0, saubere Logs, Quellen/Originalprofil unveraendert, privaterCanary.

Echte TestUnit/UnitVitals/Runtime/UnitCommand, echte SimulationRoot/UnitRegistry/
RespawnManager zur Ownerbindung; keine FakeRootmedicalcommits. Verifier steuert
nur den APIbarrier: Actorpub, erst Callerbarrier, dann Finalize. Medizinischer
Gruppenticket-/Ground-/Manageranschluss ist KEIN Ergebnis dieses Actorchecks.
Echte Canvastransformnotifications ueber beobachtendes Kind unter Actor pruefen
vollstaendige Modelle/Barrier. Nonzero Parenttranslation+Rotation+Skalierung,
BEGINpos unveraendert; COMPLETE global statt local. Echte Signal-/Reentrychecks,
realer apply_damage-Observer stoppt altes Folgesignal. Fiteligibility, Bleedout,
InplaceVitals/Commandmutation, echter RootLifecycle, FremdRoot/Actor, Objektnoalias
und Konsumreplay enthalten. Keine groessere Matrix, GPU oder Spielabnahme.

python output/native_glut_maps/actor_prepared_respawn_20261112/run.py
Eigener privater Projekt-/Userrunner mit realer Preloadclosure. Keine Gitaktionen.

## Reviewfix: Rootwelt auch nach Publish binden
_actor_respawn_can_finalize prueft nach OwnerAlive-/RegistryActorbindung die
Rootidentity.context gegen source.lifecycle.context. Nur der Weltkontext muss
unveraendert sein; legitime per-unit Lifecycle-/Receiptfortschritte bleiben erlaubt.
Echter SameRoot/SameUnitRegistry configure_hex_ground_runtime Wechsel vorFinalize
verhindert alte WORLDpose und beide Events; Wechsel im ersten COMPLETE-Vital-
bzw BEGIN-Runtimecallback verhindert jeweils das veraltete zweite Signal.
Im COMPLETEcallback gesetzte neue Pose wird nicht zurueckgesetzt.
RED21/3: actor_respawn-779403e5bc3a4b6d888fead5f4cd1199/
GREEN24/0: actor_respawn-168309dc325241249aaf454cbe9d582d/
Compile/Exit0/saubereLogs/Source-/Profil-/Canaryguards gruen. Produktfreeze.
Keine Root-/LegacyActorbodies geaendert, SourceRootverbund weiterhin separat.
