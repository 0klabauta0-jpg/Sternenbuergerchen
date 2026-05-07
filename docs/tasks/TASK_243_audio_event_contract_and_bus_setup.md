# TASK_243 - Audio Event Contract and Bus Setup

## Ziel
Die kuratierten Sounds aus TASK_242 sollen ueber einen stabilen Audio-Event-Vertrag abgespielt werden. UI, Kampf, Bewegung und kurze Effekte brauchen klare Audio-IDs, Bus-Routing, Lautstaerke-Regeln, Pooling und Settings-Anbindung.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_242 - Audio SFX Source Inventory and Curated Import
- TASK_226 - Main Menu Settings Shell Display Audio Input Gameplay
- TASK_227 - Main Menu Multiplayer Host Join Lobby Flow

## Kontext
Sound darf nicht ad hoc direkt aus UI-, Combat- oder NPC-Code geladen werden. Sonst entstehen doppelte Pfade, unkontrollierte Lautstaerke und Multiplayer-Sonderfaelle. Ein kleiner Event-Vertrag reicht: Gameplay meldet ein Ereignis, die Audio-Schicht entscheidet ueber Resource, Bus, Variante, Cooldown, Spatial/Non-Spatial und Settings.

## Umfang
1. Audio-Event-Datenmodell:
   - `audio_id`, Kategorie, Bus, Resource-Pfade, Variante, Basislautstaerke, Pitch-Range.
   - One-Shot, looped, spatial, UI-only.
   - Cooldown/Polyphony-Limit pro Event.
2. Bus-Setup:
   - `Master`, `SFX`, `UI`, `Combat`, `Movement`, optional `Ambient`.
   - Settings-Slider aus TASK_226 anbinden.
   - Mute/Reduce-Option fuer Bubbles/Gedanken und UI-Klicks vorbereiten.
3. Runtime-Schicht:
   - Zentraler `AudioEventBus` oder vergleichbare Autoload-Komponente.
   - AudioStreamPlayer-/AudioStreamPlayer3D-Pooling.
   - Keine Resource-Loads pro Frame.
   - Diagnose-Snapshot fuer aktive Stimmen, fehlende IDs, unterdrueckte Events.
4. Multiplayer-Vertrag:
   - Audio bleibt lokale Darstellung.
   - Server-/Snapshot-Ereignisse duerfen Audio ausloesen, aber Audio setzt nie Gameplay-Wahrheit.
   - Relevante Events bekommen Event-Ort, Team/Unit-ID und Sichtbarkeitskontext.
5. Fallback-Regeln:
   - Fehlender Sound erzeugt Diagnosewarnung, aber keinen Missionsabbruch.
   - UI-Event ohne Sound darf still bleiben, wenn Settings stumm sind.

## Nicht-Ziele
- Keine finale Soundbalance.
- Keine komplette Musik-/Ambient-Engine.
- Keine Voiceover- oder Dialoganlage.
- Keine Gameplay-Logik in der Audio-Schicht.

## Akzeptanzkriterien
- [x] Ein zentraler Audio-Event-Vertrag laedt `data/audio_sfx_catalog.json`.
- [x] UI-, Combat-, Movement- und Explosion-Events haben stabile Audio-IDs.
- [x] Settings koennen Master/SFX/UI/Combat/Movement sinnvoll beeinflussen.
- [x] AudioStreamPlayer werden wiederverwendet oder begrenzt gepoolt.
- [x] Diagnose meldet fehlende IDs, fehlende Dateien, aktive Stimmen und unterdrueckte Polyphony.
- [x] Multiplayer-Snapshots koennen Audio-Ereignisse ausloesen, ohne SimulationState zu mutieren.

## Umsetzung
- `AudioEventContract` laedt den kuratierten SFX-Katalog, normalisiert Bus, Spatial-Flag, Cooldown, Polyphony und Read-only-Multiplayer-Kontext.
- `AudioEventBus` richtet `SFX`, `UI`, `Combat`, `Movement`, `Ambient` und `Music` ein, routet Kategorie-Busse in `SFX`, wendet Settings an und liefert Diagnose-Snapshots.
- `AudioEventPlayerPool` begrenzt und wiederverwendet `AudioStreamPlayer`/`AudioStreamPlayer3D`; Headless-Tests simulieren Playback ohne Audio-Leaks.
- `GameSettingsContract` unterstuetzt zusaetzlich `ui_volume`, `combat_volume`, `movement_volume` und `ambient_volume`; bestehende Master/Music/SFX-Settings bleiben kompatibel.
- `docs/dev/audio_event_contract.md` dokumentiert Runtime-Grenze, Bus-Routing, Pooling, Settings, Multiplayer-Sichtbarkeit und Fehlerverhalten.

## Erwartete Dateien
- `scripts/audio/audio_event_contract.gd`
- `scripts/audio/audio_event_bus.gd`
- `scripts/audio/audio_event_player_pool.gd`
- `data/audio_sfx_catalog.json`
- `docs/dev/audio_event_contract.md`
- `scripts/tests/task_243_audio_event_contract_and_bus_setup_verifier.gd`
- `docs/tasks/TASK_243_audio_event_contract_and_bus_setup.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_243_audio_event_contract_and_bus_setup_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_226_main_menu_settings_shell_display_audio_input_gameplay.gd`
- [x] `git diff --check`

## Risiken
- Audio-Pooling darf nicht zu vielen langlebigen Nodes fuehren.
- Zu viele Busse machen Settings unuebersichtlich.
- Multiplayer-Audio darf nicht als versteckte Gameplay-Signalquelle missverstanden werden.

## Naechster Schritt
TASK_244 schliesst die Events an UI, Waffen, Schritte, Explosionen und NPC-Aktionen an.
