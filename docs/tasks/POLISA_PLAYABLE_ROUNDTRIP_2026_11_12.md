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
seine Padwahl bleiben zuständig. Neben der kurzen Aufzugsgrafik im Menü wurde
inzwischen der unten beschriebene 3D-Aufzug ergänzt. Beide stellen einen bereits
bestätigten Kauf dar und verzögern die Supplybuchung nicht. Funktion und
Gestaltung sind noch nicht durch einen Playtest belegt. Bestehendes Dock und
Liveflag bleiben unverändert.

## Physischer Aufzug: kleiner Umsetzungsschnitt

Die gewünschte Darstellung ist eine sichtbare Plattform mit Frachtkiste am
gelandeten Schiff, die aus dem Deck hochfährt und die Kiste zum Schiff bringt.
Die Nutzerfreigabe von Polisa R08 bleibt gestalterische Referenz; native
Bestandsansicht `docs/qa/polisa_r08_20261111/polisa_r08_station_near.png`,
SHA-256 `9e0cbc6ea76624f9f3d414ae69aaf5660db276b41b7c22aa83bbcfed449044a7`.
Eigenes Ziel: kleine kantige dunkelgraue Plattform, gelb markierte Kiste und
türkise Statusleuchten, passend zu Pad und Stationspalette. Die Geometrie wird
als editierbares Godot-Skript erzeugt, ohne neues Fremdmodell oder Kollision.

Nur ein erfolgreicher Supply-Kaufbeleg für das tatsächlich ausgewählte und
geparkte Polisa-Schiff startet die temporäre 3D-Projektion an der vom
TacticalController gelesenen Schiffsposition. Supply hat die Ware bereits
einmalig gebucht; die Animation erzeugt keine Fracht, keine Reservierung und
keine zweite Buchung und bleibt bei Replay aus. Fehlende Ansicht/Position darf
den bestätigten Kauf nicht rückgängig machen. Mehrere Käufe dürfen keine
unbegrenzte Zahl an Visualknoten erzeugen. Bestehende R08-Geometrie und
Kollisions-/Navigationsdaten bleiben erhalten. Native Sichtprüfung und
gemeinsamer Spielweg folgen gebündelt; bis dahin keine optische Abnahme.
Der Kandidat ergänzt auf jedem R08-Pad eine flache Luke ohne neue Kollision.
Bei bestätigtem Kauf fährt eine 3D-Plattform mit Kiste hoch und zum Schiff;
ein weiterer Kauf startet denselben pro Schiff begrenzten Effekt neu. Die Ware
ist bereits durch Supply gebucht; die sichtbare Bewegung ist keine verzögerte
Warenbuchung oder Physiksimulation. Ein nativer Vorher-/Nachhervergleich und
die tatsächliche Sichtprüfung stehen noch aus.
AP6-Arbeiten laufen parallel; Parentstand und spätere Integration abgleichen.
Ein headless Verlauf ist keine optische Freigabe oder Multiplayerabnahme.

## Gebündelte lokale Prüfung vom 12.11.

Nach Erzeugung des Godot-Klassenindexes liefen mit isoliertem APPDATA
`polisa_cargo_lift_check.gd` und `polisa_landing_owner_cycle_verifier.gd`
jeweils mit Exit 0. Ersterer prüft den echten Supply-Kaufbeleg,
Wiederholungsschutz und die Lebensdauer der 3D-Animation. Letzterer prüft mit
Fixture-Pilot und Fixture-Flow den lokalen Anflug ohne Dockpflicht, Abbruch,
erneuten Anflug, Freigabe, erhaltene Rückkehrposition, Warp und Heimlandung.
Er simuliert weder die tatsächliche Landepadkarte noch Einkauf, Aussteigen
oder Boarding. Ein erster Lauf ohne Klassenindex hatte Autoloadfehler und ist
kein gültiger Nachweis. Eine native Sichtprüfung und der zusammenhängende
Produktionsdurchlauf blieben zu diesem Zeitpunkt offen; das Liveflag ist weiterhin ausgeschaltet.

## Fortsetzung: tatsächlicher Kampagnenweg

Arbeitsbasis ist der noch nicht auf main integrierte Parallelstand `62a14dd76`.
Der echte Polisa-Durchlauf zeigte zwei Fehler: Die Transportprojektion verlor
die tatsächlich vorhandene Modell-ID vor der Missionskarte, und der primäre
Abflug löschte die Crewbindung vor dem synchronen Return-Callback. Der Flow
reicht nun vorhandene Identitätsfelder aus der Fleetdefinition durch. Der
Controller hält beim Abschluss die tatsächliche Sequenzbindung für den
Return-Callback kurz im vorhandenen sequenzgebundenen Index und entfernt sie
nur, wenn noch exakt dieselbe Bindung dort liegt. Guards und Owner bleiben
unverändert; fehlende Modellidentität wird nicht erraten.

Der Flag-off-Kampagnendurchlauf `polisa_real_roundtrip_verifier.gd` prüft mit
echter Szene, Crew und Supply den Flug nach Polisa, Padwahl, Landung, Ausstieg,
Kauf, 3D-Aufzugsknoten, Boarding, Abflug, Quantum und Heimatlandung samt Ware.
Der Heimat-Boardingweg wird dabei mit dem vorhandenen Debug-Takt beschleunigt.
Der Durchlauf ist headless: Er belegt keine visuelle oder manuelle Bedienabnahme
und keine Freigabe des weiterhin ausgeschalteten lokalen Orbitpfads. Die
Aufzugbewegung stellt die bereits gebuchte Ware dar, keine physikalische oder
verzögerte Übergabe. Der abschließende Lauf mit allen Crewmitgliedern und dem
echten Tankvorgang endete 25/25, Exit 0. Ergänzend: Boarding-/Retirementfixture
37/37, Tankservice 11/11 sowie lokaler Landungs-Owner und Aufzug jeweils Exit 0.
Nötig bleibt die gemeinsame Integration und deren Prüfung auf dem fortgeschriebenen
Parallelstand.
