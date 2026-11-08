# UI, 2D-Vorlagen und Game Flow: Zusammenfassungs-Workbench

## Ziel / Problem / Sinnhaftigkeit
Der Nutzer möchte den heutigen Stand von 2D-Vorlagen, nativer UI und daraus
folgendem Spielablauf zusammenhängend beurteilen. Über viele Chats verteilte
Wünsche, spätere Korrekturen, offene Probleme und bewusst inaktive Ideen sollen
nachvollziehbar bleiben, ohne technische Teilnachweise als Gesamtabnahme zu lesen.

## Basis und Umfang
Dokumentationsbranch `task/ui-flow-bilanz-20261108` von
`integration/core-foundation` (`3cae5a216`). Die untersuchte Produktbasis ist
ausdrücklich der neuere Main-Stand `33bc504c4` vom 08.11.2026 im Hauptcheckout.
Die veraltete Branchbasis wird nicht als heutiger Spielstand dargestellt.
Der parallel laufende CPU-/HUD-R5-Auftrag bleibt außerhalb der Ergebnisabnahme.
Die native Worktreeanlage erstellte den Checkout, scheiterte anschließend mit
`Invalid string length`; erneutes Anhängen wurde abgewiesen. Der vorhandene
Checkout wird explizit über seinen absoluten Pfad verwendet.

Enthalten: lokale interaktive HTML-Workbench, echte unveränderte Ziel-/Istbilder,
gehashte Quellenkopien, Quellenregister, Entscheidungschronik, klickbarer
Spielablauf, Slice-Prüfvorschlag und exportierbare Nutzerbewertungen/Notizen.
Nicht-Ziele: Spielcode, neue Grafik, tatsächlicher Spieltest, Gameplay-/KI-Fixes,
neue Designfreigaben, Release, Mainintegration oder Veröffentlichung.

## Relevante Dokumente / Contracts
AGENTS, PROJECT_BRIEF, ARCHITECTURE, CODEX_RULES, IMPLEMENTATION_STATUS und
relevante Roadmapabschnitte; html_report_workbench_contract,
graphics_reference_revision_contract, ui_native_design_contract,
homebase_operations_ux_contract, homebase_direct_dropship_flow_contract,
mission_command_feedback_contract, fireteam_runtime_execution_path_contract,
GDD_STATUS, UI-Feedbackchronik 01.11., Playtest 05.11., Referenzpolish R3,
R4-Checkpoint und Fortsetzung 08.11.; tatsächlich gelesene relevante Chats.

## Akzeptanzkriterien
- Zielbild, normale native Aufnahme und historische Fixture sind unterscheidbar.
- Bildvergleich verbindet jeweils Erwartung, Istzustand, Abstand und Workflow.
- Normalweg ist Homebase Direct; FOB und begehbare Basis korrekt eingeordnet.
- Nutzerberichte, bestätigte Korrekturen, offene Befunde und Analysehypothesen
  sind getrennt. Ausbleibende Nutzerabnahme wird nicht erfunden.
- Entscheidungen nennen ältere Aussage, neuere Korrektur und tragende Quelle.
- Bewusst inaktive/ausgeschlossene Ideen gelten nicht automatisch als vergessen.
- Slice von Start bis zweitem Einsatz ist als noch durchzuführende Abnahme markiert.
- Suche, Filter, Tabs, Bilddialog, Eingaben und JSON-Export funktionieren lokal
  per file:// ohne Server/externe Bibliothek; Import schreibt nur Arbeitsnotizen.
- Export erfasst Entscheidungen, Notizen, Prüfparameter und Quellenstand.
- Bild-/Quellenmanifest enthält Herkunft und SHA-256; Report ist samt Assetordner
  außerhalb der ursprünglichen Produktdateien nutzbar.

## Betroffene Dateien
`docs/reports/STERNENBUERGERCHEN_UI_FLOW_BILANZ_2026-11-08.html`, zugehöriges
`docs/reports/assets/ui-flow-bilanz-2026-11-08/`,
`docs/qa/ui_flow_bilanz_20261108/`, diese Taskdatei und ein kurzer Eintrag in
`docs/IMPLEMENTATION_STATUS.md` des Dokumentationsbranches.

## Lokale Prüfung
Statische Pfad-/Hashprüfung und tatsächlicher Browserlauf per file:// bei
Desktop- und schmaler Größe. Tabs, Filter, Dialog, Notizen sowie JSON-Download,
Import und ungültige Importe prüfen. Kein Godotlauf für diese Dokumentationsaufgabe.

## Risiken / offene Punkte
Die fünf gesichteten relevanten Chats sind keine lückenlose Gesamtgeschichte.
Ein sehr großer älterer UI-Turn war über das Chatwerkzeug nicht ladbar; der
archivierte Nutzerexport und die Repochronik dienen dort als Ersatzbeleg.
Mehrere Screens haben nur historische native Aufnahmen. Historische Messwerte
unter Fremdlast belegen keine isolierte Leistung. Subjektives Stilurteil und
Verständlichkeit bleiben beim Nutzer bzw. einem echten Playtest.

## Status
Abgeschlossen als Dokumentations-Workbench: zehn Screenbereiche, neun
Flow-Schritte, 16 Befunde, zwölf Entscheidungseinträge und acht Ideen-/Scope-
Einordnungen. 117 Browserprüfungen auf Desktop/390px bestanden, echter
JSON-Download/Import und opt-in Persistenz geprüft. 51 Bild-/Quellenhashes
und Pfad-/ID-Verweise stimmen. Direkter file://-Browsernachweis durch
Werkzeug-URL-Policy blockiert; tatsächlicher Browserlauf über temporäre
127.0.0.1-Vorschau, Offlinepfade separat statisch geprüft. Keine Spieltests
oder Spieländerungen. Details: `docs/qa/ui_flow_bilanz_20261108/README.md`.
