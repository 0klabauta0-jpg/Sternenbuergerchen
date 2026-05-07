# TASK_285 - Tactical Decision Branch Integrity Review

## Ziel
Die neuen Entscheidungslogiken fuer CommanderIntent, FTL-Planung, taktische Regeln, Multi-Fireteam-Rollen, Ausbrueche, Kommunikation, Enemy-Profile und Air-Asset-Risiko sollen auf kaputte oder doppelte Zweige geprueft werden.

Der Task sucht besonders nach "nebenbei gebauter" Logik, die aehnlich aussieht, aber nicht denselben Vertrag nutzt.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_270 - Commander to Fireteam Leader Delegation Contract
- TASK_271 - Tactical Command Modes ROE Fire Rules
- TASK_272 - Multi Fireteam Coordinated Area Plan
- TASK_274 - Tactical Communication Feedback Layer
- TASK_276 - Tactical Breakout and Exception Behavior
- TASK_277 - Dropship Freighter Anti Armor Threat Contract
- TASK_280 - Tactical Profile Editor Scenario Authoring
- TASK_284 - Gameplay Truth Architecture Boundary Audit

## Kontext
Viele Bugs entstehen nicht durch fehlenden Code, sondern durch zwei halbe Pfade: ein alter `Move`-Sonderpfad, ein neuer `CommanderIntent`-Pfad, ein UI-Fallback, ein Editor-Default und ein Snapshot-Feld, die fast dasselbe meinen. Dieser Review macht diese Verzweigungen sichtbar.

## Umfang
1. Decision Tables:
   - CommanderIntent-Klassen.
   - TacticalRules-Kombinationen.
   - FTL-Ausbrueche.
   - Multi-Fireteam-Rollen.
   - AirAssetThreat/Destroy.
   - Enemy-Taktikprofile.
2. Branch-Audit:
   - Doppelte If-/Match-Pfade fuer denselben Zustand.
   - Unreachable states.
   - Default-Faelle ohne Diagnose.
   - Alte Aliase, die neue Regeln umgehen.
   - Fallbacks, die still andere Semantik setzen.
3. Prioritaetsregeln:
   - Was gewinnt bei Konflikt: Commander-Regel, FTL-Ausbruch, Contact, AirThreat, Medic, Path blocked.
   - Konflikte muessen dokumentiert und testbar sein.
4. Regression-Fixtures:
   - Kleine Fallmatrix mit klaren Inputs und erwarteten Outputs.
   - Low-/High-FTL.
   - Contact/no contact.
   - AirThreat/no AirThreat.
5. Report:
   - branch smell, duplicate path, missing diagnostic, contract mismatch.

## Nicht-Ziele
- Kein Balancing der Entscheidungsgewichte.
- Keine neue KI.
- Kein kompletter Resolver-Rewrite, ausser ein Befund braucht eigenen Patchtask.

## Akzeptanzkriterien
- [x] Zentrale taktische Entscheidungen sind als Decision Tables dokumentiert.
- [x] Konfliktprioritaeten sind eindeutig.
- [x] Stille Defaults fuer unbekannte Profile/States sind diagnostiziert oder als Review-Befund mit Fixvorschlag dokumentiert.
- [x] Alte Commands umgehen neue Vertraege nicht.
- [x] Report nennt doppelte oder widerspruechliche Zweige mit Fixvorschlag.
- [x] Ein Verifier prueft exemplarische Branch-Matrix.

## Erwartete Dateien
- `docs/reviews/tactical_decision_branch_integrity_review.md`
- `docs/dev/tactical_decision_priority_matrix.md`
- `scripts/tests/task_285_tactical_decision_branch_integrity_review.gd`
- `docs/tasks/TASK_285_tactical_decision_branch_integrity_review.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_285_tactical_decision_branch_integrity_review.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_272_multi_fireteam_coordinated_area_plan.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_276_tactical_breakout_and_exception_behavior.gd`
- [x] `git diff --check`

## Risiken
- Review kann viele kleine Stilbefunde finden; wichtig sind nur Pfade mit Verhaltensrisiko.
- Decision Tables duerfen nicht nachtraeglich Verhalten erfinden, sondern muessen Code/Vertrag spiegeln.

## Naechster Schritt
Nach TASK_285 prueft TASK_286 die UI-/Feedback-Schicht gezielt auf "UI wird Wahrheit"-Rueckfaelle.
