# Pass05 Geologie: Referenzvergleich und Formenstand

Basis: bewusst unintegrierter Branch `task/grafikreferenzen-20261101`,
`fbcac03d1`. Besitz: nur `scripts/terrain/frontier_art_geology.gd` und dieses
Artpaket. Keine Schiffs-/Astra-, Karten-, Gameplay-, Shader-, Profil-, Test-
oder Reportaenderung. Root besitzt die weitere Einbindung und Gesamtaufnahme.

## Geoeffnete Ziele und Ist-Stand

Alle drei aktuellen Nutzerbilder wurden geoeffnet: Rostgrenze-Cutaway,
Freihafen-Distributionszentrum und taktische Gesamtkarte. Dazu die echten
Pass04-Aufnahmen `landscape.png` und `closed_outpost.png`. Originalpfade und
SHA-256 stehen in `manifest.json`; keine vorhandene Referenz wurde ersetzt.
Das Quadratraster der alten Bildtopologie und Bildbeschriftungen sind keine
neuen Gameplay-Vorgaben. Die gesetzte Hex-Topologie bleibt erhalten.

| Referenzbefund | Pass04-Ursache | Umgesetzter Formenpass |
|---|---|---|
| Rostgrenze zeigt seitlich gebrochene kurze Lagen neben ruhigeren Waenden. | Alternierende Lippen liefen auf demselben Grundriss um ganze Koerper. | Zwei lokale, unterschiedlich breite Ruecksprung-/Ueberhangzonen; stark ungleiche Lagenabstaende. |
| Freihafen und Rostgrenze zeigen eingerissene Plateauenden und schmale senkrechte Spalten. | Wiederverwendeter 16-Punkte-Grundriss mit langen geraden Kanten. | Seedabhaengige asymmetrische 18-Punkte-Umrisse, eingeschnittene Frontspalten und eine ungleich gechippte obere Bruchkante. |
| Die taktische Karte staffelt grosse Waende, mittlere Schultern und kleine Fussbrocken. | Aehnliche Prismenmassen mit jeweils zwei gleichartigen Taluskoerpern. | Vier Hauptanordnungen mit versetzten Kronen/Buttressen, null bis vier einseitig abgestuften Fragmenten und staerker keilfoermigen kleinen Brocken. |
| Gebrochene Wandzonen tragen lokale Schatten-/Farbgewichte. | Materialwechsel folgte ganzen horizontalen Oberflaechenringen. | Bestehende Palettenfarben werden zu lokalen Bruchseiten gruppiert; Palette und Root-Shader unveraendert. |

Der erste Pass05-Versuch ergab andere Konturen, aber noch zu glatte
Vorderwaende. Er ist unter `source/frontier_art_geology_pass05_r01.gd` und
`qa/r01/` erhalten. Nach geoeffneter Nahansicht wurden die Bruchzonen auf
sichtbare Seiten gelegt, Schichtdicken ungleicher, zweite lokale Brueche,
Spalten und die gebrochene Kronenkante ausgeformt. Dieser fruehe Versuch ist
nicht als endgueltige Formabnahme gewertet.

## Finale technische und visuelle Pruefung

Godot **4.6.2 official 71f334935**, native **Forward+ / Vulkan**, 1600x900.
Vier isolierte Paare: Landschaft, nahe Klippe, grosse Wandgruppe und
Rueckansicht. Alle acht finalen PNGs wurden geoeffnet. Transformation,
Orthogroesse, Profil, Materialroute und Licht sind je Paar identisch. Die
Vorherbilder dieser Probe verwenden die gesicherte Pass04-Geometrie mit
demselben aktuellen Profil/Shader wie die Nachherbilder. Sie sind keine
Umbenennung der eingefrorenen historischen Pass04-Gesamtaufnahmen.

| Messwert | Pass04 | Pass05 |
|---|---:|---:|
| Hauptanker / konservative Huellen | 14 | 14 unveraendert |
| Meshes | 55 | 54 |
| Unindizierte Mesh-Vertices | 21.744 | 23.112 |
| Dreiecke | 7.248 | 7.704 |
| Ausserhalb deklarierter Huellen | – | 0 |
| Degenerierte Dreiecke | – | 0 |

Die vorhandenen **zwoelf Geologie-Vertragspruefungen bestehen unveraendert**:
nichtleer, alle Anker identisch, Huellen innerhalb Float-Praezision,
deterministischer zweiter Neubau, endliche Transformationen/Vertices/Normalen,
Kappen nach oben, Waende nach aussen, keine degenerierten Dreiecke und kein
Vertex ausserhalb der Huellen. Maximaler Pass02-Huellendelta 0,000000954 m;
Huellendigest `46cd64cbe1874df344c4ea2c011c4cf2c87308a627a61edaf4d295b35d2e5523`.

Das bestehende 30.000-Vertex-Limit wird eingehalten; die erlaubte 45.000er
Obergrenze war nicht noetig. Alle Teile werden einmalig aufgebaut. Das Paket
enthaelt keine per-frame-Bauarbeit und keine neue Gameplay-Autoritaet. Die
Gruppen bleiben bei y=-0,10 in der Bodenflaeche verankert; lokale Ueberhaenge
sind kontinuierliche Teile des jeweiligen Wandmeshs.

Der strenge Runner bestaetigt Exit0, Marker und keine Parse-/Skript-/ERROR-
oder Leakzeilen. Finale Evidence:
`qa/check_runs/20261101T174053Z-pid120688/metadata/report.json`.
Die erste isolierte Probe hatte einen deklarierten GDScript-Typfehler in
ihrem Pfadaufbau; `native_probe_r01.log` ist ein Fehlversuch, keine Evidence.
`native_probe_final.log` und `native_probe.json` gehoeren zum finalen Vulkanlauf.

## Erreicht und weiterhin offen

Die finale Nahansicht zeigt eine eingeschnittene vertikale Bruchstelle und
lokal vorspringende, verschieden dicke Felslagen. Im weiten Bild sind die
Kronen-/Schulteranordnungen und Fussbrocken unterschiedlich; die alte
periodische Halskette ist aufgeloest. Rueckwaende bleiben bewusst ruhiger.

Die Illustrationen besitzen weiterhin deutlich reichere mittlere Erosion,
mehr kurze Ablagen und feinere Fels-/Bodenkontakte. Die grossen Deckflaechen
bleiben horizontale Plateaus; aus manchen Blickrichtungen wirken Waende
noch grob. Die erhaltenen 14 Anker ergeben getrennte Gruppen, keine komplett
neu komponierte zusammenhaengende Schlucht. Breitere Sediment-/Geröllsaeume,
Bodenmaterial und Gesamtlicht liegen bei Root. Kein Nutzerurteil, keine
illustrationsgleiche Qualitaet und keine allgemeine Performance- oder
Release-Abnahme werden behauptet.

## Quelle und Reproduktion

Editierbare Runtimequelle und identische Kopie:
`scripts/terrain/frontier_art_geology.gd` bzw.
`source/frontier_art_geology_pass05.gd`.

```text
SHA-256 f3441b0c5b4a4e4ca93ac32f2cf0f57000e309ecd5729170be21e260d8e0ec70
```

Vom Projektroot, ohne Editorimport:

```powershell
python C:/Users/bjoer/.codex/skills/godot-game-verification/scripts/run_checks.py --project . --godot godot_console.exe --manifest art/frontier_illustrated_20261101/environment/pass05/geology/qa/checks.json --skip-import --output art/frontier_illustrated_20261101/environment/pass05/geology/qa/check_runs
godot_console.exe --path . --rendering-method forward_plus --rendering-driver vulkan --script art/frontier_illustrated_20261101/environment/pass05/geology/qa/probe_geology.gd
```

Der existierende Assetimport wurde vom uebergeordneten Pass uebernommen;
ein neuer Editorimport war ausdruecklich nicht Teil dieser Arbeit. Ein
fremder Godot-Prozess wurde nicht angefasst. Parallele Nutzung ist keine
GPU-Exklusiv- oder Performancemessung. Keine Commits oder Pushes durch diesen
Teilauftrag; Root sammelt die Aenderungen.
