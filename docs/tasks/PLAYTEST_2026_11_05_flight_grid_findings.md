# Flug- und Hexdarstellung im Vollbild-Spielpass

## Ziel / Problem und belegte Ursache
Der Hexpfad in `TerrainMap3DView._add_hex_grid_lines()` baut feste schmale
Weltquads und einen noch schmaleren hellen Kern. Beide haben harte Kanten und
keine Pixelabdeckung oder Abstandsdämpfung. In Fernsicht ist Subpixel-Flimmern
damit plausibel; die native Vorheraufnahme bleibt der sichtbare Beleg.
`_world_to_air_layer_3d_position_for_payload()` ignoriert den vorhandenen
Flugstatus und setzt jede Phase auf dieselbe Terrain-Clearance von 1.28.
Auch `landed`, `unloading` und `complete` schweben dadurch dauerhaft.

## Gewünschtes Verhalten vor der Codeänderung
- Ein einmal gebautes, depth-tested Hexnetz hat weiche Pixelkanten und in
  Fernsicht weniger Kontrast. Kein heller Subpixelkern und kein Kamerarebuild.
- `inbound` zeigt über der tatsächlichen Route einen klaren Reiseflug und
  einen sanften Abstieg nahe der echten LZ. `landed`, `unloading`, `complete`
  berühren den Boden. `outbound`/`departing` steigen von der LZ wieder auf.
- Diese Darstellung liest echte Position, LZ und Phase. Sie verschiebt weder
  Runtime-Actors noch Timer, Landerechte, Passagiere oder Terrainfakten.
- Ohne bekannten Flugstatus bleibt die explizite Alt-Clearance kompatibel.
- Schub gehört zur sichtbaren fliegenden Quelle und endet bei Bodenkontakt,
  Unsichtbarkeit, Ownerentfernung oder Mapwechsel. Kein neuer Gameplay-Actor.
- Drohnen werden erst nach eindeutiger Zuordnung des tatsächlich sichtbaren
  Objekts über dessen reale Runtimeidentität angebunden. `enemy_robot` ist im
  aktuellen Mapping lediglich ein geplanter menschlicher Fallback.

## Umfang und Nicht-Ziele
Nur Hexmaterial/-quads und lesende Dropship-Pose/-Schubdarstellung mit kleinen
Helpern. Keine Flugmechanik, Actorpositionen, FoW-Freigabe, Transportdauer,
Schaden, Modellrevision, neue Gegner oder Simulationoptimierung.

## Dokumente
`PLAYTEST_2026_11_05_fullscreen_ux_visuals.md`,
`graphics_reference_revision_contract.md`, `flight_altitude_layer_contract.md`,
`dropship_lz_target_accuracy_contract.md`, `terrain_truth_visual_audit_contract.md`.
Aktive Cutlass-Quelle bleibt `astra_refinement_03`, SHA-256
`21484195affa66a1bc503f34b20ae561312057e46e077250e8a772b6881e6daf`.
Die Shader-Builtins und Renderoptionen wurden gegen die
[Godot-4.6-Spatial-Shaderreferenz](https://docs.godotengine.org/en/4.6/tutorials/shaders/shader_reference/spatial_shader.html)
geprüft. Die vier Düsenanker stammen aus den ausgewerteten Ref03-Bounds in
`art/frontier_illustrated_20261101/ships/pass05_astra_ultra/refinement_03/cutlass/review/final/evaluated_proportions.json`;
die bestehende Geometrie und ihre Materialien bleiben erhalten.

## Akzeptanz / lokale Prüfung
Gezielter Verifier zuerst auf Originalsource RED; anschließend Legacy-Air-
Clearance, monotone echte Annäherung/Entfernung, Landekontakt, FoW-/Ownergrenzen
und Grid-Shadervertrag prüfen. Root führt alle Godotläufe seriell aus.
Native gleiche Vollbildkamera in naher/ferner Ansicht und echte
Inbound-/Landed-/Outbound-Sequenz ansehen. Strukturtests ersetzen diese
Sichtprüfung oder das Nutzerurteil nicht.

## Dateien und Risiken
`scripts/terrain/terrain_map_3d_view.gd`, kleine Flight-/Gridhelper und Shader,
`scripts/tests/playtest_20261105_flight_grid_verifier.gd`.
Reine visuelle Flughöhe folgt der lokalen Oberfläche; an diskreten
Höhenstufen bleibt ein sichtbarer Übergang möglich. Exakte Drohnenzuordnung
und native Materialwirkung bleiben bis zur Rootaufnahme offen.

## Strukturstand 05.11.2026
Root hat auf Originalsource den gezielten Verifier mit **2 PASS / 8 FAIL**
ausgeführt; die acht Fehler betreffen genau Reiseflughöhe, Abstieg,
Bodenkontakt, Start und fehlendes AA-Material.
Nach Umsetzung und zwei expliziten GDScript-Typkorrekturen besteht derselbe
Flug-/Gridpfad mit zusätzlichen begrenzten Helperprüfungen **21/21**.
Evidence: `output/playtest_20261105/visual_red/20261105T062529Z-c624e6a0/flight_grid.log`
und `output/playtest_20261105/visual_green_retry/20261105T063718Z-d0844519/flight_grid.log`.
Beide Läufe stammen vom Root; kein eigener paralleler Engineprozess.
Der GREEN-Report bestätigt isolierte Nutzerdaten und unverändertes normales
Roster einschließlich Bytes, Länge und Schreibzeit. Der aktive Cutlass-GLB
wurde zusätzlich aktuell per SHA-256 gegen den oben genannten Pin geprüft.

Die neue Servicedrohnen-API ist noch kein neuer Runtime-Drohnenactor. Root
kann sie an einen sichtbaren dekorativen Basis-Prop anbinden. Native
Vollbild-Sichtprüfung und Nachbar-Air-/Hex-Gates folgen im gemeinsamen
Rootlauf; Shaderquell- und Zahlenprüfungen gelten nicht als GPU-Bildbeweis.

## Nativer Vollbildbeleg
Der normale Menü-/Basis-/Einsatzpfad unter
`output/playtest_20261105/native_visual_3440/20261105T075819Z-078ae826`
ist **77/77**, Exit 0 ohne Enginefehler, Windows/Vulkan/Forward+,
physisches und logisches **3440x1440**-Vollbild bei **1x**.
Die Captures `10_real_descent`, `11_real_ground_contact` und
`12_real_takeoff` stammen aus tatsächlich laufenden Transportphasen;
keine Actorposition, HP, Timer oder Phase wurde gepatcht. Nah-/Fernkamera
und Gridbilder sind ebenfalls in dieser normalen Sequenz erfasst.
Root hat die sichtbare Abstieg-/Kontakt-/Startfolge bestätigt. Der im
Kontaktbild entdeckte kurz eingeblendete Legacy-HUDtext hat einen separaten
UI-Writerfix und eine eigene 231/231-Regression; er stammt nicht vom Flugpfad.
Die ruhige Fernansicht ist ein nativer Bildbeleg, keine allgemeine FPS-
oder gestalterische Nutzerfreigabe.
