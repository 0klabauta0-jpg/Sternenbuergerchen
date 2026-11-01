# Hexfelder fuer den nativen Basis-Ausschnitt

> For agentic workers: use superpowers:subagent-driven-development for the
> independent navigation, visual, model and verification packages.

**Goal:** Nutzerentscheidung Hex mit gemeinsamem Koordinaten-/Graph-/Grafik-
Vertrag im neuen nativen Basis-Ausschnitt umsetzen.

**Architecture:** Versionierte HexMapData/Registry plus reiner HexGrid-Helfer;
bestehende A*/HPA und SimulationRoot konsumieren die neue Topologie.
TerrainMap3DView zeichnet und pickt dieselben Hexfelder. Legacy square8 bleibt
ein gekennzeichneter Kompatibilitaetspfad.

**Tech Stack:** Godot 4.6.2, GDScript, axial/cube hex coordinates, Blender GLBs.

**Spec:** docs/tasks/HEX_2026_11_01_foundation.md

- [ ] HexGrid, MapData/Registry und Load/Save-Vertrag einfuehren; Roundtrip,
  negative Koordinaten und Legacy-Fakten pruefen.
- [ ] A*/HPA auf sechs Hexnachbarn und passende Kosten umstellen; Hindernisse,
  Hoehen/Rampen und Legacy-Regressionen pruefen.
- [ ] SimulationRoot im Hexmodus mit physischem Streckenmass bewegen lassen;
  sechs gleich lange Richtungen messen. Legacy-Verhalten separat erhalten.
- [ ] TerrainMap3DView: Hexoberflaechen, Koordinatentransform, Auswahl und Picking;
  gebatchte Materialien/Geometrie und Profilwechsel mitpruefen.
- [ ] Freigegebene Grafikfamilie als nativen Basis-Ausschnitt auf Hex platzieren;
  Gebaeude-/Wegbelegung, Citizen-Bewegung und Ansichten oeffnen.
- [ ] Relevante bestehende Verifier, frische Import-/Bildbelege und HTML.
  Stand und verbleibende Altinhaltsmigration in getrennten Commit-Paketen sichern.
