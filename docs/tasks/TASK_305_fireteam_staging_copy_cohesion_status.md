# TASK_305 - Fireteam Staging Copy Cohesion Status

## Ziel
Operatoren sollen im FOB/Homebase-Kontext leichter in Fireteams uebernommen werden koennen. Fireteam Status soll zeigen, wie eingespielt ein Team ist, statt nur eine statische Liste zu sein.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_077 - FOB Fireteam Auswahl
- TASK_079 - FOB Fireteam Staging Ausbau
- TASK_236 - Fireteam Relationship Affinity and Cohesion
- TASK_237 - Mission Progression XP Morale Frustration
- TASK_303 - FOB Transfer Dragdrop Card Readability

## Kontext
Der User moechte Operatoren ziehen koennen und sie bei Bedarf auch direkt zu Fireteams kopieren/zuweisen. Fireteam Status kann spaeter ausdruecken, wie gut ein Team zusammen eingespielt ist.

## Umfang
1. Fireteam-Drop-Zonen:
   - Operator Card -> Fireteam Slot.
   - Transfer Team -> Fireteam Vorschlag oder Kopie.
   - Eindeutige Semantik: kopieren/zuweisen/verschieben nicht vermischen.
2. Staging:
   - Temporaere Fireteam-Zusammenstellung vor Missionsstart.
   - Warnung bei Doppelzuweisung oder fehlendem Leader.
   - Optional "als Fireteam merken".
3. Cohesion-Status:
   - Anzeige fuer Team-Eingespieltheit aus vorhandener Affinity/Cohesion.
   - Keine neue tiefe Simulation in diesem Task, nur Anzeige/Anbindung.
   - Tooltip erklaert, warum der Wert so ist.
4. UX:
   - Fireteam Status darf nicht die Transfer-UX ueberladen.
   - Karten bleiben draggable und Selection-freundlich.
5. Verifier:
   - Drop in Fireteam-Slot.
   - Doppelzuweisung wird erkannt.
   - Cohesion-Wert sichtbar und aus Daten ableitbar.

## Nicht-Ziele
- Keine neue Beziehungssimulation.
- Keine automatische optimale Teamzusammenstellung.
- Keine Combat-Balance-Aenderung.

## Akzeptanzkriterien
- [x] Operator kann per Drag auf Fireteam-Slot zugewiesen werden.
- [x] Transfer Team kann als Quelle fuer Fireteam-Staging dienen.
- [x] Doppelzuweisung/fehlender Leader werden sichtbar.
- [x] Fireteam Status zeigt einen Cohesion-/Eingespielt-Wert.
- [x] Tooltip erklaert den Wert kurz.
- [x] Verifier prueft Drop, Status und Validierung.

## Erwartete Dateien
- `scripts/meta/...`
- `scripts/ui/...`
- `data/contextual_help_catalog.json`
- `scripts/tests/task_305_fireteam_staging_copy_cohesion_status.gd`
- `docs/manual_checks/fireteam_staging_copy_cohesion_checklist.md`
- `docs/tasks/TASK_305_fireteam_staging_copy_cohesion_status.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_305_fireteam_staging_copy_cohesion_status.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_236_fireteam_relationship_affinity_and_cohesion.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_303_fob_transfer_dragdrop_card_readability.gd`
- [ ] Manueller Fireteam-Staging-Check.
- [ ] `git diff --check`

## Risiken
- "Kopieren" darf keine echte doppelte Person erzeugen; es ist eine Zuweisungs-/Staging-Referenz.
- Cohesion-Anzeige darf nicht mehr Genauigkeit versprechen, als das Datenmodell aktuell hat.

## Naechster Schritt
TASK_306 prueft den gesamten Userology-Block als Playability-Smoke.
