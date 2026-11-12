# Heimatbasis: Boden, Steine und Hexraster

## Ziel und Ursache
Nutzerbefund: dunkler unpassender Bodenfleck, farblich abgesetzte Steine,
unsichtbare Hexfelder und fragliche Steinschatten. Der aktuelle native
Compatibility-Render wird gegen den erhaltenen Frontier-Basisrender und die
zugeordneten Geologieziele verglichen. Keine neue Stilrichtung.

## Umfang und Grenzen
Eng begrenzte Korrektur der vorhandenen Bodenmaterialroute, ihrer Farbumrechnung
und Rasterdarstellung. Nativer Vorher-/Nachhervergleich mit identischer Kamera.
Kein neuer Gameplay-/Navigationsowner, keine Änderung der Gesteinsgeometrie,
keine Änderungen am sichtbaren Desktop oder an Nutzereingaben. Padkollisionen
und Unterkunftsbau liegen beim parallelen Heimatbasis-Teilauftrag.

## Verträge und Quellen
`graphics_reference_revision_contract.md`, `terrain_truth_visual_audit_contract.md`,
`hex_grid_v1_contract.md`; `CAMPAIGN_HELP_RECRUITMENT_2026_11_12.md`.
Erhaltener nativer Referenzrender:
`Assets/curated/main_menu/frontier_outpost_main_20261101.png`.
Aktueller nativer Ist-Stand: `output/visual_internal_20261112/`.
Geologieherkunft: `art/frontier_illustrated_20261101/environment/pass06/geology/`.

## Akzeptanz
- Boden und Steine gehören sichtbar zur gedämpften Rost-/Sandfamilie der Quelle.
- Wege heben sich lesbar ab, ohne einen schwarzen/grünen Fleck zu erzeugen.
- Vorhandene echte Hexfelder sind sichtbar; verdeckte Flächen bleiben verdeckt.
- Steine behalten nachvollziehbaren Bodenkontakt und gerichtete Schatten.
- Gleiche native Kamera/Beleuchtung/Renderer vor und nach der Korrektur.
- Keine Behauptung einer Nutzer-, Leistungs- oder allgemeinen Spielabnahme.

## Erwartete Dateien und Prüfung
`scripts/meta/explorable_homebase.gd`, vorhandene Terrainmaterial-/Shaderroute,
gezielte native Probe und QA-Protokoll. Geometriequellen bleiben unverändert.
Godot 4.6.2 Compatibility auf einem eigens angelegten, nie aktivierten Desktop,
isoliertes Profil; anschließend Bilder öffnen und verbleibende Abstände benennen.

## Risiken und offener Stand
Gemeinsame Shader werden auch außerhalb der Basis verwendet: rendererabhängige
Farbfehler systematisch prüfen, ästhetische Palettenänderungen auf die Basis
begrenzen. Das grobe sichtbare Hexraster ist von der feineren Innenraumnavigation
zu unterscheiden. Ausgangsbefunde noch nicht als behoben bestätigt.

## Präzisierung des Nutzers: Wege und Räume
Die Basis erhält durchgehenden, dezent strukturierten Boden ohne gemalte
Straßen-/Sandstreifen. Gebaute schmale Verbindungswege mit kleinen Randsteinen
folgen den vorhandenen echten Eingängen und Pads. Bestehende Ribbon-/Polygon-
Union-/Boulder-Werkzeuge werden wiederverwendet; keine zusätzlichen Blocker.
Weitere geöffnete Originale: `02_freihafen_distribution_center.png` sowie
`docs/reports/assets/ui-2026-11-01/references/aussenposten_stilstudie.png`.
Die in Referenzen enthaltenen Schiffe sind für diesen Vergleich irrelevant.
Modulare Schlaf-/Lagerräume mit separat baubaren Betten sind ein eigener
Gameplay-/Bauauftrag; vorhandene ganze Habitatkopien sind dafür keine Abnahme.
Neue Felsvorgabe: große Formen hexzentriert, hohe Mitte vollständig sichtblockend,
halbhohe Nachbarn für Teildeckung. Istwerte/Owner werden parallel auditiert;
Material-/Screenshotkorrekturen allein erfüllen diese Gameplayvorgabe nicht.

## Letzte verbindliche Korrekturen und erreichter Stand
Der Nutzer möchte wieder den früheren **durchgehenden geteerten Weg**, lediglich
mit besseren Kurven und Anschlüssen. Die Trittsteinvariante ist verworfen.
Aktuell sind vereinigte Asphaltgeometrie, weich geführte Kurven, kleine
Randsteine und dezent markierte Ränder eingebaut. Keine gemalten Straßenfelder
im Terrainshader. Ein sichtbarer schöner Fels auf einem Hexfeld genügt:
schlichte Hexsäulen sind verworfen, das vorhandene `rock_largeA.glb` bleibt
geometrisch erhalten und wird zentriert/in die Hexhülle eingepasst. Hohe und
niedrige Nachbarzellen lesen die gemeinsame `homebase_rock_rules.gd`-Quelle.

Frische native Übersicht, Straßennähe und Felsnähe geöffnet; reine Visualprobe
21/0. QA und genaue Grenzen in `docs/qa/homebase_visual_coherence_20261112/`.
KI-UI- und Iconstudie als ausdrücklich nicht implementierte Vorschläge unter
`art/homebase_ui_study_20261112/`. Die Befehle sollen unten ganz links stehen,
danach eine kleinere Personenkarte und weitere Personen; eigentliche
UI-Umsetzung beim parallelen Teilauftrag. Persönliche Grafikfreigabe offen.
