# TASK_N002 – Fresh-Checkout-Befund

Datum: 17. Juli 2026
Konfigurationscommit: `4393a6a9a6f036ef2ca152cf10a8702c3e713780`
Godot: 4.6.2 (headless)

## Checkout-Bootstrap

Der externe Clone importierte ohne UID-, Autoload-, Parse- oder Scriptfehler
und startete den minimalen Headless-Pfad mit Exitcode 0. Ein Windows-Export
erzeugte `Sternenbuergerchen_rel.exe` (104553472 Bytes),
`Sternenbuergerchen_rel.pck` (193800648 Bytes),
`liblimboai.windows.template_release.x86_64.dll` und
`libterrain.windows.release.x86_64.dll`.

Die kontrollierte Ursachenfolge lautet: Elf `uid://`-Autoloads erzeugten vor
dem Aufbau der UID-Registry elf unbekannte UIDs und 50 Netfox-Parse-Fehler.
Auch 51 zusätzliche Netfox-Sidecars änderten dieses Fehlerbild nicht. Nur die
Umstellung der elf Boot-Autoloads auf `res://` beseitigte den Startzirkel; die
Sidecars bleiben für Ressourcenstabilität versioniert. Fünf Asset-Placer-
Sidecars wurden ausschließlich aus konkreten textuellen UID-Warnungen
aufgenommen.

Der manuell beaufsichtigte Exportprozess war nach Artefakterzeugung beendet,
sein nachträglich abgefragter Exitcode war jedoch nicht mehr verfügbar. Der
Artefaktsatz belegt daher den Exportpfad, nicht einen nachträglich erfundenen
Exitcode.

## TASK-1179-Recapture

Run 1 und Run 2 erreichten jeweils `=== RESULTS: 18 passed, 0 failed ===` und
meldeten Exitcode 0. Beide meldeten danach:

```text
SCRIPT ERROR: Cannot call method 'call' on a previously freed instance.
at: _test_homebase_to_ground_objective_result
(res://scripts/tests/task_1179_ground_mission_objective_playthrough.gd:150)
```

Ein dritter, gezielt umgeleiteter Run vom 17. Juli 2026 ist im Arbeitsbericht
unter `C:\dev\SternenBuergerchen-worktrees\_sdd\task1179-run3.stdout.log` und
`C:\dev\SternenBuergerchen-worktrees\_sdd\task1179-run3.stderr.log` erhalten:
18/18 Assertions, zwei ungültige Homebase-UID-Warnungen und derselbe
Freed-Instance-Fehler. Der externe Prozesswrapper gab für diesen dritten Run
keinen nachträglich lesbaren Exitcode aus.

Die zwei Homebase-Sidecars sind jetzt versioniert. Sie werden erst nach einem
erneuten frischen Import als beseitigte Warnung behauptet; bis dahin sind sie
keine saubere Gameplay-Freigabe.

## Fazit

N002 belegt den Konfigurations- und Exportpfad. Der Gameplay-Pfad bleibt
„historisch vollständig, aktuell nicht sauber recaptured“, bis ein kleiner
Folgetask den Lifecycle-Zugriff auf die bereits freigegebene Instanz
testgetrieben korrigiert und TASK-1179 zweimal ohne Nachlauf-Fehler ausführt.
