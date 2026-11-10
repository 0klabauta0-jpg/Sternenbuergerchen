# Playtest-Nachtrag: Charakter, Weltaktionen und Kamera

10.11.2026. Taskbranch task/personnel-details-context-cursor-20261110 auf Main80938bf7b. Ursprünglicher Arbeitsbaum mit fremdem Terrain-/Playtest-WIP unverändert. Kein Mainmerge und kein neuer EXE-Export in diesem Folgeauftrag.

## Umsetzung
NPC-Karten und Basiswelt-NPCs öffnen dasselbe Charakterblatt. Links lesbare Eigenschaften, Kernwerte und Herleitungen mit einzelnen Faktoren untereinander; rechts tatsächliches endliches Inventar. Read-only-Labels mindestens15px, Kernwerte vor den vollständigen Rollenherleitungen, getrennte Scrollbereiche. Kein eigener Loadout-/Bestandsowner im Popup.

Basis: Linksklick NPC/Schiff auswählen, NPC-Doppelklick Details, freier Linksklick abwählen. Schiffswahl löst kein Boarding aus. Rechte Schiffs-/Serviceansicht nur bei entsprechender Auswahl oder ausdrücklich geöffnetem Servicebereich. Dessen Schiffsselector bleibt unabhängig von alter Weltwahl.

Kontextcursor bei ausgewähltem Trupp/Person über bestehenden Weltzielen: Einsteigen, Daten sichern, Einsammeln, Abbauen/Bergen. Hover mutiert nichts. Rechtsklick erstellt den bestehenden Use- oder Bewegungs-Intent; GO und Bedien-/Boardingdauer bleiben autoritativ. Verborgene Missionen und UI-Flächen nehmen keine Weltaktion an. Kein neues Lootsystem behauptet.

Zoom hält den genauen Bodenpunkt unter dem Mauszeiger; MMB verschiebt statt dreht, Q/E-Drehung bleibt. Basis und Einsatz benutzen dieselben Projektionsmethoden. Flacherer gemeinsamer Ausgangswinkel: Parameter40°, effektive Elevation ungefähr35°. Boden und Gebäude werden von derselben Kamera im selben3D-Weltraum gerendert. Die Basisbeschriftung wird als Bildschirmtext mit konstanter Schriftgröße projiziert; Übersicht zeigt weniger gleichzeitig sichtbare Aktionen. Details bleiben über Auswahl/Hover verfügbar.

Vorher bereits native1:1-Renderauflösung; schlechte Ferndarstellung lag nicht an verkleinerter Viewportauflösung. 2×MSAA glättet Geometriekanten. Ableitungsbasierte Filterung reduziert hochfrequentes prozedurales Bodenrauschen bei Ferndistanz, erhält breite Formen und nahe Details. Bounded native Vergleiche: camera_render/. Keine allgemeine GPU-/Performancefreigabe; feines Korn bleibt teilweise sichtbar.

Start-/Boardingansicht zeigt die tatsächliche Entermesser/Cutlass auf ihrem Pad in Nahaufnahme. Bereits bestätigte Pad-Sichtbarkeit wird nicht allein wegen busy verworfen. An-/Abflugdarstellung liest vorhandene Transferphase/-zeit; reine visuelle Kurven heben zuerst an beziehungsweise bremsen vor dem Aufsetzen. Vier fest verankerte zweischichtige Abgasstrahlen am unveränderten Ref03-Modell. Keine neue Flugphysik, VTOL-Gelenkanimation oder veränderte Gameplay-Timer.

## Gezielte Prüfung
Frische finale Logs: Kamera52/0; Abgas/Manöver412/0; Charakter/Inventar28/0; kompakte Lesbarkeit22/0; echte Missions-Kontextaktionen12/0; Serviceauswahl1/0; Ankunft/Use/Rückkehr21/0; Kampagnenstart13/0; tatsächlicher erster Ausflug mit Heimtransport/Upload/Save55/0. InventarruntimePASS. Native UI36/0 (D3D12, Exit0,0Enginefehler,2bekannteUID-Warnungen), geprüfte Bilder: ui/ und finaler native_ui-Beleg in logs/. Die Domainprüfungen und Grafikfixtures sind keine menschliche Stil-/Spielspaßabnahme.

Unabhängiger Review fand dreiP2: Eingabe einer versteckten Mission, überlebende Vollbildbeschriftungen in kleiner Vorschau und Überschreiben einer ausdrücklich geänderten Service-Schiffswahl. Alle korrigiert und mit gezielten Regressionen geprüft; abschließend keine offenenP1/P2 im fokussierten Review.

Ältere Layout-/Audits sind kein grüner Gesamtnachweis: task17934/9 und task18149/2 haben veraltete feste Fenstererwartungen beziehungsweise statische SimulationRoot-Textverbote. Alter R3-Kamerafixture fehlt get_place_presentation; task16020/2 bei Sichtbarkeit/Badges ungeklärt. Die zugehörigen Fensterpfade wurden auf neue Popupstruktur nachgezogen; keine behauptete Gesamtsuitefreigabe.

## Quellen / offen
Erkul-Freigabelink im Browser erfolgreich gelesen: https://erkul.games/s/85yjk7o5 → Calculator CutlassBlack; Datenstand4.10.2-LIVE.12913470. Datierte Werte/Einheiten unter data/reference/erkul_cutlass_black_20261110.json sind externe Balancing-/Erzählreferenzen, keine stillschweigende Übernahme in Gameplay. Erhaltung einer besonderen geteilten Komponenten-Konfiguration nicht unabhängig bestätigt.

Engere Gebäudestellung bleibt eigener Authoring-Nachtrag: docs/tasks/BASE_COMPACT_LAYOUT_FOLLOWUP_2026_11_10.md. Gebäudeflächen, Kollisionen und feine Innenraumnavigation müssen gemeinsam angepasst werden; hier keine reine Modellverschiebung.
