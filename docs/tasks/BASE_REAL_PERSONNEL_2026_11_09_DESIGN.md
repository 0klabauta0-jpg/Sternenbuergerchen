# Begehbare Originalraeume und echte Basis-NPCs

Status: Umsetzung des direkt beauftragten Umfangs, Rollenwahl explizit bestaetigt. Grundlage Main2302ac85a. Nutzerkorrektur: In der Kampagne gibt es keine zusaetzliche Commanderfigur; eine der zwei echten Startpersonen fuehrt das Team. Auch eine andere echte Person darf den Pilotenplatz uebernehmen; keine neue zufaellige Absturzmechanik in diesem Schritt.

## Befund und Ziel

Die aktuelle Basis bewegt nur einen separaten Erkundungs-Commander. Roster-NPCs, Boarding und Ausruestung werden bisher ueber Operationsansichten bedient. Terminals sind eigenstaendige Standkonsolen an groben Rasterpositionen. Eine echte Bett-/Schlafaktion existiert noch nicht; der vorhandene medizinische Recovery-State ist kein Schlafsystem.

Der Headless-Geometriecheck verwendet die tatsaechlich importierten Originalmeshes als unveraenderte Trimesh-Physikgeometrie. Die bisherigen Kartenwege schneiden in beiden Gebaeuden sichtbare Geometrie: Habitat bei(13.1716,0.65,7.225427), Halle bei(28.44644,0.65,7.701452). Die bisherigen Pathfinder-Gruentests allein reichen deshalb nicht. Diagnose: .scratch/base-world-20261109/geometry-before.json.

## Vorgehen

Die bestehenden Runtime-/Transport-/Loadout-Commands wiederverwenden und die Basis als vollwertigen Zugang dazu anbinden. Reine Figurenduplikate oder nur zusaetzliche Menue-Shortcuts erfuellen den Auftrag nicht. Originalraeume und ihre Einrichtung bleiben erhalten; keine erneute kahle Ersatzarchitektur.

### 1. Geometrie, Tueren und Terminals

- Laufdaten offline an den Originalwaenden, Tueren und Moebeln ausrichten. Ein feineres Basen-Laufraster soll schmale Durchgaenge abbilden; die sichtbare Ausdehnung der36x28-Basis bleibt erhalten. Die konkrete Aufloesung wird gegen Durchgangsbreite und Initialisierungs-/Pfadkosten geprueft.
- MapData/TerrainRegistry bleiben Navigationswahrheit. Meshabfragen dienen Authoring und unabhaengiger Verifikation; keine per-frame Geometriesuche oder nachtraegliche Navmutation aus Visuals.
- Gepruefte Routen vom Aussenbereich durch die sichtbare Tuer zu den nutzbaren Raeumen, Betten und Arbeitsplaetzen. Koerperbreite/Abstand zu Waenden und Moebeln mitpruefen; keine Wegabkuerzung durch Meshflaechen.
- Personal-/Smart-Mobile-Funktionen an vorhandene passende Arbeitspunkte, Ausruestung an den Arbeits-/Lagerbereich, Ruheplaetze an die vorhandenen Betten. Flug-/Tankzugang bleibt am Pad. Bedienpunkte, Marker und Beschriftungen so setzen, dass sie weder in Waenden/Moebeln stecken noch einander verdecken. Bestehende Monitore verwenden, statt ueberall neue Standkonsolen dazuzustellen.
- Ein Klick auf ein entferntes Terminal kann die ausgewaehlte Person zum Bedienpunkt schicken. Erst nach bestaetigter Ankunft wird die bestehende passende Ansicht geoeffnet. Beim blossen Vorbeigehen wird eine Interaktionsmoeglichkeit sichtbar; kein ungewolltes grosses Popup.

### 2. Echte Personen auf der Karte

- In der Kampagne exakt die zwei vorhandenen Roster-IDs darstellen: Pilot und einsatzfaehiger Leader. Keine dritte Commanderfigur. Eine dieser Personen traegt die Fuehrungsrolle; keine neu erzeugte Begleitperson.
- Linksklick waehlt eine echte Person; Name, Rolle, Zustand und passende Aktionen erscheinen in einer kleinen Aktionsleiste. Rechtsklick setzt ein gueltiges Bewegungsziel innerhalb der Basis. Das ist Basenverwaltung; die bisherige taktische Befehlshierarchie im Einsatz wird dadurch nicht allgemein ersetzt.
- Sichtbare Personen, Positionen und Auswahl referenzieren dieselben IDs wie Personalmenue, Ausruestung, Trupp und Schiff. Position und laufende Aktionen liegen bei einem SimulationRoot-gebundenen Basis-Runtimepfad, nicht in UI-Controls. Ansichtwechsel stoppen keine bereits autorisierte Bewegung oder Boardingaktion.
- An Bord befindliche Personen verschwinden erst nach bestaetigtem Boarding aus dem Aussenraum. Sie bleiben ueber die echte Schiffsliste auswaehlbar und koennen wieder aussteigen; kein Loeschen/Neuerzeugen von Rosterpersonen.

### 3. Kartenaktionen und Menuegleichheit

- Einsteigen/Aussteigen, Trupp-/Pilotenzuweisung, Ausruesten und Charakterdetails verwenden denselben vorhandenen Operations-/Transportpfad und dieselben Busy-/Transit-/Kapazitaetspruefungen. Welt- und Menuebedienung muessen dieselben Resultate/Ablehnungen liefern.
- Ausruesten oeffnet die vorhandene Ausruestung fuer die angeklickte Person. Die passende Raumkonsole ist ein zusaetzlicher Zugang zu derselben Funktion, keine zweite Inventarverwaltung.
- Beide Startpersonen reisen als dieselben Personen mit. Vom Nutzer am 09.11. bestaetigt: Auch der Pilot darf nach der Landung aussteigen und am Bodenteam teilnehmen; fuer den Rueckflug muss eine echte, aktuell zugewiesene Person am Pilotenplatz sein; der Nutzer erlaubt ausdruecklich auch einen anderen NPC mit dessen eigenen Flugfaehigkeiten. Kein zusaetzlicher unsichtbarer Pilot als Ersatz. Bestehende Truppidentitaeten bleiben beim Ein-/Aussteigen erhalten.
- Kleine Arbeits-/Ruheaktionen werden tatsaechlich ausgefuehrt: Person laeuft zum reservierten Bett, legt sich erst dort hin, ist dort schlafend/belegt und kann aufgeweckt werden. Kein Teleport und keine sofortige Heilung. **Erste Fassung ohne neue Heilungs-/Muedigkeitsbalance:** bestehende Verletzungs-/Recovery-Regeln bleiben erhalten. Schlafzustand und Bettbelegung sind echt, aber keine erfundene Regeneration.
- Der Schlafzustand sperrt inkompatible Aktionen mit konkretem Grund. Aufwecken gibt nur den Schlaf-/Bettzustand frei und heilt keine Verletzung. Bettwahl, belegtes Bett, Abbruch und unterbrochener Lauf muessen sauber aufgeloest werden.

### 4. Speichern, Modi und Integration

- Kampagnen-Checkpoints erhalten Personenidentitaeten, vorhandene Trupp-/Pilotenzuordnung und Ausruestung sowie die neue Basisposition/Schlaf-/Bettzuordnung an sicheren Basis-Meilensteinen.
- Aeltere gueltige Spielstaende ohne neue Basisfelder bleiben ladbar und erhalten passende freie Startpositionen; keine neue Kampagne erzwingen und Skirmish-Profil nicht ueberschreiben.
- Die sichtbare Kartengroesse und die wiederhergestellten Originalmodelle erhalten. Satelliten-/Handelskarte und weitere Orte behalten ihre eigenen Karten. Multiplayer-Kampagne und neue Regeneration sind keine Bestandteile dieses Auftrags.
- Isolierter Zweig task/base-personnel-world-20261109; parallelen uncommitteten Orbit-Arbeitsstand in C:/dev/SternenBuergerchen nicht anfassen. Nur lokale Commits/Mainintegration, kein Push.

## Akzeptanz und Nachweise

1. Echte Mesh-/Durchgangspruefung und echte Simulationsbewegung durch jede sichtbare Eingangstuer zu den nutzbaren Bereichen; keine nur durch Kartenfelder behauptete Erreichbarkeit.
2. Kampagnenbasis registriert/zeigt genau die beiden Rosterpersonen, keine homebase_commander_avatar-Zusatzfigur. Identitaeten und Rollen bleiben nach Mission und Fortsetzen erhalten.
3. Dieselbe Person per Karte und Menue ausruesten, einschiffen und aussteigen lassen; gleiche Ownerresultate und keine doppelten Personen/Payloads. Pilot darf nach echter Landung mitgehen, Rueckflug ohne ihn wird konkret abgelehnt.
4. Bett aufsuchen/schlafen/aufwecken, Belegungskonflikt und Abbruch testen. Keine falsche Heilung oder geaenderter medizinischer Recovery-State.
5. Terminal nur am passenden erreichbaren Bedienpunkt aktiv; ein angeforderter Weg oeffnet genau einmal die passende vorhandene Ansicht. Abstand, Belegung und Ansichtwechsel pruefen.
6. Vorhandene Kampagnen- und Skirmish-Daten erhalten; alter Save migriert, neuer Basiszustand wird konsistent wiederhergestellt. Keine Vollscans/Komplett-Rebuilds pro Frame.
7. Alle Agentenpruefungen headless/private Profile/niedrige Prioritaet, keine sichtbaren Fenster oder Fokuswechsel. Neuer Testbuild zum Selbsttesten. Technische Geometrie-/Zustandsbelege getrennt von menschlichem Gestaltungsurteil ausweisen.

## Betroffene Bereiche und Risiken

ExplorableHomebase, Basiskarten/-Laufdaten, bestehende Operations-/Transportbruecken, SimulationRoot-gebundene Basis-Personenruntime, Kampagnen-Checkpoint, kontextuelle Hilfe und fokussierte Verifier. Knackpunkte sind feine Durchgaenge ohne Terrain-/FPSregression, Pilot als echte Bodenperson ohne zweiten Transportbesitz, Einzelpersonen-/Truppbindung, alte Spielstaende und Abgleich mit dem parallel entwickelten Orbitpfad.

Relevante Vertraege: homebase_operations_ux_contract, homebase_map_services_contract, homebase_direct_dropship_flow_contract, campaign_introduction_contract, graphics_reference_revision_contract sowie bestehende Roster-/Trupp-/Loadout-Vertraege.
