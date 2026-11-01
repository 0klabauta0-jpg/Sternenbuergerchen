# Pass05 – Cutlass und Buccaneer: neue Blender-Kandidaten

Beide Schiffe wurden anhand der vier aktuellen Wimmelbild-Ziele neu modelliert. Massgeblich waren die grossen Koerperformen, Kanzeln, Motoranschluesse und klare Materialflaechen. Die aelteren R01/R02-Modelle sind keine Nutzerfreigabe und bleiben erhalten. Dies ist eine eigenstaendige Modelluebergabe auf dem noch nicht integrierten Branch `task/grafikreferenzen-20261101`.

## Direkt ansehen

- [Cutlass: 2D-Ziel / neuer Kandidat](handover/cutlass_target_comparison.png) und [R02 / Pass05](handover/cutlass_r02_comparison.png)
- [Buccaneer: 2D-Ziel / neuer Kandidat](handover/buccaneer_target_comparison.png) und [R02 / Pass05](handover/buccaneer_r02_comparison.png)

Die Bilder sind reale Blender-Render der gelieferten Modelle. Zielbilder sind perspektivische Illustrationen. R02/Neu verwenden identische Kamera, Orthoprojektion, Licht, Farbverwaltung und Aufloesung; die Manifeste speichern diese Bedingungen. Die 512px-Spielabstandsbilder bilden das Schiff mit etwa130px ab und sind keine native Godot-Aufnahme.

## Integrationsdateien

| Schiff | Dreiecke | Materialien | Blender-BBox Breite × Laenge × Hoehe |
|---|---:|---:|---|
| Cutlass | 15148 | 8 | 12.3218 × 16.0000 × 4.9713 m |
| Buccaneer | 22480 | 8 | 11.7578 × 11.0000 × 4.1198 m |

- Cutlass-Quelle: [source/final/cutlass_01.blend](cutlass/source/final/cutlass_01.blend)
- Buccaneer-Quelle: [buccaneer_master.blend](buccaneer/buccaneer_master.blend)
- Beide GLBs: `Assets/curated/frontier_illustrated_20261101/ships_pass05_astra_ultra/{cutlass_01,buccaneer_01}.glb`
- Reproduzierbare Generatoren, Referenzen, Quellen-/Lizenzstatus und Hashes: [manifest.json](manifest.json), [reference_sources.json](reference_sources.json) sowie die schiffsspezifischen Dokumente.

Ground-Pivot0 und volle XY-BBox zentriert. Blender -Y vorne wird Godot +Z vorne. Vorschlag fuer RuntimeScale weiterhin .22; die Laengen16m/11m sind stilisierte Projektmasse. Die BBox nach Godot-Achsentausch und Skalierung steht pro Asset im Manifest. Jedes GLB fasst die Geometrie in einem Mesh mit acht Materialgruppen zusammen; die BLEND-Quellen behalten die einzeln editierbaren Bauteile.

## Was verbessert wurde und was sichtbar offen bleibt

Cutlass: laengere abfallende Kanzel, gegliederter Transportruecken, Frontgabeln mit Endplatten, geformte Motorhauben, eigenstaendige Heckduesen und geschlossener Cargoabschluss. Buccaneer: schmale Keilkanzel, erhoehte Einlassschultern, verzahnte Hauben/Seitenholme, angeschlossene dickere Fluegelwurzeln, zwei Heckstege, Duesenblaetter und dicke vorwaerts gerichtete Dorsalkanone. Beide besitzen ein verbundenes Fahrwerk fuer die geforderte Bodenpose.

Die Modelle sind weiterhin gleichmaessiger und glatter als die gemalten Zielbilder. Besonders die Motorhauben, kleinen Panelanschluesse, Scheibenreflexe und gemalten Licht-/Pigmentkanten stimmen noch nicht vollstaendig. Die Buccaneer-Pods und Duesenblaetter bleiben regelmaessiger. Die Cutlass-Motorhauben lesen sich noch zu sehr als grosse helmartige Volumen; dunkle Backen, Seitenmechanik und gestufte Verkleidung sind in der Vorlage ausgepraegter. Ihre Gabelendplatten und Fluegelarme bleiben kompakter und quaderfoermiger. Eine insgesamt enge Vorlagentreue wird deshalb nicht behauptet. Die Vorder-/Heckkonzepte sind keine exakt uebereinstimmenden technischen Ansichten. Ein metrischer 2%-Referenzmatch wird nicht behauptet. Unterseite, Fahrwerk und verdeckte Verbindungen sind konstruktiv ergaenzt.

## Pruefumfang

Source-Mesh-QA und unabhaengiger frischer GLB-Roundtrip pruefen endliche Daten, alle Dreiecksecken, Normalen, UVs, Materialparameter, Texturpixel, BBox, Pivot, Achsen und Kontaktverbindungen. Fehlerhafte Zwischenstaende einschliesslich des verworfenen Blender-Normalen-Reencodes sind als Historie markiert erhalten. Der finale Export fasst die originalen GLB-Attribute ohne erneute Normalenberechnung zusammen. Die aktuellen Einzelberichte und ihre exakten Eingabehashes stehen im Manifest. Vorne/hinten/Seite/oben/Spielabstand sowie Baugruppen- und Drahtansichten wurden geoeffnet.

Es erfolgte ausdruecklich kein Godot-Import, keine Runtime-/HTML-/Statusreport-Aenderung, kein Checkout, Reset, Commit oder Push aus diesem Chat. Der Hauptchat besitzt Integration und native Gegenpruefung. Technische Kandidatenpruefung ist keine gestalterische Nutzerabnahme.

## Quellen und Lizenzstatus

Die vier vorhandenen generierten Projekt-Zielbilder sind unveraendert nach references kopiert und gehasht. Beide neuen Meshes sind eigene Rekonstruktionen; die lokalen DRAKE-OBJ-Dateien wurden nicht verwendet. R02 dient nur dem Vorhervergleich. Die selbst erstellten Materialien/Pigmenttexturen und Generatoren sind im Paket enthalten; hier wird keine gesonderte Lizenz fuer die zugrunde liegenden fremden Raumschiffentwuerfe behauptet. Die unveraendert verwendeten Blender-QA-Skillskripte deklarieren MIT; ihre Pfade und Hashes stehen in qa_tools/tool_manifest.json.
