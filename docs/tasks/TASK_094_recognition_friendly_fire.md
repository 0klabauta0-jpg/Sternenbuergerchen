# TASK_094 – Recognition: Friendly-Fire-Verwechslung

## Ziel
Units mit niedrigem `recognition`-Wert koennen in bestimmten Situationen eigene Truppen
als Feinde misidentifizieren und auf sie schiessen.

## Status: OFFEN

## Kontext
- `test_unit.gd` hat `recognition` als Export (0.0–1.0, Default 0.5)
- `simulation_root.gd` (Zeile ~728): `allow_friendly_fire: false` blockiert aktuell **jeden** Friendly-Fire komplett
- `_find_first_contact_pair()` trennt friendly/enemy Listen sauber – es gibt keinen Mechanismus fuer Verwechslung
- Aktuell ist Friendly-Fire technisch moeglich (SimulationRoot unterstuetzt es), wird aber im Combat-Loop mit `allow_friendly_fire: false` unterdrueckt

## Mechanik
- Nur wenn `fire_status == "fire_at_will"` und Feind in Sicht
- Pro Tick bei Kontakt: `randf() < MISIDENTIFICATION_BASE_CHANCE * (1.0 - recognition)`
  - recognition=1.0 → 0% Verwechslungschance
  - recognition=0.0 → MISIDENTIFICATION_BASE_CHANCE (z.B. 3% pro Tick)
- Bei Verwechslung: naechstgelegene eigene Unit wird als Ziel gewaehlt
- Damage-Effect wird mit `allow_friendly_fire: true` gesendet
- Verwechslung wird als Event sichtbar ("UNIT verwechselt Ziel!")
- Moegliche Verstaerker: Nacht, Rauch, niedrige Sicht (spaetere Tasks)

## Implementierung
1. `mission_combat_loop_driver.gd`:
   - Neuer Check in `_try_enqueue_attacks()` nach Target-Auswahl
   - Misidentification-Roll: Ziel wird durch eigene Unit ersetzt
   - Effect mit `allow_friendly_fire: true` senden
   - Event-Text anzeigen
   - Cooldown pro Unit damit nicht Dauerfeuer auf Eigene

2. `test_unit.gd`: Getter `get_recognition()` sicherstellen

## Dateien (voraussichtlich betroffen)
- `scripts/tests/mission_combat_loop_driver.gd`
- `scripts/npc/test_unit.gd` (nur Getter, falls fehlend)

## Abhaengigkeiten
- Sinnvoll nach TASK_091 (Detection-Delay), da Awareness und Recognition zusammenspielen
- TASK_093 (Discipline) sollte vorher fertig sein, damit Hold-Fire und Friendly-Fire nicht kollidieren

## Akzeptanzkriterien
- [ ] Units mit recognition=1.0 verwechseln nie Ziele
- [ ] Units mit recognition=0.1 verwechseln gelegentlich eigene Units
- [ ] Friendly-Fire-Treffer werden korrekt ueber SimulationRoot mit allow_friendly_fire=true verarbeitet
- [ ] Verwechslungs-Event wird als Text sichtbar
- [ ] Cooldown verhindert Dauerfeuer auf Eigene
