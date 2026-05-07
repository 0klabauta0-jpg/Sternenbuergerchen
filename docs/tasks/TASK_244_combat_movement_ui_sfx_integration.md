# TASK_244 - Combat Movement UI SFX Integration

## Ziel
Die Audio-Events aus TASK_243 sollen in die tatsaechlichen Spielablaeufe eingebunden werden: Button-Klicks, Waffenfeuer, Muzzle-Flash, Treffer/Impacts, Explosionen und Bewegungsschritte fuer Spieler-NPCs und Gegner-NPCs.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_200 - Enemy Team Tactics Contract and Current-State Audit
- TASK_204 - Enemy Fire Direction LOS and Engagement Readability
- TASK_205 - Muzzle Flash Particle Effects
- TASK_226 - Main Menu Settings Shell Display Audio Input Gameplay
- TASK_243 - Audio Event Contract and Bus Setup

## Kontext
Sound muss die bereits geplante taktische Lesbarkeit unterstuetzen. Waffenreichweite, Blickrichtung, Feuerrichtung, Deckung, FoW und Multiplayer duerfen durch Audio nicht veraendert werden, aber Audio soll klar zeigen, was gerade passiert.

## Umfang
1. UI-Sounds:
   - Hauptmenue, Einstellungen, Multiplayer Host/Join, Editor, Lobby und wichtige HUD-Buttons.
   - Click, hover/focus optional, switch/toggle, confirm/cancel, disabled/warning.
   - Keine Dauerbeschallung bei Listen oder Slider-Drag.
2. Combat-Sounds:
   - SMG, Rifle, LMG, Sniper, Rocket/Explosion als erste Event-Gruppen.
   - Friendly und Enemy nutzen dieselbe Event-Schicht.
   - Muzzle-Flash aus TASK_205 und Schuss-Sound werden ueber denselben visuellen Feuerpunkt plausibel synchronisiert.
   - Treffer/Impact und Explosionen bekommen eigene Events.
3. Bewegung:
   - Walk/Run-Schritte fuer NPC-Proxies.
   - Grobe Surface-Auswahl: metal/indoor, sand/rock, neutral.
   - Rate-Limit, damit mehrere NPCs nicht unkontrolliert stapeln.
4. FoW/Sichtbarkeit:
   - Sichtbare Schuesse normal.
   - Nicht sichtbare, aber hoerbare Events optional gedaempft oder als Richtungs-/Kontakt-Hinweis.
   - Komplett unbekannte Bereiche duerfen keine exakten visuellen Informationen verraten.
5. Multiplayer:
   - Audio-Events aus autoritativen Aktionen/Snapshots ableiten.
   - Clients erzeugen keine eigene Wahrheit.
   - Gleiche Aktion darf nicht doppelt lokal und aus Snapshot abgespielt werden.
6. Diagnose:
   - Pro Mission Zaehler fuer UI, Combat, Movement, Impact, Explosion.
   - Missing-Audio-IDs und unterdrueckte Polyphony sichtbar.

## Nicht-Ziele
- Keine finale Audio-Mischung.
- Keine Musik oder lange Ambiences.
- Kein kompletter Stealth-/Hearing-Gameplay-Modus.
- Keine neuen Waffenwerte ausser Event-Zuordnung.

## Akzeptanzkriterien
- [x] Button-Klicks und zentrale UI-Aktionen loesen projektlokale UI-Audio-Events aus.
- [x] Friendly- und Enemy-Schuesse loesen passende Waffen-Events aus.
- [x] Muzzle-Flash und Schuss-Sound nutzen denselben Ereigniskontext.
- [x] Schritte laufen nur bei sichtbarer/bewegter Unit und sind rate-limited.
- [x] Explosionen/Impacts loesen eigene Events aus.
- [x] FoW und Multiplayer verhindern doppelte oder informationell falsche Audio-Ausgaben.
- [x] Ein Verifier prueft Event-Zaehler, fehlende IDs, Settings-Mute und Multiplayer-Deduplizierung.

## Erwartete Dateien
- `scripts/audio/audio_event_bus.gd`
- `scripts/ui/...`
- `scripts/combat/...`
- `scripts/visualization/terrain_map_3d_view.gd`
- `scripts/tests/task_244_combat_movement_ui_sfx_integration_verifier.gd`
- `docs/manual_checks/audio_sfx_playability_checklist.md`
- `docs/tasks/TASK_244_combat_movement_ui_sfx_integration.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_244_combat_movement_ui_sfx_integration_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_160_tactical_playability_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_168_multiplayer_snapshot_contract_verifier.gd`
- [ ] Manueller Audio-Sicht-/Hoercheck.
- [x] `git diff --check`

## Umsetzung
- `AudioEventBus` bietet jetzt Runtime-Helfer fuer UI, Waffenfeuer, Movement-Steps, Impacts und Explosionen sowie Dedupe- und Kategorie-Diagnostik.
- Hauptmenue und Multiplayer-Lobby melden zentrale Click/Confirm/Switch/Cancel/Warning-Aktionen, ohne Slider-Drag zu vertonen.
- `TerrainMap3DView` spielt sichtbares Waffenfeuer am Muzzle-Flash-Kontext und sichtbare bewegte Unit-Schritte mit per-Unit-Rate-Limit.
- `MissionCombatLoopDriver` meldet Impact- und Rocket-Explosion-SFX aus autoritativ angewandtem Damage-Kontext.
- `SimulationRoot` kann Fire-Events aus akzeptierten Multiplayer-Snapshots read-only an einen vorhandenen Audio-Bus weitergeben und dedupliziert ueber Fire-Event-IDs.
- `docs/manual_checks/audio_sfx_playability_checklist.md` haelt den Fenster-Hoercheck fest.

## Risiken
- Zu viele gleichzeitige NPC-Schritte oder Schuesse koennen nerven und Performance kosten.
- FoW-Audio darf dem Spieler nicht mehr verraten als das Regelwerk erlaubt.
- UI-Sounds koennen schnell aufdringlich werden, wenn Hover/Focus zu breit aktiviert wird.

## Naechster Schritt
Nach TASK_244 sollte TASK_248 einen Import-/Playback-Smoke ueber alle neuen Audio-Pfade laufen lassen.
