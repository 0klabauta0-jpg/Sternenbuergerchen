# TASK_342 - SimulationRoot Unknown Payload Audit

## Ziel
Unbekannte Command- oder Effect-Payloads im `SimulationRoot` sollen nicht still ignoriert werden. Sie muessen diagnostisch sichtbar sein, ohne Release-Flow oder Negativtests durch harte Crashes zu zerbrechen.

## Status: GEPLANT

## Voraussetzung
- TASK_003 - SimulationRoot
- TASK_166 - Multiplayer Authority Command Contract
- TASK_284 - Gameplay Truth Architecture Boundary Audit
- TASK_337 - Architecture Performance UX Followup Gate

## Kontext
Die Review hat Default-Zweige in Command- und Effect-Verarbeitung gefunden, die unbekannte Typen aktuell ohne Diagnose passieren lassen. Das ist fuer robuste Entwicklung riskant: Tippfehler, veraltete Netzwerkpayloads oder UI-Fehlverdrahtungen koennen verschwinden, statt als klare Vertragsverletzung aufzutauchen.

## Umfang
1. Payload-Audit:
   - `_apply_command()` und `_apply_effect()` im `SimulationRoot` auf bekannte Typen, Default-Zweige und Tests verfolgen.
   - Bestehende Negativtests fuer Authority/Reject-Flows beruecksichtigen.
2. Diagnose:
   - Zaehler fuer unbekannte Command- und Effect-Typen einfuehren.
   - Letzte unbekannte Payload kompakt im Debug-Snapshot melden.
   - Warnung oder Report-Hinweis setzen, ohne produktiven Lauf hart zu beenden.
3. Gate:
   - Test fuer unbekannten Command und unbekannten Effect.
   - Bekannte Commands/Effects duerfen keine neuen Unknown-Counter erhoehen.
   - Multiplayer-Rejects bleiben kontrollierte Rejects und werden nicht mit Unknown-Payloads verwechselt.
4. Dokumentation:
   - Kurzen Report oder Statusnotiz mit erlaubtem Verhalten: sichtbar ignorieren, nicht still verschlucken.

## Nicht-Ziele
- Kein neuer Command-/Effect-Schema-Parser.
- Keine Umstellung auf Exceptions als Runtime-Kontrollfluss.
- Keine Aenderung an autoritativen Gameplay-Mutationen.
- Keine Multiplayer-Protokollmigration.

## Akzeptanzkriterien
- [ ] Unbekannte Commands und Effects erhoehen stabile Diagnose-Counter.
- [ ] Debug-Snapshot/Report zeigt mindestens Typ und Herkunftskategorie der letzten unbekannten Payload.
- [ ] Bekannte Commands/Effects verhalten sich unveraendert.
- [ ] Authority-/Multiplayer-Regressionen bleiben gruen.

## Erwartete Dateien
- `scripts/core/simulation_root.gd`
- optional `scripts/tests/task_342_simulation_root_unknown_payload_audit.gd`
- `docs/tasks/TASK_342_simulation_root_unknown_payload_audit.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_342_simulation_root_unknown_payload_audit.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_166_multiplayer_authority_command_contract_verifier.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_284_gameplay_truth_architecture_boundary_audit.gd`
- [ ] `git diff --check`

## Risiken
- Zu laute Warnungen koennen bekannte Negativtests verrauschen. Die Diagnose muss deshalb stabil zaehlbar und bei erwarteten Rejects sauber getrennt sein.

## Naechster Schritt
Nach diesem Audit koennen Command-/Effect-Vertraege leichter fuer Multiplayer- und Replay-Gates erweitert werden.
