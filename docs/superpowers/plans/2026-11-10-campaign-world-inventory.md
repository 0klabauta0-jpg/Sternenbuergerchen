# Kampagnenrunde: Spielwege, grosse Orte und Inventar — Arbeitsplan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax for tracking. Kein automatischer Implementierungsstart durch diesen Planungsauftrag.

**Goal:** Die Kampagne verstaendlich bis zur Heimkehr spielbar machen, Referenzgestaltung uebernehmen und mehrere unabhaengige Trupps auf getrennten weiterlaufenden Ortskarten ermoeglichen.

**Architecture:** Bestehende SimulationRoot-/Transport-/Kampagnenowner erweitern. UI und Weltprojektion lesen dieselben IDs und bestaetigten Snapshots. Langlebiger Ortszustand wird von austauschbarer sichtbarer Kartenprojektion getrennt; keine UI-Inventare oder zweite Reisesimulation.

**Tech Stack:** Godot 4.6.2, GDScript, gespeicherte JSON-Karten mit hex_axial_v1, vorhandene GLB-/Portrait-/UI-Assets.

**Spec:** `docs/tasks/PLAYTEST_2026_11_10_campaign_world_inventory.md` (Nutzeranforderungen 1–26, Bestandsabgleich und Referenzmanifest).

## Global Constraints

- Neue Umsetzung auf dem dann aktuellen integrierten Mainstand beginnen; gepruefter Planpin `046b6d91a`. Der historische integration/core-foundation-Pin ist kein Ersatz fuer den aktuellen Kampagnenstand.
- Ein Taskbranch pro unabhaengig abnehmbarem Paket; fremde WIP erhalten. Commits klein und nachvollziehbar; Push/Merge/Export im jeweiligen Umsetzungsauftrag klaeren, nicht aus diesem Plan ableiten.
- Gameplay-Mutationen zentral ueber SimulationRoot und vorhandene Runtimeowner; Registries nur Lookup/Index.
- Echtzeit ohne taktische Pause; Befehle maximal an FTL, keine direkte Einzel-NPC-Steuerung im Einsatz.
- Keine SceneTree-Vollscans im Hotpath, kein per-frame Komplett-Rebuild. Dirty/Caches/UpdateManager verwenden.
- Genau zwei echte Kampagnen-Startpersonen bleiben erhalten. Mehrtruppabnahme benutzt ein isoliertes, ausdruecklich benanntes groesseres Testteam.
- Originale der Referenzbilder erhalten. Jede Grafikabnahme mit Referenz und nativer Aufnahme bei gleicher Kamera/Spielentfernung; technische Gates ersetzen kein Nutzerurteil.
- Keine stillen neuen Mining-, Inventar-, Save-, PvP- oder Flugbalance-Regeln. Vorschlaege unten als solche behandeln und vor ihrem Paket im Contract konkret festlegen.

## Review Focus

1. Zweite Bodenperson/Pilot fehlt oder steht fern: Boarding darf niemanden teleportieren oder als an Bord behaupten (AP1/AP3).
2. Planmoduswechsel mit offenen Plaenen/LZ-/UI-Fokus: kein unbeabsichtigtes GO oder RMB-Durchklicken (AP2).
3. Freie LZ mit Rand/Hindernis/zweitem Schiff: Soll/Ist-Landung und erreichbarer Einstieg muessen gemeinsam gueltig sein (AP3).
4. Wiederholte/abgelehnte Transfers oder gleichzeitiges Ausruesten: Mengen und Ausruestung bleiben atomar konsistent (AP6).
5. Ortswechsel bei laufender Arbeit/Reise: anderer Ort, Reservierungen und Fortschritt gehen nicht verloren; keine doppelten Belohnungen (AP4/AP8/AP9).

## Reihenfolge und Abhaengigkeiten

`AP0 -> AP1 -> AP2 -> AP3 -> AP4 -> AP5 -> AP6 -> AP7 -> AP8 -> AP9 -> AP10`

AP1 liefert zuerst einen spielbaren Rueckweg. AP4 ist ein kleiner verbindlicher
Vertrags-/Ownerentwurf vor den groesseren Ortsaenderungen, kein unkontrollierter
Weltumbau. AP5–AP7 bleiben auch ohne mehrere Orte einzeln nutzbare Verbesserungen.
AP8 erweitert den V1-Ausflug. AP9 macht den ersten echten Mehrzweckort daraus.
Keine grossen Pakete gleichzeitig auf denselben Flow-/Controllerdateien bearbeiten.

## AP0 — Reproduzierbaren aktuellen Ausgangspunkt sichern

**Ziel/Ursache:** Nutzerbild kann aus einer anderen EXE stammen als aktueller Main.
Quellfixes und tatsaechliche sichtbare Probleme zuerst auseinanderhalten.

**Dateien:** Create `docs/qa/playtest_20261110_baseline/README.md` und Quellen-/Buildreceipt; Read `docs/qa/orbit_base_combined_20261110/README.md`, `docs/qa/campaign_replace_crash_20261110/QA.md`, aktueller externer Buildbericht. Keine Nutzersaves veraendern.

**Interfaces:** Konsumiert Buildpfad, Quellpin und den normalen Kampagnenmenueweg; liefert festen Baselinebeleg und reproduzierbare Bedienfolge fuer AP1–AP10.

- [x] Laufende EXE/PCK und Commit anhand des Buildberichts ermitteln; Nutzerscreenshot als Nutzerbeleg getrennt halten.
- [x] Isoliertes Profil starten: neue Kampagne -> Satellitenflug -> Landung -> Daten sichern -> Boardingversuch. Native Bilder/Schritte/Sperrgruende aufzeichnen, Fehler mit Exit/Log belegen.
- [x] Historische Zweiausflugbelege als historisch kennzeichnen; aktuelle gezielte Pruefung ueber `godot_console.exe --headless --path . --script res://scripts/tests/campaign_pilot_ground_loop_test.gd` (Exit 0, keine fehlgeschlagenen Assertions). Eine Fehlerbaseline nicht als PASS ausgeben.
- [x] Baselinebericht mit den offenen Reprofaellen abschliessen. Noch keine Gestaltung oder neue Weltmechanik.

**Akzeptanz:** Jeder spaetere Vorher/Nachhervergleich nennt denselben Build-/Profil-/Aufloesungskontext.

## AP1 — Schiff anklicken, Crew zurueckholen, Abschluss verstehen

**Files:** Modify `scripts/ui/mission_a5_dropship_presenter.gd`, `scripts/tests/mission_tactical_sandbox_controller.gd` (gezielt Boarding/Schiffsauswahl), `scripts/meta/meta_layer_flow.gd` (`_request_singleplayer_return`), `scripts/meta/campaign_tutorial_presenter.gd`, `scripts/mission/mission_interaction_visual_state.gd`; gezielt Welt-Picking in `scripts/terrain/terrain_map_3d_view.gd`. Update `docs/dev/singleplayer_locations_jobs_contract.md`. Create `scripts/tests/playtest_20261110_extraction_feedback_verifier.gd`.

**Interfaces:** Bestehend `request_campaign_crew_boarding(craft_id: String) -> Dictionary`, `_request_singleplayer_return(craft_id: String) -> Dictionary`, bestaetigte Job-/Crew-/Aircraftsnapshots. Weltklick setzt nur Craft-Auswahl; Boarding bleibt Runtimeaktion. Neue sichtbare Aktion `Zum Schiff / Einsteigen` nutzt die vorhandene Truppbewegung und Boardingbedingungen.

- [x] Regression zuerst: geparkte Welt-Craft anklickbar; Auswahl und HUD zeigen dieselbe craft_id. Fehlende, verletzte oder entfernte Crew verhindert Boarding/Abflug mit konkretem Grund. Nach einem pending-Ergebnis folgt automatisch sichtbarer Statusrefresh statt verborgenem zweiten Pflichtklick.
- [x] Eindeutige Aktionen in kompakter Schiffskarte anbieten: zum Schiff, einsteigen, abheben/rueckfliegen entsprechend bestaetigter Phase. Details bleiben fuer Nebendaten; keine Teleporthilfe einfuehren.
- [x] Datenbergung, Rueckkehrziel, Boarding, Auftragserfolg und Heimkehr getrennt anzeigen. COM/NEXT durch echte Interaktionsnamen/Status ersetzen; alte Rohfelder fuer Diagnose/Compatibility erhalten.
- [x] Hilfepanel aus ueberdeckter Navigation herausnehmen; native Klickbarkeit aller Headeraktionen bei drei Zielaufloesungen pruefen. Falls verschiebbar: Randbegrenzung und Zuruecksetzen mitpruefen.
- [x] `godot_console.exe --headless --path . --script res://scripts/tests/playtest_20261110_extraction_feedback_verifier.gd` und bestehender `campaign_pilot_ground_loop_test.gd`: 0 Fehler/Exit 0. Danach nativer Kampagnenrueckweg ausschliesslich ueber Produktcontrols.

**Akzeptanz:** Nutzer kann ohne Kenntnis der Details-Hierarchie seine beiden Personen zurueckholen und versteht den Auftrag. Dunkle Ersatzgeometrie nativ identifizieren; nicht auf Basis der Textursache blind loeschen.

## AP2 — Planmodus mit unmittelbarem Rechtsklick

**Files:** Modify `scripts/tests/mission_tactical_sandbox_controller.gd` (`_unhandled_input`, `_issue_command`, `_on_go_phase_pressed`), `scripts/mission/mission_command_input_guard.gd`, `scripts/ui/components/command_button.gd`; Create `docs/dev/plan_mode_input_contract.md`, `scripts/tests/playtest_20261110_plan_mode_verifier.gd`.

**Interfaces:** Vorgeschlagen `set_planning_enabled(enabled: bool) -> void` im bestehenden Input-/Controllerowner. Modus ist Eingabepraeferenz, keine zweite laufende Order. Beide Wege verwenden bestehenden autorisierten Truppcommand; sofortiger RMB umgeht nur die notwendige separate GO-Bestaetigung.

- [x] Contract zuerst: Startmodus bleibt bisheriger Planmodus an; Wechsel loest keine gepufferten Plaene aus. RMB auf gueltigen Boden ist Move bei Modus aus. UI, LZ-Picker, Schiffsauswahl und ungültige Ziele werden vorher behandelt.
- [x] Verifier: an -> Plan ohne Bewegung vor GO; aus -> genau ein bestaetigter Move ohne GO; kein Durchklicken, kein doppelter Command, kein Kommando an falschen/unverfuegbaren Trupp.
- [x] Schalter oben im Plan-ausfuehren-Button mit getrenntem Hitbereich, Tastaturfokus und klarer An/Aus-Beschriftung implementieren. GO-Hauptflaeche bei aus als nicht erforderlich kenntlich machen.
- [x] Neuen Verifier headless ausfuehren (Exit 0/0 Fehler), normale Go-/Mehrtruppregression passend zum geaenderten Pfad. Native Klicks und Fokuswechsel testen.

**Akzeptanz:** Kein neues Bewegungssystem und keine Pause; bestehende Plaene gehen beim Umschalten nicht still verloren.

## AP3 — Freie Feldlandung, Richtung und normaler Anflug

**Files:** Modify `docs/dev/singleplayer_locations_jobs_contract.md`, `docs/dev/dropship_lz_target_accuracy_contract.md`, `scripts/tests/mission_tactical_sandbox_controller.gd` (LZ/Return/Approach), `scripts/mission/dropship_lz_accuracy_contract.gd`, `scripts/ui/mission_a5_dropship_presenter.gd`, `scripts/terrain/frontier_ship_visuals.gd`; Szenario-/Rueckkehrbruecke ueber `scripts/meta/singleplayer_runtime_adapter.gd`. Create `scripts/tests/playtest_20261110_free_landing_verifier.gd`.

**Interfaces:** Bestehende requested_lz_position/resolved_lz_position und approach_angle pro craft_id erhalten. Dynamischer Rueckkehr-/Einstiegsanker liest die bestaetigte geparkte Craftposition statt festem ship_return-Marker. Padlandung bleibt eine gueltige spezielle LZ.

- [x] Vertrag aktualisieren: freie Feldlandung auf Satellit/Handel bei geeigneter Flaeche, Pads bevorzugbare Orte. Ziel und skillabhaengiges Ergebnis muessen Schiffsfussabdruck, Rand, Kollision und zugänglichen Einstieg erfuellen. Kein sicherer Kandidat -> Ablehnung vor Flugbeginn mit Grund.
- [x] Verifier zuerst: mehrere weit getrennte LZ erlaubt; blockiert/ausserhalb abgelehnt; belegte zweite LZ unabhaengig; Soll/Ist sichtbar. Nach abweichender Landung funktionieren Interaktion, Crew-Rueckkehr und Boarding am tatsaechlichen Schiff.
- [x] Feste Kampagnen-Padkopplung in LZ **und** Rueckkehrpfad ersetzen. Skillwerte im aktuellen physischen Hexmass pruefen; Radien 96..12 nicht ungeprueft als Felder interpretieren.
- [x] Uhr/Richtungskreis fuer das ausgewaehlte Schiff anbieten. Vorhandene Richtungsenum zunächst beibehalten, nicht nebenbei beliebige neue Winkellogik einfuehren.
- [x] Normalen Anflug als zusammenhaengende Phasen Geradeausflug -> Bremsen -> Abfangen/Schweben -> Aufsetzen projizieren; Triebwerksstrahl am Modell. Visual schreibt keine Positionen in die Simulation. Bei schlechtem Skill keine Landung in Fels/Wand.
- [x] Neuen Verifier und `task_311_dropship_lz_target_pick_accuracy_contract.gd` headless pruefen; AP1-Gate wiederholen. Native Front-/Seiten-/Spielkameraaufnahmen der Landung mit beiden Soll/Ist-Markern und danach echtem Boarding.

**Akzeptanz:** Spieler bestimmt geeigneten Ort und Anflugrichtung, Skill aendert das sichere Ergebnis nachvollziehbar. Keine fest gekoppelte Rueckkehr am alten Spawnpunkt.

## AP4 — Vertrag fuer langlebige Orte und unabhaengige Reisen festlegen

**Files:** Create `docs/dev/persistent_location_runtime_contract.md`; Modify `docs/dev/orbit_quantum_travel_contract.md`, `docs/dev/singleplayer_locations_jobs_contract.md`, relevante Abschnitte `docs/ARCHITECTURE.md`. Vor Code diese Dateien gegen AP1/AP3 abgleichen.

**Interfaces / vorgeschlagene Aufteilung:**

- location_id = stabiler gemeinsamer Ort, instance_id = dessen Runtimeinstanz; job_id, fireteam_id, craft_id, unit_id bleiben separate vorhandene Identitaeten.
- Langlebiger Ortsowner unter SimulationRoot fuehrt lokale Objekt-/Interaktions-/Ressourcenzustaende. Scene/Viewport sind austauschbare Projektionen.
- Reisephasen nach craft_id statt einer globalen _craft_id. Aktiver Ansichtsfokus bleibt UI-Zustand.
- Bestehenden Kampagnen-/Supply-/Transportowner erweitern statt pro Ort kopieren. get_operations_snapshot()/request_operation() bleiben die UI-Bruecke.
- Hintergrundfortschritt aus autoritativen festen Simulationsschritten; Rendering verborgen deaktivierbar. Keine naive grosse delta-Nachholung fuer Combat/Navigation beim Rueckwechsel.

- [x] Konkrete State-/Commandgrenzen und Owner anhand aktueller Klassen dokumentieren, inklusive Reisezielbindung, Ortswechsel, Wartezustand und Close/Unload.
- [x] Lebenszyklus fuer A/B/Homebase mit zwei Schiffen tabellarisch festlegen: sichtbar, im Hintergrund, Reise, wartend. Kein implizites _release_active_mission fuer einen noch belegten Ort.
- [x] Checkpointsemantik explizit definieren: aktuelle erste Fassung speichert nur sichere Basiszustaende; keine unterwegs befindlichen Trupps durch Save/Continue teleportieren. Fuer AP8 einen kohaerenten Weltcheckpoint bei geerdetem Fokus/gesichertem Tick vorsehen oder Speichern ehrlich sperren, solange kein solcher Beleg existiert.
- [x] Architekturabweichungen im Contract begruenden, restliche SimulationRoot-/Registrystruktur bewahren. Testmatrix aus Review Focus 5 konkret auf AP8/AP9 verteilen.

**Akzeptanz:** Ein aktiver Ausflug ist sichtbar als abgeloester V1-Scope markiert; keine Behauptung, Mehrkartenbetrieb existiere bereits. AP4 liefert Design, AP8 die Runtime.

## AP5 — Drei grosse zusammenhaengende Ortskarten

**Files:** Modify `maps/homebase_frontier_exploration.json`, `maps/satellite_crash_site.json`, `maps/trade_outpost.json`, `scripts/meta/explorable_homebase.gd`, relevante Rendering-/Boundsbereiche `scripts/terrain/terrain_map_3d_view.gd`, gespeicherte Navigationsdaten; Update `docs/dev/homebase_map_services_contract.md`. Create `scripts/tests/playtest_20261110_location_terrain_verifier.gd` und `docs/qa/playtest_20261110_world/`.

**Interfaces:** Gespeicherte TerrainMapData/TerrainRegistry bleiben gemeinsame Flaechen-/Hoehen-/Navigationswahrheit. Ortsmetadaten definieren POIs, Basisstartkamera und Erweiterungsflaechen, ohne Aufgabenfortschritt zu besitzen.

- [x] Zuerst einen groesseren Satelliten-Kandidaten bauen und bei echtem Spielzoom messen. Als Startkandidat die bereits im Projekt verwendete Groessenordnung 96x98 Hexfelder pruefen; kein ungeprueftes verbindliches Flaechenmass fuer alle Karten. Mehr Flaeche nur nach Last-/Wegebeleg.
- [x] Verifier: Flaeche groesser als Altkarte, LZ-/POI-/Randbereiche erreichbar, keine sichtbaren begehbar wirkenden unerreichbaren Bodeninseln; alle Wege nutzen dieselben Grenzen/Hoehen. AP3-Landezonen mitpruefen.
- [x] Blockzaun durch passende Landschaft und bewusste Kartenkante ersetzen; Kamera/Pan/Zoom so begrenzen, dass normale Ansicht Terrain zeigt. Uebersicht darf echte Kartenkante erkennen lassen, kein unendliches Terrain versprechen.
- [x] Basis als kompakten moeblierten Kern in grosser Umgebung erhalten; Startzoom auf Gebaeude/Pad, Erweiterungsflaechen daneben. Handel als Hof-/Gebaeudeensemble statt enges Brett. Satellit mit getrennten Flaechen fuer spaetere Mining-/Wrackziele; noch keine gefaelschten Ressourcenaktionen.
- [x] Native Bilder gegen homebase.png/trade_outpost.png und Screenshot vergleichen, besonders Schraeglage, Terrainhoehe, Schatten, Details und freie Wege. Schrift aus bestehendem lizenziertem Themebestand pruefen, keine neue Font-Abhaengigkeit voraussetzen.
- [x] Neuen Verifier, `campaign_base_map_test.gd` mit bewusst aktualisierten Flaechenerwartungen sowie AP1/AP3 ausfuehren. 90-s-Profilerlauf bei Bewegung/Pan/Landung: Ladezeit, Speicher, Frame-P95/P99/Max, Navspitzen protokollieren. Kein Ruckelfreiheitsurteil aus blossen Strukturchecks.

**Akzeptanz:** Nutzer sieht eine Landschaft mit Ort darin; groesse und Basiszoom sind verschiedene Einstellungen. Bestehende Innenraum-/Tuerpruefungen bleiben gueltig.

## AP6 — Echtes Referenzinventar mit atomaren Transfers

**Files:** Modify `scripts/core/singleplayer_supply_state.gd`, `scripts/mission/singleplayer_supply_command_contract.gd`, `scripts/meta/singleplayer_runtime_adapter.gd`, `scripts/meta/homebase_screen.gd`, `scripts/meta/homebase_operations_presenter.gd`, `scripts/command/loadout_contract.gd`, `scripts/meta/campaign_checkpoint_store.gd`; Create begrenzte `scripts/mission/inventory_transfer_contract.gd`, `scripts/ui/components/personnel_inventory_panel.gd`, `docs/dev/personnel_inventory_contract.md`, `scripts/tests/playtest_20261110_inventory_transfer_verifier.gd`.

**Interfaces:** Vorhandene Loadoutoperationen bleiben gueltig. Vorgeschlagene neue Operation inventory_transfer mit request_id, item_id, amount:int, source_container_id, destination_container_id. equip aus realem Container nutzt denselben atomaren Supply-/Loadoutowner. Container-IDs referenzieren Ort/craft_id/unit_id, niemals Zeilenposition oder Anzeigename.

- [x] Bestehende Container-/Itemowner komplett kartieren, dann Contract: endliche positive Ganzzahlen, Kapazitaet, Slotkompatibilitaet, Eigentuemer/Ort und Naehe/Zugriff. Kein Transfer vom fernen Schiff in den Rucksack. Kleine Startausstattung explizit datenbasiert festlegen; keine Referenzmengen als Balance.
- [x] Tests zuerst: A->B erhaelt Summe; voller Rucksack, falscher Slot, unbekanntes Item, fremder/entfernter Container und amount<=0 unveraendert; request_id-Wiederholung genau einmal; Slotwechsel legt alten Gegenstand sicher zurueck. Konflikt bei gleichem request_id/anderem Inhalt ablehnen.
- [x] Runtime erweitern, Supply-/Loadouttransaktion zusammen bestaetigen. Bestehende Waffen-/Ruestungs-IDs verwenden. Helm/Werkzeug/Aufsatz/Rucksack nur insoweit aktivieren, wie Itemtyp/Wirkung vorhanden oder in diesem Contract konkret eingefuehrt sind; dekorativer Slot ist keine Funktion.
- [x] Ein gemeinsames Panel nach inventory_drag/inventory_grid: Person, angelegte Slots, Basislager, Schiffsfracht, Rucksack, Mengen, Kapazitaeten und Transferfeedback. Drag-and-drop und klickbare Alternative loesen dieselbe Operation aus. Personal und Trupp oeffnen dasselbe Panel.
- [x] Checkpoint erfasst Container und Ausruestung konsistent; isolierter Save/Load-Test ohne Gegenstandsduplikation. Neue Verifier headless, vorhandene Supply-/Loadoutregression und normale zweite Ausruestung/zweiter Ausflug.

**Akzeptanz:** Sichtbares Inventar entspricht bestaetigten endlichen Bestaenden. Mehr Platz durch Layout gewinnen; vorhandene Personenportraits und Stats nicht durch Ida-Beispielperson ersetzen.

## AP7 — Kompakte Operationsseiten und Sternkarte

**Files:** Modify `scripts/meta/homebase_operations_presenter.gd`, `scripts/ui/star_map_screen.gd`, `scripts/ui/star_map_canvas.gd`, `scripts/meta/singleplayer_region_map_presenter.gd`, `scripts/terrain/frontier_ship_visuals.gd`, UI-Theme/Layouthelper nach aktuellem Owner; Update `docs/dev/homebase_operations_ux_contract.md`. Create `scripts/tests/playtest_20261110_operations_layout_verifier.gd`.

**Interfaces:** get_operations_snapshot()/request_operation() weiterverwenden. Neuer Praesentationssignalvorschlag location_selected(location_id: String) am StarMapCanvas routet dieselbe Auswahl wie rechte Liste, niemals automatisch begin_approach.

- [x] Neuen Verifier: FOB fehlt im regulaeren Menue, Smart Mobile letzter Einstieg; Person/Trupp/Schiff-Auswahl und Inventar teilen dieselben IDs; Ortenamen/Status deutsch und lesbar; zweites echtes Schiff auswaehlbar.
- [x] Personenkarten zur kompakten Mehrspalten-/Listenansicht verdichten. Ein Drittel als Nutzerziel im Vergleich testen, keine Mindestschrift verkleinern; lange Namen umbrechen/Details anbieten. Sortierung/Doppelklick/Badges bleiben.
- [x] Trupp- und Abflugmodule begrenzen, statt auf gesamte Breite strecken. Erkennbares aktuelles Schiff samt Pilot/Besatzung anzeigen; freie Breite fuer weitere echte Module oder zweite Reihe nutzen.
- [x] Ortsmarker auf/bei Glut mit gemeinsamen map_to_screen-Transform zeichnen und picken. Rechte Ortsliste synchron halten; Cursorzoom/Pan erhalten. Schiff aus vorhandenem Cutlass-Modell isometrisch rendern oder dessen vorhandene qualitaetsgepruefte Projektion wiederverwenden, kein Pfeildreieck als Endstand.
- [x] Neuen Verifier und `star_map_ui_verifier.gd`, `star_map_camera_verifier.gd`, `compact_singleplayer_panels_verifier.gd` ausfuehren; native Bilder/Klicks in drei Aufloesungen. Keine neuen Contentorte der Asche-System-Referenz erfinden.

**Akzeptanz:** Mehr Information ohne mehr Flaechenverschwendung; Referenzinventar bleibt nutzbar. Ein gesperrter Ort wird auch ueber direkten Planetenmarker nicht anfliegbar.

## AP8 — Erster echter Betrieb an zwei Orten

**Files:** Modify `scripts/core/singleplayer_space_travel_state.gd`, `scripts/core/singleplayer_campaign_state.gd`, `scripts/meta/meta_layer_flow.gd`, `scripts/meta/singleplayer_runtime_adapter.gd`, `scripts/meta/campaign_checkpoint_store.gd`; Create gemaess AP4 `scripts/core/location_runtime_state.gd`, `scripts/mission/location_runtime_registry.gd`, `scripts/tests/playtest_20261110_two_location_runtime_verifier.gd` (Namen vorgeschlagen, bestehende geeignete Owner zuerst wiederverwenden).

**Interfaces:** AP4 location_id/instance_id, bestehende craft_id/fireteam_id/unit_id. Route-/Kampagnencommands bekommen expliziten Craft-/Ortskontext; get_operations_snapshot liefert alle Orte/Reisen und getrennten Ansichtsfokus. Registry indexiert Runtimeinstanzen, mutiert keine Jobs/Units selbst.

- [x] Test zuerst mit isoliertem Mehrtruppteam: A am Satelliten, B am Handel, Heimatbasis bleibt bestehen. Wechsel A/B setzt weder Unitpositionen noch Interaktion, Transport oder Inventar zurueck.
- [x] Globalen Reisezustand pro craft_id erweitern; weitere aktive Ortszustande erhalten, Missionprojektion an Fokus binden. Nur Render-/UI-Prozesse versteckter Orte deaktivieren; Hintergrundtick bleibt beim Owner.
- [x] Dieselbe location_id wird bei zweitem Besuch desselben laufenden Spiels dieselbe gemeinsame Instanz. Sichtwechsel, Kartenunload und Ende eines Jobs duerfen den Ort nicht neu auffuellen oder andere Besucher loeschen.
- [x] Tests fuer unabhängige Starts, belegte LZ und wartendes zweites Schiff, abgelehnten Rueckflug, Truppverlust und Rueckkehr eines Schiffs bei weiter laufendem anderen Ort. Kein globaler Boarding-/Returnlock.
- [x] AP4-Checkpointentscheidung umsetzen und pruefen: gesamter Weltzustand konsistent speichern/laden oder klar begrenzte Savesperre ohne Datenverlust. Keine aktive Auslandscrew bei Restore still heimsetzen.
- [x] Neuer Verifier headless und bisheriger Kampagnen-Zweiausflug als Regression; nativer Wechsel A/B/A mit sichtbarem Fortschritt. Profil bei 1/2/3 Orten, ein sichtbarer Viewport; Last/Frame-/Speicherwerte mit AP5 vergleichen.

**Akzeptanz:** Zwei reale getrennte Orte laufen gleichzeitig. Keine Behauptung fertigen Multiplayer-/Server-/PvP-Betriebs; aktuelle ENetpfade bleiben kompatibel und werden bei beruehrten Commands gezielt geprueft.

## AP9 — Satellitenort mit drei echten Besuchsgruenden

**Files:** Modify `maps/satellite_crash_site.json`, `data/singleplayer/locations.json`, vorhandene Item-/Servicekataloge und AP4-Ortsowner; Create begrenzter `docs/dev/location_resource_interaction_contract.md`, datenbasierte Ressourcenstellen und `scripts/tests/playtest_20261110_multiuse_location_verifier.gd`.

**Interfaces:** Stabile site_id je Erzstelle/Wrack, verbleibende Menge beim gemeinsamen Ortsowner. Bestehender zeitgesteuerter Interaktions-/Commandpfad gibt bestaetigten Ertrag an AP6-Container. Jobabschluss ist davon unabhaengig.

- [x] Ein kleines Miningvorkommen und ein groesseres Salvagewrack abseits der Absturzstelle authoren. Im Contract minimale Dauer, benoetigtes Werkzeug, Ertrag und Kapazitaet konkret begrenzen; keine komplette Berufssimulation.
- [x] Verifier: Auftrag allein laesst Ressourcen bestehen; Mining/Salvage allein erfuellt Satellitenauftrag nicht. Entnahme erschoepft die echte gemeinsame Quelle, volles Inventar erzeugt keinen verlorenen Ertrag, Abbruch/Retry doppelt nichts.
- [x] Orts-/Sichtwechsel sowie zweiter Trupp sehen denselben Restbestand. Ergiebigkeit wird nicht pro Trupp oder Job neu erzeugt. Entdeckung/FoW nicht durch alle Marker von Anfang an umgehen.
- [x] Native drei unterschiedliche Routen zeigen: Satellit, Erz, Wrack. Neue Verifier und AP6/AP8-Regressionen ausfuehren.

**Akzeptanz:** Eine Karte hat mehrere echte Zwecke und ist als spaeterer gemeinsamer Begegnungsort vorbereitet. Kampf-/PvP-Zwang und Netzwerkumsetzung folgen einem gesonderten Auftrag.

## AP10 — Gemeinsame Abnahme statt isolierter Helper-PASS

**Files:** Create `docs/qa/playtest_20261110_acceptance/README.md`, native Bilder, Ablauf-/Profilbelege. Update IMPLEMENTATION_STATUS/TASK_ROADMAP erst fuer tatsaechlich integrierte Ergebnisse; keine geplanten Pakete als fertig markieren.

- [x] Frisches isoliertes Kampagnenprofil: vorbereiten/ausruesten -> abheben -> Sternkarte -> freie Satellitenlandung -> Daten sichern -> Boarding -> Orbit -> Heimkehr -> Handel und zweiter Rueckweg. Alle normalen Controls, kein gesetzter Erfolg.
- [x] Mehrtrupp-Szenario AP8 plus Mining/Salvage AP9: unabhaengige Orte/Reisen, bestaetigte Container und Restore gemaess vereinbartem Checkpointvertrag.
- [x] In 3440x1440, 1920x1080 und 1280x720 Eingabe-/Layoutpass. Je Bereich Referenz, nativen Ist-Stand und offene Differenzen dokumentieren: Inventar, Basis, Handel, Sternkarte, A5-HUD, Landung.
- [x] Nur betroffene Tests und ein begrenzter normaler Profilerlauf nach letzter Aenderung. Fehler/Timeouts/Leaks explizit nennen; alte rote Gates gegen aktuellen Ausgangsstand pruefen, nicht pauschal ignorieren.
- [x] Nutzerabnahme von Stil und Verstaendlichkeit getrennt festhalten. Fuer spaeter beauftragten Export den geprueften Commit/PCK/EXE eindeutig binden und normalen EXE-Spielweg separat pruefen.

## Offene Entscheidungen und begrenzte Annahmen

- Genaue Kartengroesse, Anflughoehe/-zeit und Skillabweichung werden an realem Spielmass und Profil entschieden; Nutzer hat keine verbindlichen Zahlen vorgegeben.
- Richtungskreis startet mit vorhandenen Anflugrichtungen. Feinere Winkel sind eine spaetere ausdrueckliche Erweiterung.
- Basisreferenz verlangt kleinen Kern, nicht ungefragtes Rueckbauen der bestehenden zwei Gebaeude/Pads.
- Container-/Rucksackzugriff und Checkpoint waehrend Mehrortbetrieb muessen in AP4/AP6 konkret festgelegt werden. Keine stillen Ferntransfers, Duplikate oder scheinbar sichere Saves.
- Native Interaktionsfehler der konkreten Nutzerrunde bleiben bis AP0/AP1 offen; die Planung ist keine Fehlerbehebung und bestaetigt keinen Missionssieg.
- Kein neuer HTML-Report notwendig: dieser Auftrag liefert Markdownplan plus lokal mitgelieferte Bilder. Bei spaeterem HTML gilt der Workbenchvertrag.

## Selbstpruefung des Plans

- Anforderungen 1–5 -> AP1; 6–10 -> AP5/AP9; 11–13 -> AP3; 14 -> AP2.
- Anforderungen 15–20 -> AP6/AP7; 21–22 -> AP7; 23–26 -> AP4/AP8/AP9.
- Alle fuenf Review-Faelle besitzen konkrete funktionelle Pruefungen.
- Bestehende Funktionen, neue Bedienregel und Architektur-/Contentscope sind getrennt.
- Technische Umsetzung AP0–AP10 abgeschlossen. Verifizierter Endstand, native Bilder,
Review und ausdrueckliche Grenzen: docs/qa/playtest_20261110_acceptance/README.md.
Checkboxen bezeichnen die ausgefuehrten Arbeitsschritte, keine persoenliche Stil-
oder Exportabnahme.
