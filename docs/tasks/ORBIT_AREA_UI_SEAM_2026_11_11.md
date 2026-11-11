# OrbitCanvas: kleinster UI-Anschluss

## Ziel / Ursache
Die vorbereitete native OrbitAreaCanvas soll vorhandene echte lokale Eigenschiff-DTOs zeigen und vorhandene Movecommands senden koennen. Strategischer Livekatalog V2 bleibt unveraendert. Kein neuer Reise- oder Bereichseintritt wird aktiviert.

## Scope / Nicht-Ziele
Nur scripts/ui/star_map_screen.gd und scripts/meta/meta_layer_flow.gd plus eigene Task/QA. Bestehende Canvas wiederverwenden. Optionale dritte configure-Callable fuer schmalen Area-Provider. Flow delegiert an Adapter.get_space_area_projection(craft_id), sofern vorhanden, sonst fail closed. Kein Adapter/Travel/Root/Grid/Datenedit, keine Gameplay-/Pose-/Crewwahrheit im UI, kein globaler Status oder Commit.

## Bedien-/Datenvertrag
Fleetpicker-Klick ist explizite Auswahl fuer Orbitansicht und sendet unveraendert space_focus_craft; voreingestellter Fokus/erstes Schiff wird niemals automatisch zur Orbit-Moveauswahl. Bestehende Location-Serviceauswahl bleibt separater Ort-UI-Kontext und wird nicht umgedeutet. Systemansicht immer erreichbar. Lokale Ansicht wird nur angeboten, wenn der schmale Provider den explizit gewaehlten Actor mit echter lokaler taktischer Flightprojektion im richtigen Bereich liefert. Canvas-Signal sendet ueber vorhandenes _send('space_move') ausschliesslich craft_id,target_hex,request_id; Root prueft alle Gameplayvoraussetzungen selbst.

## Aktualisierung / Quellen
Bei sichtbarer Orbitansicht getaktet nur schmaler AreaProvider (0.1s), keine pro-frame Vollsnapshots/Controlrebuilds. Systemansicht behaelt bisherigen Refresh. Sichtbarer Orbit faellt bei fehlendem Actor/Provider zur Systemansicht zurueck. Verfuegbarkeit nach explizitem Auswahl-/coarse Reisezustandswechsel erneut lesen; kein verstecktes Area-Polling. Quellen: ORBITAL_APPROACH_MAPS_2026_11_11.md, graphics_reference_revision_contract.md, ORBIT_AREA_CANVAS_2026_11_11.md, Root-DTO und bestehender strict3-Feld-Movecommand.

## Akzeptanz / lokale Pruefung
Enge Headless-UI-Contractprobe mit echter Screen/Canvas und kontrollierten Provider-/Commandcallables: kein Fallback, fehlende API, nur passende lokale Projektion, schmale Sichtbaraktualisierung, Systemrueckkehr, exakter vorhandener Command, keine Quellmutation; Einzelcompiles. Keine GPU-/Native-/Gefechts-/grosse Matrix. Das belegt UI-Anschluss, keine finale Reiseaktivierung oder Aesthetikabnahme.

## Risiken / offen
Adapter-Provider muss vom Owner geliefert werden, existierende lokale Actors brauchen echten vorherigen Bereichseintritt. Bis dahin bleibt Orbitansicht gesperrt. Keine Umstellung auf V3 oder ein Orbitziel, keine synthetischen Schiffe, keine automatische Serviceschiffzuordnung. Root-/Travel-/Sourceowner koordinieren Aktivierung separat.

## Ergebnis / Freeze
Arbeitsbasis 2f57968d8. Zehn enge UI-Contractchecks bestanden, 0 Fehler; echte Screen-/OrbitCanvas-Komponenten und echte Flowdelegation mit kontrollierten Ownercallables. Beide Einzelcompiles Exit 0. Fehlende narrow Owner-API ist explizit fail closed geprueft. QA unter output/native_glut_maps/orbit_area_ui_seam_20261111. Keine native Bildabnahme oder finale lokale Reiseaktivierungsfreigabe. Diffcheck ohne Whitespacebefund; externe .gitattributes:168-Warnung zu '(feat:' an Parent gemeldet, shared Datei nicht angefasst.

Parent hat nach Freeze den selektiven Commit genau dieser zwei Produktdateien samt eigener Task/QA autorisiert; keine anderen Quellen/Evidenzen aufnehmen. AP6 wurde parallel durch Parent als 69194ddab integriert, betroffene UI-Dateien blieben ungestagt und konfliktfrei.
