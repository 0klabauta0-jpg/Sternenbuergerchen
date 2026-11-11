# Prepared Supply Route Fuel – unverdrahteter Owner-Slice

Baseline3fb8d2985; nur SingleplayerSupplyState plus eigene neue Doku/QA geändert.
Kein Root-/Adapter-/Campaign-/Travel-/Sharedhelperedit. Keine Produktcaller, alten
Commands unverändert. Kein Commit/Push/GPU/große Matrix oder Gruppenatomizitätsclaim.

## Vorhandene API
bind_route_fuel_preparation_authority(Object)->bool: feste lebende Objectidentität
bis configure/erfolgreichem Restore; andere Bindung abgewiesen. Coordinator soll
eine private opaque Inprocesscapability verwenden und sie nie an UI exportieren.
prepare_route_fuel(command,context) verlangt context.route_fuel_authority und
normale bestehende Routingflags. validate_prepared_route_fuel(candidate,authority)
rein; commit_prepared_route_fuel validiert dann privat
_publish_prepared_route_fuel(candidate,validation). Letzterer publiziert nur
abgetrennten geprüften Patch ohne weitere fehlbare Checks/Events/await.

Defaultunbound, Bindepoch, OwnerID, privates RNGfreies Siegel, Kontextflags und
gezielter Craftfuel-/Hinroute-/ggf. Rückreserve-/einzelner Requestreceipt-Digest
plus Revision/Epoch schützen Prepare/Commit. Keine Scans vollständiger Definitions-,
Fuel-, Request- oder Inventarhistorien. Unverwandte Container-/Craft-/Beleg-/
Routenänderungen ohne Revision lassen den Kandidaten ausdrücklich gültig. Keine Ressourcen-/Inventar-/Credit-/anderenFuelwerte ersetzt.
Replays werden frisch vorbereitet und publizieren nichts; alter bereits angewandter
Applycandidate wird stale statt zweimal abzubuchen. Querykandidaten sind keine Saves.

## Begrenzter Nachweis
Direkt ausführbare QAfixture check.gd:12/0, Exit0, keineScript-/Enginefehler/Leaks.
- unbound/UIbool, feste Objectbindung/fremde Capability und keineRNGbeeinflussung;
- reine Vorbereitung/ungültige Route/Flags;
- exaktes Result/Fuel/Revision/Receipt gegen bisherigen echten apply_command-Pfad,
  Resourceowneridentität unverändert;
- Replay vor fehlender Fuelreserve, Konflikt ohne Writes;
- Siegel-/Fremdowner-/falscheObjectidentität;
- spätes Fuel/Revisionupdate; echte already_rewarded-Noopreceipt unter fremder ID
  bleibt gültig, unter derselben vorbereiteten RequestID ohne Revision stale;
- fremdes register_craft/configure_inventory bleibt gültig, Fehlen/Neuregistrierung
  mit geändertem Fuel desselben Crafts ohne Revision wird stale;
- fremde Routendefinition bleibt gültig, Rückreserveänderung stale; Configure/Rebind;
- Command-/Candidate-/Validationpatch-Aliasfreiheit und echter stiller Tail.
Supply --headless --check-only0. Erster Fixturelauf hatte nur einen Parse-Typfehler,
zweiter eine falsche Annahme über vorhandenen Resourcekey polisa; beideFixturefehler
vor finalem12/0 korrigiert. Keine breiten Regressionen angehängt.

## Spätere Integration
Root muss ALLE Owner/Flight/Wing/Registry-Gates validieren, bevor ein Publisher
läuft, und darf keine Reentranz/await oder überlappende Fuel-/Receiptpatches zwischen
Vorprüfung und Tail zulassen. Noch kein Produktaufrufer bindet die Capability;
kein bisheriger Debit-/Reise-/Savepfad ist hier auf Prepared umgestellt.

Reviewkorrektur: genau drei bestehende Cases auf relevante Keys verengt; weiterhin
12/0 und Compile0 frisch, keine zusätzliche Matrix oder Produktverdrahtung.
