# TASK_1146 - Headless Runtime Resource Leak Ownership and Exit Hygiene

## Ziel / Problem
Funktional gruene Headless-Verifier melden beim Prozessende `ObjectDB instances leaked`, Canvas-/Texture-/Font-RID-Leaks oder verbleibende `SceneTreeTimer`. Damit kann das bestehende Warning-Gate nicht verbindlich als Release-Signal genutzt werden.

## Ursache / Sinn
- Eine leere boardbare Dropship-Karte erzeugt in `fob_screen.gd` ein `Label`, haengt es bei leerem Payload aber nicht ein und gibt es nicht frei. Der einzelne Orphan haelt Theme-, Font-, Image- und Texture-Ressourcen fest.
- Das UI-Performance-Harness beendet die Main-Menu-Szene, bevor deren kurze Metric-Save-/Context-Help-Delay-Timer abgelaufen sind. Zwei `SceneTreeTimer` bleiben beim Exit referenziert.
- Bestehende GDScript-Verifier pruefen nur fachliche Ergebnisse; der Leaktext erscheint erst beim Engine-Cleanup nach `quit()`.

## Umfang
- Das ungenutzte Dropship-Label gar nicht erst erzeugen.
- Im UI-Performance-Harness kurze UI-Delay-Timer vor dem finalen Snapshot-/Prozessende kontrolliert auslaufen lassen.
- TASK_096-Debuginstrumentierung entfernen und Cleanup-Frames beibehalten.
- Ein Prozessgate bereitstellen, das TASK_096 und TASK_222 mit `--verbose` startet und echte Leakzeilen blockiert.

## Nicht-Ziele
- Keine Aenderung an Gameplay-, Dropship-, UI-Delay- oder Multiplayer-Verhalten.
- Keine Warnungen global unterdruecken.
- Keine pauschale Freigabe von Ressourcen-Caches waehrend des laufenden Spiels.

## Akzeptanzkriterien
- TASK_096 bleibt 19/19 und erzeugt keine `Leaked instance`, RID- oder ObjectDB-Leakzeile.
- TASK_222 bleibt 82/82 und erzeugt keine verbleibenden `SceneTreeTimer` oder ObjectDB-Leakzeile.
- Das neue Gate ignoriert dokumentierende PASS-Zeilen, blockiert aber echte Engine-Leakmeldungen nach dem Testabschluss.
- Player-Flow- und Multiplayer-Gates bleiben gruen.

## Betroffene Dateien
- `scripts/meta/fob_screen.gd`
- `scripts/tests/ui_hud_comic_bubble_performance_harness.gd`
- `scripts/tests/task_096_recovery_verifier.gd`
- `scripts/tests/run_task_1146_headless_resource_leak_gate.ps1`
- `scripts/tests/task_1146_headless_runtime_resource_leak_ownership_exit_hygiene.gd`
- Status, Roadmap und HTML-Arbeitsbericht

## Lokale Pruefung
- TASK_1146 Contract-Verifier
- TASK_096 `--verbose`
- TASK_222 `--verbose`
- TASK_1146 Leak-Gate
- TASK_1145 Player-Flow-Gate
- `git diff --check`

## Risiken / offene Punkte
Der Leak-Gate-Scope beginnt bewusst bei den beiden reproduzierbaren Besitzern. Weitere Verifier werden erst aufgenommen, wenn sie einzeln verbose sauber sind; bekannte erwartete Gameplay-Warnungen bleiben erlaubt.
