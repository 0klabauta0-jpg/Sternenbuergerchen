# TASK_176 - FOB Loadout Weapon Preview Selector

## Ziel
Fenster `#13 LOADOUT` soll Waffen nicht nur als Textauswahl zeigen, sondern mit einem kleinen Bild aus dem Blaster-Kit-Preview-Set sichtbar machen.

Der erste Slice bleibt bewusst klein: Die SMG nutzt `blaster-a` als Preview und Visual-Waffe. Das `Medictool` nutzt `blaster-b` als Preview und Visual-Waffe. Spaeter koennen weitere Blaster-Varianten ergaenzt werden, ohne die Loadout-UI oder den Missionspfad neu zu erfinden.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_174 - Character Helmet and Blaster Attachment Visuals
- TASK_175 - NPC Loadout Attachments

## Kontext
`#13 LOADOUT` im FOB verwaltet bereits pro Mitglied Armor sowie `Slot 1` und `Slot 2`. Diese Auswahl fliesst ueber den bestehenden Meta-/Mission-Setup-Pfad in die Mission und bleibt die Gameplay-relevante Loadout-Wahrheit.

TASK_175 hat dazu einen separaten rein visuellen Attachment-Vertrag fuer NPC-Modelle eingefuehrt. TASK_176 soll diese beiden Ebenen ergonomischer verbinden: Der Spieler soll im FOB sehen, welche sichtbare Waffe zur Auswahl gehoert, ohne dass UI-Preview-Bilder zu Combat-Werten oder SimulationRoot-Wahrheit werden.

## Asset-Regel
Alle genutzten Assets muessen ins Projekt kopiert und ueber `res://...` referenziert werden.

Lokale Arbeitsquellen wie `C:\Users\bjoer\Pictures\Sternenbuerger\Blaster Kit\Previews` duerfen nur als Importquelle dienen. Runtime, UI, Tests und Mapping duerfen nicht direkt auf absolute Benutzerpfade zugreifen.

## Umfang
1. Preview-Asset-Import:
   - `blaster-a.png` und `blaster-b.png` aus dem lokalen Preview-Ordner ins Projekt uebernehmen, falls sie nicht bereits vorhanden sind.
   - Zielpfade: `res://Assets/used/npc/blaster_kit/previews/blaster-a.png` und `res://Assets/used/npc/blaster_kit/previews/blaster-b.png`.
   - Import/License-Kontext des bestehenden Blaster-Kit-Subsets beibehalten.
2. Kleine Preview-Mapping-Tabelle:
   - SMG explizit auf `blaster-a` mappen.
   - `medictool` als eigene Auswahl erhalten und auf `blaster-b` mappen.
   - Andere Waffenbezeichnungen vorerst nicht als sichtbare Blaster-Auswahl anbieten.
3. FOB-UI in `#13 LOADOUT`:
   - Die bestehende pro-Mitglied-Auswahl bleibt erhalten.
   - Neben oder in der Slot-Auswahl wird ein kleines Preview-Bild fuer die ausgewaehlte SMG angezeigt.
   - SMG und Medictool zeigen jeweils ihr eigenes Preview; wenn spaeter kein Preview existiert, bleibt die UI stabil und zeigt keinen falschen Blaster.
4. Datenfluss:
   - Die Auswahl schreibt weiter nur die bestehenden `weapon_1`-/`weapon_2`-IDs.
   - Keine direkten Gameplay-Werte, Schadenswerte, Reichweiten, Munition oder Combat-Regeln in der UI.
5. Verifier:
   - `#13 LOADOUT` kann SMG und `medictool` weiterhin als gueltige Auswahl darstellen.
   - SMG findet das Projekt-Preview `blaster-a.png`.
   - Keine absolute lokale Asset-Quelle wird in UI-/Mapping-Code referenziert.
   - Mission-Setup/SimulationRoot-Grenze bleibt unveraendert.

## Nicht-Ziele
- Keine neue Waffenmechanik.
- Keine neuen Combat-Werte.
- Keine Reichweiten-, Schaden-, Ammo- oder Ballistik-Anbindung.
- Keine Massenimporte aller Blaster-Previews.
- Keine Gegner-Loadout-UI.
- Keine Umstellung der bestehenden Meta-Loadout-Struktur.
- Keine direkten Referenzen auf `C:\Users\...` in Projektdateien.

## Architekturregeln
- `#13 LOADOUT` ist UI/Staging und nicht Gameplay-Autoritaet.
- Gameplay-Wahrheit bleibt im bestehenden Meta-/Mission-Setup- und SimulationRoot-Pfad.
- Preview-Bilder sind rein visuelle UI-Hilfe.
- Der TASK_175-Visual-Loadout-Vertrag darf genutzt werden, aber nicht mit Combat-Daten vermischt werden.

## Akzeptanzkriterien
- [x] SMG wird in `#13 LOADOUT` mit `blaster-a.png` aus dem Projekt angezeigt.
- [x] `medictool` bleibt als Auswahl verfuegbar und bekommt `blaster-b.png` als Preview.
- [x] Vorerst werden keine weiteren Blaster-Optionen als Auswahl angeboten.
- [x] Genutzte Preview-Assets liegen unter `Assets/used/...` im Projekt.
- [x] Es gibt keine absoluten Asset-Pfade auf lokale Benutzerordner.
- [x] Die bestehende Loadout-Uebergabe in die Mission bleibt kompatibel.
- [x] Headless-Verifier deckt Asset-Pfad, UI-Auswahlvertrag und Architekturgrenze ab.

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_176_fob_loadout_weapon_preview_selector_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_087_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_175_npc_loadout_attachment_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_174_character_helmet_blaster_attachment_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/medic_support_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_096_recovery_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_114_meta_recovery_verifier.gd`
- [x] `git diff --check`

## Erwartete Dateien
- `scripts/meta/fob_screen.gd`
- `scripts/terrain/terrain_map_3d_view.gd`
- `data/npc_unit_visual_mapping.json`
- `scripts/tests/task_176_fob_loadout_weapon_preview_selector_verifier.gd`
- `scripts/tests/medic_support_verifier.gd`
- `Assets/used/npc/blaster_kit/previews/blaster-a.png`
- `Assets/used/npc/blaster_kit/previews/blaster-b.png`
- `Assets/used/npc/blaster_kit/models/blaster-b.glb`
- `docs/tasks/TASK_176_fob_loadout_weapon_preview_selector.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Risiken
- Wenn Preview-UI und Combat-Loadout vermischt werden, entsteht Architektur-Drift.
- Zu viele Optionen auf einmal koennen Fenster `#13` unuebersichtlich machen; deshalb startet der Task mit SMG und `medictool`.
- Weitere Blaster-Previews sollten erst importiert werden, wenn ihre Modell-/Loadout-Zuordnung wirklich genutzt wird.

## Ergebnis
- `#13 LOADOUT` zeigt in den Slot-Controls nur noch `SMG` und `Medictool`.
- Die SMG-Option nutzt `res://Assets/used/npc/blaster_kit/previews/blaster-a.png` als Icon und Slot-Preview.
- `Medictool` bleibt waehlbar und nutzt `res://Assets/used/npc/blaster_kit/previews/blaster-b.png` als Icon und Slot-Preview.
- `data/npc_unit_visual_mapping.json` enthaelt `medictool_blaster` mit `blaster-b.glb`; `weapon_visual_loadouts.medictool` zeigt darauf.
- `TerrainMap3DView` laesst `medictool` das Team-Default-Visual-Loadout fuer die sichtbare Waffe uebersteuern, nutzt aber weiterhin die TASK_174-Groessen-, Textur- und Orientierungs-Kalibrierung am `RightHandSocket`.
- Alte `rifle`-/`rail_gun`-Werte werden im FOB-UI-Slice auf die aktuelle SMG-Auswahl normalisiert; die bestehende Mission-/TestUnit-Waffenlogik bleibt davon getrennt.
- `scripts/tests/task_176_fob_loadout_weapon_preview_selector_verifier.gd` prueft Assetpfad, UI-Auswahlvertrag, Preview-Verhalten und lokale Pfadgrenze.

## Naechster Schritt
Manueller Sichtcheck in `#13 LOADOUT`; weitere Blaster erst importieren und mappen, wenn sie wirklich als eigene Auswahl genutzt werden.
