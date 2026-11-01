# Pass06: malerischer Gebaeudeabrieb als Materialstudie

P05-Bauformen und saubere Fassaden wurden erneut gegen die geoeffneten Rostgrenze-/Freihafen-Ziele verglichen. Diese Revision aendert ausschliesslich die Materialroute: weiche grosse Pigmentfelder, kreidiger ausgebleichte Oberseiten, waermerer Sockelstaub, wenige gerichtete Fassadenspuren und selektive kleine Kantenstellen. Keine weitere Geometrie-/Nietenrunde. Dies bleibt ein grafischer Kandidat ohne kuenstlerische Nutzerfreigabe.

Die vorhandene Godot-Quelle `scripts/terrain/frontier_closed_buildings.gd` routet Lack, Dach, Tragwerk und Sockel in vier staerkemaessig getrennte Rollen. ShaderMaterial-Ressourcen werden pro Rolle und Originalfarbe geteilt. Gebaeudeursprung/Hoehe werden einmalig beim Aufbau gesetzt; Instanzparameter enthalten die tatsaechlichen lokalen Bauteil-AABBs, damit Abrieb an wenigen Kanten liegt. Glas, Emissivfenster/-streifen, schmale Markierungen und tiefe Fugen behalten die StandardMaterial3D-Route. Deren urspruengliche Farben und Emissionsenergien wurden numerisch gegen P05 verglichen.

Der neue `shaders/terrain/frontier_building_wear.gdshader` verwendet statische weich interpolierte Felder auf mehreren Skalen. Dachoberseiten bleichen staerker als die Fassade, Staub nimmt nach unten zu, die Waschspuren laufen nur durch ausgewaehlte Wandzonen. Die erste geoeffnete Fassung war zu schwach. Gross-/Mittelfeldamplituden wurden von 0,22/0,065 auf 0,38/0,075 erhoeht; Dachbleichung und Sockelstaub wurden verstaerkt. Rauschfrequenzen blieben dabei gleich. Kein flaechenfuellendes Hochfrequenzgrunge, keine Zeit-/Normalen-/Vertexbewegung und keine neue Beleuchtung.

Der Material-/Geometrieverifier `look_probe.gd` besteht **39/39** sinnvolle Pruefungen unter Godot 4.6.2. Erfolgsmarker: `BUILDING_PASS06_QA`. Alle Mesh-Arrays/Transforms einschliesslich Vertices, Normalen und Indices liefern exakt dieselben SHA256-Fingerprints wie P05; damit bleiben 2588/2508 Dreiecke, 57/58 Meshes, Bauhuelle, Bodenstand und C-Hierarchie erhalten. Glas-/Emissivwerte, Materialteilung, vier Rollen, lokale AABB-Parameter und Ursprung bei versetzter Aufstellung sind geprueft. Rohbericht und Logs liegen unter `qa/`.

Habitat: 44 Wear-Meshes und 13 ausgenommene Standard-/Emissiv-Meshes; Halle: 43/15. Jeweils 26 geteilte Wear-Materialressourcen statt einer Kopie pro Mesh. Das ist eine Materialressourcenmessung, kein allgemeiner Performancegewinn. Die konservative AABB-Montagepruefung ist kein exakter Kontakt-/Schnitt-/Z-Fight-Oracle und geschlossene Topologie wird pro Teilmesh geprueft.

15 isolierte echte Forward+/Vulkan-Aufnahmen zeigen P05, die neue Route mit Wear aus und die endgueltige Fassung. Jeweils Front/Heck/Ensemble bei gleichen Kameras, Aufloesung 1280x900 und unveraendertem FrontierArtProfile-Licht/Environment. Die zusaetzliche Kontrolle trennt PBR-Materialrouting vom eigentlichen Abrieb: Wear aus trifft P05 im Bildmittel mit 0 bis 0,00016 RGB-Stufen von 255; Wear an aendert die Habitat-/Hallen-Nahbilder im Gesamtbildmittel um 1,96/2,15 Stufen. `verify_render_response.py` besteht dazu 6/6 Antwortpruefungen. Diese Werte belegen eine tatsaechliche Shaderwirkung, keine kuenstlerische Qualitaetsnote.

Alle 15 Bilder wurden geoeffnet. Breite Dachaufhellungen und Sockelstaub sind gegen P05 sichtbar; Glas, Portal, Schrift und Leuchtakzente bleiben lesbar. **Grenze der isolierten Probe:** Hintergrund und Schatten zeigen ein feines Checker-/Dithermuster in beiden Staenden. Die kombinierte native Root-Vorschau zeigt dieses Muster nicht und bleibt die Hauptbildreferenz. Die Illustrationen sind weiterhin reicher individuell bemalt; kleine Kantenstellen bleiben im Spielabstand sparsam und es gibt keinen modellierten Korrosions-/Texturautorenpass.

`source/` erhaelt P05-Builder, neuen Builder und Shader; `manifest.json` enthaelt exakte Runtime-/Quell-/Bildhashes, Zahlen, Pruefpfade und Grenzen. Root besitzt die kombinierten Captures, die strenge Gesamtsuite und den Report. Schiffe/Astra, Citizens, Kenney-Originale, Boden/Felsshader, Preview/Renderer, Dokumentation ausserhalb dieses Pakets und Git wurden von diesem Teilauftrag nicht veraendert.

Reproduktion ohne Import aus dem Repository-Root:

```powershell
$wearGodot = 'C:/Users/bjoer/AppData/Local/Programs/Godot/Godot_v4.6.2-stable_win64_console.exe'
$wearProbe = 'art/frontier_illustrated_20261101/environment/pass06/buildings/look_probe.gd'
& $wearGodot --headless --path . --script $wearProbe
& $wearGodot --path . --rendering-method forward_plus --rendering-driver vulkan --resolution 1280x900 --script $wearProbe -- --render
python art/frontier_illustrated_20261101/environment/pass06/buildings/verify_render_response.py
python art/frontier_illustrated_20261101/environment/pass06/buildings/finalize_manifest.py
```

Native Bildlaeufe mit Root koordinieren und erzeugte Bilder vor der Manifestfinalisierung tatsaechlich oeffnen. Bewusste Fortsetzung des noch nicht integrierten Branches `task/grafikreferenzen-20261101`; kein Commit/Push durch diesen Agenten.
