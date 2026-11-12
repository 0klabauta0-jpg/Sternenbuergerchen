# Gebundener Flowabschluss nach Surface-Retirement

## Ziel / Ursache
Travel kann Surfaceexit bereits bestaetigt haben, waehrend Controller/Root
Retirement noch warten. Flow darf weder Abschluss noch Missionsabbruch vorher
publizieren. Ein alter Retry darf keine neuen Besuche oder Rootinstanzen treffen.

## Umfang / Nichtziele
Produkt ausschliesslich scripts/meta/meta_layer_flow.gd; eigene private QA.
Kein Controller/Root/Base/Transportownerwrite, kein Travelrollback, keine
Aktivierung, kein Stage/Commit oder grosser/native Test.

## Schnittstelle / Akzeptanz
Initial retire_location_craft_visit(craft_id,unit_ids) bleibt zweistellig.
Dictionaryreceipt committed erlaubt erst den bisherigen Flowabschlusstail;
waiting speichert unveraendertes opakes retirement_binding fuer den dritten
Retryparameter. stale beendet nur den alten Retry. Weakrefs und Visit-/Root-
Kontextvergleich binden den Retry an die urspruenglichen Owner.
Legacyvoid nur fuer nichtdeklarierte Hexmissionen kompatibel.

## Dateien / Gates
get_surface_departure_retirement_guard(craft_id,location_id='') ist reine
Preflight fuer neue Surfaceaufnahmen. Sperre nur pro Craft, niemals fuer
unabhaengige Besucher desselben Ortes. Autoritative Adapter/Orbitcaller muessen
diese Grenze vor ihrem eigenen Commit respektieren; Flowguard nach fremdem
Travelcommit waere kein atomarer Ersatz. Bestehende Adapterpreview liest bereits
_find_pending_mission_craft_transfer(craft_id) unabhaengig von der Phase.
Offene Retires markieren bestehende Pendingmissiontransfers; vorhandene
Checkpoint-/Stagegates bleiben damit geschlossen. Private opake Bindung wird
nicht in UI-/Saveprojektionen kopiert. Neue Aufnahmen bekommen explizite Gates.
Vorhandener 1s Transporttimer bearbeitet hoechstens 16 Retrys je Aufruf,
Roundrobin ohne SceneTreescan oder deferred Endlosschleife.

## Pruefung / Grenzen
Kleine private echte Flowcallerprobe mit kontrollierten Controllerreceipts,
Waiting/Retry/Commit, stale Visit/Root, Legacyvoid und Hexvoid. Keine vorgetaeuschte
Root-/Groundfreigabe. Source liefert Controller/Rootpacket separat; der konkrete
RegistryAPI-Ausfall mit echten Groundintents braucht anschliessend diese Paarung.
Relevante unveraenderte Contracts: persistent_location_runtime_contract.md,
parallel_location_operations_contract.md. Opaque Binding kann root_id,
root_context, actors, lifecycles, visit_signature enthalten; der Flow liest
keines dieser Felder und persistiert das Ticket nicht.

## Implementierter Callerstand
Reine Owner-/Visitcapture und Travelread vor authorize_return (Legacy kann dort
bereits Fuel buchen), damit guardable Fehler keine Kosten verursachen.
Vor enter_space_orbit; nach positivem Receipt sofort
Record/Marker, initialer Controllercall weiter deferred mit genau diesem Record.
Frischer Visit im Deferredfenster wird nicht als alter Retire uebernommen.
Bereits gemeldetes HomeLanding bleibt im selben Record und wird erst nach
committed fortgesetzt. Modellierende Tails stehen vor dem letzten aborted-
Observerevent; kein alter Tail folgt dessen reentrantem neuen Besuch.

Private QA:18/0, exit0/cleanlog, Source/Realprofil/Canary true, changed_paths=[].
RED2/2 fuer urspruengliche Waitingcompletion, RED13/1 Observer, RED17/3 fuer
Home-/Deferredfortsetzungen archiviert. Root-/Controllerquelle bleibt separat;
Fuel-Spy RED18/1 vor letztem kleinen Reihenfolgefix ist ebenfalls archiviert.
echter Groundintent/RegistryAPI-Ausfall-Restore ist noch kein Nachweis dieses
kontrollierten Callerchecks. Keine Product-/Sharedrunnerwrites ausser Flow.
