# TASK_274 - Tactical Communication Feedback Layer

## Ziel
Der Spieler soll mitbekommen, was Fireteams gerade tun und warum. Taktische Kommunikation soll Planannahme, Rollen, Ausbrueche, Kontakt, Blockaden, Erfolg, Fehlschlag und Rueckfragen kurz sichtbar machen.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_191 - Command Chain Selection and Area Feedback Pass
- TASK_209 - Comic Bubble Asset Catalog and Visual Contract
- TASK_210 - Fireteamleader Command Feedback Bubbles
- TASK_214 - Comic Bubble Feedback Playability Smoke
- TASK_263 - Contextual Help Popup UX Contract
- TASK_272 - Multi Fireteam Coordinated Area Plan
- TASK_273 - Fireteam Leader Skill Tactical Progression

## Kontext
Wenn Teams dynamischer handeln, muss der Spieler das verstehen. Ein FTL soll nicht still abweichen. Er soll knapp melden: "Alpha sichert", "Bravo bewegt", "Kontakt links", "Pfad blockiert", "Warte auf GO", "Kann nicht", "Passe Route an".

## Umfang
1. Kommunikationsereignisse:
   - Order received.
   - Plan role assigned.
   - Phase start/complete.
   - Contact report.
   - Breakout/adaptation.
   - Cannot/needs orders.
   - Objective progress/complete.
   - Air asset threatened/destroyed.
2. Kanaele:
   - #17 Selected Fireteam.
   - #18 Mission Control.
   - Map marker/status.
   - Fireteamleader-Bubble.
   - Optional audio/short radio blip aus TASK_244.
3. Prioritaet:
   - Nicht alles gleichzeitig.
   - Kritische Meldungen oben, normale Statuszeilen kompakt.
   - Cooldowns, damit Bubbles nicht spammen.
4. Textresolver:
   - Skill/Communication des FTL kann Praezision und Ton beeinflussen.
   - Kurze, klare Labels; Detail ueber Help oder #17/#18.
5. Snapshot:
   - Meldungen sind testbar, mit Event-ID, Unit/Fireteam-ID, Prioritaet, Dauer, Channel.

## Nicht-Ziele
- Kein Dialogsystem.
- Keine langen Funksprueche.
- Keine Voiceover-Pflicht.
- Keine Lore-Konversation.

## Akzeptanzkriterien
- [x] Fireteams melden Planrolle, Phase und Ausbrueche sichtbar.
- [x] Kritische Meldungen blockieren normale Statusmeldungen.
- [x] Bubbles/#17/#18 widersprechen sich nicht.
- [x] Meldungen haben Cooldowns und stabile Event-IDs.
- [x] FTL-Communication-Skill kann Praezision beeinflussen, ohne Gameplay-Wahrheit zu aendern.
- [x] Ein Verifier prueft Kommunikationsereignisse und Anti-Spam-Regeln.

## Erwartete Dateien
- `scripts/tactical/tactical_communication_event.gd`
- `scripts/tactical/tactical_communication_resolver.gd`
- `data/tactical_communication_copy.json`
- `scripts/tests/task_274_tactical_communication_feedback_layer.gd`
- `docs/tasks/TASK_274_tactical_communication_feedback_layer.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_274_tactical_communication_feedback_layer.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_214_comic_bubble_feedback_playability_smoke.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_191_command_chain_selection_area_feedback_pass.gd`
- [x] `git diff --check`

## Risiken
- Zu viele Meldungen machen das Spiel lauter, aber nicht klarer.
- Meldungen duerfen keine zweite Gameplay-Wahrheit neben Snapshots und SimulationRoot werden.

## Naechster Schritt
Nach TASK_274 kann TASK_275 die Command-Buttons und UI-Gruppierung an den neuen Befehlsebenen ausrichten.
