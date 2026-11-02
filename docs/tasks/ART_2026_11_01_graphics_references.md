# ART_2026_11_01 - Grafikreferenzen und Modellvergleich

## Ziel und Anlass
Der Nutzer beauftragt einen Grafikdurchgang fuer Gelaende, Modelle und Menschen,
angelehnt an das referenzgefuehrte InselKrieg-Verfahren und Star Citizen. Gewuenscht
ist eine lokale HTML-Ausgabe aller tatsaechlichen Aenderungen. Zusaetzlich sind
Projektregeln zu pruefen und fuer Cutlass und Buccaneer mit dem Bildgenerator
je zwei Ansichten im illustrierten Himmelbildstil zu erstellen. Bilder unter
`C:/Users/bjoer/Pictures` und vorhandene lokale Schiffmodelle sind einzubeziehen.

Spaetere Praezisierung: Cutlass und Buccaneer staerker im Wimmelbildstil und
mit etwas weniger Details. Vier vereinfachte 2D-Ansichten ersetzen die erste
Himmelbildserie als aktuelles Ziel; die vorherige Serie bleibt erhalten.

## Arbeitsbasis
- Neuer Branch `task/grafikreferenzen-20261101` von `integration/core-foundation`,
  Basis `3cae5a216d380b58fef92724540e95fbc49bde7e`.
- Isolierter, durch Codex verwalteter Worktree; keine Fortsetzung des alten
  Rostwelt-Branches und keine Aenderung an dessen WIP.
- Integrationsregeln nennen Godot 4.6.2. Dieser Auftrag wechselt keine Engine.

## Umfang
- Zugeordnete, tatsaechlich betrachtete Referenzen und eigene neue 2D-Zielbilder.
- Cutlass und Buccaneer: je Vorder- und Heck-Dreiviertelansicht; gemeinsame
  Identitaet, Proportionen und Palette innerhalb jedes Paares.
- Zusammenhaengende Zielbilder fuer Landschaft, Aussenposten und Personen.
- Vorhandene Modelle untersuchen und konkrete visuelle Ueberarbeitungen mit
  nachvollziehbaren Quellen und nativen Vergleichsbildern ablegen.
- Grafikbezogenen Arbeitsvertrag ergaenzen; AGENTS/CODEX_RULES nur verlinken.
- Offline-HTML mit Bildvergleich, Suche/Filtern, Vergroesserung, Notizen,
  Entscheidungen, Quellen und sichtbarem JSON-Export.

## Grenzen
Gameplay, Simulation, Karte, Navigation, Sicht, Combat und Multiplayer werden
durch Kunstvorlagen oder Vergleichsszenen nicht veraendert. Bestehende Quellen,
Berichte und Nutzerbilder bleiben erhalten. Ein Bildgenerator-Ziel ist kein
nativer 3D-Render; ein Kandidatenmodell ist keine aktive Spieluebernahme.
Der HTML-Bericht benennt den erreichten Umfang und verbleibende Differenzen.

## Relevante Vertraege
- `docs/PROJECT_BRIEF.md`, `docs/ARCHITECTURE.md`, `docs/CODEX_RULES.md`
- `docs/dev/html_report_workbench_contract.md`
- `docs/dev/graphics_reference_revision_contract.md` (wird hier erstellt)
- InselKrieg: aktueller Visual Contract und zugeordnete 2D-Referenzserie;
  eigene Schiffsquellen unter `C:/Users/bjoer/3D Objects/.../DRAKE/`.

## Akzeptanz und lokale Pruefung
- Vier neue Schiffsansichten vorhanden, geoeffnet und als zwei Paare geprueft.
- Gelaende, Strukturen und Menschen mit konkreten Bildern im Bericht vertreten.
- Quellen, Prompts, Modell-/Bildstatus und SHA-256-Werte nachvollziehbar.
- Geaenderte 3D-Quellen erhalten editierbare Quelle und passende Import-/
  Geometrie-/Ansichtspruefung; Materialproben benennen unveraenderte Geometrie.
- HTML lokal ohne externe Laufzeitabhaengigkeiten; Desktop/Mobil, Bilddialog,
  Filter, Notizen und JSON-Export tatsaechlich geprueft.
- `git diff --check`; nur eigene Task-Dateien committen/pushen.

## Betroffene Dateien und offene Punkte
Geplant: neuer Grafikvertrag, kurze Regelnverweise, dieser Task, Statusnotiz,
HTML und Grafikpaket mit Bildern, Manifest, Quellen-/Generatorskripten.
Aktuelle Schiffzuordnung und Umfang der nativen Kandidaten werden nach Sichtung
festgehalten. Keine pauschale Abnahme aller Spielassets oder des Releases.
