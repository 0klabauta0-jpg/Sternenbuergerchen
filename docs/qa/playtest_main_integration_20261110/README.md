# Mainintegration Playtestplan –10.11.2026

Auftrag: Mainmerge und regulaerer GitHub-Push. Mainbasis046b6d91a,
Produktstand401c4a049. Keine Codekonflikte und keine neuen Gameplayaenderungen.
Die Integration erfolgt in der sauberen separaten Git-Kopie; fremder WIP im
Originalcheckout bleibt unberuehrt. Native Funktions-/Grafiknachweise siehe
../playtest_20261110_acceptance/README.md; das ist keine neue Exportabnahme.

## Frische Main-Pruefung

Gepruefter Maincommit c10db590f8b65cc22c990edc8a3b66136e158b88; Produktquellen
sind bytegleich401c4a049. Danach nur dieser Abschlussbeleg, keine Codeaenderung.

- Gezielte Quellsuite17/17, alle Prozesse Exit0.
- Basisruhe19/0: echte Bettwege, beide Schalter, manuelle Ausruestung/Bewegung,
  Save/Continue und physisches Boarding schlafender Besatzung.
- Vollstaendiger Kampagnenlauf152/0 mit zwei echten Ausfluegen, sichtbarem
  Wiedereinsteigen, zwei Heimkehrten und zweimal echtem Continue, Exit0.
- Kein FAIL, SCRIPT ERROR oder ERROR in diesen Integrationslogs.
- Git diff --check sauber; kein fremder WIP aufgenommen.

Rohbelege lokal output/playtest_main_integration_20261110/; jede Probe mit eigenem
APPDATA. Native175/0 und62/0 aus der vorherigen Taskabnahme wurden hier nicht
wiederholt und bleiben als solche ausgewiesen. Kein neuer Export.

Uebernahme per Fast-forward auf Main und normaler Push nach GitHub, kein Force.
Der finale Remote-Main-SHA wird nach dem Push direkt mit HEAD abgeglichen.
Der nicht ausgecheckte Mainref des Originalrepos wird ebenfalls aktualisiert;
dessen aktiver fremder Taskbranch und seine Arbeitsdateien bleiben erhalten.
