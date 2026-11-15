# Schwere Ruestung R08: neue Teile aus Skriptquelle (15.11.2026)

## Ziel
Die schwere Ruestung soll im Spiel dem bestaetigten Referenzbogen
`Referenzbilder_Bestaetigt/01_Ruestungen/03_Schwer_Mehransichten.png` (vorne, hinten, Seite, oben) entsprechen:
gewoelbte Helmkuppel mit Stirnwulst, dunklem Visierschlitz, Maske mit zwei Atemschlitzen und Kinnblock, runde Ohrscheiben;
dicker dunkler Kragenring mit kleinen Orange-Marken; Schulterplatten als drei gestapelte Sandplatten, die AUF der Schulter sitzen;
sandfarbene Schild-Brustplatte auf dunkler Brust mit zwei Riemenbloecken; Guertel mit vier dunklen Taschen; hinten drei sechseckige
Sandplatten in dunklem Rahmen; gegliederte dunkle Oberarme; Sand-Unterarmschalen mit einem Orange-Schlitz; grosse hellgraue Handschuhe;
Sand-Oberschenkelschalen seitlich; grosse Sand-Knieplatten mit zwei Schlitzen; dunkle Schienbeinbloecke mit einer Orange-Marke;
klobige Stiefel mit grauer Zehenkappe.

## Ursache
Messung in `RUESTUNG_SCHWER_VERGLEICH_2026_11_15.md`: kastiger, zu tiefer Helm ohne Maske, Rumpf 27 % zu flach mit flachen Platten,
Arme zu duenn mit kleinen schwarzen Haenden, kleine Knieplatten, Schulterplatten wie flache Fluegel, Farben zu blaeulich und zu hell,
viel zu wenig Dunkelgrau. Fuer die Teile gibt es keine editierbare Quelle, nur exportierte GLBs.

## Umfang
- Neues Generator-Skript `art/ruestung_schwer_r08_20261115/build_parts.py` (bpy) als editierbare Quelle.
- Es schreibt die schweren Teile mit den bisherigen Dateinamen in den neuen Ordner
  `Assets/curated/personnel/armor_r08_schwer_20261115/`:
  `helmet_heavy`, `collar`, `torso_heavy`, `pelvis_heavy`, `pauldron_heavy`, `upper_arm_heavy`, `forearm_heavy`,
  `hand_guard_heavy`, `thigh_heavy`, `knee_heavy`, `shin_heavy`, `boot_heavy` (je `.glb`).
- Jedes neue Teil ist Drop-in: gleiche Achsen (vorne = Blender -Y = glTF +Z, Knochenrichtung = Blender +Z), gleicher
  Pivot (Ursprung in der Mitte), gleiche Bounding-Box-Konvention (Einheitsbox fuer torso/pelvis/forearm/thigh/shin/knee),
  gleiche Materialnamen `M_Armor_Ceramic`, `M_Armor_Graphite`, `M_Armor_Titanium`, `M_Armor_Amber`, `M_Armor_Visor`.
- `scripts/terrain/personnel_armor_visual.gd`: schwer laedt aus dem neuen Ordner, alles andere aus dem alten; `REVISION` erhoeht;
  nur Zahlen im Zweig "heavy" angepasst, jeweils mit Kommentar.

## Nicht-Ziele
- Keine Aenderung an leicht/mittel/Anzug, an deren Dateien, an Rig, Animationen, Sockeln, Waffenanbau, Koerper-Shader fuer andere Ruestungen,
  an oeffentlichen Funktionssignaturen oder `body_shape_profile.json`.
- Keine neue Pose (die Idle-Haltung bleibt), kein eigener Unterzug-Farbton.

## Relevante Dokumente
- `docs/tasks/RUESTUNG_SCHWER_VERGLEICH_2026_11_15.md`, `docs/dev/graphics_reference_revision_contract.md`
- Bilder `docs/qa/ruestung_vergleich_20261115/`

## Akzeptanzkriterien
Verhaeltnisse aus Silhouetten (echter Einheiten-Proxy, Idle bei 0.2 s, ohne Waffe), Messverfahren wie im Vergleichsbericht.

| Mass | Referenz | Toleranz | alt (R07) | neu (R08) |
|---|---|---|---|---|
| Rumpftiefe / Hoehe bei 45 % | 0.268 | +-0.02 | 0.196 | 0.265 (ok) |
| Rumpf Breite / Tiefe bei 45 % | 1.44 | +-0.12 | 1.98 | 1.306 (verfehlt, zu schmal) |
| Kopftiefe / Hoehe (Seite, 3-25 %) | 0.319 | +-0.015 | 0.349 | 0.329 (ok) |
| Spannweite Armzone 46-72 % / Hoehe | 0.473 | +-0.025 | 0.396 | 0.460 (ok) |
| Beinbreite 76-97 % / Hoehe | 0.287 | +-0.02 | 0.269 | 0.281 (ok) |
| Breite / Hoehe (vorne) | 0.473 | +-0.02 | 0.464 | 0.460 (ok) |
| Dunkelgrau-Anteil vorne (Luma < 75) | ca. 35 % (Bogen vorne gemessen 30 %) | +-6 | 20 % | 30 % (ok) |

Weitere Kriterien: schwere Ruestung hoechstens 9000 Dreiecke; leicht/mittel unveraendert; Tests ohne neue FAIL-Zeilen.

## Betroffene Dateien
- `art/ruestung_schwer_r08_20261115/build_parts.py` (neu)
- `Assets/curated/personnel/armor_r08_schwer_20261115/*.glb` + `.import` (neu)
- `scripts/terrain/personnel_armor_visual.gd`
- `docs/qa/ruestung_vergleich_20261115/vergleich_heavy_r08.jpg`, `silhouette_heavy_r08.jpg`, `extra_r08_im_spielmassstab.jpg`
- `docs/IMPLEMENTATION_STATUS.md` (eine Zeile)

## Lokale Pruefung
- `python3 art/ruestung_schwer_r08_20261115/build_parts.py` (bpy), danach Godot `--headless --import`.
- Render der vier Ansichten mit dem echten Proxy, Vergleichsbogen und Silhouetten-Overlay, Messung der Verhaeltnisse.
- Tests vorher/nachher: `personnel_undersuit_switch_verifier`, `gm01_frontier_briefing_cache_verifier`, `task_097_verifier`,
  `review_completion_graphics_fixes`, `task_353_shared_loadout_contract_helper`, `playtest_20261110_two_location_runtime_verifier`.

## Risiken / offene Punkte
- Teile bleiben starr an je einen Knochen gebunden; in der geduckten Idle-Haltung koennen sich Schulter-, Oberarm- und Brustteile ueberschneiden.
- Der Bogen zeigt eine aufrechte A-Pose, das Spiel die Idle-Haltung: Seitenansicht und Armspannweite sind nur bedingt vergleichbar.
- Der Unterzug bleibt fast schwarz (kein Tint pro Ruestung im Skript vorhanden).
- Gleiche Funktion bedient Homebase, Polisa-Vitrinen und Charakter-Vorschau: dort aendert sich die schwere Ruestung mit.

## Ergebnis (15.11.2026)
- 12 Teile neu aus `build_parts.py`, schwere Ruestung 5288 Dreiecke (R07: 6964). Manifest: `Assets/curated/personnel/armor_r08_schwer_20261115/parts_manifest.json`.
- 6 Runden (Bauen, Import, Render, Messen). Bilder: `docs/qa/ruestung_vergleich_20261115/vergleich_heavy_r08.jpg` (oben Bogen, unten R08),
  `silhouette_heavy_r08.jpg` (Referenz | R08 | Differenz, rot = nur Referenz, blau = nur R08), `extra_r08_im_spielmassstab.jpg`
  (leicht, mittel, schwer mit Gewehr, Spielkamera Yaw 45 / Pitch 40, 1:1 und 4x).
- Farben gerendert (Median vorne): Dunkelgrau (66,66,70), Hellgrau (112,113,119), Sand (168,154,142), Orange vorhanden.
  Die Renderbeleuchtung zeigt die Albedo mit etwa Faktor 0.75; die Materialfarben im Skript sind darauf ausgelegt.
  Abweichung von der Vorgabe: Graphite wurde nicht auf (101,100,103) gesetzt, sondern dunkler, weil der Bogen bei
  gleicher Messung 30 % Pixel mit Luma < 75 hat (Median 53,53,57) und (101,100,103) dort der mittlere Grauton ist
  (Helm, Kragenkanten, Guertel). Titanium deckt diesen mittleren Ton ab; die Handschuhe nutzen Titanium (kein eigenes Material).
- Zahlen in `personnel_armor_visual.gd` (nur Zweig "heavy", R07-Wert in Klammern): Helm-Tiefe 1.19 (1.30), Handschuh
  0.62/0.56/0.48 x Schulterbreite (0.30/0.31/0.24) und 0.19 (0.13) Richtung Finger, Rumpftiefe 1.55 (1.16), Knie 1.40/1.20
  (1.26/1.02), Unterarm 1.75/1.50 (1.42/1.40), Schienbeinbreite 1.38 (1.25), Oberarm 0.48/0.85 (0.40/0.73),
  Schulter: Breite 1.50 (1.62), Hoehe 1.15 (0.82), Lage 0.04 Richtung Hals statt 0.07 Richtung Ellbogen, Kippwinkel -12 (-50) Grad.
- Verfehlt: Rumpf Breite/Tiefe bei 45 %. Die 45-%-Zeile liegt im Spiel unter den Schulterplatten auf Hoehe der Oberarme (Idle-Haltung,
  Arme haengen), die Oberarme sind dort schmal; im Bogen liegen dort Ellbogen/Unterarme der A-Pose.
- Sichtbare Restunterschiede: Oberarme duenner als im Bogen, Schulterplatten kantiger und weniger gewoelbt, Oberschenkelplatten
  im Vorderbild kaum sichtbar (Teile sind nicht gespiegelt, deshalb Platten beidseitig), Helm-Gesicht in der Seitenansicht
  eher als vorstehender Block, Unterzug in Achseln/Gelenken fast schwarz, Haltung geduckt statt aufrecht.
- Tests vorher/nachher gleich (keine FAIL-Zeilen): personnel_undersuit_switch_verifier, gm01_frontier_briefing_cache_verifier,
  task_097_verifier, review_completion_graphics_fixes, task_353_shared_loadout_contract_helper.
  `playtest_20261110_two_location_runtime_verifier` lief schon vorher in einen SCRIPT ERROR (Zeile 16) und Timeout; nachher nicht erneut gelaufen.
