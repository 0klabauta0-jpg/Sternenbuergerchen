# Lokaler Servicekontext (Teilauftrag parallele Orte)

## Ziel und Ursache
Reisefokus/gesamte Flotte darf lokale Basiswerkstatt und gesicherte lokale
Uploads nicht sperren. Eine explizite Orts-Schiffwahl darf keine entfernte
Fracht oder fremden Gameplayzugang erteilen.

## Umfang und Nicht-Ziele
Adapter, ServicesPresenter und PolisaScreen. Keine Supply-/Simulationsmutation,
keine Bewegungs-, Kampf-, Checkpoint- oder Fahrzeugaenderung. Grosspruefung spaeter.
Verbindlicher Rahmen: PARALLEL_LOCATION_OPERATIONS_2026_11_11.md und
../dev/location_view_selection_contract.md, vorhandene Inventory-/Serviceowner.

## Akzeptanz
- Getter bleiben lesend; Serviceschiff kommt nur aus aktuellem Ortsview.
- Polisa listet nur real geparkte lokale Crafts, kein Reise-/erstes-Schiff-Fallback.
- Command prueft Craft/Ort/Transfer/Service erneut; optionale Ortsabsicht verhindert
  stille Umdeutung alter UI-Aktionen nach Ortswechsel.
- Werkstatt: lebender am Adapter gebundener und in SimulationRoot registrierter
  BasePersonnelOwner plus gebautes freihafen_hall_01; keine neue Personalpflicht.
- Bestehende Noncampaign-Fertigung ohne Owner behaelt striktes all_at_home-Gate.
- Upload nimmt nur Basislager, belegte geerdete Heimatschiffe oder echte lokale
  Basispersonen. Globaler RecoveryFinder bleibt unveraendert.
- Rekrutierung/Kiste gehoeren zum konkreten Auftragsschiff. Pilot beansprucht
  bestaetigten Encounter-Erfolg seines Schiffs weiterhin im Orbit.
- Padbau bleibt konservativ flottenweit, bis waiting_pad-Handoff getrennt ist.

## Dateien / lokale Pruefung
scripts/meta/singleplayer_runtime_adapter.gd,
scripts/meta/singleplayer_services_presenter.gd, scripts/ui/polisa_station_screen.gd;
scripts/tests/local_service_context_check.gd. Enge Zwei-Schiff-/Zwei-Ort-Fälle,
negative Fernchips, stale Auswahl, Ownerbindung und Compile; keine GPU/Grosstests.

## Risiken / Restpunkte
Checkpoint bleibt heimatgebunden. Padbau-waiting_pad-Lifecycle bleibt global.
Neue Standortabsicht ist ein zusaetzliches Rejectgate, keine Gameplayberechtigung.
