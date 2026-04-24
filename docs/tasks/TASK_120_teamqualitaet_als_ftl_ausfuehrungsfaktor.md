# TASK_120 - Teamqualitaet als FTL-Ausfuehrungsfaktor

## Ziel
Das Designversprechen aus `DESIGN_NOTES.md` soll im Einsatz staerker spuerbar werden: Der Spieler gewinnt nicht durch perfekte Einzelsteuerung, sondern durch gute Teamzusammenstellung und brauchbare FTL-Ausfuehrung. Commander-Befehle bleiben indirekt; Teamwerte beeinflussen, wie sauber, schnell und stabil sie umgesetzt werden.

## Status: IMPLEMENTIERT

## Pflicht vor Beginn
- Lies `docs/PROJECT_BRIEF.md`
- Lies `docs/ARCHITECTURE.md`
- Lies `docs/CODEX_RULES.md`
- Lies `docs/IMPLEMENTATION_STATUS.md`
- Lies `docs/DESIGN_NOTES.md`
- Lies `docs/tasks/TASK_046_unit_skill_werte.md`
- Lies `docs/tasks/TASK_048_persoenlichkeitsmerkmale.md`
- Lies `docs/tasks/TASK_088_leadership_bonus.md`
- Lies `docs/tasks/TASK_093_discipline_hold_fire.md`
- Lies `docs/tasks/TASK_094_recognition_friendly_fire.md`
- Lies `docs/tasks/TASK_101_fireteambehaviorresolver_und_standardverhalten.md`
- Lies `docs/tasks/TASK_110_fireteammovementcontroller_und_bewegungsmuster.md`
- Lies `docs/tasks/TASK_118_combat_entscheidungen_aus_mission_driver_herausloesen.md`
- Lies `docs/tasks/TASK_119_seeded_combat_rng_und_roll_override_begrenzen.md`
- Pruefe den Git-Status

## Kontext
- Es gibt bereits viele Einzelfaktoren: Leadership, Discipline, Recognition, Stance, Movement Style, Contact Delay, Flank Morale.
- Im aktuellen Spielgefuehl droht die UI-/Controller-Regelmaschine staerker zu wirken als das Team.
- Dieser Task soll keine tiefe Sozialdynamik bauen, sondern einen V1-tauglichen Ausfuehrungsfaktor, der Teamqualitaet sichtbar und testbar macht.

## Aufgabe

### 1. Fireteam-Ausfuehrungsprofil ableiten
- Baue oder erweitere einen kleinen Fireteam-Ausfuehrungs-Resolver.
- Er soll aus vorhandenen Daten einen kompakten Score-/Profil-Satz ableiten, z.B. `order_fidelity`, `reaction_delay`, `cohesion`, `fire_discipline`, `contact_stability` und `initiative`.
- Nutze vorhandene Unit-Skills, Traits, Leadership und Rolleninformationen.
- Keine neue Persistenz fuer Beziehungen oder Sozialdynamik in diesem Task.

### 2. Umsetzung von Commander-Befehlen beeinflussen
- Der FTL-/Fireteam-Pfad soll den Ausfuehrungsfaktor beim Start oder Fortschritt von Orders konsumieren.
- Beispiele fuer V1-Wirkungen:
  - schlechte Order Fidelity erzeugt leichte Verzoegerung oder unsauberes Ziel-Offset
  - niedrige Cohesion vergroessert Formation-/Movement-Streuung
  - niedrige Fire Discipline erhoeht Hold-Fire-Brueche oder fruehes Feuer
  - hohe Leadership reduziert Verzoegerung und stabilisiert Bound-/Caterpillar-Ablauf
- Effekte muessen nachvollziehbar bleiben, nicht unfair wirken.

### 3. UI nur lesend machen
- Tactical UI darf die Ausfuehrungsqualitaet anzeigen oder erklaeren.
- UI darf diese Werte nicht selbst berechnen und nicht zur Gameplay-Wahrheit machen.
- Die Berechnung liegt in Runtime-/Resolver-Code.

### 4. Spielgefuehl sichtbar machen
- Mindestens ein klares Feedback muss entstehen, wenn ein Team einen Befehl besonders sauber oder schlecht umsetzt.
- Beispiele: `CLEAN EXEC`, `DELAY`, `SCATTER`, `LOW DISC` oder ein kleines Qualitaetskuerzel im Fireteam-Status.
- Die Anzeige bleibt beobachtend.

## Nicht-Ziele
- keine tiefe Beziehungs-/Sozialdynamik
- keine Kampagnen-Persistenz fuer Teamchemie
- keine neue Charaktergenerator-Architektur
- keine direkte Einzel-Unit-Steuerung
- kein Balancing-Grosswurf
- keine neue UI-Komplettansicht

## Akzeptanzkriterien
- Fireteams erhalten ein aus vorhandenen Unit-/Leaderdaten abgeleitetes Ausfuehrungsprofil.
- Mindestens Movement- oder Order-Start-Verhalten wird durch dieses Profil spuerbar beeinflusst.
- Der Spieler sieht im Einsatz, dass unterschiedliche Teams denselben Befehl unterschiedlich gut umsetzen.
- UI liest und zeigt die Werte, berechnet oder committed sie aber nicht.
- Headless-Verifier pruefen mindestens hohe vs. niedrige Teamqualitaet und deren Wirkung.

## Betroffene Bereiche
- `scripts/command/fireteam_behavior_profile.gd`
- Fireteam Behavior-/Movement-/Order-Resolver nach TASK_116
- `RuntimeLeader` oder bestehender Commander->FTL->Unit-Pfad, falls dort die bessere Grenze liegt
- Tactical Status-/Header-Anzeige rein lesend
- relevante Verifier fuer TASK_101, TASK_110 und neue Ausfuehrungsqualitaet

## Lokale Prueflogik
- `godot_console.exe --headless --path . --script scripts/tests/task_101_verifier.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_110_verifier.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_113_verifier.gd`
- Neuer Verifier fuer Teamqualitaet als Ausfuehrungsfaktor.

## Umsetzung
- `FireteamBehaviorProfile` traegt jetzt einen kompakten Ausfuehrungsprofil-Satz:
  - `order_fidelity`
  - `reaction_delay_seconds`
  - `execution_cohesion`
  - `execution_fire_discipline`
  - `contact_stability`
  - `initiative`
  - `execution_label`
- `FireteamBehaviorResolver` leitet diese Werte aus vorhandenen Leader-/Teamdaten ab: Skills, Discipline, Recognition und Traits.
- `FireteamMovementController` konsumiert das Profil beim Start der Ausfuehrung:
  - niedrige `order_fidelity` erzeugt einen kleinen deterministischen Ziel-Offset.
  - niedrige `execution_cohesion` vergroessert Formationstreuung.
  - `initiative` beeinflusst den Bewegungstempo-Multiplikator.
- Die Tactical UI zeigt die Qualitaet nur lesend als `EXEC ...` im Fireteam-Status; sie berechnet oder committed keine Gameplay-Werte.
- Feedback-Labels wie `CLEAN EXEC`, `DELAY`, `SCATTER`, `LOW DISC` und `STEADY` kommen aus dem Runtime-/Resolver-Pfad.

## Verifikation
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_120_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_101_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_110_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_113_verifier.gd`

Hinweis: `task_101_verifier.gd` meldet nach erfolgreichen Assertions weiterhin Godot-RID-/Resource-Leak-Ausgaben aus der Szenenpruefung.

## Git-Schritte nach lokaler Pruefung
- `git status`
- `git add` nur relevante Dateien
- `git commit -m "Make team quality affect FTL execution"`
- `git push`
- `docs/IMPLEMENTATION_STATUS.md` erst nach Umsetzung aktualisieren
