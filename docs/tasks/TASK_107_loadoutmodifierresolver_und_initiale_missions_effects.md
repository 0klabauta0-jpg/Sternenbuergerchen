# TASK_107 – LoadoutModifierResolver und initiale Missions-Effects

## Ziel
FOB-Staging erzeugt beim Missionsstart `UnitLoadoutModifiers`, die als initiale Effects ueber den autoritativen Missionspfad auf die Units wirken.

## Status: IMPLEMENTIERT

## Pflicht vor Beginn
- Lies [docs/PROJECT_BRIEF.md](docs/PROJECT_BRIEF.md)
- Lies [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
- Lies [docs/CODEX_RULES.md](docs/CODEX_RULES.md)
- Lies [docs/IMPLEMENTATION_STATUS.md](docs/IMPLEMENTATION_STATUS.md)
- Lies [docs/tasks/TASK_087_loadout_pipeline_waffen_sprites.md](docs/tasks/TASK_087_loadout_pipeline_waffen_sprites.md)
- Lies [TASK_106 – Dropship-LZ, Insertion und verzoegerte Aktivierung](docs/tasks/TASK_106_dropship_lz_insertion_und_verzoegerte_aktivierung.md)
- Pruefe den Git-Status

## Aufgabe

### 1. `LoadoutModifierResolver`
- Liest `weapon_1`, `weapon_2` und `armor` aus dem bestehenden FOB-Staging.
- Erzeugt pro Unit ein `UnitLoadoutModifiers`-Objekt.

### 2. Vorgeschlagene Waffenformeln
- `smg`:
  - `accuracy_mod = -0.06`
  - `speed_mod = +0.12`
  - `toughness_mod = +0.00`
  - `cover_mod = +0.04`
  - `range_class = "short"`
- `rifle`:
  - `accuracy_mod = +0.04`
  - `speed_mod = +0.00`
  - `toughness_mod = +0.00`
  - `cover_mod = +0.02`
  - `range_class = "medium"`
- `special`:
  - `accuracy_mod = +0.02`
  - `speed_mod = -0.05`
  - `toughness_mod = +0.06`
  - `cover_mod = +0.06`
  - `range_class = "any"`

### 3. Armor-Richtlinien
- `light`:
  - `speed_mod = +0.15`
  - `toughness_mod = -0.08`
  - `cover_mod = -0.05`
- `medium`:
  - alle Mods `0.00`
- `heavy`:
  - `speed_mod = -0.14`
  - `toughness_mod = +0.15`
  - `cover_mod = +0.10`

### 4. Missionsstart-Anwendung
- Modifikatoren werden additiv auf Basiswerte gerechnet.
- Anwendung erfolgt ueber initiale Commands oder Effects beim Missionsstart.
- Keine direkte Mutation aus Meta- oder UI-Skripten an `TestUnit`.

## Nicht-Ziele
- keine freie Waffenballistik
- kein Inventarsystem
- keine kontextabhaengige Sonderwaffen-Matrix ueber den ersten Slice hinaus

## Akzeptanzkriterien
- FOB-Staging wird in `UnitLoadoutModifiers` uebersetzt.
- Die vorgeschlagenen Waffen- und Armor-Formeln sind umgesetzt oder dokumentiert uebernehmbar.
- Die Modifikatoren werden additiv und autoritativ zum Missionsstart angewandt.
- Keine Meta-UI schreibt direkt auf Units.
