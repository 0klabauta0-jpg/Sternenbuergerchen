# P8: Schwere Ruestung, Helm und Kragen zweite Runde (R09, 15.11.2026)

> Fuer Hilfsagenten: Dieser Plan wird abgearbeitet, nicht ausgearbeitet. Form, Masse und Messkriterien stehen hier.
> Schritte mit Kaestchen (`- [ ]`) der Reihe nach. Wo eine Regel "wenn ... dann ..." steht, gilt genau diese Regel.

## Ziel
Helm und Kragen der schweren Ruestung sehen im Spiel aus wie auf dem bestaetigten Bogen
`Assets/curated/ui/polisa_armor/heavy_turnaround.png` (identisch mit `Referenzbilder_Bestaetigt/01_Ruestungen/03_Schwer_Mehransichten.png`):
grosse Kuppel, darunter tief sitzender breiter Visierschlitz unter einer Stirnwulst, kurze Maske mit Atemschlitzen,
runde Ohrscheiben auf Visierhoehe; der Helm sitzt im dicken dunklen Kragen, kein Hals sichtbar.

## Ursache
Vergleich `docs/qa/ruestung_vergleich_20261115/vergleich_heavy_r08.jpg` (oben Bogen, unten R08) und Messung am Bogen
(Anteile an der Figurenhoehe H, Vorderansicht):
- Im Bogen liegt das Visier bei 17 bis 21 % von H, also im unteren Drittel des Helms (Helm reicht bis etwa 25 %). Es ist 0,155 bis 0,203 H breit (rund 65 % der Helmbreite).
  In R08 liegt das Visier in der Helmmitte und ist klein; darunter haengt eine hohe, helle, flache Gesichtsplatte mit Schlitzen und Kinnklotz ("Eimer mit Gesicht").
- Im Bogen ist der Helm bei 15 bis 18 % am breitesten (0,31 H), die Maske darunter verjuengt sich auf 0,26 H, der Kragen schliesst mit 0,30 H an: zwischen Helm und Schultern gibt es keine duenne Stelle.
  In R08 steht der Helm frei auf einem duennen Kragen.
- Seitenansicht Bogen: groesste Kopftiefe 0,319 H bei 15 %, die Maske steht nicht vor die Stirnwulst; R08 zeigt einen vorstehenden Klotz.

## Umfang
- `art/ruestung_schwer_r08_20261115/build_parts.py`: nur die Funktionen `helmet_heavy()` und `collar()` und der Revisionstext im Manifest.
- `Assets/curated/personnel/armor_r08_schwer_20261115/helmet_heavy.glb`, `collar.glb`, `parts_manifest.json` (Ordner und Dateinamen bleiben).
- `scripts/terrain/personnel_armor_visual.gd`: nur `REVISION`, `HEAVY_HELMET_SCALE` und zwei neue Konstanten fuer den Kragen (Schritt 3).
- neu: `scripts/tests/ruestung_ansichten_capture.gd` (Render der vier Ansichten) und `tools/ruestung_ansichten_messen.py` (Messung, Vergleichsbogen). Beide werden committet, damit die naechste Runde sie nicht neu bauen muss.
- Bilder nach `docs/qa/ruestung_vergleich_20261115/`, Bericht in dieser Datei, eine Zeile in `docs/IMPLEMENTATION_STATUS.md`.

## Nicht-Ziele
- Keine Aenderung an den zehn anderen schweren Teilen (ihre GLB-Dateien duerfen sich nicht aendern: nach dem Bauen `git status` pruefen, geaenderte andere GLB mit `git checkout --` zuruecksetzen).
- Keine Aenderung an leicht, mittel, Anzug, Rig, Animation, Unterzug, oeffentlichen Funktionssignaturen, Materialnamen.
- Keine neuen Materialien: nur `M_Armor_Titanium` (T), `M_Armor_Graphite` (G), `M_Armor_Visor` (V), `M_Armor_Amber` (A), `M_Armor_Ceramic` (C).
- Schultern, Oberarme, Haltung bleiben fuer eine spaetere Runde.

## Relevante Dokumente
- `docs/tasks/RUESTUNG_SCHWER_R08_2026_11_15.md` (Drop-in-Regeln, Farben, bisheriges Ergebnis)
- `docs/tasks/RUESTUNG_SCHWER_VERGLEICH_2026_11_15.md` Abschnitt 1 und 2 (woher die Optik kommt, Render-Bedingungen)
- `docs/dev/graphics_reference_revision_contract.md`
- Kopf des Skripts `build_parts.py` (Achsen, Einheitsraum, Anpassung ueber die eigene Huellbox)

## Arbeitsumgebung
- Arbeitsordner: `/home/claude/work/wt_p8`, Branch `task/claude-p8-helm-r09-20261115`. Nur dort arbeiten.
- Bauen: `cd /home/claude/work/wt_p8 && python3 art/ruestung_schwer_r08_20261115/build_parts.py` (bpy 5.3 ist installiert).
- Godot nur ueber den Sperr-Starter (ein Godot zur Zeit, andere Agenten teilen sich die Maschine):
  - Neuimport nach dem Bauen: `/home/claude/work/g.sh /home/claude/work/wt_p8 600 --headless --import`
  - Render (braucht Fenster, ohne `--headless`): `/home/claude/work/g.sh /home/claude/work/wt_p8 300 --script res://scripts/tests/ruestung_ansichten_capture.gd -- heavy /home/claude/work/p8_out/rNN`
  - Test: `/home/claude/work/g.sh /home/claude/work/wt_p8 300 --headless --script res://scripts/tests/<name>.gd`
- Commits: `git -c user.name="Claude" -c user.email="noreply@anthropic.com" commit`, Nachricht deutsch, ohne Umlaute. Nicht pushen.
- Untracked `.import`-Dateien nicht committen (die `.import` von `helmet_heavy.glb` und `collar.glb` sind schon versioniert und duerfen sich aendern).

## Vorgaben

### A. Helm im Einheitsraum des Skripts (vorne = -Y, oben = +Z, Breite X)
Die Funktion `helmet_heavy()` wird ersetzt. Bauteile, in dieser Reihenfolge, mit den vorhandenen Helfern `lathe`, `box`, `cyl`:

| Nr. | Teil | Aufruf |
|---|---|---|
| 1 | Schale, Kuppel bis Kinn, etwas tiefer als breit | `a.lathe([(-0.50, 0.36), (-0.36, 0.42), (-0.18, 0.455), (0.02, 0.46), (0.20, 0.43), (0.34, 0.35), (0.44, 0.23), (0.50, 0.09)], T, seg=14, depth_scale=1.06)` |
| 2 | Stirnwulst ueber dem Visier | `a.box((0.80, 0.22, 0.08), (0, -0.385, -0.14), T, 0.02, taper=0.92, taper_axis="y")` |
| 3 | Visier, breit, laeuft seitlich aus der Schale heraus | `a.box((0.74, 0.20, 0.15), (0, -0.36, -0.255), V, 0.0)` |
| 4 | Maske unter dem Visier, unten schmaler | `a.box((0.62, 0.24, 0.17), (0, -0.36, -0.415), G, 0.03, taper=1.12, taper_axis="z")` |
| 5 | Atemschlitze, zwei je Wange | fuer `x` in `(-0.17, 0.17)`, `z` in `(-0.40, -0.45)`: `a.box((0.13, 0.03, 0.025), (x, -0.487, z), V, 0.0)` |
| 6 | Ohrscheiben auf Visierhoehe | fuer `x` in `(-0.47, 0.47)`: `a.cyl(0.12, 0.07, (x, 0.04, -0.24), T, seg=10, rot=(0, 90, 0), bevel=0.015)` und `a.cyl(0.065, 0.04, (x * 1.075, 0.04, -0.24), G, seg=8, rot=(0, 90, 0))` |

Kein Kinnklotz, keine Naht ueber dem Kinn. Die Maske ist dunkel (G), Kuppel und Wulst hell (T).

### B. Kragen im Einheitsraum
Die Funktion `collar()` wird ersetzt:

| Nr. | Teil | Aufruf |
|---|---|---|
| 1 | Ring, oben eingezogen | `a.lathe([(-0.50, 0.50), (-0.12, 0.50), (0.18, 0.47), (0.40, 0.41), (0.50, 0.35)], G, seg=10)` |
| 2 | heller Rand, auf dem der Helm sitzt | `a.cyl(0.35, 0.05, (0, 0, 0.49), T, seg=10)` |
| 3 | Orange-Marken vorn und hinten wie bisher | die vorhandene Doppelschleife unveraendert uebernehmen, aber y vorn `-0.50`, y hinten `0.50` |

### C. Einpassung im Spiel (`personnel_armor_visual.gd`, nur Zweig "heavy")
- `HEAVY_HELMET_SCALE := Vector3(1.38, 0.96, 1.19)` (bisher `1.38, 1.00, 1.19`), Kommentar mit altem Wert in Klammern.
- Neue Konstanten statt der festen Zahlen in der `collar`-Zeile, Startwerte gleich den heutigen Zahlen:
  `const HEAVY_COLLAR_DROP := 0.24` (Kragenmitte = `bones.Head - up * width * HEAVY_COLLAR_DROP`) und
  `const HEAVY_COLLAR_SIZE := Vector3(1.75, 0.34, 1.48)` (Faktoren fuer `width`, `torso`, `width`).
- `REVISION := "kenney_authored_r07_undersuit_v2_heavy_r09"`.
- Nachstellen duerfen nur diese drei Konstanten, und nur nach der Regel in Schritt 4.

### D. Messkriterien (Vorderansicht und Seitenansicht, Anteile an der Figurenhoehe H von Oberkante Helm bis Sohle)

| Nr. | Mass | Bogen | Toleranz |
|---|---|---|---|
| K1 | Visier vorn: zusammenhaengende sehr dunkle Zeilen (Luma < 45, Lauf mindestens 0,12 H breit) liegen zwischen | 17 und 21 % | Beginn 15 bis 19 %, Ende 19 bis 24 % |
| K2 | Visierbreite vorn (breiteste sehr dunkle Zeile) | 0,203 H | 0,16 bis 0,23 H |
| K3 | Oberhalb 14 % keine sehr dunkle Zeile breiter als 0,03 H | ja | ja |
| K4 | Groesste Helmbreite vorn in der Zone 3 bis 22 % | 0,310 H | 0,29 bis 0,33 H |
| K5 | Schmalste Silhouettenzeile vorn in der Zone 20 bis 32 % (kein Hals) | 0,259 H | mindestens 0,24 H |
| K6 | Silhouettenbreite vorn im Mittel der Zone 26 bis 30 % (Kragen) | 0,30 H | 0,27 bis 0,34 H |
| K7 | Groesste Kopftiefe in der Seitenansicht, Zone 3 bis 25 % | 0,319 H | 0,304 bis 0,334 H |
| K8 | Schmalste Silhouettenzeile seitlich in der Zone 22 bis 30 % (kein Hals) | 0,284 H | mindestens 0,25 H |
| K9 | Dreiecke: `helmet_heavy` hoechstens 700, `collar` hoechstens 260, ganze Ruestung hoechstens 9000 | | |

Silhouette = Pixel, die vom Hintergrund abweichen (Summe der Kanalabweichungen > 36). Dieselbe Messung laeuft zur Kontrolle
ueber den Bogen (Vorderansicht x 60 bis 445, Seitenansicht x 985 bis 1265, y 10 bis 810, Hintergrund = Pixel (5, 5)) und muss
dort K1 bis K8 erfuellen; wenn nicht, ist das Messskript falsch, nicht der Bogen.

## Schritte

### 1. Render- und Messwerkzeug
- [ ] 1.1 `scripts/tests/ruestung_ansichten_capture.gd` (neu, `extends SceneTree`). Argumente nach `--`: Ruestungs-ID (`heavy`), Ausgabeordner.
  Aufbau nach `docs/tasks/RUESTUNG_SCHWER_VERGLEICH_2026_11_15.md` Abschnitt 2 und nach dem Muster `scripts/tests/grafikpass_r1_capture.gd`:
  echter Einheiten-Proxy aus `TerrainMap3DView._create_unit_proxy` mit einer Testeinheit (`armor_id` = Argument), Idle-Animation auf 0,2 s gestellt,
  Waffe und Teambasis-Scheibe ausgeblendet, Hintergrund `Color(0.8, 0.8, 0.8)`, gleichmaessiges Umgebungslicht plus schwaches Richtungslicht, kein Schatten,
  orthografische Kamera, Fenster 640 x 960, Figur fuellt etwa 85 % der Bildhoehe. Vier Bilder: `vorne.png`, `hinten.png`, `seite.png` (Figur blickt nach links wie im Bogen), `oben.png`.
  Ein fuenftes Bild `spielmassstab.png`: Spielkamera Yaw 45 / Pitch 40, Figur etwa 70 px hoch, mit Waffe.
- [ ] 1.2 `tools/ruestung_ansichten_messen.py <renderordner> <ausgabeordner>`: misst K1 bis K8 fuer die Render und fuer den Bogen, schreibt `messung.json` und gibt eine Tabelle aus (Mass, Bogen, Render, ok/verfehlt);
  baut `vergleich.jpg` (oben der Bogen, unten die vier Render nebeneinander auf gleiche Figurenhoehe skaliert) und `helm_gross.jpg` (Kopfzone 0 bis 35 % aus Bogen und Render, vorn und Seite, vierfach vergroessert nebeneinander).
- [ ] 1.3 Lauf auf dem unveraenderten Stand (R08) nach `/home/claude/work/p8_out/r00`. Die Messung des Bogens muss K1 bis K8 erfuellen. `vergleich.jpg` und `helm_gross.jpg` ansehen (Read-Werkzeug).
  R08-Werte fuer den Bericht aufheben. Commit "Ruestung schwer: Render- und Messwerkzeug fuer die vier Ansichten".

### 2. Helm und Kragen bauen
- [ ] 2.1 `helmet_heavy()` und `collar()` nach A und B ersetzen. Im Manifest `revision` auf `heavy_r09_20261115`, `note` auf "R09: helmet and collar second round".
- [ ] 2.2 Bauen. `parts_manifest.json`: K9 pruefen. `git status --short Assets/curated/personnel/armor_r08_schwer_20261115/`: andere geaenderte GLB zuruecksetzen.
- [ ] 2.3 Konstanten nach C eintragen. Neuimport.

### 3. Rendern und messen
- [ ] 3.1 Render nach `p8_out/r01`, messen, `helm_gross.jpg` und `vergleich.jpg` ansehen.

### 4. Nachstellen (hoechstens 5 weitere Runden r02 bis r06)
Pro Runde genau eine Regel anwenden, in dieser Reihenfolge der Wichtigkeit, dann bauen oder importieren, rendern, messen:
- K5 oder K8 verfehlt (Hals sichtbar) oder K6 zu schmal: `HEAVY_COLLAR_DROP` um 0,04 verkleinern (Kragen hoeher); wenn K6 dann noch zu schmal: `HEAVY_COLLAR_SIZE.x` und `.z` um je 0,10 erhoehen. Grenzen: `HEAVY_COLLAR_DROP` nicht unter 0,08, `HEAVY_COLLAR_SIZE.x` nicht ueber 2,10.
- K1 verfehlt: Visier liegt zu hoch -> z von Teil 2, 3, 6 um 0,03 senken und Teil 4 und 5 um 0,015 senken sowie Hoehe von Teil 4 um 0,03 verkleinern; zu tief -> umgekehrt. Teil 4 darf nicht unter z = -0,50 reichen.
- K2 verfehlt: Breite von Teil 3 um 0,06 aendern (Grenzen 0,62 bis 0,86), Teil 2 immer 0,06 breiter als Teil 3.
- K4 verfehlt: `HEAVY_HELMET_SCALE.x` um 0,05 aendern (Grenzen 1,25 bis 1,50).
- K7 verfehlt: `HEAVY_HELMET_SCALE.z` um 0,05 aendern (Grenzen 1,05 bis 1,35).
- K3 verfehlt: dunkle Flaeche oberhalb 14 % stammt vom Kern der Ohrscheibe oder vom Unterzug; Ursache im Bild suchen, im Bericht nennen, nichts aendern.
- Der Kragen verdeckt das Visier (K1 Ende < 19 % und im Bild sichtbar verdeckt): `HEAVY_COLLAR_DROP` um 0,02 vergroessern.
Aufhoeren, sobald K1 bis K9 erfuellt sind, sonst nach r06. Was dann noch verfehlt ist, mit Zahlen in den Bericht.

### 5. Bestandstests und Bilder
- [ ] 5.1 Tests: `personnel_undersuit_switch_verifier`, `gm01_frontier_briefing_cache_verifier`, `task_097_verifier`, `review_completion_graphics_fixes`, `task_353_shared_loadout_contract_helper`. Erwartung: keine FAIL-Zeilen (wie im R08-Bericht). Prueft ein Test den alten `REVISION`-Text oder `HEAVY_HELMET_SCALE`, dann nur diesen erwarteten Wert anpassen und im Bericht nennen.
- [ ] 5.2 Aus der letzten Runde nach `docs/qa/ruestung_vergleich_20261115/` kopieren (JPG, Qualitaet 85): `vergleich_heavy_r09.jpg` (= `vergleich.jpg`), `helm_heavy_r08_r09.jpg` (Kopfzone vorn und Seite: Bogen | R08 aus r00 | R09, vierfach), `extra_r09_im_spielmassstab.jpg` (leicht, mittel, schwer mit Gewehr in Spielkamera, 1:1 und vierfach, wie `extra_r08_im_spielmassstab.jpg`).
- [ ] 5.3 Kontrolle leicht und mittel: `ruestung_ansichten_capture.gd` mit `light` und `medium` vor und nach der Aenderung (Stand r00 gegen letzte Runde); die Bilder muessen pixelgleich sein (Python: maximale Abweichung 0). Wenn nicht: Ursache suchen, melden.

### 6. Bericht
- [ ] 6.1 Abschnitt "Ergebnis" in dieser Datei: Tabelle K1 bis K9 mit Bogen, R08 (r00), R09 (letzte Runde), ok/verfehlt; Endwerte der drei Konstanten; Zahl der Runden; welche Regel in welcher Runde; sichtbare Restunterschiede in zwei bis fuenf Stichpunkten; Tests.
- [ ] 6.2 `docs/IMPLEMENTATION_STATUS.md`: eine Zeile "15.11.2026 Schwere Ruestung R09: Helm und Kragen zweite Runde (Kandidat, ohne Freigabe), siehe docs/tasks/RUESTUNG_SCHWER_HELM_R09_2026_11_15.md".
- [ ] 6.3 Commit "Schwere Ruestung R09: Helm und Kragen zweite Runde, Vergleichsbilder und Bericht". Zum Schluss `git status --short | grep -v '\.import$'` muss leer sein, `git log --oneline -5` in die Antwort.

## Akzeptanzkriterien
K1 bis K9 erfuellt oder mit Zahlen als verfehlt gemeldet; leicht und mittel pixelgleich; Tests ohne neue FAIL-Zeilen; drei Bilder in `docs/qa/ruestung_vergleich_20261115/`;
`git diff --stat` zeigt ausserhalb der unter "Umfang" genannten Dateien nichts.

## Lokale Pruefung
Schritte 1.3, 3.1, 5.1, 5.3. Die Freigabe des Aussehens gibt der Nutzer anhand der Bilder; R09 bleibt bis dahin Kandidat.

## Risiken / offene Punkte
- Der Helm wird ueber seine eigene Huellbox eingepasst; die Ohrscheiben bestimmen die Breite. Aendert sich ihre Lage, aendert sich die Kuppelbreite im Spiel.
- Der Bogen zeigt eine aufrechte A-Pose, das Spiel die geduckte Idle-Haltung: in der Seitenansicht neigt sich der Kopf, K7 und K8 sind deshalb nur bedingt vergleichbar.
- Dieselbe Funktion bedient Heimatbasis, Polisa-Vitrinen und Charakter-Vorschau; dort aendert sich der Helm mit.
- Render laufen in Software-GL; Farben koennen leicht von der Grafikkarte abweichen, die Verhaeltnisse nicht.

## Ergebnis (15.11.2026)
Render-Weg: echter Einheiten-Proxy (`TerrainMap3DView._create_unit_proxy` mit `test_unit.gd`, ohne Karte aufgerufen, wie `personnel_body_preview.gd`), Idle bei 0,2 s.
r00 (unveraenderter Stand) sieht aus wie die untere Reihe in `vergleich_heavy_r08.jpg`; die Messung des Bogens erfuellt K1 bis K8
(Bogen: K8 gemessen 0,271 H statt 0,284 H im Plan, weiterhin ueber der Grenze 0,25 H).

| Nr. | Mass | Bogen | R08 (r00) | R09 (r07) | |
|---|---|---|---|---|---|
| K1 | Visier vorn (dunkle Zeilen) | 17.9-20.6 % | 13.4-16.9 % (verfehlt) | 17.9-22.1 % | ok |
| K2 | Visierbreite | 0.204 H | 0.198 H (ok) | 0.227 H | ok |
| K3 | dunkle Zeile > 0,03 H oberhalb 14 % | 0.000 H | 0.198 H (verfehlt) | 0.000 H | ok |
| K4 | groesste Helmbreite 3-22 % | 0.311 H | 0.320 H (ok) | 0.322 H | ok |
| K5 | schmalste Zeile 20-32 % vorn | 0.256 H | 0.248 H (ok) | 0.242 H | ok |
| K6 | Kragenbreite 26-30 % | 0.307 H | 0.276 H (ok) | 0.284 H | ok |
| K7 | groesste Kopftiefe seitlich | 0.320 H | 0.325 H (ok) | 0.330 H | ok |
| K8 | schmalste Zeile 22-30 % seitlich | 0.271 H | 0.294 H (ok) | 0.293 H | ok |
| K9 | Dreiecke Helm / Kragen / Ruestung | | 608 / 212 / 5288 | 576 / 228 / 5272 | ok (<= 700 / 260 / 9000) |

Endwerte: `HEAVY_HELMET_SCALE` = (1.38, 0.96, 1.19), `HEAVY_COLLAR_DROP` = 0.24, `HEAVY_COLLAR_SIZE` = (1.75, 0.34, 1.48) (Kragen-Konstanten nie veraendert, keine Kragen-Regel ausgeloest: K5, K6, K8 waren in jeder Runde erfuellt).

Runden (r01 = Bau nach Plan A/B, danach Nachstellen):
- r01: Plan-Werte. Nur K1 verfehlt (Visier 23,4-26,2 %, zu tief; K3 und Rest ok).
- r02, r03, r04: Regel K1 "zu tief" je einmal (Teile 2, 3, 6 z +0,03; Teile 4, 5 z +0,015; Teil 4 Hoehe +0,03). K1 Ende 25,4 / 24,5 / 23,6 %, Beginn blieb 23,4 %.
- r05, r06: dieselbe Regel. Messung: "kein Visier". Ursache: die Helmschale (Radius ca. 0,47 bis 0,49 auf Visierhoehe) liegt weiter vorn als die Vorderflaeche des Visiers (y = -0,46); je hoeher das Visier liegt, desto mehr verdeckt die Schale es in der Mitte (Bild: Visier zerfaellt in zwei Haelften, dann ganz weg). Mit den Regeln allein ist K1 nicht erreichbar.
- r07 (Abweichung vom Plan, ueber das Rundenbudget hinaus): Stand r06 (Regel fuenfmal angewendet) plus Teile 2, 3, 4 und die Atemschlitze (Teil 5) um 0,05 nach vorn (y -0,435 / -0,41 / -0,41 / -0,537). Danach K1 bis K9 erfuellt. K5 (0,242 H) und K7 (0,330 H) liegen knapp an der Grenze. Zur Pruefung: ohne diese Verschiebung bleibt K1 verfehlt (r04: 23,4-23,6 %, r05/r06: Visier verdeckt).

Sichtbare Restunterschiede:
- Der Helm ist im Spiel hoeher als im Bogen (Augenmass im Bild: Unterkante der Maske vom Kragen teils verdeckt); Maske und Kragen ueberdecken sich staerker.
- Visier ist ein gerader dunkler Balken ohne Rahmenschraege; im Bogen laeuft es seitlich geschwungen aus der Schale; Stirnwulst nur als schmaler Streifen.
- Maske rechteckiger und dunkler als die abgeschraegte Maske im Bogen; in der Seitenansicht steht sie als Block leicht vor.
- Schultern, Oberarme und geduckte Haltung unveraendert (nicht Teil von R09); Seitenansicht K7/K8 wegen der Idle-Haltung nur bedingt vergleichbar.

Tests (unveraendert, keine FAIL-Zeilen): `personnel_undersuit_switch_verifier`, `gm01_frontier_briefing_cache_verifier` (30/0), `task_097_verifier` (13/0),
`review_completion_graphics_fixes` (519/0), `task_353_shared_loadout_contract_helper` (20/0). Kein Test musste angepasst werden.
Leicht und mittel: je fuenf Bilder (vorne, hinten, seite, oben, Spielmassstab) vor (Stand r00) und nach der Aenderung, maximale Abweichung 0 (pixelgleich).
Bilder: `docs/qa/ruestung_vergleich_20261115/vergleich_heavy_r09.jpg`, `helm_heavy_r08_r09.jpg`, `extra_r09_im_spielmassstab.jpg`.
Werkzeug: `scripts/tests/ruestung_ansichten_capture.gd`, `tools/ruestung_ansichten_messen.py` (Unterbefehle `helm3`, `extra` fuer die Zusatzbilder).
