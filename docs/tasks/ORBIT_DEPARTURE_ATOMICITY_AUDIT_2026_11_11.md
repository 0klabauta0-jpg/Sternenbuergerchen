# Orbit-Abflug: Readonly-Atomizitätsaudit

Stand916c388a9. Nur Quellenaudit/Notiz; keine Produktänderung, Tests, Commits,
Root-/Spaceimports. Reiner Travelcandidate wird separat vorbereitet.

## Aktueller Bruch
Adapter.authorize_departure ruft einzeln Rootcommands auf: Supply.consume_route_fuel,
Campaign.bind_departure, optional Campaign.activate_job; dann Adaptertoken. Erst
danach folgt im space_begin_approach Travel.begin_approach. Jeder Rootcommand
emittiert sofort singleplayer_command_committed. Deshalb sind zwischen allen
Schritten Fehler und synchrone Listener-/Reentranz möglich; kein gemeinsamer Commit.

Mutationen: Supply setzt Fuel und Revision, apply_command danach Requestreceipt;
Campaign setzt craftDeparture+Revision, Jobstatus/craft+Revision und jeweils eigene
Requestreceipts. Adapter setzt _departure_token_by_craft; Travelphase/Receipt und
Adapter._space_operation_requests folgen später. Auch vorhandener äußerer Replay
vor Gates macht einen frisch fehlgeschlagenen Teilcommit nicht rückgängig.

Wichtig: validate_departure ist selbst nicht rein. observe_campaign_progress()
ruft Chiprecovery (Supply) und Onboardingobserve/Rootsignal auf. Für einen wirklich
reinen Prepare diese Observation aus dem Validator in bestehende Lifecycleevents
verlagern; nicht still einen vierten Candidate-/Recoveryowner hinzufügen.

## Existierende Wiederverwendung und Grenze
Supply.preview_route_fuel und Campaign.validate_departure sind reine Gates;
beide apply_command-Pfade haben bereits Signatur/Replays vor ihren Mutationen.
Commandbuilder/Result-/Receiptformate müssen erhalten bleiben. Es existiert aber
KEINE allgemeine ownerinterne clone/adopt/publish API für Supply/Campaign.

export_state/restore_state nicht als Live-Transaktionsswap verwenden:
- Campaignrestore rekonstruiert aus Dateien und _validate_saved_state erlaubt bei
  aktiven Departures nur Pads aus _locations, nicht built_home_pad_ids03..06.
  Ein legitimer Runtimezustand kann daher trotz gültigem Departuregate scheitern.
- Supplyrestore rekonstruiert LocationResourceowner und übernimmt frische Referenzen;
  ein Vollswap könnte gebundene Runtimeconsumer/ausstehende Ressourcenbelege verlieren.
- Datei-I/O, Definitionmigration, große Inventare/Receipthistorien und Savevalidierung
  gehören nicht in den garantierten Publicationtail. Saveformat ist keine Runtimefork.

Revision allein reicht nicht: Supply.register_craft/configure_inventory schreiben
ohne _revision; erfolgreiche already_rewarded/Research-Noops können neue Receipts
ohne Gameplayrevision erzeugen; Campaign.activate_job already_active ebenso.
Ein Prepare muss benötigte Daten UND betroffene Ledgerkeys belegen, nicht nur _revision.

## Kleinste vorgeschlagene Owner-APIs (spätere Implementierung)
Supply.prepare_route_fuel(command,authority_context)->sealedCandidate:
Replay/Konflikt zuerst, bestehendes preview; nur betroffene Craftfuelvorher/nachher,
Routen-/Reservefakten, eigener Requestkey, Result/Receipt und erwartete Inputs.
Supply.validate_prepared_route_fuel(candidate)->Dictionary (rein).
Supply._publish_prepared_route_fuel(candidate): ausschließlich Fuelkeyassign,
aktuelles revision+=1 und vorgebauten Receiptkey schreiben. Keine anderen Felder
ersetzen, keine Dateizugriffe/Callbacks/Signals/weitere Validierung im Tail.

Campaign.prepare_departure(binding_command,activation_command_or_empty,context):
bestehende Bind-/Aktivierungslogik auf PRIVATER kleiner Runtimekopie oder einem
reinen Transitionhelper ausführen, nicht über restore_state. Liefert nur Patch für
craftBinding, optional Jobstatus/craft, beide bestehende Receiptformate sowie
Revisionsdelta. Geprüfte Inputs umfassen selection/job/status/craft, bestehenden
Bindingkey, beide Ledgerkeys und autorisierte gebaute Pads.
Campaign.validate_prepared_departure(candidate) und _publish_prepared_departure
mit demselben read-check/no-fail-Patchvertrag. Keine zweite persistente Wahrheit:
Candidate ist kurzlebiger versiegelter Übergang, Owner bleibt derselbe RefCounted.

Frische Owneridentität+privates Seal+relevanter Input-/Ledgerfingerprint gegen
Stale/Tampering; kein vom UI geliefertes authority_context. Ein lückenloser interner
Mutationepoch wäre Alternative, braucht aber konsequent jeden Writepfad und ist
für diesen Slice breiter. Teilpatches vermeiden Überschreiben fremder Inventar-,
Ressourcen-, Job- oder Craftänderungen. Kandidat darf keine Live-Dictionaryaliase halten.

## Gemeinsame Root-/Adaptergrenze, später zu verdrahten
1 Äußeren Operationsreplay/-konflikt zuerst prüfen. Stabile Transaktions-ID aus
  session+craft+Operationrequest ableiten, nicht allein _transfer_sequence+1.
2 Pure Pilot/Payload/Pad/Job/Map-/Saum-/Flightgates; vorbereiteten Travelcandidate,
  Supplycandidate und Campaigncandidate mit denselben IDs/Inputs erzeugen.
3 Unmittelbar vor Publication ALLE Owneridentitäten/Seals/Inputfingerprints und
  Actor-/Flight-/Area-/Pilot-/Transferbeweise erneut gemeinsam prüfen. Keine
  Ownerwrite, bevor auch der letzte Candidate sicher publizierbar ist.
4 Root publiziert Supplypatch, Campaignpatch und Travelcandidate synchron ohne
  irgendein Signal/await/Callback mit Gameplayreentranz. Nach Beginn keine
  fehlbare apply_command/restore/Filescan-/Mapload-/Registryaufnahme mehr.
5 Adapter publiziert Token und äußeren Operationsbeleg ebenfalls vor Benachrichtigung.
  Root bietet dafür schmale Commit-ohne-Signal plus finalize-Schnittstelle oder
  gebundenen no-fail Adapterpublicationtail. Erst DANACH bestehende/aggregierte
  Commandsignale senden. Jeder Listener sieht vollständig konsistenten Stand.
6 Erst nach Commit Flow._begin_space_approach/Scene-/Encounterprojektion auslösen.
  Deren späterer Ladefehler ist kein halbcommitteter Ownertransaktionsfehler;
  eigene Recoverypolitik braucht separate Freigabe, keine pauschale Fuelrefund.

SubrequestIDs bleiben Fuel/Bind/Activate eindeutig und crossreferenziert; äußere
Erfolgsreplay darf weder LastToken umschreiben noch erneut Szenenstart auslösen.
Ein einzelner alter Subreceipt ohne vollständigen Gruppenbeleg ist KEIN Beweis für
eine komplett wiederholbare Abfahrt. Legacy-Teilstände nicht durch bloße Refunds
oder als bereits erfolgreich erraten; eindeutige Reject-/Migrationregel festlegen.
Optional job_id leer heißt genau kein Activationpatch, kein Phantomauftrag.

## Minimaler späterer Dateibesitz
SupplyState+CampaignState: eigene kleine Prepare/Validate/Publishhelper, bestehende
Contracts/Save-/Receiptformate behalten. Adapter: pure Gates/Token und gemeinsamer
Departurepfad. SimulationRoot: erst später eng abgestimmter Groupcommit/finalize,
kein heutiger Import. Travelcandidate/Fleet/SpaceFlight bleiben beim zugeteilten
Orbit-/Spaceowner. Kein neuer Economy-/Departureowner, keine Inventarvollmigration.

## Späterer enger Nachweis, heute nicht ausgeführt
Rejected Travel/Bind/Activation und stale Fuel/Job/Ledger/Pilot/Saum ändern keinen
Owner/Token und emittieren kein Signal. Leerer Job, aktivierter Job, Replay/Konflikt,
legitimes gebautes Pad03..06; Ressourcenownerreferenzen unverändert. Synchroner
Listener sieht erst kompletten Commit, Reentranz kann keinen Teilstand nutzen.
Kein großer Testlauf oder pauschaler Saveumbau für diesen Auditauftrag.
