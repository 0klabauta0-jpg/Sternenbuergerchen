# Tactical Performance Release Recovery – Luna Orchestrator Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Work through the remaining tactical-map performance and release blockers in ten serial, evidence-gated packages, using `gpt-5.6-luna` with the lowest task-appropriate reasoning effort and without weakening gameplay, architecture, budgets or manual release evidence.

**Architecture:** The conductor owns Git, task order, evidence and integration. Luna workers receive one small, self-contained package at a time; they may modify only the named worktree and file corridor. Every runtime change is preceded by a red verifier, followed by deterministic gameplay/authority regression tests and SHA-bound before/after measurements. Performance caches and indexes remain derived, tick-local or render-local read models; `SimulationRoot` remains the only gameplay mutation authority.

**Tech Stack:** Godot 4.6.2, GDScript, PowerShell 7, Git worktrees, existing TASK-1187 measurement contract and TASK-1193 release-acceptance gate.

**Spec:** `docs/reports/STERNENBUERGERCHEN_TACTICAL_PERFORMANCE_STATUS_UND_WEITERARBEIT_2026-08-31.html`, `docs/tasks/TASK_1195_tactical_performance_status_report.md`, `docs/superpowers/plans/2026-08-31-combat-observed-candidate-index.md`

## Global Constraints

- Work from `integration/core-foundation`; never implement in the dirty/stale `main` checkout.
- Repository root: `C:\dev\SternenBuergerchen`.
- Integration worktree: `C:\dev\SternenBuergerchen-worktrees\integration-core-foundation-execution`.
- Plan/report worktree: `C:\dev\SternenBuergerchen-worktrees\task-1195-tactical-performance-report`.
- Godot executable: `C:\Users\bjoer\AppData\Local\Programs\Godot\Godot_v4.6.2-stable_win64_console.exe`.
- Keep `SimulationRoot` as the only gameplay mutation authority. UI, render code, caches, indexes and debug snapshots are not gameplay truth.
- Do not change `data/performance_budget_contract.json` thresholds to make a result pass.
- Do not synthesize or pre-fill human playtest evidence. `synthetic_fixture: false` must be asserted by the human reviewer.
- `128x128` is the largest automated release-candidate map. Do not approve `256x256` from headless evidence.
- Preserve deterministic ordering, contacts, detection timing, fire decisions, damage, vital states, mission result, command authority and multiplayer snapshot contracts.
- Do not use `git reset --hard`, `git clean`, stash, `git add .`, force-push or broad file rewrites.
- Use exact `git add` file lists. Preserve unrelated and generated user state.
- A package may create only its named task branch and worktree. Do not run two writing workers in the same worktree.
- Do not merge to `main`, create a tag, publish a release or deploy without a separate explicit user instruction at Package 09.
- A green headless gate is not a human playtest. A human playtest is not a substitute for a red automatic gate.
- Every measurement claim must name Git SHA, machine, Godot version, cold/warm count, range and budget status.
- If a runtime package cannot identify one measured, behavior-preserving change, finish it as an evidence-only package and do not guess.

---

# START DER KOPIERFERTIGEN DIRIGENTEN-ANWEISUNG

Du bist der Dirigent für die taktische Performance- und Release-Wiederherstellung von `SternenBuergerchen`. Arbeite die Pakete 01 bis 10 strikt seriell ab. Führe nach jedem Paket das Gate aus, integriere nur ein grünes Paket und beginne erst dann das nächste. Frage den Nutzer nicht nach Routinefreigaben. Halte nur an, wenn echte menschliche 128x128-Evidenz benötigt wird oder ein Merge nach `main`, ein Tag beziehungsweise eine Veröffentlichung ansteht.

## 1. Modellrouting und Agentenregeln

### Standardrouting

- Verwende für ausführende, prüfende und dokumentierende Unteraufgaben `gpt-5.6-luna`.
- Verwende `reasoning_effort: low` als Standard.
- Verwende beim Überschreiben des Modells immer `fork_turns: "none"`; die Arbeitskapsel unten enthält den vollständigen Kontext.
- Erhöhe auf `medium` nur, wenn derselbe klar abgegrenzte Schritt zweimal unter `low` mit demselben technischen Blocker scheitert oder wenn ein Vertragskonflikt zwischen zwei bestehenden Schnittstellen bewiesen ist.
- Erhöhe auf `high` nur für eine nachgewiesene Architektur-/Autoritätskollision, die mit `medium` nicht auflösbar war.
- Verwende niemals `xhigh`, `max` oder `ultra` für diesen Plan.
- Nach erfolgreicher Eskalationsanalyse geht die konkrete Änderung wieder an einen frischen Luna-Worker mit `low` und enger Arbeitskapsel.

### Parallelität

- Maximal ein schreibender Executor gleichzeitig.
- Nach dessen Abschluss dürfen ein read-only Contract Reviewer und ein read-only Verifier parallel prüfen.
- Der Dirigent bleibt der einzige Besitzer von Branch-Erstellung, Commits, Merges und Pushes.
- Kein Worker darf einen anderen Worktree ändern, einen Branch wechseln, pushen, mergen oder Worktrees entfernen.
- Verwende Subagenten nur für konkrete Paketaufgaben. Der Dirigent selbst hält Ledger, Gate und Git-Zustand.

### Pflicht-Skills je Paket

1. Vor einer Codeänderung: `superpowers:test-driven-development`.
2. Bei einem Fehler oder unerwarteten Messwert: `superpowers:systematic-debugging`.
3. Vor dem Paket-Gate: `superpowers:requesting-code-review`.
4. Vor jeder Aussage „fertig“, „grün“ oder „behoben“: `superpowers:verification-before-completion`.
5. Für Worktree-Anlage: `superpowers:using-git-worktrees`.
6. Für die serielle Abarbeitung dieser Datei: `superpowers:subagent-driven-development`.

### Luna-Arbeitskapsel

Jeder Worker erhält genau dieses Schema, vollständig ausgefüllt und ohne Verweis auf Chat-Historie:

```text
ROLLE: Executor | Contract Reviewer | Verifier
MODELL: gpt-5.6-luna
REASONING: low
PAKET: Pxx / TASK_xxxx / eindeutiger Titel
WORKTREE: absoluter Windows-Pfad
BRANCH: exakter Branchname
BASE-SHA: git rev-parse HEAD beim Start
ZIEL: ein Satz mit dem messbaren Ergebnis
PFLICHTLEKTÜRE: AGENTS.md, PROJECT_BRIEF, ARCHITECTURE, CODEX_RULES,
IMPLEMENTATION_STATUS, TASK_ROADMAP, konkrete Taskdatei und genannte Contracts
ERLAUBTE DATEIEN: vollständige exakte Liste
VERBOTEN: alle anderen Dateien, Budgetänderung, Snapshot-/Autoritätsänderung,
Push, Merge, Branchwechsel, Cleanup fremder Dateien
SCHRITTE: nummerierte Mikroaktionen aus dem Paket
TESTS: exakte Befehle und erwartete Exitcodes/Assertions
GATE: binäre Bedingungen für PASS oder FAIL
RÜCKGABE: Problem; Ursache; Änderung; Dateien; Tests mit Zählung;
Messwerte; Risiken; git diff --check; git status --short
```

### Rückgabeformat der Worker

```text
PACKAGE_RESULT=Pxx
STATUS=pass|fail|blocked
BASE_SHA=vom Worker ermittelter 40-stelliger SHA
HEAD_SHA=vom Worker ermittelter 40-stelliger SHA oder unchanged
FILES_CHANGED=kommagetrennte exakte Pfade oder none
TESTS=Befehl, Exitcode und Pass/Fail-Zahl je Test
MEASUREMENTS=SHA-gebundene Wertebereiche oder not_run mit Grund
CONTRACT_REVIEW=pass|fail mit einem Satz
RISKS=konkrete Restpunkte oder none
NEXT_ACTION=genau eine nächste Aktion
```

## 2. Dirigenten-Ledger

Der Dirigent hält nach jedem Schritt im Chat ein kompaktes Ledger:

```text
P01 observed candidate index ........ not_started
P02 selected combat hotspot ......... not_started
P03 simulation command attribution .. not_started
P04 dominant simulation slice ....... not_started
P05 dynamic overlay stabilization ... not_started
P06 FoW stability ................... not_started
P07 integrated automatic gate ....... not_started
P08 human 128x128 evidence .......... not_started
P09 final release decision .......... not_started
P10 closeout and report ............. not_started
```

Erlaubte Zustände sind `not_started`, `running`, `review`, `verified`, `integrated`, `human_required` und `blocked_with_evidence`. Ein Paket wird erst `integrated`, wenn Task-Branch, Commit, Tests und Integrationsmerge belegt sind.

## 3. Einmaliger Bootstrap vor Paket 01

- [ ] **B01 – Arbeitsstände prüfen**

```powershell
$repoRoot = 'C:\dev\SternenBuergerchen'
$integrationWorktree = 'C:\dev\SternenBuergerchen-worktrees\integration-core-foundation-execution'
$planWorktree = 'C:\dev\SternenBuergerchen-worktrees\task-1195-tactical-performance-report'
git -C $repoRoot worktree list --porcelain
git -C $planWorktree status --short --branch
git -C $integrationWorktree status --short --branch
git -C $integrationWorktree fetch origin --prune
git -C $integrationWorktree rev-parse HEAD
git -C $integrationWorktree rev-parse origin/integration/core-foundation
```

Gate: Beide Worktrees existieren. Der Plan-Worktree ist sauber. Der Integrations-Worktree ist sauber und sein Branch heißt `integration/core-foundation`. Bei fremden Änderungen nicht bereinigen, sondern `blocked_with_evidence` melden.

- [ ] **B02 – Plan-/Berichtbranch einmalig integrieren**

```powershell
git -C $integrationWorktree merge --ff-only origin/integration/core-foundation
git -C $integrationWorktree merge-base --is-ancestor task/1195-tactical-performance-report integration/core-foundation
```

Wenn der zweite Befehl Exitcode 0 liefert, ist die Dokumentation bereits enthalten. Bei Exitcode 1:

```powershell
git -C $integrationWorktree merge --no-ff task/1195-tactical-performance-report -m "merge: add tactical performance recovery plan"
git -C $integrationWorktree push origin integration/core-foundation
```

Danach:

```powershell
git -C $integrationWorktree status --short --branch
git -C $integrationWorktree log -3 --oneline --decorate
```

Gate: Integration ist sauber und `origin/integration/core-foundation` zeigt auf denselben SHA.

- [ ] **B03 – Paket-Worktree-Prinzip festschreiben**

Vor jedem Paket erstellt der Dirigent den exakt genannten Branch aus dem aktuellen Integrations-SHA. Existiert Pfad oder Branch bereits, wird er nicht dupliziert; stattdessen werden Branch, HEAD, Base-Ancestry und Sauberkeit geprüft.

```powershell
git -C $integrationWorktree status --short --branch
git -C $integrationWorktree pull --ff-only origin integration/core-foundation
git -C $integrationWorktree rev-parse HEAD
```

Ein Paket darf nur von einem sauberen, aktuellen Integrations-SHA starten.

---

## Paket 01 – TASK_1196: Observed Combat Candidate Index

**Ziel:** Die bereits pro Tick berechneten Contact Observations begrenzen die Fire-Pair-Suche, ohne Kontakt-, Ziel-, Schuss-, Treffer-, Vital- oder Missionsergebnis zu ändern.

**Modell:** Luna `low`; `medium` nur nach zwei reproduzierten Oracle-/Typfehlern.

**Branch/Worktree:**

- Branch: `task/1196-combat-observed-candidate-index`
- Worktree: `C:\dev\SternenBuergerchen-worktrees\task-1196-combat-observed-candidate-index`

**Verbindlicher Detailplan:** `docs/superpowers/plans/2026-08-31-combat-observed-candidate-index.md`. Jede Checkbox dieses Detailplans wird in Reihenfolge ausgeführt. Der Dirigent überspringt keine rote Testphase.

**Erlaubte Dateien:**

- `docs/tasks/TASK_1196_combat_observed_candidate_index.md`
- `scripts/tests/task_1196_combat_observed_candidate_index.gd`
- `scripts/tests/mission_combat_loop_driver.gd`
- `scripts/tactical/combat_fire_decision_resolver.gd`
- `scripts/tests/tactical_map_frame_budget_harness.gd` nur für einen fehlenden Zähler
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

### Mikroablauf

- [ ] **P01.1 – Worktree erstellen und Pflichtlektüre lesen**

```powershell
$repoRoot = 'C:\dev\SternenBuergerchen'
$worktree = 'C:\dev\SternenBuergerchen-worktrees\task-1196-combat-observed-candidate-index'
git -C $repoRoot worktree add $worktree -b task/1196-combat-observed-candidate-index integration/core-foundation
git -C $worktree status --short --branch
```

- [ ] **P01.2 – Failing Verifier und Debugvertrag erstellen**

Erwartete Debugschnittstelle:

```gdscript
get_fire_candidate_index_debug_snapshot() -> Dictionary
```

Pflichtfelder: `tick`, `candidate_attacker_count`, `candidate_pair_count`, `pairs_by_attacker_id`, `derived_only`, `read_only`, `snapshot_serialized`.

- [ ] **P01.3 – Rot beweisen**

```powershell
& 'C:\Users\bjoer\AppData\Local\Programs\Godot\Godot_v4.6.2-stable_win64_console.exe' --headless --path $worktree --script scripts/tests/task_1196_combat_observed_candidate_index.gd
```

Erwartung: Exitcode ungleich 0, weil die Schnittstelle noch nicht existiert. Ein Parserfehler gilt nicht als gültiges Rot.

- [ ] **P01.4 – Nur Debugoberfläche implementieren und grün machen**

Der Index enthält nur sortierte Unit-IDs, wird jeden autoritativen Tick neu aufgebaut und erscheint in keinem Mission-/Multiplayer-Snapshot.

- [ ] **P01.5 – Index-an/aus-Oracle rot, dann minimal grün implementieren**

Die Indexed- und Legacy-Läufe verwenden denselben Seed und 16v12/600 Ticks. Timing- und Cachezähler werden aus dem Gleichheitsvergleich ausgeschlossen. Kontakte, Fire Events, Unit States und Mission Result müssen bitgleich sein. Indexed Pair Evaluations müssen kleiner oder gleich Legacy sein.

- [ ] **P01.6 – Betroffene Verträge ausführen**

```powershell
$godot = 'C:\Users\bjoer\AppData\Local\Programs\Godot\Godot_v4.6.2-stable_win64_console.exe'
& $godot --headless --path $worktree --script scripts/tests/task_1196_combat_observed_candidate_index.gd
& $godot --headless --path $worktree --script scripts/tests/task_1191_shared_combat_visibility_cache.gd
& $godot --headless --path $worktree --script scripts/tests/task_162_combat_authority_contract_verifier.gd
& $godot --headless --path $worktree --script scripts/tests/task_208_enemy_team_tactics_playability_smoke.gd
git -C $worktree diff --check
```

- [ ] **P01.7 – Kaltlauf und Fortsetzungsgate**

```powershell
pwsh -NoProfile -File "$worktree\scripts\tests\run_task_1187_tactical_map_frame_budget.ps1" -GodotExecutable $godot -ColdRuns 1 -WarmRuns 0
```

Fortsetzen nur, wenn Oracle grün, Pair Evaluations nicht erhöht, `fire_find_contact_pair` nicht mehr als 5 Prozent regressiert und keine Script-/Leak-/Authority-Fehler auftreten.

- [ ] **P01.8 – 3-kalt/5-warm messen**

```powershell
pwsh -NoProfile -File "$worktree\scripts\tests\run_task_1187_tactical_map_frame_budget.ps1" -GodotExecutable $godot -ColdRuns 3 -WarmRuns 5
```

Pflichtauswertung: acht gleiche SHAs; Min/Max je `combat.total_tick_usec`, `combat_scope.combat_fire_decision_usec`, `combat_scope.fire_find_contact_pair_usec`, `combat_scope.contact_tracking_usec`, `combat_scope.enemy_team_tactics_usec`, `simulation.total_tick_usec` und Candidate-Pair-Zähler.

- [ ] **P01.9 – Review, exakte Commits, Integration**

Commits:

```powershell
git -C $worktree add docs/tasks/TASK_1196_combat_observed_candidate_index.md scripts/tests/task_1196_combat_observed_candidate_index.gd scripts/tests/mission_combat_loop_driver.gd
git -C $worktree commit -m "test(combat): lock observed candidate index contract"
git -C $worktree add scripts/tactical/combat_fire_decision_resolver.gd scripts/tests/mission_combat_loop_driver.gd scripts/tests/task_1196_combat_observed_candidate_index.gd
git -C $worktree commit -m "perf(combat): reuse observed target candidates"
git -C $worktree add docs/tasks/TASK_1196_combat_observed_candidate_index.md docs/IMPLEMENTATION_STATUS.md docs/TASK_ROADMAP.md
git -C $worktree commit -m "docs(perf): record observed candidate index evidence"
```

Der Dirigent prüft die tatsächlichen Diffs vor jedem `git add`; nicht geänderte Pfade werden aus dem jeweiligen Befehl entfernt. Danach Task-Branch pushen, `--no-ff` in Integration mergen, gezielte Verträge auf Integration erneut ausführen und Integration pushen.

**Gate P01:** Oracle exakt gleich; Pair Evaluations nicht höher; alle genannten Tests grün; acht Messreports auf einem SHA; TASK_1196 dokumentiert; Integration sauber und gepusht.

---

## Paket 02 – TASK_1197: Genau einen verbliebenen Combat-Hotspot bearbeiten

**Ziel:** Nach P01 genau den größten exklusiven Combat-Subscope reduzieren. Kein Sammelrefactor und keine parallelen Alternativen.

**Modell:** Luna `low`; ein `medium`-Diagnostiker ist nur erlaubt, wenn Scope-Überlappung die Auswahl unentscheidbar macht.

**Branch/Worktree:**

- Branch: `task/1197-selected-combat-hotspot`
- Worktree: `C:\dev\SternenBuergerchen-worktrees\task-1197-selected-combat-hotspot`

### Deterministische Auswahl

- [ ] **P02.1 – Pro Run die p99-Werte extrahieren**

Für die acht P01-Reports werden die p99-Werte der drei exklusiven Scopes gesammelt:

```text
combat_scope.fire_find_contact_pair_usec
combat_scope.contact_tracking_usec
combat_scope.enemy_team_tactics_usec
```

Sortiere jeden Satz und verwende den Mittelwert der beiden mittleren Werte als Median der acht Läufe. Wähle den größten Median. Bei Gleichstand gilt die Reihenfolge Pair Search, Contact Tracking, Enemy Team Tactics. Die Auswahl und alle drei Mediane kommen in die Taskdatei.

- [ ] **P02.2 – Genau einen Dateikorridor aktivieren**

**Variante A – Pair Search gewinnt:**

- Dateien: `scripts/tactical/combat_fire_decision_resolver.gd`, `scripts/mission/combat_visibility_cache.gd`, `scripts/tests/mission_combat_loop_driver.gd`, neuer Verifier `scripts/tests/task_1197_selected_combat_hotspot.gd`.
- Instrumentiere getrennt Candidate-Filter, Range, Cache-Key-Aufbau, LOS-Cache-Lookup und echte Terrain-Prüfung.
- Ändere anschließend nur den größten gemessenen Teilschritt. Zulässig ist ein tick-lokales, abgeleitetes ID-Set oder die Wiederverwendung eines bereits kanonischen Cache-Keys; Node-Referenzen und Snapshotfelder sind verboten.
- Pflichtoracle: P01 Index an/aus und P02 Optimierung an/aus erzeugen dieselben Gameplay-Snapshots.

**Variante B – Contact Tracking gewinnt:**

- Dateien: `scripts/tests/mission_combat_loop_driver.gd`, `scripts/tactical/contact_tracker.gd`, `scripts/mission/combat_visibility_cache.gd`, neuer Verifier `scripts/tests/task_1197_selected_combat_hotspot.gd`.
- Instrumentiere Observation-Aufbau, Detection-Aufrufe, Contact-State-Lookups, LOS-Key/Lookup und Event-Fan-out.
- Ändere nur den größten gemessenen Teilschritt. Wiederverwendete Observation-Daten bleiben tick-lokal und werden nicht zur Gameplay-Wahrheit.
- Pflichtoracle: Kontakte je Tick, Detection-State, Fire Events, Treffer, Vitalstatus und Mission Result bleiben exakt gleich.

**Variante C – Enemy Team Tactics gewinnt:**

- Dateien: `scripts/tests/mission_combat_loop_driver.gd`, `scripts/tactical/enemy_team_tactics_profile.gd`, neuer Verifier `scripts/tests/task_1197_selected_combat_hotspot.gd`.
- Trenne Eingabe-Signatur, Gruppierung, State-Build und Meta-Apply in Debugscopes.
- Ersetze nur den größten gemessenen Teilschritt, bevorzugt wiederholte String-Signaturarbeit durch eine strukturierte, abgeleitete Revision aus Unit-ID, Vitalstatus, quantisierter Position, Profil und Objective-Position.
- Pflichtoracle: `get_enemy_team_tactics_snapshot()`, Labels, Entscheidungen, Commands und Gameplay-Snapshot bleiben exakt gleich; stabile Eingabe erhöht `skip_count`, aber nicht `rebuild_count`.

Die beiden nicht gewählten Varianten werden nicht angefasst.

### Mikroablauf

- [ ] **P02.3 – Taskvertrag und failing Verifier erstellen**
- [ ] **P02.4 – Rot beweisen; Parser-/Fixturefehler nicht akzeptieren**
- [ ] **P02.5 – Nur Debugscopes implementieren; eine kalte Diagnose ausführen**
- [ ] **P02.6 – Genau eine Ursache auswählen und minimal implementieren**
- [ ] **P02.7 – Toggle-/Legacy-Oracle und Direktverträge ausführen**

```powershell
$godot = 'C:\Users\bjoer\AppData\Local\Programs\Godot\Godot_v4.6.2-stable_win64_console.exe'
& $godot --headless --path $worktree --script scripts/tests/task_1197_selected_combat_hotspot.gd
& $godot --headless --path $worktree --script scripts/tests/task_1196_combat_observed_candidate_index.gd
& $godot --headless --path $worktree --script scripts/tests/task_1191_shared_combat_visibility_cache.gd
& $godot --headless --path $worktree --script scripts/tests/task_162_combat_authority_contract_verifier.gd
& $godot --headless --path $worktree --script scripts/tests/task_208_enemy_team_tactics_playability_smoke.gd
& $godot --headless --path $worktree --script scripts/tests/task_218_simulation_combat_ai_tick_budget_pass.gd
git -C $worktree diff --check
```

- [ ] **P02.8 – Eine kalte und danach 3-kalt/5-warm Messung**

Kaltlauf nur als Abbruchkontrolle; Vollserie für die Aussage. Der gewählte Median-p99 muss gegenüber P01 sinken oder das Paket wird als evidenzbasiert unwirksam mit normalem Revert der Produktionsänderung abgeschlossen.

- [ ] **P02.9 – Zwei Commits und Integration**

Commit 1 enthält Taskdatei, failing Verifier und Messinstrumentierung. Commit 2 enthält genau eine Produktionsoptimierung plus Ergebnisdokumentation. Task-/Integrationsbranch werden nur nach Review und Gate gepusht.

**Gate P02:** Nur eine Variante geändert; Verhalten bitgleich; gewählter Scope ohne >5-Prozent-Regression der anderen Combat-Scopes; Vollserie auf einem SHA; Integration sauber und gepusht.

---

## Paket 03 – TASK_1198: Simulation-Command-Attribution ohne Verhaltensänderung

**Ziel:** Den SimulationRoot-Anteil nach Command-Typ, Queue-Ordering und Apply-Arbeit messen, bevor eine Simulation-Optimierung gewählt wird.

**Modell:** Luna `low`.

**Branch/Worktree:**

- Branch: `task/1198-simulation-command-attribution`
- Worktree: `C:\dev\SternenBuergerchen-worktrees\task-1198-simulation-command-attribution`

**Erlaubte Dateien:**

- `docs/tasks/TASK_1198_simulation_command_attribution.md`
- `scripts/core/simulation_root.gd`
- `scripts/tests/tactical_map_frame_budget_harness.gd`
- `scripts/tests/task_1198_simulation_command_attribution.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

**Neue Debugschnittstelle im bestehenden Snapshot:**

```gdscript
get_runtime_tick_budget_debug_snapshot() -> Dictionary
```

Zusätzliche Felder unter Debug-Flag:

```text
command_type_count: Dictionary[String, int]
command_type_usec: Dictionary[String, int]
command_requeue_count: Dictionary[String, int]
scopes_usec.command_ordering_usec: int
scopes_usec.command_apply_usec: int
```

Diese Felder sind Diagnose, read-only, nicht serialisiert und bei ausgeschaltetem Debugpfad ohne zusätzliche Hotpath-Arbeit.

### Mikroablauf

- [ ] **P03.1 – Failing Verifier für Felder, Summen und Debug-Aus erstellen**
- [ ] **P03.2 – Rot beweisen**
- [ ] **P03.3 – `_process_commands()` in Ordering und Apply aufteilen, ohne Reihenfolge zu ändern**
- [ ] **P03.4 – Pro Command-Typ Count/Usec und Requeue-Count nur unter Debug-Flag sammeln**
- [ ] **P03.5 – Harness-Felder als `simulation_command.command_type_usec` und `simulation_command.command_type_count` ausgeben**
- [ ] **P03.6 – Authority-/Snapshot-/Lifecycle-Verträge ausführen**

```powershell
$godot = 'C:\Users\bjoer\AppData\Local\Programs\Godot\Godot_v4.6.2-stable_win64_console.exe'
& $godot --headless --path $worktree --script scripts/tests/task_1198_simulation_command_attribution.gd
& $godot --headless --path $worktree --script scripts/tests/task_162_combat_authority_contract_verifier.gd
& $godot --headless --path $worktree --script scripts/tests/task_166_multiplayer_authority_command_contract_verifier.gd
& $godot --headless --path $worktree --script scripts/tests/task_168_multiplayer_snapshot_contract_verifier.gd
& $godot --headless --path $worktree --script scripts/tests/task_501_integrated_movement_command_lifecycle_hardening.gd
& $godot --headless --path $worktree --script scripts/tests/task_218_simulation_combat_ai_tick_budget_pass.gd
git -C $worktree diff --check
```

- [ ] **P03.7 – Kaltlauf, dann 3-kalt/5-warm**

Pflichtauswertung: Median-p99 und Range für `command_queue_usec`, `command_ordering_usec`, `command_apply_usec`, jeden Command-Typ, `tick_signal_emit_usec` und `simulation.total_tick_usec`. Die Summe der Typ-Counts muss dem verarbeiteten Command-Count entsprechen. Zeitwerte dürfen wegen Messoverhead abweichen; Gameplaywerte nicht.

- [ ] **P03.8 – Instrumentierungscommit, Ergebniscommit, Integration**

Keine Simulation-Optimierung in P03. Der Task schließt mit einer deterministischen Auswahl für P04.

**Gate P03:** Nur Diagnoseänderung; alle Authority-/Snapshotverträge grün; acht SHA-identische Reports; dominanter Simulation-Anteil mit Zahlen benannt; Integration sauber und gepusht.

---

## Paket 04 – TASK_1199: Genau einen dominanten Simulation-Slice bearbeiten

**Ziel:** Aus P03 genau eine nachgewiesene SimulationRoot-Ursache reduzieren. Wenn keine sichere Ursache belegt ist, wird kein Produktionscode geändert.

**Modell:** Luna `low`; `medium` nur zur Analyse eines bewiesenen Command-/Signal-Ownership-Konflikts.

**Branch/Worktree:**

- Branch: `task/1199-dominant-simulation-slice`
- Worktree: `C:\dev\SternenBuergerchen-worktrees\task-1199-dominant-simulation-slice`

### Deterministische Auswahl

- [ ] **P04.1 – Median-p99 aus P03 vergleichen**

1. Wenn `command_ordering_usec` mindestens 25 Prozent von `command_queue_usec` ausmacht, wähle den Ordering-Slice.
2. Sonst, wenn ein Command-Typ mindestens 40 Prozent von `command_apply_usec` ausmacht, wähle diesen Typ.
3. Sonst, wenn `tick_signal_emit_usec` größer als `command_queue_usec` ist, wähle den Signal-Subscriber-Attribution-Slice.
4. Sonst bleibt P04 evidence-only; keine spekulative Änderung.

### Zulässige Varianten

**Ordering-Slice:**

- Datei: `scripts/core/simulation_root.gd` und neuer `scripts/tests/task_1199_dominant_simulation_slice.gd`.
- Erlaubte Minimaländerung: Fast Path für Queue-Größe 0/1; für größere Queues bleibt `_order_payloads()` unverändert. Für Größe 1 muss Dictionary-Validierung gleich bleiben.
- Oracle: identische Reihenfolge bei 0, 1 und gemischten Prioritäten; identische Command-Commit-Events.

**Dominanter Command-Typ:**

- Dateien: `scripts/core/simulation_root.gd`, der bereits zuständige Resolver/Registry-Pfad und neuer Verifier.
- Vor Code wird der dominante Typ in mindestens 6/8 Runs bestätigt.
- Zulässig ist nur die Wiederverwendung eines bereits autoritativen Unit-/Path-/Status-Lookups innerhalb desselben Ticks. Kein Node im Command-Payload, keine serialisierte Cacheinformation, keine geänderte Requeue-Semantik.
- Oracle: Command-Reihenfolge, Positionsfolge, Status, Requeue-Zahl und Multiplayer-Snapshot exakt gleich.

**Signal-Subscriber-Attribution:**

- Dateien zunächst nur `scripts/core/simulation_root.gd`, `scripts/tests/mission_combat_loop_driver.gd`, `scripts/tests/task_1199_dominant_simulation_slice.gd`.
- Zuerst jeden direkten `tick_processed`-Subscriber messen. Danach genau den größten Subscriber bearbeiten, sofern er mindestens 40 Prozent des Signal-Scopes erklärt.
- Keine geänderte Tick-Cadence, Signalreihenfolge oder Autorität.

### Mikroablauf

- [ ] **P04.2 – Taskvertrag und red-green Oracle für die gewählte Variante**
- [ ] **P04.3 – Failing State ausführen und klassifizieren**
- [ ] **P04.4 – Minimale Änderung implementieren**
- [ ] **P04.5 – TASK_1198 plus Authority-/Snapshot-/Movement-Verträge ausführen**

```powershell
$godot = 'C:\Users\bjoer\AppData\Local\Programs\Godot\Godot_v4.6.2-stable_win64_console.exe'
& $godot --headless --path $worktree --script scripts/tests/task_1199_dominant_simulation_slice.gd
& $godot --headless --path $worktree --script scripts/tests/task_1198_simulation_command_attribution.gd
& $godot --headless --path $worktree --script scripts/tests/task_162_combat_authority_contract_verifier.gd
& $godot --headless --path $worktree --script scripts/tests/task_166_multiplayer_authority_command_contract_verifier.gd
& $godot --headless --path $worktree --script scripts/tests/task_168_multiplayer_snapshot_contract_verifier.gd
& $godot --headless --path $worktree --script scripts/tests/task_501_integrated_movement_command_lifecycle_hardening.gd
```

- [ ] **P04.6 – Kaltlauf und 3-kalt/5-warm**
- [ ] **P04.7 – Commit, Review und Integration**

**Gate P04:** Gewählte Ursache in mindestens 6/8 Baseline-Läufen dominant; exakt eine Produktionsänderung; Verhalten gleich; gewählter Scope sinkt ohne >5-Prozent-Regression anderer Simulation-Scopes; Integration sauber und gepusht. Evidence-only ist ein zulässiges Ergebnis, aber keine behauptete Optimierung.

---

## Paket 05 – TASK_1200: Dynamic-Overlay-Stabilisierung

**Ziel:** `terrain.dynamic_overlay_usec` in 8/8 Läufen auf p99 höchstens 1.000 µs stabilisieren, ohne Order-/LOS-/Fire-Sector-Darstellung zu verändern.

**Modell:** Luna `low`.

**Branch/Worktree:**

- Branch: `task/1200-dynamic-overlay-stability`
- Worktree: `C:\dev\SternenBuergerchen-worktrees\task-1200-dynamic-overlay-stability`

**Erlaubte Dateien:**

- `docs/tasks/TASK_1200_dynamic_overlay_stability.md`
- `scripts/terrain/terrain_map_3d_view.gd`
- `scripts/tests/task_1200_dynamic_overlay_stability.gd`
- `scripts/tests/tactical_map_frame_budget_harness.gd` nur für Diagnosezähler
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

**Vertrag:** `_refresh_dynamic_order_visuals_if_needed()` darf bei unveränderten Quellen weder eine Signatur neu zusammensetzen noch Order-Visuals rebuilden. `_build_order_dynamic_visual_signature()` muss dieselben visuellen Eingaben abdecken: ausgewählte Fireteams, Fire-Sector-Modus, LOS-Debug/Contact-Apply, sichtbare Unit-Position/Rotation und Live-Orientation.

### Mikroablauf

- [ ] **P05.1 – Failing Verifier mit 28 Units, 4 relevanten Units und stabiler Payload**

Der Verifier verlangt Diagnosezähler `dynamic_signature_build_count`, `dynamic_signature_unit_scan_count`, `dynamic_order_rebuild_count` und `dynamic_order_skip_count`. Nach dem ersten Aufbau dürfen 120 stabile Frames keinen Rebuild erzeugen. Ein Move einer relevanten Unit erzeugt genau einen geänderten Zustand; ein Move einer irrelevanten Unit erzeugt keinen sichtbaren Rebuild.

- [ ] **P05.2 – Rot beweisen**
- [ ] **P05.3 – Read-only Relevanzindex aufbauen**

Beim Setzen der Order-Payload wird eine sortierte Union relevanter Unit-IDs für ausgewählte und Orientation-Fireteams erzeugt. Unit-Membership-/Proxy-Änderung invalidiert nur diesen abgeleiteten Renderindex. Die Signatur iteriert die relevanten IDs statt alle `_unit_nodes`. Der Index enthält keine Gameplaywerte und wird nicht serialisiert.

- [ ] **P05.4 – Signatur-/Rebuild-Oracle grün machen**
- [ ] **P05.5 – Sicht-/FoW-/Proxy-Verträge ausführen**

```powershell
$godot = 'C:\Users\bjoer\AppData\Local\Programs\Godot\Godot_v4.6.2-stable_win64_console.exe'
& $godot --headless --path $worktree --script scripts/tests/task_1200_dynamic_overlay_stability.gd
& $godot --headless --path $worktree --script scripts/tests/task_1188_unit_proxy_dirty_sync.gd
& $godot --headless --path $worktree --script scripts/tests/task_225_fog_of_war_2_5d_visual_overlay_and_contacts.gd
& $godot --headless --path $worktree --script scripts/tests/task_1157_command_matrix_1280_readability.gd
git -C $worktree diff --check
```

- [ ] **P05.6 – 1 Kaltlauf; bei Budgetpass 3-kalt/5-warm**
- [ ] **P05.7 – Visuelles manuelles Smoke nur als Zusatz, nicht als TASK-1193-Manuellevidenz**

Order, Fire Sector und LOS Overlay bei 1920x1080 kurz prüfen. Dieses Smoke darf nicht als `tactical_release_manual_playtest_evidence.md` ausgegeben werden.

- [ ] **P05.8 – Commit, Review und Integration**

**Gate P05:** Visual-Oracle grün; irrelevante Units triggern keinen Rebuild; Dynamic Overlay p99 in 8/8 ≤1.000 µs; keine Unit-Proxy-/FoW-Regressions; Integration sauber und gepusht.

---

## Paket 06 – TASK_1201: FoW-Stabilität mit No-Code-Pass

**Ziel:** `terrain.fow_work_usec` in 8/8 Läufen auf p99 höchstens 2.000 µs halten und Sichtrevision innerhalb 350 ms publizieren. Wenn der aktuelle Integrationsstand bereits 8/8 passt, wird kein Runtime-Code geändert.

**Modell:** Luna `low`.

**Branch/Worktree:**

- Branch: `task/1201-fow-stability`
- Worktree: `C:\dev\SternenBuergerchen-worktrees\task-1201-fow-stability`

### Mikroablauf

- [ ] **P06.1 – Unveränderte 3-kalt/5-warm Serie zuerst**

Wenn alle acht FoW-Budgetstatus `pass` sind und keine Visibility-Revision älter als 350 ms wird, Taskdatei als `VERIFIED_NO_CODE` dokumentieren und zu P06.7 springen.

- [ ] **P06.2 – Nur bei mindestens einem roten Lauf failing Stabilitätsverifier erstellen**

**Erlaubte Dateien bei Rot:**

- `docs/tasks/TASK_1201_fow_stability.md`
- `scripts/core/fog_of_war_system.gd`
- `scripts/terrain/terrain_map_3d_view.gd` nur wenn der gemessene Delta-Apply-Anteil dominiert
- `scripts/tests/task_1201_fow_stability.gd`
- `scripts/tests/tactical_map_frame_budget_harness.gd`

- [ ] **P06.3 – Phasen messen**

Debugfelder: `candidate_scan_usec`, `visibility_evaluation_usec`, `delta_commit_usec`, `candidate_tile_count`, `processed_tile_count`, `slice_count`, `visibility_revision_age_msec`. Wähle den größten Median-p99-Teil.

- [ ] **P06.4 – Genau einen Teil optimieren**

Dirty-Regionen, atomare Veröffentlichung und 350-ms-Grenze bleiben erhalten. Kein Partial-Visibility-Publish, kein Full-Scan-Ersatz, keine Sichtwahrheit im Renderer.

- [ ] **P06.5 – FoW-Verträge ausführen**

```powershell
$godot = 'C:\Users\bjoer\AppData\Local\Programs\Godot\Godot_v4.6.2-stable_win64_console.exe'
& $godot --headless --path $worktree --script scripts/tests/task_1201_fow_stability.gd
& $godot --headless --path $worktree --script scripts/tests/task_1189_fow_dirty_region_fanout.gd
& $godot --headless --path $worktree --script scripts/tests/task_224_fog_of_war_tile_visibility_height_cover_runtime.gd
& $godot --headless --path $worktree --script scripts/tests/task_225_fog_of_war_2_5d_visual_overlay_and_contacts.gd
& $godot --headless --path $worktree --script scripts/tests/task_1188_unit_proxy_dirty_sync.gd
git -C $worktree diff --check
```

- [ ] **P06.6 – Kaltlauf und 3-kalt/5-warm wiederholen**
- [ ] **P06.7 – Evidence-only oder Produktionscommit, Review und Integration**

Bei `VERIFIED_NO_CODE` enthält der Commit nur Task-/Statusdokumente. Bei Codeänderung werden Test/Instrumentierung und Produktion getrennt committed.

**Gate P06:** FoW 8/8 ≤2.000 µs; Revision Age ≤350 ms; atomare Sicht und Delta-Oracle grün; Integration sauber und gepusht.

---

## Paket 07 – TASK_1202: Integrierter automatischer Release-Gate und Reparaturschleife

**Ziel:** Auf einem einzigen Integrations-SHA alle automatischen Enforcer und alle TASK-1187-Budgets grün bekommen. Fehlende menschliche Evidenz darf der einzige verbleibende Blocker sein.

**Modell:** Luna `low` für Ausführung/Auswertung; `medium` nur für widersprüchliche Gate-/JSON-Ausgabe.

**Arbeitsort:** ausschließlich sauberer Integrations-Worktree `C:\dev\SternenBuergerchen-worktrees\integration-core-foundation-execution`. P07 ändert dort zunächst keine Dateien.

### Mikroablauf

- [ ] **P07.1 – Integration und Remote-SHA belegen**

```powershell
$integrationWorktree = 'C:\dev\SternenBuergerchen-worktrees\integration-core-foundation-execution'
$godot = 'C:\Users\bjoer\AppData\Local\Programs\Godot\Godot_v4.6.2-stable_win64_console.exe'
git -C $integrationWorktree status --short --branch
git -C $integrationWorktree fetch origin --prune
git -C $integrationWorktree rev-parse HEAD
git -C $integrationWorktree rev-parse origin/integration/core-foundation
```

- [ ] **P07.2 – Vollständigen TASK-1193-Gate ausführen**

```powershell
pwsh -NoProfile -File "$integrationWorktree\scripts\tests\run_task_1193_tactical_release_acceptance.ps1" -GodotExecutable $godot -ColdRuns 3 -WarmRuns 5
```

Der Exitcode darf wegen fehlender manueller Evidenz 1 sein. Entscheidend ist die Zeile `TACTICAL_RELEASE_ACCEPTANCE_JSON=`.

- [ ] **P07.3 – Binär auswerten**

Automatisches Ziel:

```text
TASK_1179 pass
TASK_1192 pass
TASK_284 pass
TASK_832 pass
TASK_868 pass
TASK_411 pass
TASK_222 pass
TASK_1187 pass
alle budget_status.*.status pass
```

Wenn nur `Manual evidence is missing` oder die SHA-Prüfung der manuellen Evidenz verbleibt, gehe zu P08.

- [ ] **P07.4 – Bei automatischem Rot genau einen Reparaturzyklus starten**

Priorität: Harness-/Script-/Leakfehler, Combat, Simulation, Dynamic Overlay, FoW, Interaktion, andere Budgets. Erzeuge genau einen Branch für den ersten Blocker, verwende den passenden Paketvertrag P02/P04/P05/P06, führe red-green, direkte Verträge, 1 Kaltlauf und 3-kalt/5-warm aus, integriere und wiederhole P07.2. Nie zwei Budgetblocker in einem Reparaturcommit.

Deterministische Branchnamen für den ersten Zyklus:

```text
task/1202-gate-repair-harness
task/1202-gate-repair-combat
task/1202-gate-repair-simulation
task/1202-gate-repair-dynamic-overlay
task/1202-gate-repair-fow
task/1202-gate-repair-interaction
task/1202-gate-repair-other-budget
```

Ein zweiter Zyklus desselben Scopes erhält das Suffix `-02`, danach `-03`. Vor jedem Zyklus muss die vorherige Ursache und der neue Messbefund dokumentiert sein. Wenn drei Zyklen desselben Scopes keine messbare Verbesserung liefern, nicht blind fortsetzen: `blocked_with_evidence`, genaue Profile/Versuche und eine neue Architekturentscheidung anfordern.

- [ ] **P07.5 – TASK_1202 dokumentieren**

Taskdatei enthält Integrations-SHA, acht Läufe, Enforcerstatus, alle Budgetranges und exakt verbleibende Failures aus dem JSON.

**Gate P07:** Alle automatischen Enforcer und Budgets pass; nur reale menschliche Evidenz fehlt; Integration sauber und gepusht. Sonst Reparaturschleife oder evidenzbasierter Blocker, keine falsche Freigabe.

---

## Paket 08 – TASK_1203: SHA-sichere echte 128x128-Full-HD-Manuellevidenz

**Ziel:** Zuerst die bereits nachgewiesene SHA-Zirkularität des bestehenden Evidenz-Gates red-green beheben; danach spielt eine verantwortliche Person den echten 128x128-Pfad auf dem exakt automatisch geprüften Code-SHA und dokumentiert das Ergebnis. Der Dirigent darf diese Evidenz weder erzeugen noch als Mensch ausfüllen.

**Modell:** Kein Luna-Executor für die eigentliche Prüfung. Luna `low` darf nur die Anleitung und anschließend die formale Vollständigkeit prüfen.

**Branch/Worktrees:**

- Contract-Branch: `task/1203-manual-evidence-sha-binding`
- Contract-Worktree: `C:\dev\SternenBuergerchen-worktrees\task-1203-manual-evidence-sha-binding`
- Evidence-Branch: `task/1203-manual-128x128-evidence`
- Evidence-Worktree: `C:\dev\SternenBuergerchen-worktrees\task-1203-manual-128x128-evidence`

### Mikroablauf

- [ ] **P08.1 – Failing SHA-Binding-Vertrag erstellen**

Der bestehende Runner fordert `git_sha: HEAD`. Eine neu committed Evidenzdatei kann ihren eigenen Commit-SHA nicht vorab enthalten. Das ist ein realer Gate-Vertragsfehler und wird vor dem Human-Handoff behoben.

Erlaubte Dateien im Contract-Worktree:

- `docs/tasks/TASK_1203_manual_evidence_sha_binding.md`
- `scripts/tests/task_1193_tactical_release_acceptance.gd`
- `scripts/tests/run_task_1193_tactical_release_acceptance.ps1`
- `docs/tasks/TASK_1193_tactical_release_acceptance.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

Der failing Verifier verlangt:

```text
git_sha in der Evidenz bezeichnet den automatisch und menschlich geprüften Code-SHA.
Der Evidenzcommit darf ein Nachfahre dieses Code-SHA sein.
Zwischen Code-SHA und Evidenzcommit darf ausschließlich
docs/performance/tactical_release_manual_playtest_evidence.md geändert sein.
Der Code-SHA muss Ancestor des Evidenzcommits sein.
Ungültige, unbekannte oder nicht verwandte SHAs bleiben blockiert.
```

- [ ] **P08.2 – Rot beweisen**

```powershell
$godot = 'C:\Users\bjoer\AppData\Local\Programs\Godot\Godot_v4.6.2-stable_win64_console.exe'
& $godot --headless --path 'C:\dev\SternenBuergerchen-worktrees\task-1203-manual-evidence-sha-binding' --script scripts/tests/task_1193_tactical_release_acceptance.gd
```

Erwartung: Der neue Parent-/Ancestor-Evidenzfall schlägt gegen den bisherigen exakten `git_sha: HEAD`-Vergleich fehl.

- [ ] **P08.3 – Minimalen Runner-Fix implementieren**

`run_task_1193_tactical_release_acceptance.ps1` liest den 40-stelligen Wert der Zeile `git_sha:`. Er akzeptiert ihn nur, wenn er HEAD entspricht oder Ancestor von HEAD ist und `git diff --name-only git_sha..HEAD` exakt einen Pfad liefert: `docs/performance/tactical_release_manual_playtest_evidence.md`. Der Summary-JSON enthält zusätzlich `manual_evidence_git_sha`. Alle bestehenden Pflichtfelder, `synthetic_fixture: false` und automatischen Budgets bleiben unverändert.

- [ ] **P08.4 – Contract prüfen, committen, integrieren und pushen**

```powershell
& $godot --headless --path 'C:\dev\SternenBuergerchen-worktrees\task-1203-manual-evidence-sha-binding' --script scripts/tests/task_1193_tactical_release_acceptance.gd
git -C 'C:\dev\SternenBuergerchen-worktrees\task-1203-manual-evidence-sha-binding' diff --check
```

Commit 1 enthält failing Verifier/Taskvertrag, Commit 2 den Runner-Fix, Commit 3 die dokumentierte Prüfung. Nach Review in Integration mergen, den TASK-1193-Verifier dort wiederholen und Integration pushen.

- [ ] **P08.5 – Evidence-Worktree aus dem geprüften Integrations-SHA erstellen**

Dieser Base-SHA wird als `manualTestCodeSha` im Ledger festgehalten. Vor dem Human-Playtest ist der Evidence-Worktree sauber und enthält noch keine Evidenzdatei.

- [ ] **P08.6 – Human-Handoff ausgeben**

Der Dirigent nennt exakt:

```text
Git-SHA: manualTestCodeSha aus P08.5
Godot: 4.6.2
Viewport: 1920x1080
Map: 128x128
Pfad: echte Mission, kein release-singleplayer-first-go-firefight Fixture
Aktionen: LZ/De-board, erster Move, erster Contact, erster Fire Event,
Kamera Pan/Zoom, Overlay/Menü öffnen und zurückkehren
Werkzeuge: Godot Profiler, Visual Profiler, Monitors, Video RAM
Datei: docs/performance/tactical_release_manual_playtest_evidence.md
```

- [ ] **P08.7 – Nur der Mensch erstellt die Evidenzdatei**

Sie muss diese exakten maschinenlesbaren Felder enthalten:

```text
result: PASS
reviewed_by: Name der tatsächlich prüfenden Person
git_sha: exakt manualTestCodeSha aus P08.5
map_size: 128x128
first_move: PASS
first_contact: PASS
first_fire: PASS
stutter_check: PASS
synthetic_fixture: false
```

Zusätzlich: Datum, CPU/GPU/RAM, Godot-Version, Cold/Warm-Beobachtung, Pan/Zoom, Overlay-Rückkehr, auffällige Spikes und kurze Entscheidung.

- [ ] **P08.8 – Formale Prüfung nach menschlicher Rückgabe**

```powershell
$evidenceWorktree = 'C:\dev\SternenBuergerchen-worktrees\task-1203-manual-128x128-evidence'
git -C $evidenceWorktree rev-parse HEAD
Get-Content -Raw "$evidenceWorktree\docs\performance\tactical_release_manual_playtest_evidence.md"
```

Der Dirigent prüft Felder und SHA, ändert aber keine Beobachtung. Bei `FAIL` bleibt Release blockiert und der konkrete menschliche Befund wird ein neuer kleiner Task; kein Feld wird auf PASS umgeschrieben.

- [ ] **P08.9 – Menschliche Datei separat committen, prüfen und integrieren**

```powershell
git -C $evidenceWorktree add docs/performance/tactical_release_manual_playtest_evidence.md
git -C $evidenceWorktree commit -m "test(release): record 128x128 manual playtest evidence"
git -C $evidenceWorktree diff --check integration/core-foundation...HEAD
git -C $evidenceWorktree diff --name-only integration/core-foundation...HEAD
```

Der letzte Befehl muss exakt die Evidenzdatei ausgeben. Erst dann Review, Task-Branch pushen, in Integration mergen und Integration pushen.

**Gate P08:** SHA-Binding-Verifier grün; nur die Evidenzdatei liegt zwischen `manualTestCodeSha` und Evidence-Commit; echte Person, 128x128/FullHD, alle Pflichtfelder, `synthetic_fixture: false`; Integration sauber und gepusht.

---

## Paket 09 – TASK_1204: Finale Release-Entscheidung auf einem SHA-konsistenten Stand

**Ziel:** TASK_1193 liefert `release_status=approved` oder einen ehrlichen, exakt benannten Blocker. Kein automatischer Merge nach `main`.

**Modell:** Luna `low`; der SHA-Vertrag wurde bereits in P08 red-green gesichert.

### Mikroablauf

- [ ] **P09.1 – SHA-Vertrag der Evidenz erneut prüfen**

Der Runner muss `manual_evidence_git_sha=manualTestCodeSha` melden. `git diff --name-only manualTestCodeSha..HEAD` muss ausschließlich die Evidenzdatei enthalten. Jede zusätzliche Code-/Datenänderung invalidiert die menschliche Evidenz und erfordert einen neuen Playtest auf dem neuen Code-SHA.

- [ ] **P09.2 – Vollständigen Gate erneut ausführen**

```powershell
$integrationWorktree = 'C:\dev\SternenBuergerchen-worktrees\integration-core-foundation-execution'
$godot = 'C:\Users\bjoer\AppData\Local\Programs\Godot\Godot_v4.6.2-stable_win64_console.exe'
pwsh -NoProfile -File "$integrationWorktree\scripts\tests\run_task_1193_tactical_release_acceptance.ps1" -GodotExecutable $godot -ColdRuns 3 -WarmRuns 5
```

- [ ] **P09.3 – JSON und Exitcode gemeinsam prüfen**

PASS verlangt Exitcode 0, `release_status=approved`, acht grüne Enforcer, alle Budgets pass und `manual_evidence_passed=true`.

- [ ] **P09.4 – Integrationsfreigabe dokumentieren**

`docs/tasks/TASK_1204_final_tactical_release_decision.md` enthält SHA, Testzähler, Budgetranges, manuelle Person/Datum ohne erfundene Inhalte und Entscheidung.

- [ ] **P09.5 – Einmalige externe Autoritätsfrage**

Nur bei vollständigem PASS fragt der Dirigent genau einmal:

```text
Der Integrationsstand ist auf dem unmittelbar zuvor ausgegebenen aktuellen SHA vollständig automatisch und
manuell freigegeben. Soll ich diesen Stand jetzt nach main mergen und den
Release-/Tag-Schritt vorbereiten?
```

Ohne ausdrückliches Ja endet P09 als `integration_release_ready`. Kein Main-Merge, kein Tag, kein Release.

**Gate P09:** TASK_1193 tatsächlich approved oder genauer Blocker dokumentiert; keine zirkuläre/falsche Evidenz-SHA; keine unerlaubte Main-/Release-Aktion.

---

## Paket 10 – TASK_1205: Abschlussbericht, Status und Übergabe

**Ziel:** Den tatsächlich erreichten Stand als neuen responsiven HTML-Abschlussbericht und kompakte Repository-Wahrheit dokumentieren.

**Modell:** Luna `low` für Datensammlung und Dokumentation; ein read-only Luna-Reviewer `low` prüft Claim/Evidence-Grenzen.

**Branch/Worktree:**

- Branch: `task/1205-tactical-performance-closeout`
- Worktree: `C:\dev\SternenBuergerchen-worktrees\task-1205-tactical-performance-closeout`

**Erlaubte Dateien:**

- `docs/tasks/TASK_1205_tactical_performance_closeout.md`
- `docs/reports/STERNENBUERGERCHEN_TACTICAL_PERFORMANCE_RELEASE_RECOVERY_ABSCHLUSS.html`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- die abgeschlossenen Taskdateien 1196 bis 1204 nur für fehlende Ergebnisabschnitte

### Mikroablauf

- [ ] **P10.1 – Git-/Task-/Messinventar aus lokalen Quellen erstellen**

Liste pro Paket Branch, Commit, Integrationsmerge, Dateien, Testzähler, Mess-SHA, Baseline/After-Range und Gate-Status. Nicht gemessene oder evidence-only Pakete werden so bezeichnet.

- [ ] **P10.2 – HTML-Bericht erstellen**

Der Bericht enthält: Executive Summary, vorher/nachher Messmatrix, Package Ledger, Architektur-/Gameplay-Oracle, automatische Gates, menschliche Evidenz, offene Risiken, Releaseentscheidung, Git-Historie und direkte lokale Links. Er funktioniert per `file://`, mobil bei 390 px, Desktop, Druck und ohne externe Ressourcen.

- [ ] **P10.3 – Claim Review**

Jede Aussage wird als `verifiziert`, `teilweise`, `nicht ausgeführt` oder `blockiert` klassifiziert. Keine Optimierungsbehauptung ohne Messserie; keine Releasebehauptung ohne P09-PASS.

- [ ] **P10.4 – Technische Dokumentprüfung**

```powershell
$worktree = 'C:\dev\SternenBuergerchen-worktrees\task-1205-tactical-performance-closeout'
npx --yes html-validate "$worktree\docs\reports\STERNENBUERGERCHEN_TACTICAL_PERFORMANCE_RELEASE_RECOVERY_ABSCHLUSS.html"
git -C $worktree diff --check
git -C $worktree status --short
```

Zusätzlich: alle lokalen `href`-Ziele vorhanden, IDs eindeutig, Browserkonsole ohne Fehler, Desktop- und 390-px-Mobilansicht visuell prüfen.

- [ ] **P10.5 – Dokumentcommit, Review, Integration und Push**

```powershell
git -C $worktree add docs/tasks/TASK_1205_tactical_performance_closeout.md docs/reports/STERNENBUERGERCHEN_TACTICAL_PERFORMANCE_RELEASE_RECOVERY_ABSCHLUSS.html docs/IMPLEMENTATION_STATUS.md docs/TASK_ROADMAP.md
git -C $worktree commit -m "docs(perf): close tactical release recovery"
```

Nach Review Task-Branch pushen, in Integration mergen, Dokumentprüfung auf Integration wiederholen und Integration pushen.

- [ ] **P10.6 – Finale Dirigenten-Ausgabe**

Die Antwort verwendet genau die Repository-Kategorien:

1. Problem
2. Ursache
3. Änderung
4. betroffene Dateien
5. Risiken / offene Punkte
6. lokale Prüflogik
7. Git-Status / Commit / Push-Status

Zusätzlich enthält sie einen direkten Link zum Abschlussbericht und nennt, ob `main` unverändert, gemergt oder noch freizugeben ist.

**Gate P10:** Bericht technisch/visuell geprüft; Claims durch Task-/Messdaten gedeckt; Status/Roadmap aktuell; Integration sauber und gepusht; Main-/Release-Status explizit.

---

## 4. Stopp-, Revert- und Selbstheilungsregeln

### Ohne Nutzerfrage selbst lösen

- Fehlender Importcache: Godot im betroffenen Worktree headless starten und nur ignorierte Importartefakte entstehen lassen.
- Ein einzelner Testfehler: exakt reproduzieren, mit `systematic-debugging` Ursache bestimmen, minimal korrigieren, vollständiges Paket-Gate wiederholen.
- Testname/Dateipfad hat sich auf Integration geändert: mit `rg --files` und Taskdokumenten verifizieren; keine neuen Tests erfinden, wenn ein bestehender äquivalenter Contract vorhanden ist.
- Schwankender Einzelmesswert: keine Entscheidung aus einem Lauf; 3-kalt/5-warm und Wertebereiche verwenden.
- Unwirksame Optimierung: nur Produktionscommit normal reverten, Verifier/Diagnose behalten und Ergebnis dokumentieren.
- Task-Branch existiert bereits: Branch, Base, Worktree und Sauberkeit prüfen und fortsetzen; keine Duplikate erzeugen.

### Echte Stopps

- Fremde uncommitted Änderungen überlappen erlaubte Dateien.
- Drei dokumentierte Reparaturzyklen desselben Scopes verbessern die Messung nicht.
- Menschliche 128x128-Evidenz fehlt oder ist FAIL.
- Main-Merge, Tag, Release oder Deployment steht an und es gibt keine ausdrückliche aktuelle Anweisung.

### Revert-Regel

Kein `git reset --hard` und kein Checkout fremder Dateien. Bei einer bereits committed, regressiven Produktionsänderung:

```powershell
$productionCommitSha = 'der im Paket-Ledger festgehaltene 40-stellige Produktionscommit-SHA'
git show --stat $productionCommitSha
git revert $productionCommitSha
```

Der Revert wird getestet, dokumentiert und normal gepusht. Nicht committed Änderungen werden nur in den exakten, vom Worker selbst geänderten Dateien per `apply_patch` korrigiert.

## 5. Abschlusskriterium des Gesamtplans

Der Plan ist vollständig abgearbeitet, wenn P01 bis P10 jeweils einen belegten Endstatus besitzen, alle automatischen TASK-1193-Enforcer und Budgets auf einem Integrations-SHA grün sind, echte 128x128-Evidenz korrekt gebunden ist, die finale Releaseentscheidung ehrlich dokumentiert ist und der Abschlussbericht im Integrationsbranch liegt. Ein Main-Merge ist nicht Teil des automatischen Abschlusses.

# ENDE DER KOPIERFERTIGEN DIRIGENTEN-ANWEISUNG
