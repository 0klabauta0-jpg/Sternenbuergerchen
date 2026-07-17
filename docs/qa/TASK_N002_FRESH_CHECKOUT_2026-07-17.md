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

## Nachtrag: versionierter Release-Export

Am 17. Juli 2026 wurde der offizielle Release-Workflow auf Commit
`97989559132d55ae5e0d2c24e77fd901b9e02a6b` erneut ausgeführt:

```text
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/tools/export_runtime_release.ps1
```

Der Workflow prüfte den versionierten Preset gegen den JSON-Vertrag, legte den
ignorierten Zielordner `builds/` an und endete mit nativem Exitcode 0. Seine
lokale, ignorierte Provenance-Datei `builds/release_build_provenance.json`
nennt dieselbe Commit-ID sowie:

- `Sternenbuergerchen_rel.exe`: 104553472 Bytes
- `Sternenbuergerchen_rel.pck`: 193802168 Bytes
- PCK-SHA-256:
  `a5ff35d1a4ad998005fb9d830c0a63c129be179edde7d328aa46c3b5bb20bf0f`
- `liblimboai.windows.template_release.x86_64.dll` und
  `libterrain.windows.release.x86_64.dll`

Der dazugehörige Contract enthält `export_credentials.cfg` explizit im
`all_resources`-Exclude-Filter; der Test prüft den Eintrag in JSON und Preset
sowie deren vollständige Reihenfolge. Für diesen Nachtrag wurde kein echter
Credential-Wert angelegt oder versioniert.

**Caveat:** Nach den zwei kleinen, versionierten Export-Fixes wurde kein zweiter
externer Fresh-Clone-Lauf ausgeführt. Der erfolgreiche lokale Export belegt
den aktuellen Workflow und seinen nativen Exitcode, ersetzt aber nicht das
separate Fresh-Clone-Gate oder die offene TASK-1179-Recapture.

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
