# UI Theme and Component Library

Status: TASK_164 implementiert

## Fortschreibung Native UI R1 · 01.11.2026

Die bestätigten UI-Entwürfe werden jetzt in allen bestehenden Screenfamilien nativ verwendet. Verbindliche Gestaltungsrollen und Grenzen: [ui_native_design_contract.md](ui_native_design_contract.md). Bilder, technische Nachweise und weitere Prüfpunkte: [Native-R1-QA](../qa/ui_native_r1_20261101/README.md).

- `TacticalUITheme.get_theme()` liefert eine gecachte Theme-Ressource; `apply_screen(Control)` setzt sie an der Wurzel. Dynamische Kinder und Popups erben die Basis.
- Bestehende `style_*`-APIs bleiben erhalten. `style_action_tile(Button, selected, primary)` ergänzt die kompakten Missionsaktionen. MetaUISkin delegiert an dieselben Token und StyleBox-Fabriken.
- Fenster, Inputs, Dropdowns, Listen, Tabs, Scrollbars, Tooltips, Fokus und Auswahl teilen dieselben Rollenfarben. Keine globale Traversierung bei Runtime-Refreshes.
- Der neue A5-Helfer ordnet vorhandene Controls an und aktualisiert Darstellung. Geometrie-/Style-Signaturen vermeiden unveränderte Schreibvorgänge; keine neue Gameplay-Wahrheit.
- Der unten beschriebene TASK164-Selected-Fireteam-Slice ist historisch und inzwischen stillgelegt. Aktuelle Integration wird durch die nativen Theme-/A5-/Shell-Verifier und gezielte bestehende Bedienprüfungen belegt; der alte TASK164-Verifier erwartet noch den stillgelegten Besitzer.

## Gestaltungsfortschreibung 02.11.2026
Die bestätigten Original-2D-Ziele und aktuellen Nutzeranweisungen haben nach `ui_native_design_contract.md` Vorrang vor den bisherigen nativen Zwischenmaßen. Schlichte Rahmen oder die Beschränkung des damaligen TASK164 auf vorhandene Kenney-Assets sind keine dauerhafte Stilsperre. Referenzgetreue dekorative Rasterelemente, Nine-Patch-Rahmen und mehrschichtige Flächen dürfen echte native Controls ergänzen; gemeinsame Theme-Rollen, lesbare Texte, Eingabe/Fokus und bestehender Zustandsbesitz bleiben erhalten. Keine globale Runtime-Traversierung oder neue Gameplay-Wahrheit.

## Zweck
Diese kleine UI-Basis ist eine gemeinsame Darstellungs-Schicht fuer Homebase, FOB und Mission. Sie ersetzt keine Screen-Logik und haelt keinen Gameplay-State. Komponenten bekommen fertige Daten/Snapshots von bestehenden Runtime- oder Meta-Pfaden und zeigen sie nur an.

## Dateien
- `scripts/ui/tactical_ui_theme.gd`
  - zentrale Farben, Statusfarben, Card-/Badge-/Button-/Progress-Styles und kompakte Icon-Groessen.
- `scripts/ui/components/status_badge.gd`
  - kompakte Statusanzeige fuer Ready, Contact, Warning, Danger usw.
- `scripts/ui/components/tactical_card.gd`
  - kleiner PanelContainer-Basisstil fuer taktische UI-Karten.
- `scripts/ui/components/unit_roster_row.gd`
  - read-only Zeile fuer Unit-Snapshots mit Name, Rolle und Status.
- `scripts/ui/components/command_button.gd`
  - Button mit Command-ID als UI-Metadatum; keine Command-Ausfuehrung.
- `scripts/ui/components/progress_line.gd`
  - kompakte Label-plus-Progressbar-Zeile.
- `scripts/ui/components/ui_tooltip_icon_helper.gd`
  - Tooltip-/Icon-Helfer mit kleinem kuratiertem Asset-Manifest.

## Historischer erster Anwendungs-Slice (TASK164)
Der damalige Missions-Slice `FireteamStatusPanel` in `MissionTacticalSandboxController` nutzte:
- `TacticalCard` als Panelbasis
- `StatusBadge` fuer den ausgewaehlten Fireteam-Zustand
- `ProgressLine` fuer Suppression-Fortschritt
- `CommandButton` fuer `Return to Plan`

Die bestehende lesbare `SuppressionLabel`-Zusammenfassung bleibt erhalten. Die neue UI liest nur bestehende Werte wie Suppression, Ad-hoc-Order und Plan-Rueckkehrbarkeit.

## Historische kuratierte Kenney-Assets (TASK164)
In diesem Slice wurden keine neuen Asset-Dateien importiert. Sein Manifest verwies nur auf vorhandene Repo-Dateien:
- `res://Assets/kenney_ui-pack/PNG/Grey/Default/icon_checkmark.png`
- `res://Assets/kenney_ui-pack/PNG/Grey/Default/icon_cross.png`
- `res://Assets/kenney_ui-pack/PNG/Grey/Default/icon_circle.png`
- `res://Assets/kenney_ui-pack/PNG/Grey/Default/star.png`
- `res://Assets/kenney_ui-pack/PNG/Grey/Double/arrow_basic_e_small.png`
- `res://Assets/kenney_ui-pack-space-expansion/PNG/Grey/Default/bar_square_large.png`
- `res://Assets/kenney_ui-pack-space-expansion/PNG/Grey/Default/button_square_header_small_rectangle_screws.png`
- `res://Assets/kenney_cursor-pixel-pack/Tiles/tile_0000.png`

## Grenzen
- Keine neue Gameplay-Funktion.
- Keine zweite UI-Wahrheit neben `SimulationRoot`.
- Historischer TASK164-Scope: kein kompletter Redesign-Pass und keine Masseneinbindung lokaler Assets. Das beschränkt keine später ausdrücklich beauftragte UI-/Grafikrevision. Neue Assets benötigen weiterhin zugeordnete Referenz, Herkunft und Import-/Sichtprüfung.

## Verifier
- `scripts/tests/task_164_ui_theme_component_verifier.gd`
  - prueft Theme-Tokens, kuratierte Asset-Pfade, alle Komponenten und den Mission-Selected-Fireteam-Slice.
