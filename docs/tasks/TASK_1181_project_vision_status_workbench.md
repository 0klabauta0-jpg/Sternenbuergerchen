# TASK 1181 - Project Vision And Status Workbench

## Ziel / Problem

Eine eigenstaendige HTML-Workbench soll die Idee von `SternenBuergerchen`, den belegten Projektstand, offene Pflichtarbeit, moegliche Erweiterungen und den konkreten Nutzen von GPT-5.6 ausgewogen erklaeren.

Die vorhandene Dokumentation ist belastbar, aber ueber viele Architektur-, Status-, Task- und Verifier-Dateien verteilt. Fuer Projektentscheidungen und externe Leser fehlt eine kompakte, visuell gut lesbare Gesamterzaehlung.

## Sinnhaftigkeit / Ursache

- Die Spielvision soll ohne Kenntnis von ueber tausend Task-Eintraegen verstaendlich werden.
- Implementiertes, teilweise ausgereiftes und zukuenftiges Verhalten muss klar getrennt bleiben.
- Die Seite soll zugleich Erklaerung und lokale Entscheidungs-Workbench sein.

## Umfang

- Neuer Report unter `docs/reports/` auf Basis des HTML-Workbench-Contracts.
- Zusammenfassung von Spielidee, Core Loop und Commander-/FTL-Fantasie.
- Evidenzbasierte Einordnung des aktuellen Stands aus Projektbrief, Architektur, Implementierungsstatus, Roadmap und relevanten Contracts.
- Trennung von Pflichtarbeit und optionaler Zukunftsvision.
- Konkrete, begrenzte Darstellung der Vorteile von GPT-5.6 fuer die weitere Arbeit.
- Lokale Controls, Notizen, Persistenz und JSON-Export.

## Nicht-Ziele

- Keine Runtime-, Gameplay-, Balance- oder Godot-Szenenaenderung.
- Keine pauschale Neubewertung aller historischen Tasks.
- Keine verbindliche Erweiterung des V1-Scopes.
- Kein externer Server und keine externen Assets.

## Relevante Contracts / Dokumente

- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/html_report_workbench_contract.md`
- `docs/dev/fireteam_runtime_execution_path_contract.md`
- `docs/superpowers/specs/2026-07-17-project-vision-status-workbench-design.md`

## Akzeptanzkriterien

- Die HTML erklaert Spielidee und Core Loop fuer einen neuen Leser.
- Der Projektstand unterscheidet mindestens vier sichtbare Evidenzstufen.
- Bereits umgesetzte Spielerpfade werden nicht mit Zukunftsvisionen vermischt.
- Pflichtarbeit und optionale Erweiterungen sind getrennt priorisierbar.
- Die GPT-5.6-Sektion nennt konkrete Arbeitsvorteile und verbleibende Grenzen.
- Der Report funktioniert direkt per `file://` und ohne externe Abhaengigkeiten.
- Navigation, Filter, editierbare Notizen und lokale Persistenz funktionieren.
- Ein sichtbarer Button `JSON exportieren` erzeugt das Workbench-v1-Schema.
- Desktop- und Mobile-Pruefung zeigen keine unlesbaren Ueberlagerungen.

## Betroffene Dateien

- `docs/reports/STERNENBUERGERCHEN_SPIELIDEE_PROJEKTSTAND_GPT56_2026-07-17.html`
- `docs/tasks/TASK_1181_project_vision_status_workbench.md`
- `docs/superpowers/specs/2026-07-17-project-vision-status-workbench-design.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung

- Statischer HTML-/Schema-Check.
- Browser-Smoke per `file://` fuer Navigation, Filter, Notizen, Persistenz, Export und Import.
- Desktop- und Mobile-Screenshots.
- `git diff --check`.

## Risiken / offene Punkte

- Der Implementierungsstatus ist umfangreich; der Report muss nach Spielerwirkung verdichten, ohne einzelne Tasks als vollstaendige Produktreife zu ueberinterpretieren.
- Aussagen zu GPT-5.6 bleiben konkrete Entwicklungsfaehigkeiten, keine Garantie fuer Fehlerfreiheit oder Spielqualitaet.
- Die Workbench speichert nur Arbeitsnotizen und erzeugt keine zweite Gameplay-Wahrheit.
