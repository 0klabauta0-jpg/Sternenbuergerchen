# TASK_1129 - Tactical Communication Bubble Typography and Mode Contract Reconciliation

## Status: IMPLEMENTIERT

## Ziel / Problem
Der TASK-1128-Full-HD-Beleg zeigt kollisionsfreie Fireteam-Bubbles, aber eine kleine 8-px-Schrift. Gleichzeitig stehen TASK_212 bei 18/19 und TASK_214 bei 32/36, weil World-Gedanken pro Fireteam zusammenfallen, der Minimalmodus durch einen Context-Fallback umgangen wird und alte Text-/Renderannahmen nicht mehr zum heutigen Vertrag passen.

## Sinnhaftigkeit / Ursache
- HUD-Bubble-Typografie ist direkt im Visualpfad hart auf 8 px gesetzt und im Render-Snapshot nicht messbar.
- `_build_feedback_bubble_anchor_key()` priorisiert fuer alle Bubbles `fireteam_id`; World-Gedanken unterschiedlicher Units kollabieren deshalb auf einen Eintrag.
- `_should_replace_command_feedback_bubble_after_cooldown()` erlaubt `command_context` auch dann, wenn der zentrale Gate den Payload wegen `minimal` abgelehnt hat.
- TASK_214 erwartet noch `comms_lines`, obwohl konkrete Order-Summaries absichtlich aus `command_context` stammen, und verlangt jeden Rohpayload statt der deduplizierten sichtbaren Eintraege.

## Umfang
- HUD-Bubble-Schrift auf mindestens 10 px anheben und im Render-Snapshot ausweisen.
- HUD-Bubbles weiter pro Fireteam, World-Bubbles mit Unit-ID pro Unit deduplizieren.
- Context-Cooldown-Ersatz nur erlauben, wenn der aktuelle Modus die Payload-Kategorie grundsaetzlich zulaesst.
- TASK_214 auf `command_context` und sichtbare deduplizierte Eintraege aktualisieren, ohne Settings- oder Visual-only-Gates zu lockern.
- Neuer fokussierter Verifier fuer Typografie und World-Unit-Dedupe.

## Nicht-Ziele
- Kein neues Bubble-Artwork oder Textkatalog-Rewrite.
- Keine Aenderung an Gameplay-, Command-, Event-, Simulation-, RPC- oder Snapshotwahrheit.
- Keine Gedankenanzeige ohne Hold-Eingabe.
- Keine Aufhebung von Fog-of-War-Filtern oder Gesamtlimits.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_211_comic_bubble_toggles_cooldowns_and_settings.md`
- `docs/tasks/TASK_212_npc_thought_bubble_hold_to_peek_overlay.md`
- `docs/tasks/TASK_214_comic_bubble_feedback_playability_smoke.md`
- `docs/tasks/TASK_1128_tactical_communication_hud_bubble_density_real_window_readability.md`

## Akzeptanzkriterien
- HUD-Bubble-Render-Snapshot meldet `hud_font_size >= 10`.
- Drei World-Thought-Payloads desselben Fireteams mit drei Unit-IDs erzeugen drei sichtbare Eintraege.
- Command- und Thought-Bubble derselben Unit bleiben nach Prioritaet auf hoechstens einen World-Eintrag dedupliziert.
- Minimalmodus unterdrueckt akzeptierte Routine-Commands und zeigt Blocked-Feedback.
- `command_context` ist fuer konkrete Order-Summaries der aktuelle Textvertrag.
- TASK_212 und TASK_214 sind vollstaendig gruen.
- TASK_1128 Real Window zeigt weiterhin kollisionsfreie, angenehm lesbare Bubbles.

## Betroffene Dateien
- `scripts/terrain/terrain_map_3d_view.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_214_comic_bubble_feedback_playability_smoke.gd`
- `scripts/tests/task_1129_tactical_communication_bubble_typography_mode_contract_reconciliation.gd`
- Status-, Roadmap- und HTML-Berichtsdokumentation

## Lokale Pruefung
- TASK_1129 RED/GREEN.
- TASK_212 und TASK_214 RED/GREEN.
- TASK_1128 headless und Real Window.
- TASK_274, TASK_1119, TASK_1104 und TASK_222.
- `git diff --check`.

## Risiken / offene Punkte
Groessere Schrift vergroessert Bubble-Rechtecke. Der bestehende Full-HD-Abstandsvertrag muss deshalb nach der Aenderung erneut laufen; Text darf weder abgeschnitten werden noch in die Nachbar-Bubble ragen.

Der neue Full-HD-Beleg bleibt kollisionsfrei. Als naechster sichtbarer Befund bleiben die sehr kleinen Fireteam-Mini-Card-Statuszeilen und das unklare `FT ?` trotz bekannter BLUE-/GOLD-Identitaet.

## Ergebnis
- HUD-Bubble-Schrift steigt von 8 auf 10 px und wird als `hud_font_size` im read-only Render-Snapshot ausgewiesen.
- HUD-Bubbles deduplizieren weiter pro Fireteam; World-Bubbles mit Unit-ID deduplizieren pro Unit.
- Hold-to-Peek kann dadurch Leader-, Medic-, Pilot- und Engineer-Gedanken sichtbar an ihren Units halten.
- Der Context-Cooldown-Fallback respektiert wieder den zentralen Bubble-Modus; `minimal` unterdrueckt Routine und behaelt Blocked-Feedback.
- TASK_214 dokumentiert `command_context` als aktuellen konkreten Order-Summary-Pfad und prueft sichtbare Eintraege nach Dedupe statt rohe Payloadanzahl.

## Lokale Pruefergebnisse
- TASK_1129: 4/4.
- TASK_212: 19/19.
- TASK_214: 36/36.
- TASK_1128: 8/8 Real Window.
- Sichtbeleg: `tmp/task_1128_tactical_communication_hud_bubble_density.png`.
