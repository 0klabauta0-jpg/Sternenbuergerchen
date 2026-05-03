# TASK_175 - NPC Loadout Attachments

## Ziel
NPC-Helme und Waffen sollen nicht mehr nur pauschal aus dem Visual-Mapping kommen, sondern kontrolliert aus einem kleinen Loadout-/Rollenvertrag abgeleitet werden.

Der sichtbare 2.5D-Pfad aus TASK_171 bis TASK_174 bleibt erhalten: Modelle, Sockets, Helm- und Blaster-Kalibrierung werden weiter genutzt. TASK_175 fuehrt nur die Entscheidung ein, welches Attachment ein NPC bekommt.

## Status: GEPLANT

## Voraussetzung
- TASK_171 - NPC Model Replacement Animated Characters
- TASK_172 - NPC Animation Scale Helmets and Enemy Visuals
- TASK_173 - NPC Animation Skeleton Socket Contract
- TASK_174 - Character Helmet and Blaster Attachment Visuals

## Kontext
Aktuell haengen freundliche und gegnerische NPCs im 2.5D-Visual-Pfad standardisiert Helm und Blaster aus `data/npc_unit_visual_mapping.json` an `HeadSocket` und `RightHandSocket`.

Das ist fuer die visuelle Abnahme gut, aber fuer spaetere Rollen, Ausruestung und Waffenvarianten zu grob. Die Attachments sollen weiterhin reine Darstellung bleiben. Gameplay-Wahrheit, Combat-Werte und Befehlslogik duerfen dadurch nicht in die UI oder 3D-View wandern.

## Umfang
1. Kleiner Loadout-Visual-Vertrag:
   - Visual-Loadout-Daten fuer Helm und Waffe definieren.
   - Defaults fuer bestehende NPCs erhalten.
   - Friendly-, Enemy- und Rollenvarianten erlauben.
2. Mapping-Erweiterung:
   - `data/npc_unit_visual_mapping.json` so erweitern, dass Attachments pro Team, Unit, Rolle oder Fallback waehlbar sind.
   - Bestehende Helm-/Blaster-Kalibrierungen weiterverwenden.
3. TerrainMap3DView-Anbindung:
   - Attachment-Auswahl aus dem Visual-Loadout lesen.
   - Fehlende Loadout-Eintraege robust auf Defaults zurueckfallen lassen.
   - Missing-Asset-Marker und Snapshot-Zaehler fuer echte Ressourcenfehler beibehalten.
4. Verifier:
   - Friendly- und Enemy-NPCs behalten ihre bisherigen Default-Attachments.
   - Rollen-/Loadout-Override kann mindestens eine andere Blaster-Variante waehlen.
   - Keine SimulationRoot-Commands oder Effects werden durch Visual-Loadouts erzeugt.

## Nicht-Ziele
- Keine neuen Combat-Werte.
- Keine echte Waffenmechanik.
- Keine Ballistik oder Projektilsimulation.
- Keine Inventar- oder Ausruestungs-UI.
- Keine neuen Asset-Massenimporte.
- Keine Aenderung an RuntimeLeader, SimulationRoot oder CombatLoop-Wahrheit.

## Architekturregeln
- Loadout-Attachments sind Visual-Daten, nicht Gameplay-State.
- Die 3D-View darf nur darstellen und diagnostizieren.
- Gameplay-Rechte, Schaden, Reichweite und Munition bleiben ausserhalb dieses Tasks.
- Bestehende Socket-Namen und Attachment-Kalibrierungen aus TASK_173/TASK_174 bleiben die Basis.

## Akzeptanzkriterien
- [ ] Bestehende NPCs sehen ohne explizites Loadout weiter aus wie nach TASK_174.
- [ ] Mindestens eine Unit-/Rollenvariante nutzt eine andere Blaster-GLB aus dem importierten Blaster-Kit.
- [ ] Enemy-NPCs nutzen weiterhin animierte Character-Modelle und koennen Loadout-Attachments erhalten.
- [ ] Fehlende oder ungueltige Loadout-Pfade erzeugen sichtbare Diagnose statt stillem Fallback auf falsche Proxies.
- [ ] Visual-Loadouts veraendern keine SimulationRoot-Command- oder Effect-Queues.
- [ ] Headless-Verifier prueft Default, Override, Missing-Asset-Diagnose und Architekturgrenze.

## Lokale Pruefung
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_175_npc_loadout_attachment_verifier.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_174_character_helmet_blaster_attachment_verifier.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_160_tactical_playability_verifier.gd`
- [ ] `git diff --check`

## Dateien
- `data/npc_unit_visual_mapping.json`
- `scripts/terrain/terrain_map_3d_view.gd`
- `scripts/tests/task_175_npc_loadout_attachment_verifier.gd`
- `docs/tasks/TASK_175_npc_loadout_attachments.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Risiken
- Wenn Loadout-Daten zu frueh mit Combat-Werten vermischt werden, entsteht Architektur-Drift.
- Socket-/Achsenkalibrierung darf nicht pro Rolle neu geraten werden; Varianten sollen die bestehenden Attachment-Transform-Regeln nutzen.
- Visuelle Unterschiede koennen in Headless-Tests nur strukturell, nicht final optisch bewertet werden.

## Naechster Schritt
Visual-Loadout-Schema im Mapping klein definieren und einen fokussierten TASK_175-Verifier anlegen, bevor `TerrainMap3DView` erweitert wird.
