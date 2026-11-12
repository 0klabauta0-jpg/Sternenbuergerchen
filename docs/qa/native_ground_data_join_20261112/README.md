# Native A/B/C data join 2026-11-12

Isolierter gemeinsamer Integrationsbranch; committed Quelle 1b924b640 einschliesslich Rampenrevision5204312c0. Dies ist ein begrenzter Daten-/Assetjoin, keine neue Spiel-, Grafik-, Performance- oder Releaseabnahme.

## Ergebnis
A/B/C enthalten jeweils exakt131072 eindeutige persistierte Axialzellen. Odd-r Spalte q+floor(r/2)=-170..341 (512), r=-108..147 (256). Quell-JSONs sind byteidentisch zu1b924b640 und byteidentisch zur frischen deterministischen Ausgabe des portierten begrenzten Authoringpfads. Regionalversion3, Hoehenschritt0.75, terrain_height_rules=explicit_hex_ramps_v1. Keine tactical_grid_rules/keine globale Optin-Aktivierung hinzugefuegt.

A75/B85/C65 Rampenzellen; offline erreichbare Zellen53973/57737/76046; alle geprueften Marker-/Ressourcenanker sowie Rampen-/Brueckenpassagen bestehen den source-authoring-Check. Diese Zahlen belegen Datenkonnektivitaet, keine reale Actorbewegung. Fuenf referenzierte Meshpfade existieren; neuer Sandstein GLB und editierbares Blend sind die committed Originale samt SOURCES-Beleg. Kein Blender-Neubau oder neue optische Abnahme.

## Semantik / SaveAs
Marker-IDs, Standort-Metadaten, bestehende place_world-Felder, Struktur-IDs, Patrouillen und Enemy-Teamconfigs gegen die zuvor aktuellen96er-Karten geprueft. Keine Missions-/Job-/Ressourcen-Datei veraendert. B-Lager +66q, C-Chipcompound +91q/H4 einschliesslich Marker- und realen Blockerfootprints entsprechen der Quelle. Die alten JSONs liegen unveraendert unter maps/legacy/native_ground_20261112/.

Godot4.6.2 TerrainMapData SaveAs/Reload aller drei voller Karten:92 Checks,0 Fehler. Alle393216 Zellen inkl. Koordinaten, Hoehen, Rampen und Objekttyp-IDs erhalten; Autorenmetadaten erhalten; Quellen unberuehrt. Zweiter SaveAs bestaetigt stabile kanonische Marker-/Enemy-Normalisierung. Der Verifier liegt neben diesem Bericht und kann mit godot_console.exe --headless --path . --script res://docs/qa/native_ground_data_join_20261112/save_reload.gd ausgefuehrt werden; Ausgabe in user://native_ground_data_join_20261112.

Die ersten strikten Diagnosen bleiben als save_reload.log und save_reload_normalized.log erhalten: Der bestehende Savepfad rundet Markerpositionen auf ganze Weltpixel, ergaenzt Katalogfarben und Default-Enemyprofile. Der schon in den96er-Karten unbekannte marker_type_id spawn_enemy_defense wird zu custom normalisiert; semantische Marker-ID, Name und gerundete Position bleiben erhalten. Der abschliessende Test verwendet fuer diesen bestehenden Vorgang TerrainMarkerCatalog.has_type und prueft Stabilitaet beim zweiten Save. Kein Runtimefix oder unerwaehnter neuer Fehler.

## Checkpoint-/Versionsgrenze
Die geaenderte Kartenflaeche/Hoehen/Rampen veraendern den Registry-Fingerprint. Aktive Oberflaechensaves alter Karten duerfen nur bei explizitem Legacyrouting geladen werden; der Companion-Checkpointvertrag muss sonst Map-Fingerprintmismatch ablehnen. Keine stille Actorumsetzung. Die erhaltenen JSONs sind keine automatische Routingimplementierung. Urspruengliche reine Home-Checkpoints ohne Oberflaechenactors bleiben ueber semantische IDs kompatibel.

## Nachweise / Grenzen
Manifest mit Quell-/Legacy-SHA256: data_manifest.json. Deterministische Reports A/B/C_authoring_check.json. Finaler Enginebeleg save_reload_catalog_normalized.log. Quelltask ist als historischer Snapshot abgelegt; dessen fruehere native/Gameplayaussagen sind hier nicht neu bestaetigt. git diff --check fuer die zugeordneten Daten/Authoringdateien erfolgreich. Keine Gefechte, breite Tests, EXE oder Commit/Push durch diesen Teilauftrag.
