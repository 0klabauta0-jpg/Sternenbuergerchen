# Task 2: echte Bodenpersonen und besetzter Pilotenposten

Stand: 10.11.2026, isolierter Zweig task/base-personnel-world-20261109. Runtime-Kandidat c9d84f58d; abschliessender Verifier-Umbau folgt als eigener Validierungsschritt. Keine sichtbaren Fenster, keine CUA-Eingriffe und kein Push durch diesen Worker.

## Problem und Aenderung

Der bisher separat zugewiesene Pilot war keine echte Bodenperson im Missions-Payload. Die Kampagne uebergibt jetzt die wirklichen Rosterprofile und individuellen Loadouts beider Personen an die Mission; voruebergehende Einsatzmitgliedschaft veraendert die dauerhafte Truppzuordnung nicht. Bereits physisch eingeschiffte Personen bleiben auch nach einem Wechsel des Pilotenpostens eindeutig im Payload erhalten.

Jede reale einsatzfaehige Person des gelandeten Teams kann den Pilotenposten ueber assign_campaign_pilot uebernehmen; die Schiffdetails bieten dafuer eine kleine Auswahl. Eine Zuweisung erzeugt keine Anwesenheit. request_campaign_crew_boarding prueft den wirklichen Rueckweg zum gelandeten Schiff und stellt die bestehenden SimulationRoot-Embark-Effekte ein. get_campaign_pilot_flight_guard akzeptiert erst die bestaetigte Anwesenheit der aktuell zugewiesenen Person; bereits eingestellte, noch nicht ausgefuehrte Effekte reichen nicht. Rueckflug-Fuel wird erst nach diesem Guard abgebucht. Verzoegerte bestaetigte Missionsergebnisse bleiben bis zum Boarding erhalten und werden beim Freigeben der Missionsinstanz verworfen.

Der echte Zweipersonenlauf deckte ausserdem einen Teilformationsfehler auf: zwei besetzte Plaetze eines Vierpersonen-Presets verschoben den Mittelpunkt beim TAKE um rund 94 Welteinheiten. Dadurch brach die Interaktions-Haltebestaetigung nach echter Ankunft ab. Nur fuer Kampagneneinsaetze werden solche Teilformationen um den angeforderten Anker zentriert; relative Abstaende bleiben erhalten. Die vollstaendige Vierpersonenformation und der bisherige Einzelpersonenfall sind regressionsgeprueft. Skirmish verwendet die neue Zentrierung nicht.

## Nachweise

Alle Godot-Laeufe: 4.6.2, --headless, private APPDATA-Verzeichnisse, BelowNormal. Im finalen Zweiausflug bleiben Engine.time_scale und Missions-/Flugzeiten bei 1x; der vorhandene Treiber kann lediglich die alte Boarding-Anzeigefixture vorziehen. Der erste Abflug wartet vorher auf den wirklichen Basisweg und das bestaetigte Boarding.

| Pruefung | Ergebnis | Beleg |
| --- | --- | --- |
| Echter Kampagnen-Zweiausflug, Satellit und Handel | 97/0, Exit 0, zwei reale Heimkehren | pilot_logs/actual_campaign_two_sorties.log |
| Echte Profil-/ID-Uebergabe | 4/0 | pilot_logs/handoff.log |
| Zweipersonenformation plus unveraenderte volle Formation | 8/0 | pilot_logs/two_person_formation.log |
| Bestehende Einzelpersonenformation | 4/0 | pilot_logs/single_leader_regression.log |
| SimulationRoot-Embark-/Deploy-Effekte (TASK 117) | 9/0 | pilot_logs/simulation_effect_regression.log |
| Bestehender paralleler Transport/Drop (TASK 397) | 12/0 | pilot_logs/legacy_parallel_transport_regression.log |
| Parsecheck finaler Piloten-Verifier | ohne Scriptfehler | pilot_logs/parse.log |
| Aelteres HUD-Gate TASK 503, Default-/Skirmish-Kontext | 9/1, begrenzter offener Befund | pilot_logs/hud_503_bounded_failure.log |

Der reale Zweiausflug prueft beide echten NPC-IDs, deren wirkliche Bewegung und Deployment, Pilotenausruestung vor und nach Continue, Ablehnung eines erfundenen Ersatzpiloten, Ablehnung von Abflug ohne Anwesenheit ohne Fuel-Abbuchung und erst nach einem echten SimulationRoot-Tick erlaubtes Boarding. Die Leaderperson uebernimmt den Pilotenposten beim ersten Einsatz und behaelt ihn fuer die tatsaechliche erste Heimkehr, Checkpoint/Continue, den zweiten Abflug und die zweite Heimkehr. Beide Continues erhalten Identitaeten, Ausruestung, Ressourcen und Fortschritt; das Skirmish-Profil bleibt bytegleich. Der Rueckflug-Payload enthaelt beide IDs genau einmal.

Fruehere Diagnose-Laeufe erreichten dieselben Gameplay-Meilensteine, endeten aber mit einem Typfehler in einer Verifier-Assertion nach verschachtelten Coroutine-/Continue-Pfaden. Die strikten Abschlusspruefungen liegen jetzt in einer synchronen Hilfsfunktion; die Kampagnen-Verifier verzichten auf asynchrone super-Aufrufe. Der finale Lauf beendet sich regulär mit allen 97 Assertions.

## Grenzen und offene Punkte

Keine native Sicht-/Bedienabnahme und keine neue Absturz- oder Skillrisikobalance. Der aeltere TASK-503-Befund betrifft die Erwartung an ausgewaehlte eingeschiffte FT1-Rosterkarten im linken HUD. Er wurde nicht repariert und hier nicht gegen eine unveraenderte Baseline bewiesen; die neuen Kampagnenzweige sind im dortigen Default-Kontext aus. Deshalb kein pauschales Alle-Tests-gruen-Urteil.

Betroffene Owner: MetaLayerFlow, SingleplayerRuntimeAdapter.authorize_return, MissionTacticalSandboxController, bestehende SimulationRoot-Embark-/Deploy-Effekte und FireteamMovementController. Basisruntime, Savevalidierung, Geometrie und Basisprojektion liegen bei den anderen Task-Workern; der Gesamtbericht bewertet deren Nachweise getrennt.
