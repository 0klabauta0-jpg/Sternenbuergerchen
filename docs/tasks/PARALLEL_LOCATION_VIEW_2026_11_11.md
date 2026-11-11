# Mehrortansicht ohne Reise- oder Besuchsmutation

## Ziel / Ursache
Geladene Orte laufen bereits weiter, aber der normale Basiszugang wird bei fremden Reisen umgeleitet. Hintergrundabfahrt/-ankunft kann zudem einen anderen betrachteten Ort wegschalten. Shopwahl und Reise-/Missionsidentitaet muessen getrennt bleiben.

## Scope / Nicht-Ziele
Zentraler View-only Einstieg und gepruefte UI-Schiffwahl in MetaLayerFlow, separater immer erreichbarer Basisbutton und geladene Ortsbuttons in StarMapScreen, ausschliesslich Homebase-Zweig der Sandboxnavigation. Keine neue Simulation, keine Transport-/Crew-/Besuchszustaende, keine Save- oder Kaufwahrheit. Adapter/Services/Polisapanel gehoeren dem anderen Agenten; Tabletop besitzt Movement/Root/Driver.

## Vertraege / Schnittstellen
PARALLEL_LOCATION_OPERATIONS_2026_11_11, persistent_location_runtime_contract, singleplayer_locations_jobs_contract, orbit_quantum_travel_contract, location_view_selection_contract. Public open_location_view(location_id,craft_id=''), get_location_view_snapshot()->{view,location_id,craft_id}, select_location_view_craft(location_id,craft_id)->Dictionary. _view_craft_by_location ist nur UI-Auswahl; kein Fallback aus Reise- oder Besuchsidentitaet.

## Akzeptanz
- Basisansicht auch waehrend fremdem Orbit/Quantum/Approach; vorhandene Abflug-/Boarding-/Anflug-/Kaufgates unveraendert.
- Wechsel zu geladenem Ort fokussiert vorhandenen Root ohne admit/configure/clear; versteckte Roots ticken weiter.
- Auswahl prueft bekannte Craftdefinition und aktuelle Flow-Ortszuordnung; stale/fehlende Auswahl ergibt keinen Serviceschiff-Fallback.
- Hintergrundankunft/-abfahrt/-callback erhaelt den fremden View/Context. Primaerauftragsabbruch und tatsaechliches Crewretire bleiben erhalten.
- Vorhandenen Driver-Zeitursprung und Zeitlimit pro Ort korrekt lesen/anzeigen, keinen neuen Simulationsclock erzeugen.

## Dateien / Pruefung / Grenzen
scripts/meta/meta_layer_flow.gd, scripts/ui/star_map_screen.gd, nur _navigate_to_meta_view/homebase in scripts/tests/mission_tactical_sandbox_controller.gd. Eigener winziger Headlessfixture mit zwei Ortsroots und getrennten Driverclockfakten, keine GPU-/Gefechts-/Save-/Netzmatrix. Background-Approach ist echte Ankunft/Admission, kein blosser Viewwechsel; nur ihr Anzeigeeffekt wird begrenzt. Interaktive Schiffsauswahl-/Render-/echte Mehrortreiseabnahme spaeter. Kein Commit/Push durch Teilagenten.

## Lokaler Beleg 2026-11-11
44/0 kleine Headlesschecks mit zwei Fake-Ortsroots und echten Flow-/StarMapScreen-Methoden. Beide Roots ticken bei verstecktem B weiter; Home waehrend Quantum, Kontext/Identitaet/Clock, kein Admission bei Navigation, stale Auswahl, reale Retire-/Primaerabortpfade, sekundaerer Abflug am selben Ort, fremde Hintergrundankunft sowie Anzeige-Follow des Sternkarten-Reisecraft geprueft. Echte Approach-Admission/Transporthelfer sind im Fixture begrenzte Spies; dies ist keine Reise-/Crew-/Gefechtsfreigabe.

Vier Produktdateien separat mit Godot 4.6.2 check-only kompiliert. git diff --check sauber. Fixture und Logs: output/native_glut_maps/parallel_location_view_20261111/. Beim echten StarMapScreen-Aufbau fand der Fixture einen bestehenden fehlenden polisa_orbit-Key in star_map_canvas.gd:label_directions; Root gab die einzelne Ergaenzung ausdruecklich frei. Kein Lookdev geaendert. Deshalb vierte Produktdatei im Slice: scripts/ui/star_map_canvas.gd.

Offen: native Bedien-/Darstellungspruefung, tatsaechliche parallele Gefechte/Reisen/Shopkaeufe, Save/Load. Der bestehende Legacy-Rueckkehrpfad _finish_singleplayer_visit_if_returned bleibt unveraendert. Kein Commit oder Push durch Teilagenten.

Review-Folge: Bei Arrival/Callback in denselben aktiven Root wird der Kontext vor Anzeige-Restore erneut aus dessen aktuellem Controller/Setup/Driver abgeleitet. Die vorherige UI-Kopie darf real eingetroffenen Nachschub nicht spaeter zurueckschreiben. Vier Zusatzchecks pruefen geaenderte Planung/Setup sowohl bei sichtbarer Same-Root-Ankunft als auch verborgenem Same-Root-Callback aus der Basisansicht. Gesamtergebnis 44/0. Basis-Servicepanel bleibt bei fehlender Welt-Schiffauswahl erreichbar; explizite Auswahl gehoert nur dem Flow-DTO, alte Presenter-Direktsetzung entfernt (mit Backendowner abgestimmt).

Terminaler Review-Folgepfad: Restore bekommt den tatsaechlich aktualisierten Root explizit von Approach/Callback. Auch wenn echter _release_active_mission den aktiven Zeiger bereits genullt hat, wird der weiterhin registrierte gleiche Root aus seinem lebenden Controller/Setup reprojiziert. Zwei Zusatzchecks fuer terminalen versteckten Callback mit echtem Release; 44/0, Meta-Compile erneut sauber.
