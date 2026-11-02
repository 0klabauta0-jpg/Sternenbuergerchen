# UI-Zielbildabgleich · 02.11.2026

## Ziel / Problem
Die tatsächlichen nativen UI-/GM01-Bilder liegen aus Nutzersicht noch zu weit von den bestätigten 2D-Vorlagen entfernt. Vor einer weiteren Grafikiteration zuerst prüfen, ob ältere Dokumentregeln die Zielnähe unbeabsichtigt beschränken; danach echte Enginebilder mit ihren jeweils zugeordneten 2D-Zielen vergleichen und eine begrenzte nächste Runde daran ausrichten.

## Sinn / Ursache
Der Dokumentaudit fand keine allgemeine Sperre gegen referenzgeführte Grafikrevisionen. Frühere UI-Zwischenstände schreiben jedoch Rahmen- und Pixelgrößen unnötig endgültig fest; R4 enthält inzwischen überholte Square8-Angaben. Technisch vorhandene Hexkanten sind noch kein Nachweis menschlicher Rastererkennbarkeit. Terrain-Sichtmaske und dynamischer Gegnerfilter müssen getrennt erklärt und geprüft werden.

## Umfang / Reihenfolge / Nicht-Ziele
1. Dokumentaudit abschließen und nur aktuelle Gestaltungsautorität, historische Grenzen, Hexstand sowie Sicht-/Lesbarkeitsanforderungen klarstellen.
2. Erst danach tatsächliche native Bilder öffnen und direkt mit den bestätigten Original-2D-Zielen vergleichen; Brückenbilder bleiben ergänzende Übersetzungshilfen.
3. Eine begrenzte visuelle Folgerunde aus den wichtigsten sichtbaren Abständen ableiten. Änderungen und Nachweise getrennt als Vorschlag, Umsetzung und Prüfung kennzeichnen.

Keine neue UI-/Gameplay-Wahrheit, keine geänderten Commands, Gegnerinformationen oder Laufzeitgates. Exakte bestehende Cutlass-Identität erhalten. Keine rückwirkende Änderung historischer Nachweise; keine Mainintegration, Veröffentlichung oder pauschale Spielabnahme.

## Relevante Contracts / Dokumente
- `docs/PROJECT_BRIEF.md`, `docs/ARCHITECTURE.md`, `docs/CODEX_RULES.md`, `docs/IMPLEMENTATION_STATUS.md`
- `docs/dev/graphics_reference_revision_contract.md`
- `docs/dev/ui_native_design_contract.md`
- `docs/dev/ui_theme_component_library.md`
- `docs/dev/gm01_frontier_map_contract.md`
- `docs/ui_concepts/ui_20261102_r4/BILDPRUEFUNG_UND_UEBERGABE.md`

Zusätzliche Fortschreibung: `docs/ARCHITECTURE.md` (aktueller GM01-Hexverbraucher statt nur erstem Slice) und `docs/IMPLEMENTATION_STATUS.md` (abgeschlossene begrenzte Runde).
- Bestätigte UI-Ziele unter `docs/reports/assets/ui-2026-11-01/`; zugeordnete Gelände-/Außenpostenziele unter `docs/reports/assets/grafik-2026-11-01/`

## Akzeptanzkriterien
- Die zuletzt bestätigten Original-2D-Zielbilder und aktuelle Nutzeranweisungen sind Gestaltungsautorität; R4-Brücken oder ältere native Zwischenmaße ersetzen sie nicht.
- Referenzgetreue dekorative Raster-/Nine-Patch-/mehrschichtige Rahmen sind um echte native Controls zulässig. Text, Fokus, Eingabe, Zustandsbesitz und Erreichbarkeit bleiben erhalten.
- Frühere Zahlen und schlichte Rahmen sind als Ausgangsstand erkennbar; kompakte quadratische Aktionen, zwei mögliche Reihen und lesbare Beschriftung bleiben Ziel.
- Der aktuelle GM01-Stand ist als48×48Hex dokumentiert; historische Square8-Stände werden ausdrücklich zeitlich eingeordnet.
- Rastererkennbarkeit wird am tatsächlich gerenderten Spielabstand bei1280×720 und1920×1080 menschlich beurteilt; Geometrie-/Pixelchecks allein reichen nicht.
- Die bekannte Terrain-Bodenmaske, der entfernte schwarze Aufbaukasten und der unabhängige Gegner-Sichtfilter werden nicht gleichgesetzt.
- Dokumentkorrektur erfolgt vor dem neuen Bildvergleich. Eine folgende visuelle Runde benennt Ziel, sichtbaren Abstand, Änderung und echte native Nachprüfung; keine Stilfreigabe durch technische Checks behaupten.

## Betroffene Dateien
Dokumentkorrektur ausschließlich in dieser Task-Datei sowie:
- `docs/dev/ui_native_design_contract.md`
- `docs/dev/ui_theme_component_library.md`
- `docs/dev/gm01_frontier_map_contract.md`
- `docs/ui_concepts/ui_20261102_r4/BILDPRUEFUNG_UND_UEBERGABE.md`

Begrenzte Folgerunde nach dem direkten Bildvergleich: gemeinsame passive, mehrschichtige Rahmen in `scripts/ui/tactical_ui_theme.gd`, `scripts/meta/meta_ui_skin.gd` und `scripts/ui/reference_panel_frame.gd`; kompakte native Missionsgeometrie in `scripts/meta/drop_light_layout_contract.gd` und `scripts/ui/mission_a5_hud_layout.gd`; ausschließlich sichtbare Hexkanten in `scripts/terrain/terrain_map_3d_view.gd`. Keine Modell-, Licht-, Karten- oder FoW-Regeländerung. Die native Rahmenrunde ersetzt die weiterhin nötige Gebäude-/Geländerevision nicht.

Neue isolierte Nachweise unter `docs/qa/ui_zielbild_20261102/` sowie Capture-Adapter `scripts/tests/ui_zielbild_normal_capture.gd`; bestehender A5-Verifier wird auf die bewusst geänderte Zielgeometrie angepasst, seine Callback-/Status-/Überlappungsprüfungen bleiben erhalten. Neue Workbench `docs/reports/STERNENBUERGERCHEN_UI_ZIELBILD_2026-11-02.html` vergleicht Original, vorherigen nativen Stand und neue echte Aufnahmen.

Zusätzlich `scripts/meta/npc_compact_card.gd` (normale Namenszeile 14px, explizite Spezialslot-Overrides erhalten) und `scripts/ui/tactical_event_log_panel.gd` (Petrolfarbe und passiver gemeinsamer Rahmen). Die bekannte 8%-Bodenabtönung bleibt in dieser Runde bestehen; der entfernte schwarze Aufbaukasten wird nicht zurückgebracht.

## Lokale Prüfung
Nach der Dokumentkorrektur betroffene Abschnitte lesen und auf widersprüchliche aktuelle Größen-/Raster-/Referenzangaben prüfen. Kein Engine- oder Gameplaytest ist für die reine Dokumentkorrektur erforderlich. Der anschließende Bildvergleich benötigt echte geöffnete Enginebilder; mögliche Implementierung und deren gezielte Funktions-/Renderprüfung getrennt dokumentieren.

## Risiken / offene Punkte
Größere Rahmen oder Portraits dürfen Kompaktheit und vorhandene Eingabeflächen nicht verdrängen. Referenztreue ist ein sichtbares Qualitätsurteil und keine Folge bestandener Strukturtests. Ein deutlicheres Raster darf keine versteckten Gegner offenlegen. Historische R4-Ergebnisse bleiben unverändert gültige Nachweise ihres damaligen Standes.

## Stand
Dokumentaudit und Korrektur zuerst abgeschlossen, danach alle vier Originalziele mit dem nativen Ausgangsstand verglichen. Begrenzte Rahmen-/Missions-/Hexrunde umgesetzt und nativ nachgeprüft: acht Gates / 857 Assertions, zwei normale Starts / 102 Checks, sechs separate Fixturebilder und zehn Offline-HTML-Checks grün. Echte 1920er und 1280er Bilder geöffnet; verbleibende Unterschiede sowie die tatsächlich aktive prozedurale Gebäudehülle in `docs/qa/ui_zielbild_20261102/NACHPRUEFUNG.md` festgehalten. Umfassende Modell-, Portrait- und Szenenrevision sowie gestalterisches Nutzerurteil bleiben offen. Kein Mainmerge oder Release.
