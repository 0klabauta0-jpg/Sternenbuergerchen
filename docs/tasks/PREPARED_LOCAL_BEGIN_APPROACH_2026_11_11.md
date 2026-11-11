# Prepared Local Begin Approach (unverdrahtet)

## Ziel / Ursache
Der neue lokale Oberflaechenpfad benoetigt einen vorbereiteten Travelphasenschritt aus dem echten lokalen taktischen Orbitflight. Dieser Schritt darf weder eine Saumfreigabe erfinden noch vor dem gemeinsamen Rootcommit Flightpose, Fuel oder Campaign aendern.

## Scope / Nicht-Ziele
Nur Fleet-/Travelowner, eigene Task, eigener kurzer Contract und kleine QA. Bestehende drei Prepared-Fleet-APIs und der registrierte neunfeldrige Rootkontext bleiben; operation begin_approach kommt mit exakt typed payload {craft_id:String,location_id:String} hinzu. Kein Productcaller, Root/Flight/Adapter/Supply/Campaignedit, kein neues Gate-/UI-Token, warp_departure oder startQuantum-Prepare, kein Missionload, Event oder Debit. Alte produktive Reisecommands und deren Guards bleiben unveraendert.

## Bedingungen / Patch
Travelphase orbit, tatsächlicher Flight local+tactical. SourceArea und TargetArea sind identisch und entsprechen Flightarea und kanonischer Bodylayout-ID. location_orbits[target] muss dem echten Travelorbit entsprechen; genau dieser Body muss surface_location_id==target ausweisen. Stationen werden explizit abgewiesen. homebase bleibt im getrennten Landepfad und wird hier nicht akzeptiert.

Prepare bindet tatsaechliche Flightobjektidentitaet/CraftID/Revision/Frame/Area/Mode. Es liefert nur phase=approach, location_id=target und Revision+1 samt bestehender Receiptstruktur; keine Pose. Root muss Gate, Footprint, Claims und Registry separat autoritativ pruefen. Nach ALLEN Validierungen deaktiviert/deindiziert Root Flight und publiziert die Ownerpatches. Deshalb darf der vorvalidierte private Traveltail Flight nicht erneut lesen; public Commit nach Flightaenderung muss stale sein. finish_approach darf danach weiterhin nur als vorhandener trusted Phasenschritt bei inactive funktionieren.

## Quellen / Arbeitsbasis
Parent 346144881, Pflichtdocs und orbital_approach_contract, bestehende prepared_space_area_travel_contract und LOCAL_TRAVEL_LIFECYCLE_GUARD_2026_11_11. Echte SourceFlight Activity-API ist integriert. Kein neuer Runtimeowner oder privater Rootadapter.

## Akzeptanz / lokale Pruefung
8-10 kleine Ownerchecks: mutationsfreies Prepare, exakter Payload, Frame/Mode/Orbit/Bodybindung, Station/Home reject, Flightstaleness, private Publication nach echter Activitydeaktivierung, vorhandener finish und strategischer Warp/lokaler Exit als enge Regression. Einzelcompiles, keine grosse Matrix/GPU/Native-/Gefechtspruefung, kein Commit oder Statusedit.

## Risiken / offen
Der Kandidat ist bewusst keine geometrische Freigabe. Kein Rootgroupcommit, Debit oder Oberflaechenload ist angeschlossen. Groessere Native-, Save- und Performanceabnahme bleibt offen. Definitionsbindung allein ersetzt weder echten Saum noch Pilot/Crew-/Belegungsbeweise.

## Implementierung / enger Beleg
Die bestehende neunteilige Contextstruktur und drei Fleet-APIs wurden lediglich um begin_approach mit exakt craft_id/location_id erweitert. Travel bindet actual local+tactical Flight und den expliziten surface_location_id-Link des echten Orbitbodies. Reale Same-Orbit-Nichtoberflaeche distress_orbit, falscher Orbit/Body, Polisa-Station und homebase werden abgewiesen. Keine bestehende Commandroute oder Root/Flightdatei geaendert.

owner_check.gd meldet 10/0, runtime_wired=false. Echte Flight-Motion und Activity-API statt Modefakes. Nach gemeinsamer Validate demonstriert echte Deaktivierung den stale public Commit und den weiterhin still publizierbaren privaten Tail. finish_approach bleibt Phase-only; erfolgreicher Request replayt nach Finish ohne weitere Mutation. Strategischer Warpabschluss und vorhandener lokaler inaktiver Exit bleiben posefrei. Die Fixtureposition ist bewusst kein Saum: Travelcandidate ist kein geometrischer Accessbeleg.

Beide Einzelcompiles Exit0, Diffcheck sauber. QA: output/native_glut_maps/prepared_local_begin_approach_20261111. Default-Godotuserdir, keine Save-/Restore-/Profilwrites oder Profilguardbehauptung. Kein produktiver Root-/Surface-/Debit-/Missionloadanschluss und kein Commit/Push.
