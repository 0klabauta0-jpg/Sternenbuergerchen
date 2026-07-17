# Project Vision And Status Workbench Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build one self-contained German HTML workbench that explains the Spielidee and game vision, the evidenced project state, the architecture in plain language, the remaining mandatory and optional work, and the bounded advantages of GPT-5.6.

**Architecture:** The report is a single offline HTML document under `docs/reports/`. Semantic HTML and inline CSS render the briefing; a small inline JavaScript module owns only report navigation, filters, editable workbench state, local persistence, import, and export. Runtime and gameplay files are not touched.

**Tech Stack:** HTML5, CSS, browser-native JavaScript, Local Storage, Blob downloads, File System Access API as an optional fallback, Playwright browser smoke.

## Global Constraints

- Derive the report from `docs/reports/_html_workbench_template.html` and `docs/dev/html_report_workbench_contract.md`.
- Use `schema = sternenbuergerchen.html_workbench.v1` and `report_id = project_vision_status_gpt56_2026_07_17`.
- Work directly through `file://` with no webfonts, external scripts, external images, server, or build step.
- Keep gameplay truth in the runtime; report persistence may store only local decisions and notes.
- Distinguish implemented and verified, implemented in the working state, partial/further work, and vision/options.
- State the fresh TASK_1179 caveat: the isolated rerun reached 18 early checks but then stopped before the final Objective/Debrief assertions because of UID/autoload and freed-instance errors.

---

### Task 1: Briefing Content And Evidence Structure

**Files:**
- Create: `docs/reports/STERNENBUERGERCHEN_SPIELIDEE_PROJEKTSTAND_GPT56_2026-07-17.html`

**Interfaces:**
- Consumes: project brief, architecture contract, TASK roadmap, TASK_1179, player-flow reports, and the HTML workbench contract.
- Produces: semantic sections with the IDs `vision`, `journey`, `status`, `architecture`, `future`, `gpt56`, and `workbench`.

- [ ] **Step 1: Run the missing-artifact check**

Run:
```powershell
if (Test-Path 'docs/reports/STERNENBUERGERCHEN_SPIELIDEE_PROJEKTSTAND_GPT56_2026-07-17.html') { exit 0 } else { Write-Error 'TASK_1181 report missing'; exit 1 }
```
Expected: exit 1 with `TASK_1181 report missing`.

- [ ] **Step 2: Create the semantic report shell and authored content**

Create a UTF-8 HTML5 document with this exact top-level contract:
```html
<body data-report-id="project_vision_status_gpt56_2026_07_17"
      data-report-schema="sternenbuergerchen.html_workbench.v1">
  <header id="top">...</header>
  <nav aria-label="Briefing-Bereiche">...</nav>
  <main>
    <section id="vision">...</section>
    <section id="journey">...</section>
    <section id="status">...</section>
    <section id="architecture">...</section>
    <section id="future">...</section>
    <section id="gpt56">...</section>
    <section id="workbench">...</section>
  </main>
  <footer>...</footer>
</body>
```

The authored copy must explicitly contain `Commander`, `Fire Team Leader (FTL)`, `SimulationRoot`, `EventRouter`, `RuntimeLeader`, `UnitRegistry`, `FTLRegistry`, `UpdateManager`, `Homebase`, `Dropship`, `Objective`, `Debrief`, `GPT-5.6`, `TASK_1179`, `18 frühe Checks`, `Muss`, and `Kann`.

- [ ] **Step 3: Add the tactical visual system**

Implement inline CSS variables and responsive layout with these fixed color roles:
```css
:root {
  --bg: #07100f;
  --surface: #101a18;
  --surface-raised: #15231f;
  --line: #2a423b;
  --text: #edf4ef;
  --muted: #9aada5;
  --signal: #80e6b0;
  --amber: #f2ba61;
  --danger: #ff7f6e;
}
```

Use broad briefing bands, a seven-stage journey ribbon, compact evidence badges, a left-to-right architecture flow that wraps on narrow screens, `:focus-visible` states, and a mobile breakpoint no wider than `760px`.

- [ ] **Step 4: Run the structural content check**

Run:
```powershell
$path = 'docs/reports/STERNENBUERGERCHEN_SPIELIDEE_PROJEKTSTAND_GPT56_2026-07-17.html'
$html = Get-Content -Raw -Encoding UTF8 -LiteralPath $path
$required = @('id="vision"','id="journey"','id="status"','id="architecture"','id="future"','id="gpt56"','id="workbench"','SimulationRoot','EventRouter','GPT-5.6','TASK_1179','18 frühe Checks')
$missing = @($required | Where-Object { -not $html.Contains($_) })
if ($missing.Count) { throw "Missing: $($missing -join ', ')" }
```
Expected: exit 0 and no missing markers.

### Task 2: Offline Workbench Behavior

**Files:**
- Modify: `docs/reports/STERNENBUERGERCHEN_SPIELIDEE_PROJEKTSTAND_GPT56_2026-07-17.html`

**Interfaces:**
- Consumes: controls carrying `data-export-key`, notes carrying `data-note-key`, decisions carrying `data-choice-group`, and evidence cards carrying `data-evidence`.
- Produces: `buildExport(): object`, `applyImport(payload: object): void`, `saveLocalState(): void`, and `applyEvidenceFilters(): void`.

- [ ] **Step 1: Add exportable controls and stable keys**

Add checkbox/select/textarea/contenteditable controls with stable prefixes:
```text
status.*
priorities.*
decisions.*
notes.*
filters.*
```

Include visible buttons with the exact labels `JSON exportieren`, `JSON kopieren`, `JSON importieren`, `Arbeitsstand speichern`, and `Zurücksetzen`.

- [ ] **Step 2: Implement state, filters, import, and export**

The script must use these exact constants and output shape:
```js
const schema = "sternenbuergerchen.html_workbench.v1";
const reportId = "project_vision_status_gpt56_2026_07_17";
const storageKey = `${schema}:${reportId}`;
const payload = {
  schema,
  report_id: reportId,
  title: document.title,
  exported_at: new Date().toISOString(),
  controls: {},
  notes: {},
  active_choices: {},
  computed: {},
  metadata: {}
};
```

Reject imports whose `schema` or `report_id` differs. Save only workbench fields to Local Storage. Evidence filters must hide/show cards without changing their content or evidence level.

- [ ] **Step 3: Run the static workbench contract check**

Run:
```powershell
$html = Get-Content -Raw -Encoding UTF8 -LiteralPath 'docs/reports/STERNENBUERGERCHEN_SPIELIDEE_PROJEKTSTAND_GPT56_2026-07-17.html'
$required = @('sternenbuergerchen.html_workbench.v1','project_vision_status_gpt56_2026_07_17','JSON exportieren','JSON kopieren','JSON importieren','localStorage','buildExport','applyImport','data-export-key','data-note-key','data-choice-group','data-evidence')
$missing = @($required | Where-Object { -not $html.Contains($_) })
if ($missing.Count) { throw "Missing workbench contract: $($missing -join ', ')" }
```
Expected: exit 0.

### Task 3: Status, Browser Verification, And Delivery

**Files:**
- Modify: `docs/IMPLEMENTATION_STATUS.md`
- Verify: `docs/reports/STERNENBUERGERCHEN_SPIELIDEE_PROJEKTSTAND_GPT56_2026-07-17.html`

**Interfaces:**
- Consumes: completed report and fresh test evidence.
- Produces: one TASK_1181 completion section and verified desktop/mobile screenshots.

- [ ] **Step 1: Append TASK_1181 status**

Append a section containing `Status`, `Stand`, `Verifikation`, `Risiken / offene Punkte`, and `Naechster Schritt`. State that the report changes no runtime truth and that the fresh TASK_1179 rerun exposed a verification caveat.

- [ ] **Step 2: Run a Playwright file-URL smoke**

Open the report through its absolute `file:///` URL. Verify section navigation, evidence filters, one priority choice, a note round trip through Local Storage, JSON export shape, rejected mismatched import, and reset. Expected: all assertions pass.

- [ ] **Step 3: Capture and inspect desktop and mobile renders**

Capture `1440x1000` and `390x844` full-page screenshots. Confirm no horizontal overflow, overlapping sticky controls, clipped journey steps, unreadable architecture nodes, or first-viewport status ambiguity.

- [ ] **Step 4: Run final hygiene checks**

Run:
```powershell
git diff --check
git status --short
git diff -- docs/reports/STERNENBUERGERCHEN_SPIELIDEE_PROJEKTSTAND_GPT56_2026-07-17.html docs/IMPLEMENTATION_STATUS.md docs/superpowers/plans/2026-07-17-project-vision-status-workbench.md
```
Expected: `git diff --check` exits 0 and only TASK_1181-owned files are changed.

- [ ] **Step 5: Commit and push the task branch**

Run:
```powershell
git add docs/reports/STERNENBUERGERCHEN_SPIELIDEE_PROJEKTSTAND_GPT56_2026-07-17.html docs/IMPLEMENTATION_STATUS.md docs/superpowers/plans/2026-07-17-project-vision-status-workbench.md
git commit -m "Add project vision status workbench"
git push -u origin task/task-1181-project-vision-status-workbench
```
Expected: commit succeeds and the remote branch advances.

## Plan Self-Review

- The plan covers every TASK_1181 acceptance criterion and adds no runtime or gameplay scope.
- All file paths, IDs, schema values, visible button labels, evidence caveats, commands, and expected results are explicit.
- The JavaScript names and export fields are consistent between the content and browser-verification tasks.
