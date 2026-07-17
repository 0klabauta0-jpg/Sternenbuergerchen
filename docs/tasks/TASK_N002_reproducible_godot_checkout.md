# TASK_N002 — Reproduzierbarer Godot-Checkout

## Ziel / Problem

Ein frischer Checkout muss sich mit Godot 4.6.2 ohne UID-, Autoload-, Parse-
oder Exportkonfigurationsfehler importieren und minimal starten lassen.

## Ursache / Sinnhaftigkeit

Der isolierte TASK-1179-Rerun endete unter Bedingungen mit UID-/Autoload-
Problemen und einer bereits instanziierten Runtime vor den letzten Assertions.
Solange ein ausschließlich versionierter Checkout den Projekteinstieg nicht
reproduziert, ist die Produktevidenz nicht belastbar. Dieses Gate trennt
Einrichtungsfehler eindeutig von späteren Runtime-Defekten.

## Umfang

- `*.uid` aus `.gitignore` entfernen und nur benötigte UID-Sidecars mit
  versionierter Quelle einchecken.
- `/builds/` sowie `export_credentials.cfg` ignorieren und `.godot/` ignoriert
  lassen; `export_credentials.cfg` zusaetzlich im versionierten
  `all_resources`-Exportfilter ausschliessen.
- Einen bereinigten, versionierten Windows-Preset `export_presets.cfg` mit
  relativem Buildpfad und ohne Secrets oder persönliche Pfade bereitstellen.
- Mit `test_task_n002_checkout_config.ps1` den statischen Vertrag prüfen.
- Mit `verify_task_n002_fresh_checkout.ps1` einen externen Git-Clone ohne
  Hardlinks erzeugen, headless importieren, minimal starten und optional
  exportieren. UID-, Autoload-, Parse- und Scriptfehler sind harte Gates.
- TASK 1179 nach bestandenem Checkout-Gate zweimal bis zu seinem tatsächlichen
  Objective-/Debrief-Ergebnis ausführen und ehrlich als Evidenz festhalten.

## Nicht-Ziele

- Keinen separaten Runtime-Fehler durch Abschwächen des Verifiers verdecken.
- Keine Missionslogik, keinen sichtbaren Produktpfad und keine
  Command-Autorität umbauen.
- TASK 1180 weder integrieren noch als aktuelle Evidenz ausgeben.

## Relevante Dokumente und Contracts

- `docs/CURRENT_GAME_STATE.md` und `docs/qa/CURRENT_EVIDENCE.md`
- `project.godot`, `.gitignore` und der Export-/Ressourcenvertrag
- `docs/dev/export_runtime_package_contract.md`
- `docs/tasks/TASK_1179_ground_mission_objective_playthrough.md`
- `docs/dev/fireteam_runtime_execution_path_contract.md`

## Akzeptanzkriterien

- Der Konfigurationsvertrag ist auf der Ausgangsbasis rot dokumentiert und auf
  dem versionierten Stand grün.
- Alle elf Netfox-Autoloads booten ueber stabile `res://`-Pfade; ihre
  versionierten Sidecars behalten die dokumentierten UID-Werte. Kein Cache-,
  Library-, tmp- oder Probe-Sidecar wird versioniert.
- Ein lokales `export_credentials.cfg` ist sowohl per Git-Ignore als auch
  explizit im versionierten `all_resources`-Exportfilter von Release-Paketen
  ausgeschlossen.
- Der externe Fresh-Clone importiert und startet mit echten Exitcodes ohne
  UID-, Autoload-, Parse- oder Scriptfehler.
- Der Windows-Export wird mit verfügbaren Templates tatsächlich versucht;
  fehlende externe Templates werden mit Befehl, Exitcode und Log als Blocker
  dokumentiert.
- TASK 1179 wird zweimal zum tatsächlichen Ergebnis ausgeführt. Ein eigener
  Runtime-Defekt erhält Commit, Datum, Testart, Artefakt und Caveat, niemals
  einen erfundenen Erfolg.

## Betroffene Bereiche

`.gitignore`, `project.godot`-referenzierte UID-Sidecars,
`export_presets.cfg`, der Exportvertrag, der TASK-511-Hygiene-Verifier sowie
die fokussierten N002-Checkout-Verifier. Gameplay, Szenen und Command-Pfade
bleiben unverändert.

## Lokale Prüfung

1. `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/tests/test_task_n002_checkout_config.ps1`
2. `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/tests/verify_task_n002_fresh_checkout.ps1`
3. Zwei TASK-1179-Läufe nach erfolgreichem Fresh-Clone-Gate.
4. `godot_console.exe --headless --path . --script scripts/tests/task_511_export_runtime_package_hygiene.gd`
5. `git diff --check`

## Risiken / offene Punkte

Godot erzeugt beim Import zusätzliche UID-Sidecars. Nur Sidecars mit
versionierter Quelle dürfen nach einer bewussten Prüfung aufgenommen werden.
Der End-to-End-Trace bleibt wegen Meta-/3D-Aufbau teuer; ein sauberer Import
ersetzt keinen späteren Objective-/Debrief-Nachweis.

## Abhängigkeit / Exit-Gate

TASK_N003 darf erst beginnen, wenn der Fresh-Checkout-Befund und die beiden
TASK-1179-Ergebnisse auf einem committed Checkout mit vollständiger Evidenz
festgehalten sind.

## Befund und Evidenzstand (17. Juli 2026)

Die Ursache wurde mit zwei kontrollierten Fresh-Clone-Experimenten getrennt:
Die elf Netfox-Autoloads als `uid://`-Einträge erzeugten vor dem Aufbau der
UID-Registry 50 Parse-Fehler und elf unbekannte UIDs. Zusätzliche Netfox-
Sidecars allein beseitigten diesen Startzirkel nicht. Die produktive Lösung
bootstrapt deshalb genau diese Autoloads über stabile `res://`-Pfade und
versioniert ihre Sidecars weiterhin für stabile Ressourcenidentitäten.
Fünf Asset-Placer-Sidecars wurden ausschließlich aus konkreten textuellen
UID-Referenzen abgeleitet; eine pauschale Aufnahme aller erzeugten Sidecars
findet nicht statt.

Ein externer Clone von Commit `4393a6a9a6f036ef2ca152cf10a8702c3e713780`
importierte ohne UID-, Autoload-, Parse- oder Scriptfehler und startete den
minimalen Headless-Pfad mit Exitcode 0. Ein Windows-Release-Export erzeugte
EXE, PCK und beide Runtime-DLLs. Die vollständige Befundkette samt temporären
Logpfaden, Testbefehlen und Caveats steht in
`docs/qa/TASK_N002_FRESH_CHECKOUT_2026-07-17.md`.

Die zwei anschließenden TASK-1179-Läufe erreichten jeweils 18/18 Assertions
und Exitcode 0, meldeten danach aber beide eine bereits freigegebene Instanz.
Das ist ein separater Harness-/Runtime-Nachlaufdefekt und **kein** sauberer
Objective-/Debrief-Vollnachweis. Der aktuelle Produktstatus bleibt deshalb
bei „historisch vollständig, aktuell nicht sauber recaptured“, bis der Defekt
in einem folgenden, eng begrenzten Task behoben und frisch getestet ist.
