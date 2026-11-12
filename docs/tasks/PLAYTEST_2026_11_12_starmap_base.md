# Spieltest 12.11.2026: Sternkarte und Basis

## Ziel und Ursache
Der Spieltest meldet einen blockierten Uebergang vom Orbit zur Oberflaeche und schwer auffindbare Raumsteuerung. Sternkarte und Basis sollen konsistente, gut sichtbare Aktionen erhalten.

## Umfang und Akzeptanz
- Je Himmelskoerper ein Orbitmarker; vorhandene Reise- und Speicherstaende sicher behandeln.
- Flugziel und Ortsanflug tatsaechlich erreichbar, Auftrag sichtbar markiert; Sprung mit links Auswahl, rechts Ziel, Treibstofffeedback und Alt-Reichweite.
- Rotten als eingeklappte, ausfahrbare Karten links auf System- und Raumkarte; Auswahl per Klick, Strg und Rahmen, Schiff in Rotte erkennbar.
- Steuerung, Basis ansehen sowie Trupp und Ausruestung links; Standort der Basis nennen, Flugdeck zeigt nur anwesende Schiffe.
- Boerner-System, sinnvolle Ortsnamen, zwei Monde: erster mit Heimatbasis, zweiter fuer spaetere Skirmishbasis vorbereitet.
- Kenney Space/Fabrication als Gestaltungsgrundlage fuer Flugpads, Waende und Boden; einheitliche Palette und Bereichsicons.

## Nichtziele und Grenzen
Keine zweite Gameplay-Wahrheit im UI. Keine Umdeutung alter gespeicherter Reiseziele ohne Migration; keine behauptete visuelle Abnahme ohne native Sichtpruefung. Skirmishbasis auf zweitem Mond nur vorbereiten.

## Dokumente
`docs/ARCHITECTURE.md`, `docs/dev/orbit_quantum_travel_contract.md`, `docs/dev/persistent_location_runtime_contract.md`, `docs/dev/graphics_reference_revision_contract.md`.

## Betroffene Dateien und Pruefung
Voraussichtlich Sternkarten- und Orbit-UI, Reise-/Rottenowner, Systemdaten, Basis-/Baudarstellung und zugehoerige Verifier. Gezielt reale Navigations- und Auswahlwege, Save-Kompatibilitaet und native Darstellung pruefen. Betroffene Dateien bei Umsetzung konkretisieren.

## Risiken / offene Punkte
Aktives V2-System hat drei Marker pro Orbit; V3 ist vorbereitet, aber nicht produktiv umgestellt. Die aktuelle Systemdefinition hat neben Glut 1a und 1b einen dritten Heimatmond. Rotten werden derzeit nicht gespeichert. Korrekte Zuordnung von Heimatbasis und alten Speicherstaenden muss vor Umbau geklaert und getestet werden.

## Zwischenstand 12.11.2026
Auf Main cb331cd0d separater Task-Worktree: Sternkarten-Detailpanel und Navigation links angeordnet; Sternkartenkopf zeigt Börner-System. `playtest_20261112_left_panel.gd` und `orbit_auto_transit_ui_verifier.gd` headless erfolgreich. Noch kein nativer Sichtcheck. Alle weiteren Akzeptanzpunkte oben bleiben offen; die Ursache des gemeldeten Orbitproblems ist nicht reproduziert. Kein Commit, Push, Main-Merge oder EXE.

## Fortsetzung: aktueller Pruefstand
Sternkarte zeigt nur `orbit_1` je Koerper; der V2-Reiseowner und seine weiteren Marker bleiben fuer bestehende Zustandsdaten erhalten. Angenommene Auftraege zeigen Zielkoerper und Markierung, Schiffe sind einzeln per Klick fokussierbar, Rechtsklick auf sichtbaren Orbitmarker sendet den bisherigen Sprungbefehl. Stern/Planet heissen im Datenkatalog Börner/Mare Nostrum; IDs bleiben stabil.

Im isolierten APPDATA-Testprofil durchlief der echte Kampagnenweg Annahme, Boarding, Abheben, Sprung/Abbruch/Neustart, Anflug, Kartenaufbau und Landung: `CAMPAIGN_AIR_SUPPORT_REAL passed=31 failed=0` (scripts/tests/playtest_20261112_real_approach.gd). Das ist kein Beleg fuer den Zustand des Nutzerspielstands und kein nativer Sichttest. Neue gezielte Headlesschecks fuer Marker, Zielhinweis, Schiffsklick, Rechtsklick, Namen und Seitenleiste bestehen; Kamera 28/0, Orbit-UI bestanden. `playtest_20261110_planet_sites_verifier.gd` hat einen veralteten `_ship_texture`-Check: bereits Main besitzt dieses Feld nicht mehr; die anderen drei Checks bestehen.

Noch offen: Rottenkarten und Mehrfachauswahl einschliesslich Gruppenspruengen, Alt-Reichweite und Spritfeedback fuer Spruenge, echter Zwei-Mond-Umbau einschliesslich Migrationspfad, Basisstandort, Kenney-Baukasten und Icons, visuelle und breite Regression. Spruenge selbst haben derzeit keine distanzbasierte Treibstoffabrechnung; vorhandene Kraftstoffkosten gelten fuer Ortsrouten/Anfluege. Vor Reichweitenanzeige den Vertrag erweitern, nicht eine erfundene Reichweite anzeigen.

Nachtrag: Ein Klick auf ein Rottenmitglied fokussiert dessen existierende Führung und markiert zusätzlich das konkret geklickte Schiff; `playtest_20261112_wing_focus.gd` bestanden. Das ist noch keine Mehrfachauswahl oder Gruppennavigation.

## Rotten-Fortsetzung auf Main 668c70202
Einklappbare linke Rottenreiter, Klick/Strg und Rahmenwahl im Reiterbereich; Selektion bleibt UI-State. Ein Sprung sendet fuer jedes ausgewaehlte Rottenmitglied den vorhandenen Einzelcommand, Ablehnungen werden pro Schiff angezeigt; Teilerfolg ist moeglich. Klick auf Karte synchronisiert die zugehoerige Rotte. Mausereignis-Verifier, Gruppensprung mit simulierter Teilablehnung, bestehender Wing-Checkpoint und aktualisierter Mehrschiff-Reiseowner-Verifier bestanden. Noch kein nativer Sichttest oder integrierter Mehrschiff-Gruppensprung mit echten Schiffen; Rahmenselektion auf der Sternkarte selbst, Fuel/Alt, zwei Monde, Basis und Grafik bleiben offen. Alter space_travel_state_verifier erwartet historisches Zwei-Koerper-System und ist nicht aktuell.

## Fortsetzung: integrierte und native Rottenprobe
Echte Sternkarten-Controls, zwei Reiseowner, SimulationRoot und Runtimeadapter: Auswahl und Gruppensprung durch native Mausereignisse 3/0, auch auf nicht aktiviertem Windows-Desktop; Aufnahme und Grenzen unter `docs/qa/starmap_wings_20261112/`. Karten fahren vertikal auf. Alt zeigt echte Hin-/Rueckflug-Fuelgates ab Heimatbasis; Warp selbst kostet weiterhin keinen Treibstoff. Basisansicht liest Heimatmondbezeichnung aus Systemdaten. Erster realer Kampagnenflug nach diesen Aenderungen 31/0. Weiter offen bleiben seitliche Flyouts, Rahmenselektion direkt auf der Sternkarte, Sprungtreibstoff und geometrische Reichweite, Zwei-Mond-Migration und Kenney-Bauteile/Icons. Historischer Basisverifier 107/97 wegen ueberholtem Fixture; keine breite Basisfreigabe.
