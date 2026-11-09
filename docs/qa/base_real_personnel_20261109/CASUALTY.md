# Kampagne: terminaler Personalausfall statt endlosem Boarding

Finalreview-P1 auf Kandidat `c9d84f58d`, ein begrenzter Fixpass. Kein Commit/Push durch diesen Agenten.

## Befund und Verhalten

`MetaLayerFlow._on_mission_combat_resolved` wartete vor Ergebnisverarbeitung auf Boarding. Der echte Transportowner lehnt einen ausgefallenen Piloten bzw. nicht boardingfaehige Bodenbesatzung dauerhaft ab; CombatLoopDriver hatte das Gefecht bereits beendet. Ergebnis, medizinische Folgen und Debrief wurden nie erreicht.

Nur die terminalen Boardinggruende `pilot_unavailable` und `crew_unavailable` beenden jetzt die Kampagnensortie als fehlgeschlagene Extraktion. Auch ein taktischer Objective-Sieg ohne moegliche Extraktion ist kein erfolgreicher Ausflug; das originale Ergebnis bleibt in `original_mission_result`. Der bestehende Owner verbucht den Fehlschlag; echte Teamzustaende und vorhandene Personal-/Recovery-/Progressionsfolgen erreichen den Debrief. Keine fingierte physische Heimkehr, kein Rueckflug-Fuelabzug, keine Erfolgsbelohnung und kein neuer sicherer Checkpoint.

Der sichtbare Debrief erklaert den Ausgang und bietet `Letzten sicheren Checkpoint fortsetzen`. Beide alten Debrief-Rueckcallbacks laden in diesem Fall ausschliesslich denselben normalen Kampagnen-Continue-Pfad. Das setzt Personal/Ressourcen/Vorbereitung ausdruecklich auf den letzten sicheren Basisstand zurueck. Der gescheiterte Ausflug wird nicht gespeichert. Vor Continue liegt das Schiff weiterhin am Einsatzort. Dies ist kein Rettungs-, Heilungs- oder Absturzsystem. Boarding-/Pilot-/Flugregeln auf dem gesunden Pfad und Skirmish bleiben erhalten.

Der optionale Live-AAR-Snapshot benoetigt einen fitten taktischen Selection-Anchor. Nach dem ersten Fix zeigte der echte All-down-Test in dieser optionalen Abfrage die vorhandene Rekursion `_resolve_fireteam_leader_for_behavior` <-> `_get_selection_anchor_for_fireteam`. Ausschliesslich fuer den terminalen Failed-Extraction-Ergebniszweig wird deshalb dieser optionale Live-Snapshot ausgelassen; echte `team_states`, der CombatLoopDriver-Ergebnisdatensatz und die medizinische Progression bleiben erhalten. Kein allgemeiner Tactical-Refactor.

## Regression und Nachweis

`campaign_casualty_debrief_retry_test.gd` verwendet den vorhandenen echten Vorbereitungs-/Boarding-Walk und Outbound-/Lande-Treiber. Erst nach echter Landung setzt die gezielte Schadensfixture die realen Simulationseinheiten auf 0 HP und loest CombatLoopDriver auf:

1. Beide echten NPCs ausgefallen, aufgeloeste Niederlage.
2. Lebender Pilot, ausgefallener anderer Boden-NPC, aufgeloester taktischer Sieg mit unmoeglicher Extraktion.

Beide pruefen Freigabe der Mission ohne Pending-Retry, sichtbaren Debrief, beide Personen/medizinische Progression, fehlgeschlagenen Auftrag, keine Belohnung/keinen Rueckflug-Fuelabzug/keinen erfundenen Heimtransfer, idempotente erneute Ergebniszustellung plus Service-Ticks, bytegleich erhaltenen Checkpoint, sichtbare primaere Checkpoint-Aktion und deren echte Szenen-Neuladung durch Continue, genau zwei wiederhergestellte Personen und unveraenderte Skirmish-Profilbytes.

RED: `casualty_logs/red.log` und `red_excerpt.err` zeigen sechs direkte Produktfehler auf unveraendertem Runtimecode; anschliessend wurde der weiterhin gehaltene All-down-Missionsprozess wegen wiederholter Tactical-Rekursion gestoppt. Der Stack-Auszug ist explizit begrenzt; voller repetitiver Rohlog bleibt unter `.scratch/casualty-red2.err`.

GREEN: **56 bestanden, 0 fehlgeschlagen**, finale Runtimequellen; `casualty_logs/green.log` und `green.err`. Keine Script-/Runtimefehler. Zwei vorhandene UID-Fallback-Warnungen aus `homebase_test_screen.tscn` bleiben sichtbar und getrennt vom Ergebnis. `git diff --check` fuer die bearbeiteten getrackten Dateien bestanden (nur CRLF/LF-Hinweise).

Befehl: `godot_console.exe --headless --path . --script res://scripts/tests/campaign_casualty_debrief_retry_test.gd`. Frisches privates APPDATA `.scratch/casualty-final-profile`, Hintergrund/Hidden, Prozessprioritaet BelowNormal; keine sichtbaren Fenster, CUA oder Fokuswechsel.

## Dateiumfang und Grenzen

Runtime: `scripts/meta/meta_layer_flow.gd`, `scripts/meta/debrief_screen.gd`. Regression: `scripts/tests/campaign_casualty_debrief_retry_test.gd`. Verhaltensvertrag: `docs/dev/campaign_introduction_contract.md`. Dieser Bericht und begrenzte Logs. Bestehende fremde Helper-/Format-/QA-Aenderungen erhalten. Breiter gesunder Zweiausflug und Skirmish wurden hier nicht erneut ausgefuehrt; die schon vorliegende separate Happy-Path-Evidenz wird nicht als neuer Test ausgegeben. Root uebernimmt Aggregate, Commit, Scoped-Re-Review und Buildintegration.
