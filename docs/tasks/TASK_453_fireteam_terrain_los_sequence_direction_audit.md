# TASK_453 - Fireteam Terrain LOS Sequence Direction Audit

## Ziel / Problem
Nach den letzten Fireteam-Baseline-Slices ist unklar, ob wir tiefer an einzelnen Formationsdetails arbeiten sollen oder zuerst die groessere Struktur klaeren muessen: Terrain-/LOS-Wahrheit, Sequenzlogik fuer raupenartiges bzw. ueberschlagendes Vorgehen und die Rolle von Terrain3D.

## Sinnhaftigkeit / Ursache
Die aktuelle Formation-Workbench beschreibt statische Positionen und Sicherungsbilder. Raupenartiges Vorgehen, Bounding, Regroup, Kontaktpausen und Area-Clearing sind aber zeitabhaengige Sequenzen. Gleichzeitig stoeren Playtest-Symptome wie falsche Bodenplatten, Vegetation auf/unter Tiles, Hoehenwirkung und schwer lesbare Sichtlinien die Bewertung der Fireteam-Behaviors.

Ohne saubere Trennung wuerden weitere Detailkorrekturen riskieren, neue Fallbacks oder zweite Wahrheiten einzubauen.

## Umfang
- Neue interaktive HTML-Workbench unter `docs/reports/`.
- Uebersicht ueber Gameplay-Wahrheit fuer Terrain, LOS, Cover, Visuals und Terrain3D.
- Trennung von Formation-Workbench und zukuenftiger Doctrine-/Sequence-Workbench.
- Entscheidungsfelder fuer naechsten Slice: Terrain-Audit, Sequenz-Workbench oder direkter Runtime-Fix.
- Offene Fragen und Akzeptanzkriterien fuer spaetere Workbench-/Runtime-Slices.
- Kurze Contract-Ergaenzung, dass Terrain3D vorerst nicht Gameplay-Autoritaet wird.

## Nicht-Ziele
- Keine Runtime-Codeaenderung.
- Keine Umstellung auf Terrain3D als Pathing-/LOS-/Cover-Wahrheit.
- Keine neue Sequence-Runtime.
- Keine Aenderung an Mission-Testmap, Visual-Mapping oder Fireteam-Bewegung.
- Kein Playtest-Fix in diesem Slice.

## Relevante Contracts / Dokumente
- `docs/dev/html_report_workbench_contract.md`
- `docs/dev/fireteam_behavior_modes_contract.md`
- `docs/dev/fireteam_runtime_execution_path_contract.md`
- `docs/tasks/TASK_433_install_third_party_godot_plugins.md`
- `docs/tasks/TASK_439_fireteam_runtime_map_flow_limbo_review.md`
- `docs/tasks/TASK_445_html_report_workbench_standard.md`
- `docs/tasks/TASK_451_fireteam_workbench_runtime_import.md`
- `docs/tasks/TASK_452_fireteam_runtime_baseline_visual_contact_pass.md`

## Akzeptanzkriterien
- Die HTML benennt klar, welche Schicht autoritativ ist: `TerrainRegistry`, Tile-Daten, LOS-System, Pathfinder, Combat Resolver und Visualpfad.
- Die HTML beschreibt Terrain3D als moegliche Visual-/Authoring-Hilfe, aber nicht als aktuelle Gameplay-Wahrheit.
- Die HTML trennt statische Formation von zeitabhaengiger Sequenz.
- Die HTML enthaelt eine kleine Zielstruktur fuer eine spaetere Doctrine-/Sequence-Workbench.
- Die HTML bietet lokale Controls, Notizen und `JSON exportieren`.
- Der empfohlene naechste Schritt ist als kleiner, pruefbarer Slice formuliert.

## Betroffene Dateien
- `docs/tasks/TASK_453_fireteam_terrain_los_sequence_direction_audit.md`
- `docs/reports/fireteam_terrain_los_sequence_audit.html`
- `docs/dev/fireteam_behavior_modes_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- HTML lokal per `file://` oeffnen und Export-Button bedienen.
- `git diff --check`

## Risiken / offene Punkte
- Die Seite ist eine Arbeits-/Entscheidungshilfe und keine Runtime-Wahrheit.
- Terrain3D kann spaeter hilfreich sein, darf aber nicht still eine zweite LOS-/Cover-/Pathing-Autoritaet werden.
- Sequenzbegriffe wie raupenartig, Bounding und ueberschlagend brauchen vor Runtime-Code eine kleine Datenform mit Phasen, Rollen, Triggern und Abbruchbedingungen.

## User-Entscheidungen 2026-05-17
- Nicht weiter manuell testen, bevor der naechste strukturelle Slice klar ist.
- Area-Clearing kommt nicht in die erste Sequence-Workbench; es bleibt ein spaeterer Folge-Slice.
- Terrain3D soll spaeter als reiner Visual-Prototyp gegen eine Kopie der Drillmap getestet werden, ohne Runtime-Wahrheit umzuschalten.
- Dev-UI soll dauerhaft die relevanten Terrain-/LOS-Werte sichtbar machen: Tile-ID/Typ, Surface, `height_level`, `object_height`, `walkable`, `blocks_los`, `cover_value`, Sicht-/Waffenreichweite, LOS-Status, Blocker-Koordinate und Blocker-Art.
- Sequence-Workbench exportiert zunaechst Doku-/Entscheidungs-JSON. Runtime-Import entsteht erst, wenn die Doku-Werte im Playtest akzeptiert sind; einzelne Werte duerfen dann bewusst uebernommen werden.
- Mauern brauchen eine genauere LOS-Regel als "ganzes Tile blockt". Zielbild: Wand-/Zaunobjekte werden als Kanten- oder Segment-Blocker behandelt. Entlang einer Wand darf Sicht moeglich bleiben; blockiert wird, wenn die Sichtlinie das Wandsegment kreuzt. Diagonale Sicht von Nordwest nach Suedost soll eine versetzte Wand nur dann blocken, wenn die Linie deren Blocker-Segment tatsaechlich schneidet.
