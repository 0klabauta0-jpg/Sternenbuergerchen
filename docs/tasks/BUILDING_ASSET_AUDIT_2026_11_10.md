# Gebaeude- und Assetbestand vor dem Editor-Nachzug

## Ziel / Problem
Alte und aktuelle Gebaeude-/Umgebungsassets samt Verwendungen unterscheiden.
Der Nutzer vermutet ueberholte Modelle und Platzierungen im aktuellen Spiel.

## Ursache / Sinn
Mehrere Grafikgenerationen, feste GM01-Buehne und neue begehbare Basis/Orte
koennen unterschiedliche Modell-, Katalog- und Navigationspfade verwenden.
Alter oder fehlende direkte Stringreferenzen allein beweisen keine Obsoleszenz.

## Umfang und Nicht-Ziele
Statische Referenzpruefung von Modellen, Katalogen, Karten, Szenen, Runtime,
Editor und Offlinebuildern. Aktuell / ersetzt / historisch / stoerend / unklar
mit konkreten Fundstellen dokumentieren. Keine Loeschung, Assetaenderung,
Migration, Editorimplementierung, Commit, Push oder Export in diesem Auftrag.

## Relevante Dokumente
AGENTS.md; PROJECT_BRIEF.md; ARCHITECTURE.md; CODEX_RULES.md;
IMPLEMENTATION_STATUS.md; TASK_ROADMAP.md;
docs/dev/graphics_reference_revision_contract.md;
docs/dev/gm01_frontier_map_contract.md;
docs/dev/map_editor_asset_workflow_contract.md;
docs/dev/persistent_location_runtime_contract.md.

## Akzeptanzkriterien
- Aktive Basis, Handelsort, Satellitenort und GM01 bis zur Modelldatei verfolgen.
- Alte Modellgenerationen und Tilekatalog-/Editorpfade separat ausweisen.
- Fehlende Ressourcen und auseinanderlaufende Verwendungen konkret belegen.
- Maschinenlesbarer Bestands-/Verwendungsnachweis und lesbarer Bericht.
- Keine Produktdateien oder vorhandenen Assets veraendern.

## Betroffene Dateien
Diese Taskdatei und docs/qa/building_asset_audit_20261110/.
Ein kurzer Statusverweis in docs/IMPLEMENTATION_STATUS.md nach Abschluss.

## Lokale Pruefung
Reproduzierbarer statischer Scan, JSON-Parse, Pfadexistenz, manuelle Pruefung
der dynamischen Modellaufloesung und relevanter Loader; git diff --check.
Kein nativer Sicht-/Gameplaytest und keine daraus abgeleitete Grafikabnahme.

## Risiken / offene Punkte
Dynamische Pfade, externe/user://-Spielstaende und nur per UID referenzierte
Ressourcen benoetigen Sonderbehandlung. Keine automatische Loeschliste.
Basis: 274f142c2 auf task/playtest-plan-20261110, neuer eigener Auditbranch
task/building-asset-audit-20261110; enthaelt neuere Ortsarbeiten als lokales main.

## Status
Bestandspruefung abgeschlossen. Ergebnis und Prioritaeten:
docs/qa/building_asset_audit_20261110/README.md.
703 Modell-/Quelldateien, 352 Terrain-Mappings, 21 parsebare Karten;
fuenf echte Godot4.6.2-Roundtrips zeigen Datenverlust bei vier Ortskarten.
Aktive Altpaletten, Stationsgebaeude und alte Renderdefaults dokumentiert.
Nutzerpraezisierung: Auch alte Kenney-/blockige Test-/Renderpfade und deren
Ordner-/Katalogketten als Ablösekandidaten erfassen. Keine Loeschung in diesem
Bestandsauftrag; erst Verbraucher migrieren. Editor-Nachzug bleibt Folgearbeit.
