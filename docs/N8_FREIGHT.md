# N8 · Automatische NPC-Verladung

Stand 21.09.2026, lokaler Arbeitsstand. Keine vollständige N8-Grafikfreigabe und noch kein neues Windows-Paket.

## Bedienung und reale Warenbewegung
- Kauf reserviert und bezahlt Händlerware. Eine physische Kiste am Händler ersetzt die direkte Gutschrift im Schiff.
- Verkauf stellt Ware am Schiffszugang bereit. Credits und Händlerbestand steigen erst nach der Anlieferung.
- `transfer` zwischen Basislager und Schiff erzeugt ebenfalls eine Kiste und einen Ladeauftrag. Menge/Drag-and-drop bleiben erhalten; frei verfügbare NPCs laufen automatisch.
- Gesunde freie Figuren übernehmen offene Aufträge; an Bord befindliche freie Figuren steigen hierfür automatisch aus. Gebundene Arbeiter und Bodenkämpfer bleiben in ihrer Aufgabe. Eine Figur trägt zunächst eine Einheit pro Weg; mehrere Aufträge können beide Figuren beschäftigen.
- Jede Aufnahme und Ablage braucht eine Spielsekunde, dazwischen gelten echte Navigation und Rampen. Fertige Aufträge geben die Crew frei. Boarding nach der Arbeit bleibt ausdrücklich steuerbar.
- `cancel_hauling` stoppt die Teamaufträge. Bereitgestellte Ware bleibt an der Quelle, getragene Ware wird als Kiste neben der Figur abgelegt. Keine magische Rückbuchung.
- Verwundung/PvP benutzt denselben Ablegepfad. `pickup_freight {crate_id,unit_id}` schickt die ausgewählte Person zur Kiste und danach zum Schiff. Links- und Rechtsklick funktionieren. Erst die tatsächliche Ankunft entnimmt Ware: zwei Teams können zur gleichen Kiste laufen, aber keine Einheiten duplizieren.
- Start, Reise und Mietschiffswechsel sind während offener Aufträge gesperrt. Pause stoppt alle Bewegungen/Übergaben. Händler-Nachschub läuft weiterhin einmal auf der autoritativen Simulationszeit.

## Zustandsvertrag
`cargo_hauling.gd` mutiert ausschließlich innerhalb von SimulationRoot. `hauling.jobs` enthält Auftrag, Quelle, verbleibende Menge, gehaltene Einheit, Träger, Ablageziel, Phase und Verkaufspreis. `freight_world` enthält einen stabilen Zähler und die physisch vorhandenen Kisten. Im Teamspiel teilen beide Kerne genau dieselbe Frachtwelt; die eigene Basis bleibt über `base:<team>` getrennt.

Bestehende gültige Saves ohne neue Felder erhalten einen leeren Frachtzustand nach Validierung. Aktuelle Felder müssen gemeinsam gültig sein. Team-Saves prüfen übereinstimmende Frachtwelten und Teamzuordnung. Angefangene Transporte, lose Kisten und Verkaufspreise bleiben erhalten. Geld und Ware werden nicht von UI oder Netzwerkclient berechnet.

## Prüfung
- `haul_flow_test`: Kauf ohne Teleport, automatische Crew, Pause, Lieferung, Speichern, Verkauf erst bei Anlieferung.
- `haul_raid_test`: echter Bodenangriff auf Träger, Fallkiste, Übernahme durch Gegenteam, identische Anfragebelege und Save vor/nach Überfall.
- `haul_guards_test`: Abbruch vor und während Transport, Startblockade, konkurrierende Aufnahme und atomare Ablehnung beschädigter Aufträge.
- `haul_window_test`: reales Godot-Fenster, Marktknopf, sichtbare Tragelast, Abbruch, Raycast auf Fallkiste und echter Rechtsklick über InputEvent.
- `haul_network_run.py`: zwei echte Produktprozesse, ENet sowie authentifizierte WebSockets; Gastkauf, sichtbarer Träger, Ablegen, Übernahme zum gegnerischen Schiff, beide Projektionen und gemeinsamer Save. Evidenz: Temp `sternen-haul-network-x7hgpbuk` / `sternen-haul-network-pkhltf5k`.
- 16-Prozess-Regressionsläufe: ENet `sternen-team16-069fbb9eacf44c1792569da73c3a25b8`, WebSocket `sternen-team16-67418c8241d84ffb9ecfe24a6455b1fa`.
- Weitere gezielte Kernregressionen grün, darunter Welt 320, Navigation 173, Crew-Migration 67, Crew-Reise 57, Grundspielweg 89, Boden 149, Orbit 79, Flug/Fracht 39, Energie 34 und Teamzustände. Ältere Testreisen warten jetzt ausdrücklich auf reale Lieferung; die neuen Frachtprüfungen beobachten zusätzlich die Zwischenzustände.

## Grenzen
- Gilt für Handel und Basislager/Schiffstransfers. Die bestehenden Mining-/Bergungs-Ausgabepfade werden in diesem Schritt nicht in eine vollständige Feldlogistikkette umgebaut.
- Die persönliche Missions-Blackbox wird ebenfalls getragen und kann fallen; gegnerische Crews können sie noch nicht übernehmen, weil die Auftragsidentität bislang an eine Karriere gebunden ist. Handelswaren sind nicht geschützt.
- Keine Schiffsenterung, Frachtraum-Innenkarte, Gabelstapler oder allgemeine zivile Hafen-KI. Kisten blockieren keine Nav-Wege; sichtbare Kisten sind anklickbare Bestände.
- Zwei lokale Prozesse über Netzwerk sind kein Test zwischen unabhängigen Heimanschlüssen. Der grafische N8-Referenzabgleich und ein neues auslieferbares Paket bleiben separat offen.
