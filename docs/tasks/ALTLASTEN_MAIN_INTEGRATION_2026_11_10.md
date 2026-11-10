# Gepruefte Altlastenbereinigung nach Main uebernehmen

## Ziel / Anlass
Expliziter Nutzerauftrag: geprueften Stand c21f89c23 aus
task/altlasten-fuenf-schritte-20261110 sauber in Main integrieren, auf dem
zusammengefuehrten Main erneut testen und pushen. Laufende Arbeiten bleiben.

## Umfang / Nicht-Ziele
- Basis: sauberer lokaler Main und origin/main fbb7f52be.
- Sechs bereits gepruefte Commits unveraendert integrieren.
- Eigener Integrationsbranch und vorhandener separater Main-Worktree.
- Keine Produktneuentwicklung, keine Release-EXE und keine Main-Uebernahme
  des parallel laufenden Kampagnen-/Skirmish-Umbaus.
- Original-Checkout C:/dev/SternenBuergerchen: weder Checkout, Stash, Reset,
  Restore, Add noch Commit; staged/unstaged und untracked Inhalte bewahren.

## Dokumente
- docs/tasks/ALTLASTEN_FUENF_SCHRITTE_2026_11_10.md
- docs/qa/altlasten_20261110/README.md und REVIEW.md
- docs/qa/altlasten_20261110/baseline_failures.json
- docs/dev/export_runtime_package_contract.md
- docs/dev/runtime_script_layout_contract.md

## Akzeptanz
1. Integrationsproduktbaum entspricht dem geprueften Taskstand; etwaige
   Unterschiede zu Main sind ausschliesslich der beauftragte Umfang.
2. Neuer Import und26 isolierte Gates auf dem tatsaechlichen Main bestehen.
3. Frischer Portraet-PCK-Check mit echten Produktionsfiltern besteht.
4. Original-WIP: Branch/HEAD, Indexeintraege, staged/unstaged Diffs und erfasste
   untracked Quelldateien bleiben identisch; externe Aenderungen gesondert melden.
5. Main wird ohne Force gepusht, Remote-HEAD ist nachweislich gleich lokal.
6. Die drei bekannten baselinegleichen Altgates bleiben als solche kenntlich.

## Betroffene Dateien
Bereits gepruefter Mergeumfang; zusaetzlich diese Taskdatei,
docs/qa/altlasten_main_integration_20261110/* und IMPLEMENTATION_STATUS.md.

## Lokale Pruefung / Risiken
Godot4.6.2, bestehender Review2-Isolationsrunner und26er-Manifest; realer
Default-Roster vor den Laeufen gepinnt. Kein Test gegen produktives user://.
Frische Paketprobe isoliert von losen Quellressourcen. Refs vor Push erneut
lesen; konkurrierenden Mainfortschritt integrieren statt ueberschreiben.
Eigene Testmetadaten im Integrationsworktree von fremdem WIP trennen.

## Ergebnis
Maincode b8d3cdc77: Import0Fehler,26/26 Gates, Paketprobe750/0.
Produktidentitaet zum freigegebenen Task und WIP-Erhalt nachgewiesen.
Nachweis: docs/qa/altlasten_main_integration_20261110/README.md.
