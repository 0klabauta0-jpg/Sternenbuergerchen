# UI-Dichte Heimatbasis: PC-Dichte fuer Seitenleiste, Personenkarten, Trupp und Ausruestung (P6, 15.11.2026)

## Ziel

Die Heimatbasis-Oberflaeche (Seitenleiste, Personen- und Truppkarten, Trupp-und-Ausruestungs-Ansicht, Kommando-Dock) soll bei 1920x1080 schlanker und fuer Maus und Tastatur dichter werden. Nutzerurteil: "klobig und breit, eher Telefon- als PC-Bedienung".

## Ursache

Laut `docs/tasks/UI_DICHTE_BESTANDSAUFNAHME_2026_11_15.md` setzt `scripts/meta/homebase_operations_presenter.gd` seine Groessen an Ort und Stelle: `_button()` 40 hoch mit Schrift 17, Navigationsknoepfe 46 hoch mit Icon 36, Personenkarten 99 hoch, Aktionsleisten ueber die ganze Spaltenbreite (1010 px). Die Ausruestungs-Slots (264x80, Icon 72) und Lagerkacheln (126x80) kommen aus `scripts/ui/components/personnel_inventory_panel.gd`. Es gibt keine gemeinsame Dichte-Tabelle.

## Umfang

- Eine Dichte-Tabelle `DENSITY` oben in `homebase_operations_presenter.gd` ("PC density, user decision 14.11.2026"); alle betroffenen Groessen des Presenters lesen daraus.
- Zielwerte (Entscheidung Hauptchat): Standardbutton 30 hoch (Haupt-Aktion 34), Schrift 15; Navigationsknoepfe 36 hoch, Icon 24, Schrift 15; Unterpunkte 30 hoch, Schrift 14; Personenkarten ca. 64 hoch mit Portrait ca. 48x48; Aktionsleisten "Aus Trupp entfernen"/"Charakter ansehen" in Inhaltsbreite (hoechstens 280), 30 hoch, links; Ausruestungs-Slots ca. 240x60 mit Icon 48, Lagerkacheln ca. 110x64.
- `personnel_inventory_panel.gd`: nur die Groessen von Slot und Lagerkachel, als benannte Konstanten oben in dieser Datei (das Panel hat eigene Groessen und wird auch vom Charakterblatt benutzt).
- Seitenleistenbreite nur verringern, wenn jedes deutsche Label hoechstens zweizeilig und ohne Abschneiden bleibt.

## Nicht-Ziele

- Keine anderen Screens (Mission-HUD, Hauptmenue, Sternkarte, Smart Mobile, Dienste-Panel).
- Kein Verhalten, keine Reihenfolge, keine Texte, Farben, Icons oder Knotennamen aendern; keine Umbenennung von Signalen oder Funktionen; kein Umformatieren.
- Bestehende Ueberlappungen, die nicht aus den angefassten Groessen folgen (z. B. "Standort: ..." gegen "Versorgung oeffnen", Raumbeschriftungen in der 3D-Ansicht, Kampagnen-Hinweiskarte ueber den Spalten), werden nur gemeldet.
- Theme-Dateien (`tactical_ui_theme.gd`, `base_management_skin.gd`) bleiben unveraendert.

## Regeln, die die Zahlen uebersteuern

Kein Klickziel unter 28 px, kein Fliesstext unter 14 px, kein abgeschnittener oder ueberlappender Text.

## Akzeptanzkriterien

- Alle oben genannten Groessen stehen in `DENSITY` (Presenter) bzw. in benannten Konstanten (Inventar-Panel); keine verstreuten Literale mehr fuer diese Groessen.
- Vorher/Nachher-Aufnahmen 1920x1080 unter `docs/qa/ui_dichte_20261115/p6_vorher_*.jpg` und `p6_nachher_*.jpg`: Basis mit Seitenleiste und Dock, Trupp und Ausruestung (auch nach unten gescrollt), Personal mit offenen Untermenues.
- Keine abgeschnittenen Woerter, keine neuen Ueberlappungen in diesen Aufnahmen.
- Die ausgewaehlten Tests haben nach der Aenderung keine neuen FAIL-Zeilen; angepasste Erwartungen sind unten einzeln aufgefuehrt.

## Betroffene Dateien

- `scripts/meta/homebase_operations_presenter.gd`
- `scripts/ui/components/personnel_inventory_panel.gd` (nur Groessenkonstanten von Slot und Lagerkachel)
- `docs/tasks/UI_DICHTE_HEIMATBASIS_2026_11_15.md`, `docs/IMPLEMENTATION_STATUS.md`
- `docs/qa/ui_dichte_20261115/p6_*.jpg`

## Lokale Pruefung

- Aufnahmen mit echtem Renderer (`--rendering-driver opengl3 --resolution 1920x1080`), Weg wie in der Bestandsaufnahme: Hauptmenue -> Kampagne neu -> `request_operation("navigate", ...)`. Knotentabellen ausserhalb des Repos (`/home/claude/work/p6_out`).
- Headless-Tests vor und nach der Aenderung (Liste und Ergebnis siehe Abschnitt "Ergebnis").

## Risiken / offene Punkte

- Drei Textzeilen (Name, Rolle, Status) mit mindestens 14 px plus ein 28 px hohes Namens-Klickziel passen nicht in 64 px; die Karte wird etwas hoeher als 64.
- Das Inventar-Panel wird auch im Charakterblatt verwendet; Slot- und Kachelgroessen aendern sich dort mit.
- Dropdowns benutzen den Theme-Innenrand (6 px oben/unten); ohne Theme- oder Farbaenderung erreichen sie die 30 px nicht ganz.

## Ergebnis

Umgesetzt in `homebase_operations_presenter.gd` (Tabelle `DENSITY`, Hilfsfunktionen `_button_style` und `_card_style` fuer den kleineren Innenrand) und in `personnel_inventory_panel.gd` (Konstanten `SLOT_*`, `STORAGE_TILE_*`, Hilfsfunktion `_compact_tile` fuer den Innenrand der Lagerkacheln; Rucksack-Kacheln unveraendert).

### Messwerte vorher/nachher (1920x1080, Kampagne neu, lebende Knoten)

| Element | Vorher | Nachher |
|---|---|---|
| Navigationsknopf einzeilig (Personal, Sternkarte, Smart Mobile) | 166x46, Schrift 17, Icon 36 | 166x36, Schrift 15, Icon 24 |
| Navigationsknopf mit Untermenue (Basis erkunden, Flugdeck) / Aufklapp-Pfeil | 132x50 / 32x50 | 132x36 / 32x36 |
| "Trupp & Ausruestung" (fester Zeilenumbruch) | 166x50 | 166x44 |
| Unterpunkte (Bauen ... Tankservice) | 166x30, Schrift 13 | 166x30, Schrift 14 |
| "Datenterminal / Hochladen" | 166x48 (2 Zeilen, Schrift 13) | 166x48 (2 Zeilen, Schrift 14) |
| Seitenleistenbreite | 166 | 166 (unveraendert, siehe unten) |
| "Charakterdetails", "Neuer Trupp" | 166x40 / 121x40, Schrift 17 | 166x30 / 109x30, Schrift 15 |
| Personenkarte Personal / Trupp | 267x99 / 280x99 | 267x74 / 280x74 |
| Portrait in der Karte | 52x87 (Personal), 72x87 (Trupp) | 48x48 (beide) |
| Name in der Karte | Schrift 19, 39 hoch | Schrift 16, 28 hoch, buendig mit Rolle/Status |
| Zuweisen-Knopf (+ / Haken) | 40x42 | 40x34 |
| Dropdowns (Sortierung, Trupp, Schiff) | 267..280x42, Schrift 17 | 267..280x34, Schrift 15 |
| Suchfeld / "Person zurueck ins Personal" | 267x40 / 267x34 | 267x32 / 267x32 |
| "Aus Trupp entfernen" / "Charakter ansehen" | 1010x40, Schrift 17 | 167x30 / 155x30, Schrift 15, links |
| Ausruestungs-Slot | 264x80, Icon 72 | 240x60, Icon 48 |
| Lagerkachel Basislager | 126x80, Icon 32, Innenrand 10 | 110x68, Icon 28, Innenrand 6/4 |
| Container "Basislager" | 320x258 | 288x234 |
| Kommando-Dock | 1920x161, Tasten 75..83x58 | unveraendert |

Nicht erreicht und warum:
- Personenkarte 74 statt ca. 64: Name (Klickziel mindestens 28) plus Rolle und Status (je 14 px Schrift, 20 px Zeile) plus 2x3 Innenrand ergeben 74. Weniger nur mit kleinerer Schrift oder weniger Zeilen.
- Lagerkachel 68 statt 64: dreizeilige Beschriftung ("Leichte / Ruestung / x 2") mit 14 px braucht 60 plus Innenrand; die Gitterzeile zieht die Nachbarkachel mit.
- Dropdowns 34, Suchfeld und Ablagestreifen 32 statt 30: sie benutzen den Theme-Innenrand (6 px oben/unten); eine eigene Stylebox wuerde die Farben aendern.
- Zuweisen-Knopf 34 statt 30: der Haken-Knopf ist meist deaktiviert und nutzt dann den Theme-Stil "disabled" mit 6 px Innenrand.
- Seitenleistenbreite bleibt 166: "Werkstatt / Blueprints" braucht bei 14 px ca. 150 px Text plus 16 px Innenrand; jede schmalere Spalte bricht diesen Punkt und "Basis erkunden" in zwei Zeilen und macht die Leiste hoeher. Ein Gewinn von wenigen Pixeln Breite gegen mehr Hoehe lohnt nicht.
- Kommando-Dock: die neun Tasten sind Aktionskacheln (Icon ueber Text, 5er-Gitter, 75..83x58). Reine Textkacheln stehen in derselben Gitterzeile wie Icon-Kacheln und wuerden auf die Zeilenhoehe gestreckt; die Dockhoehe haelt ausserdem die Untergrenze 180 in `explorable_homebase.gd` und die Personenkarte. Eine Verkleinerung auf 56 haette nichts Sichtbares geaendert; `explorable_homebase.gd` bleibt unberuehrt.

### Aufnahmen

`docs/qa/ui_dichte_20261115/p6_vorher_*.jpg` und `p6_nachher_*.jpg`: `03_basis_dock`, `04_trupp_ausruestung`, `04c_trupp_ausruestung_unten` (Ausruestungsspalte nach unten gescrollt), `05_personal_untermenues_offen`.

Sichtpruefung nachher: keine abgeschnittenen Woerter, keine neuen Ueberlappungen. Weiterhin sichtbar (nicht durch diese Aenderung verursacht, nicht behoben):
- "Standort: Heimathafen . Asterholm" ueberlappt "Versorgung oeffnen" oben rechts (Basisansicht).
- Kampagnen-Hinweiskarte und Hilfetext ueberdecken Spaltenkoepfe und Personalliste (Bilder 04, 05).
- Raumbeschriftungen der 3D-Basis ueberlappen sich ("Smart Mobile"/"Personal"/"Tomas Ibarra", "Flugdeck"/"Entermesser 1").
- Lagerkachel bricht "Sanitaetsgeraet" mitten im Wort (vorher "Sanitaetsg|eraet", jetzt "Sanitaets|geraet").
- Optischer Eindruck: Unterpunkte (14 px Standardschrift) wirken groesser als die Hauptpunkte (15 px Barlow Condensed).
- Inventar-Panel: "Verschieben", "Anlegen" und deren Dropdowns bleiben 43 hoch (eigene Panel-Groessen, nicht Teil dieses Pakets).
- Dock: "WEITERE PERSONEN" und die Personenkachel nutzen Schrift 12 (unter 14), in `explorable_homebase.gd`.

### Tests (Linux headless, vorher ohne Aenderung, nachher mit Aenderung)

Gleich vor/nach: `base_management_access_verifier` 26/0, `character_navigation_equipment_verifier` 4 FAIL (bekannt), `reference_polish_r3_20261106_homebase_verifier`, `playtest_20261105_homebase_operations_verifier`, `base_management_visuals_verifier`, `playtest_20261110_operations_layout_verifier`, `flugdeck_layout_verifier`, `playtest_20261105_explorable_homebase_verifier` (jeweils dieselben FAIL-Zeilen vorher und nachher), `homebase_command_dock_verifier` 10/0, `playtest_details_inventory_verifier` 28/0. `playtest_hit_area_audit_verifier`: failed=0 vorher und nachher; die Liste teilweise weggescrollter Knoepfe (sichtbarer Rest unter 28 px) waechst von 4 auf 13 Eintraege (Navigationsspalte und Truppliste bei 1280x720, Lagerkacheln im Scrollbereich).
Besser nachher: `playtest_20261109_navigation_verifier` ("Primary departure action fits 1280x720" jetzt PASS), `playtest_20261109_personnel_dragdrop_verifier` ("Runtime-bound 1280x720 flightdeck keeps actual departure button inside viewport" jetzt PASS, 45/0).
Nicht lauffaehig hier: `astra_menu_fixes_20261113` (REVIEW2_ISOLATION_REFUSED).
Keine Test-Erwartung wurde geaendert.
