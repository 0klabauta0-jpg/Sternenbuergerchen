# Orbit area canvas: unverdrahtete native 2D-Projektion

## Ziel / Ursache
Der neue lokale Orbit braucht eine lesbare native Ansicht seiner autoritativen Root-DTOs. Dieser Slice erstellt nur eine wiederverwendbare Canvas-Komponente, ohne Screen, Route oder Gameplayzugang zu aktivieren.

## Umfang / Nicht-Ziele
Nur neue scripts/ui/orbit_area_canvas.gd, diese Task und eigene QA. set_projection(snapshot, selected_craft_id='', body_visual={}) kopiert das Root-get_space_area_snapshot-DTO. Kamera und explizite Auswahl sind UI-Zustand. move_requested sendet ausschliesslich craft_id und axiales target_hex. Keine automatische Erstauswahl, Runtimeposition, Interpolation, Simulation, Autorisierung, Fremdschiffe, Ownerinstanz oder SceneTree-Suche. Keine bestehenden Dateien bearbeiten.

## Quellen / Grafikstatus
Root-DTO aus Source ff47d1c1e; Flight position_plane/heading_rad und echte footprint_cells. SpaceAreaGrid/StrategicHexGrid/HexGrid und OrbitApproachLayout bleiben Geometriequellen. Layoutmaske und Gates sind Offsetzellen, Flight und Moveziele axial. Lokale Karte 512x256; strategische Karte bleibt unberuehrt. docs/dev/graphics_reference_revision_contract.md und ORBITAL_APPROACH_MAPS_2026_11_11.md gelten. Vorhandene native StarMapCanvas/StarMapWorldView bilden 2D-Palette und projizierten 3D-Stilbezug; keine neue Bildgenerierung/Assets/3D-Modelle. Dies ist ein unverdrahteter nativer Darstellungs-Kandidat, keine visuelle Nutzerabnahme.

## Akzeptanz
Korrekte Koordinaten und inverse Picking-Projektion; tiefe DTO-Kopie; nur explizit passende Eigenschiffauswahl kann ID/Zelle emittieren; keine Auswahl bei fehlendem/fremdem DTO; gleiche Body-/Gategeometrie aus Layout. Pan/Zoom/Recenter rein UI. Grid nur sichtbarer Ausschnitt und adaptive LOD, keine 131072-Zellen-Komplettiteration; kein Process/Tick. Redraw nur bei Projektion/Kamera/Groessenwechsel. Acht bis zehn kleine Headlesschecks plus Einzelcompile; keine GPU/Mission/grosse Suite.

## Dateien / Risiken
Neue Komponente und output/native_glut_maps/orbit_area_canvas_20261111/{check.gd,check.log,compile.log,README.md,SHA256SUMS.txt}. Kein Produktcaller. Root muss jede Moveanforderung weiterhin gegen Bereich, Revision, Footprint, Belegung, Rotte und Gameplay pruefen. Canvasfilter sind keine Erlaubnis. Ohne native Bildpruefung keine Aesthetikbehauptung. Kein Commit/Sharedstatus.

## Ergebnis / Freeze
10 gezielte Headlesschecks bestanden, 0 Fehler; Einzelcompile unter Godot 4.6.2 Exit 0. Grid/Body/Gates liegen auf einer separaten statischen CanvasItem-Schicht; reine Shippositionsupdates behalten denselben Layout-/Maskcache und invalidieren nur die Shipprojektion. Kamera/Layout/Bodyvisual/Groesse invalidieren die statische Schicht. Bei Fit erscheint nur ein grobes Punktraster, maximal 5000 sichtbare Stichproben. Kein Renderingharness/PNG, daher keine native Bild- oder Aesthetikabnahme. Kein Provider und keine Produktverdrahtung.
