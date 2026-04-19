# TASK_081 – Meta-Layer: UI-Harmonisierung fuer FOB, Homebase und Loadout

## Ziel
Die Meta-UI soll in Homebase und FOB visuell und funktional konsistenter werden: kompaktere Header-Navigation, ein klarer Missionsbrief im FOB, ein stabiler Charakter-Overlay per Doppelklick, unverzerrte Drag-Karten, eine kompaktere Respawn-Stagingflaeche sowie ein Loadout-Bereich, in dem pro Fireteam-Mitglied Armor und zwei Waffen-Slots direkt an einer kompakten NPC-Karte gepflegt werden. Zusaetzlich soll die Dropship-Wartezone nicht nur Textstatus, sondern sichtbare Fireteam-Karten tragen. Auf der Homebase-Seite kommt ausserdem ein Flight-Deck-Fenster hinzu, in dem ein Flieger ausgewaehlt, ein Pilot hineingezogen und mit eigener Ankunftsprogression separat zur FOB geschickt werden kann; bestaetigte Teamtransfers sollen ebenfalls zuerst als laufender Anflug sichtbar sein und nicht mehr sofort zur FOB umschalten.

## Pflicht vor Beginn
- Lies `docs/PROJECT_BRIEF.md`
- Lies `docs/ARCHITECTURE.md`
- Lies `docs/CODEX_RULES.md`
- Lies `docs/IMPLEMENTATION_STATUS.md`
- Lies `docs/tasks/TASK_075_homebase_tooltips_charakterbogen_polish.md`
- Lies `docs/tasks/TASK_079_fob_fireteam_staging_ausbau.md`
- Lies `docs/tasks/TASK_080_meta_transfer_sichtbarkeit_und_sheet_toggle.md`
- Pruefe den Git-Status

## Abhaengigkeit
- TASK_080 muss implementiert sein.
- Die bestehende Homebase -> FOB -> Mission -> Debrief-Kette darf funktional erhalten bleiben.
- UI bleibt Darstellung; Gameplay- oder Inventar-Wahrheit wird nicht in Meta-Skripte verschoben.

## Ist-Zustand (nach TASK_080)
- Homebase und FOB besitzen bereits dichte Meta-Screens mit Header-Navigation und NPC-Karten.
- Der FOB-Screen enthaelt Fireteam-, Respawn-, Loadout- und Dropship-Staging, aber Header, Drag-Praesentation und Charaktereinsicht sind noch uneinheitlich.
- Der bisherige Loadout-Pfad mischt Team-Default-Steuerung und individuelle Slots; die Darstellung pro Mitglied ist noch nicht auf Kartenbasis vereinheitlicht.

## Aufgabe

### 1. Header und Missionsbrief harmonisieren
- Homebase- und FOB-Header sollen dieselben kompakten Nav-Button-Proportionen nutzen.
- Im Homebase-Header soll zusaetzlich ein kompaktes Missions-Dropdown sitzen, ueber das die aktive Meta-Mission und Map gewaehlt werden koennen, ohne die Header-Hoehe zu vergroessern.
- Der FOB soll einen klar lesbaren Mission-Brief-Header mit Missionsname, Map-Bezug und Slot-Anzeige erhalten.
- Der Start-Mission-Button soll als bewusster roter Primarakzent lesbar bleiben, ohne eine neue globale Button-Architektur einzufuehren.

### 2. FOB-Charaktereinsicht als Overlay ausbauen
- Doppelklick auf kompakte NPC-Karten im FOB soll einen grossen Charakter-Overlay oeffnen.
- Das Overlay soll Portrait, Rolle, Status, Skills, Traits, Loadout-Hinweis und Kurz-Bio anzeigen.
- Das Overlay soll explizit schliessbar sein und bei Fokuswechsel sauber nachziehen.

### 3. Loadout-Bereich pro Mitglied verdichten
- Der Team-Default-Armor-Block soll entfallen.
- Stattdessen soll jedes Fireteam-Mitglied im Loadout-Bereich ueber eine kompakte NPC-Karte mit Lead-Stern, Armor-Dropdown sowie zwei Waffen-Slots verfuegen.
- Lead-Umschaltung soll direkt an der Karte bleiben und nicht ueber eine separate Zusatzzeile erfolgen.

### 4. Drag-Darstellung stabilisieren
- Beim Ziehen von NPC-Karten darf sich die Kartengroesse nicht sprunghaft veraendern.
- Die Drag-Vorschau soll sich an der tatsaechlichen Kartengroesse orientieren statt an harten Breitenwerten.

### 5. Staging-Verortung sichtbarer machen
- Die FOB-Respawn-Flaeche soll kompakter werden, ohne den Header erneut aufzublaehen.
- Kompakte NPC-Karten im FOB sollen ihre aktuelle Verortung lesbar tragen, etwa Pool, Fireteam, Wait Zone, Boarding oder Respawn-Kontext.
- Die Dropship-Wartezone soll gedroppte bzw. aktive Fireteams als echte Karten im rechten Panel zeigen statt nur als Textliste.
- Dieselbe Fireteam-Karte soll in Loadout, FOB-Respawn und Dropship-Wartezone als dragbare Karte sichtbar sein und nicht nur ueber Text oder Fokuswechsel repraesentiert werden.
- Loadout, Respawn und Dropship sollen Fireteam-Karten nicht automatisch aus Fokus oder Fireteam-Mitgliedschaft anzeigen; die Sichtbarkeit dieser Karten entsteht erst durch explizites Drag-and-Drop.
- Der vorgesehene V1-Fluss ist: Fireteam in der Fireteam-Spalte erstellen oder befuellen, dann Fireteam-Karte in den Loadout-Bereich ziehen, und erst von dort in die Dropship-Wartezone weiterziehen.
- Fuer V1 soll es kleine Rueckwege ohne Gegendraht geben: ein explizites `Clear` fuer das Loadout-Staging und ein gezieltes Entfernen des fokussierten Fireteams aus der Dropship-Wartezone.
- Die eigentlichen Respawn-, Loadout- und Dropship-Fenster sollen selbst als Drop-Ziele dienen; kleine separate Drop-Felder oder Drop-Knoepfe sollen entfallen.

### 6. Homebase-Transport entkoppeln
- Die Homebase erhaelt rechts ein drittes Flight-Deck-Fenster, das zu Beginn leer startet; neue Shipcards entstehen erst ueber `Flieger im Dropdown waehlen -> + druecken`.
- Fliegerauswahl und zugewiesener Pilot sollen in diesem Fenster als klar zusammengehoeriger Block nebeneinander lesbar sein; ein duenner Rahmen fasst Ship, Pilot-Slot und Buttons visuell zusammen.
- Direkt am Flieger-Dropdown sitzt `+`, damit weitere Dropships oder Frachter gezielt aus dem aktuell gewaehlten Typ erzeugt werden koennen; das Entfernen erfolgt direkt in der jeweiligen Shipcard.
- In diesem Fenster soll ein Pilot per Drag-and-Drop zugewiesen werden koennen.
- Das Flight Deck soll pro Flieger eine eigene sichtbare `Shipcard` untereinander rendern; Dropdown-Auswahl und Shipcard-Stack bleiben dabei synchron.
- Ein zugewiesener Pilot muss aus einer Shipcard wieder herausdragbar sein, insbesondere zurueck ins Roster oder in eine andere Shipcard.
- Ein zugewiesener Pilot kann ueber `Send Ship to FOB` einzeln zur FOB geschickt werden; im Flight-Deck bleibt waehrenddessen ein Fortschrittsbalken bis zur Ankunft sichtbar.
- Zusaetzlich soll `craft_cargoB` als Frachter im selben Dropdown verfuegbar sein; weitere Frachterinstanzen koennen ueber denselben `+`/`-`-Pfad erzeugt werden.
- Fuer Frachter gibt es ein Cargo-Dropdown direkt in der Shipcard, zunaechst mindestens `Rover`.
- `Load` startet fuer die ausgewaehlte Frachterladung einen eigenen Fortschrittsbalken im Flight Deck; ein Frachter mit selektierter, aber noch nicht geladener Fracht darf noch nicht Richtung FOB starten.
- `Send to FOB` in der Homebase uebergibt das gestagte Team nicht mehr sofort an die FOB, sondern startet ebenfalls einen sichtbaren Anflug mit Fortschrittsbalken im Homebase-Transferfenster.
- Der `Send to FOB`-Button fuer das gestagte Team sitzt oben rechts direkt im Transferfenster und nicht mehr im globalen Mission-Brief der Homebase.
- Der bestaetigte Transfer darf die View nicht automatisch auf die FOB umschalten; die FOB wird erst bei Ankunft aktualisiert.

## Architekturhinweise
- Missionsname, Map und Slot-Kapazitaet sollen aus dem bestehenden `MetaLayerFlow` in den FOB-Screen gereicht werden.
- Charakter-Overlay und Loadout-Anzeige bleiben reine Meta-Read-/Write-Ansichten auf dem bestehenden FOB-State.
- Keine neue Persistenz, kein globaler Overlay-Manager und kein neues Inventarsystem.

## Nicht-Ziele
- keine echte Waffen-, Inventar- oder Gewichtssimulation
- keine neue Missionsplanungs- oder Kampagnenarchitektur
- keine Ausweitung des Meta-Layers zu einer persistierenden Datenquelle fuer Gameplay

## Akzeptanzkriterien
- Homebase und FOB zeigen dieselben kompakten Nav-Button-Proportionen im Header.
- Der Homebase-Header besitzt ein kompaktes Missions-Dropdown, das den aktiven Missions-/Map-Kontext umschaltet, ohne die Header-Zeile hoeher zu machen.
- Der FOB-Header zeigt Mission, Map und Slot-Bezug konsistent an.
- Doppelklick auf eine FOB-NPC-Karte oeffnet einen schliessbaren Charakter-Overlay.
- Im Loadout-Bereich werden pro Fireteam-Mitglied Armor, Slot 1 und Slot 2 direkt neben einer kompakten NPC-Karte bearbeitet.
- Lead-Stern sitzt in der NPC-Karte und bleibt sowohl im Fireteam als auch im Loadout sichtbar.
- Die Drag-Vorschau veraendert die Kartengroesse nicht mehr sichtbar.
- Der Start-Mission-Button bleibt rechts im FOB-Missionsbrief, ohne die aktuelle Header-Hoehe erneut zu vergroessern.
- Die rechte Dropship-Wartezone zeigt aktive Fireteams als sichtbare Karten.
- FOB-NPC-Karten zeigen eine knappe Verortung aus dem aktuellen Meta-State.
- Fireteam-Karten koennen zwischen Fireteam-Liste, Loadout, FOB-Respawn und Dropship-Wartezone gezogen werden; die Staging-Zonen zeigen dafuer eigene sichtbare Fireteam-Karten-Hosts.
- Loadout- und Dropship-Karten erscheinen nicht automatisch durch Fokus; sie erscheinen erst nach explizitem DnD.
- Die Dropship-Wartezone akzeptiert Fireteam-Karten in V1 nur aus dem Loadout-Staging.
- Das Loadout-Staging kann per kleinem `Clear` wieder geleert werden, ohne das Fireteam selbst aufzuloesen.
- Ein fokussiertes Fireteam kann gezielt wieder aus der Dropship-Wartezone entfernt werden.
- Respawn-, Loadout- und Dropship-Panel koennen direkt als Fensterflaechen fuer Fireteam-DnD genutzt werden; separate Drop-Felder sind entfernt.
- Ein Drag zwischen Respawn, Loadout und Dropship soll als Verschieben funktionieren: Das Fireteam bleibt nicht als Kopie im alten Fenster liegen.
- Fireteam-Karten in Respawn-, Loadout- und Dropship-Staging duerfen ihren Drag nicht mehr durch ein sofortiges Rebuild beim Mouse-Down verlieren; Fokuswechsel darf den Re-Drag nicht abbrechen.
- Die Fireteam-Liste links ist nur noch der Pool fuer nicht gestagte Teams. Sobald ein Fireteam in Loadout, Respawn oder Dropship liegt, verschwindet seine Karte aus dem Fireteams-Fenster, bis es wieder aus allen Ziel-Fenstern entfernt wurde.
- Das Fireteamfenster selbst ist jetzt wieder ein direktes Drop-Ziel. Ein Fireteam kann also aus Loadout, Respawn oder Dropship zurueck in den Pool gezogen werden und verschwindet dabei aus dem bisherigen Fenster.
- NPC-Karten und Charakterboegen zeigen jetzt den Meta-Ort konsistenter an: Homebase im Transferkontext, FOB im Pool/Loadout/Respawn sowie Rover fuer Wait-Zone, Boarding und bereits verladenen Zustand.
- Die Fireteam-Karte im Respawn-Fenster traegt jetzt dieselben mitgliedsbezogenen Armor-/Slot-1-/Slot-2-Dropdowns wie das Loadout, statt nur die nackte Teamkarte zu zeigen.
- Die Fireteam-Karten in der Dropship-Wait-Zone zeigen Portraits und Namen der Mitglieder sowie einen Boarding-Fortschrittsbalken, der mit dem aktiven Dropship-Zyklus startet.
- Boarding laeuft jetzt manuell statt automatisch an: Nach der automatischen Ankunft des Dropships wechselt die Wait-Zone in einen bereiten Zustand, und erst `Start Boarding` startet die eigentlichen Boarding-Timer.
- Das Boarding wird pro NPC statt pro Fireteam abgewickelt. Ein Fireteam gilt erst dann als voll geboardet, wenn jedes aktuell in der FOB vorhandene Mitglied seinen eigenen Boarding-Durchlauf abgeschlossen hat.
- Die Dropship Wait Zone zeigt das Dropship jetzt auch visuell: Im Anflug wird `craft_speederB` dargestellt, in der FOB `craft_speederB_SE`. Rechts oben sitzt dazu ein kleiner Ankunftsbalken fuer den Approaching-to-FOB-Zustand.
- Die kompakte NPC-Karte behaelt beim Ziehen ihre kompakte Geometrie und zieht nicht mehr auf Spalten- oder Loadout-Breite auf.
- Die Homebase zeigt rechts ein eigenes Flight-Deck-Fenster mit Fliegerauswahl, Pilot-Slot und aktiven Pilotfluegen; das Deck startet leer.
- Der Flight-Deck-Block zeigt Dropship und Pilot-Slot nebeneinander und gruppiert sie mit einem duennen Rahmen als gemeinsame Einheit.
- Ueber `Flieger waehlen -> +` koennen weitere Dropships oder Frachter in das leere Deck aufgenommen werden.
- Das Flight Deck rendert jetzt mehrere `Shipcards` untereinander; jede Karte zeigt Schiff, Pilot-Slot bzw. NPC-Karte und die kleinen `Send`-/`Clear`-/`-`-Buttons direkt rechts neben der NPC-Karte.
- Ein Pilot kann aus dem Homebase-Roster in den Flieger gezogen, dort einzeln zur FOB geschickt und ueber einen eigenen Fortschrittsbalken verfolgt werden.
- Piloten koennen aus einer Shipcard wieder per Drag herausgezogen und in eine andere Shipcard oder zurueck ins Roster gelegt werden.
- `craft_cargoB` ist als Frachter im Flight-Deck-Dropdown verfuegbar und kann wie andere Flieger vervielfaeltigt werden.
- Frachter besitzen ein Cargo-Dropdown direkt in ihrer Shipcard; mindestens `Rover` ist als V1-Cargo waehlbar.
- Ein Frachter zeigt fuer `Load` einen separaten Ladebalken in `Deck Activity`, und ein selektiertes Cargo muss erst geladen sein, bevor `Send` den Flug zur FOB startet.
- Ein bestaetigtes Homebase-Transferteam bleibt zunaechst als laufender Anflug in der Homebase sichtbar; erst nach Abschluss erscheint es in der FOB.
- Der Teamtransfer-CTA `Send to FOB` sitzt oben rechts direkt in der Kopfzeile des Transferfensters.
- Ein von der Homebase gestartetes Schiff erscheint waehrend des Transfers in Homebase und FOB gleichzeitig als ausgegraute Shipcard, damit der Handoff als gemeinsamer Meta-Zustand sichtbar bleibt.
- Nach der Ankunft in der FOB verschwindet die Shipcard aus der Homebase und bleibt nur noch in der FOB sichtbar.
- Ein angekommenes Dropship kann in der FOB direkt als sichtbare Shipcard verfolgt und als Fireteam-Drop-Ziel genutzt werden.
- Ein ankommender Frachter behaelt in der FOB seinen Cargo-Zustand als sichtbare Shipcard, damit z. B. ein Rover dort als eigener Meta-Zustand lesbar bleibt.
- `Send to FOB` wechselt nicht mehr automatisch von der Homebase in die FOB.

## Git-Schritte nach lokaler Pruefung
- `git status`
- `git add` nur relevante Dateien
- `git commit -m "Harmonize meta UI across FOB, homebase, and loadout (TASK_081)"`
- `git push`
- `docs/IMPLEMENTATION_STATUS.md` erst nach Umsetzung aktualisieren