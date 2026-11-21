# Tripo-Tanker: Modellpruefung und Spielmassstab

## Ziel und Anlass
Das vom Nutzer in Blender geoeffnete `C:/dev/SternenBuergerchen/Assets/Trip/tanker.blend`
auf Vollstaendigkeit, Texturen, Geometrie und geeigneten Spielmassstab pruefen.
Die aktuelle Tripo-Quelle ist etwa einen Meter lang und daher kein fertiger Meterexport.
Der Tanker soll spaeter als teuer rufbarer Nottankdienst dienen und eventuell teuer
kaufbar werden. Dieser Auftrag bereitet das Modell vor; diese Gameplaywege werden
hier nicht implementiert.

## Arbeitsbasis und Schutz
Isolierter sparsamer Worktree, Branch `task/tanker-tripo-20261121`, Main-Basis
`be0b30af9e8d29155be5f6473960a537b1f1d1da`. Die alte allgemeine Integration-Basis
`3cae5a216` vom 31.08.2026 wird fuer diesen aktuellen Assetkandidaten nicht verwendet.
Main, der vorherige Schiff-Worktree, die geoeffnete Blender-Datei und fremdes WIP
bleiben erhalten. Keine Bedienung von Maus oder Tastatur, keine Bridge-Aenderung.

## Umfang und Nicht-Ziele
- Unveraenderte Quellsicherung mit Hash und vollstaendigem Material-/Texturinventar.
- Separate bearbeitbare Meterfassung und GLB mit eingebetteten Bildern.
- 102 m Laenge gemaess frueherer Nutzerangabe als nachvollziehbare Ausgangsgroesse;
  gleichfoermig skalieren, neue Tripo-Proportionen erhalten.
- Blender Z-up, Nase -Y; Godot Y-up, Nase +Z; horizontal zentriert, Unterkante0.
- 82 getrennte Teile in der editierbaren Quelle bewahren. Falls verlustfrei moeglich,
  Texturen fuer die statische Spiel-GLB atlasieren und Drawcalls reduzieren.
- Native Vergleichsbilder, Blender-QA, frischer GLB-Import in isoliertes Godot-Pruefprojekt.
- Kein Ersetzen der vorhandenen Starfarer und keine Eintragung in Main-Katalog,
  keine Preise, Ruf-Kommandos, Betankungslogik oder Kauf-/Save-Aenderungen.

## Vertraege und Referenzen
- `docs/PROJECT_BRIEF.md`, `docs/ARCHITECTURE.md`, `docs/CODEX_RULES.md`, aktueller
  Kopf von `docs/IMPLEMENTATION_STATUS.md`, `docs/dev/graphics_reference_revision_contract.md`.
- Bestehender Main-Cutlass-Anker: 16 Modell-Einheiten *0.22 =3.52 Welt-Einheiten.
- Vorbereiteter Schiff-Worktree: `docs/dev/ship_mechanisms_scale_contract.md`,
  3.52/37.5 =0.0938666667 Welt-Einheiten pro Referenzmeter; nicht Personen-/Hexmassstab.
- Aktuelles Nutzer-Modell ist die Gestaltungsquelle; native Aufnahmen dokumentieren
  diese Quelle. Keine neue KI-Interpretation und keine Formrekonstruktion.

## Akzeptanzkriterien / lokale Pruefung
- Bilder sind geladen, gepackt bzw. im GLB eingebettet; keine fehlenden Materialslots/UVs.
- Ziel102mLaenge innerhalb0.001m; Breite/Hoehe proportional; dokumentierter Faktor.
- Trisbudgetmax30000, keine unbeabsichtigte Form-/Detailreduktion.
- Quelle hashgleich erhalten; Export- und Roundtrip-Bounds, Pivot, Material und Triangles pruefen.
- Blender-Geometriefehler beheben oder bei begrenzter Diagnose klar offenlegen;
  verbleibende Warnungen erklaeren, keine unverifizierte Spielreife behaupten.
- Godot-Pruefung und Bilder getrennt von produktiver Integration und Nutzerabnahme benennen.

## Betroffene Dateien
Neues Paket `art/tanker_tripo_20261121/`, isoliertes `qa/tanker_tripo_20261121/`,
diese Task und ein eigener Statusabschnitt. Keine bestehenden Gameplaydateien.

## Risiken / offene Punkte
Quelle hat82Materialien mit kleinen Einzeltexturen; Atlas muss UVs und Farbraum erhalten.
Bestehende102x48.5x24.5mStarfarer-Masse werden nur in der Laenge uebernommen:
die neue Tripo-Form darf nicht auf die alte Breite/Hoehe verzerrt werden.
Nottankdienst, Betankungsanschluss-Animation, Kollision und Kauf bleiben Folgeaufgaben.

## Abschluss
Modellkandidat erstellt und geprueft: 102 x 68.655 x 28.882 m, 15097 Dreiecke,
82 editierbare Bauteile. Die statischen GLBs verwenden ein Material mit gepacktem
2048 x 4096 Atlas. Blender-QA ohne Fehler; gezielt getrennte Nahtvertices und drei
verdeckte Flaechenpaare als begruendete Warnungen im Paket-README dokumentiert.
Godot 4.6.2 importiert alle drei Endvarianten fehlerfrei; sechs native Aufnahmen
mit Materialvergleich und Cutlass-Groessenanker wurden gesichtet. Separate QA,
keine Main-Integration und keine gestalterische Nutzerfreigabe.
Quelle nach Abschluss hashgleich; Downloadkopie und finale Artefakthashes im
`art/tanker_tripo_20261121/deliverable_manifest.json`.
