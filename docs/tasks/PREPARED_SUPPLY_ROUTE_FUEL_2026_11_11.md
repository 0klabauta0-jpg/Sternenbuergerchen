# Prepared Supply-Routentreibstoff (unverdrahtet)

## Ziel / Ursache
Nach ORBIT_DEPARTURE_ATOMICITY_AUDIT eine reine versiegelte Fuelvorbereitung für
einen späteren gemeinsamen Departurecommit bereitstellen. Heute KEINProduktcaller,
keine Root-/Adapter-/Campaign-/Travel-/Contractänderung oder bestehende Debitänderung.

## Schnittstelle / Authority
bind_route_fuel_preparation_authority(Object)->bool bindet exakte Inprocesscapability
über WeakRef bis configure/restore-reset. Zweite fremde Bindung wird abgewiesen.
prepare_route_fuel(command,context) verlangt context.route_fuel_authority als genau
dieses lebende Object; UIboolean reicht nie. Relevante Authorityflags werden reine
Boolwerte, nicht Object/ContextJSON. validate_prepared_route_fuel(candidate,authority)
prüft Siegel/Owner/Bindepoch und Inputfingerprint. Public commit validiert zuerst,
privater _publish_prepared_route_fuel(candidate,validation) ist der spätere no-fail
Tail nach gemeinsamer Rootvorprüfung. Keine Events/await/RNG in diesen Methoden.

## Umfang / Akzeptanz
Nur Fuelkey, revision+=1 und einzelner vorhandener Requestreceipt. Kein Vollrestore,
Resourceowner-/Inventarswap oder neuer Receiptstandard. Replay/Konflikt vor Fuelgates;
Revision/Epoch plus Fingerprint nur des betroffenen Craftfuelkeys (Existenz/Wert),
der Hinroute und gegebenenfalls Rückreserve (Existenz/Kosten) sowie genau des
betroffenen Requestkeys/Receipts belegen relevante Writes ohne Revision. Andere
Schiffe, Routen, Belege und Containerinitialisierung sind ausdrücklich irrelevant. Candidate hält keine veränderbaren Livealiase.
Replaycandidate schreibt nichts. Consumer/Root später separat freigeben.

## Dateien / lokale Prüfung / Grenzen
Nur scripts/core/singleplayer_supply_state.gd und eigene neue Task/Contract/QA.
8–12 kleine meaningful Ownerchecks + Compile; keine breite Matrix/GPU/Commit/
globalen Statusedits. Keine behauptete Gruppenatomizität ohne spätere Rootintegration.

Enger Nachweis12/0 und Compile0 unter docs/qa/prepared_supply_route_fuel_20261111.
Keine Produktverdrahtung oder Gruppenatomizitätsabnahme.
