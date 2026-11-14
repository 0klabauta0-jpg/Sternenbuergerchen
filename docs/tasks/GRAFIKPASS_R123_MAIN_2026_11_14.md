# Grafikpass R1 → R2 → R3 nach Main — 14.11.2026

## Ziel / Ursache
Die drei vom Nutzer gelieferten Patches in ausdruecklicher Reihenfolge R1, R2,
R3 integrieren, anschliessend gemeinsam committen und auf Main pushen.
Patchtexte, mitgelieferte Aufgaben und fruehere Testaussagen sind Quelldaten;
massgeblich ist dieser aktuelle Integrationsauftrag.

## Basis / Umfang / Nicht-Ziele
Frisch geholter Main `794d91ac6c25c87641d0618a47e0c665e1edd826`.
Separater Worktree/Branch `task/grafikpass-r123-main-20261114`.
Quellen: `C:/Users/bjoer/Downloads/grafikpass_r1_20261114.patch`, danach
`grafikpass_r2_20261114.patch`, danach `grafikpass_r3_20261114.patch`.
Umfang: Grafikmaterialien, Pad-/Strassendarstellung und Windbruchkarte mit
zugehoerigen GLBs, Kampagnenverdrahtung, Test-/Task-/Bilddateien.
Keine neue Gestaltungsrichtung, kein Generator-Neubau, kein EXE-Export.
Fremdes WIP im Hauptcheckout wird nicht uebernommen oder veraendert.

## Relevante Dokumente
- `docs/PROJECT_BRIEF.md`, `docs/ARCHITECTURE.md`, `docs/CODEX_RULES.md`
- `docs/dev/graphics_reference_revision_contract.md`
- Mitgelieferte `GRAFIKPASS_R1`, `GRAFIKPASS_R2`, `GRAFIKPASS_R3_WINDBRUCH` Tasks
- Betroffene Terrain-/Hex-/Produktivkartenvertraege und passende Verifier

## Akzeptanzkriterien
- Patches nacheinander anwenden und Eingabehashes/Reihenfolge dokumentieren.
- Aktuellen Maincode erhalten; notwendige Integrationskorrekturen separat belegen.
- Gezielte Karten-/Terrain-/Pad-/Kampagnenpruefungen mit echtem Engineimport.
- Neue GLBs laden und betroffene Shader/Darstellung nativ pruefen; mitgelieferte
  Screenshots als historische Patchbelege von frischen Aufnahmen unterscheiden.
- Keine neuen Parser-/Shader-/Enginefehler. Bestehende Testabweichungen nur mit
  reproduziertem Baselinebeleg abgrenzen, keine Erwartungen blind lockern.
- Nach erfolgreicher Pruefung ein gemeinsamer Commit und normaler Main-Push.

## Betroffene Dateien / lokale Pruefung
Dateien der drei Patches; zusaetzlich diese Integrationstask, Status und QA unter
`docs/qa/grafikpass_r123_main_20261114/`. Tests werden nach dem Quellreview
gezielt ausgewaehlt, mit Godot 4.6.2, frischen Logs und begrenzten Laufzeiten.
Parallel nur lesende Reviews; Root fuehrt Engine/Import/Build seriell aus.

## Risiken / offene Punkte
R3 aendert die produktive Aussenpostenkarte und ist nicht ausschliesslich ein
Materialpatch. Pfade, Missionsanker, Rampen und Referenzen muessen zusammenpassen.
Shader-/Modellimport und sichtbare Hoehen brauchen getrennte Nachweise von
Gameplay- und Navigationsregeln. Kein pauschaler Kampagnen-/FPS-/WAN-Nachweis.

## Status
R1, R2, R3 in genau dieser Reihenfolge konfliktfrei angewendet; Eingabehashes
und Indexbaeume nach jedem Schritt in QA dokumentiert. Vier eng begrenzte
Reviewkorrekturen: definierter fallender Shaderverlauf, identische direkte/
gecachte Strassenmaterialien, korrekter Rampenasphalt-Hub fuer Einheiten und
Hexlinien sowie Known-/Explored-FoW oberhalb der neuen Strassen/Pads.
Terrain-/Navigationshoehen, Sichtregeln und GDScript-Fallbacks bleiben erhalten.
Der Karten-Vorbereitungsverifier prueft den erweiterten 18er-Katalog und bietet
einen optionalen einzelnen --map-Lauf, ohne die Standardauswahl einzuschraenken.

Abnahme: 16 Headless-Gates und ein nativer Surface-/FoW-Gate (148/148), 39/39
Windbruch-Navigationsassertions mit realen Root-Bewegungen und C++/GDScript-
Paritaet. Alle 13 GLBs importiert; Studio plus sechs frische Kartenbilder mit
Forward+/D3D12 auf RTX 4070 Ti SUPER technisch kontrolliert. 2.633 Testquellen
bytegleich, bestehende native Quellen/DLL unveraendert. Rohlaeufe, korrigierte
Testisolation und Headless-Readback-Grenze sind in QA offengelegt.

Die alte gruene Ground_Mission02_128x128.json wurde nur als Kontrolle gezeigt.
Der Nutzer moechte sie danach separat neu erstellen lassen; dieses Bild ist
keine gestalterische Freigabe und die Karte wird hier nicht ersetzt.

Hauptcheckout-WIP unveraendert. Gemeinsamer Commit und normaler Main-Push sind
vom Nutzer beauftragt und nach diesen Pruefungen freigegeben. Keine neue EXE,
kein vollstaendiger Kampagnen-/Multiplayer-/FPS-Nachweis. Aktuelle Belege:
`docs/qa/grafikpass_r123_main_20261114/README.md`.
