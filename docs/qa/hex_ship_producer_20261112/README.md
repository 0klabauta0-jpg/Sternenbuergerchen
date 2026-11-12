# AP6: konkrete Schiffsproducer und Aussteigemaske

Kleine private Projekte, Godot4.6.2, keine Hauptszene oder Produktionskarte.
`ship_producer`:66/0; bestehender tatsächlicher Transportcontroller:73/0.
Quellen unverändert, getrennte Userprofile und Originalprofilguard jeweils grün.
Die exakten Quellhashes und Originalausgaben liegen im Manifest/ZIP.

Der tatsächliche Controller wählt nur akzeptierte Landestände oder laufende
Sequenzen. Unbemannte geparkte Schiffe zählen ebenfalls. Gebundene Profile und
Registryrevision bestimmen den begrenzten abgeleiteten Cache; Kamera und Fortschritt
erzeugen keine neue physische Geometrie. Der echte Aussteigeconsumer übergibt die
fremden Sperren nur beim neuen Root-Gruppenticket. Polling publiziert nichts vorzeitig.

Reguläre angenommene Ankünfte binden ein Profil nach allen Startguards, auch in
LegacyPolisa als Voraussetzung der vorhandenen lokalen Kaufprüfung. Im Hexmodus
prüfen endgültiger LZ und beide Touchdownübergänge aktuelle NPC-/Slot-/Moveclaims
und akzeptierte fremde Schiffskörper. Vorher angenommene Geometrie bleibt dabei
unverändert; ein belegter Touchdown wartet im Anflug.

Frischer unabhängiger Review fand drei P2-Lücken. Tatsächliche Repros62/4 vor
Fix, danach66/0: unakzeptierte wartende LZ, Körperüberlappung trotz altem
Mittelpunktabstand und hineingelaufener NPC zwischen Start und Touchdown.
Erstes Interface-RED42/1, vorherige Setup-/Parserfehler im Archiv sind kein RED.

Geometriequelle im Verifier ist eine bekannte Projektionsfixture. Der vereinbarte
tatsächliche Renderergetter `get_landed_craft_body_projection` liegt im Parent
`b9f194d9e`, Kartenidentität in `55ccb737a`. Der ältere Source-Renderer wurde nicht
mit inkompatiblen Payloadsignaturen überschrieben. Gemeinsame Integration prüft
diesen Anschluss gesondert. Setup/Base und AP7/8 bleiben weitere Pakete.
Keine native Grafik-, Save-, Multiplayer-, FPS-, AP9- oder EXE-Abnahme.
