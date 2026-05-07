# TASK_214 - Comic Bubble Feedback Playability Smoke

## Ziel
Die Comic-Bubble-Reihe soll in einem integrierten Missionslauf geprueft werden: Asset-Katalog, Fireteamleader-Rueckmeldungen, Settings, Cooldowns, NPC-Gedanken per Hold-Taste, skillbasierte Texte und Snapshot-/Side-Effect-Grenzen.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_209 - Comic Bubble Asset Catalog and Visual Contract
- TASK_210 - Fireteamleader Command Feedback Bubbles
- TASK_211 - Comic Bubble Toggles Cooldowns and Settings
- TASK_212 - NPC Thought Bubble Hold to Peek Overlay
- TASK_213 - Skill Based Bubble Text Resolver and Content Pass

## Kontext
Sprechblasen koennen einzeln korrekt sein und zusammen trotzdem nerven: zu viele, zu lang, falscher Ort, falscher Zeitpunkt. Dieser Smoke prueft den realen Eindruck im Mission-Loop und stellt sicher, dass Bubbles nur Anzeige bleiben.

## Umfang
1. Missionslauf:
   - Spieler gibt Move/Defend/Take/Engage-Befehle.
   - FTL antwortet kurz.
   - Ungueltiger Befehl erzeugt knappe Ablehnung.
   - Contact/Warning priorisiert wichtige Bubble.
2. Settings:
   - `off`, `minimal`, `normal` pruefen.
   - Cooldown und Maximalzahl pruefen.
   - Thought-Hold-Taste pruefen.
3. Skilltexte:
   - Fireteamleader mit hohem und niedrigem Skill vergleichen.
   - NPCs mit Medic/Shooter/Pilot/Engineer/Leader-Rollen pruefen.
   - Texte bleiben kurz und passen in Bubble.
4. 2.5D-Lesbarkeit:
   - Bubbles folgen Units, aber verdecken HUD und Mission-Ziele nicht dauerhaft.
   - Bei Kamera/Zoom bleiben sie lesbar oder werden sauber ausgeblendet.
5. Multiplayer-/Snapshot-Grenze:
   - Bubble-Events duerfen als Visual-Information gespiegelt werden.
   - Snapshot-Anwendung erzeugt keine neuen Commands, Effects oder KI-Entscheidungen.
6. Manuelle Checkliste:
   - Kurzer Sichtcheck fuer Lesbarkeit, Timing, Nervfaktor und Abschaltbarkeit.

## Nicht-Ziele
- Kein Ersatz fuer Einzelverifier.
- Kein vollstaendiges Dialog-/Storysystem.
- Keine neue Gameplaymechanik.
- Kein Voice- oder Audiofeedback.

## Akzeptanzkriterien
- [x] Der integrierte Smoke erzeugt FTL-Bubbles fuer Befehle und blockierte Befehle.
- [x] Off/Minimal/Normal veraendern nur Sichtbarkeit, nicht Gameplay.
- [x] NPC-Gedanken erscheinen nur waehrend Hold.
- [x] Skillbasierte Texte sind unterscheidbar und kurz.
- [x] Maximalzahl und Cooldown verhindern Bubble-Spam.
- [x] Snapshot-/Viewer-Pfade erzeugen keine SimulationRoot-Commands oder Effects.
- [x] Eine manuelle Sichtcheckliste dokumentiert Lesbarkeit und Timing.

## Erwartete Dateien
- `scripts/tests/task_214_comic_bubble_feedback_playability_smoke.gd`
- `docs/dev/comic_bubble_manual_smoke_checklist.md`
- `scripts/terrain/terrain_map_3d_view.gd`
- `scripts/ui/comic_bubble_runtime_gate.gd`
- `docs/tasks/TASK_214_comic_bubble_feedback_playability_smoke.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_214_comic_bubble_feedback_playability_smoke.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_160_tactical_playability_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_168_multiplayer_snapshot_contract_verifier.gd`
- [ ] Manueller Mission-Map-Sichtcheck anhand Checkliste.
- [x] `git diff --check`

## Umsetzung
- `task_214_comic_bubble_feedback_playability_smoke.gd` prueft den integrierten Controller-/Gate-/2.5D-/Snapshot-Pfad mit Normal, Minimal, Off, Cooldown, Maximalzahl, Hold-Gedanken, skillbasierten Texten und visual-only-Grenze.
- `docs/dev/comic_bubble_manual_smoke_checklist.md` dokumentiert den manuellen Sichtcheck fuer Lesbarkeit, Timing, Nervfaktor und Abschaltbarkeit.
- Keine neue Gameplaymechanik: Bubble-Daten bleiben Anzeige- und Diagnosepayloads.

## Risiken
- Integrierte Smokes finden Nervfaktor besser als Einzeltests, lokalisieren Fehler aber schlechter.
- Falls die Bubbles zu dominant sind, braucht es danach einen kleinen Timing-/Opacity-Polish.

## Naechster Schritt
Nach TASK_214 kann die Bubble-Schicht in Playtests aktiviert werden oder in einen gezielten Polish-Pass gehen.
