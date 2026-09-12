# Neustart: Spielvision, Analyse und Arbeitsplan

## Ziel und Anlass
Der Nutzer möchte seine ursprüngliche und fortentwickelte Commander-Spielidee rekonstruieren und einen vollständigen Neustart planen: Zweierstart, Aufträge, Crew-Wachstum, Wirtschaft, Boden und Raum sowie große gestaltete Planetenregionen. Lieferumfang ist Analyse, Entwicklungsplan und lokale interaktive HTML, keine aktuelle Gameplay-Implementierung.

## Arbeitsbasis
- `integration/core-foundation` auf `3cae5a216d380b58fef92724540e95fbc49bde7e`.
- Eigener Dokumentations-Worktree `task-neustart-vision-2026-09-12`, Branch `task/neustart-vision-2026-09-12`.
- Alt-GDD, Originalnutzerwünsche vom 19.07. und 01.09.2026 und heutige Commander-Bestätigung werden mit Quellenstatus zusammengeführt.

## Umfang und Grenzen
- Historische Absichten, statisch belegter Bestand, heutige Wünsche und neue Vorschläge unterscheiden.
- Kenney/Rostwelt/Space-Opera-Konzeptbilder unverändert in eine eigenständige HTML einbetten.
- N0–N8 als überprüfbare Spielergebnisse planen, offene Grundsatzfragen sichtbar lassen.
- Keine Runtime, Assets, alten Arbeitsbäume, fremden WIP oder alten Roadmap-Pakete ändern.

## Relevante Dokumente
`PROJECT_BRIEF.md`, `ARCHITECTURE.md`, `CODEX_RULES.md`, `IMPLEMENTATION_STATUS.md`, `GDD_STATUS.md`, `DESIGN_NOTES.md`, `dev/html_report_workbench_contract.md`, bestehende Landschaftsberichte und ausgewählte Missions-/Personalquellen.

## Dateien und Akzeptanz
- `docs/reports/STERNENBUERGERCHEN_NEUSTART_2026-09-12.html`: deutsch, offline, mobil und Desktop; Quellen, Entscheidungen, Notizen, lokale Speicherung, JSON-Export und Textfallback.
- `docs/superpowers/plans/2026-09-12-sternenbuergerchen-neustart.md`: Abhängigkeiten, vorgeschlagene Zustandsbesitzer, konkrete erste Umsetzung, Abnahmegates und Risiken.
- Diese Task-Datei und ein knapper Dokumentationseintrag in `IMPLEMENTATION_STATUS.md`.
- Browserprüfung: keine JavaScript-Fehler, keine fehlenden Bilder, keine horizontale Überbreite, Navigation/Filter/Notizen/Export funktionieren.

## Risiken / Evidenzgrenze
Keine neue Godot-Messung oder vollständige Codeprüfung. Historische Performance bleibt an ihre Mess-SHAs gebunden. Der Plan ist ein Reviewentwurf, kein umgesetzter Neustart und keine automatische Ersetzung des alten Projektbriefs. Eine bessere Modellgeneration allein ist kein Erfolgsnachweis.

## Lokale Abschlussprüfung
- Playwright/Chromium über direkten `file://`-Aufruf, 12.09.2026 16:13 UTC.
- Desktop 1440x1000 und Mobile 390x844: kein horizontaler Seitenüberlauf; Screenshots angesehen.
- 13 Kapitel, 11 offene Entscheidungsfelder; sämtliche lokalen Quelllinks und Anker erreichbar, keine doppelten IDs, alle vier eingebetteten Bildverwendungen geladen.
- JavaScript-Syntax, Missionsschritte, Boden-/Raumfilter, Forschungsbaum, Notizen/Entscheidungen nach Reload, JSON-Download und Exporttext, Import-Roundtrip, ungültiger Import sowie Bilddialog erfolgreich geprüft.
- Browserfehler: 0; externe Ressourcenanfragen: 0. Testnotizen nach Prüfung entfernt.
- Unabhängiger Inhaltsreview: eine Timing-Differenz zwischen Plan und HTML korrigiert (Basis vor N3, Weltverbindung vor N4); Startschiff als frühe Entscheidung im Plan ergänzt.
- Die HTML enthält alle Inhalte und Bilder selbst. Verlinkte Markdown-Quellen und der Zusatzplan sind ergänzende lokale Dokumente.
