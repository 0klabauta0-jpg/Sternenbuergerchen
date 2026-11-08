# R4: TASK174 misst sichtbare Waffenachsen und wirkliche gesenkte Pose

## Problem / gebundene Ursache
TASK174 meldet81/2 sowohl auf exakt Main3b12b2878 als auch im R4-Kandidaten.
Das ist ein beidseitig reproduzierter Baselinebefund, keine R4-Regression.
Der alte Test prueft BlasterVisual-Root(-Z/+Y) und Proxy+Z als NPC-Ruecken.
Diese Achsen sind fuer die sichtbaren importierten Waffen nicht korrekt:
zwischen Root und Mesh liegt eine Child-Yaw-Korrektur; der Unit-Facingvertrag
verwendet Proxy-X als Front und damit Proxy+X als Ruecken.

Der unveraenderte normale Missionsinspector
`idle_axis_inspection/20261107T094404Z-36b69d2a/` liest5/5 strukturelle/
Puritychecks. Beide vorhandenen Figuren stehen in lowered/idle. Alter
Rootbarrel-DOWN-Dot liegt bei+.959, sichtbarer Meshfront-DOWN-Dot bei-.959:
der sichtbare Lauf zeigt tatsaechlich nach oben. Root-UP gegen alten Back ist
etwa-.13, gegen kanonischen Back etwa-.95; Mesh-DOWN gegen kanonischen Back
liegt bei+.95. Ein reiner Austausch der NPCback-Achse repariert den Gatefehler
und den vorhandenen sichtbaren Idlefehler daher nicht.

## Unabhaengige Original-GLB-Geometrie
Nur Original-BIN-Positionsaccessors und Node-JSON gelesen, keine Engine oder
Assetmutation:
- `blaster-a`:36Vertices an der negativenZ-Front, Flaechenzentrum
  `(0,.079549145,-.370000005)`. Magazin hat nur Translation
  `(0,-.152950853,-.145)`, keine Rotation. Oberes Mountzentrum `(0,0,0)`,
  unteres Tipzentrum `(0,-.150000006,+.019999999)`.
- `blaster-f`:6Vertices an der negativenZ-Front, Flaechenzentrum
  `(0,.082500003,-.654999971)`. Magazin hat nur Translation
  `(0,-.0425,.1)`, keine Rotation. Oberes Mountzentrum `(0,0,0)`,
  unteres Tipzentrum `(0,-.179999992,+.019999999)`.
Die sichtbare Mündung ist damit Mesh(-Z), das Magazin erstreckt sich dominant
entlang Mesh(-Y) mit kleiner positiverZ-Neigung. Der alte Root+Y-Vektor ist
keine passende Geometrie-Oracle.

## Ziel / Umfang / Nicht-Ziele
Die zwei TASK174-Orientierungspruefungen auf tatsaechliche gesenkte Pose,
primaeren sichtbaren Mesh, geometrisch richtige Richtung und vorhandenen
Unit-Facingvertrag beziehen. Dieselben Grenzwerte bleiben unveraendert:
Front-DOWN-Dot mindestens.85 und Magazin-Back-Dot mindestens.70.
Alle anderen Import-/Lizenz-/Mapping-/Socket-/Rootposition-/Scale-/Textur-/
Animations-/Simulationpuritygates bleiben erhalten. Keine Schwellenlockerung,
kein Assertionentfernen, keine Actor-/Posture-/Position-/Clock-/Authoritypatches.

Der korrigierte Test muss zuerst auf dem jetzigen lowered-Child180-Kandidaten
real rot sein. Erst danach wird die bestaetigte Asset-Visualkorrektur der
beiden belegten A/F-Loadouts gesondert freigegeben. Andere Waffenloadouts,
Originalrohclips, Sockets, Rootpositionen, Skalierung und Spielzustand bleiben.
Produktwriter ist der Visualagent nach Rootfreigabe; keine Produktwrites
durch den unabhaengigen Gate-/Achsenreviewer.

## Dokumente / betroffene Dateien
AGENTS, PROJECT_BRIEF, ARCHITECTURE, CODEX_RULES, R4-Haupttask,
Combat-Visual-Untertask, Idle-Axis-Evidence-Task,
`unit_facing_visual_contract.md`,
`scripts/tests/task_174_character_helmet_blaster_attachment_verifier.gd`.
Produkt nach eigener Freigabe nur enger Visual-Asset-/Mappingpfad.

## Akzeptanz / lokale Pruefung
1. TASK174 bestaetigt vor der Orientierungspruefung die wirklich angezeigte
   Waffenpose lowered und aktuelle Animation idle auf den bestehenden IDs.
2. Sichtbarer primaerer Mesh liefert Front(-Z) und Magazin(-Y); kanonischer
   NPC-Ruecken ist die horizontale Proxy+X-Richtung. Beide bisherigen
   Dotgrenzen bleiben. Kein Artefakt-Eintrag ersetzt Mesh-/Posturebeweis.
3. Neuer enger echter RED auf dem bisherigen Candidate mit sichtbarer
   Idlefront nach oben. Beleg bleibt bestehen; Test und Produkt getrennt pinnen.
4. Nach separatem Produktpatch bestehen korrigierter174, Muzzle-Anchor23+
   samt beiden Aim-Eintritten/-Austritten, Pose-Stability und vorhandene
   Attachment-/Weaponloadout-Nachbarn auf demselben finalen Pin.
5. Native Vollbild-/Spielabstandsaufnahmen pruefen die sichtbare Richtung;
   Inspector- und Rendererfixtures sind kein physischer Schussnachweis.

## Risiken / Status
Mapping- oder Gatekorrektur darf weder laufende Rohclips einfrieren noch
Magazine-/Muzzleachsen zur Laufzeit neu erfinden. Ein Gate kann nur die zwei
belegten GLB-Achsen beanspruchen; das ist keine automatische Abnahme anderer
Waffen. Task vor Gate-Reparatur geschrieben. Zum ersten korrigierten Root-RED
war Produkt unveraendert55c183a8/09a7a1fa; weitere Schritte stehen unten.

## Gate-Reparatur vor Produktpatch
- TASK174 prueft zwei zusaetzliche tatsaechliche lowered/playing-idle-
  Vorbedingungen und danach den primaeren sichtbaren Mesh(-Z/-Y) gegen
  DOWN/kanonischen Proxy+X-Ruecken. Grenzen unveraendert.85/.70; kein alter
  sonstiger Gate entfernt. Diagnose `TASK174_IDLE_MESH_AXES` zeigt die Dots.
- Test-SHA256
  `e3b96fcdd2ad0ae09e228fe4c25cf1da465b3bdc94402ba1639e7d56c29d4f9b`.
  Kein Engine-/Produktlauf durch den Testautor.
- Root-RED vor Produktfix83/2: beide lowered/idle-Vorbedingungen bestehen,
  sichtbare Meshfront-DOWN liegt-.959 und Magazin-Back+.953/.946. Der Test
  belegt den echten Main-Assetfehler statt bloss eine geaenderte Referenz.
- Danach separater freigegebener Visualagent-Produktfix nur der beiden A/F-
  Meshchild-Yaws auf0 mit defensiver Defaultvererbung. Conditional-Aimed-
  Sonderpfad entfernt; Sourcepin Mapping`a7d133cd...`, Terrain`6e448486...`.
  Unabhaengiges Source-Review dieses finalen Asset-/Poseowners: APPROVED scoped.
- Root-GREEN `attachment_actual_mesh_green/20261107T095103Z-f9993215/`:
  85/85 ohne Enginefehler, stabile Quellen. AnchorGlobalFinal und Pose15/15
  ebenfalls laut Root gruen; native Bilder und physische Schuesse bleiben
  eigene Rootnachweise. Alte Main81/2- und neue ActualMesh83/2-Belege bleiben.
