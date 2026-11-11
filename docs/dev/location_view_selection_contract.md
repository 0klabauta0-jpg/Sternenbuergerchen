# Ansicht und Serviceschiff sind keine Reiseidentitaet

MetaLayerFlow.open_location_view oeffnet homebase mit erlaubter Remoteansicht, star_map ohne Reisecommand oder einen bereits registrierten Ort ueber focus_location. Unbekannte/ungeladene Orte werden abgelehnt. Ein blosser Wechsel ruft weder Ortsaufnahme, Szenenkonfiguration, Boarding, Rueckflug noch Clear/Release auf.

_view_craft_by_location besitzt nur die UI-Auswahl. select_location_view_craft prueft bekannte Flow-Craftdefinition plus aktuelle Ortszuordnung: homebase nach _aircraft_location_by_craft, Missionsort nach derselben aktuellen Missionzuordnung und _craft_location_runtime/LocationRegistry. Diese UI-Pruefung ist KEINE Service-/Landungsfreigabe; der Backendowner prueft vor jedem Gameplaycommand weiterhin Parken, Transit, Anwesenheit und Zugang. Leere Auswahl darf ausdruecklich loeschen.

get_location_view_snapshot liefert nur view/location_id/craft_id. Missionort kommt vom lebenden betrachteten Root, nicht von _active_singleplayer_identity. Ungueltige oder stale Auswahl liefert craft_id=''; es gibt keinen Fallback auf Reisefokus, ersten Servicecraft oder Primaerbesucher. Auf star_map ist location_id/craft_id leer. Die Auswahl darf fuer einen geladenen Hintergrundort gespeichert werden, aendert aber weder sichtbaren Ort noch Reisefokus oder Mission-/Besuchsidentitaet.

Hintergrundabfahrt behaelt die bereits betrachtete Ortsansicht; reale Primaerjob-Abbruch- und Crewretirepfade bleiben bestehen. Home-/Approach-Ankunft darf nur dem aktuell auf der Sternkarte betrachteten Reisecraft folgen. Sonst bleibt der fremde View mit seinen vorhandenen Kontextprojektionen erhalten. Jede lokale Runtime und ihr Fortschritt bleiben beim bisherigen Owner.

Die Meta-Timeranzeige liest den bereits vorhandenen CombatLoopDriver.mission_timer_started_at_msec und mission_time_limit_seconds je Ort. Cache/Fallback sind nur bestehende Anzeigeprojektionen, keine zweite Uhr. Ansichtswechsel starten, pausieren oder resetten diese Uhr nicht.
