# TASK_445 - HTML Report Workbench Standard

## Ziel / Problem

Interaktive HTML-Reports unter `docs/reports/` sollen kuenftig im gleichen Workbench-Format entstehen: gut lesbar, bedienbar und mit JSON-Export, damit Playtest-Auswahlen, Notizen und offene Entscheidungen wieder in Codex eingelesen werden koennen.

## Sinnhaftigkeit / Ursache

Der Report `fireteam_behavior_playtest_workbench.html` hat sich als guter Kommunikationsweg erwiesen. Ohne verbindliche Vorlage muesste jede neue HTML-Seite Export-, Notiz- und Statuslogik neu erfinden.

## Umfang

- Neuer Contract fuer HTML-Workbench-Reports unter `docs/dev/`.
- Wiederverwendbares HTML-Template unter `docs/reports/`.
- Interaktive Fireteam-Formation-Tuning-Workbench als erstes nutzbares Werkzeug fuer den naechsten Playtest-Pass.
- Dauerhafte Repo-Regel in `AGENTS.md`, damit neue HTML-Arbeitsreports dieses Format verwenden.
- Roadmap- und Status-Dokumentation fuer den Task.

## Nicht-Ziele

- Keine Runtime-Aenderung.
- Keine automatische Migration bestehender Reports.
- Kein globaler Codex-Skill ausserhalb dieses Repositories.
- Kein automatisches Auslesen von Browser-Downloads.
- Kein stiller Dateisystemzugriff ohne Browser-Freigabe.

## Relevante Contracts / Dokumente

- `AGENTS.md`
- `docs/CODEX_RULES.md`
- `docs/reports/fireteam_behavior_playtest_workbench.html`

## Akzeptanzkriterien

- Neue HTML-Arbeitsreports haben eine klare Workbench-Struktur mit Uebersicht, Test-/Entscheidungsteilen und Notizen.
- Das Template enthaelt einen sichtbaren Button `JSON exportieren`.
- Der Export sammelt Checkboxen, Radio-Buttons, Inputs, Selects, Textareas, `contenteditable`-Notizen und aktive Optionsbuttons.
- Der Export ist lokal per `file://` nutzbar, ohne Server und ohne externe Abhaengigkeiten.
- Der Export erzeugt eindeutige Dateinamen mit Zeitstempel; wenn der Browser Dateisystemzugriff erlaubt, kann ein Reports-Ordner verbunden werden, in den weitere Exporte als neue JSON-Dateien geschrieben werden. Ohne Freigabe bleibt der normale Download-/Textfeld-Fallback aktiv.
- Die Fireteam-Formation-Workbench zeigt ein verschiebbares Fireteam, ein verschiebbares Ziel, Formationsabstaende, Sicht-/Feuersektoren und Slider fuer Geschwindigkeit, Sicht, Buddy-Abstand, Buddy-Team-Abstand und Reihenversatz.
- Der Formation-Export enthaelt die eingestellten Werte und berechnete Member-Positionen.
- Einzelne Teammember koennen in der Formation-Workbench direkt gezogen werden; Buddy-Abstand, Buddy-Team-Abstand und Reihenversatz werden daraus zurueck in die Regler geschrieben.
- Buddy-Teams sind explizit sichtbar und konfigurierbar, immer als Zweierteams.
- Zusaetzliche Tuning-Parameter fuer Formationstyp, Sicherungssektor, Cohesion-Radius und Deckungsprioritaet sind exportierbar.
- `FOV`, `Waffen-RW`, `Tile-Gr.` und `Cohesion` sind im Tool klar benannt und erklaert.
- Grundformation und Sicherungsbild sind im Tool von abgeleiteten Runtime-/Profilwerten getrennt.
- `Tile-Gr.` veraendert das sichtbare Raster; `Waffen-RW` wird aus der gewaehlten Waffe abgeleitet; `Cohesion` zeigt den Zusammenhaltsradius um den Teamanker.
- Speed, Sicht und FOV werden als zusammenhaengendes Command-/Stance-Profil sichtbar, aber nicht mit der manuell gesetzten Grundformation vermischt.
- Command-/Stance-Profil und Grundformation koennen getrennt geschaltet werden: Command-Wechsel darf eine manuell abgestimmte Formation nicht unbeabsichtigt ueberschreiben.
- Die Formation-Workbench exportiert einen benannten Formationskandidaten inklusive Leader-Position; der Export ist noch kein Runtime-Default.
- Die Formation-Workbench kann Fireteam-Groessen 2, 4, 6 und 8 anzeigen. Die Mannequins sind als Positionen 1-8 nummeriert, damit Roster-/NPC-Zuordnung spaeter separat entschieden werden kann.
- Grundformationen koennen fuer genau einen Command/Stance als Override gemerkt, aktiviert/deaktiviert und exportiert werden.
- Buddyteams koennen abgeschaltet werden; dann zeigt die Workbench eine lose Wolkenformation ohne Buddy-Links.
- Die Leader-Position wird als konkrete Positionsnummer 1-8 gewaehlt, nicht nur als grobe vorn/hinten/lateral-Regel.
- Manuell gedrehte Sicherungsbilder koennen fuer genau einen Command/Stance als Override gemerkt und exportiert werden.
- FOV ist auf 10-90 Grad begrenzt und zeigt einen experimentellen Fokusfaktor fuer die Sichtweiten-Diagnose.
- Einzelne Teammember koennen ueber einen Drehgriff in ihrer Blick-/Waffenrichtung rotiert werden; die Richtung wird exportiert.
- Ein eigener Matrix-Tab zeigt Move, Engage, Take und Defend jeweils in C/N/A als kompakte Vergleichsbilder.

## Betroffene Dateien

- `AGENTS.md`
- `docs/dev/html_report_workbench_contract.md`
- `docs/reports/_html_workbench_template.html`
- `docs/reports/fireteam_formation_tuning_workbench.html`
- `docs/tasks/TASK_445_html_report_workbench_standard.md`
- `docs/TASK_ROADMAP.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung

- Template lokal im Browser oeffnen und Export-Button pruefen.
- Formation-Workbench lokal im Browser oeffnen, Team/Ziel verschieben, Slider aendern und JSON exportieren.
- `git diff --check`

## Risiken / offene Punkte

- Der JSON-Export ist ein Kommunikationsartefakt, keine Gameplay-Wahrheit.
- Die Formation-Workbench ist zunaechst ein Tuning-/Kommunikationsmodell und noch nicht direkt an Runtime-Konstanten gebunden.
