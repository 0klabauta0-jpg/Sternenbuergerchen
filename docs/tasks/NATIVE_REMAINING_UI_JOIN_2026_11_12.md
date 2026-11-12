# Native Remaining UI Join - 12.11.2026

## Ziel / Ursache
Im Main-Join fehlen bereits umgesetzte Punkte-Startproduzenten, drei Erfahrungs-Vorlagen, vier gezeichnete Portraets, Kartensteuerungshilfe und die lokale Forschungsplanungsworkbench. Vorhandene Verbraucher allein machen die Startwege nicht erreichbar.

## Umfang / Nicht-Ziele
Gezielter Sourceport aus 820a91caf/6308e6f02/ed8ebafc3/0d2864468 und Workbench84dd481b1. Keine Root-/Adapter-/Flow-/Supply-/Sternkatalogaenderungen, kein UI-Neuentwurf, keine Altmodellimporte oder grossen Tests.

## Vertraege / Dateien
PROJECT_BRIEF, ARCHITECTURE, CODEX_RULES, IMPLEMENTATION_STATUS; contextual_help_popup_ux_contract und html_report_workbench_contract. scripts/meta/game_start_contract.gd, skirmish_start_configuration.gd, character_sheet_formatter.gd, character_sheet_view.gd (nur Erfahrungsreadout); scripts/ui/main_menu_screen.gd, skirmish_points_dialog.gd, global_escape_menu.gd; zwei JSON-Kataloge, vier Portraetressourcen und ein freigegebenes Sheet; bestehende Source-Workbench samt Generator.

## Akzeptanz
1000/1500 erreichen den normalen Basisaufbau mit endlichem Budget; Punkte-Drafts werden validiert und einmalig konsumiert. Drei Erfahrungs-Vorlagen erfordern bewusstes Anwenden, Einzelwerte bleiben per Expertenschalter erreichbar. Readout erkennt exakte Vorlage oder individuelles Profil. Portraets45..48 sind ladbar und im Katalog. Escape bietet Kartensteuerung und Zurueck. Neue Kampagnen-/Basis-/Save-/Hilfefunktionen bleiben erhalten. Workbench bleibt lokales Planungsartefakt mit JSON-Export.

## Lokale Pruefung / Risiken
Kleine Punkte-Draft-Roundtrip-, Erfahrungs-, Katalog- und Hilfechecks plus Compile nach koordinierter Assetimportfreigabe. Keine native Gesamtbedienungs-/Performance-/Exportabnahme. Root koordiniert den einzigen inkrementellen Import. Keine Commits durch Teilagent.

## Ergebnis
Gezielte Sourceports umgesetzt. Die gemeinsame Charakteransicht erhielt nur Erfahrungsreadout und Profilwirkungsanzeige; Layout/Slots/Inventory blieben unveraendert. Beide JSON-Kataloge bewahren saemtliche vorhandenen Eintraege. Workbench und Generator sind byte-identisch zu84dd481b1. Gezeichnetes Sheet samt45..48-Ressourcen fuer den von Root koordinierten Import bereit.

Begrenzte Pruefung: RED0/1 (fehlende APIs), danach GREEN45/0 in output/native_remaining_ui_join/green.log; Punktebudget1000/1500, Snapshot/Einmalkonsum, Rejects, neun Erfahrungsrollen-/Stufenkombinationen mit Identitaets-/Ausruestungs-/Historienerhalt, individuelle Profile, Katalogkoexistenz und ResourceLoader.exists. Fuenf check-only Compiles exit0: Mainmenu, Escape, Punktedialog, Formatter, Charakteransicht. JSON-Erhalt, eindeutige IDs, UTF-8-Erhalt, Original-Workbenchhash und lokaler Exportaufbau separat gelesen/geprueft. git diff --check sauber.

Grenzen: ResourceLoader.exists ist kein frisches Texturladen vor Import. Kein nativer Klick-/Layout-/Sichtnachweis, keine volle Punkte-Ausflugskette, keine Gesamtperformance-/Save-/EXE-Abnahme. Keine Commits/Pushes durch diesen Teilagenten.

Root-Abschluss: frischer inkrementeller Import exit0 ohne Fehler/Leaks. Alle vier
Atlasressourcen laden danach wirkliche Texturen mit627px-Portraetbreite. Die
kleine UI-Probe prueft zusaetzlich die beiden tatsaechlichen Dialogbuttons: ihre
pressed-Signale liefern getrennt1000 und1500. Final46/0, exit0 ohne Fehler/Leaks;
unabhaengiges lesendes Review ohne wichtige Befunde. Probe und Logs liegen in
docs/qa/native_remaining_ui_join_20261112. Keine native Layout- oder volle
Punkte-Ausflugsabnahme daraus ableiten; neuerer Campaign-Continue beim Mainjoin
methodenweise erhalten.
