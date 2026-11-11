# R05 Quellen und Sichtung

- Eigene 2D-Zielskizze: layout_target.svg, vor dem Layoutcompiler erstellt. layout_final.svg ist eine abgeleitete Draufsicht, keine native Aufnahme.
- Root-KI-Konzept: references/station_concept_ai.png mit Root-Prompt/README daneben. Tatsächlich geöffnet. Übernommen: kräftige Ringquerschnitte, Tragachse, technische Unterbauten, Hull/Dark/Cyan-Farbgliederung. Die falsche KI-Padverteilung wurde ausdrücklich nicht übernommen: R05 besitzt sieben Pads pro Sektor.
- Gabriel Merovingi, „Port Olisar Wallpaper — Star Citizen (fanart)“, Behance, 14.01.2021: https://www.behance.net/gallery/111339155/Port-Olisar-Wallpaper-Star-Citizen-(fanart). Tatsächlich geöffneter Blueprint in references/merovingi_blueprint.png, Original https://mir-s3-cdn-cf.behance.net/project_modules/1400_opt_1/61cf53111339155.6004cb30a837c.png. Formreferenz für klar abgegrenzte Padgruppen, Zwischenbaugruppen und kräftige Ringe. Keine Meshübernahme.
- CitizenCon-Modellfoto https://media.starcitizen.tools/b/bc/CitizenCon_2024_Event_-_Models_Port_Olisar_1.jpg: Quelllink geprüft; lokaler Abruf scheiterte an TLS beziehungsweise HTTP403. Keine erfolgreiche Bildsichtung behauptet.
- Will Greenwood, „Port Olisar and Botany Lab, Star Citizen Fan Art“, https://willgreenwood.artstation.com/projects/Dx3XxR: Projektseite gelesen; Beschreibung nennt EZ-Hab-Umgebung und eigene Botanik-Erweiterung. Kein lokal geöffnetes Innenraumbild und keine Assetübernahme.
- Vorhandene offizielle/R02-Referenzen bleiben unter art/polisa_lookdev_20261111/references erhalten. R03 und R04 bleiben unverändert.
- Native Mannequins: bestehender operator.glb und personnel_armor_visual.gd verwenden die vorhandene R07-Körper-/Rüstungsausführung. Drei Rigs einmal in Idle gestellt und deaktiviert; sechs weitere Standbilder teilen einmal gebackene Meshressourcen. Keine neue Rüstungsrevision.

Die offizielle Godot4.6-MeshInstance3D-Dokumentation bestätigt die einmalige Skelettpose-Backfunktion: https://docs.godotengine.org/en/4.6/classes/class_meshinstance3d.html. Sie wird nur beim statischen Szenenaufbau verwendet.
