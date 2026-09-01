# Combat-/Contact-Visibility-Architekturanalyse Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> `superpowers:subagent-driven-development` (recommended) or
> `superpowers:executing-plans` to implement this plan task-by-task. Steps use
> checkbox (`- [ ]`) syntax for tracking.

**Goal:** Die reale, gerichtete Sichtabfrage-Topologie von Contact Tracking,
Fire Pair Search und Enemy Tactics belegen, drei voneinander isolierte
Architekturvarianten zeitnah gepaart messen und genau eine sichere Empfehlung
oder `NO_SAFE_FOURTH_FIX` ausgeben.

**Architecture:** Ein debug-only Modus T erfasst Konsumenten, gerichtete Paare,
Gueltigkeitsgruende und Kosten, waehrend ein separater Modus P nur vorhandene
Gate-Scopes und minimale Variantenzaehler nutzt. Jede Variante laeuft mit
AUS/EIN-Schalter im selben Build und wird nach ihrer Evidenz durch normale
Revert-Commits wieder entfernt; der Analysezweig wird nie integriert.

**Tech Stack:** Godot 4.6.2, GDScript, PowerShell 7, Git-Worktrees, bestehender
TASK-1187-Tactical-Map-Harness und 16v12-Combat-Fixture.

**Spec:**
`docs/superpowers/specs/2026-09-01-combat-contact-visibility-analysis-design.md`

## Global Constraints

- Autoritative Runtime-Basis ist exakt
  `origin/integration/core-foundation` auf
  `3cae5a216d380b58fef92724540e95fbc49bde7e`. Drift vor P00 blockiert die
  Ausfuehrung und verlangt eine Planaktualisierung.
- Plan-/Spec-Quelle ist der gepushte Branch
  `origin/task/1206-combat-contact-visibility-analysis-plan`; sein beim Start
  aufgeloester 40-stelliger SHA wird unveraenderlich im Preflight protokolliert.
- Analysebranch ist exakt
  `task/1206-combat-contact-visibility-architecture-analysis`; Worktree ist
  exakt
  `C:\dev\SternenBuergerchen-worktrees\task-1206-combat-contact-visibility-architecture-analysis`.
- Der Ausfuehrungszweig entsteht mit `superpowers:using-git-worktrees` frisch
  von der autoritativen Integrationsbasis. Bestehende gleichnamige Branches
  oder Worktrees werden nicht ueberschrieben.
- `C:\dev\SternenBuergerchen` und dessen dirty/stale `main` bleiben
  unveraendert. Kein `checkout`, `reset`, `clean`, `stash`, `git add .` oder
  breites Prozessbeenden dort.
- `SimulationRoot` bleibt alleinige Gameplay-Mutationsautoritaet. Terrain-LoS
  bleibt ticklokal, abgeleitet, read-only und nicht serialisiert.
- Range, Arc, Vitalstatus, Detection, Stealth, Weapon-, Command- und Teamregeln
  verbleiben bei den bestehenden Konsumenten.
- Source/Target bleibt gerichtet. Reverse-Paare sind Diagnose, niemals Fast
  Path, solange kein eigener Richtungs- und Reichweitenbeweis vorliegt.
- Modus T und Modus P werden nie gleichzeitig aktiviert. Modus-T-Zeiten sind
  Diagnose und keine Release-Performance-Evidenz.
- Es laeuft hoechstens ein Paket und hoechstens ein Worker gleichzeitig. Ein
  Worker startet keine weiteren Worker und fuehrt keinen Commit oder Push aus.
- Standardworker ist immer `gpt-5.6-luna` mit `low`. Die freigegebene Spec
  ueberschreibt damit den generischen High-/Xhigh-Default des
  Orchestrierungs-Skills.
- `medium` ist erst nach einer reproduzierten Evidenzkollision erlaubt;
  `high` nur bei belegter Autoritaets-, Snapshot- oder gerichteter
  Sichtsemantik-Kollision. Niemals `xhigh`, `max` oder `ultra`.
- Nur der Dirigent darf nach eigener Scope-, Diff- und Testpruefung committen
  und den Analysebranch ohne Force pushen.
- Nicht autorisiert: PR, Merge nach `integration/core-foundation`, Aenderung an
  `main`, Remote-Merge, Tag, Release und Deployment.
- Eine Empfehlung aus TASK-1206 ist kein produktiver Fix. Eine spaetere
  Umsetzung startet als neuer Task frisch von der Integrationsbasis.
- Ein unerwarteter Testfehler aktiviert `superpowers:systematic-debugging`;
  Gates oder Schwellen werden nicht aufgeweicht.

---

## 1. Dirigentenvertrag

### 1.1 Paket-Ledger

Der Dirigent fuehrt diese Tabelle im Arbeitsprotokoll. Zulaessige Zustaende
sind `pending`, `running`, `worker-complete`, `verified-green` und `blocked`.
Nur eine Zeile darf `running` sein.

| Paket | Ergebnis | Anfangszustand |
|---|---|---|
| P00 | Autoritaet, Worktree, WIP-Manifest und Baseline | pending |
| P01 | Erwartet roter Topologievertrag | pending |
| P02 | Gruene Modus-T-Instrumentierung | pending |
| P03 | 16v12-Topologiematrix und Varianten-Eligibility | pending |
| P04 | Erwartet roter gepaarter Runnervertrag | pending |
| P05 | Gruener Modus-P-Runner und Self-Control | pending |
| P06 | Variante A gemessen und wieder entfernt | pending |
| P07 | Variante B gemessen und wieder entfernt | pending |
| P08 | Variante C gemessen und wieder entfernt | pending |
| P09 | Binare Entscheidung und Abschlussakte | pending |

`worker-complete` ist kein Erfolg. Nur der Dirigent setzt nach eigener
Reproduktion `verified-green`. Ein Paket startet erst nach
`verified-green` des direkten Vorgaengers.

### 1.2 Verbindlicher Preflight-Datensatz

Vor P01 und nach jedem Kontextverlust wird exakt dieser Datensatz neu befuellt:

```text
AUTHORITATIVE_ROOT: C:\dev\SternenBuergerchen
PLAN_PATH: docs/superpowers/plans/2026-09-01-combat-contact-visibility-architecture-analysis.md
PLAN_REVISION: 40-stelliger SHA des beim Start gelesenen Planbranches
PROJECT_INSTRUCTIONS: C:\dev\SternenBuergerchen\AGENTS.md plus die dort genannten Kerndokumente
CURRENT_BRANCH: task/1206-combat-contact-visibility-architecture-analysis
HEAD_SHA: tatsaechlicher 40-stelliger SHA
EXPECTED_BASE_SHA: 3cae5a216d380b58fef92724540e95fbc49bde7e
WORKTREE: C:\dev\SternenBuergerchen-worktrees\task-1206-combat-contact-visibility-architecture-analysis
DIRTY_TRACKED: exakte Liste oder NONE
DIRTY_UNTRACKED: exakte Liste oder NONE
WIP_BASELINE_MANIFEST: git status, git diff, git diff --cached und SHA256 aller erlaubten bereits vorhandenen Dateien
ACTIVE_AGENTS: exakte Liste oder NONE
REMOTE_AND_PR_STATE: Branchtracking und bekannte PRs; UNKNOWN ist nicht gruen
AUTHORIZATION: edit=yes; commit=yes; push=yes nur Analysebranch; pr=no; local_merge=no; remote_merge=no; tag=no; release=no; deploy=no
FIRST_NON_GREEN_PACKAGE: fruehestes Paket ohne Dirigentenbeleg
```

### 1.3 Verbindliche Worker-Rueckgabe

Jede Kapsel verlangt alle Felder. Fehlende Felder blockieren das Paket.

```text
PACKAGE: exakte Paket-ID
WORKER_AND_MODEL: Workername und gpt-5.6-luna
EFFORT: low, medium oder high mit Eskalationsgrund
AUTHORITATIVE_ROOT: C:\dev\SternenBuergerchen
WORKTREE: exakter Analyseworktree
BRANCH: task/1206-combat-contact-visibility-architecture-analysis
BASE_SHA: 40-stelliger Start-SHA
RESULT_SHA_OR_UNCOMMITTED: 40-stelliger SHA oder UNCOMMITTED
CHANGED_FILES: exakte Liste oder NONE
OUT_OF_SCOPE_FILES_OBSERVED_BUT_UNTOUCHED: exakte Liste oder NONE
TESTS: je Zeile exakter Befehl, Exitcode und wortgetreuer Ergebnis-Marker
EXPECTED_VS_UNEXPECTED_FAILURES: exakte Einordnung
WORKER_GATE: pass, fail oder blocked
BLOCKERS: exakte Liste oder NONE
MANUAL_OR_EXTERNAL_GATES_REMAINING: exakte Liste oder NONE
PROCESSES_STARTED: je Prozess PID, Executable, volle Commandline und Worktreepfad oder NONE
ARTIFACTS_AND_LOGS: exakte Pfade oder NONE
RECOMMENDED_NEXT_ACTION: genau eine begrenzte Aktion
```

### 1.4 Verbindlicher Dirigenten-Gate-Record

```text
PACKAGE: exakte Paket-ID
VERIFIED_RESULT_SHA: 40-stelliger SHA oder UNCOMMITTED
SCOPE_REVIEW: pass oder fail
DIFF_REVIEW: pass oder fail
PARENT_TESTS: je Zeile exakter Befehl, Exitcode und wortgetreuer Marker
FOREIGN_WIP_PRESERVED: yes oder no
WIP_BASELINE_COMPARISON: exakte Status-/Hash-Evidenz
AUTOMATED_GATE: green, red oder blocked
MANUAL_GATE: not-applicable
PACKAGE_STATE: verified-green oder blocked
BLOCKER_AND_CORRECTION_SCOPE: exakte Korrekturkapsel oder NONE
NEXT_PACKAGE_AND_BASE_SHA: naechste Paket-ID und 40-stelliger SHA oder NONE
```

### 1.5 Prozessregel

Kein Paket beendet Prozesse nach Executablename. Vor einem Stop muessen PID,
Parent-PID, Executable, volle Commandline und der normalisierte Analysepfad
zusammenpassen. Fremde oder pfadlose Godot-Prozesse machen eine Messserie
ungueltig, werden aber nicht beendet.

---

## 2. Geplante Dateistruktur und Schnittstellen

### 2.1 Neue Dateien

- `scripts/tests/task_1206_combat_contact_visibility_architecture_analysis.gd`
  enthaelt direkte Vertragspruefungen, das 600-Tick-Orakel und den begrenzten
  16v12-Topologiedump.
- `docs/reports/TASK_1206_COMBAT_CONTACT_VISIBILITY_ARCHITECTURE_ANALYSIS.md`
  enthaelt Umgebung, Query-Matrix, Rohwerte, Deltas, Gate-Tabellen, Reverts und
  genau einen Entscheidungswert.

### 2.2 Bestehende Dateien im maximalen Korridor

- `scripts/mission/combat_visibility_cache.gd`: Modus-T-Aggregate sowie je
  Variante genau ein debug-only Fast-Path-Prototyp.
- `scripts/tests/mission_combat_loop_driver.gd`: Consumer-Tags,
  Environment-Konfiguration und nur fuer Variante C das Contact-Read-Model.
- `scripts/tactical/combat_fire_decision_resolver.gd`: Fire-Pair-Consumer-Tag
  und nur fuer Variante C die exakte gerichtete Read-Model-Pruefung.
- `scripts/tests/run_task_1187_tactical_map_frame_budget.ps1`: feste
  AUS/EIN-Paarfolge, Quiet-Window-Pruefung und AB-JSON-Aggregation.
- `scripts/tests/tactical_map_frame_budget_harness.gd`: nur TASK-1206-Metadaten
  aus den drei Environment-Variablen im bestehenden Report.
- `docs/tasks/TASK_1206_combat_contact_visibility_architecture_analysis.md`:
  Status und Endentscheidung.

### 2.3 Fest definierte Analyse-API

P02 erzeugt diese Namen; spaetere Pakete duerfen sie nicht umbenennen:

```gdscript
func configure_task1206_analysis(variant: String, enabled: bool, topology_enabled: bool) -> void
func get_task1206_analysis_snapshot(include_pair_dump: bool = false) -> Dictionary
func set_task1206_analysis_configuration(variant: String, enabled: bool, topology_enabled: bool) -> void
func get_task1206_visibility_analysis_snapshot(include_pair_dump: bool = false) -> Dictionary
```

Environment-Namen:

```text
STERNENBUERGERCHEN_TASK1206_VARIANT
STERNENBUERGERCHEN_TASK1206_ENABLED
STERNENBUERGERCHEN_TASK1206_TOPOLOGY
```

Variantenwerte:

```text
off
shared_tick_result_contract
cache_internal_structured_reuse
contact_derived_read_model
```

Consumer-Tags:

```text
contact_tracking
fire_pair_search
enemy_security
enemy_team_tactics
other_combat
```

### 2.4 Report-Scope-Mapping fuer Modus P

| Ergebnisname | TASK-1187-JSON-Pfad |
|---|---|
| combat | `scopes."combat.total_tick_usec".p99` |
| fire_decision | `scopes."combat_scope.combat_fire_decision_usec".p99` |
| pair_search | `scopes."combat_scope.fire_find_contact_pair_usec".p99` |
| contact_tracking | `scopes."combat.contact_tracking_usec".p99` |
| enemy_team_tactics | `scopes."combat_scope.enemy_team_tactics_usec".p99` |
| simulation | `scopes."simulation.total_tick_usec".p99` |
| command_queue | `scopes."simulation_scope.command_queue_usec".p99` |

---

### Task 0 (P00): Autoritaet, isolierter Worktree und Baseline

**Files:** Read `AGENTS.md`, alle vorgeschriebenen Kerndokumente, TASK-1206,
Spec und diesen Plan; create in the new branch die drei TASK-1206-Dokumente.

**Interfaces:** Consumes gepushten Planbranch und exakte Integrationsbasis;
produces Analyseworktree, Preflight, WIP-Manifest und Basistests.

**Worker capsule:** Kein Worker. P00 ist Dirigentenarbeit.

- [ ] **Step 1: Skills und alle Instruktionen vollstaendig lesen**

Erforderlich sind `superpowers:using-git-worktrees`,
`orchestrating-serial-luna-releases` samt Referenz und die in `AGENTS.md`
genannten Projektdokumente.

- [ ] **Step 2: Remotes und Basis ohne Checkout verifizieren**

```powershell
$repo = 'C:\dev\SternenBuergerchen'
git -C $repo fetch origin
git -C $repo rev-parse origin/integration/core-foundation
git -C $repo rev-parse origin/task/1206-combat-contact-visibility-analysis-plan
git -C $repo worktree list --porcelain
git -C $repo status --short --branch
```

Expected: Integration exakt `3cae5a216d380b58fef92724540e95fbc49bde7e`;
Plan-SHA 40-stellig; Hauptcheckout nur gelesen.

- [ ] **Step 3: Namenskollisionen pruefen**

```powershell
$analysisBranch = 'task/1206-combat-contact-visibility-architecture-analysis'
$analysisWorktree = 'C:\dev\SternenBuergerchen-worktrees\task-1206-combat-contact-visibility-architecture-analysis'
git -C $repo show-ref --verify --quiet "refs/heads/$analysisBranch"
$branchExists = $LASTEXITCODE -eq 0
$worktreeExists = Test-Path -LiteralPath $analysisWorktree
Write-Output "branch_exists=$branchExists worktree_exists=$worktreeExists"
```

Expected: beide `False`. Sonst Zustand inventarisieren, nichts ueberschreiben
und nur bei belegter Identitaet fortsetzen.

- [ ] **Step 4: Worktree von der exakten Basis anlegen**

```powershell
git -C $repo worktree add -b $analysisBranch $analysisWorktree 3cae5a216d380b58fef92724540e95fbc49bde7e
git -C $analysisWorktree rev-parse HEAD
git -C $analysisWorktree status --short --branch
```

- [ ] **Step 5: Freigegebene Dokumente SHA-sicher uebernehmen**

```powershell
$planWorktree = 'C:\dev\SternenBuergerchen-worktrees\task-1206-combat-contact-visibility-analysis-plan'
$planRevision = (git -C $planWorktree rev-parse HEAD).Trim()
$docPaths = @(
  'docs/tasks/TASK_1206_combat_contact_visibility_architecture_analysis.md',
  'docs/superpowers/specs/2026-09-01-combat-contact-visibility-analysis-design.md',
  'docs/superpowers/plans/2026-09-01-combat-contact-visibility-architecture-analysis.md'
)
git -C $analysisWorktree checkout $planRevision -- $docPaths
git -C $analysisWorktree diff --check
git -C $analysisWorktree status --short
```

- [ ] **Step 6: Dokument-Bootstrap committen und pushen**

```powershell
git -C $analysisWorktree add -- $docPaths
git -C $analysisWorktree diff --cached --name-status
git -C $analysisWorktree commit -m "docs(perf): seed TASK-1206 analysis contract"
git -C $analysisWorktree push -u origin $analysisBranch
```

- [ ] **Step 7: Godot-Import vollenden**

```powershell
godot_console.exe --headless --path $analysisWorktree --import
```

Expected: Scan beendet und die Combat-Audioimporte vorhanden. Bleibt ein
Pluginprozess nach belegtem Scanende offen, nur aufgezeichnete PIDs mit
passender Analyse-Commandline beenden.

- [ ] **Step 8: Basistests ausfuehren**

```powershell
godot_console.exe --headless --path $analysisWorktree --script scripts/tests/task_1197_selected_combat_hotspot.gd
godot_console.exe --headless --path $analysisWorktree --script scripts/tests/task_1196_combat_observed_candidate_index.gd
godot_console.exe --headless --path $analysisWorktree --script scripts/tests/task_1191_shared_combat_visibility_cache.gd
```

Expected: 35/35, 12/12 und 12/12; keine Resource-/Scriptfehler.

- [ ] **Step 9: WIP-Baseline-Manifest erfassen**

```powershell
git -C $analysisWorktree status --porcelain=v1
git -C $analysisWorktree diff
git -C $analysisWorktree diff --cached
Get-FileHash -Algorithm SHA256 -LiteralPath (
  'scripts/mission/combat_visibility_cache.gd',
  'scripts/tests/mission_combat_loop_driver.gd',
  'scripts/tactical/combat_fire_decision_resolver.gd',
  'scripts/tests/run_task_1187_tactical_map_frame_budget.ps1',
  'scripts/tests/tactical_map_frame_budget_harness.gd'
) | Format-Table Path,Hash
```

**Gate P00:** Basis, Plan, Worktree, Dokument-Bootstrap, drei Basistests und
WIP-Manifest sind belegt; `main` blieb unberuehrt.

---

### Task 1 (P01): Erwartet roten Modus-T-Vertrag schreiben

**Files:** Create
`scripts/tests/task_1206_combat_contact_visibility_architecture_analysis.gd`.

**Interfaces:** Consumes bestehende Cache-API; produces RED-Vertrag fuer die
vier Analyse-Methoden, Consumer-Aggregate und Richtungsschutz.

**Worker capsule:**

```text
PACKAGE_ID_AND_GOAL: P01, nur den erwarteten roten TASK-1206-Verifier schreiben
MODEL: gpt-5.6-luna
EFFORT: low
BASE_SHA: verifizierter P00-HEAD
ALLOWED_FILES: scripts/tests/task_1206_combat_contact_visibility_architecture_analysis.gd
FORBIDDEN_SCOPE: Produkt, Harness, Dokumente, Git und externe Aktionen
EXPECTED_GATE: Harness ist nur wegen fehlender TASK-1206-API rot
STOP_CONDITIONS: Basistest rot, andere Datei geaendert oder anderer Fehlergrund
```

- [ ] **Step 1: Testfixture anlegen**

```gdscript
extends SceneTree
const CACHE_SCRIPT: GDScript = preload("res://scripts/mission/combat_visibility_cache.gd")

class RegistryDouble extends RefCounted:
	var revision: int = 7
	func get_revision() -> int: return revision
	func world_to_grid(position: Vector2) -> Vector2i: return Vector2i(roundi(position.x), roundi(position.y))
	func get_height_at_world(_position: Vector2) -> int: return 0

var _passed: int = 0
var _failed: int = 0
func _init() -> void: call_deferred("_run")
func _assert(condition: bool, message: String) -> void:
	if condition: _passed += 1; print("PASS: %s" % message)
	else: _failed += 1; push_error("FAIL: %s" % message)
```

- [ ] **Step 2: Fehlende API und Default-off pruefen**

`_run()` prueft alle vier Namen aus Abschnitt 2.3. Fehlen sie, druckt er
`TASK1206_API_MISSING` und beendet Exit 1 ohne weitere dynamische Calls.

- [ ] **Step 3: Gerichtete Topologiefaelle codieren**

```gdscript
cache.call("begin_tick", 41)
cache.call("has_line_of_sight_between_points", Vector2(10, 10), Vector2(20, 10), -1.0, registry, "alpha", "bravo", compute, "contact_tracking")
cache.call("has_line_of_sight_between_points", Vector2(10, 10), Vector2(20, 10), -1.0, registry, "alpha", "bravo", compute, "fire_pair_search")
cache.call("has_line_of_sight_between_points", Vector2(20, 10), Vector2(10, 10), -1.0, registry, "bravo", "alpha", compute, "enemy_security")
cache.call("has_line_of_sight_between_points", Vector2(10, 10), Vector2(200, 10), 5.0, registry, "alpha", "far", compute, "other_combat")
```

Assertions: zwei exakte A->B-Konsumenten, ein Reverse-Angebot ohne Reuse, ein
Range-Reject ohne Terrain-Aufruf, ein Terrain-Aufruf fuer beide exakten A->B
und korrekte Architekturflags.

- [ ] **Step 4: Gueltigkeitsfaelle codieren**

Sourceposition, Registryrevision und Tickwechsel erzwingen neue Terrain-LoS.
Der normale Snapshot hat keinen Pairdump; expliziter Testdump maximal 32.

- [ ] **Step 5: RED reproduzieren**

```powershell
godot_console.exe --headless --path . --script scripts/tests/task_1206_combat_contact_visibility_architecture_analysis.gd
```

Expected: Exit 1 und `TASK1206_API_MISSING`.

- [ ] **Step 6: Worker liefert vollstaendigen Handoff**

- [ ] **Step 7: Dirigent prueft, committet und pusht RED**

```powershell
git diff --check
git add -- scripts/tests/task_1206_combat_contact_visibility_architecture_analysis.gd
git diff --cached --name-status
git commit -m "test(combat): define TASK-1206 visibility topology contract"
git push
```

**Gate P01:** Erwartetes RED ist aus dem richtigen Grund reproduziert und als
isolierter Testcommit gesichert.

---

### Task 2 (P02): Modus-T-Instrumentierung und Consumer-Tags implementieren

**Files:** Modify `scripts/mission/combat_visibility_cache.gd:12-230`,
`scripts/tests/mission_combat_loop_driver.gd:124-200,230-272,777-805,2820-3050,3212-3230,3419-3448,4083-4089,4494-4499,5008-5014`,
`scripts/tactical/combat_fire_decision_resolver.gd:301-349,556-563`; test the
TASK-1206 verifier.

**Interfaces:** Consumes P01 RED; produces feste API, Modus-T-Aggregate und
alle fuenf Consumer-Tags ohne Gameplaywirkung.

**Worker capsule:**

```text
PACKAGE_ID_AND_GOAL: P02, Modus T minimal bis P01-GREEN implementieren
MODEL: gpt-5.6-luna
EFFORT: low
BASE_SHA: verifizierter P01-HEAD
ALLOWED_FILES: Cache, MissionCombatLoopDriver, CombatFireDecisionResolver und TASK-1206-Verifier
FORBIDDEN_SCOPE: Varianten-Fast-Paths, Runner, Report, SimulationRoot, UI, Audio und Git
EXPECTED_GATE: TASK-1206, TASK-1197, TASK-1196 und TASK-1191 gruen
STOP_CONDITIONS: Orakeldifferenz, Reverse-Reuse oder Analyse im Snapshot
```

- [ ] **Step 1: Cache-Konfiguration und Snapshot implementieren**

```gdscript
const TASK1206_VARIANTS: Array[String] = ["off", "shared_tick_result_contract", "cache_internal_structured_reuse", "contact_derived_read_model"]
const TASK1206_CONSUMERS: Array[String] = ["contact_tracking", "fire_pair_search", "enemy_security", "enemy_team_tactics", "other_combat"]
const TASK1206_PAIR_DUMP_LIMIT: int = 32

func configure_task1206_analysis(variant: String, enabled: bool, topology_enabled: bool) -> void:
	var normalized: String = variant.strip_edges().to_lower()
	_task1206_variant = normalized if TASK1206_VARIANTS.has(normalized) else "off"
	_task1206_enabled = enabled and _task1206_variant != "off"
	_task1206_topology_enabled = topology_enabled and not _task1206_enabled
	_task1206_reset_diagnostics()
```

Der Snapshot gibt Variant, Enabled, Topology, `consumers`, `costs`, `overlap`,
optional maximal 32 Pairrecords und die drei Architekturflags zurueck.
Diese Flags sind exakt `derived_only: true`, `read_only: true` und
`snapshot_serialized: false`.

- [ ] **Step 2: Optionalen Consumer-Parameter rueckwaertskompatibel einfuehren**

An beide `has_line_of_sight`-Methoden kommt als letzter Defaultparameter
`consumer_tag: String = "other_combat"`; bestehende Calls bleiben gueltig.

- [ ] **Step 3: Request-, Range- und Richtungstopologie erfassen**

Nur Modus T erzeugt die gerichtete Signatur aus Tick, IDs, Positionen,
Registry-Identitaet und Revision. Exakter zweiter Consumer erhoeht
`exact_cross_consumer_hit_count`; nur Reverse erhoeht
`reverse_pair_opportunity_count`; Range-Reject wird vor Cachekosten gezaehlt.

- [ ] **Step 4: Kosten pro Consumer erfassen**

Exakte Namen: `signature_key_build`, `cache_lookup`, `entry_write`,
`terrain_los`, jeweils Count und usec. Bestehende TASK-1197-Profiler bleiben
unveraendert.

- [ ] **Step 5: Driver-Konfiguration und Environment-Bridge implementieren**

```gdscript
func set_task1206_analysis_configuration(variant: String, enabled: bool, topology_enabled: bool) -> void:
	var cache = get_node_or_null(combat_visibility_cache_path)
	if cache != null and cache.has_method("configure_task1206_analysis"):
		cache.call("configure_task1206_analysis", variant, enabled, topology_enabled)

func get_task1206_visibility_analysis_snapshot(include_pair_dump: bool = false) -> Dictionary:
	var cache = get_node_or_null(combat_visibility_cache_path)
	if cache == null or not cache.has_method("get_task1206_analysis_snapshot"): return {}
	return Dictionary(cache.call("get_task1206_analysis_snapshot", include_pair_dump)).duplicate(true)
```

- [ ] **Step 6: Sichtaufrufe exakt taggen**

Contact -> `contact_tracking`; Detection/Hold/Readout -> `other_combat`; Resolver
-> `fire_pair_search`; Enemy Watch -> `enemy_security`; Cover-Slot-LoS ->
`enemy_team_tactics`. Reverse bleibt nur Diagnose.

- [ ] **Step 7: TASK-1206 GREEN ausfuehren**

```powershell
godot_console.exe --headless --path . --script scripts/tests/task_1206_combat_contact_visibility_architecture_analysis.gd
```

Expected: `TASK1206_TOPOLOGY_CONTRACT_OK`, null Failures.

- [ ] **Step 8: Direkte Regressionen ausfuehren**

```powershell
godot_console.exe --headless --path . --script scripts/tests/task_1197_selected_combat_hotspot.gd
godot_console.exe --headless --path . --script scripts/tests/task_1196_combat_observed_candidate_index.gd
godot_console.exe --headless --path . --script scripts/tests/task_1191_shared_combat_visibility_cache.gd
```

Expected: 35/35, 12/12, 12/12.

- [ ] **Step 9: Dirigent prueft, committet und pusht**

```powershell
git diff --check
git add -- scripts/mission/combat_visibility_cache.gd scripts/tests/mission_combat_loop_driver.gd scripts/tactical/combat_fire_decision_resolver.gd scripts/tests/task_1206_combat_contact_visibility_architecture_analysis.gd
git diff --cached --name-status
git commit -m "test(perf): expose TASK-1206 visibility topology"
git push
```

**Gate P02:** Modus T ist debug-only, gerichtet, begrenzt und gruen; Default-off
bleibt in allen drei Basistests unveraendert.

---

### Task 3 (P03): 16v12-Topologie messen und Eligibility festschreiben

**Files:** Modify TASK-1206-Verifier und Taskdatei; create
`docs/reports/TASK_1206_COMBAT_CONTACT_VISIBILITY_ARCHITECTURE_ANALYSIS.md`.

**Interfaces:** Consumes P02-Snapshot; produces Topologie-JSON, Query-Matrix und
fuer A/B/C je `eligible` oder `excluded`.

**Worker capsule:**

```text
PACKAGE_ID_AND_GOAL: P03, 16v12-Topologie erfassen und keine Variante implementieren
MODEL: gpt-5.6-luna
EFFORT: low
BASE_SHA: verifizierter P02-HEAD
ALLOWED_FILES: TASK-1206-Verifier, Taskdatei und TASK-1206-Markdownreport
FORBIDDEN_SCOPE: Cache, Driver, Resolver, Performancebehauptung, Variante und Git
EXPECTED_GATE: Exit-0-Topologie-JSON und binare Eligibility je Variante
STOP_CONDITIONS: Pairdump ueber 32, Orakeldifferenz, Resourcefehler oder unbekannter Consumer
```

- [ ] **Step 1: Evidence-Modus in den Verifier aufnehmen**

User-Arg `--task1206-topology-evidence` erstellt die reale 16v12-Fixture,
aktiviert nur Topology, deaktiviert Minimum Spacing, primt identisch und laesst
600 Ticks laufen. Genau eine Zeile wird gedruckt:

```text
TASK1206_TOPOLOGY_JSON={kompaktes gueltiges JSON aus dem tatsaechlichen Lauf}
```

Schema ist `sternenbuergerchen.task1206.visibility_topology.v1`; enthalten sind
Git-SHA, Tickzahl, Aggregate, Pairdumpgroesse und kanonischer Orakelhash.

- [ ] **Step 2: Topologielauf ausfuehren**

```powershell
$env:STERNENBUERGERCHEN_GIT_SHA = (git rev-parse HEAD).Trim()
godot_console.exe --headless --path . --script scripts/tests/task_1206_combat_contact_visibility_architecture_analysis.gd -- --task1206-topology-evidence
```

Expected: Exit 0, eine JSON-Zeile, korrekter SHA, 600 Ticks.

- [ ] **Step 3: Query-Matrix bilden**

Pro Producer/Reuse-Consumer werden Richtung, Cadence, beide Rangevertraege,
exakte Ueberlappung, Reverse-Angebote, Terrainersparnis und Zusatzkosten mit
Rohzaehlern dokumentiert.

- [ ] **Step 4: Eligibility mit festen Formeln entscheiden**

- A: mindestens zwei exakte Konsumenten pro Resultat und
  `exact_cross_consumer_hit_count > 0`.
- B: `exact_cross_consumer_hit_count > 0` und
  `contact_unique_ordered_pair_count / exact_cross_consumer_hit_count <= 4.0`.
- C:
  `exact_contact_producer_fire_probe_count / fire_pair_search_request_count >= 0.80`;
  Nenner null bedeutet `excluded`.
- Reverse-Angebote zaehlen nie als Hit.

- [ ] **Step 5: Report und Taskstatus schreiben**

Reportkopf mit SHA, Hardware, Windows, Godot, Importstatus, Matrix, Formeln und
Eligibility. Taskstatus wird `TOPOLOGY_VERIFIED_MEASUREMENT_PENDING`; keine
Architekturempfehlung.

- [ ] **Step 6: Dirigent reproduziert, prueft, committet und pusht**

```powershell
git diff --check
git add -- scripts/tests/task_1206_combat_contact_visibility_architecture_analysis.gd docs/reports/TASK_1206_COMBAT_CONTACT_VISIBILITY_ARCHITECTURE_ANALYSIS.md docs/tasks/TASK_1206_combat_contact_visibility_architecture_analysis.md
git commit -m "docs(perf): record TASK-1206 visibility topology"
git push
```

**Gate P03:** Topologie und Eligibility aller drei Varianten sind SHA-sicher
belegt; keine Variante wurde implementiert.

---

### Task 4 (P04): Erwartet roten Modus-P-/Runnervertrag schreiben

**Files:** Modify
`scripts/tests/task_1206_combat_contact_visibility_architecture_analysis.gd`.

**Interfaces:** Consumes bestehenden TASK-1187-Runner und Harness; produces RED
fuer Environment-Metadaten, Quiet Window, zwei Smokes, feste 16er-Folge, acht
Paare und sieben Scopeauswertungen.

**Worker capsule:**

```text
PACKAGE_ID_AND_GOAL: P04, nur statischen und schnellen roten Runnervertrag ergaenzen
MODEL: gpt-5.6-luna
EFFORT: low
BASE_SHA: verifizierter P03-HEAD
ALLOWED_FILES: scripts/tests/task_1206_combat_contact_visibility_architecture_analysis.gd
FORBIDDEN_SCOPE: PowerShell, Harness, Produkt, Dokumente und Git
EXPECTED_GATE: RED nur wegen fehlender TASK-1206-Runnerfelder
STOP_CONDITIONS: Topologievertrag rot oder Parser-/Fixturefehler
```

- [ ] **Step 1: Statische Runnervertraege ergaenzen**

Der Verifier liest Runner und Tactical-Map-Harness und verlangt exakt:

```text
Task1206Variant
Task1206Paired
QuietWindowSeconds
STERNENBUERGERCHEN_TASK1206_VARIANT
STERNENBUERGERCHEN_TASK1206_ENABLED
STERNENBUERGERCHEN_TASK1206_TOPOLOGY
TASK_1206_VISIBILITY_AB_JSON=
sternenbuergerchen.task1206.visibility_ab.v1
```

- [ ] **Step 2: Folge, Scopes und Paarzahl statisch pruefen**

Der Test verlangt die literal gespeicherte Folge
`off,on,on,off,on,off,off,on,off,on,on,off,on,off,off,on`, alle sieben
JSON-Pfade aus Abschnitt 2.4 und eine Prüfung auf exakt acht Paare.

- [ ] **Step 3: RED ausfuehren**

```powershell
godot_console.exe --headless --path . --script scripts/tests/task_1206_combat_contact_visibility_architecture_analysis.gd
```

Expected: Exit 1, `TASK1206_PAIRED_RUNNER_CONTRACT_MISSING`; Topologieanteil
bleibt gruen.

- [ ] **Step 4: Worker liefert vollstaendigen Handoff**

- [ ] **Step 5: Dirigent committet und pusht erwartetes RED**

```powershell
git add -- scripts/tests/task_1206_combat_contact_visibility_architecture_analysis.gd
git diff --cached --check
git commit -m "test(perf): define TASK-1206 paired runner contract"
git push
```

**Gate P04:** Runnervertrag ist aus dem geforderten Grund rot; kein Runner oder
Runtimepfad wurde vorgezogen.

---

### Task 5 (P05): Gepaarte TASK-1187-Ausfuehrung und Self-Control implementieren

**Files:** Modify
`scripts/tests/run_task_1187_tactical_map_frame_budget.ps1:1-36`,
`scripts/tests/tactical_map_frame_budget_harness.gd:122-137,266-287` und den
TASK-1206-Verifier.

**Interfaces:** Consumes P04 RED und P02 Environment-Bridge; produces
`TASK_1206_VISIBILITY_AB_JSON` mit 18 Prozessrecords, 16 gewerteten Runs, acht
Paaren und sieben Scopezusammenfassungen.

**Worker capsule:**

```text
PACKAGE_ID_AND_GOAL: P05, Modus-P-Runner minimal bis GREEN und schnelle Self-Control
MODEL: gpt-5.6-luna
EFFORT: low
BASE_SHA: verifizierter P04-HEAD
ALLOWED_FILES: TASK-1187-PowerShell-Runner, Tactical-Map-Harness und TASK-1206-Verifier
FORBIDDEN_SCOPE: Variantenlogik, Produkt-LoS, Reportentscheidung, Releasegate und Git
EXPECTED_GATE: statischer Vertrag gruen; Fast-Self-Control liefert gueltiges AB-JSON
STOP_CONDITIONS: Standard-TASK-1187 bricht, Prozesszahl falsch oder SHA-/JSON-Mismatch
```

- [ ] **Step 1: Rueckwaertskompatible Parameter ergaenzen**

```powershell
[ValidateSet('off','shared_tick_result_contract','cache_internal_structured_reuse','contact_derived_read_model')]
[string]$Task1206Variant = 'off',
[switch]$Task1206Paired,
[ValidateRange(0,60)]
[int]$QuietWindowSeconds = 60,
[switch]$Fast
```

Ohne `-Task1206Paired` bleiben `-ColdRuns`, `-WarmRuns` und der bisherige
Outputvertrag identisch. `-Fast` uebergibt nur `--task1187-fast`.

- [ ] **Step 2: TASK-1206-Metadaten im GDScript-Report ergaenzen**

```gdscript
"task1206": {
	"variant": OS.get_environment("STERNENBUERGERCHEN_TASK1206_VARIANT").strip_edges().to_lower(),
	"enabled": OS.get_environment("STERNENBUERGERCHEN_TASK1206_ENABLED") == "1",
	"topology_enabled": OS.get_environment("STERNENBUERGERCHEN_TASK1206_TOPOLOGY") == "1",
}
```

- [ ] **Step 3: Quiet Window ohne Prozesskill implementieren**

Im Paired-Modus prueft der Runner im Einsekundentakt die konfigurierte Dauer.
Jeder vor dem ersten eigenen Start gefundene Godot-Prozess fuehrt mit PID und
Commandline zu `TASK1206_QUIET_WINDOW_BLOCKED`; kein Prozess wird beendet.

- [ ] **Step 4: Zwei Smokes und feste 16er-Folge implementieren**

Erst ungewertet AUS/EIN, danach die feste Folge. Jeder Lauf ist ein neuer
Godot-Prozess und braucht Exit 0, genau eine TASK-1187-JSON-Zeile, denselben
SHA, `topology_enabled=false` und passende Variant-/Enabled-Metadaten.

- [ ] **Step 5: Paarbildung und Statistik implementieren**

Adjacent Runs bilden acht Paare. Pro Scope: Rohwerte, min/max/Median je Modus,
acht Deltas `(on-off)/off`, Delta-Median und Zahl `on < off`. Missing/null p99
bricht ab. JSON-Kopf:

```powershell
$summary = [ordered]@{
  schema = 'sternenbuergerchen.task1206.visibility_ab.v1'
  git_sha = $gitSha
  variant = $Task1206Variant
  smoke_run_count = 2
  scored_run_count = 16
  pair_count = 8
  sequence = $sequence
  runs = $runs
  scopes = $scopeSummaries
}
```

- [ ] **Step 6: P04-Vertrag GREEN ausfuehren**

```powershell
godot_console.exe --headless --path . --script scripts/tests/task_1206_combat_contact_visibility_architecture_analysis.gd
```

Expected: `TASK1206_PAIRED_RUNNER_CONTRACT_OK`.

- [ ] **Step 7: Schnelle 18-Prozess-Self-Control ausfuehren**

```powershell
pwsh -NoProfile -File scripts/tests/run_task_1187_tactical_map_frame_budget.ps1 -Mode Measure -ColdRuns 0 -WarmRuns 1 -Task1206Variant cache_internal_structured_reuse -Task1206Paired -QuietWindowSeconds 0 -Fast
```

Expected: Exit 0, eine AB-JSON-Zeile, 2 Smokes, 16 scored, 8 Paare, korrekter
SHA und sieben Scopeobjekte. Fast-Werte sind keine Performanceevidenz.

- [ ] **Step 8: Standardrunner regressionspruefen**

```powershell
pwsh -NoProfile -File scripts/tests/run_task_1187_tactical_map_frame_budget.ps1 -Mode Measure -ColdRuns 1 -WarmRuns 0 -Fast -QuietWindowSeconds 0
```

Expected: bisheriger `TASK_1187 PASS`-Marker und eine normale JSON-Zeile.

- [ ] **Step 9: Worker liefert vollstaendigen Handoff**

- [ ] **Step 10: Dirigent prueft, committet und pusht**

```powershell
git diff --check
git add -- scripts/tests/run_task_1187_tactical_map_frame_budget.ps1 scripts/tests/tactical_map_frame_budget_harness.gd scripts/tests/task_1206_combat_contact_visibility_architecture_analysis.gd
git diff --cached --name-status
git commit -m "test(perf): add TASK-1206 paired measurement mode"
git push
```

**Gate P05:** Modus P ist von T getrennt, Standard-TASK-1187 kompatibel und
die schnelle 18-Prozess-Self-Control schema-gruen.

---

### Task 6 (P06): Variante A `SHARED_TICK_RESULT_CONTRACT` isoliert bewerten

**Files:** Modify when eligible `scripts/mission/combat_visibility_cache.gd`
und TASK-1206-Verifier; always modify den TASK-1206-Markdownreport.

**Interfaces:** Consumes P03-Eligibility und P05-Runner; produces A-Orakel,
A-Kosten, gegebenenfalls volle Serie, Gate und normale Reverts.

**Worker capsule:**

```text
PACKAGE_ID_AND_GOAL: P06, nur Variante A prototypisieren und messen oder belegt ausschliessen
MODEL: gpt-5.6-luna
EFFORT: low
BASE_SHA: verifizierter P05-HEAD
ALLOWED_FILES: CombatVisibilityCache, TASK-1206-Verifier und TASK-1206-Markdownreport
FORBIDDEN_SCOPE: Variante B/C, Driver, Resolver, Release, Merge und Git
EXPECTED_GATE: A-Gatezeile vollstaendig; Kandidat danach normal revertiert
STOP_CONDITIONS: A excluded, Orakeldifferenz, Kostengate rot oder Messumgebung ungueltig
```

- [ ] **Step 1: Eligibility lesen**

Ist A `excluded`, keine Produktdatei aendern; exakte P03-Zaehler und
`not-run`-Performancefelder in den Report schreiben, dann Step 11.

- [ ] **Step 2: Erwartet roten A-Vertrag ergaenzen**

Bei A-EIN verlangt der Test eine gecachte Resultat-Entry mit Feldern `tick`,
`source_id`, `target_id`, beiden Positionen, `registry_identity`,
`terrain_revision`, `clear` und den drei Architekturflags. Zwei exakte Calls:
ein Materialisieren, ein `shared_result_reuse`, ein Terrain-LoS. Reverse,
Position, Revision und Tick duerfen nicht treffen.

- [ ] **Step 3: A-RED ausfuehren**

```powershell
godot_console.exe --headless --path . --script scripts/tests/task_1206_combat_contact_visibility_architecture_analysis.gd
```

Expected: `TASK1206_VARIANT_A_MISSING`.

- [ ] **Step 4: Minimalen A-Prototyp implementieren**

Nur bei A-EIN speichert der Cache je voll gueltigem gerichteten Pair ein
Dictionary mit den Vertragsfeldern. Range laeuft davor. Der boolesche API-Return
liest nur `clear`; kein Event/Snapshot erhaelt das Resultat. Zaehler:
`result_materialization_count`, `result_materialization_usec`,
`shared_result_reuse_count`.

- [ ] **Step 5: A-GREEN und Orakel ausfuehren**

```powershell
godot_console.exe --headless --path . --script scripts/tests/task_1206_combat_contact_visibility_architecture_analysis.gd
godot_console.exe --headless --path . --script scripts/tests/task_1197_selected_combat_hotspot.gd
godot_console.exe --headless --path . --script scripts/tests/task_1196_combat_observed_candidate_index.gd
godot_console.exe --headless --path . --script scripts/tests/task_1191_shared_combat_visibility_cache.gd
```

- [ ] **Step 6: Worker liefert Kandidat und Handoff uncommitted**

- [ ] **Step 7: Dirigent committet und pusht A-Kandidaten**

```powershell
git add -- scripts/mission/combat_visibility_cache.gd scripts/tests/task_1206_combat_contact_visibility_architecture_analysis.gd
git commit -m "perf(analysis): prototype shared tick visibility result"
git push
```

- [ ] **Step 8: A-Modus-T-Kostengate ausfuehren**

Topologielauf mit A-EIN wiederholen. Wenn
`result_materialization_usec >= saved_signature_key_usec + saved_terrain_los_usec`,
keine volle Serie; A `fail` wegen Materialisierung.

- [ ] **Step 9: Nur bei gruenem Kostengate volle Serie ausfuehren**

```powershell
pwsh -NoProfile -File scripts/tests/run_task_1187_tactical_map_frame_budget.ps1 -Mode Measure -Task1206Variant shared_tick_result_contract -Task1206Paired -QuietWindowSeconds 60
```

- [ ] **Step 10: A-Gates auswerten**

Report: Rohwerte, Mediane, acht Deltas, Verbesserungszahl und alle Gates.
`pass` verlangt Pair <= -2 Prozent, mindestens 6/8 Verbesserungen, Contact <=
+5 Prozent und ON <= 21.929,25 usec sowie alle anderen Scope-Deltas <= +5
Prozent.

- [ ] **Step 11: Evidenz committen**

```powershell
git add -- docs/reports/TASK_1206_COMBAT_CONTACT_VISIBILITY_ARCHITECTURE_ANALYSIS.md
git commit -m "docs(perf): record TASK-1206 variant A evidence"
git push
```

- [ ] **Step 12: Kandidat normal reverten und verifizieren**

```powershell
$candidate = git log --format=%H --grep='^perf(analysis): prototype shared tick visibility result$' -n 1
git revert --no-edit $candidate
git push
godot_console.exe --headless --path . --script scripts/tests/task_1206_combat_contact_visibility_architecture_analysis.gd
godot_console.exe --headless --path . --script scripts/tests/task_1197_selected_combat_hotspot.gd
git diff --check
```

**Gate P06:** A ist `pass`, `fail` oder `excluded` dokumentiert und vollstaendig
wieder entfernt.

---

### Task 7 (P07): Variante B `CACHE_INTERNAL_STRUCTURED_REUSE` isoliert bewerten

**Files:** Modify when eligible
`scripts/mission/combat_visibility_cache.gd:125-190` und TASK-1206-Verifier;
always modify den TASK-1206-Markdownreport.

**Interfaces:** Consumes die nach P06 wiederhergestellte P05-Basis; produces
zeitnah gepaarte Neubewertung der Zyklus-3-Idee und normale Reverts.

**Worker capsule:**

```text
PACKAGE_ID_AND_GOAL: P07, nur Variante B prototypisieren und messen oder belegt ausschliessen
MODEL: gpt-5.6-luna
EFFORT: low
BASE_SHA: verifizierter P06-Revert-HEAD
ALLOWED_FILES: CombatVisibilityCache, TASK-1206-Verifier und TASK-1206-Markdownreport
FORBIDDEN_SCOPE: Variante A/C, Driver, Resolver, aufgeweichte Gates und Git
EXPECTED_GATE: B-Gatezeile vollstaendig; Kandidat danach normal revertiert
STOP_CONDITIONS: P06 nicht netto null, B excluded, Orakeldifferenz oder ungueltige Serie
```

- [ ] **Step 1: P06-Netto-null und B-Eligibility belegen**

Cache-/Testhashes muessen dem P05-Stand entsprechen. Ist B `excluded`, den
P03-Grund und `not-run` in den Report schreiben, dann Step 10.

- [ ] **Step 2: Erwartet roten B-Vertrag ergaenzen**

Bei B-EIN muss `_cache_key_reuse_by_pair[source][target]` zusaetzlich
`result_ready` und `result` halten. Exakte Folgeabfrage erhoeht
`structured_fast_path_hit_count`; Reverse, Position, Registryrevision und Tick
duerfen nicht treffen.

- [ ] **Step 3: B-RED ausfuehren**

```powershell
godot_console.exe --headless --path . --script scripts/tests/task_1206_combat_contact_visibility_architecture_analysis.gd
```

Expected: `TASK1206_VARIANT_B_MISSING`.

- [ ] **Step 4: Minimalen B-Prototyp implementieren**

Nur hinter B-EIN werden Registry-Identitaet und aktuelle Terrainrevision vor
dem String-Key genau einmal gelesen. Nur vollstaendig gerichtete,
positions-/registry-/revisionsgleiche Entry mit `result_ready=true` liefert das
boolesche Resultat. Sonst laeuft der bisherige Key-/Lookup-/Terrainpfad und
fuellt die Entry. Zaehler: `structured_entry_write_count`,
`structured_fast_path_hit_count`, `structured_validation_miss_count`.

- [ ] **Step 5: B-GREEN und Orakel ausfuehren**

```powershell
godot_console.exe --headless --path . --script scripts/tests/task_1206_combat_contact_visibility_architecture_analysis.gd
godot_console.exe --headless --path . --script scripts/tests/task_1197_selected_combat_hotspot.gd
godot_console.exe --headless --path . --script scripts/tests/task_1196_combat_observed_candidate_index.gd
godot_console.exe --headless --path . --script scripts/tests/task_1191_shared_combat_visibility_cache.gd
```

- [ ] **Step 6: Worker liefert Kandidat und Handoff uncommitted**

- [ ] **Step 7: Dirigent committet und pusht B-Kandidaten**

```powershell
git add -- scripts/mission/combat_visibility_cache.gd scripts/tests/task_1206_combat_contact_visibility_architecture_analysis.gd
git commit -m "perf(analysis): prototype cache-internal visibility result reuse"
git push
```

- [ ] **Step 8: Volle B-A/B-Serie ausfuehren**

```powershell
pwsh -NoProfile -File scripts/tests/run_task_1187_tactical_map_frame_budget.ps1 -Mode Measure -Task1206Variant cache_internal_structured_reuse -Task1206Paired -QuietWindowSeconds 60
```

Expected: gueltiges 8-Paar-JSON. Historische Zyklus-3-Werte werden separat als
nicht gepaart dargestellt.

- [ ] **Step 9: B-Gates auswerten**

Dieselben sieben Gates wie P06. Contact ist rot, wenn gepaart > +5 Prozent
oder ON-Median > 21.929,25 usec; Pairgewinn ueberschreibt das nicht.

- [ ] **Step 10: Evidenz committen**

```powershell
git add -- docs/reports/TASK_1206_COMBAT_CONTACT_VISIBILITY_ARCHITECTURE_ANALYSIS.md
git commit -m "docs(perf): record TASK-1206 variant B evidence"
git push
```

- [ ] **Step 11: B normal reverten und pruefen**

```powershell
$candidate = git log --format=%H --grep='^perf(analysis): prototype cache-internal visibility result reuse$' -n 1
git revert --no-edit $candidate
git push
godot_console.exe --headless --path . --script scripts/tests/task_1206_combat_contact_visibility_architecture_analysis.gd
godot_console.exe --headless --path . --script scripts/tests/task_1197_selected_combat_hotspot.gd
git diff --check
```

**Gate P07:** B ist vollstaendig gemessen oder formal ausgeschlossen und
netto entfernt; historische Werte wurden nicht als zeitgleiche Kontrolle
ausgegeben.

---

### Task 8 (P08): Variante C `CONTACT_DERIVED_READ_MODEL` isoliert bewerten

**Files:** Modify when eligible `scripts/tests/mission_combat_loop_driver.gd`,
`scripts/tactical/combat_fire_decision_resolver.gd` und TASK-1206-Verifier;
always modify den TASK-1206-Markdownreport.

**Interfaces:** Consumes P03-C-Eligibility und P07-Revertbasis; produces einen
gerichteten Contact-Read-Model-Prototyp, Missgruende, gegebenenfalls Serie und
normale Reverts.

**Worker capsule:**

```text
PACKAGE_ID_AND_GOAL: P08, nur Variante C prototypisieren und messen oder mit 80-Prozent-Regel ausschliessen
MODEL: gpt-5.6-luna
EFFORT: low
BASE_SHA: verifizierter P07-Revert-HEAD
ALLOWED_FILES: MissionCombatLoopDriver, CombatFireDecisionResolver, TASK-1206-Verifier und Report
FORBIDDEN_SCOPE: Reverse-Reuse, Cachevariante A/B, ContactTracker-Persistenz, Snapshot und Git
EXPECTED_GATE: C-Gatezeile vollstaendig; Kandidat danach normal revertiert
STOP_CONDITIONS: P07 nicht netto null, C unter 80 Prozent, Reverse noetig oder Orakeldifferenz
```

- [ ] **Step 1: C-Eligibility belegen**

Ist die P03-Quote < 0,80 oder Nenner null, keine Produktdatei aendern; exakte
Zaehler und `not-run` dokumentieren, dann Step 11.

- [ ] **Step 2: Erwartet roten C-Vertrag schreiben**

Der Test verlangt bei C-EIN den Context
`task1206_contact_visibility_read_model`. Jeder Probe liefert genau einen Grund:

```text
hit
missing_attacker_entry
missing_target_entry
tick_mismatch
source_position_mismatch
target_position_mismatch
registry_mismatch
revision_mismatch
range_insufficient
direction_mismatch
```

Range wird im Fire-Resolver selbst geprueft; Reverse bleibt Miss.

- [ ] **Step 3: C-RED ausfuehren**

```powershell
godot_console.exe --headless --path . --script scripts/tests/task_1206_combat_contact_visibility_architecture_analysis.gd
```

Expected: `TASK1206_VARIANT_C_MISSING`.

- [ ] **Step 4: Driver-Read-Model minimal implementieren**

Bei C-EIN leert Contact Tracking die Map je Tick und speichert nur nach
erfolgreicher eigener Range- und Terrain-LoS-Pruefung:

```gdscript
{
	"tick": _current_tick,
	"source_id": attacker_id,
	"target_id": enemy_unit_id,
	"source_position": friendly.global_position,
	"target_position": enemy.global_position,
	"registry_identity": registry.get_instance_id(),
	"terrain_revision": registry.get_revision(),
	"terrain_clear": true,
	"producer_range": contact_los_range,
}
```

Die Map geht nur kopiert/read-only in den Decision-Context, nie in
ContactTracker oder Snapshot.

- [ ] **Step 5: Resolver-Validierung minimal implementieren**

`is_target_attackable()` berechnet zuerst effektive Fire-Range. Danach darf nur
eine exakt gerichtete, tick-/positions-/registry-/revisionsgleiche Entry
Terrain-LoS ersetzen. Jeder Miss nutzt den bestehenden Sichtservice; kein
Reverse-Fallback.

- [ ] **Step 6: C-GREEN und Orakel ausfuehren**

```powershell
godot_console.exe --headless --path . --script scripts/tests/task_1206_combat_contact_visibility_architecture_analysis.gd
godot_console.exe --headless --path . --script scripts/tests/task_1197_selected_combat_hotspot.gd
godot_console.exe --headless --path . --script scripts/tests/task_1196_combat_observed_candidate_index.gd
godot_console.exe --headless --path . --script scripts/tests/task_1191_shared_combat_visibility_cache.gd
```

Expected: alle gruen; C-Zaehlersumme entspricht Probezahl.

- [ ] **Step 7: Worker liefert Kandidat und Handoff uncommitted**

- [ ] **Step 8: Dirigent committet und pusht C-Kandidaten**

```powershell
git add -- scripts/tests/mission_combat_loop_driver.gd scripts/tactical/combat_fire_decision_resolver.gd scripts/tests/task_1206_combat_contact_visibility_architecture_analysis.gd
git commit -m "perf(analysis): prototype contact-derived visibility read model"
git push
```

- [ ] **Step 9: C-A/B-Serie ausfuehren**

```powershell
pwsh -NoProfile -File scripts/tests/run_task_1187_tactical_map_frame_budget.ps1 -Mode Measure -Task1206Variant contact_derived_read_model -Task1206Paired -QuietWindowSeconds 60
```

Gueltig nur bei gemessenem Hit-Anteil >= 0,80; sonst C `fail`, auch wenn ein
Scope schneller ist.

- [ ] **Step 10: C-Gates und Missgruende dokumentieren**

Rohwerte, acht Deltas, sieben Performancegates und alle Missgruende in den
Report. `direction_mismatch` ist kein Hit.

- [ ] **Step 11: Evidenz committen**

```powershell
git add -- docs/reports/TASK_1206_COMBAT_CONTACT_VISIBILITY_ARCHITECTURE_ANALYSIS.md
git commit -m "docs(perf): record TASK-1206 variant C evidence"
git push
```

- [ ] **Step 12: C normal reverten und pruefen**

```powershell
$candidate = git log --format=%H --grep='^perf(analysis): prototype contact-derived visibility read model$' -n 1
git revert --no-edit $candidate
git push
godot_console.exe --headless --path . --script scripts/tests/task_1206_combat_contact_visibility_architecture_analysis.gd
godot_console.exe --headless --path . --script scripts/tests/task_1197_selected_combat_hotspot.gd
git diff --check
```

**Gate P08:** C ist mit 80-Prozent-, Richtung-, Range- und Performancebeleg
entschieden und netto entfernt.

---

### Task 9 (P09): Binare Architekturentscheidung und Abschluss

**Files:** Modify TASK-1206-Markdownreport und
`docs/tasks/TASK_1206_combat_contact_visibility_architecture_analysis.md`.

**Interfaces:** Consumes P00-P08 und P05-Instrumentierungsbasis; produces genau
einen Entscheidungswert und einen sauberen gepushten Analysebranch.

**Worker capsule:**

```text
PACKAGE_ID_AND_GOAL: P09, Evidenz konsolidieren und keine Runtime aendern
MODEL: gpt-5.6-luna
EFFORT: low
BASE_SHA: verifizierter P08-Revert-HEAD
ALLOWED_FILES: TASK-1206-Markdownreport und TASK-1206-Taskdatei
FORBIDDEN_SCOPE: Runtime, Tests, Budgets, Integration, main, PR, Tag, Release, Deploy und Git
EXPECTED_GATE: genau ein erlaubter Entscheidungswert und vollstaendige Restblocker
STOP_CONDITIONS: Variantendiff uebrig, Rohdaten fehlen, Mathematik uneindeutig oder Orakel rot
```

- [ ] **Step 1: Netto-null aller Varianten belegen**

Cache-, Driver-, Resolver- und Testhashes gegen P05. Unterschiede duerfen nur
P02/P03/P05 sein; A/B/C muessen null sein.

- [ ] **Step 2: Gewinner deterministisch bestimmen**

Nur `pass`-Varianten. Bei mehreren: niedrigster Combat-ON-Median, danach
niedrigster Contact-ON-Median, kleinere oeffentliche API, weniger langlebige
Datenstrukturen. Ohne Pass zwingend `NO_SAFE_FOURTH_FIX`.

- [ ] **Step 3: Genau einen Entscheidungswert schreiben**

```text
SHARED_TICK_RESULT_CONTRACT
CACHE_INTERNAL_STRUCTURED_REUSE
CONTACT_DERIVED_READ_MODEL
NO_SAFE_FOURTH_FIX
```

Report und Task markieren genau einen davon als finale Entscheidung; keine
Mischvariante.

- [ ] **Step 4: Releasegrenzen sichtbar halten**

Weiter offen nennen: Combat-/Simulation-/Command-Budgets, FoW-Varianz, Dynamic
Overlay soweit offen, echte 128x128-Full-HD-Manuellevidenz und alle
Integration-/main-/Release-Autorisierungen.

- [ ] **Step 5: Vollstaendige direkte Regressionen ausfuehren**

```powershell
godot_console.exe --headless --path . --script scripts/tests/task_1206_combat_contact_visibility_architecture_analysis.gd
godot_console.exe --headless --path . --script scripts/tests/task_1197_selected_combat_hotspot.gd
godot_console.exe --headless --path . --script scripts/tests/task_1196_combat_observed_candidate_index.gd
godot_console.exe --headless --path . --script scripts/tests/task_1191_shared_combat_visibility_cache.gd
godot_console.exe --headless --path . --script scripts/tests/task_162_combat_authority_contract_verifier.gd
godot_console.exe --headless --path . --script scripts/tests/task_208_enemy_team_tactics_playability_smoke.gd
godot_console.exe --headless --path . --script scripts/tests/task_218_simulation_combat_ai_tick_budget_pass.gd
```

Expected: TASK-1206 gruen; 35/35, 12/12, 12/12, 23/23, 57/57, 81/81.

- [ ] **Step 6: Default-off TASK-1187-Kontrolle ausfuehren**

```powershell
pwsh -NoProfile -File scripts/tests/run_task_1187_tactical_map_frame_budget.ps1 -Mode Measure -ColdRuns 1 -WarmRuns 0 -Task1206Variant off -QuietWindowSeconds 60
```

Expected: Exit 0, SHA korrekt, Variant off, Topology false. Budgetrot ist kein
Releasepass.

- [ ] **Step 7: Entscheidungskonsistenz und Diff pruefen**

```powershell
rg -n "SHARED_TICK_RESULT_CONTRACT|CACHE_INTERNAL_STRUCTURED_REUSE|CONTACT_DERIVED_READ_MODEL|NO_SAFE_FOURTH_FIX" docs/reports/TASK_1206_COMBAT_CONTACT_VISIBILITY_ARCHITECTURE_ANALYSIS.md docs/tasks/TASK_1206_combat_contact_visibility_architecture_analysis.md
git diff --check
git status --short
```

- [ ] **Step 8: Worker liefert vollstaendigen Handoff**

- [ ] **Step 9: Dirigent committet und pusht Abschluss**

```powershell
git add -- docs/reports/TASK_1206_COMBAT_CONTACT_VISIBILITY_ARCHITECTURE_ANALYSIS.md docs/tasks/TASK_1206_combat_contact_visibility_architecture_analysis.md
git diff --cached --name-status
git diff --cached --check
git commit -m "docs(perf): conclude TASK-1206 visibility architecture analysis"
git push
```

- [ ] **Step 10: Remote- und Schutzstatus final verifizieren**

```powershell
git rev-parse HEAD
git rev-parse '@{u}'
git status --porcelain=v1
git rev-parse integration/core-foundation
git rev-parse origin/integration/core-foundation
git rev-parse main
git rev-parse origin/main
git log --oneline --decorate -n 20
```

Expected: Analyse-HEAD gleich Remote, sauber; Integration weiter
`3cae5a216d380b58fef92724540e95fbc49bde7e`; `main` unveraendert; keine
Merge-/Tag-/Releaseaktion.

**Gate P09:** TASK-1206 endet mit genau einer zulaessigen Entscheidung,
sauberem gepushten Analysebranch und sichtbaren Releaseblockern.

---

## 3. Fehler- und Korrekturschleifen

### 3.1 Erwartetes RED versus unerwartetes Rot

- P01/P04 sind nur gruen, wenn der benannte fehlende Vertrag rot ist.
- Parser-, Import-, Leak-, Fixture-, SHA- oder Resourcefehler sind unerwartet
  und aktivieren vor GREEN eine begrenzte Debugkapsel.
- Kein unerwartetes Rot wird durch Entfernen einer Assertion oder Aendern einer
  Schwelle repariert.

### 3.2 Messserien

- Ein ungueltiges Paar wird genau einmal in derselben Reihenfolge wiederholt.
- Zwei oder mehr ungueltige Paare verwerfen die ganze 16er-Serie; nach neuem
  Quiet Window startet sie von vorn.
- Kein guenstiger Wert ersetzt still einen verworfenen Wert.
- Widersprechen zwei gueltige Serien in Vorzeichen oder Gate, darf der Dirigent
  Luna auf `medium` eskalieren und genau eine dritte Serie anordnen.
- `high` ist nur bei fortbestehender Autoritaets-/Richtungs-/Snapshotkollision
  erlaubt. Performancevarianz allein ist kein High-Grund.

### 3.3 Scopeverletzung

Eine nicht erlaubte Datei, ein fehlender Handoffwert oder unbekannter Prozess
blockiert das Paket. Der Dirigent sichert den Diff, verwirft nichts breit und
gibt nur eine begrenzte Korrekturkapsel aus.

### 3.4 Varianten-Reverts

Jede Variante wird mit `git revert` ihres exakten Kandidatencommits entfernt.
Kein Reset, Checkout-Restore, Stash oder manuelles Rueckkopieren. Erst nach
Hashvergleich startet die naechste Variante.

---

## 4. Planvalidierung vor Ausfuehrung

```powershell
$plan = 'docs/superpowers/plans/2026-09-01-combat-contact-visibility-architecture-analysis.md'
$text = Get-Content -Raw -LiteralPath $plan
$packages = [regex]::Matches($text, '^### Task [0-9]+ \(P[0-9]{2}\):', 'Multiline').Count
$gates = [regex]::Matches($text, '^\*\*Gate P[0-9]{2}:', 'Multiline').Count
$checkboxes = [regex]::Matches($text, '^- \[ \]', 'Multiline').Count
$fences = [regex]::Matches($text, '^```', 'Multiline').Count
$redFlags = @('T' + 'BD', 'T' + 'ODO', 'implement ' + 'later', 'add ' + 'appropriate', 'similar ' + 'to task')
$forbidden = 0
foreach ($redFlag in $redFlags) {
  $forbidden += [regex]::Matches($text, [regex]::Escape($redFlag), 'IgnoreCase').Count
}
$required = @(
  'gpt-5.6-luna',
  'EFFORT: low',
  'Niemals `xhigh`, `max` oder `ultra`',
  'TASK_1206_VISIBILITY_AB_JSON=',
  'NO_SAFE_FOURTH_FIX',
  'QuietWindowSeconds 60',
  'off,on,on,off,on,off,off,on,off,on,on,off,on,off,off,on',
  'mindestens 6/8 Verbesserungen',
  '21.929,25 usec',
  'git revert',
  'integration/core-foundation'
)
if ($packages -ne 10) { throw "PACKAGE_COUNT=$packages" }
if ($gates -ne 10) { throw "GATE_COUNT=$gates" }
if ($checkboxes -lt 70) { throw "CHECKBOX_COUNT=$checkboxes" }
if (($fences % 2) -ne 0) { throw "UNBALANCED_FENCES=$fences" }
if ($forbidden -ne 0) { throw "FORBIDDEN_MARKERS=$forbidden" }
foreach ($needle in $required) {
  if (-not $text.Contains($needle)) { throw "MISSING_REQUIRED_TOKEN=$needle" }
}
git diff --check
if ($LASTEXITCODE -ne 0) { throw 'DIFF_CHECK_FAILED' }
Write-Output "PLAN_VALIDATION_OK packages=$packages gates=$gates checkboxes=$checkboxes fences=$fences"
```

Geplante Create-Pfade duerfen fehlen. Alle bestehenden Runtime-, Harness-,
Spec- und Taskpfade muessen vorhanden sein.

---

## 5. Copy-ready Startprompt fuer einen neuen Dirigenten-Task

```text
Führe den Plan
C:\dev\SternenBuergerchen-worktrees\task-1206-combat-contact-visibility-analysis-plan\docs\superpowers\plans\2026-09-01-combat-contact-visibility-architecture-analysis.md
streng seriell ab P00 aus.

Lies zuerst AGENTS.md, alle dort geforderten Kerndokumente, die freigegebene
TASK-1206-Spec, superpowers:using-git-worktrees,
orchestrating-serial-luna-releases samt Orchestrierungsvertrag und den gesamten
Plan. Rekonstruiere nach jedem Kontextverlust Preflight und Ledger.

Nutze je Worker-Kapsel gpt-5.6-luna mit low. Medium ist nur nach reproduzierter
Evidenzkollision, high nur bei belegter Autoritäts-, Snapshot- oder gerichteter
Sichtsemantik-Kollision erlaubt. Niemals xhigh, max oder ultra. Starte nie zwei
Worker oder Varianten parallel.

Du bist autorisiert, ausschließlich den Analysebranch/-worktree anzulegen,
dort die im Paket erlaubten Dateien zu editieren, nach eigener Verifikation zu
committen und den Analysebranch ohne Force zu pushen. Nicht autorisiert sind
PR, Merge nach integration/core-foundation, jede Änderung an main, Remote-
Merge, Tag, Release oder Deployment.

Führe A, B und C nur nach Eligibility aus, miss AUS/EIN im selben Build in der
festgelegten 8-Paar-Folge und entferne jeden Kandidaten danach mit normalen
Revert-Commits. Ende mit genau einer zulässigen Architekturentscheidung oder
NO_SAFE_FOURTH_FIX. Ein Architekturpass ist keine Releasefreigabe.
```

## 6. Execution handoff

Nach validierter Planlieferung bestehen zwei Ausfuehrungsformen:

1. **Neuer serieller Dirigenten-Task (empfohlen):** Startprompt aus Abschnitt 5;
   Luna bearbeitet je Paket eine Kapsel, der Dirigent verifiziert dazwischen.
2. **Inline-Ausfuehrung:** In diesem Task mit `superpowers:executing-plans`;
   dieselben Paket-, Worker- und Dirigentengates bleiben bindend.

Keine Form wird durch die reine Planfreigabe automatisch gestartet.
