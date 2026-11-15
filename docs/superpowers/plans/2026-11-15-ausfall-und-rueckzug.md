# Ausfall und Rückzug in der Kampagne (Paket 3a) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** In der Kampagne stehen Ausgefallene nicht mehr von selbst auf; nach dem Einsatz sind sie verwundet (drei Stufen, Ausfallzeit) oder tot (zurückgelassen), und ein Rückzug lässt den Auftrag offen.

**Architecture:** Ein reiner Regel-Resolver (`campaign_casualty_rules.gd`) entscheidet aus dem Missionsergebnis je Person „unversehrt / verwundet / tot“. Der Combat-Driver bekommt einen Schalter, den `meta_layer_flow.gd` nur für Kampagneneinsätze setzt. `meta_layer_flow.gd` wendet das Ergebnis genau einmal auf den Kader an; ein kleiner Zeit-Owner (`personnel_recovery_runtime.gd`) zählt die Ausfallzeit. Skirmish und Mehrspieler laufen unverändert über den bisherigen Respawn-Pfad.

**Tech Stack:** Godot 4.6.2, GDScript, Tests als `extends SceneTree`-Skripte unter `scripts/tests/`.

**Spec:** `docs/tasks/SPIELRUNDE_AUSFALL_RUECKZUG_2026_11_15.md` (Regeln 1–8). Leitbild: Projektdokument `claude/Spielvision.md`, Abschnitt 4.

## Global Constraints

- Arbeitsordner ist ausschließlich `C:\dev\SternenBuergerchen-worktrees\spielrunde-ausfall-20261115` (Branch `task/spielrunde-ausfall-rueckzug-20261115`). Nie im Hauptordner `C:\dev\SternenBuergerchen` ändern, nie auf `main` committen, nicht pushen, nicht mergen.
- Die Regeln gelten nur, wenn `MetaLayerFlow.is_campaign_start()` wahr ist. Ohne den Schalter muss sich jeder bestehende Pfad Bit für Bit wie vorher verhalten.
- Gameplay-Wahrheit liegt bei `SimulationRoot`, Driver, Runtime-Ownern und `SingleplayerCampaignState`. UI liest und sendet Commands, speichert nichts Eigenes (AGENTS.md).
- Nicht anfassen: `scripts/core/simulation_root.gd`, `scripts/meta/explorable_homebase.gd`, `scripts/meta/homebase_operations_presenter.gd`, `scripts/terrain/*`, `scripts/ui/mission_a5_*.gd`, `shaders/`, Assets. Im Missionscontroller (`scripts/tests/mission_tactical_sandbox_controller.gd`) ausschließlich die in Aufgabe 4 genannten zwei Funktionen, und `_apply_fireteam_mini_member_portrait_strip` auf keinen Fall.
- Balancewerte stehen in `data/singleplayer/casualty_rules.json`, nie als Zahl im Code.
- Alte Spielstände müssen nicht lesbar bleiben; neu erzeugte Stände müssen speichern und laden.
- Texte für Spieler auf Deutsch mit Umlauten.
- Tests: immer nur ein Godot-Prozess, ohne Fenster, niedrige Priorität, mit Wegwerf-Profil. Aufruf aus dem Arbeitsordner:
  `$env:APPDATA = "$env:TEMP\sb_spielrunde_profil"; godot_console.exe --headless --path . -s scripts/tests/<name>.gd`
  Vor dem ersten Lauf einmal `godot_console.exe --headless --path . --import`. Nie fremde Godot-Prozesse beenden.
- Jede Aufgabe endet mit einem Commit auf dem Task-Branch. Commit-Nachrichten auf Deutsch, eine Zeile, plus die im Auftrag genannten Attributionszeilen.

## Review Focus

1. **Missionsergebnis kommt mehrfach an.** `meta_layer_flow.gd` stellt ein wartendes Kampagnenergebnis alle 0,25 s erneut zu. Erwartung: Verluste, Tote und Rückzugszähler werden genau einmal angewendet. Test in Aufgabe 5.
2. **Der erste Truppführer (Kaderplatz 0) stirbt, andere leben.** Erwartung: Ein anderer Truppführer rückt auf Platz 0, der Checkpoint bleibt gültig; gibt es keinen, ist es ein Totalverlust ohne Tote. Test in Aufgabe 6.
3. **Speichern, Spiel beenden, fortsetzen.** Erwartung: Verwundete bleiben verwundet mit Restzeit, Tote bleiben weg, niemand taucht doppelt auf. Test in Aufgabe 6 und 7.
4. **Sanitäter richtet jemanden in der Versorgungsfrist auf.** Erwartung: Person kämpft weiter und ist danach nur leicht verwundet. Test in Aufgabe 2.
5. **Skirmish und Mehrspieler.** Erwartung: Respawn nach 30 s wie bisher, kein neues Feld im Mehrspieler-Snapshot. Test in Aufgabe 2.

---

### Task 1: Regeln als Daten und reiner Resolver

**Files:**
- Create: `data/singleplayer/casualty_rules.json`
- Create: `scripts/core/campaign_casualty_rules.gd`
- Test: `scripts/tests/campaign_casualty_rules_verifier.gd`

**Interfaces:**
- Produces (alle `static`, Skript `extends RefCounted`, ohne `class_name`, Aufruf über `preload`):
  - `load_rules(path: String = "res://data/singleplayer/casualty_rules.json") -> Dictionary`
  - `classify_unit(team_state: Dictionary, mission_outcome: String) -> Dictionary` → `{"unit_id": String, "outcome": "unharmed"|"wounded"|"dead", "severity": ""|"light"|"medium"|"severe"}`
  - `resolve_mission(team_states: Array, mission_outcome: String, roster_units: Array, pilot_unit_id: String, rules: Dictionary) -> Dictionary` → `{"total_loss": bool, "total_loss_reason": String, "casualties": Array, "fatality_unit_ids": PackedStringArray}`
  - `build_recovery_state(severity: String, rules: Dictionary) -> Dictionary` → `{"state": "wounded", "severity": severity, "seconds_total": float, "seconds_remaining": float, "source": "campaign_casualty"}`
- Eingabefelder je `team_state`: `unit_id`, `vital_state` (`fit`/`down`/`bleedout`/`respawning`), `health_points`, `was_downed` (bool), `near_ship` (bool), `aboard` (bool). `mission_outcome` ist `won`, `aborted` oder `lost`.

- [ ] **Step 1: Datendatei anlegen**

```json
{
  "schema_version": 1,
  "balance_status": "initial_values_not_final",
  "down_revive_window_seconds": 60.0,
  "recovery_radius_world": 72.0,
  "recovery_seconds": { "light": 180.0, "medium": 900.0, "severe": 2400.0 }
}
```

- [ ] **Step 2: Fehlschlagenden Test schreiben** (`campaign_casualty_rules_verifier.gd`, Aufbau wie `scripts/tests/air_defense_engagement_verifier.gd`: `check(ok, label)`, Schlusszeile `CAMPAIGN_CASUALTY_RULES passed=%d failed=%d`, `quit(1 if failed else 0)`)

```gdscript
const R = preload("res://scripts/core/campaign_casualty_rules.gd")
func ts(id: String, vital: String, was_downed := false, near := false, aboard := false) -> Dictionary:
	return {"unit_id": id, "vital_state": vital, "health_points": 0 if vital != "fit" else 100, "was_downed": was_downed, "near_ship": near, "aboard": aboard}
func unit(id: String, role: String, leadership := 0.0, piloting := 0.0) -> Dictionary:
	return {"unit_id": id, "roster_role_category": role, "skill_values": {"leadership": leadership}, "dropship_piloting": piloting}
func _run() -> void:
	var rules: Dictionary = R.load_rules()
	check(float(rules.down_revive_window_seconds) == 60.0 and float(rules.recovery_seconds.medium) == 900.0, "rules load from data file")
	check(R.classify_unit(ts("a", "fit"), "won").outcome == "unharmed", "fit and never down is unharmed")
	var light: Dictionary = R.classify_unit(ts("a", "fit", true), "aborted")
	check(light.outcome == "wounded" and light.severity == "light", "revived in the field is lightly wounded")
	var medium: Dictionary = R.classify_unit(ts("a", "down"), "won")
	check(medium.outcome == "wounded" and medium.severity == "medium", "down at a won mission is recovered, medium")
	var severe: Dictionary = R.classify_unit(ts("a", "bleedout", true, true), "aborted")
	check(severe.outcome == "wounded" and severe.severity == "severe", "critical near the ship on retreat is recovered, severe")
	check(R.classify_unit(ts("a", "down", true, false, true), "lost").severity == "medium", "aboard counts as recovered")
	check(R.classify_unit(ts("a", "down"), "aborted").outcome == "dead", "down and left behind on retreat is dead")
	check(R.classify_unit(ts("a", "bleedout"), "lost").outcome == "dead", "critical and left behind on defeat is dead")
	var roster: Array = [unit("lead", "operator", 0.6), unit("pilot", "pilot", 0.0, 0.7), unit("two", "operator", 0.4), unit("three", "operator", 0.0)]
	var normal: Dictionary = R.resolve_mission([ts("lead", "fit"), ts("two", "down"), ts("pilot", "fit", false, true, true)], "aborted", roster, "pilot", rules)
	check(not normal.total_loss and Array(normal.fatality_unit_ids) == ["two"], "one left behind dies, mission is no total loss")
	var pilot_down: Dictionary = R.resolve_mission([ts("lead", "fit"), ts("pilot", "down")], "won", roster, "pilot", rules)
	check(pilot_down.total_loss and pilot_down.total_loss_reason == "pilot_down" and pilot_down.fatality_unit_ids.is_empty(), "pilot down is a total loss without deaths")
	var all_down: Dictionary = R.resolve_mission([ts("lead", "down"), ts("two", "bleedout"), ts("pilot", "fit", false, true, true)], "lost", roster, "pilot", rules)
	check(all_down.total_loss and all_down.total_loss_reason == "ground_team_down", "whole ground team down is a total loss")
	var no_leader: Dictionary = R.resolve_mission([ts("lead", "down"), ts("two", "down"), ts("three", "fit"), ts("pilot", "fit", false, true, true)], "aborted", roster, "pilot", rules)
	check(no_leader.total_loss and no_leader.total_loss_reason == "no_leader_left", "deaths that leave no leader are a total loss")
	var state: Dictionary = R.build_recovery_state("severe", rules)
	check(state.state == "wounded" and float(state.seconds_remaining) == 2400.0 and float(state.seconds_total) == 2400.0, "recovery state carries the configured time")
```

- [ ] **Step 3: Test laufen lassen, er muss scheitern** (Skript `campaign_casualty_rules.gd` fehlt).

- [ ] **Step 4: Resolver schreiben.** Regeln:
  - `classify_unit`: `fit` ohne `was_downed` → unharmed; `fit` mit `was_downed` → light. Nicht `fit` (oder `health_points <= 0`): geborgen, wenn `mission_outcome == "won"` oder `near_ship` oder `aboard`; geborgen und `vital_state == "bleedout"` → severe, sonst medium; nicht geborgen → dead. `respawning` zählt wie `bleedout`.
  - `resolve_mission`, Reihenfolge der Totalverlust-Prüfung: (1) Pilot nicht `fit` → `pilot_down`; (2) kein `team_state` außer dem Piloten ist `fit` → `ground_team_down`; (3) nach Abzug der Toten enthält `roster_units` keine Person mit `roster_role_category == "operator"` und Führung > 0 (`skill_leadership`, sonst `skill_values.leadership`) → `no_leader_left`; (4) kein Pilot (`dropship_piloting > 0`) übrig → `no_pilot_left`; (5) weniger als 2 Personen übrig → `roster_too_small`. Bei Totalverlust: `casualties` und `fatality_unit_ids` leer.
  - `casualties` enthält nur Einträge mit `outcome != "unharmed"`.

- [ ] **Step 5: Test laufen lassen:** `CAMPAIGN_CASUALTY_RULES passed=13 failed=0`.

- [ ] **Step 6: Commit** (`git add data/singleplayer/casualty_rules.json scripts/core/campaign_casualty_rules.gd scripts/tests/campaign_casualty_rules_verifier.gd`).

### Task 2: Combat-Driver: Schalter, kein Respawn, Versorgungsfrist

**Files:**
- Modify: `scripts/tests/mission_combat_loop_driver.gd` (Konstante Z. 47, `_queue_bleedout_for_downed_units` Z. 1819, `_has_down_state_linger_elapsed` Z. 1860, `_request_respawn_for_unit` Z. 1872, `_on_unit_vital_status_changed` Z. 3809, `_build_team_states` Z. 3323)
- Test: `scripts/tests/campaign_casualty_driver_verifier.gd`

**Interfaces:**
- Produces am Driver:
  - `@export var campaign_casualty_rules_enabled: bool = false`
  - `@export var down_revive_window_seconds: float = 3.0` (ersetzt im Kampagnenfall `DOWN_STATE_VISIBLE_MIN_SECONDS`)
  - `func get_casualty_flags() -> Dictionary` → `{unit_id: {"was_downed": bool}}` für eigene Einheiten
  - `_build_team_states` liefert je Einheit zusätzlich `"was_downed": bool`

- [ ] **Step 1: Zuerst klären und im Commit-Text festhalten:** Greift der Respawn eigener Einheiten heute auf Hex-Karten überhaupt? (`SimulationRoot._apply_respawn_effect` Z. 7589 leitet auf `_apply_hex_respawn_effect` um, `begin_hex_respawn` Z. 2964 hat keinen Aufrufer.) Nur lesen, `simulation_root.gd` nicht ändern.

- [ ] **Step 2: Fehlschlagenden Test schreiben.** Vorlage für den Aufbau (Driver plus echte `TestUnit`, ohne Meta-Ebene): `scripts/tests/campaign_guard_vital_gate_verifier.gd`. Prüfungen, Schlusszeile `CAMPAIGN_CASUALTY_DRIVER passed=%d failed=%d`:
  - Schalter aus: eigene Einheit auf 0 HP → nach Ablauf von 3 s Zustand `bleedout`, `RespawnManager` hat einen Respawn für sie angenommen („skirmish still respawns“).
  - Schalter an, `down_revive_window_seconds = 60.0`: eigene Einheit auf 0 HP → nach simulierten 5 s weiterhin `down`; `RespawnManager` hat keinen Respawn („no respawn in campaign“).
  - Schalter an: `apply_heal` auf die liegende Einheit innerhalb der Frist → Zustand `fit`, `get_casualty_flags()[id].was_downed == true` („medic revive inside the window, flagged“).
  - Schalter an, Frist auf 0.0 gesetzt: Einheit wird `bleedout`, bleibt `bleedout`, kein Respawn; `_build_team_states` enthält `was_downed: true`.
  - Schalter an: gegnerische Einheit auf 0 HP respawnt wie bisher (Gegner sind nicht Teil dieses Pakets).
  - Die Zeit im Test über die vorhandene Uhr des Drivers steuern (`_down_state_started_msec_by_unit_id` zurückdatieren), nicht echt warten.

- [ ] **Step 3: Test muss scheitern.**

- [ ] **Step 4: Umsetzen.**
  - `_request_respawn_for_unit`: bei `campaign_casualty_rules_enabled and unit_team_id == friendly_team_id` sofort zurück.
  - `_has_down_state_linger_elapsed`: Schwelle ist `down_revive_window_seconds`, wenn der Schalter an ist, sonst `DOWN_STATE_VISIBLE_MIN_SECONDS`.
  - `_on_unit_vital_status_changed`: bei neuem Zustand `down` die `unit_id` in `_was_downed_unit_ids` merken (nur eigene Einheiten, nur bei Schalter an).
  - Kein neues Feld in Mehrspieler-Snapshots.

- [ ] **Step 5: Test grün, dazu Regression:** `task_1069_station_route_evac_abort_outcome.gd`, `medic_support_verifier.gd`, `task_513_mission_combat_resolution_boundary.gd`, `campaign_guard_vital_gate_verifier.gd` müssen dieselben Zahlen liefern wie vor der Änderung (vorher einmal laufen lassen und notieren).

- [ ] **Step 6: Commit.**

### Task 3: Missionsaufbau und Ergebnis in der Meta-Ebene

**Files:**
- Modify: `scripts/meta/meta_layer_flow.gd` (`_configure_mission_instance` Z. 4326, Block `combat_driver` ab Z. 4446; `_build_mission_result` Z. 4588 ff.)
- Test: `scripts/tests/campaign_casualty_result_verifier.gd`

**Interfaces:**
- Consumes: Task 1 `load_rules`; Task 2 `campaign_casualty_rules_enabled`, `down_revive_window_seconds`, `get_casualty_flags()`; vorhanden: `TacticalController.get_campaign_ground_ship_access(craft_id) -> Dictionary` (`ok`, `position`), Meta `dropship_embarked` an der Einheit.
- Produces: Jeder Eintrag in `mission_result.team_states` trägt in der Kampagne zusätzlich `was_downed`, `near_ship`, `aboard` (alle bool). Außerhalb der Kampagne bleiben die Einträge unverändert.

- [ ] **Step 1: Fehlschlagenden Test schreiben.** Aufbau wie `scripts/tests/campaign_casualty_debrief_retry_test.gd` (Kampagnenstart über `game_start_contract.request_start(self, "campaign", "new")`, echte Meta-Szene, echter Einsatz). Prüfungen, Schlusszeile `CAMPAIGN_CASUALTY_RESULT passed=%d failed=%d`:
  - Nach Missionsstart in der Kampagne: `CombatLoopDriver.campaign_casualty_rules_enabled == true` und `down_revive_window_seconds == 60.0`.
  - Nach Missionsstart in Skirmish (zweiter Lauf mit `"skirmish"`): Schalter `false`.
  - `_build_mission_result` für einen Kampagneneinsatz, in dem eine Bodenperson auf 0 HP gesetzt wurde und 100 Einheiten vom Schiff entfernt liegt: ihr Eintrag hat `was_downed == true`, `near_ship == false`, `aboard == false`; eine Person, die 40 Einheiten entfernt liegt, hat `near_ship == true`; der Pilot im Schiff hat `aboard == true`.

- [ ] **Step 2: Test muss scheitern.**

- [ ] **Step 3: Umsetzen.**
  - In `_configure_mission_instance`: `combat_driver.set("campaign_casualty_rules_enabled", is_campaign_start() and not preview_mode)` und die Frist aus den Regeln.
  - In `_build_mission_result` (nur `is_campaign_start()`): `was_downed` aus `get_casualty_flags()`; `aboard` aus Meta `dropship_embarked`; `near_ship` = Abstand der Einheit zum Punkt aus `get_campaign_ground_ship_access(craft_id)` ≤ `recovery_radius_world`. Die Position der Einheit aus derselben Quelle lesen wie `request_campaign_crew_boarding` (auf Hex-Karten der Hex-Zustand, sonst `global_position`). Ist kein Schiff gelandet (`ok == false`), gilt `near_ship = false`.

- [ ] **Step 4: Test grün. Step 5: Commit.**

### Task 4: Einschiffen mit Ausgefallenen (geteilte Datei)

**Vor Beginn:** Projektdokument `claude/Abstimmung-Bedienung-und-Grafik.md` lesen. Steht dort, dass ein anderer Strang gerade `request_campaign_crew_boarding`, `get_campaign_pilot_flight_guard` oder das Aufsitzen (L03) bearbeitet, diese Aufgabe NICHT beginnen, sondern melden. Sonst die beiden Funktionen dort unter „Aktuell in Arbeit“ eintragen lassen (der Hauptchat trägt ein).

**Files:**
- Modify: `scripts/tests/mission_tactical_sandbox_controller.gd`, nur `request_campaign_crew_boarding` (Z. 14042) und `get_campaign_pilot_flight_guard` (Z. 13775)
- Test: `scripts/tests/campaign_casualty_boarding_verifier.gd`

**Interfaces:**
- Consumes: Task 2 Schalter am Driver (`get_node_or_null("../CombatLoopDriver")`).
- Produces: `request_campaign_crew_boarding(...)` gibt bei Schalter an zusätzlich `"casualty_unit_ids": PackedStringArray` zurück (eigene Besatzung des Schiffs, die nicht `fit` ist). Rückgabegründe `pilot_unavailable` und `crew_unavailable` bleiben erhalten, bedeuten aber bei Schalter an: Pilot nicht `fit` bzw. keine einzige Bodenperson `fit`.

- [ ] **Step 1: Fehlschlagenden Test schreiben** (echter Kampagneneinsatz wie Task 3). Prüfungen, Schlusszeile `CAMPAIGN_CASUALTY_BOARDING passed=%d failed=%d`:
  - Zwei Bodenpersonen am Schiff, eine davon auf 0 HP: `request_campaign_crew_boarding(craft)` → `ok == true`, die einsatzfähige Person ist danach an Bord, `casualty_unit_ids == [id der Ausgefallenen]`. (Heute: `crew_unavailable`.)
  - Danach `get_campaign_pilot_flight_guard(craft).ok == true` (Ausgefallene zählen nicht als fehlende Besatzung).
  - Alle Bodenpersonen auf 0 HP: `ok == false`, `reason == "crew_unavailable"`.
  - Pilot auf 0 HP: `reason == "pilot_unavailable"`.
  - Schalter aus (Skirmish-/Altpfad): unverändertes Verhalten, eine Person auf 0 HP → `crew_unavailable`.
  - Eine einsatzfähige Person, die nicht am Schiff ist, blockiert weiterhin mit `crew_not_at_ship`.

- [ ] **Step 2: Test muss scheitern. Step 3: Umsetzen** (in der Schleife über `relevant_crew`: bei Schalter an Personen mit `get_vital_state() != "fit"` überspringen und sammeln, statt abzulehnen). **Step 4: Test grün, dazu** `playtest_20261110_extraction_loop.gd`, `playtest_20261110_extraction_feedback_verifier.gd`, `campaign_legacy_satellite_boarding_verifier.gd` mit denselben Zahlen wie vorher. **Step 5: Commit.**

### Task 5: Verluste genau einmal anwenden

**Files:**
- Modify: `scripts/meta/meta_layer_flow.gd` (`_on_mission_combat_resolved` Z. 4507, `_apply_mission_progression_to_roster` Z. 4726)
- Modify: `scripts/tests/campaign_casualty_debrief_retry_test.gd` (prüft heute „Ausfall → Niederlage“; gilt künftig nur noch für Totalverlust)
- Test: `scripts/tests/campaign_casualty_apply_verifier.gd`

**Interfaces:**
- Consumes: Task 1 `resolve_mission`, `build_recovery_state`; Task 3 Felder in `team_states`; Task 4 Rückgabe des Einschiffens.
- Produces im Missionsergebnis (nur Kampagne): `"casualties": Array` (Einträge aus Task 1 plus `display_name`), `"fatality_unit_ids": PackedStringArray`, `"casualty_total_loss": bool`. Am Kader: verwundete Personen haben `availability_status = "wounded"`, `recovery_state` aus `build_recovery_state`, `status_text = "wounded"`.
- Produces: `func _apply_campaign_casualties(mission_result: Dictionary) -> Dictionary` (gibt das angereicherte Ergebnis zurück).

- [ ] **Step 1: Fehlschlagenden Test schreiben.** Prüfungen, Schlusszeile `CAMPAIGN_CASUALTY_APPLY passed=%d failed=%d`:
  - Sieg mit einer liegenden Bodenperson: Ergebnis bleibt `victory`, `campaign_checkpoint_retry_required` fehlt, Auftrag wird abgeschlossen bzw. `pending_upload`; die Person hat `availability_status == "wounded"` und `recovery_state.severity == "medium"`, `seconds_remaining == 900.0`.
  - Rückzug (`aborted`, `evacuation`) mit einer liegenden Person außerhalb des Radius: `fatality_unit_ids == [id]`.
  - Pilot liegt: `casualty_total_loss == true`, Ergebnis `defeat` mit `campaign_checkpoint_retry_required == true` wie bisher, niemand ist verwundet oder tot.
  - Dasselbe Ergebnis wird ein zweites und drittes Mal an `_on_mission_combat_resolved` übergeben (wie der 0,25-s-Wiederholer): `seconds_remaining` wurde nicht erneut gesetzt, `fatality_unit_ids` nicht doppelt verarbeitet.
  - Eine vom Sanitäter aufgerichtete, am Ende einsatzfähige Person: `severity == "light"`, `seconds_remaining == 180.0`.
  - In Skirmish: kein Feld `casualties`, `availability_status` wie bisher (`recovering` aus `mission_progression_resolver.gd`).

- [ ] **Step 2: Test muss scheitern.**

- [ ] **Step 3: Umsetzen.**
  - In `_on_mission_combat_resolved` (Kampagne): `pilot_unavailable` / `crew_unavailable` vom Einschiffen bleiben der Totalverlust-Pfad wie heute. Bei `ok`: Ergebnis mit `_build_mission_result` bauen, `resolve_mission` aufrufen; `total_loss` → denselben Pfad wie heute `failed_extraction` gehen.
  - `_apply_campaign_casualties` nach `_apply_mission_progression_to_roster` aufrufen, damit die Stufe den dort gesetzten Status `recovering` überschreibt. `mission_progression_resolver.gd` bleibt unverändert.
  - Einmaligkeit: an der Stelle absichern, an der heute schon verhindert wird, dass ein wartendes Ergebnis Belohnung oder Fortschritt doppelt bucht; keinen zweiten Merker daneben erfinden, wenn der vorhandene genügt.
  - Tote werden in dieser Aufgabe nur gemeldet (`fatality_unit_ids`); das Entfernen folgt in Task 6.

- [ ] **Step 4: Test grün, `campaign_casualty_debrief_retry_test.gd` angepasst und grün. Step 5: Commit.**

### Task 6: Tote aus dem Kader nehmen, Nachrücken, Gefallenenliste

**Files:**
- Modify: `scripts/meta/meta_layer_flow.gd` (neu `_remove_campaign_fatalities`; Vorbild `remove_skirmish_person` Z. 8749)
- Modify: `scripts/meta/campaign_checkpoint_store.gd` (`validate_payload`: optionales Feld `fallen`)
- Modify: die Stelle, die den Checkpoint-Payload baut und wieder einliest (`singleplayer_runtime_adapter.gd`, um Z. 1716; genaue Funktion per `git grep -n "base_personnel" scripts/meta/singleplayer_runtime_adapter.gd` bestimmen)
- Test: `scripts/tests/campaign_casualty_roster_verifier.gd`

**Interfaces:**
- Consumes: Task 5 `fatality_unit_ids`; vorhanden: `BasePersonnelRuntime.remove_person(unit_id)` (`scripts/core/base_personnel_runtime.gd:501`), `PersonnelLoadoutState.remove_unit(unit_id)` (`scripts/core/personnel_loadout_state.gd:27`).
- Produces: `func _remove_campaign_fatalities(unit_ids: PackedStringArray, mission_result: Dictionary) -> void`; Kampagnen-Checkpoint mit optionalem `"fallen": Array` aus `{"unit_id", "display_name", "job_id", "location_id"}`.

- [ ] **Step 1: Fehlschlagenden Test schreiben.** Kader mit vier Personen (Truppführer A auf Platz 0, Pilot auf Platz 1, Truppführer B, Schütze C). Prüfungen, Schlusszeile `CAMPAIGN_CASUALTY_ROSTER passed=%d failed=%d`:
  - C stirbt: C fehlt in `_all_team_units`, in der Basis-Personalliste, in `staged_unit_ids`, in jeder `fireteam_definitions[].unit_ids` und in `member_loadouts` des Schiffs; `campaign_checkpoint_store.validate_payload(...)` des neu gebauten Stands ist `ok`.
  - A (Platz 0) stirbt, B lebt: B steht danach auf Platz 0, der Pilot auf Platz 1, `validate_payload` ist `ok`. War A `lead_unit_id` eines Trupps, ist der Lead jetzt ein lebendes Mitglied dieses Trupps oder der Trupp ist aufgelöst, wenn er leer ist.
  - Gegenstände, die die tote Person trug, liegen nicht mehr im Spiel (sie bleiben am Ort zurück; kein Übertrag ins Basislager).
  - `fallen` enthält genau einen Eintrag je Toter mit Name und Auftrag; `validate_payload` lehnt `fallen` ab, wenn es kein Array aus Dictionaries ist.
  - Checkpoint speichern, Meta-Szene neu aufbauen, fortsetzen: die Tote ist weiterhin weg, `fallen` ist erhalten, niemand ist doppelt.

- [ ] **Step 2: Test muss scheitern. Step 3: Umsetzen** (`_remove_campaign_fatalities` am Ende von `_apply_campaign_casualties` aufrufen; Nachrücken: erste lebende Person mit `roster_role_category == "operator"` und Führung > 0 an Platz 0 tauschen). **Step 4: Test grün, dazu** `campaign_checkpoint_run_id_verifier.gd` und `campaign_save_menu_routing_verifier.gd` mit denselben Zahlen wie vorher. **Step 5: Commit.**

### Task 7: Ausfallzeit zählen und Einsatzsperre

**Files:**
- Create: `scripts/core/personnel_recovery_runtime.gd`
- Modify: `scripts/meta/meta_layer_flow.gd` (`_process` Z. 419)
- Modify: `scripts/core/base_personnel_runtime.gd` (`_board_team` Z. 971 und der Einzelpersonen-Einstieg daneben)
- Modify: `scripts/meta/singleplayer_runtime_adapter.gd` (`authorize_departure`)
- Test: `scripts/tests/campaign_casualty_recovery_verifier.gd`

**Interfaces:**
- Consumes: Task 5 `recovery_state` am Kader.
- Produces in `personnel_recovery_runtime.gd` (alle `static`, `extends RefCounted`, ohne `class_name`):
  - `is_wounded(unit: Dictionary) -> bool` (`availability_status == "wounded"` und `recovery_state.seconds_remaining > 0`)
  - `advance(units: Array, delta_seconds: float) -> Dictionary` → `{"units": Array, "changed": bool, "recovered_unit_ids": PackedStringArray}`; bei Restzeit ≤ 0: `availability_status = "active"`, `recovery_state = {}`, `status_text = ""`
  - `describe(unit: Dictionary) -> String` → z. B. `"Verwundet (mittel), noch 12:30"`; Stufennamen `leicht`, `mittel`, `schwer`; Zeit als `m:ss`
- Produces in `BasePersonnelRuntime`: `func set_unavailable_unit_reasons(reasons: Dictionary) -> void` (`{unit_id: Meldung}`); Einschiffen einer dort genannten Person wird abgelehnt mit `{"ok": false, "reason": "unit_wounded", "message": <Meldung>}`, ohne etwas zu verändern.
- Produces im Adapter: `authorize_departure(craft_id)` lehnt mit `reason == "unit_wounded"` und der Meldung ab, solange eine verwundete Person an Bord dieses Schiffs oder für es eingeteilt ist.

- [ ] **Step 1: Fehlschlagenden Test schreiben.** Prüfungen, Schlusszeile `CAMPAIGN_CASUALTY_RECOVERY passed=%d failed=%d`:
  - Rein: `advance([wounded(900)], 60.0)` → `seconds_remaining == 840.0`, `changed`; `advance([wounded(30)], 60.0)` → `availability_status == "active"`, `recovery_state.is_empty()`, `recovered_unit_ids == [id]`; eine `active`-Person bleibt unberührt und `changed == false`.
  - Rein: `describe` für mittel mit 750 s Rest → `"Verwundet (mittel), noch 12:30"`.
  - Echte Meta-Szene, Kampagne: mittlere Verwundung setzen, 5 s Prozesszeit laufen lassen → Restzeit um 4 bis 6 s gesunken (Zählung läuft in Echtzeit, auch ohne offene Basisansicht).
  - Einschiffen der Verwundeten an der Basis → `reason == "unit_wounded"`, Meldung enthält ihren Namen; Position und Status der Person unverändert.
  - Verwundete ist nach der Heimkehr noch an Bord: `authorize_departure(craft)` → `reason == "unit_wounded"`; nach dem Absetzen der Person ist dieser Sperrgrund weg.
  - Restzeit auf 0 laufen lassen → Einschiffen erlaubt.
  - Checkpoint speichern, Szene neu aufbauen, fortsetzen: `seconds_remaining` ist der gespeicherte Wert (± 2 s).
  - In Skirmish zählt nichts und nichts wird gesperrt.

- [ ] **Step 2: Test muss scheitern. Step 3: Umsetzen.** In `_process` das echte Delta aufsummieren und je volle Sekunde `advance` auf `_all_team_units` anwenden (nur Kampagne, nur wenn jemand verwundet ist); bei `changed` `_replace_roster_units` und `set_unavailable_unit_reasons` neu füttern. **Step 4: Test grün. Step 5: Commit.**

### Task 8: Rückzug lässt den Auftrag offen

**Files:**
- Modify: `scripts/core/singleplayer_campaign_state.gd` (`_fail` Z. 285, `_retry_failed` Z. 306, `export_state` Z. 318, `_validate_saved_state`)
- Modify: `scripts/meta/singleplayer_runtime_adapter.gd` (`record_mission_result` Z. 982; neu `reopen_retreated_jobs`)
- Modify: `scripts/meta/meta_layer_flow.gd` (Stelle, an der nach der Heimkehr des Schiffs der Basis-Checkpoint geschrieben wird)
- Test: `scripts/tests/campaign_retreat_keeps_job_open_verifier.gd`

**Interfaces:**
- Produces im Kampagnenstand: Job-Einträge tragen `retreat_count: int` (Standard 0) und `reopen_at_home: bool`; beide überstehen `export_state` → `restore_state`.
- Produces im Adapter: `func reopen_retreated_jobs() -> Dictionary` → `{"ok": true, "reopened_job_ids": PackedStringArray}`; setzt Aufträge mit `reopen_at_home` auf `accepted`, sobald `_retry_failed_home_gate` (Z. 1027) es erlaubt; mehrfacher Aufruf ändert nichts weiter.

- [ ] **Step 1: Fehlschlagenden Test schreiben** (Aufbau wie `scripts/tests/campaign_retry_boundary_test.gd`). Prüfungen, Schlusszeile `CAMPAIGN_RETREAT failed=%d`:
  - Ergebnis `{"result": "aborted", "win_condition_type": "evacuation"}` für den aktiven Auftrag, Schiff noch am Einsatzort: Status `failed`, `retreat_count == 1`, `reopen_at_home == true`; die Abflugbindung des Schiffs besteht noch und `authorize_return(craft).ok == true`.
  - Schiff zu Hause, `reopen_retreated_jobs()`: Status `accepted`, `reopen_at_home == false`, Bindung gelöscht, `reopened_job_ids == ["satellite_recovery"]`; ein zweiter Aufruf liefert eine leere Liste.
  - Der Auftrag lässt sich danach ohne `Erneut annehmen` wieder als Ziel wählen und anfliegen; ein zweiter Rückzug ergibt `retreat_count == 2`.
  - `abandon_job` und eine Niederlage (`defeat`) verhalten sich wie bisher: `failed`, `retreat_count` unverändert, Wiederannahme nur über `accept_job` zu Hause.
  - `export_state()` → `restore_state()` erhält `retreat_count`.

- [ ] **Step 2: Test muss scheitern. Step 3: Umsetzen.** `reopen_retreated_jobs()` unmittelbar vor dem Schreiben des Basis-Checkpoints nach der Heimkehr aufrufen, damit der gespeicherte Stand den offenen Auftrag enthält. **Step 4: Test grün, `campaign_retry_boundary_test.gd` unverändert grün. Step 5: Commit.**

### Task 9: Anzeige

**Files:**
- Modify: `scripts/meta/debrief_screen.gd` (Abbruchtext Z. 704–721, Personenzeilen um Z. 657 und 732)
- Modify: `scripts/meta/character_sheet_formatter.gd` (`format_status_text`)
- Modify: `scripts/meta/homebase_screen.gd` (Statuszeile der Personenkarte, Z. 8203)
- Modify: `scripts/meta/singleplayer_job_board_presenter.gd`
- Test: `scripts/tests/campaign_casualty_display_verifier.gd`

**Interfaces:**
- Consumes: Task 5 `casualties`, `fatality_unit_ids`; Task 7 `describe`; Task 8 `retreat_count`.

- [ ] **Step 1: Fehlschlagenden Test schreiben** (Textprüfung wie in `scripts/tests/review8_ux_debrief_abort_verifier.gd`). Prüfungen, Schlusszeile `CAMPAIGN_CASUALTY_DISPLAY passed=%d failed=%d`:
  - Debrief nach Rückzug in der Kampagne zeigt die Überschrift `Rückzug · Auftrag bleibt offen` (nicht „Einsatz abgebrochen“); in Skirmish bleibt der alte Text.
  - Debrief-Zeile einer mittel Verwundeten enthält `Verwundet (mittel)` und `15:00`; die Zeile einer Toten enthält `Gefallen · zurückgelassen`.
  - `format_status_text` für eine Verwundete liefert den Text aus `describe`.
  - Die Personenkarte der Heimatbasis zeigt denselben Text statt des rohen Werts `wounded`.
  - Auftragstafel: Auftrag mit `retreat_count == 1` zeigt `Offen · 1 Rückzug`, mit 2 `Offen · 2 Rückzüge`.

- [ ] **Step 2: Test muss scheitern. Step 3: Umsetzen** (nur Anzeige; keine Knoten umbenennen, keine Größen ändern). **Step 4: Test grün, `review8_ux_debrief_abort_verifier.gd` grün. Step 5: Commit.**

### Task 10: Verträge und Gesamtlauf

**Files:**
- Create: `docs/dev/campaign_casualty_retreat_contract.md` (Regeln 1–8 der Aufgabendatei, Owner je Regel, Ergebnisfelder aus Task 5, Kampagnenstand-Felder aus Task 8)
- Modify: `docs/dev/campaign_introduction_contract.md` (Z. 82 und Z. 117–121: „Terminaler Personalausfall“ gilt nur noch bei Totalverlust), `docs/dev/mission_evacuation_abort_contract.md` (Auftragsstatus nach Evakuierung), `docs/dev/singleplayer_locations_jobs_contract.md` (Z. 24, 29), `docs/DECISIONS.md` (neue Entscheidung: kein Respawn in der Kampagne), `docs/GLOSSARY.md` (Bleedout in der Kampagne = „kritisch“)
- Modify: `docs/tasks/SPIELRUNDE_AUSFALL_RUECKZUG_2026_11_15.md` (Status, Testzahlen, offene Punkte)

- [ ] **Step 1:** Dokumente schreiben bzw. anpassen. `docs/PROJECT_BRIEF.md` nicht ändern (wird später als Ganzes ersetzt).
- [ ] **Step 2:** Alle neuen Tests dieses Plans nacheinander laufen lassen und die Zahlen in die Aufgabendatei schreiben.
- [ ] **Step 3:** Diese vorhandenen Tests laufen lassen und mit den vor Beginn notierten Zahlen vergleichen; jede Verschlechterung beheben oder mit Ursache melden: `campaign_two_moon_roundtrips_real_verifier.gd`, `campaign_five_actual_sorties_verifier.gd`, `campaign_pilot_ground_loop_test.gd`, `campaign_active_mission_continue_verifier.gd`, `campaign_onboarding_state_test.gd`, `campaign_supply_progression_verifier.gd`, `task_237_mission_progression_xp_morale_frustration.gd`, `task_1071_station_route_full_victory_debrief_trace.gd`, `review2_20261102_p1_hidden_mission_verifier.gd`.
- [ ] **Step 4:** `git status --short` zeigt nur beabsichtigte Dateien; keine `.import`-, `.uid`- oder Profil-Dateien committen. Commit.
- [ ] **Step 5:** Schlussbericht: je Aufgabe Commit-Hash und Testzahlen; was vom Plan abweicht und warum; was nicht geprüft werden konnte.
