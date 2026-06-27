# Contact Report Contract

## Zweck
Contact Reports beschreiben Feindwissen fuer UI, Preview und Event-Log, ohne daraus perfekte Gegnerwahrheit zu machen.

`ContactTracker` bleibt die missionslokale Kontaktquelle. UI, HUD, Primary-View und Threat-Preview lesen Snapshots nur read-only und committen keine Kontakte, Positionen oder Combat-Entscheidungen.

## Snapshot-Felder
- `fireteam_id`: Fireteam, fuer das der Kontakt bekannt ist.
- `unit_id` / `target_id`: bekannte oder relayed Ziel-ID.
- `team_id`: gegnerisches Team, falls bekannt.
- `enemy_type`: grobe Typinformation, z. B. Rolle, Spezialwaffe oder `unknown`.
- `last_known_position`: letzte tatsaechlich vom Tracker bekannte Position.
- `approximate_position`: gerasterte Spieler-/UI-Position, wenn Confidence nicht hoch genug ist.
- `position_uncertainty_world`: grobe Unsicherheit in World-Units.
- `detection_state`: `spotted`, `confirmed`, `suspected` oder `lost`.
- `report_state`: `current`, `last_known` oder `stale`.
- `confidence`: 0.0 bis 1.0.
- `confidence_level`: `low`, `medium` oder `high`.
- `last_seen_tick`, `last_seen_age_ticks`, `last_seen_age_seconds`: Alter der letzten Sichtung.
- `report_text`: kurze HUD-/Event-Log-Meldung.
- `read_only`: immer `true`.
- `ui_sets_gameplay_truth`: immer `false`.

## Regeln
- Preview- und UI-Systeme duerfen aus Contact Reports Risiken und Lesbarkeit ableiten, aber keine Gegner bewegen, entdecken oder bestaetigen.
- `last_known_position` bleibt die Trackerdatenlage; `approximate_position` ist nur eine Anzeige-/Preview-Abstraktion.
- Stale-Kontakte bleiben sichtbar, wenn FoW/Overlay das erlaubt, muessen aber als unsicher erkennbar sein.
- Event-Log-Meldungen werden aus Contact-Snapshot-Aenderungen abgeleitet und sind visual-only.

## Nicht-Ziele
- Keine neue FoW-Wahrheit.
- Kein Combat-Rewrite.
- Keine neue Gegner-KI.
- Keine perfekte Enemy-Typ-Erkennung.
