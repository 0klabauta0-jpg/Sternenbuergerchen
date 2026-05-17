# HTML Report Workbench Contract

## Zweck

Dieser Contract beschreibt das Standardformat fuer interaktive HTML-Arbeitsreports in `docs/reports/`. Das Format ist fuer Playtests, Architekturentscheidungen, Kontrolllisten, Tuning-Workbenches und Review-Arbeitsseiten gedacht.

## Wann verwenden

Wenn Codex eine neue HTML-Datei in `docs/reports/` erstellt oder einen bestehenden Report groesser umbaut, soll der Report als Workbench gebaut werden, ausser der User verlangt ausdruecklich eine rein statische Seite.

## Pflichtbestandteile

- Klarer Kopfbereich mit Titel, Kurzbeschreibung, Datum/Task und aktuellem Stand.
- Navigation oder Tabs, wenn die Seite mehr als einen Themenblock hat.
- Lesbare Bereiche fuer Erwartung, Ist-Zustand, offene Fragen und naechste Schritte.
- Bedienbare Elemente fuer Playtest-Status, Entscheidungen, Parameter und Notizen.
- Sichtbarer Button `JSON exportieren`.
- Exportbereich oder Kopierfunktion, damit der JSON-Inhalt ohne Zusatztool an Codex gegeben werden kann.
- Optionaler Button zum Verbinden eines lokalen Reports-Ordners, wenn der Browser die File System Access API anbietet. Dieser Zugriff darf nur nach sichtbarer Browser-Freigabe erfolgen.

## JSON-Export

Der Export muss lokal per `file://` funktionieren und mindestens folgende Struktur liefern:

```json
{
  "schema": "sternenbuergerchen.html_workbench.v1",
  "report_id": "kurzer_report_id",
  "title": "Reporttitel",
  "exported_at": "ISO-8601 Zeitstempel",
  "controls": {},
  "notes": {},
  "active_choices": {},
  "computed": {},
  "metadata": {}
}
```

Der Export soll erfassen:

- Checkboxen und Radio-Buttons.
- Textfelder, Zahlenfelder, Slider, Selects und Textareas.
- `contenteditable`-Notizen.
- Buttons mit `data-choice-group`, wenn sie eine aktive Auswahl darstellen.
- Berechnete Werte, wenn die Seite ein Tuning- oder Diagnosewerkzeug ist.
- Eindeutige Export-Dateinamen mit Zeitstempel, damit mehrere Playtest-Staende erhalten bleiben.

Wenn der Browser lokalen Ordnerzugriff erlaubt, darf `JSON exportieren` nach vorheriger oder beim ersten Export angefragter Freigabe neue JSON-Dateien in den gewaehlten Reports-Ordner schreiben. Wenn das nicht verfuegbar ist oder abgelehnt wird, muss der Download-/Textfeld-Fallback weiter funktionieren.

## Import

Import ist empfohlen, aber nicht Pflicht. Wenn Import vorhanden ist, darf er nur die HTML-Bedienelemente der Seite setzen. Er darf keine Projektdateien schreiben und keine Runtime-Wahrheit erzeugen.

## Abgrenzung

- HTML-Workbench-Daten sind Arbeitsnotizen und Playtest-Kommunikation.
- Gameplay-State bleibt bei Runtime, Simulation, Datenmodellen und Contracts.
- Die Workbench darf keine zweite Mission-, Unit-, Combat- oder Fireteam-Wahrheit einfuehren.

## Vorlage

Neue Reports sollen von `docs/reports/_html_workbench_template.html` abgeleitet werden, wenn keine passendere bestehende Workbench als Vorlage dient.
