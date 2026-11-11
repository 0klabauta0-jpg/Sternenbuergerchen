# Parallele Ortsoperationen: Integrationsgrenze

## Gegenstand
Zentraler reiner Ansichtswechsel, erhaltene registrierte Ortsroots, getrennte
Serviceschiffwahl und lokale Basis-/Polisaguards. Bestehende Reise-, Transport-,
Inventar-, Credit- und Simulationsowner bleiben zustaendig.

## Unabhaengige Pruefung
Readonlyreview fand zwei reale Fehler im ersten Kandidaten: verbrauchender
Encounter-Erfolgsgetter bei der automatischen Pilotenrettung und veraltete
Planprojektion bei Ankunft/Callback am selben Ort. Beide wurden gegen aktuelle
Produktpfade geprueft und gezielt korrigiert. Die zweite Korrektur umfasst auch
den terminalen Callback, der den aktiven Zeiger loest, den Ort jedoch erhaelt.

Die kleinen Fixturelaeufe hier sind frisch im gemeinsamen Integrationsstand
ausgefuehrt; Ergebnisse in results.json und den vollstaendigen Logs. Source-
Compilebelege der Teilpakete liegen unter docs/qa/local_service_context_20261111
und output/native_glut_maps/parallel_location_view_20261111. Keine alte grosse
Matrix wiederholt.

Finaler gemeinsamer Lauf: View44/0, Service30/0, Flow und Adapter check-only
Exit0 ohne Scriptfehler. Finaler unabhaengiger Deltareview ohne Restblocker.
source_normalized_sha256.json haelt LF-normalisierte Quellhashes fest.

## Sourceaudit fuer verdeckten Fortschritt
SimulationRoot._physics_process prueft Autoritaet, keine Viewsichtbarkeit.
CombatLoopDriver._on_tick_processed nutzt seinen lokalen Root/Registry.
TacticalController._process fuehrt Extraktion, Dropsequenz, taktische Ausfuehrung
und Sicherung vor dem _tactical_ui_visible-Return aus. Flow deaktiviert bei
verdeckten registrierten Ortsroots nur Kamera/View/Viewport/Input, nicht den
Rootprozess. Das ist ein Sourcebefund; die kleinen tickenden Fake-Ortsroots
sind keine ausgespielte Mehrortschlacht.

## Praktische Grenzen
Die Viewfixture nutzt echte Flow-/Screenmethoden mit kleinen Controller-/Setup-/
Driver-/Runtime-Spies. Admission und schwere Transporthelfer sind ersetzt.
Die Servicefixture nutzt echte kleine Supply-/Encounterdaten, aber Stub fuer
Sim-/Base-/Flowbindung. Echte Personenaufnahme, parallele Gefechte, Shopkaeufe,
Reisen, Boarding, native Bedienung, Save/Continue und Framezeiten bleiben zur
spaeteren grossen Abnahme. Checkpoint bleibt heimatgebunden. Ein Crew-Faehrbetrieb
mit zurueckgelassener zugewiesener Mannschaft ist kein Nebeneffekt der Navigation.

Kein Mainmerge, kein EXEbau und keine neue Kartenaktivierung.
