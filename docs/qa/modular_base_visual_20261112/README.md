# Modulare Basis: native Grafikprojektion 12.11.2026

Historische erste Revision. Die nachfolgende Nutzerkorrektur mit groben
Spielfeld-Hexen, 16-cm-Waenden und bestaetigten Tueroeffnungen steht unter
`docs/qa/modular_base_hex_revision_20261112/`; die Bilder dieses Pakets bleiben
als vorheriger Modellstand erhalten.

## Ziel und Ergebnis

Der Arbeitsstand ersetzt die leeren, weitgehend weissen Raumkaesten durch
Cutaways mit den **tatsaechlichen Materialien des bestehenden Habitat-GLB**:
warme Wandpaneele, dunkle Rahmen, orange Baender, unterteilte Deckplatten.
Schlafraeume erhalten eine flache Ruhezone und Wandpaneele, Lager eingelassene
Wandfaecher, Gaenge blaue Wandfelder und flache Leitmarkierungen. Die grossen
Raeume sind weiterhin sparsamer eingerichtet als die Referenz.

`modular_base_room_visual.gd` ist ausschliesslich Darstellung. Der bestehende
Kapazitaets-/Plansignaturpfad baut sie bei Aenderungen auf. Pro Raum entstehen
zwei gebatchte MeshInstances und eine Bodenschrift; die Geometrie wird je Typ
einmal erzeugt und danach wiederverwendet. Materialressourcen kommen direkt
aus dem unveraenderten aktiven Habitat. Kein per-frame Neuaufbau.

## Gemeinsame Geometrie und Navigation

Der Ursprung wird aus `modular_base_geometry.gd` gelesen (im geprueften Stand
15/36). Modulraster 6 m; aeussere bisherige Wandhuelle 6,22 x 1,45 x 6,22 m;
alle vier Tuerdurchlaesse bleiben 1,44 m breit. Pfosten ersetzen den betreffenden
Paneelabschnitt, damit deren Stirnflaechen nicht koplanar flimmern.

Alle Wanddetails einschliesslich der flachen Lagerfaecher liegen im bestehenden
gesperrten Wandband ab `WALL_INNER=2.72`. Es gibt keine frei stehenden Kisten,
Regale oder neuen Collider in begehbaren Bereichen. Die Faecher sind visuelle
Wandgliederung, keine neuen Inventarbehaelter.

Der Deckboden liegt sichtbar bei 20 mm ueber Terrain. Kleine Farbmarkierungen
liegen wenige Millimeter darueber. `_standing_y()` projiziert Figuren auf
denselben 20-mm-Boden; ein durch die bestehende Plansignatur gepflegter
Zellcache vermeidet einen Raumsuchlauf pro Figur. Navigation und gespeicherte
Positionen werden nicht veraendert. Originalbetten, deren Transformationen
und Schlafhoehen bleiben bei den bestehenden Bett-Ownern und Meshableitungen.

## Referenz und Bildstatus

- 2D-Ziel: `docs/reports/assets/grafik-2026-11-01/references/current/01_rostgrenze_cutaway.png`.
- Modell-/Materialreferenz: `docs/qa/base_real_personnel_20261109/habitat_cutaway_01_material.png`.
- Aktive Originalquelle: `Assets/curated/base_access_20261109/habitat_cutaway_01.glb`.
- `native/original_beds.png`: unveraendertes Habitat unter dem aktuellen Basislicht.
- `native/connected_rooms.png`, `native/modular_bed.png`: echte produktive
  Schlaf-/Lagerprojektion mit einem separat gekauften Originalbett.
- `native/three_modules_front.png` und `native/three_modules_rear.png`: gleiche
  Dreiergruppe Schlafraum–Gang–Lager, Kameraweite 21, Yaw 24 bzw. 204 Grad.
- `native/sleeping_original_beds.png`: Kameraweite 8, zwei separat gekaufte
  Originalbetten, echte Person nach abgeschlossenem Lauf mit `status=sleeping`;
  historischer Stand vor dem unten beschriebenen Posefix.
- `native/sleeping_original_beds_r0_posefix.png` und
  `native/sleeping_original_beds_r1_posefix.png`: derselbe Raum bei Rotation
  0 und 90 Grad nach dem parallel eingebrachten Posefix.
- `native/awake_original_beds_r0_posefix.png` und
  `native/awake_original_beds_r1_posefix.png`: echte Aufwachaktionen danach.
- `native/three_modules_front_posefix.png` und
  `native/three_modules_rear_posefix.png`: aktuelle Dreiergruppe nach dem Posefix.
- `native/build_ui.png`: bestehende reale Bauoberflaeche; diese Grafikrevision
  gestaltet die Bauoberflaeche nicht um.

Alle genannten nativen Aufnahmen wurden geoeffnet. Die Materialien stimmen mit
dem Originalhabitat im gleichen Basislicht ueberein; die helle Wandwirkung ist
auch dort sichtbar. Pfosten-/Bodenflimmern aus der ersten Probe ist korrigiert.
Die ehemalige provisorische Darstellung wurde vor der Revision angesehen;
dieses Paket enthaelt keinen identischen Vorher/Nachher-Geometrievergleich.
SHA-256 fuer Referenzen, Quellen, Pruefskripte und Aufnahmen steht im Manifest.

## Lokale Pruefung

- `scripts/tests/modular_base_room_visual_verifier.gd`: **27 bestanden, 0 Fehler**,
  Exit 0. Unveraenderte Eingabe, Material-/Meshcache, 2 Meshes je Typ,
  keine Collider, Huellenabmessungen, alle Shell-Vertices innerhalb der
  bestehenden Wandmaske, freie Tuerbreite, 20-mm-Figurenprojektion und
  unveraenderte Standhoehe ausserhalb bestaetigter Module.
- `scripts/tests/campaign_modular_native_capture.gd`:
  `MODULAR_NATIVE_CAPTURE_PASS`, Exit 0.
- `scripts/tests/modular_base_room_visual_capture.gd`:
  `MODULAR_ROOM_VISUAL_CAPTURE_PASS`, Exit 0. Echte Bau-/Bettkommandos und
  echte Personenankunft; nur Guthaben im isolierten Captureprofil gesetzt.
  Der erweiterte finale Lauf prueft Schlafen und Aufwachen fuer Raumrotation
  0/1; die gemessene X/Z-Neigung nach Aufwachen ist beide Male 0/0.

Der parallel eingebrachte Bett-Posefix uebernimmt den Originalabstand zwischen
Modellpivot und Bettende (0,36 m) und verhindert, dass Bewegungs-Yaw die
Schlafausrichtung ueberschreibt. Die vier finalen Nahaufnahmen wurden geoeffnet:
Figur in beiden Rotationen laengs auf der Matratze mit Kopf am Kissen;
nach Aufwachen wieder aufrecht auf freiem Boden. Keine Modifikation der
Originalbettgeometrie. Das im selben Lauf sichtbare Basisbefehlsband stammt aus
einer parallelen UI-Ueberarbeitung und ist keine Layoutabnahme dieses Pakets.

Godot 4.6.2, OpenGL Compatibility, NVIDIA RTX 4070 Ti SUPER, 1280 x 720.
`hidden_desktop_run.py` im Paket wird aus dem Projektroot aufgerufen, etwa mit
`python docs/qa/modular_base_visual_20261112/hidden_desktop_run.py res://scripts/tests/modular_base_room_visual_capture.gd`.
Der Runner erzeugt einen eigenen Windows-Desktop, aktiviert ihn niemals und
setzt zusaetzlich `SW_HIDE`. Kein Mausklick, kein sichtbares Fenster, isoliertes
APPDATA. Zwei vorhandene TSCN-UID-Warnungen verwenden den korrekten Textpfad;
keine Script-/Shaderfehler im finalen Lauf.

## Grenzen und offene Punkte

Keine persoenliche Gestaltungsfreigabe, keine breite FPS-/GPU-Messung oder
Performanceabnahme. Die gezielte Batch-/Cachepruefung belegt nur den Aufbau.
Freie Lagerregale und weitere Moebel brauchen zuvor passende autoritative
Hindernisse. Der Gang verwendet bewusst den bestehenden 6-m-Modulgrundriss.
Der anfaengliche Posebefund ist durch den parallelen Bett-Teilauftrag behoben
und in den finalen Bildern technisch bestaetigt. Die gemeinsame Gameplay-/Save-/Migrations-
Regression gehoert zum Root-Task. Arbeit auf dem bereits unintegrierten
`task/campaign-help-recruitment-20261112`, kein eigener Commit, Main-Merge oder EXE.
