# Strikter V3-Kaltleser, keine Liveumschaltung

Source0bbcee40b nach engem unabhaengigem Readonlyreview ohne Produktblocker als
c1a1de786 integriert. Sourcef83299688 ist bereits vorhandener Helferimport und
wurde nicht doppelt uebernommen.

Frischer privater v3_reader bestanden, sauberer Log, Sourcehashes inklusive
echtem data/singleplayer/star_system.json und echtes Spielerprofil unveraendert,
Canary vorhanden. Der Runner setzt space_reader_probe/isolated=true ausschliesslich
in seinem neu erstellten privaten project.godot. Ohne diesen Marker verweigert
die Probe vor jedem erreichbaren Schreibablauf den Start. Alle V3-/Defektkopien
werden nur in der privaten JSON-Kopie geschrieben, nie in den Produktkatalog.

Echter V2-/V3-Coldconfigure, bestehende fuenf Orbitkoordinaten/Locationlinks und
Warp zum Sonnenorbit geprueft. Unbekannte, nichtnumerische und gebrochene Version,
alte V3-Marker, Draft-/Migrationsdaten und Sonnenoberflaeche werden abgewiesen.
Fehlerhafte Neukonfiguration laesst die alte Definition nicht weiterbenutzen.

LiveJSON weiterhin V2, automatischer lokaler Warpschalter weiterhin AUS.
Lokaler Polisa-Dockanschluss und normaler Besucherprofilproducer/AP6c sowie
AP7/8 bleiben offen. Keine Save-Schemamigration oder Away-Speicherfreigabe,
keine grosse native/Performanceabnahme, keine EXE.
