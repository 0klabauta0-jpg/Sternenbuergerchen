# Frontier-Grafik in Godot: erster Durchgang

> For agentic workers: use superpowers:subagent-driven-development for these
> bounded tasks. Every step remains tied to the approved image targets.

**Goal:** Die bestaetigten Basis-/Citizen-Bilder als zusammenhaengenden nativen
Godot-Ausschnitt und wiederverwendbare Grafikfamilie umsetzen.

**Architecture:** Neues visuelles Profil fuer die vorhandene TerrainMap3DView;
neue eigene Struktur-GLBs, originale Kenney-Astronauten und ein nativer
Referenzausschnitt. Die anschliessend ausdruecklich beauftragte Hex-Umstellung
hat einen eigenen versionierten Vertrag und Plan; bestehende Karten bleiben
im bisherigen Format.

**Tech Stack:** Godot 4.6.2, GDScript, Blender 5.2.3, glTF.

**Spec:** docs/tasks/ART_2026_11_01_engine_graphics_pass.md

## Schritte
- [x] Neue eigene Habitat-/Werkstatt-/Versorgungsmodelle aus den bestaetigten
  Vorlagen erstellen; editierbare Quelle, GLB und Geometrie-QA ablegen.
- [x] Nach der Nutzerkorrektur vier originale Kenney-Astronauten einsetzen;
  eigene Figurenstudien verwerfen. Originalformen/-texturen, Rig-/Poseprobe,
  frischer GLB-Roundtrip und native Importkontrolle dokumentieren.
- [x] Reines Grafikprofil an den vorhandenen Terrain-3D-View anschliessen:
  helle warme Bodenfamilie, matte Flaechen, gerichtete Licht-/Felsmassen.
- [x] Nativen Preview-Ausschnitt mit den neuen Modellen, Kamera/Zoom und
  Bewegung/Pose bauen; gleichzeitig Quellen-/Modellzuordnung festhalten.
- [x] Nichtmutation der Kartenfakten durch Grafik und Profilwechsel pruefen;
  relevante bestehende 3D-/Navigationsverifier ausfuehren.
- [x] Native Ansichten oeffnen und sichtbare Fehler korrigieren; sechs echte
  Ansichten fuer die HTML-Uebergabe aufnehmen.
- [ ] Abschliessende HTML-Uebergabe, Metadaten und Git-Push.

## Pruefschwerpunkte
Mensch/Tuer-Massstab; Figurenfuesse und Handkontakte; ueberdeckte begehbare
Flaechen; gemeinsame Materialressourcen; Profilwechsel ohne veraltete Caches.

## Hex-Pruefung
Den vorhandenen Pfadgraphen und Diagonalkosten gegen Code pruefen. Vorteile
gleich langer Hexnachbarn und Kosten einer Migration schriftlich darstellen.
Freier gezeichneter Boden und diskreter Navigationsgraph koennen zusammen
bestehen. Die Entscheidung fuer Hex wurde anschliessend ausdruecklich getroffen.
Die erste Integration steht in `2026-11-01-hex-foundation.md`; eine vollstaendige
Migration von Altinhalten, Editor und sechsseitigen Mauern ist noch offen.
