# Audio Event Contract

## Ziel
Audio ist eine lokale Darstellungsschicht. Gameplay-, Missions- und Multiplayer-State bleiben bei `SimulationRoot`, Registries und den bestehenden Runtime-Systemen. Code meldet nur ein Audio-Ereignis; die Audio-Schicht entscheidet Resource, Bus, Lautstaerke, Pitch, Cooldown, Polyphony und Sichtbarkeit.

## Quellen
- Katalog: `res://data/audio_sfx_catalog.json`
- Curated Assets: `res://Assets/used/audio/kenney_all_in_one/`
- Runtime-Vertrag: `res://scripts/audio/audio_event_contract.gd`
- Runtime-Node: `res://scripts/audio/audio_event_bus.gd`
- Player-Pool: `res://scripts/audio/audio_event_player_pool.gd`

## Event-Modell
Ein Event nutzt entweder eine stabile `event_id` wie `ui_click`, `combat_blaster`, `movement_footstep_neutral` oder eine explizite `audio_id`. Der Katalog bleibt die einzige Quelle fuer Projektpfade. Runtime-Code darf keine lokalen User-Pfade oder direkte Pack-Pfade referenzieren.

Der normalisierte Eintrag enthaelt:
- `audio_id`
- `planned_event`
- `category`
- `bus_name`
- `path`
- `default_volume_db`
- `random_pitch_range`
- `spatial`
- `cooldown_msec`
- `polyphony_limit`
- `ui_only`

## Busse
Die Audio-Schicht stellt bei Initialisierung sicher, dass diese Busse existieren:
- `Master`
- `Music`
- `SFX`
- `UI`
- `Combat`
- `Movement`
- `Ambient`

Routing:
- `Music -> Master`
- `SFX -> Master`
- `UI`, `Combat`, `Movement`, `Ambient -> SFX`

Settings aus TASK_226 bleiben kompatibel: `master_volume`, `music_volume` und `sfx_volume` wirken weiterhin. TASK_243 ergaenzt Kategorie-Multiplikatoren `ui_volume`, `combat_volume`, `movement_volume` und `ambient_volume`, damit UI, Kampf und Bewegung spaeter getrennt abgestimmt werden koennen.

## Pooling
`AudioEventPlayerPool` verwaltet begrenzte Pools fuer `AudioStreamPlayer` und `AudioStreamPlayer3D`. Der Bus laedt Streams ueber den Katalog und spielt keine Resource direkt aus UI-, Combat- oder NPC-Code.

Defaults:
- 16 nicht-spatiale Player
- 12 spatiale Player
- Polyphony-Limits pro Event aus dem normalisierten Katalog
- Cooldowns pro Event, damit UI-Klicks, Schritte und Explosionen nicht spammen

## Multiplayer
Audio-Payloads aus Snapshots sind read-only:
- `read_only_audio_event = true`
- `audio_sets_gameplay_state = false`
- `mutates_simulation_state = false`

Snapshot-Ereignisse duerfen lokal Audio ausloesen, wenn sie fuer den lokalen Client hoerbar/sichtbar sind. `visible_to_local = false`, `visibility_context = hidden`, `unseen` oder `fog_hidden` unterdruecken die Ausgabe. Dadurch kann FoW/Multiplayer spaeter verhindern, dass Audio mehr verraet als der Sichtbarkeitsvertrag erlaubt.

TASK_244 nutzt `dedupe_key` und `dedupe_window_msec`, damit dieselbe autoritative Aktion nicht einmal lokal und danach erneut aus einem Snapshot gespielt wird. Fire-Events verwenden ihre `event_id` als Dedupe-Schluessel; sichtbare Muzzle-Flash-VFX und Schuss-SFX teilen denselben Fire-Event-Kontext.

## Runtime-Hooks
Der Bus bietet Convenience-Methoden fuer Integrationscode:
- `emit_ui_action()`
- `emit_weapon_fire()`
- `emit_impact()`
- `emit_explosion()`
- `emit_movement_step()`

UI-, Combat-, Movement-, Impact- und Explosion-Code melden nur Ereignisse. Die Mapping-Entscheidung fuer konkrete Audio-IDs bleibt im Katalog und im Bus.

## Fehlerverhalten
Fehlende IDs, fehlende Ressourcen, Cooldown-Unterdrueckung, Polyphony-Unterdrueckung, Dedupe-Unterdrueckung und Settings-/Sichtbarkeitsunterdrueckung landen im Diagnose-Snapshot. Eine fehlende Audio-Datei bricht keine Mission ab.
