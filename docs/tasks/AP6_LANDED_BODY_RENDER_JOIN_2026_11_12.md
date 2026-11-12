# AP6: begrenzter Producer-/Renderer-JOIN

## Ziel / Ursache
Source-Bodyproducer verwendet kontrollierte Projektion; Parent b9f liefert
den echten readonly Landedgetter. Beide bestehenden Methoden zusammen nachweisen.

## Umfang / Nicht-Ziele
Nur eigene Task und output/native_glut_maps/ap6_landed_body_join_20261112.
Kein Produkt-/Sharedrunnerwrite, Stage/Commit, Flag-/LiveJSON-/EXEwechsel.
Keine produktive Szene, GPU/native Darstellung, volle Karte oder Gesamtabnahme.

## Quellen / Akzeptanz
hex_ground_ship_producer_verifier.gd, landed_craft_body_render_yaw_20261112,
polisa_bound_ground_body_profile_contract und Bodyproducer-Task. Echte
Controllerprojektion ruft echten TerrainMap3DViewgetter mit realem Cutlassasset.
Actual _try_start_drop_sequence bindet angenommenes Profil; tatsächlicher
Visualentry/Renderer lesen dieses detached Profil und halten Gesamt-Yaw bei
Kameradrehung. Keine gefälschte Projektion, kein handgesetztes Ownerergebnis.
Nur Startup/UI und überschaubare Actor-/Terraininputs kontrollieren.

## Lokale Prüfung / Risiken
Ein privates headless Projekt/Profil mit Isolationcanary, Source-/Profilhashschutz.
Vor Ausführung Dependencyfreeze durch Parent nötig: AP7-Terrainguard wird parallel
bearbeitet. Keine laufenden WIP-Bodies kopieren/testen. Rendererasset wird geladen,
keine tatsächliche Darstellung oder komplette Transportreise behauptet.

## Ergebnis
Parent bestätigte Dependencyfreeze vor Kopie/Lauf. Einzelner tatsächlicher
JOIN6/0, Exit0, sauberes Log; source_unchanged/real_profile_unchanged/private_canary
true. Kanonische QA output.log/report.json und README direkt im eigenen Paket.
Keine Produktänderung/Stage/Commit, kein Scene-/Native-/AP6-Gesamtpass.
