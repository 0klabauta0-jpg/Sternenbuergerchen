# TASK_374 - Objective Countdown Indicator

## Ziel
Missionen mit Zeitlimit, Hold-Timer, Exfil-Fenster oder Objective-Countdown sollen einen klaren, kompakten Timer im Mission-HUD erhalten.

## Status: GEPLANT

## Sinnhaftigkeitscheck
Der Review-Punkt ist sinnvoll, aber nur fuer Szenarien mit echter Timer-Wahrheit. Das aktuelle Objective-System liefert Capture-State; ein Countdown darf nicht frei im HUD erfunden werden.

## Problem
Zeitkritische Missionsziele waeren ohne sichtbaren Timer schwer spielbar und schlecht planbar.

## Ursache
Objective-Snapshots enthalten Objective-Status, aber keinen einheitlichen Mission-Timer-/Countdown-Vertrag.

## Umfang
- Objective-/Scenario-Timer-Vertrag definieren: `countdown_seconds`, `timer_state`, `objective_id`, `source`.
- Anzeige nur sichtbar machen, wenn das Szenario einen Timer liefert.
- Farbe/Dringlichkeit ab Schwellenwerten, aber keine blinkende Dauerablenkung.
- Multiplayer-Snapshot-Kompatibilitaet pruefen.
- Kein Timer in Szenarien ohne Zeitlimit.

## Akzeptanzkriterien
- [ ] Timer erscheint nur bei valider Countdown-Quelle.
- [ ] Gruen/Gelb/Rot oder vergleichbare Dringlichkeit ist testbar und dezent.
- [ ] Objective-Capture-Snapshots bleiben kompatibel.
- [ ] Headless-Test prueft aktive, pausierte/fehlende und abgelaufene Timer.
- [ ] Mission-HUD-Layout bleibt fixed und nicht ueberlappt.

## Erwartete Dateien
- `scripts/core/objective_status.gd`
- `scripts/core/simulation_root.gd`
- `scripts/tests/mission_objective_status_view.gd`
- `scripts/tests/task_374_objective_countdown_indicator.gd`

## Lokale Pruefung
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_374_objective_countdown_indicator.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_279_lz_security_air_asset_tactical_playability_smoke.gd`
- [ ] `git diff --check`

## Risiken / offene Punkte
- Wenn Missionsszenarien noch keinen Timer speichern, braucht dieser Task zuerst einen minimalen Scenario-Vertrag statt eine HUD-only Uhr.

