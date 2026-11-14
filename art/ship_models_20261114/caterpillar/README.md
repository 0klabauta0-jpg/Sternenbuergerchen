# Caterpillar – reduzierter Modellkandidat mit beweglichen Teilen

Lieferstand 14.11.2026: editierbare `caterpillar.blend` und `caterpillar.glb`.
Quelle: lokal bereitgestellte `DRAKE-CATERPILLAR.FBX` aus
`C:/Users/bjoer/3D Objects/drive-download-20250521T120706Z-1-001/DRAKE/`.
Quell-SHA-256: `776bcab307544213861e0567f3ba9c2d42e69d50c4c71009541ad488f1822b3c`.
Original unveraendert nachgeprueft. Keine neue Lizenzbehauptung fuer dieses lokale Derivat.

| Kennzahl | Quelle | Kandidat |
|---|---:|---:|
| Dreiecke | 243269 | 32826 |
| Meshobjekte | 1 | 14 |
| Materialien | 1 Default, keine Texturen | 4 neue konstante Farbmaterialien |
| Reduktion | — | 86,51 % |

Die Quelle wurde wie der historische Aufbereitungsablauf auf 8 m Laenge normiert.
Dies ist ein Arbeitsmassstab, keine kanonische Caterpillar-Groesse. Blender vorne
-Y, GLB/Godot vorne +Z, oben +Y. Finale GLB-Masse X/Y/Z:
2,982616 × 0,953407 × 8,012558 m; Boden Y=0. Minimale Breitenzunahme durch das
neu angebaute externe Liftdeck. Der statische Hull bleibt an der urspruenglichen
Schiffsachse; die Gesamt-Boundingbox ist wegen des asymmetrischen Lifts rechts erweitert.

## Klappen und Aufzug

- `CargoDoor_L_01` bis `04` und `CargoDoor_R_01` bis `04`: echte, aus den vier
  Quell-Frachtmodulen getrennte Seitentuer-Geometrie. Jeweils eigene untere
  Scharnierachse, 90 Grad Oeffnung, 6 mm mechanischer Abstand zur aufgearbeiteten
  Rumpfkante. Keine blossen Platzhalter-Empties.
- `NoseCargoDoor`: getrennte echte Frontpanel-Geometrie, 90 Grad um untere X-Achse.
- `ServiceLiftDeck`: neu konstruierte Ersatzplattform neben dem Kommandomodul,
  mit zwei Fuehrungen und Halterung. Die Quelle besitzt keinen identifizierbaren
  separaten Lift und kein Rig. Dieser Lift ist deshalb **ein neuer Mechanikkandidat,
  keine behauptete originalgetreue Rekonstruktion**. Hub 0,30 m im Arbeitsmassstab.
- `Scene`: ein gemeinsamer Demonstrationsclip mit zehn bewegten Meshknoten.
  Anfang geschlossen/oben; etwa 1 s Klappen offen; etwa 2 s Klappen offen und
  Lift unten; bei 3 s wieder geschlossen/oben. `Hull` und Fuehrungen bleiben fest.

Gameplay-Ansteuerung, Kollisionen, begehbarer Innenraum, Cargo-Logik und Mitfahren
von Personen sind nicht implementiert. Diese Datei liefert die editierbare
Modellvorbereitung und eine echte exportierte Bewegungsprobe fuer den Folgeausbau.

## Aufbereitung und Pruefung

Bewegungsteile vor der Reduktion aus zusammenhaengenden Quellflaechen getrennt.
Duplikate entfernt; duenne Quellschalen minimal verdickt, damit Dachflaechen beim
Voxelbereinigen erhalten bleiben. Voxelbereinigung getrennt je Bauteil, leichte
Glaettung, direkte Collapse-Reduktion, frischer Meshdatablock, Kleinstreste und
Normalen bereinigt. Keine Planar-Dissolve-Stufe nach Voxel: ein verworfener Versuch
zeigte dabei beschaedigte Flaechen. Fehlerberichte `qa_rejected_r01/r02/r03.json`
bleiben als eindeutig historische Befunde erhalten.

`qa_raw.json`: **PASS, keine Fehler**. Vier akzeptierte Hinweise melden sechs
verdeckte Gegenflaechenpaare an geschlossenen Klappen bzw. der Lifthalterung.
Die Tuer-Gegenflaechen bleiben erhalten, weil sie beim Oeffnen getrennte sichtbare
Koerper werden; die Halterung ist ein gewollter Montagekontakt. Keine gleichgerichteten
ueberlappenden Flaechen, inkonsistenten Normalen oder schwebenden Teile mehr gemeldet.
UV-Pruefung aus, da ausschliesslich untexturierte konstante Materialien verwendet werden.

`verification.json`: gespeicherte Blender-Datei erneut geoeffnet, frischer GLB-Import
mit identischen 32826 Dreiecken, 14 Meshes und Bounds. `Scene` und alle zehn
bewegten Meshes gegen festen Hull nachgewiesen; Originalhash unveraendert.
Unabhaengige Godot-Pruefung liegt im benachbarten `../godot_probe/`.

Geoeffnete Sichtbelege: Material-, Solid-, Teilefarben-, Drahtgitter- und
Offen-Aufnahmen sowie direkte Quelle/Kandidat-Vergleiche. `comparison_manifest.json`
fixiert Kamera, Orthoskalierung, Aufloesung und Licht fuer die drei identischen
Quelle/Kandidat-Ansichtspaare. Kleine Greebles sind vereinfacht, grosse Silhouette,
Dachschalen, Kommandomodul und Triebwerksgruppen bleiben erkennbar erhalten.
Keine gestalterische Nutzerabnahme behauptet.

## Reproduktion ohne gemeinsame Blender-Sitzung

Nur eigene Blender-5.1.1-Prozesse, je `--background --factory-startup --threads 2
--python-exit-code 1 --python <Skript>`, aus dem Worktree. Keine Live-MCP-Verbindung.
Reihenfolge unter `tools/`: `caterpillar_inspect.py`, `caterpillar_analyze.py`,
`caterpillar_build.py`, `caterpillar_finalize.py`, `caterpillar_verify.py`,
`caterpillar_comparison.py`, `caterpillar_wire_review.py`. Danach normales Python
`tools/caterpillar_metadata.py`.
Der Drahtgitter-Renderer deaktiviert nur fuer temporaere Diagnosekopien die
Wireframe-Even-Offset-Gehrung, die an schmalen Dreiecken kuenstliche lange Spitzen
zeichnen kann. Die eigentliche Geometrie und der Export werden dadurch nicht veraendert.
