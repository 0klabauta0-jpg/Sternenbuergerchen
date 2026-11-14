# Native Hex-Sichtlinie: begrenzter Geometriekern

Zum Task [Native Terrainvorbereitung und Kampf-/FoW-Sicht](../tasks/NATIVE_TERRAIN_VISIBILITY_2026_11_14.md).

## Zuständigkeit und Sprachgrenze

`LineOfSightSystem` verwendet standardmäßig `NativeVisibilityKernel` aus der
bestehenden Navigation-GDExtension, um die geordnete Hexzellliste einer Sichtlinie
zu berechnen. C++ erhält zwei `Vector2i` und liefert ein `Array[Vector2i]`.
Es gibt keine Terrainkopie, keinen Terraincache, keine Registryreferenz und keine
GDScript-Callbacks innerhalb der nativen Schleife.

Der bisherige GDScript-LOS-Leser entscheidet weiterhin über vorhandene Zellen,
aktuelle `blocks_los`-/Objekthöhen-Overrides, Endpunkthöhen und den ersten
tatsächlichen Blocker. `HexVisibilityQuery` behält Reichweite und Blickkegel;
`CombatVisibilityCache` behält seine ticklokalen Keys, Grenzen und Zähler.
FoW behält seine Beobachter, Dirty-Jobs, Arbeitsbudgets und atomare Veröffentlichung.
Diese Optimierung führt keinen neuen Gameplaybesitzer ein.

## Exakte Regeln

- Die Zellfolge entspricht `HexGrid.line`: kanonisch sortierte Endpunkte,
  `Vector2.lerp`, derselbe kleine Nudge und dieselbe Cube-Rundung; eine umgekehrte
  Anfrage erhält die umgekehrte Zellliste. Auch negative Koordinaten bleiben gültig.
- Quelle wird nie selbst zum Blocker. Die Zielzelle ist standardmäßig ausgenommen;
  `include_target` bleibt für Vorschauen ausdrücklich verfügbar.
- Explizite Endpunkthöhen bleiben Floatwerte einschließlich H+0,5. Der vorhandene
  Vergleich gegen beide Endpunkthöhen wird nicht durch Navigationsexposure-LOS
  oder eine gerundete Höhenklasse ersetzt.
- Jede tatsächliche LOS-Auswertung liest die aktuellen Tile-/Readerwerte.
  Direkte Tileänderungen ohne Registryrevision und benutzerdefinierte Reader
  werden durch diese Optimierung nicht zwischengespeichert. Bereits bestehende
  Resultatcaches behalten ihren eigenen unveränderten Gültigkeitsvertrag.
- `square8` einschließlich gerichteter Wandsegmente verwendet vollständig den
  bisherigen GDScriptpfad.

## Fallback und Diagnose

Die Erweiterung wird pro LOS-Instanz bei der ersten Hexanfrage geprüft. Fehlt
`NativeVisibilityKernel` oder dessen Methode, bleibt die ursprüngliche
GDScriptberechnung aktiv. Native Eingaben außerhalb ±1.000.000 je Koordinate oder
mit mehr als 65.536 Schritten werden ohne native Allokation abgewiesen; eine leere
oder unpassende Rückgabe wählt ebenfalls den bisherigen Pfad. Diese Grenzen
schränken die öffentlich akzeptierten LOS-Eingaben nicht neu ein.

`set_native_visibility_enabled(false)` wählt pro Instanz die unveränderte
GDScriptreferenz für Diagnose und Vergleiche. Der Schalter ist kein gespeicherter
Spielzustand. `get_native_visibility_snapshot()` meldet die tatsächlich erfolgten
nativen Aufrufe, Fallbacks und den Kern `stateless_hex_line`; bloß vorhandene
DLL-Dateien gelten nicht als Nachweis nativer Ausführung.

## Build und Prüfung

`native_visibility.{h,cpp}` wird über das bestehende
`native/navigation/SConstruct` und dessen gepinnten `godot-cpp`-Build gebaut.
Registrierung und Bibliothek bleiben Teil der vorhandenen Navigationserweiterung.
Der belegte Binärumfang ist Godot 4.6.2/Windows x64; weitere Plattformen benötigen
einen eigenen Build und eigene Prüfung. Die strikten Float-Buildoptionen bleiben
erhalten, damit die Rundungsfolge nicht umgeordnet wird.

`native_visibility_verifier.gd` vergleicht Zelllisten, erste Blocker, Halbwerthöhen,
Zielregeln, aktuelle Reader, Squarewände und bestehende Cacheergebnisse. Mit
`--require-native=true` verlangt er tatsächliche native Aufrufe; ohne DLL prüft
derselbe Verifier den Fallback. `native_visibility_benchmark.gd` misst den
aktuellen gecachten Kampflesepfad und komplette FoW-Full-/Dirty-Jobs getrennt.
Vorbereitung, native Übergabe und Rückgabe bleiben innerhalb der passenden
Messgrenzen. Eine schnelle Zellliste ist allein weder ein FoW-Gesamtgewinn noch
ein FPS-, Grafik-, Kampagnen- oder Multiplayernachweis. Endgültige Rohmessungen
und ihre Einschränkungen gehören in den QA-Bericht des Tasks.
