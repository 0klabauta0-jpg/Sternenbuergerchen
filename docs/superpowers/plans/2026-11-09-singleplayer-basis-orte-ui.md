# Einzelspieler: Basis, Orte und UI — Umsetzungsplan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Einen durchgängigen Einzelspielerablauf aus neuer Heimatbasis, übersichtlicher Personalausrüstung, ortsgebundenen Aufträgen und drei nutzbaren Startorten herstellen.

**Architecture:** Die bestehende Operations-Oberfläche, ihre Snapshot-/Commandbrücke und die gemeinsame Hex-/Runtimebasis erweitern. Ort, Auftrag und Reise getrennt modellieren; Gameplaymutationen verbleiben bei SimulationRoot und den vorgesehenen Domain-/Runtimekomponenten. Die Basis ist eine Darstellung desselben Personal-/Transportzustands, keine zweite Verwaltung.

**Tech Stack:** Godot 4.6.2, GDScript, vorhandene JSON-Karten/Szenarien, hex_axial_v1, bestehende native 3D-/UI-Renderer; keine neue Engine oder UI-Bibliothek.

**Spec:** [Playtest, Zielbild und Grenzen](../../tasks/SINGLEPLAYER_PLAYTEST_2026_11_09_basis_orte_ui.md).

Status: **AP0–AP7 implementiert; AP8 technisch bestanden, native Abnahme offen.**
Echter Zweiausflugslauf nach Reviewfixes60/60. Produktstand6d0e463fe:
20 fokussierte Gates und6 Transport-/Interaktionsregressionen bestanden.
[QA-Abschluss](../../qa/singleplayer_20261109/README.md). Frischer Taskbranch ab
geprueftem Main ed77c1058; gemeinsamer Integrationsbranch unveraendert.
Direkte lokale Mainintegration anschliessend autorisiert, kein Push/Release.
Offene Checkboxen betreffen verbleibende native/inhaltliche Abnahme.

## Globale Grenzen

- Godot 4.6.2; vorhandene Hex-Topologie hex_axial_v1 für neue Karten.
- SimulationRoot und vorgesehene Runtime-/Domainkomponenten besitzen Gameplayzustand.
- UI/3D zeigen Snapshots und senden Commands; keine zweite Auftrags-, Orts-, Personal-, Loadout-, Inventar- oder Transportwahrheit.
- get_operations_snapshot() und request_operation(operation, payload) bleiben UI-Brücke.
- Keine SceneTree-Vollscans im Hotpath; Control-/Zeilen-Caches und Dirty-/Batch-Updates erhalten.
- Keine Savegame-Migration erforderlich; frische Testprofile verwenden und normale Nutzerdaten erhalten.
- Drei Startorte insgesamt sind Planannahme: Basis, Satelliten-Absturzstelle, Handelsaußenposten.
- Sichtbares Einsteigen, weitere Außenposten und vollständige Bau-/Lagerwirtschaft sind Ausbau.
- Umsetzung AP0–AP8 autorisiert: Spielcode, lokale Pruefungen, lokale Commits und anschliessend direkte lokale Mainintegration. Kein Push/Release. Seit PC-Nutzungsanweisung nur Hintergrund/Headless ohne Fokus-/Eingabeuebernahme.

## Review-Fokus

1. Navigation nach mehrfachen Wechseln: kein Altbildschirm-Zwang, kein versteckter Rückweg, kein aktivierbarer FOB.
2. Drag-and-drop bei leeren/vollen/besetzten/unterwegs befindlichen Trupps: keine doppelte Mitgliedschaft oder Payload.
3. Auftrag/Zielort bei Wechsel, Abbruch oder mehreren Aufträgen am selben Ort: kein falscher Start, keine automatische Reise.
4. Handel/Betankung bei Doppelklick, Wiederholung und unzureichenden Mitteln: genau eine Transaktion, kein negativer Bestand.
5. Innenraum und Padansicht: sichtbare Tür/Position muss zur Navigation und realen Craft-ID passen; Bildkulissen reichen nicht.

## Reihenfolge und überprüfbare Zwischenstände

| Paket | Ergebnis | Abhängigkeit |
|---|---|---|
| AP0 | Aktuelle Arbeitsbasis, Begriffe und verbindliche Grenzen | vor jedem Produktcode |
| AP1 | Neue Navigation ohne Legacy-Sackgasse, FOB gesperrt | AP0 |
| AP2 | Kompaktes Personal, Details, Slots und Drag-and-drop | AP1 |
| AP3 | Echte erweiterte Basis mit Innenräumen und zwei Pads | AP0; parallel zu AP2 planbar |
| AP4 | Smart Mobile, Regionalkarte, Auftrag-/Ortsmodell | AP1 |
| AP5 | Abflug vom tatsächlichen Pad zum ausgewählten Ort | AP2–AP4 |
| AP6 | Spielbarer Satellitenauftrag | AP4–AP5 |
| AP7 | Kleiner Handel-/Fuel-State und Handelsort | AP3–AP6 |
| AP8 | Gesamtdurchlauf und native Abnahme | AP1–AP7 |

AP1–AP3 liefern bereits nutzbare Verbesserungen vor neuem Kampagneninhalt.
AP4 definiert die gemeinsamen IDs, bevor AP5–AP7 diese konsumieren.
Änderungen an homebase_screen.gd, dem Presenter und MetaLayerFlow seriell integrieren.

## AP0 — Basis und Contracts festlegen

**Ziel/Ursache:** Aktueller Hauptstand ist 91 Commits neuer als die vorgegebene Integration.
Die Planung darf nicht versehentlich die inzwischen integrierte Oberfläche zurücksetzen.

**Dateien:** docs/dev/homebase_operations_ux_contract.md; docs/PROJECT_BRIEF.md;
docs/TASK_ROADMAP.md; diese Task-/Planungsdateien. Neue Contracts:
docs/dev/singleplayer_locations_jobs_contract.md und docs/dev/homebase_map_services_contract.md.

**Schnittstelle:** Noch keine Produkt-API. Verbindliche IDs, Besitzer und Statusübergänge
werden hier festgelegt; AP4 konkretisiert sie in prüfbaren Datenhelfern.

- [x] Vor Umsetzung aktuellen Git-/Worktreezustand erneut prüfen; Integrationsbasis kontrolliert auf
  den benötigten, getesteten Hauptstand bringen; frischen task/-Branch verwenden.
- [x] Änderungsbefunde gegen diesen Stand prüfen; vorhandene neue Basis und Owner erhalten.
- [x] Die Spezifikation als Task-Akzeptanz übernehmen; neue Navigation und Wegfall des regulären
  Erweiterte-Werkzeuge-Wegs festhalten; historische UI-first-Aussage im Brief korrigieren.
- [ ] „Cutlist“ am echten Personalbildschirm zuordnen. Bis dahin kein benanntes Element blind löschen.
- [x] Rangbegriff klären: bestehender Rollen-/Fähigkeitsbadge versus echter Dienstgrad.
  Bei echtem Dienstgrad Datenfeld und Sortierschlüssel beschreiben; kein Beförderungssystem ableiten.
- [x] Minimalhandel festlegen: genau ein festes Kaufangebot und eine Betankungsaktion,
  begrenzte Credits/Mengen, bestehende Ausrüstungs-/Item-ID wiederverwenden; Werte in Daten,
  kein Produktions-/Lieferkettenmodell. Diese Empfehlung ist kein bereits bestätigtes Balancing.
- [x] Als kleinste Fuel-Regel feste datenbasierte Kosten je Ortsverbindung vorsehen:
  genau einmal bei autorisiertem Abflug abbuchen, bei Ablehnung/erneuter Anfrage keine zweite
  Abbuchung. AP7 ergänzt diesen Anschluss an AP5; Startwerte müssen den Test-Rundflug erlauben.
  Kein kontinuierliches Verbrauchsmodell und keine neue Notfall-/Strandingmechanik.

**Abnahme/Prüfung:** Dokumente nennen Ziel, Grenzen, Eigentümer, Daten-IDs, betroffene Pfade,
Prüfungen und offene Punkte. git diff --check. Keine Engineprüfung für reine Planungsdokumente.

## AP1 — Navigation und Lesbarkeit

**Dateien ändern:** scripts/meta/homebase_operations_presenter.gd;
scripts/meta/homebase_screen.gd; scripts/meta/meta_layer_flow.gd;
docs/dev/homebase_operations_ux_contract.md.

**Tests:** neues scripts/tests/playtest_20261109_navigation_verifier.gd;
bestehend playtest_20261105_homebase_operations_verifier.gd.

**Schnittstellen:** get_operations_snapshot() -> Dictionary und
request_operation(operation: String, payload: Dictionary = {}) -> Dictionary
weiterverwenden. Navigationszustand bleibt Darstellungszustand.

- [x] Verifier zuerst um sichtbare Wege, echte Buttonaktionen, Rücknavigation und FOB-Blockade ergänzen;
  aktueller OperationsReturnButton ist vorhanden und darf nicht als fehlender Callback diagnostiziert werden.
- [x] Links Basis erkunden, Personal, Trupp & Ausrüstung, Smart Mobile, Karte und Einsatz & Abflug
  als klare Ziele entwerfen. Noch nicht implementierte Ziele bis AP4 ehrlich sperren.
- [x] Erweiterte Werkzeuge aus dem regulären Einzelspielerweg entfernen; benötigte Funktionen erhalten.
  Gemeinsame Backend-/Kompatibilitätspfade nicht pauschal löschen.
- [x] FOB sichtbar durchstreichen und deaktivieren; programmatische normale Eintrittsroute ebenfalls sperren.
  Interne bestehende Transport-/Multiplayerverträge nicht beiläufig ändern.
- [x] Rechten Bereich auf Auswahl, wichtigste Werte und nächste Aktion reduzieren;
  Details aufklappen/Charakterbogen. Kontrast und Zustandsicons verbessern.
- [ ] Verifier und echte native Klickfolge prüfen, inklusive Zurück/Escape und wiederholtem Ansichtswechsel.

**Abnahme:** Kein regulärer Weg landet in der Altansicht oder FOB. Aktiver Bereich, nächste Aktion
und Rückweg sind klar; bei 1280×720 kein abgeschnittener Hauptbutton.

## AP2 — Personal, Charakterdetails, Ausrüstung und Drag-and-drop

**Dateien ändern:** scripts/meta/homebase_operations_presenter.gd;
scripts/meta/homebase_screen.gd; scripts/meta/npc_compact_card.gd;
scripts/meta/npc_rank_badge_resolver.gd; vorhandene Drop-Target-Controls nur soweit nötig;
scripts/meta/portrait_identity_catalog.gd nur bei echter Rollenvariantenzuordnung.

**Tests:** neues scripts/tests/playtest_20261109_personnel_dragdrop_verifier.gd;
task_388_homebase_fireteam_roster_shipcard_polish.gd;
task_346_homebase_direct_staging_character_popup.gd;
task_381_homebase_fireteam_loadout_flightdeck_polish.gd;
task_207_npc_rank_skill_badge_derivation.gd;
task_233_portrait_identity_catalog_and_roster_presentation.gd.

**Schnittstellen:** Bestehendes Dragpayload type=homebase_unit_card / Unit-ID und vorhandene
Fireteam-Payloads verwenden. Alle Änderungen über request_operation() an vorhandene
Zuweisungs-/Loadout-/Boardingowner delegieren; kein eigener Mitgliedschaftscache als Wahrheit.

- [x] Regressionen für Person → neuen Trupp, Wechsel, Entfernen bis leer, Pilotfreigabe,
  voller Trupp und busy/transit Reject anlegen; zweite freie Gruppe muss bearbeitbar bleiben.
- [x] Kompakte Personenzeilen mit stabiler Unit-ID, Name, Rolle/Badge und knapper Ausrüstung bauen;
  in Personalansicht nur Personenbezug. Kleinere Listenporträts, Detailportrait darf größer bleiben.
- [x] Bestehende Sortiermetriken Name/XP/Leader/Tutor/Pilot wiederverwenden;
  Rangsortierung entsprechend AP0, mit stabilen Name-/ID-Ties.
- [x] Doppelklick über vorhandenen card_open_requested-/Charakterbogenpfad verbinden;
  normaler Klick wählt aus, Drag öffnet nicht versehentlich den Bogen.
- [x] Personen auf Truppplätze, Mitglieder zurück/zwischen Gruppen und komplette Fireteams
  auf reale Schiffskarten ziehen. Ungültige Ziele zeigen einen knappen konkreten Grund.
- [x] 2D-Ausrüstungsslots für gewählte Person und Trupp darstellen; Slot-Drops validieren
  echte Item-/Loadout-IDs. Bestehende Gesichter/Identitäten erhalten, Rollenkennzeichen als
  Overlay/Uniformvariante ergänzen; keine Neuwürfelung des Rosters.
- [x] Bestehende Last-/Transit-/Kapazitätsgates und Layoutchecks erneut ausführen.

**Abnahme:** Funktioniert ohne Legacyansicht. Keine doppelten Mitglieder, verlorenen Piloten,
stummen Rejects oder frei erfundenen Bestände. Vollständige Lagerbegrenzung erst im späteren Ausbau.

## AP3 — Heimatbasis als größere begehbare Karte

**Dateien ändern:** maps/homebase_frontier_exploration.json;
scripts/meta/explorable_homebase.gd; scenes/meta/explorable_homebase.tscn;
scripts/meta/homebase_commander_avatar.gd nur falls Eingabegrenze betroffen;
scripts/terrain/frontier_outpost_pad.gd nur für Visualwiederverwendung.

**Tests:** playtest_20261105_explorable_homebase_verifier.gd;
neu scripts/tests/playtest_20261109_base_interior_pad_verifier.gd.

**Schnittstellen:** set_active(active: bool), request_walk_to(world_position: Vector2) -> bool,
request_terminal(id: String) -> bool, terminal_open_requested(id: String),
get_exploration_snapshot() -> Dictionary erhalten. Neue Terminal-IDs jobs/refuel über die
gleiche Signalbrücke; tatsächliches Refuel erst AP7, zuvor ausdrücklich gesperrt.

- [x] Vorhandene Basiskarte erweitern, zwei Gebäude erhalten, zwei benachbarte Pads mit stabilen
  IDs, Servicepunkt, Wege und freie spätere Bauflächen authorieren; Felsen weiter nach außen.
- [x] Gebäude in einsehbarer Cutaway-/Ohne-Dach-Ansicht zeigen.
  Gleichzeitig gespeicherte Fußböden, Eingänge und Begehbarkeit authorieren;
  kein Ableiten von Navigation/LOS/Kollision aus bloßer Modelloptik.
- [x] Verbindung von Commanderstart zu beiden Innenräumen, allen Terminals und beiden Pads
  prüfen; Außenwände bleiben Hindernisse. Keine globale Spielpause.
- [x] Interaktionen an tatsächliche Nähe und bestehende Commands binden;
  gleiche Personal-/Planungs-/Jobansichten wie linke Navigation öffnen.
- [x] Präplatzierte Testgebäude/Pad-Footprints datenbasiert halten, ohne jetzt ein Bausystem zu erfinden.
- [ ] Gezielt Bewegungs-/Aktivierungs-/Inputfokus-/Blocker-/Navprüfungen ausführen;
  native Vorher-/Nachherbilder aus gleichem Blickwinkel prüfen.

**Abnahme:** Größere zusammenhängende Karte, betretbare sichtbare Innenräume, zwei erreichbare Pads.
Die feste alte 24×20-Erwartung im Verifier bewusst durch Inhalts-/Erreichbarkeitsorakel ersetzen.

## AP4 — Orte, Aufträge, Smart Mobile und Regionalkarte

**Neue Dateien:** scripts/mission/singleplayer_location_contract.gd;
scripts/mission/singleplayer_job_contract.gd;
scripts/core/singleplayer_campaign_state.gd;
scripts/mission/singleplayer_campaign_command_contract.gd;
scripts/meta/singleplayer_job_board_presenter.gd;
scripts/meta/singleplayer_region_map_presenter.gd;
data/singleplayer/locations.json; data/singleplayer/jobs.json.

**Ändern:** scripts/meta/meta_layer_flow.gd; scripts/core/simulation_root.gd für den
engen autoritativen Commandanschluss; HomebaseScreen-/Operations-Brücke;
später mission-/scenario-/recovery-spezifische Adapter nur soweit der neue Ortshandoff es verlangt.

**Tests:** neu scripts/tests/playtest_20261109_job_location_flow_verifier.gd;
task_538_homebase_to_mission_launch_handoff_smoke.gd.

**Vorgeschlagene Daten-/API-Grenze:**
- location_id ist unabhängig von job_id. Ortsdaten: ID, Name, Regionposition, map_file_path,
  scenario_file_path, landing_pad_ids, services.
- Auftragsdaten: ID, Titel, Zielort-ID, Objective-/Scenario-Bezug, Belohnungsdefinition;
  Status offered/accepted/active/completed/failed.
- Stabile Orts-IDs: homebase, satellite_crash, trade_outpost; erster Job satellite_recovery.
- Reine Helper: normalize_location(raw: Dictionary) -> Dictionary;
  normalize_job(raw: Dictionary, locations: Dictionary) -> Dictionary.
- request_operation("accept_job", {"job_id": ...}) und
  request_operation("select_destination", {"location_id": ..., "job_id": ...})
  delegieren an den autoritativen Owner. UI-Fokus ist kein angenommener Auftrag.
- Snapshots transportieren accepted_job_ids, selected_job_id, selected_location_id und
  den bestätigten Reise-/Auftragsstatus. Runtimecommand-Adapter im Contract ausdrücklich definieren.
- SingleplayerCampaignState hält bestätigte Auftragsannahme/-status, Zielzuordnung und
  einmalige Abschlussbelege außerhalb der deaktivierbaren Basis und der austauschbaren
  Missionsszenen. get_campaign_snapshot() -> Dictionary ist lesend; Übergänge für Annahme,
  Aktivierung, Abschluss und Fehlschlag erfolgen ausschließlich durch autorisierte Commands.
  MetaLayerFlow bindet den langlebigen State an den Runtime-/SimulationRoot-Commandpfad und
  orchestriert dessen Lebenszyklus, mutiert ihn nicht in UI-Callbacks.
- Bestehender Aircraft-/Transportowner behält laufende Flugphasen und Payloads.
  Campaign-State referenziert Craft-/Ort-/Job-IDs und übernimmt keinen zweiten Transitstatus.

- [x] Tests für Annahme ohne Flug, ungültigen Ort, Auftragswechsel, mehrere Jobs am gleichen Ort,
  Handel ohne Kampfauftrag und Abbruch anlegen.
- [x] Den langlebigen Campaign-State einschließlich Commandhandlern tatsächlich implementieren;
  Ansichtswechsel, Erkundungs-Deaktivierung und Missionsinstanzwechsel erhalten Annahme,
  Zielzuordnung und Abschlussbelege. AP5–AP7 konsumieren denselben Owner.
- [x] Orts-/Jobdefinitionen getrennt laden und Referenzen validieren.
- [x] Smart Mobile als kompakte Auftragsliste mit Details, Annehmen, Status und „Auf Karte zeigen“ bauen.
- [x] Separate Regionalkarte mit Basis/Absturzstelle/Handelsposten und sichtbarem Zielort herstellen.
  Keine vorhandene taktische Karte als Regionalkarte umbenennen.
- [x] Planung und Abflug aus derselben Auswahl speisen; Missionsauswahl zeigt Auftrag plus Ort.
- [x] Über den bestehenden Start-/Handoffpfad mit einer vorhandenen Mission prüfen, bevor neue Inhalte folgen.

**Abnahme:** In allen Ansichten ist erkennbar, welcher Auftrag wohin führt. Annahme ist keine Reise;
ein Ortswechsel startet keine fremde Mission und ein Handelsposten braucht keinen Kampfauftrag.

## AP5 — Reales Pad, Schiff und ortsbezogener Abflug

**Dateien ändern:** scripts/meta/aircraft_manager.gd; scripts/meta/explorable_homebase.gd;
scripts/meta/homebase_operations_presenter.gd; scripts/meta/meta_layer_flow.gd;
bestehende Schiffspreviewhelper weiterverwenden.

**Tests:** neu scripts/tests/playtest_20261109_pad_departure_verifier.gd;
task_348_homebase_fob_payload_state_isolation.gd;
task_354_homebase_direct_loadout_regression_matrix.gd;
task_385_homebase_direct_return_isolation.gd;
task_538_homebase_to_mission_launch_handoff_smoke.gd;
task_586_debrief_return_homebase_handoff.gd.

**Schnittstelle:** Bestehende craft_id und Payload bleiben AircraftManager-/Runtimebesitz.
Padbelegung bindet landing_pad_id → craft_id. Reise speichert destination_location_id sowie
optional job_id; interne to_mission-/to_homebase-Phasen werden gezielt adaptiert,
ohne den äußeren Ort durch eine zweite UI-Reisewahrheit zu ersetzen.

- [x] Tests für tatsächliches Schiff/Pad, leeres Schiff, falsche Payload, parallele Crafts,
  Auswahlwechsel während Transit und Rückkehr ins korrekte Pad anlegen.
- [x] Statischen Cutlass-Prop im relevanten Spielerweg durch Projektion des tatsächlichen Craftzustands ersetzen.
- [x] Einsatz & Abflug aus einer passenden Kamera auf Schiff und Pad darstellen,
  bei Bedarf als getaktete/dirty aktualisierte Vorschau; keine erfundene Liveaufnahme.
- [x] Pilot, Trupp, Boarding, Zielort, Auftrag und nächste Aktion kompakt zusammenführen.
- [x] Start/Abbruch/Rückflug an den vorhandenen Transporthübergang anschließen;
  pro Craft unabhängig, ohne FOB-Zwang.
- [x] Fuel-Anzeige bis AP7 ausdrücklich als noch nicht verfügbare Mechanik behandeln;
  keine Dekozahl als Reisevoraussetzung verwenden.

**Abnahme:** Richtiger realer Craft, richtige Payload und richtiger Ort; kein Schiffs-/Teamklon.
Boardingfortschritt ist funktional. Laufende Boardingfiguren sind hier keine Voraussetzung.

## AP6 — Satelliten-Absturzstelle und Bergungsauftrag

**Neue Dateien:** maps/satellite_crash_site.json;
data/mission_scenarios/satellite_recovery.json.
**Ändern:** data/singleplayer/locations.json; data/singleplayer/jobs.json;
bestehender Missionsinteraktions-/Debriefadapter nur wenn nötig.
**Test:** neu scripts/tests/playtest_20261109_satellite_recovery_verifier.gd.

**Schnittstellen:** location_id=satellite_crash; job_id=satellite_recovery.
Bestehende MissionInteractionPointBinding-/Use-/Runtimeprogress-Verträge nutzen.

- [x] Kleine authorierte Hexkarte mit Absturzstelle, tatsächlichem Interaktionsziel, erreichbarer
  Landezone und Rückkehrmöglichkeit erstellen. Neue Modellarbeit nur bei fehlenden passenden Assets.
- [x] Vorgeschlagener erster Objectiveablauf: Satellit finden → Daten/Bergungsgut sichern →
  Schiff erreichen → zurückkehren. Diese konkrete Bergungsvariante ist Planempfehlung.
- [x] Erfolg und Fehlschlag an echte Runtime-/Scenario-Gates binden;
  Nähe oder UI-Klick allein darf keinen Abschluss setzen.
- [x] Einmaligen Abschluss-/Belohnungsbeleg mit stabiler Job-/Abschluss-ID erzeugen;
  AP7 konsumiert ihn ohne Doppelgutschrift.
- [x] Start, Fortschritt, Abbruch, erneutes Anzeigen des Ergebnisses und Rückkehr prüfen.

**Abnahme:** Von der Basis angenommener Auftrag kann am richtigen Ort tatsächlich abgeschlossen werden;
kein bloßes Kartenbild und kein bedingungsloser Erfolg beim Laden.

## AP7 — Minimalhandel, Betankung und Handelsaußenposten

**Neue Dateien:** scripts/core/singleplayer_supply_state.gd;
scripts/mission/singleplayer_supply_command_contract.gd;
data/singleplayer/trade_offers.json; maps/trade_outpost.json;
data/mission_scenarios/trade_outpost_visit.json.
**Ändern:** scripts/core/simulation_root.gd nur enger Commandanschluss;
MetaLayerFlow-Lifecycle; AircraftManager-/Operations-Snapshots; Ortsdaten.
**Tests:** neu scripts/tests/playtest_20261109_trade_refuel_verifier.gd.

**Schnittstellen:** Supply-State persistiert über Ansicht-/Ortswechsel und enthält credits,
ein kleines item_quantities-Dictionary und fuel_by_craft_id. Reiner Commandbuilder:
build_buy_command(offer_id: String, quantity: int, request_id: String) -> Dictionary;
build_refuel_command(craft_id: String, amount: float, request_id: String) -> Dictionary.
Autorisierte Anwendung nur durch SimulationRoot/zugeordneten Runtime-Owner.
get_supply_snapshot() -> Dictionary liest bestätigte Werte.
Belohnungen konsumieren AP6-Abschluss-ID genau einmal.

- [x] Negativ-/Wiederholtests zuerst: zu wenig Credits, ungültige Menge, volles Fuel,
  unbekanntes Angebot, bereits bearbeitete request_id, doppelte Abschlussbelohnung,
  Wechsel zur/von der Erkundungsansicht.
- [x] Minimalen autoritativen, lebenszyklusfesten State und atomare Buchung implementieren;
  keine negativen Werte und kein UI-eigener Kontostand.
- [x] Ein endliches festes Kaufangebot und eine Betankungsleistung definieren;
  keine vollständige Inventar-/Loadout-Sperrlogik oder Wirtschaftssimulation daraus machen.
- [x] Kleine Händlerkarte mit erreichbarem Landepad und Handels-/Serviceinteraktion authorieren.
  Bestehende Station-Assets wiederverwenden; neue Karte ausdrücklich hex_axial_v1,
  Legacy-square8-Karten nicht still umdeuten.
- [x] Basis-Tankpunkt an denselben echten Fuel-/Servicezustand anschließen;
  gemeinsame Bestände/Transaktionen über beide Ansichten konsistent anzeigen.
- [x] Für den Testlauf ausreichend Starttreibstoff und erreichbare Rückkehr sicherstellen;
  keine neue Stranding-/Fuel-Notfallmechanik ohne gesonderten Auftrag.
- [x] Die in AP0 definierte feste Route-Fuelabbuchung an den autorisierten AP5-Abflug hängen:
  Ablehnung und wiederholte Request-ID verbrauchen nichts zusätzlich; unzureichendes Fuel
  blockiert vor Abflug mit konkretem Grund. Kein laufender Verbrauch im Visual-/UI-Tick.
- [x] Satellitenbelohnung → reale Kauf-/Betankungsaktion → Rückkehr prüfen.

**Abnahme:** Ein nachweisbarer Kauf und eine Betankung verändern bestätigte Werte genau einmal.
Der Ort ist auch ohne Kampfauftrag besuchbar. Vollständige Lager-/Bauwirtschaft bleibt Folgearbeit.

## AP8 — Gesamtdurchlauf, Sichtprüfung und Abschluss

**Dateien:** neuer scripts/tests/playtest_20261109_singleplayer_loop_smoke.gd;
QA-Bericht docs/qa/singleplayer_20261109/README.md mit Rohbelegen;
Task-/Contract-/Statusdokumente aktualisieren.
Kein HTML erforderlich; falls später gewünscht, Workbench-Vertrag beachten.

- [ ] Technische Einzelgates der veränderten Pfade zusammen ausführen; vorhandene Source-/Ownerregressionen erhalten.
- [ ] In frischem isolierten Profil regulär starten: Basis erkunden → Personal sortieren/Details →
  neuen Trupp per Drag besetzen → ausrüsten → Auftrag annehmen → Ort auf Karte →
  boarden/abfliegen → Satellitenziel → Rückkehr → Handel/Refuel → zurück.
- [ ] Zweiten Ausflug im selben Lauf prüfen; keine hängenbleibenden Payloads, alten Aufträge,
  doppelten Belohnungen oder verlorenen Personen.
- [ ] Native Screenshots und echte Eingaben bei 1280×720, 1920×1080 und 3440×1440 prüfen:
  Scroll, Text, Dropdowns, Doppelklick, Dragziele, Rückwege, Welt-/UI-Fokus und Basisinnenräume.
- [ ] Normale Erkundungs-/Abflugroute kurz profilieren: keine versteckten Vollrebuilds,
  kein unnötiger dauerhaft rendernder Zweitviewport; Ergebnisse statt FPS-Versprechen dokumentieren.
- [ ] Unabhängiges Code-/Scope-Review. Technisch bestanden, nativ gesehen und vom Nutzer
  gestalterisch angenommen ausdrücklich getrennt berichten.
- [ ] Aktuellen Branch, lokale Änderungen sowie Commit-/Pushstatus korrekt nennen.
  Integration/Push/Build erst im Rahmen eines dafür autorisierten Folgeauftrags.

**Vorgeschlagenes Engine-Prüfmuster:** Einmal vorhandenes Godot-4.6.2-Console-Binary lokalisieren,
dann jeweils
`<godot-console> --headless --path <aktuelle-implementierungs-worktree> --script res://scripts/tests/<verifier>.gd`.
Erwartung: Exit 0 und keine FAIL-/Parse-/Scriptfehler; Report-Assertions mit auswerten.
Keine festen Framezahlen als Ersatz für echte Readiness/Simulation-Commits.

## Optionaler Ausbau nach dem ersten vollständigen Loop

1. **Sichtbares Boarding:** Figuren vom echten Bereitstellungsbereich zum richtigen Craft laufen lassen;
   Animation liest bestätigten Boardingzustand. Keine zweite Personal-/Payloadsimulation.
2. **Lagergebundene Ausrüstung:** echten Bestand in 2D-Slots reservieren/rückgeben,
   einschließlich Mengen-/Doppelzuweisungsregeln. Bestehende Grundslots bleiben bedienbar.
3. **Baubare Basis:** die vorgesehenen Gebäude-/Pad-/Service-Footprints in einen eigenen
   Bau-/Progressionscontract überführen; keine Umdefinition des Testaufbaus als fertiges Bausystem.
4. **Weitere Außenposten:** z. B. Service-/Rettungs- oder Forschungsort erst nach gesonderter
   Entscheidung. Keine zusätzlichen Karten im aktuellen Dreierumfang verstecken.

## Selbstprüfung des Plans

- Jede protokollierte Anforderung ist einem AP oder dem ausdrücklich optionalen Ausbau zugeordnet.
- „Cutlist“, Rangdefinition und die Anzahl der Karten sind als Unsicherheit/Planannahme gekennzeichnet.
- Bestehende Gesichter, neue Oberflächenrichtung und gewünschtes Abfluglayout bleiben erhalten.
- Die fünf Review-Fälle besitzen konkrete Tests in AP1, AP2, AP4, AP7 und AP3/AP5.
- Die vorgeschlagenen neuen Helpernamen/Dateien sind keine Behauptung vorhandener Implementierung.
- Keine offenen Tests oder Vorschläge sind als erledigt markiert.
