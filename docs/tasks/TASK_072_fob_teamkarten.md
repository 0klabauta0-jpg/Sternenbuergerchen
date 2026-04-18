# TASK_072 – FOB: Teamkarten und Einsatzstatus

## Ziel
Die FOB soll dieselben NPC-Karten wie die Heimatbasis wiederverwenden, um das uebertragene Team, den Rueckfluss aus der letzten Mission und die Einsatzbereitschaft deutlich lesbarer zu machen.

## Pflicht vor Beginn
- Lies `docs/PROJECT_BRIEF.md`
- Lies `docs/ARCHITECTURE.md`
- Lies `docs/CODEX_RULES.md`
- Lies `docs/IMPLEMENTATION_STATUS.md`
- Lies `docs/tasks/TASK_070_npc_karten_komponente.md`
- Lies `docs/tasks/TASK_071_heimatbasis_npc_karten.md`
- Pruefe den Git-Status

## Abhaengigkeit
- TASK_070 (NPC-Karten-Komponente) muss vorher implementiert sein.
- TASK_071 (Heimatbasis: NPC-Karten und Auswahlfokus) muss vorher implementiert sein.
- TASK_034 (FOB-Rueckfluss) muss vorhanden sein.
- Der bestehende Debrief-/Mission-Rueckfluss muss bereits funktionieren und darf nicht gebrochen werden.

## Ist-Zustand (nach TASK_071)
- Die FOB kann das ausgewaehlte Team empfangen und eine Mission starten.
- Letzte Missionsresultate liegen bereits in einfacher Dictionary-Form vor.
- Die eigentliche FOB-Darstellung ist aber weiterhin textuell und zeigt Team sowie Rueckfluss nur als rohe Statuszeilen.

## Aufgabe

### 1. Uebertragenes Team als NPC-Karten anzeigen
- Stelle das aktuell in der FOB verfuegbare Team als wiederverwendete NPC-Karten dar.
- Nutze dafuer dieselbe Karten-Komponente wie in TASK_070 und dieselbe oder kompatible Meta-Datenaufbereitung.
- Die Karten sollen mindestens Name, kompakte Unit-Identitaet und einen einfachen FOB-Status zeigen.

### 2. Letzten Missionsrueckfluss in Kartenstatus ueberfuehren
- Werte den bestehenden `mission_result`-/`team_states`-Rueckfluss fuer die Kartenanzeige aus.
- Zeige pro Unit einen kompakten Status, z. B.:
  - `READY`
  - `FIT`
  - `DOWN`
  - `BLEEDOUT`
  - `RESPAWNING`
  - `UNKNOWN`
- Ohne Rueckflussdaten soll die FOB einen klaren Default-Zustand wie `READY FOR MISSION` oder aehnlich zeigen.

### 3. FOB als Staging-Screen lesbarer machen
- Behalte `Back` und `Start Mission` als Hauptaktionen bei.
- Ergaenze eine kleine Zusammenfassung ueber dem Team oder daneben, z. B.:
  - Teamgroesse
  - letzte Missionswertung
  - Anzahl einsatzbereiter Units
- Die FOB bleibt dabei ein Staging-Screen, keine neue Simulations- oder Loadout-Oberflaeche.

### 4. Keine zweite Kartenlogik einfuehren
- Die FOB soll bewusst dieselbe Karten-Komponente wiederverwenden.
- Status- oder Badge-Unterschiede duerfen ueber einfache Konfiguration, nicht ueber einen separaten Fork, abgebildet werden.

## Architekturhinweise
- FOB bleibt menu- und flowgetrieben.
- Keine neue Gameplay-Wahrheit in der FOB speichern.
- Bestehender Missionsstart- und Debrief-Rueckfluss bleibt ueber `MetaLayerFlow` koordiniert.
- Keine neue Rollen-, Loadout- oder Fahrzeuglogik vorziehen.

## Nicht-Ziele
- keine Rollenwechsel-Mechanik mit echter Wirkung
- keine Loadout- oder Ausruestungsverwaltung
- keine Dropship- oder Rover-UI
- keine tiefe After-Action-Analyse
- keine Persistenz oder Kampagnenlogik

## Akzeptanzkriterien
- Die FOB zeigt das aktuelle Team als NPC-Karten statt als reine ID-/Textliste.
- Der letzte Missionsrueckfluss ist pro Unit direkt an der Kartenanzeige lesbar.
- `Back`, `Start Mission` und der Debrief-Rueckfluss funktionieren weiterhin.
- Die FOB verwendet dieselbe Karten-Komponente wie die Heimatbasis und fuehrt keinen parallelen Kartenpfad ein.

## Git-Schritte nach lokaler Pruefung
- `git status`
- `git add` nur relevante Dateien
- `git commit -m "Define FOB team card task (TASK_072)"`
- `git push`
- `docs/IMPLEMENTATION_STATUS.md` erst nach Umsetzung aktualisieren