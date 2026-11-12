# Polisa: expliziter lokaler Dockauftrag

## Ziel / Ursache
Den vorbereiteten Dockowner aus der vorhandenen lokalen Sternkartenansicht
explizit anfordern. Bestehende Buttons und Commandhandler wiederverwenden.

## Umfang / Nicht-Ziele
Nur scripts/ui/star_map_screen.gd, diese Task und eigene kleine QA. Kein
Root-/Adapter-/Flow-/Canvas-/Ownerumbau, keine neue Gestaltung, Autowahl,
Navigation, Position-, Fuel- oder Visitmutation. Strategischer Anflug bleibt.
Kein Stage/Commit, Flag-/LiveJSON-/EXEwechsel oder native Gesamtabnahme.

## Quellen / Umsetzung
ARCHITECTURE/CODEX_RULES, polisa_station_dock_layout_contract.md,
SPACE_POLISA_LOCAL_DOCK_2026_11_12.md und vorhandene Orbit-UI-Seam.
Ein Button im vorhandenen SpaceMapViews-Stil. Aktuellen AreaDTO vor jeder
Anforderung erneut lesen; nur Projektion speichern, kein eigener Dockzustand.

## Akzeptanz / lokale Probe
Polisa andocken erscheint nur bei sichtbarer lokaler Glut2-Ansicht, explizit
gewähltem lokalem eigenem RootDTO-Actor und genau einem Targetrecord mit
target_id=polisa_station_dock/revision=polisa_glut2_dock_v1. Fehlender Provider,
Actor, DTO oder unbekannte Revision schliesst/deaktiviert. Tatsächlicher Button
sendet nur space_begin_station_dock mit craft_id, location_id=polisa, target_id,
layout_revision und eigener request_id durch _send. Keine Autoauswahl/-fahrt.
Kleine echte Screencommandprobe in privatem Projekt/Profil, RED/GREEN und Compile.

## Risiken / Integration
RootDTO/Dockowner und reviewed Callbackfix müssen gemeinsam integriert werden.
Der Button ist keine Gate-, Crew-, Fuel- oder Visitberechtigung. Server prüft
die tatsächlichen Voraussetzungen; Ownerablehnung erscheint im bestehenden UI.

## Freeze / Evidenz
Nur Screenproduktdiff +28/-2. Sauberes RED: fehlender Button1/1, danach
zehn tatsächliche Screenchecks10/0 und EinzelcompileExit0. Bericht unter
output/native_glut_maps/polisa_dock_ui_20261112; Quelle-/echter Profilhashschutz
und privater Isolationcanary true. Kein Runtime-/Native-/Dockinggesamtpass.
