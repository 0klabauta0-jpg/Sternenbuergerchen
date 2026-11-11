# Restplan nach Polisa-Freigabe

## Ziel und Ursache
Der Nutzer hat Polisa R08 am11.11.2026 gestalterisch freigegeben und beauftragt die selbststaendige Fortsetzung sowie Bewegungsabstimmung mit dem Tabletop-Chat. Grosse Tests bleiben ausdruecklich spaeter. Dieser Task haelt die aktuelle Reihenfolge fest, statt aeltere erledigte Punkte erneut als offen zu fuehren.

## Umfang und Nicht-Ziele
Gesicherte Tabletop-Pakete gezielt pruefen/integrieren; unabhaengige Profil- und Forschungsfortsetzung auf vorhandenen Ownern. Polisa gestalterisch erhalten. Kein neuer Fahrzeugmodellbau, keine vorgezogene grosse Gefechts-/FPS-/Save-/Netzmatrix, kein Main-/EXE-Schritt in diesem Paket.

## Arbeitsaufteilung / konkrete naechste Schritte
0. Neuer Nutzerauftrag parallele Orte: Heimat/Polisa/Einsatz ohne Neuaufbau ansehen, Hintergrundfortschritt erhalten und lokale Serviceaktionen nicht an die gesamte Flotte koppeln. Bestehende Orts-/Reiseowner nutzen. Task PARALLEL_LOCATION_OPERATIONS_2026_11_11 und eigener Contract; Crew-Faehrbetrieb und unterwegs Speichern nicht implizit freigeben.
1. Tabletop besitzt AP5-Bewegung: Commands als Absichten, effektives vorhandenes Tempo in Ticksegmente umrechnen, logische Felduebergabe und stetige Darstellung trennen. Danach Lifecycle-/Speicher-/Netzgrenzen. Root integriert nur gesicherte Pakete; keine automatische Kartenaktivierung. AP4 plus vollstaendiger Korridorcache sind in Root f4353eed4 vorhanden, aber bewegen noch keine Figuren.
2. Profilagent: gemeinsamer read-only Erfahrungstext. Nur exakte Uebereinstimmung mit derselben Vorlage als solche kennzeichnen, sonst Individuelles Profil. Profilanteil an Tempo/Zielen/Schadenseingang aus vorhandener UnitProfileMath zeigen, keine neue Kampf-/Tempoformel und keine Savefelder. Echte interne Wertevereinfachung erst mit stabilen Tabletop-Verbrauchern abstimmen.
3. Forschungsagent: bezahltes Recycling nach Industrie und tatsaechlich gefertigtem Bergungswerkzeug; zwei salvage aus Basislager plus20Cr zu einem bestehenden Rucksack mit echtem12-Slot-Verbraucher. Forschung100Cr, alles vorlaeufige Balance. Bestehender Supplyowner, atomare Materialien/Output/Credits, alte Rezepte/Spielstaende erhalten. Danach Workbench-Ist-Baseline nachziehen.
4. Schiffsrest: aktuellen Owner-/Persistenzstand gegen Contract pruefen, dann kleinsten echten Komponenten-/Verbraucherpfad und lokale Polisa-Auslieferung planen. Kein Verkauf funktionloser Komponenten, keine erfundene Schiffsausstattung. Derzeit Heimatlieferung.
5. Spaeter gebuendelt: echtes B-Gefecht1x, Karten-/Editor-/Inventar-/Reisebedienung, Save/Continue, Netz, Performance; anschliessend bewusste Main-/EXE-Integration.

## Vertraege und Dateien
AGENTS, PROJECT_BRIEF, ARCHITECTURE, CODEX_RULES, ACTIVE_WORKPLAN, TABLETOP_RESTPLAN_INTEGRATION, hex_tactical_runtime_contract, hex_reservation_plan_contract, explicit_hex_ramps_contract, polisa_ship_equipment_contract, bestehende Forschungs-/Profil-/Workbench-Tasks. A/B/C512x256, Sternkarte256x256 und Polisa512x256 bleiben bestehen.

## Akzeptanz / lokale Pruefung
Aufgaben haben klare Dateibesitzer; keine zweite Gameplaywahrheit im UI. Bestehende Getter get_move_speed_factor/get_combat_speed_multiplier/get_accuracy_skill und Normierung bleiben kompatibel. Nur erforderliche enge Compile-/Ownerchecks pro tatsaechlicher Aenderung. Quelle, Integration und spaetere Abnahme getrennt dokumentieren. Polisa-Freigabe bezieht sich auf Gestaltung, nicht auf ungepruefte Handels-/Save-/Dockingfunktionen.

## Risiken / offen
AP5 und Lifecycle sind noch keine aktive Bewegung. Drei Vorlagen ersetzen nicht automatisch alle internen Achsen. Recyclingmaterialien brauchen Restore-/Replaybelege ohne Altstandbruch. Schiffsowner/Komponentenkatalog/Consumer und lokale Pad-/Crewuebergabe sind noch offen. Neue Fahrzeuge bleiben zurueckgestellt.

## Fortschreibung nach den Folgepaketen
Profilreadout6308e6f02 und Recycling/Workbench84dd481b1 sind integriert und gepusht. Die obigen Punkte2/3 beschreiben deren begrenzten Umfang, keinen offenen Implementierungsauftrag mehr. Kleine Profil-/Recyclingchecks und statischer Workbenchcheck bestanden; grosse Nutzungs-/Saveabnahme bleibt offen. AP5 besitzt jetzt reine Bewegungsprojektion3095c11b0 und Stop-/Zentrierkernfd8ed553a; echte Command-/Actoraktivierung bleibt im Tabletop-Chat.

Parallele Orte b3f9ab26d sind implementiert, kleine View44/0+Service30/0; echte
Mehrortabnahme spaeter. Warp-Benennung/D-bis-A-Vertrag3dcb24c3b und datierte
Erkul-/Abholreferenz2fca7f90d sind gesichert. Erster funktionaler Cutlass-Warpslot
jetzt eng integriert/geprueft:42/0 Warp+Store,14/0 Return,7/0 Root,30/0 Service.
Root/Tabletop-Hooks abgestimmt; kein Hex-/Move-/Tick-/Actorbody mitgeaendert.
Lokale Abholung bleibt eigener vorhandener Task, Waffen und Retrofit-Retirement
bleiben offen. Keine grossen Tests/Main/EXE.

Fortsetzung lokale Abholung: Nach Freigabe additiver Tactical-Crew-/Padbereiche
ist der bestehende Task umgesetzt. Reale leere Stationsaufnahme, eigene
Herkunft statt Fake-Outboundtoken, Heimatpadreserve, ausdruecklicher Handoff/
Boarding/Rueckflug und Receiptkompatibilitaet. Gemeinsame kleine Vertikal18/0,
Flow23/0, Backend43/0; Presencegrenze im Vertikaltest explicit_owner_endpoints_not_flight_motion.
Historische Pilotkarten und fehlender Campaignmarker gezielt korrigiert.
Grosse native Gesamtabnahme weiter spaeter. Movementquelle arbeitet noch ihre
engen AP5-Reviewbefunde ab; ohne gesicherten Commit kein fremder WIPimport.

Danach Quellpaket a66b84522 fertig uebergeben, unabhaengig geprueft und als
c5e536d0d integriert. ActualMove42/0 im gemeinsamen Stand; Polisa-Heimkehrprobe
18/0 nach Rootintegration und zwei Compilechecks0. Nur Evidenzattrs manuell
vereinigt, keine Gameplaykonflikte. 3D-/Gruppenankunft und weitere AP5/AP6–8-
Grenzen bleiben beim Tabletop-Chat; Produktionskarten weiter unaktiviert.
