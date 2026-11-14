# Personalinventar — Playtest 10.11.2026

## Besitzer und Zugriff

SimulationRoot bestaetigt Supply-Commands. SingleplayerSupplyState besitzt endliche
Bestandscontainer. `PersonnelLoadoutState` am selben SimulationRoot besitzt die
angelegte Personenausruestung. Ein Ausruestungstausch liest dessen aktuellen Slot
und bestaetigt Bestand und neuen Slot synchron vor dem Committed-Signal.
Replays liefern ihren Beleg, ohne ein inzwischen neueres Loadout zurueckzusetzen.
UI zeichnet kopierte Snapshots und sendet Requests, ohne eigene Bestaende oder
eine zweite Loadout-Wahrheit zu fuehren. Alte Homebase-Getter/-Setter delegieren
an denselben Owner; Fireteam-Loadouts sind Exportprojektionen. Die eigenstaendige
Homebase bindet ihn zunaechst an einen lokalen SimulationRoot; der Kampagnenroot
uebernimmt genau denselben Owner, einschliesslich frueh restaurierter Daten.
Unzugewiesene Piloten behalten ihre Ausruestung auch bei versteckten Ansichten.
Das Checkpointfeld `craft.member_loadouts` und das Format bleiben unveraendert.

IDs: `base:homebase`, `craft:<craft_id>`, `unit:<unit_id>:backpack`.
Basislager fasst 200, Schiff 48, Rucksack 12 Gegenstandseinheiten. Das sind
vorlaeufige Mengenlimits, keine Gewichtsbehauptung. Neue Kampagnen erhalten je
zwei leichte/mittlere/schwere Ruestungen, zwei SMGs, zwei Gewehre und ein Medictool im Lager.
Angelegte Startausruestung wird nicht zusaetzlich als Lagerbestand verbucht.
Heimatlager und dessen bisheriger Item-Snapshot benutzen dasselbe Dictionary. Kaeufe am Handel werden in die Fracht des tatsaechlich dort geparkten Schiffs geliefert; ein voller Frachtraum lehnt vor Zahlung ab. Alte Spielstaende
ohne Container bleiben ladbar; ihre vorhandenen Kaufmengen bleiben erhalten.

Zugriff setzt ein vertrauenswuerdiges, vom Adapter ermitteltes Zugriffsset voraus.
In der ersten Fassung sind Transfers nur bei ruhender, verfuegbarer Person an
der Heimatbasis und dort geparktem Schiff erlaubt. Kein Zugriff auf entfernte
Schiffe oder fremde Personen. Schlafen, Bewegung und Boarding sperren Zugriff.
Basisvorbereitung gilt als Lagerzugriff; ein physischer Gang zu jeder Kiste ist
kein Bestandteil dieses Pakets. Ortsinventare werden spaeter gesondert angebunden.

## Transaktion

`inventory_transfer` enthaelt Item-ID, positive ganze Menge, Quelle und Ziel.
`inventory_equip` enthaelt Person, Quellcontainer, Slot und Item-ID. Armor-Items
heissen `armor_light`, `armor_medium`, `armor_heavy`; Waffen behalten bestehende
IDs. Primaer/Sekundaer akzeptieren Waffen, Armor nur Ruestungen. `none` ist kein
Gegenstand; Ablegen einer Sekundaerwaffe benoetigt einen freien Rueckgabeplatz.
Helm/Aufsatz haben noch keinen eigenen Wirkungsowner und bleiben als zukuenftige
Slots gekennzeichnet. Medictool benutzt den bestehenden Waffentyp.

Vor jeder Mutation: bekannte IDs, Zugriff, Bestand, Kapazitaet und Kompatibilitaet
pruefen. Beim Tausch wird das bisher angelegte Item atomar in die Quelle gelegt.
Kein Erfolg darf einen Gegenstand erzeugen oder verlieren. Dieselbe Request-ID
liefert denselben Beleg; anderer Inhalt mit derselben ID wird abgelehnt.
Bestandscontainer und Belege werden im bestehenden Supply-Checkpoint gespeichert;
das Personal-Loadout im bestehenden Personalcheckpoint. Beide gehoeren zu dessen
gemeinsamem sicheren Basissnapshot. Mehrort-Saves bleiben nach Ortsvertrag gesperrt,
solange kein vollstaendiger Weltcheckpoint existiert.

## Darstellung und Pruefung

Referenzen: `inventory_drag.png` und `inventory_grid.png` im Playtest-Assetordner.
Echte Personenportraits und IDs bleiben. Ein gemeinsames Panel fuer Personal und
Trupp zeigt Slots sowie Basislager, Schiff und Rucksack mit Mengen/Kapazitaeten.
Drag-and-drop und klickbare Transfer-/Anlegenbuttons senden dieselben Commands.
Abgelehnte Aktionen zeigen den Grund. Keine unendliche kostenlose Gegenstandspalette
im Kampagneninventar.

Verifier prueft Erhaltung, falschen Slot, vollen Container, unberechtigten Zugriff,
ungueltige Menge/Item-ID, Replay/Konflikt und Export/Restore ohne Duplikation.

## Playtest-Revision: Details und Weltwahl — 10.11.2026
Doppelklick auf NPC-Karten und echte Basis-NPCs öffnet dasselbe Charakterblatt. Links sind Eigenschaften/Kernwerte und Herleitungen mit einzelnen Faktoren untereinander, rechts liest das bestehende Inventarpanel den endlichen Supply-/Loadoutbestand derselben Person. Kompakte Lesedarstellung verwendet mindestens15px-Schrift. Wechselnde Person oder Zugriffsgrenze verwirft nur UI-Gegenstandsauswahl; Commands und Ablehnungsgründe bleiben beim vorhandenen Owner. Linksklick auf ein Basisschiff wählt seine Detailansicht und löst kein Boarding aus. Leerer Linksklick wählt ab. Das schwebende Servicepanel erscheint im Basismodus nur für ein ausgewähltes Schiff; die explizite Serviceseite besitzt weiterhin ihre eigene Schiffs-Auswahl.

## Lokaler Handels-Frachtaufzug — 14.11.2026

`station:trade_outpost:lift` ist ein endlicher, persistenter 256-Einheiten-
Container im bestehenden Supply-State, analog zum Polisa-Aufzug. Kauf liefert
am freigegebenen Handelsservice in diesen Container. Der vorhandene
AutomaticCargoTransfer transportiert in beiden Richtungen zwischen lokalem
Schiff und Aufzug. Jeder Schritt prueft Ort/Pad/Zugriff erneut und bucht ueber
bestehende Inventory-Commands; Abbruch erfindet keine Waren und rollt bereits
transportierte Ware nicht still zurueck. Verkauf darf ausdruecklich aus dem
lokalen Liftbestand oder dem lokalen Schiff erfolgen. Fremde/entfernte Lifte
und Schiffe werden abgelehnt. Alte Staende erhalten beim Configure den leeren
neuen Container; vorhandene Mengen werden nicht umgeschrieben.

Die feste Aufzugsdarstellung und Buttonbeschriftungen lesen Menge/Transferphase
vom Supply-/Frachtowner. Sie besitzen keine zweite Inventar- oder Jobwahrheit.
