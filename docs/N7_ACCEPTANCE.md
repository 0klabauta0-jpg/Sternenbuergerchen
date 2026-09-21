# N7 · geprüfter Zwischenstand · 21.09.2026

## Geliefert
- Team-Modus: 2 Teams mit je bis zu 8 Menschen, Host mitgerechnet. Gemeinsame Crew-/Schiffsbefehle im Team, private Wirtschaft, autoritative Gegnerprüfung. Host verwaltet Lobby, Zuweisung und Heimatwelten. Offene Lobby friert den Zustand ein. Boden-PvP mit Ausrüstung, Schaden und Respawn; noch kein Schiff-PvP.
- Vier Heimatplaneten mit separaten persistenten Fundstellen/NPCs und geteilten Beständen bei Begegnung. Momentan gleiche Layouts, verschiedene Paletten. Erste KI nur für regelgebundene Basisarbeit.
- Bunker als persistenter Einsatz mit pro Person gespeicherter Ebene. Aufzug bewegt Auswahl. Lokale Ansicht und Kameraausschnitt getrennt von der Simulation; beide Ebenen ticken.
- Graphischer Forschungsbaum; Material-/Medizinforschung und Legierungsrezept durch den echten Werkbank-Arbeitsablauf. Kein eigener Forschungsraum.
- Sieben originale Blender-Requisiten, möblierte Basis, dichtere Depotgruppen, Felsstufen, Zielvorschauen, Planetentexturen und Dossierkomposition. Die Referenzdetaildichte ist noch nicht erreicht.

## Autorität und Speicherung
TeamCampaign kapselt zwei SimulationRoot-Instanzen. Sender wird anhand der authentifizierten Peer-ID genau einem Team zugeordnet. Netzwerk verteilt pro Peer nur die erlaubte Projektion. TeamRoster besitzt Mitgliedschaft; TeamCombat prüft Ort, Ebene, Reichweite und Sichtlinie. Vier Weltbestände werden von ko-lokalen Teams geteilt. Team-Saveformat v2 enthält beide validierten Kernpayloads (Schema5), Weltbestände, Entdeckung, Kampf und Host-Team; Gäste verbinden sich neu. Bei geladener Partie ohne Gegner wird die Lobby geöffnet. Solo-Saves bleiben getrennt erhalten.

## Nachweise
- 16 echte Produktprozesse: ENet und authentifizierte WebSockets, je 8 Spieler/Team. Letzter ENet: sternen-team16-6f6ee7b3d4b8496ebaf6289f9f42a122; WebSocket: sternen-team16-142afc4bfe7a465081161519b1f1a830 (lokale Temp-Evidenz).
- Öffentlicher WSS-Tunnel: 73 Prüfungen, zwei Prozesse auf einem Rechner. Kein Zwei-Haushalte-Nachweis. Evidenz sternen-internet-14360503483c4417ad3cb068cf8be85a.
- Teamkampagne21, Weltintegrität21, PvP-Spielweg9, isolierter Kampf10, TeamRoster26, Forschung9, Bunkerebenen10: bestanden.
- Kern104, Boden147, Navigation162, Welterweiterung164, Reise57, Migration67: bestanden.
- Native Produktstrecke76, Dossier22, Referenz-UX9, Bunkerebenen-Fenster9: bestanden.
- Vier Befunde der unabhängigen Schlussprüfung (Planetenwiederverwendung, getrennte Gegnerbestände am selben Ort, verlorenes Host-Team nach Laden, offene Lobby fortsetzbar) reproduziert und regressionsgesichert korrigiert.
- Echte native Aufnahmen und direkter Referenzvergleich in output/N7_REFERENZABGLEICH.html. Szenenaufnahmen verwenden kontrollierte Kameras/Testzustände und sind getrennt von Ablaufnachweisen.

## Offen
Referenzniveau der Landschaft und Architektur; eigenständige Layouts neuer Planeten; Schiff-PvP; selbständig reisende/angreifende KI; Rekrutierung, Basisbau und Forschungsraum; Schiffsinnenräume; Langzeit-/Mehrhaushalttests. Keine vollständige Abnahme der ursprünglichen Spielvision.

## Windows-Paket
Eigenständiger Export 0.7.0; eingebettetes Paket außerhalb des Projektordners mit 29 Prüfungen bestanden (Menü, Spiel, Modelle und Ressourcen). Prüfskript lief im Godot-Runner gegen den exportierten EXE-Datenpack, nicht als Skript in der Release-EXE. N6 unverändert erhalten.
