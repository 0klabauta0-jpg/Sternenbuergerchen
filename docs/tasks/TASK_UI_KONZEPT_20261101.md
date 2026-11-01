# UI-Konzept und Bildgenerator-Icons · 01.11.2026

## Ziel / Problem
Vorhandene Oberflächen und Funktionen sichten, visuelle Alternativen im aktuellen SternenBürgerchen-Stil erstellen und eine nachvollziehbare Übergabe für die spätere Godot-Umsetzung liefern.

## Grundlage / Ursache
Der Nutzer beauftragt ausdrücklich Entwürfe, Icons mit dem Bildgenerator und die Erklärung der Gestaltungsentscheidungen. Bestehende UI-Vorschläge und der laufende Grafikpass dienen als Quellen. Wiederverwendete Befehlssymbole und sehr kleine Theme-Schriften sind konkrete Ansatzpunkte aus dem Code; ihre Wirkung ist noch nicht mit Spielern geprüft.

## Umfang und Nicht-Ziele
- Funktionsinventar, Alternativen, generierte Rasterentwürfe und sechs separate Icon-Kandidaten.
- Lokale interaktive Review-Workbench und schriftliche Übergabe einschließlich exakter Prompts, Herkunft und Prüfgrenzen.
- Keine Änderung an Runtime, Input, Regeln, Szenen oder aktiven Assets; keine Integration des parallelen Grafikpasses.

## Relevante Quellen
AGENTS.md; docs/PROJECT_BRIEF.md; docs/ARCHITECTURE.md; docs/CODEX_RULES.md; docs/IMPLEMENTATION_STATUS.md; docs/TASK_ROADMAP.md; docs/dev/ui_theme_component_library.md; docs/dev/html_report_workbench_contract.md; docs/ui_concepts/better_ui/README.md.

## Akzeptanzkriterien
- Vorhandene Funktionen und Vorschläge sind getrennt und mit Quellpfaden erfasst.
- Mindestens zwei vergleichbare Missionsrichtungen und ein Staging-Entwurf sind sichtbar.
- Icons liegen als separate PNG-Kandidaten vor; Transparenz, Größe und sichtbare Semantik sind geprüft.
- Begründungen, Zustände, Implementierungsanschlüsse und offene Prüfungen sind dokumentiert.
- Workbench funktioniert lokal und exportiert Entscheidungen/Notizen als JSON.

## Betroffene Dateien
docs/ui_concepts/ui_20261101/; docs/reports/STERNENBUERGERCHEN_UI_2026-11-01.html; docs/reports/assets/ui-2026-11-01/; diese Task-Datei; eine knappe Ergänzung in docs/IMPLEMENTATION_STATUS.md.

## Lokale Prüfung
Sichtprüfung der erzeugten PNGs; Metadaten-/Alpha-/Dateiverweisprüfung; Workbench im Browser einschließlich Variantenwahl und JSON-Export; git diff --check. Keine Godot-Laufzeitfreigabe durch diesen Konzepttask.

## Risiken / offene Punkte
Generierte Schrift und Layout sind Illustrationen. Texte, Controls, Zustände und Fokus müssen später nativ umgesetzt werden. Integration-Basis: 3cae5a216; der parallele Grafikbranch bleibt eine separat benannte Stilquelle. Nutzer hat SternenBürgerchen bestätigt.
