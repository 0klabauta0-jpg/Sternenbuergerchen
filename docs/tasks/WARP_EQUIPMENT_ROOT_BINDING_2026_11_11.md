# Warp-Antrieb: enger Rootanschluss

## Ziel / Ursache
Der bestehende Plan verlangt einen funktionierenden Schiffskomponentenpfad.
Der erste Slot ist ein Warp-Antrieb: C Odyssey und A Hemera fuer explizit
kanonische Cutlass. Nutzerregel: D schwach, C, B, A hochwertig. Erkul liefert
die datierte Kompatibilitaetsreferenz, keine fertige Spielbalance.

## Umfang / Nicht-Ziele
SimulationRoot bindet einen eigenen Equipmentowner. Nur der neue Supply-Einbau
bekommt vertrauenswuerdige Prepare-/Commitcallbacks. Bestehender start_quantum
liest den exakten Craft-Effekt vom Owner. Keine zweite Uhr, keine UI-Wirkung,
keine Aenderung der Tabletop-Hex-/Move-/Tick-/Actor-/Profilbereiche.

## Abstimmung / Vertraege
Tabletop-Chat hat eigenen Equipmentbindingbereich und getrennte Dispatchhooks
freigegeben; keine seiner AP5-WIP-Bodies werden veraendert. Basis b3f9ab26d,
polisa_ship_equipment_contract, QUANTUM_DRIVE_SLICE_AUDIT_2026_11_11,
parallel_location_operations_contract und bestehende Architektur gelten.

## Betroffene Dateien / Schnittstelle
scripts/core/simulation_root.gd: configure_ship_equipment(owner), gebundener
_ship_equipment_owner und trusted Context im request_singleplayer_command.
Owner prepare_install(craft_id,slot_id,item_id,expected_revision),
commit_prepared_install(prepared,request_id), get_quantum_effect(craft_id).
campaign_start_configuration.gd benennt ausschliesslich den neu verfassten
Kampagnenstarter explizit model_id=cutlass. Alte unbekannte Definitionen werden
nicht aus Rolle oder Rendergrafik zu installierbaren Modellen umgedeutet;
ihre bisherige Reisedauer bleibt Baseline1. Skirmish und Kauf tragen bereits
explizite kanonische Modellidentitaeten.
Supply/Travel/Adapter/Checkpoint/Katalog/UI werden im abgestimmten Teilauftrag
umgesetzt, kein Eingriff in deren State durch den Rootgetter.

## Akzeptanz / kleine Pruefung
Bestehende Ownerkonfiguration bleibt kompatibel; ohne Equipmentowner Basiseffekt1.
UI-/Contextwert kann keinen anderen Warpeffekt einschleusen. Nur neuem Supplyop
werden echte Ownercallbacks bereitgestellt. Einbau/Replay/Restore/Travel werden
in kleinen Ownerchecks geprueft, Root separat kompiliert und reviewed.

## Risiken / offen
Schema/Homecheckpoint und atomarer Supplyeinbau muessen vor Verkauf zusammen
stimmen. Grosse Native-/Gefechts-/Reise-/Save-/Performancetests spaeter; keine
lokale Schiffsabholung oder neuen Fahrzeuge in diesem Slice.
