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

## Beobachter und Relays (Review 2, 2026-11-02)
- `ContactTracker.update()` aggregiert die Beobachtungen je Fireteam/Ziel vor
  der Anwendung: `detection_complete` per OR und vorhandene Confidence-Hinweise
  per Maximum. Ein unvollstaendiger Observer stuft damit die vollstaendige
  Beobachtung eines anderen Observers desselben Updates nicht zurueck.
- LOS-Dauer waechst einmal pro aufeinanderfolgendem Simulationstick. Erneute
  Anwendung im selben Tick erhaelt LOS-Zaehler und bereits erreichte Detection-
  Vollstaendigkeit. Eine echte LOS-Luecke setzt den Kontakt auf `lost`; nach
  Wiederaufnahme beginnt die LOS-Bestaetigung erneut.
- Erneute bestaetigte Sichtung aktualisiert den Payload eines wartenden Relays,
  behaelt aber dessen frueheste Faelligkeit. Die bestehende Leadership-Verzoegerung
  bleibt erhalten; ein bereits wartender Bericht wird auch nach Sichtverlust
  mit der zuletzt tatsaechlich beobachteten Position und deren Tick zugestellt.
- Hat der Empfaenger im Zustelltick direkte `spotted`-/`confirmed`-Sicht, erhaelt
  das Relay dessen eigenen LOS-Zaehler, Detection-State und Position. Es ergaenzt
  nur die `detected_by`-Herkunft; ohne direkte Sicht bleibt der Relay-Pfad
  vermutetes Kontaktwissen (`suspected`).

## Nicht-Ziele
- Keine neue FoW-Wahrheit.
- Kein Combat-Rewrite.
- Keine neue Gegner-KI.
- Keine perfekte Enemy-Typ-Erkennung.
