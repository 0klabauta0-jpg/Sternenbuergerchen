# TASK_367 - FTL Public Readiness Snapshot Contract

## Ziel
Einen kleinen, UI-tauglichen Readiness-Snapshot fuer Fireteam-Leader bereitstellen, der bestehende Werte wie `reaction_delay_seconds`, `plan_quality`, `morale` und Label nutzt.

## Status: GEPLANT

## Sinnhaftigkeitscheck
Der Review-Punkt ist sinnvoll, weil `FireteamBehaviorResolver` bereits `build_public_leader_tactical_snapshot()` und Werte fuer Reaktion, Planqualitaet und Moral kennt. Die Aufgabe ist also kein Balancing-Neubau, sondern ein sauberer Anzeigevertrag.

## Problem
FTL-Leistung beeinflusst Ausfuehrung, ist im Mission-HUD aber nur indirekt ueber Texte erkennbar.

## Ursache
Die vorhandenen FTL-Metriken stecken in Profil-/Plan-Metadaten und werden nicht als stabiler, kleiner HUD-Snapshot aggregiert.

## Umfang
- Public Snapshot fuer Mission-HUD normalisieren: Fireteam-ID, Leader-Name, Reaction, Morale, Plan Quality, Execution Label.
- Quellen priorisieren: FireteamBehaviorResolver, Plan-Assignments, Mission-Setup/Units.
- Fehlende Werte explizit als unavailable markieren statt 0.5-Fakewerte als Wahrheit zu zeigen.
- Snapshot klein, deterministisch und multiplayer-spiegelbar halten.
- Dokumentieren, dass UI den Snapshot nur liest.

## Akzeptanzkriterien
- [ ] Snapshot enthaelt nur read-only Felder und keine Objekt-/Node-Referenzen.
- [ ] Fehlende Leader oder fehlende FTL-Daten erzeugen nachvollziehbare Fallbacks.
- [ ] Wertebereiche fuer Reaction, Morale und Plan Quality sind geklemmt und dokumentiert.
- [ ] Regression prueft, dass Snapshot-Erstellung keine SimulationRoot-Commands/Effects enqueued.
- [ ] Existing TASK_273/274-Vertraege bleiben kompatibel.

## Erwartete Dateien
- `scripts/tactical/fireteam_behavior_resolver.gd`
- ggf. `scripts/tactical/ftl_readiness_snapshot_contract.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_367_ftl_public_readiness_snapshot_contract.gd`

## Lokale Pruefung
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_367_ftl_public_readiness_snapshot_contract.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_273_fireteam_leader_skill_tactical_progression.gd`
- [ ] `git diff --check`

## Risiken / offene Punkte
- Morale darf nicht frei im HUD berechnet werden, wenn Mission-/Roster-Fortschritt spaeter eine andere Quelle definiert.
- Der Snapshot muss klein bleiben, damit er nicht zum zweiten Fireteam-Modell wird.

