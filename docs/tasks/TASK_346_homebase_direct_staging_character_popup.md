# TASK_346 - Homebase Direct Staging Character Popup

## Ziel
Wenn der FOB fuer den ersten Gameplay-Flow umgangen wird, soll die Homebase die wichtigsten FOB-Staging-Funktionen direkt anbieten:

- `#10 FIRETEAMS`
- `#13 LOADOUT`
- bestehendes Homebase-Flightdeck als Boarding-/Dropship-Ziel

Die bisher rechts standardmaessig sichtbare Charakterkarte soll nicht mehr als normales festes Homebase-Fenster erscheinen. Der Charakterbogen wird nur noch per Doppelklick auf eine NPC-/Operator-Karte als frei schwebendes Popup-Fenster geoeffnet, ausserhalb der normalen nummerierten Fenster.

## Status: IMPLEMENTIERT

## Ausgangslage
- `scripts/meta/drop_light_layout_contract.gd` definiert fuer Homebase aktuell ein rechtes `character_sheet`-Fenster.
- `scripts/meta/homebase_screen.gd` rendert dieses Fenster als `InfoPanel` und nutzt `CharacterSheetView` darin.
- `scripts/meta/fob_screen.gd` hat bereits die festen FOB-Fenster `#10 FIRETEAMS`, `#13 LOADOUT` und Flightdeck-/Dropship-Staging.
- `scripts/meta/npc_compact_card.gd` kann per Doppelklick eine Character-Sheet-Anfrage ausloesen.
- TASK_316 sichert bereits ab, dass kompakte NPC-Karten das Character Sheet auch in Staging-Kontexten oeffnen koennen.

## Umfang

### 1. Homebase-Layout fuer direkten Staging-Flow
- Entferne die rechts dauerhaft sichtbare Character-Sheet-Flache aus dem normalen Homebase-Fensterlayout.
- Nutze den frei werdenden Platz fuer direkte Staging-Fenster.
- Die Homebase bekommt ein sichtbares `#10 FIRETEAMS`-Fenster.
- Die Homebase bekommt ein sichtbares `#13 LOADOUT`-Fenster.
- Das bestehende Homebase-Flightdeck bleibt als Flightdeck/Boarding-Ziel erhalten und wird in den direkten Staging-Flow eingebunden.
- Fenster bleiben im festen Drop-Light-/FullHD-Layout, ohne ueberlappende oder springende Panels.

### 2. Fireteam-Auswahl in der Homebase
- Fireteam-Karten und Member-Reihen sollen in der Homebase sichtbar und bedienbar werden.
- Bestehende Fireteam-/Roster-Datenpfade wiederverwenden.
- Keine zweite Fireteam-Wahrheit in der UI erzeugen.
- Drag-and-Drop oder gleichwertige bestehende Auswahlpfade duerfen nur Meta-Staging-State setzen.

### 3. Loadout in der Homebase
- `#13 LOADOUT` soll die kompakte Loadout-Bearbeitung aus dem FOB-Kontext in der Homebase verfuegbar machen.
- Fireteam-/Member-Loadout soll denselben Vertragsdaten folgen wie im FOB.
- Loadout-Aenderungen duerfen nicht als parallele Gameplay-Wahrheit in der UI gespeichert werden.

### 4. Flightdeck / Dropship-Staging
- Fireteams sollen aus der Homebase direkt dem Dropship/Flightdeck zugewiesen werden koennen.
- Bestehende Dropship-/Payload-/Pilot-Pfade wiederverwenden.
- Der Flow soll sich fuer den spaeteren Mission-Start so verhalten, als kaemen die Daten aus dem FOB-Staging.
- Das FOB selbst wird in diesem Task nicht geloescht; es wird nur fuer den direkten Homebase-Flow umgangen.

### 5. Character Sheet als Popup
- Der Charakterbogen ist standardmaessig geschlossen.
- Doppelklick auf eine NPC-/Operator-Karte oeffnet ein Popup-Fenster mit `CharacterSheetView`.
- Das Popup liegt ausserhalb der normalen nummerierten Fenster und ist nicht Teil des festen Homebase-Window-Rasters.
- Popup muss schliessbar sein.
- Popup darf die festen Fenster nicht verschieben.
- Popup soll innerhalb des Viewports bleiben und keine wichtigen Controls dauerhaft verdecken.
- Doppelklick soll aus relevanten Kartenkontexten funktionieren:
  - Homebase-Roster.
  - `#10 FIRETEAMS`.
  - `#13 LOADOUT`.
  - Flightdeck-/Dropship-Karten, sofern dort NPC-/Member-Karten sichtbar sind.

## Nicht-Ziele
- Kein Entfernen des FOB-Screens.
- Kein neues Fireteam- oder Loadout-Datenmodell.
- Kein neues MissionStart-/Dropship-System.
- Kein Umbau der SimulationRoot-Wahrheit.
- Keine finale Art-Direction fuer alle Panel-Proportionen.
- Kein Character-Sheet-Redesign, ausser es ist fuer Popup-Tauglichkeit minimal noetig.

## Akzeptanzkriterien
- [x] Homebase zeigt kein dauerhaftes rechtes Character-Sheet-Fenster mehr.
- [x] Homebase zeigt `#10 FIRETEAMS`.
- [x] Homebase zeigt `#13 LOADOUT`.
- [x] Das bestehende Homebase-Flightdeck bleibt sichtbar und kann Fireteam-/Dropship-Staging aufnehmen.
- [x] Doppelklick auf NPC-/Operator-Karten oeffnet ein Character-Sheet-Popup.
- [x] Das Popup liegt ausserhalb der normalen nummerierten Fenster.
- [x] Das Popup kann geschlossen werden, ohne Layout oder Auswahlzustand zu verlieren.
- [x] Die festen Fenster bewegen sich nicht, wenn das Popup geoeffnet oder geschlossen wird.
- [x] Homebase-Staging nutzt bestehende Fireteam-, Loadout- und Dropship-State-Pfade.
- [x] Headless-Verifier prueft Layout, Popup-Verhalten und Staging-Vertrag.

## Erwartete Dateien
- `scripts/meta/drop_light_layout_contract.gd`
- `scripts/meta/homebase_screen.gd`
- `scripts/meta/fob_screen.gd`
- `scripts/meta/npc_compact_card.gd`
- `scripts/meta/fob_fireteam_card.gd`
- `scripts/meta/character_sheet_view.gd`
- `scripts/meta/ui_block_labels.gd`
- `scripts/tests/task_346_homebase_direct_staging_character_popup.gd`
- `docs/tasks/TASK_346_homebase_direct_staging_character_popup.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_346_homebase_direct_staging_character_popup.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_316_fob_fireteam_staging_migration.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_314_fob_npc_pool_window_left_of_fireteams.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_310_fob_flightdeck_fireteam_userology_smoke.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_179_homebase_drop_light_fixed_fullhd_layout_verifier.gd`
- [x] `git diff --check`

## Umgesetzt
- `DropLightLayoutContract` entfernt das feste Homebase-`character_sheet` aus dem nummerierten Raster und reserviert den Bereich fuer `#10 FIRETEAMS`, `#13 LOADOUT` und das vergroesserte Flightdeck.
- `HomebaseTestScreen` haengt direkte Fireteam-, Loadout- und Dropship-Staging-Panels ein und nutzt dafuer den bestehenden `FOBDropPanel`-/`FOBFireteamCard`-Vertrag.
- Character Sheets werden standardmaessig geschlossen gehalten und per Doppelklick als frei schwebendes Popup geoeffnet.
- `MetaLayerFlow` synchronisiert Homebase-Fireteam-Auswahl und kann einen direkten Homebase-Drop-State in die bestehende Missionsplanung uebernehmen.
- `task_346_homebase_direct_staging_character_popup.gd` sichert Layout, Popup und Drop-State ab.

## Risiken / offene Punkte
- Das Homebase-Fensterlayout muss neu ausbalanciert werden; FullHD-Sichtcheck bleibt wichtig.
- Falls FOB- und Homebase-Staging zu stark auseinanderlaufen, muss zuerst ein kleiner gemeinsamer Helper extrahiert werden statt Logik zu kopieren.
- Das Popup darf nicht wie ein neues nummeriertes Fenster behandelt werden, sonst geht der Platzgewinn verloren.
- Der direkte Homebase-Flow muss spaeter klar gegen den optionalen FOB-Flow abgegrenzt werden.
