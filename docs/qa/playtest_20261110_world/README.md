# AP5 — groessere Ortskarten

Vier gespeicherte Karten mit 9408 Hexfeldern, signierten Koordinaten und unveraenderten Innenraum-/Missionsankern. Erweiterte Basisnavigation behaelt die bisher gepruefte Raumclearance. Der separat gerenderte Basis-Blockzaun ist entfernt; die Startkamera umfasst Gebaeude und Pads. Referenzen homebase/trade_outpost und Nutzerscreenshot wurden betrachtet. Die Basis bleibt gegenueber dem Referenzbild noch weitlaeufig und die Landschaft detailarm: keine persoenliche Stilabnahme behauptet.

Pruefung: location_terrain 16/0; campaign_base_map 9/0. Lookup-Verifier auf 150528 feinen Navigationszellen 2000 identische Objekt-Lookups in 0.783 ms. Vorheriger linearer Lookup schon auf alter kleiner Navigation 3246 ms; Index veraendert keine Gameplaydaten.

Native D3D12, RTX4070TiSuper, 1920x1080, privates APPDATA: 26912 ms Aufbau, anschliessend 90 s ruhende Basisansicht: 21374 Samples, P95 8.353 ms, P99 15.328 ms, Maximum 148.709 ms, statischer Godot-Speicher ca.670.6 MB. Zwei kurze Vorlaeufe hatten wesentlich schlechtere Werte und sind nicht unterschlagen: P95 ca.134 ms; Shader-/Desktoplast nicht isoliert. Keine allgemeine Ruckelfreiheits-/Releaseaussage. Bewegung/Pan/Landung und mehrere Orte werden im gemeinsamen Abschluss separat geprueft.

Reproduzierbare Scripts: playtest_20261110_location_terrain_verifier.gd, playtest_20261110_terrain_lookup_verifier.gd, playtest_20261110_native_base_probe.gd. Rohdaten output/playtest_20261110; nativer Screenshot dort native/base.png. Kein Nutzerprofil oder laufendes Nutzerspiel bedient.
