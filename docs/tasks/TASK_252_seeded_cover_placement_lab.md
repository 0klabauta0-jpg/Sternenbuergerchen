# TASK_252 - Seeded Cover Placement Lab

## Ziel
Test- und Editor-Karten sollen reproduzierbar sinnvolle Cover-Verteilungen erzeugen koennen. Ein seedbares Cover-Lab waehlt walkable Tiles mit Mindestabstand, bewertet sie ueber LOS-/Threat-Heuristik und liefert Terrain-Patches fuer Map-Editor oder Testkarten.

## Status: GEPLANT

## Voraussetzung
- `TASK_057 - Cover aus Terrain-Tiles`
- `TASK_056 - LOS ueber Terrain-Tiles`
- `TASK_129 - Deckungsbewusste Pfade mit HPA und Subgoal-Vorbereitung`

## Kontext
- Cover-aware Navigation ist nur so wertvoll wie die Cover-Daten.
- Von Hand gesetzte Deckung ist fuer schnelle Taktik-Prototypen langsam.
- Poisson-Disk/Blue-Noise-Ideen sind nuetzlich, aber im Projekt sollte die Auswahl tilebasiert und deterministisch sein.

## Umfang
1. Seedbare Kandidatenauswahl:
   - walkable Tiles aus `TerrainRegistry`.
   - Mindestabstand zwischen Kandidaten.
   - deterministische Sortierung und RNG-Nutzung.
2. Cover-Scoring:
   - erwartete Feindrichtungen oder Threat-Positionen.
   - LOS-Blockade ueber bestehende Terrain-/LOS-Daten.
   - Bonus fuer Objective-/Approach-nahe, aber nicht blockierende Positionen.
   - vorhandenes Cover respektieren.
3. Greedy-Auswahl:
   - hoechste Scores zuerst.
   - Mindestabstand zu gewaehlten Covers.
   - maximale Anzahl/Quote konfigurierbar.
4. Patch-Ausgabe:
   - keine Runtime-Gameplay-Mutation.
   - Ergebnis als Terrain-Patch-Dictionaries: `grid_position`, `cover_value`, optional `blocks_los`, optional `walkable`.
   - spaeter im Map-Editor anwendbar.
5. Verifier:
   - gleicher Seed liefert gleiche Auswahl.
   - Mindestabstand haelt.
   - Pfade aus TASK_129 profitieren messbar auf Testkarte.

## Nicht-Ziele
- Kein automatisches Runtime-Stempeln waehrend Missionen.
- Kein NavigationServer-Rebuild.
- Keine freien Poisson-Punkte ausserhalb des Iso-Grids.
- Keine Designer-Hero-Cover ersetzen.

## Architekturregeln
- Tooling/Editor-Daten sind nicht Gameplay-Wahrheit im laufenden Einsatz.
- Terrain-Daten bleiben in `TerrainRegistry`/Mapdaten.
- Keine UI-Callbacks mit direktem Gameplay-Commit.

## Akzeptanzkriterien
- [ ] Cover-Lab liefert reproduzierbare Patches fuer denselben Seed.
- [ ] Gewaehlte Cover-Tiles halten Mindestabstand.
- [ ] Nicht-walkable Tiles werden nicht als begehbare Cover-Punkte gewaehlt.
- [ ] LOS-/Threat-Score beeinflusst Auswahl sichtbar.
- [ ] Cover-aware Pfadtest zeigt bessere Cover-/Exposure-Metriken nach Patch-Anwendung.

## Erwartetes Ergebnis
Wir koennen schnell gute Cover-Testkarten erzeugen und Task-129-Pfadkosten auf belastbarere Terrain-Daten stellen.

## Lokale Pruefung
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_252_verifier.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_129_verifier.gd`

## Dateien (voraussichtlich)
- `scripts/terrain/cover_placement_lab.gd`
- `scripts/tests/task_252_verifier.gd`
- optional spaeter: Map-Editor-Anbindung

## Risiken
- Automatische Cover-Verteilung kann langweilig oder zu gleichfoermig wirken. Das Lab soll Designer-Arbeit beschleunigen, nicht ersetzen.
