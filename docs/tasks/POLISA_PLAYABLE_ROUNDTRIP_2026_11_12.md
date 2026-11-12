# Polisa: spielbarer Rundflug und Warenabholung

## Ziel und Ursache

Den vorhandenen Einzelspielerweg vom Heimatstart über Polisa und zurück zur
Heimat durchgehen und die konkret auftretenden Lücken beheben. Das Schiff soll
auf der Polisa-Karte vom Kartenrand zum Landepad fliegen, landen, Crew absetzen,
vor Ort tanken und Waren kaufen und wieder zur Basis zurückkehren können.
Gekaufte Ware soll nachvollziehbar ins Schiff gelangen; ein sichtbarer Aufzug
ist gewünscht und gesondert gegen den vorhandenen tatsächlichen Warenfluss zu
prüfen. Der separate Raumdock und Raumkampf bleiben zurückgestellt.

## Basis und Grenzen

Bewusste Basis ist der noch nicht auf main integrierte gemeinsame Stand
`8505698b7` aus dem parallelen Chat. PROJECT_BRIEF, ARCHITECTURE, CODEX_RULES,
IMPLEMENTATION_STATUS, `POLISA_STATION_2026_11_11.md`,
`POLISA_SERVICES_REMAINDER_2026_11_11.md` und die Reise-/Visitverträge gelten.
Keine fremden AP6-/AP7-Bodies überschreiben, keine V3-/Flagfreigabe ableiten,
keine neue EXE. Supply, Fleet, Flight und Visit bleiben die vorhandenen Owner.

## Akzeptanz und Vorgehen

1. Tatsächlichen produktiven Flag-off-Weg von Boarding und Heimatstart bis
   Polisa-Orbit, Anflug, tatsächlicher Kartenübernahme und Landepad prüfen.
2. Vorhandene Ausstiegs-, Tank-, Kauf-/Schiffsinventar- und Rückweg-Anbindung
   anhand echter Owner und des möglichst echten Flows prüfen; Zwischenstände
   und Fixtures klar benennen. Nur eng eingrenzbare Fehler ändern.
3. Im vorbereiteten lokalen Orbitweg löst der normale Polisa-Anflug den
   vorhandenen Karten-/Landepadablauf aus. Das separate Raumdock ist keine
   Voraussetzung; es bleibt als bestehender eigener Weg erhalten. Kein
   Oberflächenalias für die Station, kein zweiter Visit-/Flugowner.
4. Separat belegen, ob ein Frachtaufzug wirklich existiert oder Waren direkt
   eingebucht werden; sichtbaren Transport nicht als vorhanden behaupten.

## Betroffene Dateien / Prüfung / Risiken

Geplant sind Travel-/Fleet-/Adapter- und der bestehende räumliche Root-
Transaktionsanschluss. Einstiegskante: lokaler Orbit-Polisa-Anflug muss derzeit
durch die Oberflächeprüfung und wird deshalb abgelehnt; der strategische Weg
ist vorhanden. Der Supplykauf schreibt aktuell direkt in die Schiffsfracht;
eine sichtbare Aufzugsbewegung ist im Bestand nicht gefunden. Nicht als
vorhanden behaupten. Prüfung später zusammen mit dem parallelen Paket bündeln;
keine große Testmatrix.

Hookplan: Eine eigene vorbereitete Fleetoperation `begin_station_landing`
übernimmt den normalen Anflug auf `polisa` im lokalen Glut-2-Orbit. Root prüft
denselben Flight-/Index-/Rotten-/Claimzustand wie beim Dock, ohne Dockgate als
Landevoraussetzung. Der vorhandene Kartenflow fliegt anschließend das Landepad
an. Rückkehr und Abbruch reaktivieren den tatsächlich gehaltenen Flight mit
eigenem Stationsbeleg; keine Oberflächen- oder Dockoperation wird umgedeutet.
Ein sichtbarer Warenaufzug darf nur Kaufbelege/Schiffsinventar projizieren und
keine zweite Buchung oder weitere Cargo-Wahrheit einführen.

Arbeitsstand: Der lokale Polisa-Anflug besitzt separate vorbereitete Reise-
operationen; nach Anflugabbruch und Abflug wird die vorher gehaltene Orbitpose
erneut auf freien Footprint/Claims geprüft. Der existierende Kartenflow und
seine Padwahl bleiben zuständig. Im Polisa-Menü zeigt eine kurze Aufzugsgrafik
einen bereits bestätigten Kauf ins gewählte Schiffslager; sie ist eine reine
UI-Animation, kein physischer Lastenaufzug und verzögert die Supplybuchung
nicht. Funktion und Gestaltung sind noch nicht durch einen Test oder Playtest
belegt. Bestehendes Dock und Liveflag bleiben unverändert.
AP6-Arbeiten laufen parallel; Parentstand und spätere Integration abgleichen.
Ein headless Verlauf ist keine optische Freigabe oder Multiplayerabnahme.
