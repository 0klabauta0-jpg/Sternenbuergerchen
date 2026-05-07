# TASK_260 - Loadout Selection Decorative Weapons Weight Playability

## Ziel
Loadout-Auswahl und Gewicht sollen spielbar und logisch geprueft werden: echte Waffen sind waehbar, Zierwaffen bleiben nicht waehbar, "keine Waffe" ist erlaubt wo vorgesehen, Gewicht sinkt dann korrekt, und Werte/Previews/Socket-Visuals bleiben konsistent.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_086 - Waffenmodell WeaponData
- TASK_087 - Loadout-Pipeline und Waffen-Sprites
- TASK_107 - LoadoutModifierResolver und initiale Missions-Effects
- TASK_175 - NPC Loadout Attachments
- TASK_176 - FOB Loadout Weapon Preview Selector
- TASK_190 - Weapon Visual Loadout Expansion and Scale
- TASK_246 - Visual Scale Alignment Asset Pass
- TASK_256 - Automated Playability Coverage Contract
- TASK_259 - Character Card Roster Switching Playability

## Kontext
Neue Waffenvisuals und Zierwaffen koennen UI und Gameplay leicht durcheinanderbringen. Ein dekoratives Modell darf nicht automatisch als spielbare Waffe auftauchen. Umgekehrt muss eine echte Loadout-Option Werte, Gewicht, Preview, Mission-Visual und eventuell Multiplayer-Snapshot konsistent beeinflussen.

## Umfang
1. Loadout-Inventar:
   - Spielbare Waffen.
   - Medizin-/Tool-Items.
   - Zierwaffen/Visual-only-Assets.
   - "Keine Waffe"/leer, falls fuer Rolle oder Slot erlaubt.
2. Auswahlregeln:
   - Nur freigeschaltete/spiellogische Loadout-Items sind waehbar.
   - Zierwaffen erscheinen hoechstens als Preview/locked/visual-only, nicht als aktive Auswahl.
   - Nicht erlaubte Kombinationen bleiben disabled mit Grund.
3. Gewicht:
   - Gewicht wird aus aktueller Auswahl berechnet.
   - "Keine Waffe" reduziert Gewicht.
   - Medictool/Heavy/Sniper/Rocket haben erwartete Gewichtsauswirkung.
   - Character Card und Loadout-Panel zeigen denselben Wert.
4. Gameplay-Effekte:
   - Gewicht beeinflusst nur vorgesehene Stats/Modifiers.
   - Keine Auswahl erzeugt keine versteckte Waffe im Combat.
   - Visual-Loadout folgt Auswahl oder bewusstem Fallback.
5. UI-Playability:
   - Optionsliste scrollt bei vielen Items.
   - Preview passt in Slot/Fenster.
   - Wechsel zwischen NPCs aktualisiert Loadout korrekt.
6. Multiplayer/Snapshot:
   - Nur spielrelevante Loadout-Daten replizieren.
   - Visual-only-Daten bleiben lokal oder katalogbasiert.

## Nicht-Ziele
- Kein finales Waffenbalancing.
- Keine neuen Waffenmodelle importieren.
- Keine Inventarwirtschaft.
- Keine Munition-/Durability-Mechanik.

## Akzeptanzkriterien
- [x] Spielbare Loadout-Items und Zierwaffen sind eindeutig getrennt.
- [x] Zierwaffen koennen nicht versehentlich als aktive Waffen gewaehlt werden.
- [x] "Keine Waffe" funktioniert dort, wo erlaubt, und reduziert Gewicht.
- [x] Gewichtsanzeige in Loadout und Character Card bleibt konsistent.
- [x] Mission/Combat nutzt keine versteckten Waffen nach leerer Auswahl.
- [x] Preview/Sockets/Visuals bleiben projektlokal und skaliert.
- [x] Ein Verifier prueft Auswahl, Disabled-Gruende, Gewicht, Character Card, Mission-Snapshot und Report.

## Umsetzung
- `WeaponData` fuehrt `none` als explizites Gameplay-Loadout ohne Schaden, Preview, Visual-Loadout und Gewicht sowie Gewichtswerte fuer die bestehenden Waffen.
- `LoadoutModifierResolver` berechnet `loadout_weight`, erlaubt `none` als Range-Klasse und serialisiert nur gameplay-relevante Loadout-Daten.
- FOB-Loadout-Slots bieten `None`, zeigen Fireteam-/Member-Gewicht und verstecken Preview-Art fuer leere Slots.
- Character-Sheet-Rendering nutzt den berechneten Loadout-Text aus dem Screen-Kontext.
- `SimulationRoot` repliziert keine Active-Weapon-Felder, wenn die Einheit keine aktive Angriffwaffe hat.
- `TerrainMap3DView` deaktiviert Weapon-Visuals fuer zwei `none`-Slots absichtlich, ohne daraus Missing-Asset-Fehler zu machen.
- `docs/reports/playability_loadout_weight_report.md` und `docs/dev/loadout_playability_rules.md` dokumentieren Befund und Regeln.

## Erwartete Dateien
- `scripts/tests/task_260_loadout_selection_decorative_weapons_weight_playability.gd`
- `docs/reports/playability_loadout_weight_report.md`
- `docs/dev/loadout_playability_rules.md`
- `data/...`
- `scripts/meta/...`
- `scripts/tests/playability/playability_test_harness.gd`
- `docs/tasks/TASK_260_loadout_selection_decorative_weapons_weight_playability.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_260_loadout_selection_decorative_weapons_weight_playability.gd` (72/0)
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_176_fob_loadout_weapon_preview_selector_verifier.gd` (30/0)
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_190_weapon_visual_loadout_expansion_and_scale.gd` (48/0)
- [x] `godot_console.exe --headless --path . --script scripts/tests/test_weapon_data.gd` (24/0)
- [x] `git diff --check`

## Risiken
- Bestehende Loadout-Tests koennen UI-Auswahl und Gameplay-Auswirkung getrennt pruefen; dieser Task muss die Kette bewusst zusammenziehen.
- "Keine Waffe" darf nicht aus Versehen Combat-Nullrefs oder unsichtbare Defaultwaffen erzeugen.

## Naechster Schritt
TASK_261 prueft, ob ganze Spielwege und Screenwechsel keinen State verlieren.
