# TASK_1090 - Two-Player Station Route Decision Playtest

## Ziel / Problem
Die technischen Multiplayer-Gates fuer Ownership, ROE, Snapshot-Kompression und Reassembly sind gruen. Der alte sichtbare Station-Reentry-Host/Client-Decision-Review steht jedoch bei `0/15` manuellen Checks. Es ist nicht aktuell belegt, ob zwei reale Fenster den ersten taktischen Entschluss angenehm, getrennt und lesbar zeigen.

## Ursache / Sinnhaftigkeit
Alte TASK-611/TASK-791-Capture-Pakete starten zwei Fenster, wurden nach den aktuellen Station-Route-, CONTACT-FIRE- und Release-Aenderungen aber nicht erneut sichtbar abgenommen. Headless-Tests beweisen Autoritaet, nicht Fensterlayout, Rollenlesbarkeit oder den Spielergriff am ersten Kontakt.

## Umfang
- Zwei echte Godot-4.6.2-Fenster mit Station-Route-Szenario starten und erfassen.
- Host `P1 ALPHA` und Client `P2 BRAVO` sichtbar unterscheiden.
- Deployment-/Missionsansicht, erster Kontakt und Decision-Card auf beiden Fenstern pruefen.
- Bestehende Befehle und GO bleiben der einzige Commit-Pfad; keine automatische Spielerentscheidung.
- Den groessten belegten Bedien-, Lesbarkeits- oder Multiplayer-Befund klein beheben.

## Nicht-Ziele
- Kein Matchmaking, persistentes PvP oder neuer Netzwerk-Transport.
- Keine zweite Mission-, Fireteam- oder Combat-Wahrheit in Capture-/UI-Code.
- Kein kompletter HUD-Umbau ohne sichtbaren Befund.

## Akzeptanzkriterien
- Host- und Client-Fenster werden aus demselben aktuellen Projektstand gestartet.
- Beide Fenster zeigen getrennten Peer-/Team-Kontext und das Station-Route-Szenario.
- Decision-/Command-Flächen sind sichtbar und blockieren die Karte nicht unbrauchbar.
- Ein Wrong-Owner-/Wrong-Team-Pfad bleibt serverseitig blockiert und sichtbar begruendet.
- Erlaubte eigene Fireteam-Befehle laufen ueber Host-Autoritaet; Client setzt keine Gameplay-Wahrheit direkt.
- Screenshots/Manifest und automatischer Verifier dokumentieren den aktuellen Befund.
- TASK_1083 und TASK_1082 bleiben gruen.

## Betroffene Dateien
- vorhandene Station-Route-/Host-Client-Capture- und Mission-UI-Pfade nur bei belegtem Befund
- `scripts/tests/task_1090_two_player_station_route_decision_playtest.gd`
- Status-, Roadmap- und HTML-Berichtsdokumentation

## Lokale Pruefung
- aktueller Zwei-Fenster-Launch/Capture mit Godot 4.6.2
- TASK_1090 Red/Green
- TASK_1083, TASK_1082 und betroffene Station-Route-Verifier
- HTML-Inline-JavaScript und `git diff --check`
- finaler Godot-4.6.2-Release/Provenance-Startcheck bei Codeaenderung

## Risiken / offene Punkte
Ein Screenshot kann Bedienbarkeit nur teilweise beweisen. Technische Ownership-/Replication-Evidence und sichtbarer Fensterbefund werden deshalb gemeinsam bewertet. Alte `manual_review_done=false`-Manifeste gelten nicht als aktueller Fehlerbeweis.

## Ergebnis
- Godot 4.6.2 zeigt Host `P1 ALPHA` und Client `P2 BRAVO` gleichzeitig mit derselben Station-Route-Karte.
- Beide Fenster listen nur die lokal kommandierbaren Fireteams und initialisieren einmalig eine lesbare Auswahl samt Mitgliedern.
- Die lokale Team-Perspektive kommt zuerst aus echter Peer-Zuordnung, im Review-Harness ersatzweise aus `--team`; ein `OfflineMultiplayerPeer` gilt nicht als verbundene Session.
- `MissionSetup.team_id` bleibt autoritativer Szenario-Bootstrap. `fog_viewer_team_id` trennt davon die lokale Wahrnehmung, damit der Client Bravo-Sicht lesen kann, ohne Spawns oder Registries umzudeuten.
- Szenario-Bravo-Gruppen behalten ihre `group_id` als Fireteam-ID und sind damit nicht mehr unzugeordnet.
- Der vermeintliche Karten-Blackout war kein Gameplay-/FoW-Fehler, sondern ein durch liegengebliebene Diagnoseprozesse ueberlasteter Capture. Nach Prozessbereinigung zeigen beide Fenster die Karte vollstaendig.
- Der Zwei-Fenster-Helfer startet weiterhin zwei unabhaengige Sichtinstanzen. Echte ENet-Autoritaet und Wrong-Owner-Reject bleiben separat durch TASK_1082/1083 belegt; ein voll verbundener Station-Route-Durchlauf ist Folgearbeit.

## Lokales Ergebnis
- TASK_1090: 16/16
- TASK_714: 37/37
- TASK_712: 62/62
- TASK_1082: 21/21
- TASK_1083: 24/24
- sichtbarer 4.6.2-Zwei-Fenster-Capture: Host- und Client-Karte, Team-Badges, Fireteam-Mini-Cards und Member-Auswahl lesbar
