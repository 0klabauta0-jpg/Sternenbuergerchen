# REVIEW7 - Sieben Befunde behoben

Basis Main `668423dcf`, Branch `task/review7-fixes-20261103`.
Keine Main-Integration in diesem Auftrag.

Gepruefte Produktcommits: `1fc8a7709` (Spacing), `e3e4483c9` (Session/Lobby),
`ac63f662a` (FoW/Kamera/Animation). `source_context.json` ordnet die 114 Rohhashes
den kanonischen Gitblobs zu; nur normale Repository-Textfilter sind beteiligt.

Alle sieben P2-Befunde behoben und unabhaengig APPROVED. Elf neue Regressionen
vor dem jeweiligen Produktfix rot gesehen; final **699/699** Assertions gruen.
Frische gemeinsame Matrix: **103 Gates, 100 PASS, drei bestaetigte Altfehler**.
Gruene Gates: **3588/3588** Assertions; alle Gates zusammen 3661 erfolgreich,
sieben fehlgeschlagen. Keine All-green-/Release-Abnahme.

| Befund | Korrektur | Neue Assertions |
| --- | --- | --- |
| Separation kreuzt Hoehenkanten | Tatsaechliche Segmentzellen ueber bestehenden Pathfinder pruefen | 352 |
| Missionsstart umgeht Kartenfreigabe | Rohmanifest, lokale Zustimmung, alte Offers und echte Lobby-/Maplaunch-Consumer absichern | 36 + 34 |
| Bravo-Host ohne Gegenseite | Gegner relativ zur Hostseite plus Versus-Startguard | 20 |
| Rejoin scheitert in Mission zwei | Token verbundener Clients beim Missionsabschluss erhalten | 42 |
| FoW-Jobs werden verworfen | Target-LOS trennen, Bewegung zusammenfassen, harte Inputs invalidieren, echten Overlay erhalten | 60 + 30 + 51 + 38 |
| Bewegter Kontakt setzt Kamera zurueck | Stabile Kontakt-/Fireteamidentitaet statt Koordinaten | 19 |
| Laufende Animation invalidiert nicht | Sichtbaren Animationstime-Fortschritt als Redrawgrund melden | 17 |

## Altfehler und Fixtures

Alle drei roten Gates auf archiviertem Original-Main mit exakt denselben
Fehlerzeilen, Assertionzahlen und Exitcodes reproduziert. 1672 archivierte
Skript-/Projektdateien stimmen unabhaengig geprueft mit Git ueberein.

- TASK839: 29/2; bestehende Meta-/Tactical-Aggregatpruefungen.
- TASK1122: 9/2; bestehende Filmic-/Brightness-Erwartungen.
- `bugfix_multiplayer_lobby_setup_and_asset_catalog_followup`: 35/3;
  bestehende Default-Roster-Erwartungen und Raised-Floor-Footprint.

Originalbelege: `original_main_adjacent/` und `original_main_task839/`.
Diese Erwartungen blieben unveraendert. Zwei andere veraltete Fixtures wurden
gezielt korrigiert: zusammenhaengende legale Terrainstrecke statt Spacing-
Teleport; echter eingefrorener AnimationPlayer fuer Badge-only-Redrawchecks.
Ihre bisherigen Verhaltensassertionen bleiben erhalten.

## Performance und Rendering

128/256-Terrain-FoW publiziert bei bewegten Gegnern nach Frame30/126.
Auch kontinuierliche Observerbewegung erhaelt den Initialfortschritt; weitere
Revisionen erscheinen ohne Stoppen und entsprechen nach Stillstand dem Oracle.
Echter gestreamter View: 5184 Overlaytiles, genau ein Fullbuild, stabile Mesh-ID
und entfernter Safetyblackout. Fortlaufende +1-Deltas werden auch waehrend des
Erstaufbaus angewendet; eine Revisionsluecke benoetigt einen Fullbuild.

Abschliessender nativer Lauf: **39/39**, D3D12/Forward+, RTX4070TiSUPER,
erzwungenes Color-/Transform-Ruecklesen erfolgreich. Drei echte 1920x1080-PNGs
unter `native_render/20261103T151716Z-c53fd867/`.
Headless-Dummy unterstuetzt dieses Ruecklesen nicht. CPU-Tilestates, Slots,
Mesh, Cursor und Safety bleiben dort zwingend geprueft; GPU-Alphas nativ.
Die Diagnose-Fehllauefe bleiben als Rohhistorie erhalten.

TASK1188: 28 Units, 8696 Frames /60003ms, Proxy-Sync-p99 **3918us <8000us**.
Kein gepaarter FPS-/GPU-Speedupnachweis. Laufende Animationen zeichnen nun
korrekt neue Frames und verursachen entsprechende zusaetzliche Renderarbeit.

## Isolation und Grenzen

259 Prueflaeufe mit 259 frischen eindeutigen Userpfaden. Originalroster in
SHA256, Laenge und Schreibzeit gleich. Runner/Guard unveraendert; nativer
Helper nutzt dieselbe Overlay-Erstellung und denselben synchronen Guard.
114 Quell-/Test-/Harnessfingerprints stimmen nach Abschluss ueberein.

Vorbereitende Baseline-/Matrixstarts und ein Headless-/Nativstart ueberschnitten
sich kurz. Die massgebliche finale Matrix und danach der native Wiederholungslauf
liefen in diesem Task strikt nacheinander. Kein Performancevergleich nutzt die
Ueberschneidungen. Rohberichte und Fehlversuche sind im Index enthalten.

TASK228-V1-Grenze bleibt: Accept wartet auf Payload; die bestehende explizite
Payload-API ist getestet. Kein neuer Download-/Asset-/Scenario-Transfer.
Atomare Terrainstichproben sind bei Bewegung zeitversetzt; die 350-ms-Dirty-
Grenze ist keine Initial-Fullscan-Zusage. Keine allgemeine Animationspixel-,
Langzeit-, FPS-, UX- oder Releaseabnahme.

## Belege und Reproduktion

- `verification_summary.json`: strenger Index, Gatezahlen, Baselines,
  Sourcehashes und gesamte Isolationshistorie.
- `independent_review.md`: Code-/Fixture-/Belegaudits.
- `verified_final_suite/20261103T150801Z-1ef7d266/report.json`: finale Matrix.
- `native_render/20261103T151716Z-c53fd867/report.json`: nativer Folgelauf.

Nur mit frisch selbst gepruefter Originalrosterbaseline wiederholen:

```powershell
python scripts/tests/run_review2_isolated.py --manifest scripts/tests/review7_20261103_checks.json --baseline output/review7_fixes_20261103/roster_baseline.json --output output/review7_fixes_20261103/replay
python output/review7_fixes_20261103/run_native_render_check.py
```
