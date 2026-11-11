# Prepared Supply Route Fuel

Unverdrahteter interner Owneranschluss; alte apply_command/consume_route_fuel-Pfade
bleiben unverändert. Einmal gebundene lebende Objectcapability ist Pflicht, UIflags
allein nie Authority. Bindung bleibt bis configure/erfolgreichem Restore gesperrt,
Reset invalidiert alte Kandidaten. Keine globale RNG-Nutzung für Versiegelung.

Vorbereitung ist read-only für Gameplay und Belege. Erst Replay/Konflikt, dann
bestehende Fuel-/Hin-Rückreserveprüfung. Siegel enthält Owner-ID/Bindepoch,
normalisierte primitive Flags, Command/Result und relevanten Liveinputdigest plus
Revision/Epoch. Nur tatsächliche preview_route_fuel-Inputs werden erfasst:
betroffener Craftfuelkey mit Existenz/Wert, Hinroutenkosten/Existenz, bei verlangter
Rückreserve deren Kosten/Existenz und exakt der Requestkey samt Existenz/Receipt.
Andere ReceiptIDs/Craftregistrierungen/Containerkonfiguration/Routendefinitionen
werden weder gescannt noch verursachen sie ohne relevante Revision Staleness.
Eine echte No-op-Receiptbelegung derselben RequestID bleibt auch ohne Revision
eine Staleänderung. Keine Livealiase oder vollständigen Receipt-/Inventar-/
Definitionsscans.

validate ist rein. commit validiert dann veröffentlicht nur den vorbereiteten
Fuelkey, erhöht aktuelle Revision um1 und setzt genau einen Requestreceipt.
Replay setzt kein Feld. Ressourcen-/Inventar-/Credit-/andereFuelowner bleiben
identisch. Privater _publish_prepared_route_fuel(candidate,validation) enthält
keine weiteren fehlbaren Checks/Callbacks/Signals/await. Sein validation-Token ist
nur im späteren synchronen Rootgruppencommit verwendbar: alle Kandidaten zuerst
prüfen, kein Owner-/UIwrite dazwischen. Heute kein Produktaufrufer verdrahtet.

Enger Nachweis12/0 und Compile0 unter docs/qa/prepared_supply_route_fuel_20261111.
Keine Produktverdrahtung oder Gruppenatomizitätsabnahme.
