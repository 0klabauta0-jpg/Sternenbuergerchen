# Cutlass und Buccaneer – Proportionsrevision 02

Die erneute Nutzerkritik betraf die Hauptformen: zu kleine Cutlass-Vorderflügel, eine unplausibel kleine bemannte Turmkabine, beide Cockpits und übergroße Buccaneer-Triebwerke. Die Zuordnung der Vorderflügel zur Cutlass wurde vom Nutzer ausdrücklich bestätigt. Diese Runde ändert deshalb die Proportionen der vorhandenen editierbaren Modelle.

| Änderung gegenüber Refinement 01 | Ergebnis, ausgewertete Geometrie |
|---|---|
| Cutlass-Vorderflügel | Spannweite 9,33 → 11,62 m (+24,6 %), größere zusammenhängende Wurzeln, dünnere Spitzen |
| Cutlass-Cockpit | Breite 1,81 → 2,29 m (+26,4 %), breiterer Bug, größere zusammenhängende Seitenverglasung |
| Cutlass-Turmkörper | 1,31 × 1,26 × 0,81 → 2,08 × 2,45 × 1,54 m, Fensterband und Sitzpersonen-Prüfvolumen |
| Buccaneer-Triebwerke | Druckhüllen-Durchmesser −22 %, Länge −10 %; komplette Pods mit Hauben, Ringen, Düsen und Anbindungen angepasst |
| Buccaneer-Cockpit | Breite +13,3 %, zwei große Seitenfenster je Seite, schräge Frontscheibe, kürzere geschlossene Dachfläche |

Die Buccaneer behält ihre äußere Spannweite und Kanonengeometrie. Ihre inneren Flügelwurzeln schließen an die kleineren Pods an. Modellmaße sind stilisierte, aus Perspektivbildern abgeleitete Arbeitsmaße: Cutlass 16 m Länge, Buccaneer 11 m; keine Behauptung kanonischer Maße. Der Cutlass-Personenproxy plausibilisiert die äußere Turmgröße, keinen fertigen begehbaren Innenraum oder zertifizierte Ergonomie.

## Direkte Vergleiche

| Schiff | 2D-Vorlage / neuer Kandidat | Refinement 01 / Refinement 02 |
|---|---|---|
| Cutlass | [Vorn und hinten](review/cutlass/sheets/Ziel_und_Neu.png) | [Vorher und neu](review/cutlass/sheets/Vorher_und_Neu.png) |
| Buccaneer | [Vorn und hinten](review/buccaneer/sheets/Ziel_und_Neu.png) | [Vorher und neu](review/buccaneer/sheets/Vorher_und_Neu.png) |

Vorher/Neu verwendet pro Ansicht identische feste Kameras, Beleuchtung, Maßstäbe und Ausschnitte. Die perspektivischen Zielillustrationen sind nicht kamerakalibriert. Je acht Bedingungspaare und 23 Datei-Bindungen sind in den jeweiligen `matched_conditions.json` geprüft. Alle zwölf finalen Ansichten je Schiff und die vier Tafeln wurden durch die unabhängige Prüfung geöffnet; die führende Instanz prüfte zusätzlich alle vier Tafeln und ausgewählte Rohansichten/frische GLB-Ansichten. Die Bilddateien sind echte Blender-Render des gebundenen Modells.

## Dateien und Prüfung

| Schiff | Editierbare Quelle | GLB | Dreiecke / Quellteile |
|---|---|---|---|
| Cutlass | [cutlass_01.blend](cutlass/source/final/cutlass_01.blend) | [cutlass_01.glb](../../../../../Assets/curated/frontier_illustrated_20261101/ships_pass05_astra_ultra/refinement_02/cutlass_01.glb) | 16.224 / 144 |
| Buccaneer | [buccaneer_master.blend](buccaneer/buccaneer_master.blend) | [buccaneer_01.glb](../../../../../Assets/curated/frontier_illustrated_20261101/ships_pass05_astra_ultra/refinement_02/buccaneer_01.glb) | 19.632 / 88 |

Je ein exportiertes Mesh und acht Materialien. Beide finalen Audits bestehen mit **0 Fehlern und 0 Warnungen**. Geprüft wurden unter anderem Source-Topologie, Verbindungen, Maßstab, Achsen, Boden, Positionen, Normalen, UVs, Materialwerte und vollständige Texturpixel gegen direkten GLB-Inhalt und einen frischen Blender-Reimport. Keine Prüftoleranz wurde gelockert. Die GLBs wurden nach dem Export verlustfrei auf ein Mesh konsolidiert.

Details und Reproduktion: [Cutlass](cutlass/README.md), [Buccaneer](buccaneer/README.md). Messnachweise: [Cutlass](cutlass/review/final/evaluated_proportions.json), [Buccaneer](buccaneer/evaluated_proportions.json). Audits: [Cutlass](cutlass/review/final/independent_qa.json), [Buccaneer](buccaneer/audit.json). Sichtberichte: [Cutlass](review/cutlass/VISUAL_REVIEW.md), [Buccaneer](review/buccaneer/VISUAL_REVIEW.md).

Die großen Flächen, Mechanik und Glaswirkung sind weiterhin einfacher als in den gemalten Vorlagen. Native Godot-Prüfung, Integration und Nutzerabnahme stehen aus. Das sind statische Kandidaten ohne neue Animationen oder Kollisionsmodelle.

[manifest.json](manifest.json) bindet Dateien, Exporte, Herkunft, Messungen und Prüfungen per SHA-256. Die 156 eindeutigen geschützten Artefakte aus den zwei früheren Manifesten sind unverändert. Die fortgeschriebene eigene Task-Datei ist die einzige erklärte Dokumentationsausnahme. Originale, Vorgänger und Zwischenstände bleiben erhalten. Keine externen 3D-Meshes wurden importiert; Projekttexturen und bereitgestellte Referenzen werden weiterverwendet, ohne neue Lizenzzusagen für die zugrunde liegenden Schiffsdesigns.

Arbeit ausschließlich im vorgegebenen Grafik-Worktree auf `task/grafikreferenzen-20261101`, ohne Checkout, Commit, Push oder Laufzeitänderung. Nur neue Refinement-02-Dateien und die eigene Task-Fortschreibung.
