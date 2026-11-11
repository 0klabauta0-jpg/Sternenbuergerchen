# Orbit-Anfluglayout: reine Authoringgeometrie

## Ziel / Ursache
Die aktualisierte Orbitvorgabe braucht eine lokale Karte mit 512 x 256 Zellen: Ankunft unten, oben mittig ein nominal 256 Zellen breiter Himmelskoerperbogen mit maximal 4 Zellen sichtbarer Tiefe. Die 4 Zellen bezeichnen die sichtbare Tiefe, nicht den Planetradius. Derselbe Saum liefert Gatekandidaten.

## Scope / Nicht-Ziele
Reiner statischer Godothelper scripts/mission/orbit_approach_layout.gd und ein kurzer eigener Authoringvertrag. Keine Aenderungen an World, SpaceRuntime, UI, StarSystem, Root oder bestehenden Karten. Kein Schiffs-, Rotten-, Blockaden-, Reise-, Save- oder Zugangszustand. Produktive 3 Orbitmarker bleiben erhalten, bis Warp, lokaler Flug und Saumgate beim vorhandenen Weltraumkampfowner angeschlossen sind. Die strategische Karte bleibt 256 x 256.

## Geometrie / API
build(body_id) liefert frische Daten mit deterministischer body_map_id, Rect2i-Mapbounds (0,0,512,256), unterem Ankunftsband (0,224,512,32), Limbfakten und neuen Body-/Gatezellarrays. contains_local_cell(cell), limb_depth_at(column) und gate_cells(body_id) sind reine Leser. Die Geometrie verwendet logische Zellzentren x+0.5/y+0.5 und erzeugt keine neue Navigationswahrheit.

Bogenenden liegen bei x=128/384, y=0; die Mitte liegt bei x=256, y=4. R=(128^2+4^2)/(2*4)=2050; Kreismitte (256,-2046), der Rest des Koerpers liegt oberhalb der Karte. Pro Spalte x=128..383 werden bis ceil(Unterkante) konservativ beruehrte Bodyzellen belegt, maximal die Zeilen 0..3. Die erste freie Zelle direkt UNTER dieser Maske ist der Gatekandidat. Damit liegt kein Gate in der Koerpermaske. Es gibt keine feste 3-Marker-Enum.

Das untere Band y=224..255 ist nur eine technische Flaechenvorgabe. Der Runtimeowner muss die tatsaechliche freie Bottomspawnzelle validieren. Der Helper setzt keine Schiffposition.

## Vertraege / Dateien
AGENTS, PROJECT_BRIEF, ARCHITECTURE, CODEX_RULES und orbit_quantum_travel_contract. Der eigene orbit_approach_layout_contract dokumentiert diesen noch unverdrahteten Kandidaten. Arbeitsbasis ec5bf93c0 im isolierten gemeinsamen Integrationsstand, keine Mainintegration.

## Akzeptanz / lokale Pruefung
8 kleine Headlesschecks: Bounds/Breite/Tiefe, Radius/Sagitta, Gateanzahl/Bounds, Bodytiefe, gemeinsame Limbquelle und erste freie Gatezeile, unteres Band, stabile kollisionsfreie IDs sowie frische Datenkopien. Ein separater check-only Compile. Keine GPU-, Native-, Gefechts- oder grossen Tests, kein Commit/Push.

## Risiken / offene Punkte
Unverdrahtet: Der DTO ist weder Runtimezustand noch Zugangs- oder Blockadewahrheit. Spaetere Topologie und Renderprojektion muessen dieselbe Geometrie verwenden. Die Bandhoehe 32 bestimmt keine Rottenaufstellung oder Spawnfreigabe. Die Bogengroesse ist Kartenkomposition, keine reale Astronomie. Der produktive Anschluss an Combat und Reise folgt separat.

## Lokaler Beleg / Freeze
geometry_check.gd meldet 8/0 und runtime_wired=false. Helper check-only: Exit 0, keine Scriptfehler. Evidenz und Quellhashes: output/native_glut_maps/orbit_approach_layout_20261111. Nur neuer Helper und eigene Dokumente; keine bestehende Produktdatei oder Orbitmarker geaendert.
