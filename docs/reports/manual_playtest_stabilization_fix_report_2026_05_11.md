# Manual Playtest Stabilization Fix Report 2026-05-11

## Kurzfassung
Die akuten Audit-Funde aus Dropship, RMB-Orders, Feedback-Bubbles, FOB-Loadout, Multiplayer-Lobby, Editor-Palette und Docs wurden bearbeitet. Der aktuelle Arbeitsstand nutzt Godot 4.6.2 als eindeutige Zielversion; `sternenbuerger-gdd.docx` ist als Alt-GDD/Inspiration dokumentiert und erzeugt keine zweite technische Wahrheit.

## Behobene Punkte
- Dropship-Visuals: Format-Fehler in der Visual-Signatur repariert, geplante LZs bleiben sichtbar, und RTB/Outbound-Zustaende werden wieder in den Visual-Entries beruecksichtigt.
- Multi-Dropship-Flow: ausgewählte Mission-Dropship-Karten ziehen ihre Payload jetzt aus dem rohen Card-State, damit ein zweites Dropship nicht vom stale Selected-Card-State des ersten ueberschrieben wird.
- Inbound-Auswahl: die aktive Drop-Sequenz speichert Craft-ID, LZ, Approach und Payload separat. Dadurch kann Dropship 2 waehrend Dropship 1 inbound ist fuer Mission Control ausgewaehlt und als Drop-Queue markiert werden, ohne dass Dropship 1 seine Sequenz oder Payload verliert.
- Offscreen-Warten: Mission-Dropships im Zustand `waiting` bleiben als Karte/Plan sichtbar, aber nicht als geparktes Modell an der Map-Kante.
- RMB-Orders: Test-World-Ziele werden nicht mehr ein zweites Mal auf Tile-Mitte geschoben; echte UI-Eingaben behalten das normale Snapping.
- Feedback-Bubbles: nur visuell taugliche Bubbles blockieren die Deduplizierung, damit falsche/non-visual Entries keine echten Status-Bubbles verschlucken.
- FOB-Loadout: Teammitglieder erscheinen als kompakte Name/Portrait-Karten, die das Character Sheet oeffnen.
- Multiplayer-Lobby: der Screen bleibt in einem festen Panel und nutzt internes Scrolling statt ueber den 1280x720-Viewport hinauszuwachsen.
- Map-Editor-Palette: Gruppen bleiben erhalten, zusaetzlich gibt es `Alle` als vollstaendige Langliste.
- Docs: Godot 4.6.2 ist in den bindenden Projektregeln und im Performance-Budget-Contract vereinheitlicht; das DOCX ist als Alt-GDD/Inspiration mit konkreten Konflikten dokumentiert.

## GDD-Konflikte
Die konkreten Problemstellen am DOCX sind nicht, dass die Ideen falsch waeren, sondern dass sie unmarkiert neben den aktuellen Markdown-Docs andere Wahrheiten anbieten:

- Phase 1 ohne Multiplayer vs aktueller ENet/UPnP-Multiplayer-Prototyp.
- Node.js-WebSocket-Server vs aktuelle Godot-ENet-Architektur.
- externe Universums-/IP-Begriffe vs repo-eigene bindende Projektlinie.
- 15 bis 100 NPCs und groessere Teamleader-Slices vs aktueller kleiner V1-Fireteam-/Dropship-Scope.
- tiefe Sozial-/Sympathie-/Stat-Systeme vs aktuell nur teilweise implementierte V1-Mechaniken.

## Lokale Pruefung
- `task_258_fixed_window_clipping_scrollbar_playability_audit.gd` exit-code gruen
- `bugfix_multiplayer_lobby_setup_and_asset_catalog_followup.gd` 29/0
- `task_259_character_card_roster_switching_playability.gd` exit-code gruen
- `bugfix_character_team_editor_usability_pass.gd` exit-code gruen
- `task_310_fob_flightdeck_fireteam_userology_smoke.gd` 5/0
- `bugfix_mission_multi_dropship_cards.gd` exit-code gruen
- `bugfix_mission_dropship_plans_and_facing.gd` exit-code gruen
- `task_313_dropship_arrival_visibility_feedback_smoke.gd` 5/0
- `bugfix_mission_fire_sector_overlay.gd` exit-code gruen
- `task_158_verifier.gd` exit-code gruen
- `task_160_tactical_playability_verifier.gd` exit-code gruen
- `task_186_mission_map_unit_presence_registry_audit.gd` exit-code gruen
- `task_192_mission_map_npc_behavior_playability_smoke.gd` exit-code gruen
- `task_250_asset_audio_background_playability_smoke.gd` exit-code gruen
- `bugfix_mission_right_click_order_flow.gd` exit-code gruen
- `task_286_ui_feedback_truth_regression_review.gd` exit-code gruen
- `bugfix_dropship_mission_flow_verifier.gd` exit-code gruen
- `task_222_performance_regression_gate_and_manual_profile_checklist.gd` exit-code gruen

## Offene Punkte
- Manueller FullHD-Sichtcheck fuer die genaue optische Balance von Lobby, FOB-Loadout und Mission-Dropship-Visuals bleibt sinnvoll.
- Echte Internet-Erreichbarkeit via UPnP/Router/NAT bleibt ein manueller Netzwerkcheck.
- Falls DOCX-Inhalte aktiv werden sollen, muessen sie einzeln in Markdown-Tasks oder Decisions migriert werden.
