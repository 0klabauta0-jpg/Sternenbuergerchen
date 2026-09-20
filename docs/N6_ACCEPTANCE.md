# N6 · Reise, Fracht, Crewverwaltung und Flugaufträge

Stand 21.09.2026. Godot 4.6.2. Auftrag: [N6_TRAVEL_CARGO_UX.md](tasks/N6_TRAVEL_CARGO_UX.md).

## Spielbarer Umfang

- Asche-Systemkarte mit drei Planetengruppen und neun vorhandenen Zielen. Vierzehn Einzelkarten und Risiken bleiben erhalten. Eigenes Schema, keine kopierten RSI-Bilddateien. Anregung: offizieller [Pyro Galactic Guide](https://robertsspaceindustries.com/en/comm-link/spectrum-dispatch/13852-Galactic-Guide-Pyro-System).
- Orbitaufstieg und Planetenanflug als aus dem Snapshot animierte Reise. Kein Reisebalken; Pause bleibt zugänglich und hält Darstellung und Spielzeit an.
- Warenkarten zeigen ausschließlich positive Bestände, individuelle Symbole, Stück und Frachtplätze. Menge wählen, echte Drag-and-drop-Verladung oder Klick. Host bestätigt den atomaren transfer-Befehl. Keine erfundenen Massenwerte.
- Lager benennt Heimatdock/Schiffszugang als Voraussetzung. Blackbox erst ausladen, dann über dauerhaft sichtbaren Button 260 Cr und Bauplan abholen. Verständliche Bedienung der bestehenden Zahlung.
- Kontext oben links neben Werkzeugleiste, Crew rechts, Systemfunktionen im Header. Segoe-UI-Systemschrift mit Fallback, weniger Versalien. Büroterminal im Aufenthaltsraum zeigt vorhandene Crew und öffnet Dossiers; keine Rekrutierung behauptet.
- Flugnavigation berücksichtigt hohe statische Hindernisse ab 4 m und konservativen Hüllenradius plus Sicherheitsabstand. Gecachtes 4-m-A*-Raster, anschließend Sichtlinienglättung mit exakter Rechteckprüfung. Ziele in Hindernissen oder ohne sicheren Weg werden abgelehnt. Pilotenskill verändert Tempo, nicht Sicherheit.
- Patrouille zwischen aktuellem Ort und Rechtsklick-Ziel; endliches lokales 180-m-Suchraster, in rust mit Radar und tatsächlicher Näheidentifikation. Halt und manuelles Flugziel ersetzen Auftrag. Kein automatisches Mining/Handeln, keine gleichzeitigen Regionen.

## Zustand und Kompatibilität

SimulationRoot bleibt alleinige Autorität. Optionales ship.order ergänzt Schema5: leer oder mit kind (patrol/search), region, points und index. Alte Schema5-Daten ohne Feld werden ergänzt. Vorhandene Felder werden nach Typ, Tätigkeit, Region, Flugmodus, Reisebindung, Punktzahl/Positionen, Index und Zielkonsistenz geprüft. Punkte bilden den Auftrag; berechnete Umwege sind nur flüchtiger Cache. Pause, Save/Load und Koop-Snapshots erhalten den Auftrag. Reise und Landung setzen ihn zurück. Nach Laden früher erlaubter Flugpositionen in neuer Hüllengeometrie wird ein freier Nachbarpunkt gesucht und geloggt; blockierte alte Ziele werden mit Meldung angehalten. Historische Validatoren bleiben unverändert.

## Nachweise dieses Arbeitslaufs

- 810 Kernprüfungen: 38 neue Flug/Fracht, 57 Crew, 67 Migration, 160 Navigation einschließlich Bürozugang, 104 Grundlauf, 73 Orbit, 147 Boden, 164 Welt/Wirtschaft. Abschließende Läufe bestanden. Navigation meldete bis 1968 ms für eine initiale Bodenwegplanung; keine allgemeine Performancegarantie.
- 97 Prüfungen im echten Produktfenster: erster Auftrag vom Start über Radar/Bergung bis Lager-Drop und tatsächlichen +260 Cr, Büro/Dossier, Handeln, F5/F9, zentrierte Reiseanimation mit Pause, Patrouillenklick und Halt. Nachweise: tests/travel_cargo_window_test.gd, output/n6-product-result.json, output/n6-window-final.log. Keine Gameplay-Erfolgsdaten injiziert; Simulation zeitlich beschleunigt.
- 12 Save-Lebenszyklusprüfungen über vier neue Prozesse. Bestehende Karriere nicht benutzt.
- ENet: 65 Prüfungen in zwei Produktprozessen; vollständige Snapshots bei Pause/Restore/Abschluss gleich. TEMP-Evidenz: sternen-internet-abf77dc91ad74f499d29f0e1be74b349.
- Öffentliche WSS mit DNS-Ersatzweg: 79 Prüfungen in zwei Produktprozessen, darunter Gast-Patrouille, replizierter Auftrag und Halt. TEMP-Evidenz: sternen-internet-28b6d80f95a748f0b682cd1917a17496. Kein Nachweis zweier unabhängiger Haushalte.
- Screenshots angesehen. Angeschnittener Animationsrahmen und mitscrollende Abgabe vor letzter Abnahme korrigiert. Maßgeblich ist der abschließende ungestörte Fensterlauf ohne Enginefehler; durch parallele native Fenster gestörte Zwischenläufe gelten nicht als Abnahme.
- Windows-Export, frisch entpacktes SHA-Manifest, normale EXE-Starts für Menü/Spiel und 29 Proben im exakten eingebetteten PCK bestanden. Siehe WINDOWS_DELIVERY.md.

## Grenzen

Rekrutierung, XP, eigenständiger Fernhandel, reale kg-Massen, dynamische gegenseitige Schiffskollision, begehbare Schiffsinnenräume und PvP bleiben offen. Flugplanung ist konservativ; enge Stellen können unpassierbar sein. Büro ist ein Arbeitsplatz im Aufenthaltsraum. Beide Crewporträts verwenden weiterhin das bestehende Kenney-Motiv. Tests sind keine menschliche Verständlichkeits- oder Spielspaßabnahme.
