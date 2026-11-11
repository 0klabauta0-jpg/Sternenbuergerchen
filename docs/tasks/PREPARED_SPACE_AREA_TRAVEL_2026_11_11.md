# Prepared Fleet-/Travel-Bereichsuebergang: unverdrahteter Kandidat

## Ziel / Ursache
Der kuenftige Rootuebergang muss Reisephase und Flight-/Bereichsaufnahme gemeinsam validieren und ohne nachtraeglichen strategischen Posewrite publizieren. Alte apply_command/_arrive-Pfade sind dafuer kein stiller Transaktionstail. Dieser Slice bereitet ausschliesslich den vorhandenen Reiseowner vor.

## Scope / Nicht-Ziele
Kanonische Prepare/Validate/Commit-Delegation am Fleetowner, private mutationsfreie Vorbereitung und signal-/awaitfreier Zustandspublish im vorhandenen Travelowner. Nur advance, wenn ein echter aktiver Quantumflug durch das konkrete Delta abgeschlossen wird, sowie existierendes surface/approach -> enter_orbit. Keine neue warp_arrival-Phase. Kein produktiver Aufrufer und keine Aenderung an Root, Flight, View, Adapter, Fuel, Campaign, Surfaceanflug, Gates oder Maps. Keine zweite Pose; vorbereitete Zustandsdaten duerfen keine Flightposition schreiben.

## Vertraege / Arbeitsbasis
HEAD 916c388a9 im isolierten gemeinsamen Integrationsworktree. Pflichtdocs, ORBITAL_APPROACH_MAPS_2026_11_11, orbital_approach_contract und eigener prepared_space_area_travel_contract. SpaceChat hat Dateibesitz fuer diese beiden Reiseowner bestaetigt; Root implementiert spaeter den atomaren gemeinsamen Tail.

## API / Authoritygrenze
prepare_space_area_transition(craft_id,expected_travel_revision,source_area_id,target_area_id,root_context), validate_prepared_space_area_transition(candidate,root_context), commit_prepared_space_area_transition(candidate,root_context).

Vorher explizites Initialsetup: configure_space_area_transition_authority(authority:Object) und bind_space_area_transition_context(root_context,authority). Context enthaelt request_id, request_signature (Rootkanon), operation, typed payload, source_area_id, target_area_id, expected_travel_revision, expected_phase, context_id. Vollstaendige Bindung statt runtime_authorized-Bool oder frei erfindbarer Context-ID. Registrierte Contexts/Candidates werden durch Lifecycleconfigure invalidiert. Authority darf nicht per Replay oder beliebigem zweiten Setup uebernommen werden.

Dies ist eine vertrauenswuerdige Inprocessschnittstelle, keine Sicherheitsbarriere gegen Code mit Zugriff auf dieselben Objektinternas. Private Ownersiegel/Revisionen dienen reproduzierbarer Integritaet, nicht der Behauptung kryptographischer Isolation. Kein produktiver Commandrouter bietet die API an.

Kanonische IDs sind mit Root/SpaceChat geklaert: SourceArea ist fuer beide Operationen leer, TargetArea ist die orbit_approach:-LayoutID des tatsaechlich passenden kanonischen Body aus Orbit-/Locationdefinition. Keine orbit:- oder surface:-ID einfuehren. Der alte Auditentwurf ist historisch. Diese Plausibilitaetsbindung beweist keine echte Flightposition oder Registrybelegung; deren Freigabe bleibt Rootaufgabe.

## Akzeptanz / kleine lokale Pruefung
Prepare aendert keinen Gameplayzustand; Owner/Revision/Gesamtkontext und Kandidateninhalt werden erneut geprueft. Geaenderte Request-ID-Nutzung wird abgewiesen, identische erfolgreiche Wiederholung gibt denselben Beleg ohne weitere Mutation. Lifecycle-Reset und Austausch eines Craftowners invalidieren alte Kandidaten. Commit schreibt nur vorher validierte Reisephasendaten, ohne apply_command, _arrive, Signale oder Posewrites. 15 gezielte kleine Checks und zwei Compilepruefungen, keine grosse Matrix.

## Dateien / Risiken / offen
Nur scripts/core/singleplayer_fleet_travel_state.gd, scripts/core/singleplayer_space_travel_state.gd, eigener Task/Contract und eigene kleine Fixture. Root muss spaeter alle beteiligten Owner vor dem ersten Debit validieren, still publizieren und erst danach Events senden. Auch vorbereiteter Travelcommit allein ist keine atomare Surface-/Fuel-/Campaignreise. Kein Commit/Push, keine Produktverdrahtung.


## Implementierter, weiterhin unverdrahteter Kandidat
Die beiden vorhandenen Owner enthalten nur den additive Prepare/Validate/Commit-Pfad. Fleet bindet einmalig eine WeakRef-Objectidentitaet und hoechstens 64 gleichzeitig offene kanonische Kontexte. configure invalidiert Authority, Kontexte, Owner-/Epochbindungen und Erfolgsreceipts. Jeder neue aktive Kontext bekommt eine monotone Bindserial. Release entfernt Kontext, Serial und uncommittete Requestreservierung. Derselbe Kontext darf neu registriert werden, aber alte Kandidaten bleiben wegen der Serial ungueltig. Ein erfolgreicher Publish entfernt den Kontext automatisch aus dem offenen Pool; sein separater Receipt bleibt identisch replaybar, auch nach Phasewechsel. Konflikte derselben Request-ID sind waehrend aktiver Bindung und fuer erfolgreiche Belege verboten. Abgebrochene uncommittete Requestreservierungen sind nach ausdruecklichem Release freigegeben, ohne alte Kandidaten wiederzubeleben.

Travelkandidaten enthalten nur intern normalisierte Phasen-/Orbit-/Timerfelder und den vollstaendigen gebundenen Kontext; kein Save-/Restoreclone. Revalidate prueft auch den Requestkey: ein echter advance(delta=0) mit derselben ID kann einen Legacy-Noopbeleg ohne Revisionsaenderung speichern und muss den Kandidaten dann blockieren. Der stille Tail schreibt weder _position noch _origin_position, _route_control, _route_destination oder _heading; kein Flightowner wird aufgerufen. Neue Integritaetssiegel verwenden ObjectID/Epoch/Zeit und verbrauchen kein globales Combat-RNG. Bestehender _surface_seal ist unveraendert.

## Lokale Evidenz / Freeze
output/native_glut_maps/prepared_space_area_travel_20261111/owner_check.gd: 15/0, runtime_wired=false. Unter anderem echte Quantum-/Surface-/Approachowner, Contextrelease/Rebind, Noop-Requestkollision und Erfolgsretry nach Phasewechsel. Keine Fake-Fleet- oder RootTransition-Erfolgsstub. Zwei check-only Compiles und Diffpruefung; keine alte Matrix oder produktive Verdrahtung, kein Commit/Push.
