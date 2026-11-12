# Modulare Basis: Hexboden, schlanke Waende und echte Tueroeffnungen

## Aktueller Stand

Diese Nutzerkorrektur ersetzt den Grafikstand unter
`docs/qa/modular_base_visual_20261112/`: keine quadratischen Bodenplatten mehr,
Wanddicke 16 statt 32 cm und nur die im Raumplan bestaetigten Tueroeffnungen.
Die alten Aufnahmen bleiben dort als historische Revision erhalten.

Die einzelne Wand liegt mittig auf der 6-m-Modulgrenze, bei +/-3,0 m mit
Aussenkante +/-3,08 m. Sockel, Rahmen und eingelassene Wanddetails bleiben
vollstaendig innerhalb dieser schlankeren Huelle. Die Navigation besitzt
weiterhin ihren eigenen Sicherheitsabstand; die Grafik aendert ihn nicht.

Der Innenboden zeigt **die tatsaechlichen groben Spielfeld-Hexzellen**.
`TerrainMapData.get_tile_at_grid()` liefert die vorhandenen Zellen;
`TerrainMap3DView._grid_to_3d_position()` und die gemeinsame `HexGrid.corners()`-
Geometrie liefern ihre Kanten. Die Darstellung schneidet diese Weltkanten am
Raumrand ab und verwendet dieselbe Kantenmaterialroute wie das Aussengelaende.
Raumrotation dreht deshalb nicht das Welt-Hexraster. Keine neue Feldbelegung,
Navigation oder Gameplay-Wahrheit; die feinere Basisnavigation bleibt separat.

Die Darstellung liest `plan.rooms[].doors` in lokaler N/E/S/W-Reihenfolge.
Geschlossene Seiten werden vollstaendig ausgefuellt; Schwellenmarkierungen
erscheinen nur bei offenen Tueren. Historische Belege ohne Tuerfeld behalten
den vom Owner definierten Zustand mit vier Oeffnungen. Neue Baustaende und
Tuerkommandos stammen vom parallel implementierten Runtime-/Supply-Owner.

Die verschobenen Bettplaetze am Rand und ihre Schlaf-/Wachpositionen stammen
ebenfalls vom gemeinsamen Geometrie-/Bettowner. Der Visualhelper verschiebt
keine Betten. Quelle, Massstab und Materialien der Originalbetten sind erhalten.

## Aufbau und gezielte Pruefung

Pro Modul bleiben zwei gecachte Meshes fuer Deck und Waende; der Hexboden
ergaenzt genau ein gebatchtes Kantenmesh. Wand-/Deckcaches sind nach Typ und
Tuerzustand getrennt. Hexkanten entstehen beim bestehenden Planwechsel;
keine per-frame Rekonstruktion oder SceneTree-Suche.

`scripts/tests/modular_base_room_visual_verifier.gd`: **39 bestanden, 0 Fehler**,
Exit 0, im finalen Lauf keine Script- oder Enginefehler. Enthalten sind:

- Huellenabmessungen und saemtliche Wanddetail-Vertices innerhalb der 16-cm-Wand.
- Mesh-Strahlpruefung der tatsaechlich offenen/geschlossenen N/E/S/W-Seiten.
- Nur vorhandene MapData-Zellen fuer das grobe Hexraster.
- Identische Weltkanten bei 0 und 90 Grad Raumrotation.
- Ressourcenwiederverwendung, drei Meshes mit Hexprojektion, keine Collider.
- 20-mm-Figurenprojektion auf bestaetigten Modulen, urspruenglicher Boden daneben.

Ein erster Testlauf hatte noch die alte 32-cm-Huellenannahme. Danach wurden ein
Test-Typfehler und der fehlende SceneTree-Anschluss der Testkamera korrigiert.
Die oben genannten 39/0 beziehen sich auf den anschliessenden sauberen Lauf.

## Native Bilder und Befund

`scripts/tests/modular_base_room_visual_capture.gd`: **PASS, Exit 0**.
Godot 4.6.2, OpenGL Compatibility, NVIDIA RTX 4070 Ti SUPER, 1280 x 720,
isoliertes APPDATA. Der mitgelieferte Runner erstellt einen Windows-Desktop,
aktiviert ihn niemals und setzt zusaetzlich `SW_HIDE`. Kein Maus-/Desktop-
Eingriff oder sichtbares Fenster. Zwei bekannte Szenen-UID-Warnungen verwenden
erfolgreich den Textpfad; keine Script-/Shaderfehler im finalen Lauf.

Alle acht Aufnahmen unter `native/` wurden geoeffnet und verglichen:

- `three_modules_front_posefix.png` / `three_modules_rear_posefix.png`:
  Schlafraum–Gang–Lager, Kameraweite 21, Yaw 24/204 Grad. Hexkanten passen
  ueber Raumgrenzen zum Aussengelaende; Wandsilhouette deutlich schlanker.
- `door_added_r0.png` / `door_removed_r0.png`: gleiche Kameraweite 8 und
  gleicher Blick. Echte `campaign_set_room_door`-Kommandos oeffnen und
  schliessen die suedliche Raumseite; die native Geometrie folgt sichtbar.
- `sleeping_original_beds_r0_posefix.png` / `awake_original_beds_r0_posefix.png`
  sowie entsprechende `r1`-Bilder: echte Figur erreicht die wandnahen Betten,
  liegt laengs auf der Matratze und steht nach Aufwachen auf freier Bodenflaeche.
  Beide Aufwachposen haben X/Z-Neigung 0/0.

Der Capture setzt nur im isolierten Testprofil Guthaben; Bau, Bettkauf,
Tueraenderung und Personenaktionen laufen ueber die echten Commands.
Quellen-/Referenz-SHA-256 und Bildhashes stehen im Manifest. Die 2D-Zielreferenz
`01_rostgrenze_cutaway.png` und das bestehende Habitat-Materialbild bleiben
zugeordnet; keine neue generierte Grafik und keine veraenderte Original-GLB.

## Reproduktion und Grenzen

Aus dem Projektroot:
`python docs/qa/modular_base_hex_revision_20261112/hidden_desktop_run.py res://scripts/tests/modular_base_room_visual_capture.gd`.
Die Rohbilder werden nach `output/modular_hex_native/` geschrieben.

Keine persoenliche Gestaltungsfreigabe oder breite FPS-/GPU-Abnahme. Das Raster
zeigt das grobe Spielfeld, nicht die feinere Bewegungsdiskretisierung im Inneren.
Diese Grafikpruefung ersetzt keine komplette Navigation-/LOS-/Save-Abnahme.
Die im Bild sichtbare UI gehoert zum parallelen Root-Task und ist keine neue
UI-Implementierung dieses Teilauftrags. Arbeit weiterhin auf dem unintegrierten
Task-Branch; kein eigener Commit, Merge oder EXE-Export durch den Grafikagenten.
