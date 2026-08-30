# TASK_1182 - Clean Checkout Netfox Autoload Stability

## Ziel

Ein frischer Checkout muss die Netfox-Autoloads ohne lokale `.uid`-Seiten-Dateien
aufloesen und starten koennen.

## Ursache

`project.godot` referenziert die elf Netfox-Autoloads ueber Godot-UIDs, waehrend
`.gitignore` alle `*.uid` Dateien ausschliesst. Damit besitzt ein sauberer
Checkout keine belastbare UID-Aufloesung fuer diese Projektkonfiguration.

## Umfang

- Die elf Netfox-Autoloads verwenden explizite, getrackte `res://`-Skriptpfade.
- Ein Contract-Verifier prueft die Konfiguration und die ladbaren Skripte.
- Der TASK_1146-Prozessgate erfasst den echten Exit-Code jedes Verifiers.

## Nicht-Ziele

- Keine Aenderung an Netfox-Logik oder Multiplayer-Verhalten.
- Keine Aufnahme generierter `.uid`-Dateien in Git.
- Keine Lockerung von `.gitignore` fuer Godot-Importartefakte.

## Akzeptanzkriterien

- Frischer Checkout, Godot-Import und Headless-Smoke ergeben keine UID- oder
  Autoload-Aufloesungsfehler.
- TASK_1182 prueft alle elf Autoloads und beendet den Prozess bei Fehlern mit 1.
- TASK_1146 propagiert einen nicht-null Exit-Code auch dann, wenn kein
  auswertbares `FAIL` im Text steht.
