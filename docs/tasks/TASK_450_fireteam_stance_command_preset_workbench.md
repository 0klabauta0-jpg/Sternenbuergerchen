# TASK_450 - Fireteam Stance Command Preset Workbench

## Ziel / Problem

Die Formation-Workbench soll klar zeigen, wo globale C/N/A-Stance-Grundwerte geaendert werden und wo statische Command/CNA-Formation und Sicherung gespeichert werden.

## Sinnhaftigkeit / Ursache

Bisher waren Speed, Sicht, FOV und Deckung nur ueber Auto-Profil und einzelne Slider sichtbar. Dadurch war unklar, ob C/N/A selbst editiert wird oder ob nur die aktuelle Command-Ansicht manuell veraendert ist.

## Umfang

- Aufklappbaren Editor fuer globale Stance-Grundwerte C/N/A ergaenzen.
- Charakterbogen-Hooks als sortierte Workbench-Checkliste exportierbar machen.
- Statische Command/CNA-Presets fuer Formation und Sicherung speicherbar/exportierbar machen.
- Begriffe fuer zeitabhaengige Bewegung wie raupenartig, ueberschlagend, Bounding oder Fireline aus der statischen Formationsebene herausnehmen.
- Workbench-Export um Stance-Profile, Command/CNA-Preset-Overrides und Character-Hook-Locks erweitern.
- Stance-Grundwerte nebeneinander darstellbar machen, damit C/N/A direkt vergleichbar sind.
- Leader-Position als FTL-Markierung auf einer Positionsnummer behandeln, nicht als Slot-Tausch.

## Nicht-Ziele

- Keine Runtime-Aenderung.
- Keine direkte Veraenderung von Charakterbogenwerten.
- Keine finale Area-Regel fuer Take/Engage/Defend.
- Keine Darstellung zeitabhaengiger Ablaufsequenzen. Erst steht/scannt/deckt A, dann bewegt B, dann Rollenwechsel gehoert in eine eigene Sequenz-Workbench oder Runtime-Task.

## Relevante Contracts / Dokumente

- `docs/dev/fireteam_behavior_modes_contract.md`
- `docs/dev/html_report_workbench_contract.md`
- `docs/tasks/TASK_448_fireteam_workbench_profile_clarity.md`
- `docs/tasks/TASK_449_fireteam_distance_cna_workbench_rules.md`
- `docs/reports/fireteam_formation_tuning_workbench.html`

## Akzeptanzkriterien

- Die Workbench enthaelt einen klar sichtbaren Editor fuer globale Stance-Grundwerte.
- C/N/A-Stance-Karten stehen auf breiten Viewports nebeneinander.
- Stance-Aenderungen wirken live auf die aktuellen Speed-/Sicht-/FOV-/Deckungswerte, wenn Auto-Profil aktiv ist.
- Leader-Position setzt das Sternchen auf die gewaehlte Position.
- Leader-Position aendert nur die FTL-Markierung und setzt keine manuell gezogene Formation zurueck; manuelles Positionsziehen setzt die Leader-Auswahl nicht auf `auto`.
- Nach Drag-and-drop bleiben manuelle Formationen beim Veraendern von `Buddy`, `Teamabstand` und `Reihe` erhalten; die Regler verformen die aktuelle Formation proportional statt auf das Formationspreset zurueckzuspringen.
- Ein freier Klick auf die Formation-Map setzt kein neues Ziel und verschiebt keine Formation; Ziel, Teamanker, Member und Blickrichtungen werden nur ueber ihre Griffe veraendert.
- Command/CNA-Presets koennen statische Formation und Sicherung speichern.
- Gespeicherte oder exportierte Workbench-Staende werden lokal als Workbench-Standard gemerkt und beim Reload automatisch wiederhergestellt; `Zuruecksetzen` loescht diesen lokalen Standard.
- Der eingebaute Startsatz enthaelt die zuletzt exportierten gespeicherten Formationen aus `_05`: Move C/N/A, Engage C/N/A und Take A.
- Der eingebaute Startsatz enthaelt auch die in `_05` gespeicherten Sicherungsbilder fuer Engage C/N/A und Take A.
- Der eingebaute Startsatz enthaelt auch die zuletzt bewusst getunten C/N/A-Stance-Grundwerte aus den Playtest-Exports: C 35/100/75/75/-0.3/+5, N 65/80/45/30/+0.3/0, A 100/50/20/35/0/-3 fuer Speed/Sicht/Deckung/Aim/Kontaktzeit/Zielhilfe.
- JSON-Export enthaelt `stance_profile_by_stance`, `command_stance_preset_overrides` und `character_sheet_hook_locks`.
- Der Contract beschreibt, dass Workbench-Stance-Profile, statische Formation/Sicherung und zeitabhaengige Ablaufsequenzen getrennte Ebenen sind.

## Betroffene Dateien

- `docs/reports/fireteam_formation_tuning_workbench.html`
- `docs/dev/fireteam_behavior_modes_contract.md`
- `docs/tasks/TASK_450_fireteam_stance_command_preset_workbench.md`
- `docs/TASK_ROADMAP.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung

- HTML-Script-Syntax pruefen.
- Browser-Smoke mit Playwright/Chrome.
- `git diff --check`

## Risiken / offene Punkte

- Die Workbench bleibt ein Tuning-/Exportwerkzeug und ist noch keine Runtime-Wahrheit.
- Area-Regeln und finale Skill-Skalierung muessen in eigenen Slices entschieden werden.
- Raupenartig/ueberschlagend kann in dieser Workbench nur als Standbild-Moment simuliert werden, nicht als echte Abfolge.
