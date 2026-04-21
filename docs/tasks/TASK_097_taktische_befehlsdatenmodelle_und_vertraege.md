# TASK_097 – Datenmodelle, engage und Ad-hoc-Vertraege

## Ziel
Die neue Taktikschicht bekommt alle benoetigten Dictionary-kompatiblen Datenmodelle fuer Planung, globale Phasen, Ad-hoc-Eingriffe und Loadout-Modifikatoren. Gleichzeitig wird `engage` als regulärer geplanter Befehl wieder in den Befehlsvertrag aufgenommen.

## Status: OFFEN

## Pflicht vor Beginn
- Lies [docs/PROJECT_BRIEF.md](docs/PROJECT_BRIEF.md)
- Lies [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
- Lies [docs/CODEX_RULES.md](docs/CODEX_RULES.md)
- Lies [docs/IMPLEMENTATION_STATUS.md](docs/IMPLEMENTATION_STATUS.md)
- Lies [docs/tasks/TASK_038_fireteam_aufteilung.md](docs/tasks/TASK_038_fireteam_aufteilung.md)
- Lies [docs/tasks/TASK_039_phasen_wirkung.md](docs/tasks/TASK_039_phasen_wirkung.md)
- Pruefe den Git-Status

## Kontext
- Diese Task-Reihe folgt dem aktualisierten Taktik-Prompt und erweitert den bisherigen engen V1-Rahmen bewusst.
- Bestehende Kernsysteme `SimulationRoot`, `RuntimeLeader`, `EventRouter`, `UnitRegistry`, `FTLRegistry`, `CommanderCommand`, `FTLTask`, `UnitCommand` und `CommandToFTLTaskTranslator` bleiben strukturell bestehen.
- Neue Systeme schreiben nicht direkt auf `TestUnit`, sondern erzeugen Commands oder Effects fuer den bestehenden autoritativen Pfad.

## Aufgabe

### 1. Neue Datenmodelle einfuehren
- `FireteamWaypoint`
- `FireteamOrderPlan`
- `FireteamBehaviorProfile`
- `PhaseState`
- `AdHocOrder`
- `UnitLoadoutModifiers`

### 2. Befehlsvertraege erweitern
- `FireteamWaypoint.command_type` unterstuetzt:
  - `move`
  - `defend`
  - `engage`
  - `flank`
  - `take`
- `flank` wird als Sonderfall explizit dokumentiert:
  - geplant als Wegpunkt-Typ
  - ad hoc als Sofortbefehl im Gefecht

### 3. Ad-hoc-Vertrag formalisieren
- `AdHocOrder.order_type` unterstuetzt:
  - `flank`
  - `disengage`
  - `fall_back`
  - `focus_fire`
  - `hold_till_last_man`
- `resume_plan_after` ist fuer den ersten Slice immer `true`.

### 4. Integrationsgrenzen festziehen
- Alle Modelle bleiben leichtgewichtig und netzwerkfreundlich.
- `FireteamBehaviorProfile` bleibt reines Laufzeit-Ergebnis und wird nicht persistiert.
- Keine neue Autoload-Schicht.
- Keine strukturelle Ersetzung vorhandener Runtime-Systeme.

## Nicht-Ziele
- keine UI
- keine Plan-Ausfuehrung
- keine Suppression-Logik
- keine Gegner-Patrouillen

## Akzeptanzkriterien
- Alle sechs Modelle existieren als saubere Datentraeger.
- `engage` ist im Planungsvertrag wieder enthalten.
- Ad-hoc-Befehle haben einen klaren eigenen Laufzeitvertrag.
- Kein bestehender Kernbaustein wird strukturell ersetzt.
