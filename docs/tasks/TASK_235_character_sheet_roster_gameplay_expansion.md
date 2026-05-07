# TASK_235 - Character Sheet Roster Gameplay Expansion

## Ziel
Das Charakterbogensystem soll vom reinen Werteblatt zu einer spielbaren Character-Gameplay-Ansicht wachsen: Skills, Traits, Rollen, Badges, Beziehungen, Fireteam-Historie, Missionserfahrung, Verletzung/Recovery und Stimmung.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_049 - Heimatbasis Skills UI
- TASK_096 - Recovery Loop
- TASK_164 - UI Theme and Component Library
- TASK_179 - Homebase Drop Light Fixed FullHD Layout
- TASK_207 - NPC Rank Skill Badge Derivation
- TASK_233 - Portrait Identity Catalog and Roster Presentation
- TASK_234 - Persistent Player Roster Save and Reset

## Kontext
`MetaUnitProfile` und `CharacterSheetView` koennen bereits viele Werte darstellen. Fuer Character-Gameplay braucht das Sheet aber mehr Kontext: Was hat diese Person erlebt? Mit wem arbeitet sie gut? Warum ist sie frustriert? Welche Rolle passt ihr?

## Umfang
1. Sheet-Struktur:
   - Identity/Portrait.
   - Top-3 Badges.
   - Kernwerte.
   - Traits.
   - Rolle/Loadout.
   - Status/Recovery.
   - Beziehung/Teamfit.
   - Progress/Mission-Historie.
2. Roster-Ansicht:
   - 20 bis 30 NPCs scanbar halten.
   - Sortieren/Filtern nur minimal, z. B. Rolle oder Status.
   - Nicht alle langen Details auf einmal zeigen.
3. Statusdaten:
   - injured, recovering, active, unavailable, training/resting als V1-Status vorbereiten.
   - Keine falsche Gameplaywirkung ohne Resolver.
4. Beziehungsvorschau:
   - Sympathien/Asympathien aus TASK_236 anzeigen, falls vorhanden.
   - Fireteam-Historie und Cohesion kurz darstellen.
5. Text:
   - Knapp, taktisch, keine Romanseite.
   - Relevante Hinweise fuer Teamwahl statt reiner Flavor.
6. Verifier:
   - Sheet rendert 30 Profile ohne Layoutbruch.
   - Missing Portrait/Badge-Fallbacks.
   - Status/Relationship-Felder optional, aber stabil.

## Nicht-Ziele
- Kein komplettes RPG-Menue.
- Kein Drag-and-Drop-Rework.
- Keine Progressionsformeln.
- Kein Relationship-Gameplay, das folgt in TASK_236.

## Umsetzung
- `MetaUnitProfile` fuehrt optionale V1-Character-Gameplay-Felder: `availability_status`, `recovery_state`, `relationship_summary_text`, `relationship_links`, `fireteam_history`, `mission_history` und `progression`.
- `StartRosterGenerator` initialisiert neue NPCs mit aktivem Status, leerer Mission-Historie, Fireteam-Vorschlagshistorie und neutralen Morale-/Frustration-Werten.
- `CharacterSheetFormatter` und `CharacterSheetView` rendern kurze Bloeke fuer Rolle/Loadout, Status/Recovery, Teamfit und Progress zusaetzlich zu Portrait, Traits, Skills und Badges.
- Homebase-Rosterkarten bleiben kompakt und zeigen Status plus Standort in einer scanbaren Kurzzeile.
- Homebase und FOB akzeptieren denselben Profil-Payload; fehlende Relationship-/Progress-Felder haben stabile Fallbacks.

## Akzeptanzkriterien
- [x] Character Sheet zeigt Identity, Skills, Traits, Badges, Status und Progress-Felder.
- [x] Roster mit 20 bis 30 NPCs bleibt scanbar.
- [x] Missing Portrait/Badge/Relationship-Daten brechen UI nicht.
- [x] Homebase/FOB nutzen dieselben Profile.
- [x] Ein TASK_235-Verifier prueft Sheet/Roster-Rendering und Datenfallbacks.

## Erwartete Dateien
- `scripts/meta/meta_unit_profile.gd`
- `scripts/meta/character_sheet_formatter.gd`
- `scripts/meta/character_sheet_view.gd`
- `scripts/meta/homebase_screen.gd`
- `scripts/meta/fob_screen.gd`
- `scripts/tests/task_235_character_sheet_roster_gameplay_expansion.gd`
- `docs/tasks/TASK_235_character_sheet_roster_gameplay_expansion.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --import`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_235_character_sheet_roster_gameplay_expansion.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_179_homebase_drop_light_fixed_fullhd_layout_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_176_fob_loadout_weapon_preview_selector_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_207_npc_rank_skill_badge_derivation.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_234_persistent_player_roster_save_and_reset.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_232_start_roster_generation_contract.gd`
- [ ] Manueller Homebase/FOB-Sichtcheck mit 24+ NPCs.
- [x] `git diff --check`

## Risiken
- Zu viele Werte machen das Sheet unlesbar. Es braucht Prioritaet und knappe Darstellung.
- UI darf keine Gameplay-Wahrheit speichern.

## Naechster Schritt
Nach TASK_235 kann TASK_236 Beziehungen und Fireteam-Cohesion modellieren.
