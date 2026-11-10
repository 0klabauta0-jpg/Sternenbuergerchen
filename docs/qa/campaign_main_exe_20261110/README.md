# Main-Integration und neue EXE — 10.11.2026

Integration von Kampagne e4b407fe in Main 1023d11c3, getrennt vom fremden WIP im ursprünglichen Arbeitsbaum. Ziel: fünf Missionen und drei Skirmish-Starts über die neue Windows-EXE ausprobieren.

## Konfliktauflösung
Automatische Ruhe und Main-PersonnelLoadoutState bleiben erhalten. Kampagnen- und Skirmishstart setzen echte Loadouts über den autoritativen Owner. Supply behält genau einen LocationRuntimeState je Ort. Ressourcenpanel und vorhandenes Welt-Use/GO entnehmen aus demselben endlichen Bestand; sichere Checkpoints erhalten diesen Bestand. Mining-Nachkauf im Kampagnenmodus erst nach Freischaltung. Main-Wrackkollisionen und vorhandene Modelle bleiben erhalten.

## Reproduzierter Navigationsfehler
M3 blieb beim tatsächlichen Rückbesuch mit Rekrut auf einem isolierten begehbaren Höhenrücken (27,-1) stehen. Echte Pfadsuche verlangt am Höhenübergang eine slope-Kante; der alte Kartenverifier akzeptierte jede Höhendifferenz<=1. Neues Gate mit TerrainPathfinder: RED68/1; Böschungen an generierten niedrigen Rücken: GREEN69/0. Kein Teleport, kein fingierter Missionsbeleg. Unabhängiger Code-Reviewer bestätigte die isolierte18-Zellen-Komponente und den notwendigen Anschluss. Main-Wrack-Geometrieprüfung weiterhin PASS.

## Frische Prüfungen
Beigelegte Logs und results.json: Kampagnenstart13/0; Domainkette54/0; vorbereitete Starts209/0; tatsächlicher Early/Mid/Late-Flow97/0; Ressourcenzugänge/Restore21/0; Kapazitätsnavigation169/0; stationäre Interaktion/Rückkehr21/0; automatischer RuheablaufPASS; Inventar-/Supply-/Kampagnen-/Menüregressionen grün. Tatsächlicher erster Ausflug mit Heimtransport/Upload/Save55/0.

Kampagne-Neu/Ersetzen/Abbrechen/Fortsetzen: headless80/0, native D3D12/Forward+81/0. Native117 PreDraw-Signale,216 aktive Kamera-/SSAO-Samples,0 unsichere Ziele. Sechs bekannte UID-Fallbackwarnungen, keine Engine-/Scriptfehler. Private APPDATA-Profile; keine echten Teams oder Nutzerspielstände durch Tests beschrieben.

Tatsächliche Fortsetzung ab zuvor erflogenem M2-Basischeckpoint:123/0. M3-Händlerlieferung, M4-Kampf/Chip/Heimupload, M5-Raumkampf/Rettung, Padbau und echtes Continue mit4Personen/2Schiffen/Pad2. Nicht als ununterbrochener nativer Fünf-Missionen-Playtest ausgegeben. Unabhängiger abschließender Review: keine offenen P1/P2 in Konfliktlösung und Kartenfix.

## Grenzen und Paket
Spätere Schiffmodelle sowie Träger-/Fahrzeug-Spezialfähigkeiten bleiben bezeichnete Platzhalter. Native Start-/Rendererprüfung ersetzt keinen vollständigen menschlichen Kampagnenplaytest und keine allgemeine Performance-/MP-Freigabe. Export-/EXE-Nachweis folgt im neuen Paket C:/dev/SternenBuergerchen-builds/2026-11-10-campaign-skirmish-main-r03/PRUEFBERICHT.md.
