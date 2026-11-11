# Orbit destination catalog: unverdrahteter V3-Draft

Der neue reine Helper build_v3_draft kompiliert einen uebergebenen heutigen V2-Datenkatalog in eine unabhaengige V3-Draftdefinition. Er liest keine Runtime-/Save-/Flightowner und schreibt weder die produktive JSONdatei noch einen Spielzustand. V2 und seine drei produktiven Marker bleiben unveraendert.

Alle bisherigen fuenf Orbit-IDs mit orbit_1-Koordinaten und alle Locationbindings bleiben erhalten. Genau ein Orbitziel je nonstation Body: vorhandene fuenf plus sun_orbit. Jeder hat einen einzigen Marker orbit_1. Sun nutzt abgestimmt q=Sun.q-(ceil(radius)+1), r=Sun.r, heute (58,128), mit kanonischer GRID.normalized-Position. Bounds und Nichtkollision werden geprueft; Fehler fuehren zum Reject, nicht zu stiller Suche oder Verschiebung bestehender Koerper. Sonne erhaelt keine Surfacebindung.

Stationkind station hat keinen eigenen Bodyorbit/Bodyareaindex. Polisa bleibt am Glut2-Koerperorbit. Unbekannte Nonstation-Bodies werden nicht verworfen. Die lokale Bodyarea-ID wird aus OrbitApproachLayout abgeleitet und bleibt 512x256; strategisch bleibt 256x256.

Die Rueckgabe enthaelt explizite V2->V3-Markeraliase nur fuer Migration. Es gibt keine normale Runtimefunktion zum Umleiten alter UIcommands; kuenftige Produktcommands muessen aktuelle IDs/Revisionskontexte verlangen. Abgeleitete Body-/Orbitindizes sind keine neue persistente Zielwahrheit. V3/Draftflags verhindern keine versehentliche Nutzung durch beliebigen Code; produktive Umstellung ist hier schlicht nicht verdrahtet und der heutige V2-only-Parser wird nicht geaendert.

Quelle und QA: docs/tasks/ORBIT_DESTINATION_CATALOG_DRAFT_2026_11_11.md. Erst der spaetere gemeinsam integrierte Produktpfad darf den Katalog umschalten.
