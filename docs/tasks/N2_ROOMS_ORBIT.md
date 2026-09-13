# Rostgrenze: Räume, große Einzelkarten und erster Raumkontakt

Autorisiert am 13.09.2026. Fortsetzung des eigenständigen Neustarts auf Basis 3eef3d7. Der Nutzer möchte ausdrücklich weiterhin separat geladene Maps; Piraten erscheinen auf einer zufällig zugeschalteten Begegnungskarte. Kein nahtloser Planet/Orbit und kein Höhenflug.

## Spielerweg dieser Stufe

1. In einer gegliederten Basis beginnen: Unterkünfte, Lager, einfache Werkstatt, Küche/Aufenthalt mit abseits stehendem Auftragscomputer; transparente Vorderwände und klarer Zugang. Umliegende Rostlandschaft und sichtbare freie Andockflächen schaffen Raum für spätere Module.
2. Die einfache Werkbank repariert und fertigt einfache Ausrüstung. Höhere Werkbankstufen schalten bessere Rezepte frei; der Einstieg bleibt klein. Figurenbogen zeigt vorhandene Person, Aufgabe, Fähigkeiten und Ausrüstung; weitergehende alte Crewideen werden im Gesamtplan ausdrücklich erhalten.
3. Die weitläufige Satellitenkarte zunächst absuchen. Unbekannte Radarsignale scannen, per Point-and-Click mit dem Shuttle auf derselben Ebene anfliegen, Nähe identifiziert den Fund, landen und bergen. Verborgene Fundmodelle/-namen nicht vor Entdeckung verraten.
4. Zur größeren orbitalen Handelsstation reisen. Gelegentlich wird dafür eine separate Raumbegegnung geladen: einfacher Freibeuter, Ausweichziele per Rechtsklick, Pilot und zweiter Mann am Turm, Angriff oder Flucht, danach Fortsetzung zum Reiseziel. Kein permanenter Figuren-/Schiffsverlust in dieser frühen Stufe.
5. Nur die aktive Karte rendern. Basis ca. 320×320 m, Mission ca. 640×640 m, Station ca. 160×160 m, Raumkontakt ca. 480×480 m als erste Projektgrößen. Maßstab/Startzoom anhand tatsächlicher Fensterbilder prüfen; keine Leistungszusage allein aus Kartenfläche.

## Arbeitsteilung / Verträge

- Kern: SimulationRoot/Catalog/SaveValidator, Simulationserweiterungen in kleinen Modulen, Migration alter Saves; echte autoritative Commandprüfung und ENet-kompatible Snapshots. Räume und Koordinaten zentral im Catalog. Regionwerte base/rust/station/space. Keine UI-Mutationen.
- Welt: ausschließlich scripts/world, lokale Blender-Konvertierung des Nutzer-Buccaneer, sichtbare Raumgliederung und größere Einzelkarten; Koordinaten aus Catalog. Keine Veränderung der Ursprungsmodelle. Modelle unter assets/local bleiben Git-ignoriert.
- Oberfläche/Integration: vorhandene Icongestaltung weiterführen, kontextbezogene Flug-/Radar-/Turmaktionen, schlanke Figurenbögen und Werkbankstufe, echte Produktfensterprüfungen.
- Gesamtbericht: umfassender, mobil lesbarer HTML-Spielplan mit aktuellen Entscheidungen, nachvollziehbarer Trennung von implementiert/geplant/offen und Quelle der übernommenen Crewideen. Als eigenständige private ChatGPT-Sites-Seite veröffentlichen, ohne Spielquellen, lokale Modelle oder fremde Projektgeschichte mitzupublizieren.

## Prüfung

Gezielte Kernprüfungen für Reisechance, Begegnung/Flucht, Tod/Rückführung, Radar vor/nach Entdeckung, Arbeiter-/Crewrollen, Pause, Wiederholungen und Save-Migration. Reale Fensterbilder von Basis, Station, Suchgebiet und Raumkontakt. Zwei ENet-Prozesse für neue geteilte Zustände. Bestehende Prüfungen aktualisieren, wenn der bestätigte Spielerweg bewusst verändert wurde; keine alten Erwartungswerte als Produktanforderung behandeln. Statische HTML-/Asset-/Scriptprüfung und bestätigte private Sites-Veröffentlichung.

## Noch spätere Gesamtziele

Bunker-Bodenkampf, Verwundung/Evakuierung/Respawn, umfassende Bewerbungen/Rekrutierung und Persönlichkeitssysteme, Mining und Salvaging am Boden/im Orbit, Hauling, Forschung, zusätzliche Schiffe/Planeten, faires PvP und große kombinierte Operationen bleiben im Gesamtplan. Diese Stufe behauptet keine Fertigstellung des gesamten Spiels.
