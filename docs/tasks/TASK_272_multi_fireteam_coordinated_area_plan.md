# TASK_272 - Multi Fireteam Coordinated Area Plan

## Ziel
Wenn der Spieler zwei oder mehr Fireteams auf ein gemeinsames Ziel oder Gebiet setzt, soll ein koordinierter Plan entstehen: Wer sichert, wer bewegt sich, wer nimmt ein, wer deckt, wer flankiert oder wer bleibt Reserve. Der Spieler muss das nachvollziehen koennen.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_121 - Area Order Marker
- TASK_122 - Defend Area Semantik
- TASK_123 - Attack Area Semantik
- TASK_124 - Area Feedback in #17 Selected Fireteam
- TASK_188 - Fireteam Advance Styles Map Readability
- TASK_191 - Command Chain Selection and Area Feedback Pass
- TASK_270 - Commander to Fireteam Leader Delegation Contract
- TASK_271 - Tactical Command Modes ROE Fire Rules

## Kontext
Aktuell kann jedes Fireteam eigene Orders bekommen. Spannender wird es, wenn mehrere Teams denselben Commander-Intent teilen und daraus ein sichtbarer Gruppenplan entsteht. Beispiel: Team Alpha bindet/sichert, Team Bravo bewegt sich, Team Charlie nimmt das Gebiet oder bleibt Reserve.

## Umfang
1. Planrollen:
   - Lead/Assault.
   - Support/Base.
   - Security/Watch.
   - Reserve/Medic/Recover.
   - Recon/Probe.
2. Planer:
   - Aus CommanderIntent, Teamqualitaet, Position, Kontaktlage, Terrain, Cover und Waffenrange Rollen vorschlagen.
   - Spieler kann Vorschlag bestaetigen oder Rollen simpel tauschen.
   - Kein komplexer Optimierer; V1 bleibt nachvollziehbar.
3. Ausfuehrung:
   - Teams bewegen in Phasen.
   - Support-Team haelt/Sichert, Lead bewegt, Reserve wartet.
   - FTLs duerfen Ausbrueche aus TASK_276 melden.
4. UI/Feedback:
   - Plan-Karte: knappe Rollenlabels.
   - #17 zeigt pro Fireteam Rolle, Phase, naechsten Schritt.
   - #18 zeigt Gesamtplanstatus.
   - Bubbles/Radio melden Start, Wechsel, Blockade, Abschluss.
5. Tests:
   - Zwei Fireteams nehmen Area.
   - Drei Fireteams mit Support/Lead/Reserve.
   - Plan bleibt bei Contact und blocked Path stabil.

## Nicht-Ziele
- Kein perfekter MilSim-Planer.
- Kein automatisches Gewinnen durch Planvorschlag.
- Keine direkte Kontrolle einzelner Units.
- Kein UI-Redesign jenseits kompakter Rollenanzeige.

## Akzeptanzkriterien
- [x] Multi-Fireteam-Plan kann Rollen Lead/Support/Security/Reserve zuweisen.
- [x] Spieler sieht vor GO, wer welche Rolle uebernimmt.
- [x] #17/#18 und Map zeigen Planphase und Rolle ohne Widerspruch.
- [x] Mehrere Fireteams stapeln nicht und halten Mindestabstand.
- [x] Ausfuehrung nutzt bestehende Area-/Waypoint-/SimulationRoot-Pfade.
- [x] Ein Verifier prueft 2- und 3-Fireteam-Plaene, Status und State-Konsistenz.

## Erwartete Dateien
- `scripts/tactical/multi_fireteam_plan_resolver.gd`
- `scripts/command/commander_intent.gd`
- `scripts/tactical/fireteam_execution_plan.gd`
- `scripts/tests/task_272_multi_fireteam_coordinated_area_plan.gd`
- `docs/dev/multi_fireteam_plan_contract.md`
- `docs/tasks/TASK_272_multi_fireteam_coordinated_area_plan.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_272_multi_fireteam_coordinated_area_plan.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_188_fireteam_advance_styles_map_readability.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_191_command_chain_selection_area_feedback_pass.gd`
- [x] `git diff --check`

## Risiken
- Automatische Rollen duerfen den Spieler nicht bevormunden.
- Zu viel Karten-Overlay kann Units verdecken; Status muss kompakt bleiben.

## Naechster Schritt
Nach TASK_272 kann TASK_273 FTL-Skill und Teamfortschritt sichtbar in die Planqualitaet einfliessen lassen.
