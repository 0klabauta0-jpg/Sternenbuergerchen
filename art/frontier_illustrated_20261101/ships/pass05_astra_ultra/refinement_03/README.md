# Refinement 03 – Cockpitwanne und vier Cutlass-Triebwerke

Der neueste Nutzerentwurf ist umgesetzt: Die Buccaneer erhält eine geschlossene untere Cockpitwanne mit Verglasung in der oberen Hälfte. Die Cutlass erhält schmalere Vorderflügel, kleinere hintere Motoren und zwei zusätzliche vordere Motoren. Die Hecktriebwerke bleiben die äußerste seitliche Kontur. Dieser Cutlass-Aufbau ist eine bewusste Änderung gegenüber den ursprünglichen Illustrationen.

| Änderung gegenüber Refinement 02 | Gemessenes Ergebnis |
|---|---|
| Buccaneer-Seitenglas: unterste Kante relativ zur lokalen Kanzelhöhe | 18,3 % → 50,3 % |
| Buccaneer-Unterteil | Geschlossene facettierte Wanne mit Kiel, Seitenflächen und abgesetztem Rand |
| Cutlass-Vorderflügelspannweite | 11,618 → 8,224 m (−29,2 %) |
| Cutlass-Heckdüsen-Durchmesser | 2,332 → 2,029 m (−13 %) |
| Neue Cutlass-Frontdüsen | Durchmesser 1,014 m, exakt 50 % der neuen Heckdüsen |
| Cutlass-Außenkontur | Heckgruppe reicht auf jeder Seite 0,818 m weiter heraus als die gesamte Vordergruppe |

Die neuen Frontmotorachsen liegen nur 0,229 m weiter innen als die Heckmotorachsen. Der größere bemannte Turm und die überarbeitete Cutlass-Kanzel bleiben geometrisch unverändert. Bei der Buccaneer bleiben alle 87 Bauteile außerhalb der Kanzel unverändert, einschließlich der zuvor um 22 % im Durchmesser verkleinerten Motoren. Maße sind weiterhin stilisierte Arbeitsmaße, keine kanonischen Fahrzeugdaten.

## Direkte Vergleiche

| Schiff | Auf die neue Korrektur zugeschnitten | Vorher / neu, vorn und hinten | Ursprüngliche Illustration / neu |
|---|---|---|---|
| Buccaneer | [Seitenvergleich](review/buccaneer/sheets/Vorher_und_Neu_Seite.png) | [Vergleich](review/buccaneer/sheets/Vorher_und_Neu.png) | [Referenzvergleich](review/buccaneer/sheets/Ziel_und_Neu.png) |
| Cutlass | [Draufsichtvergleich](review/cutlass/sheets/Vorher_und_Neu_Oben.png) | [Vergleich](review/cutlass/sheets/Vorher_und_Neu.png) | [Referenzvergleich](review/cutlass/sheets/Ziel_und_Neu.png) |

Jeweils links Refinement 02 und rechts Refinement 03, bei identischen Modellkameras, Licht, Rendermaßstab und Bildrahmen. Die zusätzlichen Seiten-/Draufsichttafeln zeigen die vollständigen identischen 1200×900-Rahmen. Die Perspektivillustrationen sind nicht kamerakalibriert. Alle finalen Bilder wurden geöffnet; zusätzliche Originalansichten wurden auf offiziellen RSI-Seiten geprüft: [Recherche und genaue Quellen](review/ORIGINAL_REFERENCE_NOTES.md). Keine externe 3D-Geometrie wurde importiert.

## Dateien und Prüfung

| Schiff | Editierbare Quelle | GLB | Dreiecke / editierbare Teile |
|---|---|---|---|
| Cutlass | [cutlass_01.blend](cutlass/source/final/cutlass_01.blend) | [cutlass_01.glb](../../../../../Assets/curated/frontier_illustrated_20261101/ships_pass05_astra_ultra/refinement_03/cutlass_01.glb) | 22.496 / 174 |
| Buccaneer | [buccaneer_master.blend](buccaneer/buccaneer_master.blend) | [buccaneer_01.glb](../../../../../Assets/curated/frontier_illustrated_20261101/ships_pass05_astra_ultra/refinement_03/buccaneer_01.glb) | 19.672 / 88 |

Beide Modelle: ein GLB-Mesh, acht Materialien, finale Source-/frische GLB-Prüfung **0 Fehler und 0 Warnungen**. Positionen stimmen exakt; Normalen, UVs, Materialwerte und vollständige Texturpixel liegen innerhalb unveränderter Grenzen. Kontaktgraph, Geometrie, Achsen, Gesamtmaße und Boden sind geprüft. Je acht Kamera-/Lichtpaare und 23 Bild-/Dateibindungen bestehen ebenfalls. Herkunft, Messungen, Scripts, Quellen, Exporte und Bilder stehen im [Manifest](manifest.json).

Details und Reproduktion: [Cutlass](cutlass/README.md), [Buccaneer](buccaneer/README.md). Sichtberichte: [Cutlass](review/cutlass/VISUAL_REVIEW.md), [Buccaneer](review/buccaneer/VISUAL_REVIEW.md). Messnachweise: [Cutlass](cutlass/review/final/evaluated_proportions.json), [Buccaneer](buccaneer/evaluated_proportions.json).

Offen bleiben die ästhetische Nutzerabnahme und native Godot-Prüfung/Integration. Die Modelle haben weiter vereinfachte Mechanik, Glas- und Materialwirkung. Der Sitzpersonenproxy im Cutlass-Turm plausibilisiert nur dessen äußere Größe; kein ausgearbeiteter Innenraum, Zugang oder ergonomischer Nachweis. Keine neue Animation oder Kollision.

Alle Vorgänger bleiben unverändert erhalten, einschließlich des geprüften Refinement-02-Zwischenstands. Einzige deklarierte Dokumentationsausnahme: die fortgeschriebene eigene Task-Datei. Arbeit auf `task/grafikreferenzen-20261101` im vorgegebenen Grafik-Worktree, ohne Checkout, Commit, Push oder Runtime-Eingriff.
