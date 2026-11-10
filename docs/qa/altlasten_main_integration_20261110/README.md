# Mainintegration der geprueften Altlastenbereinigung — 10.11.2026

Nutzerauftrag: geprueften Stand nach Main uebernehmen, erneut testen und pushen;
laufende Arbeiten erhalten. Vorheriger Main fbb7f52be, freigegebener Task
c21f89c23. Integrationsbranch task/altlasten-main-integration-20261110:
Taskdokument99c636d71 und sauberer Merge b8d3cdc77, dann Fast-forward des
separaten Main-Worktrees auf diesen Commit. Kein Produktkonflikt oder neuer
Produktcode. Gegenueber c21 kommt nur die Integrationstaskdatei hinzu.

## Frisch auf tatsaechlichem Main geprueft
- Godot4.6.2 Import Exit0, keine Script-/Compile-/Runtimefehler.
- Vollstaendige beauftragte26er-Matrix26/26,26 isolierte user://-Profile,
  keine Fehler/Leaks, realer Default-Roster unveraendert.
- Neuer echter Godot-Portraet-Testexport mit Produktionsfiltern750/0,
  Import/Export/Lauf jeweils Exit0, keine Fehler/Leaks/Warnungen.
- 42 alte Originale samt Sidecars und Texturpayloads fehlen,57 andere bleiben
  nutzbar; gespeicherte Aliasse/Embleme und264 erfasste Quellinputs erhalten.
- Unabhaengiger read-only Integrationsaudit ohne Blocker; Produkt-/Testbaeume
  gegen den geprueften Taskstand byteidentisch. Nachweis-Commits aendern nur Doku.

Maschinenbelege: verification.json und package_verification.json. Der gepruefte
Main-Codecommit ist b8d3cdc777d9c88f3d0b3b355ba5678b6067ca08. Die drei bereits
belegten Altgate-Abweichungen bleiben in ../altlasten_20261110/baseline_failures.json
kenntlich; sie wurden hier nicht als gruene Gesamtsuite ausgegeben. Kein neuer
Spiel-Releaseexport, keine native Gestaltungs- oder allgemeine FPS-Freigabe.

## Laufende Arbeiten erhalten
Original-Checkout C:/dev/SternenBuergerchen blieb auf
task/campaign-skirmish-rebuild-20261110 mit HEAD e765f507c. Kein Checkout,
Stash, Reset, Restore, Add oder Commit dort. Indexeintraege und staged Diff
blieben identisch;94 getrackte WIP-Dateien und252 ungetrackte Quelldateien
wurden erfasst. Keine erfasste Datei fehlt; alle252 ungetrackten Dateien sind
bytegleich. Waehrend der Integration wurden vier Dateien parallel ungestagt
weiterbearbeitet. Deren neueren Zustand haben wir bewusst nicht mit dem
Anfangssnapshot ueberschrieben. Details: wip_preservation.json.

Main-Arbeitsverzeichnis: C:/dev/SternenBuergerchen-worktrees/building-main-20261110.
Integrationsdoku entstand auf dem eigenen Taskbranch, Main wird nur per
Fast-forward aktualisiert. Vor dem normalen Push wird origin/main erneut
geprueft; kein Force-Push. Remote-HEAD-Nachweis erfolgt nach dem Push.

## Reproduktion
`python scripts/tests/run_review2_isolated.py --project . --manifest scripts/tests/altlasten_regression_manifest.json --baseline .godot/altlasten_main_integration_20261110/roster_baseline.json --output .godot/altlasten_main_integration_20261110/recheck --timeout 150`

`python scripts/tests/altlasten_portrait_export_probe.py --backend exporter --phase final --filters production --label main-recheck --run`

Der lokale Rosterpin und die Rohlogs bleiben unter .godot. Erfasst werden
SHA256/Laenge/mtime vor Tests; der bestehende Runner arbeitet fail-closed und
restauriert niemals automatisch echte Profildaten.
