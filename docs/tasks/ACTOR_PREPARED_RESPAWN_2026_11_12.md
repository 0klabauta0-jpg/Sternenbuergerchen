# Vorbereitete Actor-Respawnmodelle

## Ziel / Ursache
Root/Ground/RespawnManager muessen komplette Modelle vor ersten Actorcallbacks
publizieren. Bestehendes begin_respawn/respawn emittiert mitten im Actorreset.
## Umfang / Nichtziele
NUR additive neue Methoden/Handlefelder/Helfer in scripts/npc/test_unit.gd.
Keine bestehenden Weapon/AI/Runtime/Respawn/Ready/Configurebodies aendern; keine
Root/Manager/Ground/Driver-/Sharedrunnerwrites. NormalLegacysemantik unveraendert.
## API / Strategie
prepare_actor_respawn(owner,transition,world_position=Vector2.ZERO),
validate_prepared_actor_respawn, _publish_prepared_actor_respawn, finalize_actor_respawn.
Leere inprocess Handles, private bounded weak Records/Valuepatch. BEGIN aus down/
bleedout: bestehender idleBuilder und respawning-Vitals mit aktuellen HP/Bleedticks,
Command/Contact leeren, Pose und LastDamage behalten. COMPLETE aus down/bleedout/
respawning wie Legacy: fit/maxHP/0, idle, Command/Contact/LastDamage leeren.
Eligibility/exakte Actor-/Root-/Registry-/Lifecycle-/Vitals-/Runtime-/Command-
bindungen vor erstem Write pruefen. Tail nur vorvalidierte Modellzuweisungen,
keine Pose-/Visualsetter oder Signale. Finalize erst nach allen Root/Ground/
Manager-Modellen: COMPLETE WORLDpose global_position, echte Visual-/Readability-
wege, runtime/vital-Ereignisse. Mark-before-callback, reentrant veraenderte Modelle
stoppen veraltete restliche Ereignisse. Kein neues Health-/Posesystem.
## Akzeptanz / Dateien / QA
Echter TestUnit+Vitals/Runtime/UnitCommand, echter Root+Registry zur Ownerbindung,
kein gefaelschter Rootcommit. Nonzero Parenttransform; stille Tail; echte Signale/
Reentry; Eligibility/Stale/ForeignOwner/Noalias/Replay. Eigener kleiner privater
Verifier output/native_glut_maps/actor_prepared_respawn_20261112.
## Dokumente / Risiken
PROJECT_BRIEF/ARCHITECTURE/CODEX_RULES, Hexruntime-/AP6Vertrag. Root/Ground/Manager-
Groupanschluss bleibt Sourcearbeit. Canvasnotifications erst Finalize, keine
volle Respawn-/Spiel-/Performancefreigabe. Keine grossen Tests/Gitaktionen.

## Ergebnis / Freeze
EchteActorprobe20/0 inkl Compile/Exit0 und allen privaten Guards. Signalreihenfolge
BEGIN runtime->vital / COMPLETE vital->runtime, reentrantem Schaden kein altes
Folgesignal. BEGIN-Weltpos bleibt, bestehender rein medizinischer Visualwinkel
28->45Grad bleibt imFinalize erhalten (keine neue GroundFacing-Regel).
COMPLETE setzt Weltziel per global_position unter verschobenem/gedrehtem/skaliertem
Parent; echte Canvasnotifications erst nach Callerbarrier. Kein Rootmedical-
Gruppencommit gefaelscht: SourceRoot/Manager/Ticketintegration bleibt separat.
Genauere API/Bindungen und Artefakte im eigenen README/Manifest; Produktfreeze.

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
