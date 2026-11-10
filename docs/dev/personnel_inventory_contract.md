# Personalinventar — Playtest 10.11.2026

## Besitzer und Zugriff

SimulationRoot bestaetigt Supply-Commands. SingleplayerSupplyState besitzt endliche
Bestandscontainer. Das vorhandene Personal-Loadout bleibt beim bisherigen
Personalowner; ein Ausruestungstausch prueft dessen aktuellen Slot und gibt den
neuen Slot erst nach erfolgreichem Bestandscommit synchron an denselben Owner.
UI zeichnet Snapshots und sendet Requests, ohne eigene Bestaende zu fuehren.

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
