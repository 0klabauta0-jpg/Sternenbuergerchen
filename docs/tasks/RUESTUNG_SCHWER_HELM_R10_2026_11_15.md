# P9: Schwere Ruestung, Helm dritte Runde (R10, 15.11.2026)

> Fuer Hilfsagenten: Dieser Plan wird abgearbeitet, nicht ausgearbeitet. Die Helmform ist vom Hauptchat gebaut,
> gerendert und gemessen; sie liegt uncommittet im Arbeitsordner. Offen sind Kragen, Pruefungen, Bilder, Bericht.

## Ziel
Der Helm der schweren Ruestung folgt dem Bogen `Assets/curated/ui/polisa_armor/heavy_turnaround.png` auch in der Form:
Stirnwulst, Visier und Maske sind gebogene Baender, die der Helmschale folgen; das Visier laeuft seitlich um den Helm,
liegt vertieft zwischen Wulst und Maske; die Maske ist hell wie die Kuppel. Der Kragen fasst den Helmfuss sichtbar ein.

## Ursache
R09 (`docs/tasks/RUESTUNG_SCHWER_HELM_R09_2026_11_15.md`) erfuellt die Masse, aber Wulst, Visier und Maske waren gerade Kaesten
vor einer runden Schale: Visier als gerader Balken, Maske als dunkler Block, der seitlich vorsteht. Nutzerauftrag 15.11.: noch eine Helmrunde.

## Stand im Arbeitsordner (vom Hauptchat, uncommittet)
- `art/ruestung_schwer_r08_20261115/build_parts.py`: neuer Helfer `Asset.arc_band(z0, z1, r0, r1, half_angle, thickness, material, seg, depth_scale, centre)`
  (Ringsektor um Z, aussen `r0` unten und `r1` oben, Mitte -90 Grad = vorn) und neue Funktion `helmet_heavy()`:
  Schale wie R09; Wulst `arc_band(-0.03, 0.05, 0.505, 0.49, 54, 0.10, T)`; Visier `arc_band(-0.18, -0.03, 0.467, 0.471, 46, 0.10, V)`;
  Maske `arc_band(-0.50, -0.18, 0.38, 0.478, 50, 0.10, T)`; vier Atemschlitze; Ohrscheiben Radius 0.13.
- `helmet_heavy.glb` und `parts_manifest.json` dazu gebaut (Helm 632 Dreiecke, Ruestung 5328).
- Messung des Hauptchats (`/home/claude/work/p9_out/r01`): K1 18,0 bis 21,8 % ok, K2 0,206 ok, K3 ok, K4 0,322 ok,
  **K5 0,240 verfehlt (Grenze fuer R10: mindestens 0,25)**, K6 0,284 ok, K7 0,332 ok, K8 0,268 ok.
- Die Helmform (`helmet_heavy()` und `arc_band`) wird nicht mehr geaendert.

## Umfang
- `scripts/terrain/personnel_armor_visual.gd`: nur `REVISION` (`..._heavy_r10`), `HEAVY_COLLAR_DROP`, `HEAVY_COLLAR_SIZE`.
- `build_parts.py`: nur der Revisionstext im Manifest (`heavy_r10_20261115`, note "R10: curved brow, visor and mask").
- Bilder nach `docs/qa/ruestung_vergleich_20261115/`, Bericht in dieser Datei, eine Zeile in `docs/IMPLEMENTATION_STATUS.md`
  (Datei ist kein gueltiges UTF-8: nur als Bytes anhaengen, z. B. Python `open(p, "ab")`).

## Nicht-Ziele
Keine Aenderung an anderen Teilen, an leicht/mittel/Anzug, an Materialnamen, an der Helmform. Schultern und Oberarme bleiben fuer spaeter.

## Arbeitsumgebung
- Arbeitsordner `/home/claude/work/wt_p9`, Branch `task/claude-p9-helm-r10-20261115`. Ausgaben nach `/home/claude/work/p9_out/rNN` (r00 und r01 sind belegt, mit r02 beginnen).
- Bauen: `python3 art/ruestung_schwer_r08_20261115/build_parts.py`. Danach `git status`: ausser `helmet_heavy.glb`, `collar.glb`, `parts_manifest.json` darf sich keine GLB aendern (sonst `git checkout --` auf die anderen).
- Godot nur ueber `/home/claude/work/g.sh /home/claude/work/wt_p9 <sekunden> <argumente>` (ein Godot zur Zeit, Bash-Timeout 600000 ms):
  Neuimport `600 --headless --import`; Render `300 --script res://scripts/tests/ruestung_ansichten_capture.gd -- heavy /home/claude/work/p9_out/rNN`;
  Messung `python3 tools/ruestung_ansichten_messen.py <renderordner> <renderordner>`; Test `300 --headless --script res://scripts/tests/<name>.gd`.
- Aendert sich nur eine Konstante in `personnel_armor_visual.gd`, ist kein Neuimport noetig; nach jedem Bauen der GLB schon.
- Commits: `git -c user.name="Claude" -c user.email="noreply@anthropic.com" commit`, deutsch ohne Umlaute. Nicht pushen. Untracked `.import` nicht committen. Kein `pkill`.

## Schritte
- [ ] 1. Manifesttext und `REVISION` setzen, bauen, Neuimport, Render nach r02, messen. Die Werte muessen denen aus r01 entsprechen (Abweichung hoechstens 0,005 H). `helm_gross.jpg` ansehen.
- [ ] 2. Kragen nachstellen, hoechstens drei Runden (r03 bis r05), je Runde genau ein Schritt, dann rendern, messen, `helm_gross.jpg` und `vergleich.jpg` ansehen:
  - Runde 1: `HEAVY_COLLAR_DROP` 0,24 -> 0,20.
  - Runde 2, nur wenn K5 < 0,25 oder K6 < 0,29: `HEAVY_COLLAR_SIZE.x` 1,75 -> 1,90 und `.z` 1,48 -> 1,60.
  - Runde 3, nur wenn K5 < 0,25: `HEAVY_COLLAR_DROP` 0,20 -> 0,16.
  - Sofort eine Runde zuruecknehmen und aufhoeren, wenn danach K1 verfehlt ist oder im Bild die obere Reihe der Atemschlitze vom Kragen verdeckt wird.
  - Aufhoeren, sobald K1 bis K8 erfuellt sind und K5 mindestens 0,25 ist. Die alten Werte kommen als Kommentar in Klammern hinter die Konstanten.
- [ ] 3. Tests ohne FAIL-Zeilen: `personnel_undersuit_switch_verifier`, `gm01_frontier_briefing_cache_verifier`, `task_097_verifier`, `review_completion_graphics_fixes`, `task_353_shared_loadout_contract_helper`.
- [ ] 4. Pixelgleichheit leicht und mittel: `ruestung_ansichten_capture.gd` mit `light` und `medium` auf dem Endstand nach `p9_out/light_neu`, `p9_out/medium_neu`; Vergleich mit `/home/claude/work/p8_out/light_alt` und `/home/claude/work/p8_out/medium_alt`, maximale Abweichung 0.
- [ ] 5. Bilder (JPG, Qualitaet 85) nach `docs/qa/ruestung_vergleich_20261115/`:
  `vergleich_heavy_r10.jpg` (= `vergleich.jpg` der letzten Runde),
  `helm_heavy_r08_r09_r10.jpg` (Kopfzone vorn und Seite, vierfach: Bogen | R08 aus `/home/claude/work/p8_out/r00` | R09 aus `/home/claude/work/p8_out/r07` | R10; das Werkzeug hat dafuer den Unterbefehl `helm3`, um eine Spalte erweitern),
  `extra_r10_im_spielmassstab.jpg` (Unterbefehl `extra`, wie `extra_r09_im_spielmassstab.jpg`).
- [ ] 6. Abschnitt "Ergebnis" fuellen (Tabelle K1 bis K9: Bogen, R09, R10; Endwerte der Konstanten; Runden; Tests; sichtbare Restunterschiede in zwei bis vier Stichpunkten), Zeile in `docs/IMPLEMENTATION_STATUS.md`:
  "- 15.11.2026 Schwere Ruestung R10: Helm dritte Runde, gebogene Wulst, Visier und Maske (Kandidat, ohne Freigabe), siehe docs/tasks/RUESTUNG_SCHWER_HELM_R10_2026_11_15.md".
- [ ] 7. Ein Commit "Schwere Ruestung R10: Helm dritte Runde, gebogene Wulst, Visier und Maske". `git status --short | grep -v '\.import$'` leer, `git log --oneline -2` in die Antwort.

## Akzeptanzkriterien
K1 bis K8 wie in R09 (Tabelle D dort), K5 mindestens 0,25 oder mit Zahl als verfehlt gemeldet; K9: Helm hoechstens 700 Dreiecke, Ruestung hoechstens 9000;
leicht und mittel pixelgleich; Tests ohne FAIL-Zeilen; drei Bilder vorhanden.

## Risiken / offene Punkte
- Ein hoeherer Kragen kann die Maske verdecken; dafuer die Abbruchregel in Schritt 2.
- Die Idle-Haltung neigt den Kopf, Seitenansicht nur bedingt mit dem Bogen vergleichbar.
- Heimatbasis, Polisa-Vitrinen und Charakter-Vorschau zeigen den Helm ebenfalls.

## Ergebnis
Render-Weg wie R09. r02 (Helmform, Kragen unveraendert) entspricht r01 (K5 0,240 verfehlt). Alle Werte aus r04 (Endstand).

| Nr. | Mass | Bogen | R09 | R10 (r04) | |
|---|---|---|---|---|---|
| K1 | Visier vorn | 17.9-20.6 % | 17.9-22.1 % | 18.0-21.8 % | ok |
| K2 | Visierbreite | 0.204 H | 0.227 H | 0.206 H | ok |
| K3 | dunkle Zeile oberhalb 14 % | 0.000 H | 0.000 H | 0.000 H | ok |
| K4 | groesste Helmbreite | 0.311 H | 0.322 H | 0.322 H | ok |
| K5 | schmalste Zeile 20-32 % vorn | 0.256 H | 0.242 H | 0.250 H | ok (genau an der Grenze) |
| K6 | Kragenbreite 26-30 % | 0.307 H | 0.284 H | 0.317 H | ok |
| K7 | groesste Kopftiefe seitlich | 0.320 H | 0.330 H | 0.332 H | ok |
| K8 | schmalste Zeile 22-30 % seitlich | 0.271 H | 0.293 H | 0.281 H | ok |
| K9 | Dreiecke Helm / Kragen / Ruestung | | 576 / 228 / 5272 | 632 / 228 / 5328 | ok |

Endwerte: `HEAVY_COLLAR_DROP` = 0,20 (vorher 0,24), `HEAVY_COLLAR_SIZE` = (1,90, 0,34, 1,60) (vorher 1,75 / 1,48); `HEAVY_HELMET_SCALE` unveraendert.
Kragenrunden:
- r03 (Runde 1, DROP 0,24 -> 0,20): K5 0,240 -> 0,246 (noch verfehlt), K6 0,284 -> 0,294, K8 0,268 -> 0,271. Atemschlitze frei.
- r04 (Runde 2, SIZE 1,90 / 1,60, weil K5 < 0,25): K5 0,250, K6 0,317, K8 0,281. K1 bis K8 erfuellt, Atemschlitze im Bild frei. Runde 3 entfiel, keine Runde zurueckgenommen.
Revision `kenney_authored_r07_undersuit_v2_heavy_r10`, Manifest `heavy_r10_20261115`.

Tests (keine FAIL-Zeilen): `personnel_undersuit_switch_verifier` PASS, `gm01_frontier_briefing_cache_verifier` 30/0, `task_097_verifier` 13/0,
`review_completion_graphics_fixes` 519/0, `task_353_shared_loadout_contract_helper` 20/0. Leicht und mittel: je fuenf Bilder gegen p8_out `light_alt`/`medium_alt`, maximale Abweichung 0.
Bilder: `docs/qa/ruestung_vergleich_20261115/vergleich_heavy_r10.jpg`, `helm_heavy_r08_r09_r10.jpg`, `extra_r10_im_spielmassstab.jpg`.
Werkzeug-Aenderung: `helm3` nimmt optional eine dritte Spalte (Aufruf `helm3 <r08> <r09> <r10> <out>`), Beschriftung in `extra` auf "R10".

Sichtbare Restunterschiede:
- Visier vorn ist noch ein fast gerader Balken; der Bogen hat eine leichte Woelbung nach unten und laeuft seitlich stufig aus; im Bild bleibt die Schale links/rechts ueber dem Visier etwas runder und heller als im Bogen.
- Maske ist jetzt hell wie die Kuppel, aber seitlich im Profil kleiner und ohne die abgeschraegte Kante des Bogens; Seitenvisier ist ein kurzer dunkler Block statt eines langen Schlitzes.
- K5 liegt genau auf 0,250 H; Kragen ist breiter (0,317 H gegen 0,307 H im Bogen) und im Profil dicker als im Bogen.
- Idle-Haltung neigt den Kopf, Seitenansicht nur bedingt vergleichbar; Schultern und Oberarme unveraendert.

