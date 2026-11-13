# Enger Navigationsabschluss 13./14.11.2026

## Technischer Stand
- `final_occupied_goal/7171d550f13740929aec93e98579adbf`: 47/0, echter stationaerer Zielblocker, Tokenerhalt, Export/Prepare/Publish-Restore und Ankunft nach Freigabe.
- `final_formation_occupied/61dcc0177dd64dc1a20e0778a3cc85f7`: 58/0, freie Mitgliedsziele erhalten; finale Spacing-Ausgabe wird vor echter Root-Commandausgabe gegen Belegung repariert. Echte TAKE-Stufe mit haltendem eigenen Covermitglied prueft unterschiedliche Ziel-/Haltehexfelder und reale Ankunft ohne Verschiebung der Deckungsperson. Mitbewegte Mitglieder werden nur bei stufeneigener Bewegungsrolle und bereits vorhandenem wegfuehrendem Groundcommitment ausgenommen.
- `final_backoff_ship/1e90240915c34435b2b556cc7d52da4b`: 33/0, echte Recovery, danach extern blockiertes Ziel, Abort, alternative legale Backoffwahl und zwei echte Originalzielankuenfte.
Alle drei ohne Enginefehler; Source-, Originalprofil- und private Canaryguards gruen.

## Echte Kampagnenfolge bleibt offen
Der unveraenderte Benit-Checkpoint SHA256 `354a4a9f6841b51a8d906878c2b263e6cbb55136cbd9939dfdac7ca038c5e789` besitzt drei echte abgeschlossene Heimkehren. Kein weiterer Lauf hat bisher die zwei verbleibenden erfolgreichen Heimkehren bewiesen.

- `223d04c7a98e4c2098b61f0977206e08`: 51/1, 334s. Alle drei Actors verlassen den Schiffsstart legal; Gegner besiegt, Chip normal benutzt und echter Rueckmarsch/ship_return-Use abgeschlossen. Pilot war im Gefecht terminal ausgefallen. Bestehender Owner verarbeitet `pilot_unavailable` als echte Niederlage/fehlgeschlagene Extraction; kein Geisterflug und kein neuer Homecheckpoint. Der gemeldete Orbitwait-Timeout darf nicht als verbleibender Navfehler interpretiert werden. Private Home-Datei bleibt bytegleich Benit; keine spaetere aktive Wiederaufnahme vorhanden.
- `f50ba33c20934a75a4352b6e0076bbbc`: 45/1, 251s. Normaler Root-Move des Piloten zum echten Schiffsaccess, regulaeres pilot-only Boarding und Flightguard bestanden. Zwei Bodenkraefte erreichen ueber normalen GO einen Sammelpunkt und danach das Gefechtsgebiet. Rekrut faellt im folgenden Kampf aus, ein Gegner bleibt fit. Keine weiteren Heimkehren. Alle Engine-/Profilguards gruen.

Diese beiden Laeufe veraendern keine Gesundheit, Gegner oder Spielerprofile. Die unveraenderten Homepersonen besitzen nur Pistolen. Die beiden obigen Fehlversuche verwendeten MOVE/RUSH fuer den Feindanmarsch; der vorhandene eigentliche TAKE/ENGAGE-Befehl (`MissionTacticalSandboxController.issue_take`) nutzt ENGAGE/aimed statt der abgesenkten Move-Waffenhaltung. Ein erfolgreicher taktischer Kampagnennachweis oder eine normale bessere Basisausruestung ist deshalb ein eigener noch offener Nachweisschritt, kein weiterer belegter Navigationsdefekt.

## Verworfen / Diagnose
- `0c52e14ff92c4121b2c8c653ddd6306a`: neuer Proximitywait forderte unnoetig auch jeden urspruenglichen Actor; echte Vitals/Boarding muessen beruecksichtigt werden. Kein Erfolg.
- `67e5b87487914781b6e22cbddc4bdfde`: kontrollierter Abbruch nach nachgewiesenem nachtraeglich belegtem Spacingziel; kein Erfolg.
- `4f06934a29c3484fa85bab8518169e18`: kontrollierter Abbruch nach eindeutigem Schiffs-Recoveryziel in der Hullmaske; durch obige enge Regression korrigiert. Kein Erfolg.
- Alter FullFive `efdc89a07ad74ee28e39083c271a3cb0` bleibt 198/1. Keine Umdeklaration in einen bestandenen Fuenferlauf.

## Letzter TAKE-Versuch und Ende der Wiederholungen
`2b4308910050444a848b7c233ae57614` verwendete regulaeres Pilotboarding, Sammeln und das vorhandene TAKE/ENGAGE-Menue. Der lesende Trace belegt einen eigenen haltenden Coveractor auf109,30, waehrend das bewegte Mitglied denselben Zielhex erhielt und wartete. Nach diesem eindeutigen Befund kontrolliert beendet; kein bestandener Kampagnenlauf. Dieser enge Produktfehler ist durch obiges58/0-Gate korrigiert: haltende eigene Personen bleiben Blocker. Identische bereits belegte Anker werden nicht nochmals als harte externe Zielausschluesse uebergeben, damit der bestehende Root-Nachbarplaner suchen kann. Keine Unit wird versetzt. Danach wurden auf ausdrueckliche Koordination keine weiteren Kampagnenversuche durchgefuehrt. Der erfolgreiche vollstaendige Fuenfernachweis bleibt offen.

Finale enge Testquelle: Snapshot `100b0976aebc4b589d7064879b830eed` (2886 Dateien, capturegleich). Produktintegration/Commit/Main/Website erfolgen ausschliesslich durch Root.
