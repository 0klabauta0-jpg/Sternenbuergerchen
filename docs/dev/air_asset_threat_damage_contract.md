# Air Asset Threat Damage Contract

## Scope
TASK_277 macht Dropships und Frachter als taktische Luft-/Transportassets lesbar bedrohbar. Der Contract ist bewusst keine Flugsimulation: Er definiert faire Threat-Gates, einen Status-Snapshot und einen `SimulationRoot`-Effect, damit UI und Tests nicht selbst Gameplay-Wahrheit setzen.

## Statusmodell
- `intact`: Asset ist verfuegbar.
- `threatened` / `locked`: Warnphase; der Spieler sieht eine Air-Risk-Warnung vor Schaden oder Verlust.
- `hit` / `damaged`: Trefferphase nach sichtbarer Warnung.
- `destroyed` / `crashed`: terminaler Verlust im Mission-Kontext.
- `recovering` / `unavailable`: Asset kann nicht gerufen werden, Meta-Folgen folgen in TASK_278.

`AirAssetStatus.to_snapshot()` enthaelt `runtime_authority = "SimulationRoot"` und `ui_sets_gameplay_truth = false`.

## Zielbarkeit
Nur explizit definierte Anti-Armor-Waffen duerfen Air Assets bedrohen:
- `rocket_launcher`
- `rail_gun`

`smg`, `rifle`, `sniper`, `medictool` und nicht bekannte Waffen erzeugen keine Air-Asset-Threat. Der Resolver respektiert:
- `range_tiles` gegen `WeaponData.get_effective_tile_range()`
- `has_line_of_sight`
- `visible_in_fow`
- `altitude_layer`; `safe`, `high`, `orbit`, `offmap` sind nicht verwundbar

## Fairness
Ein intaktes Asset wird beim ersten gueltigen Anti-Armor-Kontakt nur `threatened` oder `locked`. `hit`, `damaged`, `destroyed` oder `crashed` sind erst erlaubt, wenn bereits eine Warnung sichtbar war oder `warning_seen = true` gesetzt ist.

## LZ-Risiko
`lz_secure_level` senkt das Risiko. `enemy_at_pressure` und `enemy_security_pressure` erhoehen es. Die Mission-UI spiegelt den Zustand mit kompaktem Text:
- `AIR RISK`
- `DAMAGED`
- `LOST`

## Effects, VFX, SFX
Gueltige Threats erzeugen einen `air_asset_status_update`-Effect fuer `SimulationRoot`. Der Effect transportiert:
- `status_snapshot`
- `vfx_events` fuer Rocket/Trail, Hit/Explosion, Smoke/Debris
- `sfx_events` fuer Warning, Hit oder Explosion
- `ui_sets_gameplay_truth = false`

Die VFX/SFX-Payloads sind Contract-Payloads und duerfen spaeter von TASK_244-/TASK_205-Runtimes abgespielt werden.

## Kommunikation und Breakouts
Mission Controller spiegelt gueltige Threats in:
- `tactical_communication_events` mit `air_asset_threatened` oder `air_asset_destroyed`
- `tactical_breakouts` mit `air_asset_threatened` oder `air_asset_destroyed`
- `get_command_feedback_snapshot().air_asset_status`

UI zeigt den Status, aber setzt keine zerstoererische Wahrheit. Autoritative Speicherung laeuft ueber `SimulationRoot.get_air_asset_status_snapshot(asset_id)`.
