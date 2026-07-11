# TASK_1124 - Connected Contact World Root and Compositing Residue Isolation

## Ziel / Problem
Im echten BLUE-/GOLD-Erstkontakt bleibt rechts neben der gerahmten Karte ein weisser Doppelblock sichtbar. TASK_1123 hat abgeschlossene leere Dropship-Visuals, normale Zielwelt-Meshes, registrierte Surface-/HeightEdge-Zellen und einfache Peer-Canvas-Sichtbarkeit als direkte Ursache ausgeschlossen.

## Sinnhaftigkeit / Ursache
Das Produktbild wird aus mehreren Lobby-, CanvasLayer- und SubViewport-Schichten zusammengesetzt. Ohne einen Capture direkt aus der Ziel-SubViewport-Textur bleibt unklar, ob der Block bereits in der 3D-Welt gerendert wird oder erst beim Root-Compositing entsteht. Eine spekulative Runtime-Loeschung koennte gueltige Stations-, Transport- oder Multiplayer-Visuals entfernen.

## Umfang
- BLUE und GOLD erhalten zusaetzlich zum Produktbild einen reinen Ziel-World-Capture direkt aus der jeweiligen `SubViewport`-Textur.
- Pixelbelegung im auffaelligen rechten Bereich wird zwischen Produkt- und World-Capture verglichen.
- Bei World-Ursprung wird der erzeugende 3D-Root/Visualtyp isoliert; bei Compositing-Ursprung wird nur der Capture-/Canvaspfad korrigiert.
- Der Fix erhaelt aktive Dropships, Map-Assets, Fireteam-Proxies und andere Peer-Simulationen.

## Nicht-Ziele
- Kein pauschales Culling entfernter Kartenobjekte.
- Keine Aenderung an SimulationRoot, Combat, Pathfinding, Formation oder Netzwerkpayload.
- Kein per-frame SceneTree- oder Meshscan.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_1123_connected_first_contact_unit_formation_world_residue_readability.md`
- `docs/tasks/TASK_1119_connected_first_contact_three_peer_product_visual_playtest.md`
- `docs/ARCHITECTURE.md`

## Akzeptanzkriterien
- Reine BLUE-/GOLD-World-Captures sind Full HD und eindeutig derselben Peer-Perspektive zugeordnet.
- Der Doppelblock ist per Pixelvergleich eindeutig World oder Root-Compositing zugeordnet.
- Der erzeugende Pfad ist benannt und mit einem RED/GREEN-Verifier abgesichert.
- Finale Produktcaptures enthalten keinen unverbundenen Doppelblock.
- Multiplayer-, Dropship-, Formation- und Performance-Gates bleiben gruen.

## Betroffene Dateien
- `scripts/tests/task_1119_connected_first_contact_three_peer_product_visual_playtest.gd`
- `scripts/tests/task_1124_connected_contact_world_root_compositing_residue_isolation.gd`
- Erzeugender Visual-/Capturepfad nach Diagnose
- Status-, Roadmap- und HTML-Berichtsdokumentation

## Lokale Pruefung
- TASK_1124 headless nach erzeugten Real-Window-Captures.
- TASK_1119 headless und Real Window je BLUE/GOLD.
- TASK_1123, TASK_1120, TASK_1104 und TASK_222.
- `git diff --check`.

## Risiken / offene Punkte
Root-Viewport-Screenshots koennen rendererabhaengige Dirty-Regionen enthalten. Der World-Capture muss deshalb direkt aus der Ziel-SubViewport-Textur stammen und fuer belastbare Belege im Compatibility-Renderer wiederholt werden.

## Ergebnis
- Ursache war kein Kartenasset und kein Root-Canvas: Alle taktischen Peer-`SubViewport`s teilten im Einprozess-Produktlauf dieselbe `World3D`.
- `TerrainMap3DView` setzt fuer neu erzeugte und bereits vorhandene taktische SubViewports jetzt `own_world_3d = true`.
- Der RED/GREEN-Verifier instanziert zwei Missionen und prueft getrennte `World3D`-Instanzen.
- BLUE und GOLD wurden im Compatibility-Renderer jeweils als Produktbild und direkt aus der Ziel-SubViewport-Textur aufgenommen.
- Der ehemalige Residue-Bereich enthaelt in allen vier frischen Belegen `0` Fremdpixel.

## Verifikation
- TASK_1124: 11/11.
- TASK_1119: 27/27 headless, 33/33 BLUE Real Window, 33/33 GOLD Real Window.
- TASK_1123: 9/9; TASK_1120: 11/11; TASK_1122: 11/11; TASK_1104: 31/31; TASK_222: 82/82.
- Sichtpruefung: kein weisser Doppelblock; verbleibender UX-Befund ist die enge lokale Unit-/Contact-Ballung am Kartenrand.
