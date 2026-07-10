# TASK_1073 - Release Build Provenance Guard

## Ziel / Problem

Der Release-Startcheck bestaetigt derzeit, dass ein Spieleordner vollstaendig
und juenger als das Altersbudget ist. Er schreibt aber den aktuellen Git-HEAD
in sein Manifest, ohne belegen zu koennen, dass der vorhandene PCK aus genau
diesem Commit stammt. Nach einem Codecommit kann ein aelterer Build dadurch
irrtuemlich als aktuell erscheinen.

## Ursache / Sinnhaftigkeit

Export und Startcheck teilen bisher nur den Zielpfad. Eine kleine
Provenance-Datei am Release-Paket verbindet beide Schritte, ohne in Runtime,
Mission oder UI einzugreifen. Damit wird ein frischer Export vor einem
sichtbaren Playtest eindeutig nachweisbar.

## Umfang

- Der erfolgreiche Runtime-Export schreibt neben EXE/PCK ein
  `release_build_provenance.json` mit Branch, vollem Git-Commit, Zeit und
  SHA-256 des PCK.
- Der read-only Startcheck verlangt diese Datei, vergleicht ihren Commit mit
  dem aktuellen Repository-HEAD und prueft den PCK-Hash.
- Der bestehende Exportvertrag dokumentiert den aktuellen `scripts/tests/`-
  Legacy-Bridge-Pfad explizit als Runtime-Abhaengigkeit, statt ihn
  widerspruechlich aus dem Paket ausschliessen zu wollen.
- Fehlende, unlesbare oder nicht passende Provenance ist ein hartes Fail-Gate.
- Das Startcheck-Manifest exportiert Provenance-Pfad, erwarteten/gefundenen
  Commit und Hash-Gate fuer Reports.

## Nicht-Ziele

- Kein automatischer Export oder Prozessstart im Startcheck.
- Kein Codesigning, keine Taskleisten-Aenderung und kein Gameplay-Umbau.
- Kein Release-Upload oder Deployment-Service.

## Relevante Contracts / Dokumente

- `data/export_runtime_package_contract.json`
- `docs/dev/export_runtime_package_contract.md`
- `scripts/tools/export_runtime_release.ps1`
- `scripts/tools/release_runtime_start_check.ps1`
- TASK_511 und TASK_818

## Akzeptanzkriterien

- Ein erfolgreicher Export schreibt die Provenance mit Commit und PCK-Hash.
- Ein Startcheck ohne passende Provenance faellt hart durch.
- Ein passender frischer Export besteht den Startcheck.
- Der Startcheck bleibt read-only und startet, beendet oder verschiebt nichts.

## Betroffene Dateien

- `data/export_runtime_package_contract.json`
- `scripts/tools/export_runtime_release.ps1`
- `scripts/tools/release_runtime_start_check.ps1`
- `scripts/tests/task_1073_release_build_provenance_guard.gd`
- Status, Roadmap und aktueller HTML-Bericht

## Lokale Pruefung

- TASK_1073 13/13 und TASK_511 27/27.
- Echter `export_runtime_release.ps1`-Lauf und anschliessender
  `release_runtime_start_check.ps1`-Lauf.
- `git diff --check`.

## Risiken / offene Punkte

Die PCK-Hash-Pruefung liest das Paket bewusst vollstaendig und ist daher ein
manueller Release-Check, kein Runtime-Hotpath. Ein neuer Commit nach Export
erzwingt absichtlich einen erneuten Export vor dem naechsten Release-Playtest.
