# First Engagement Release Recapture Design

## Ziel
Der erste Feuerentscheid soll sich als lesbarer, aktueller Release-Schritt an den bestehenden Flow Preview -> GO -> Bewegung -> Kontakt anschliessen.

## Architektur
`MissionTacticalSandboxController` stellt einen weiteren read-only Snapshot bereit. Er kombiniert den bereits akzeptierten TASK_1172-Kontakt-Handoff mit dem vorhandenen TASK_543-Engagement-Snapshot und den existierenden Release-/Host-/Client-Evidenzen. Der Snapshot bewertet nur vorhandene Daten und veraendert weder `SimulationRoot` noch Runtime-Komponenten.

## Datenfluss
`TASK_1172 Handoff` + `TASK_543 Engagement` + `Release Provenance` + `Host/Client Capture` -> `TASK_1173 Snapshot` -> Verifier/HUD-Contract.

## Lesbare Entscheidung
- `fired`: Angreifer, Ziel, Waffe, FireEvent und taktischer Kontext sind sichtbar.
- `waiting` oder `blocked`: Die Entscheidung nennt eine konkrete Warte- oder Blockursache.
- In beiden Faellen bleiben Deckung, Distanz oder LOS als Begruendung erreichbar.

## Grenzen
Der Task baut keine Combat-Mechanik, keine UI-Paralleldaten und keine neue Multiplayer-Autoritaet. Der Snapshot setzt explizit `read_only = true`, `ui_sets_gameplay_truth = false` und alle `creates_*`-Flags auf `false`.

## Teststrategie
Der neue Verifier prueft die Contract-Struktur mit kleinen, stabilen Handoff-Fixtures und misst vor/nach dem Snapshot Command- und Effect-Queues. Die echte Mission-Ausfuehrung bleibt separat durch TASK_543 abgesichert; TASK_1172 sichert die vorherige Kontaktstufe ab.
