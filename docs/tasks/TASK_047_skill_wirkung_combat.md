# TASK 047 – Skill-Wirkung im Combat

## Ziel
Die Unit-Skill-Werte aus TASK_046 sollen jetzt echte Gameplay-Wirkung haben: Trefferchance, Bewegungstempo und Schadensreduktion werden aus den individuellen Skills abgeleitet.

## Pflicht vor Beginn
- Lies `docs/PROJECT_BRIEF.md`
- Lies `docs/ARCHITECTURE.md`
- Lies `docs/CODEX_RULES.md`
- Lies `docs/IMPLEMENTATION_STATUS.md`
- Pruefe den Git-Status

## Abhaengigkeit
- TASK_046 (Unit-Skill-Werte) muss vorher implementiert sein.

## Ist-Zustand (nach TASK_046)
- Jede Unit hat `accuracy`, `speed`, `leadership`, `toughness` als Daten.
- `DamageModel` nutzt eine feste `hit_chance` aus dem Effect-Dictionary.
- Bewegungsgeschwindigkeit ist einheitlich (nur phasenabhaengig aus TASK_039).
- Es gibt keine individuelle Schadensreduktion.

## Aufgabe

### 1. Accuracy -> Trefferchance
- Im `SimulationRoot` oder `MissionCombatLoopDriver`: wenn ein `damage`-Effect enqueued wird, soll die `hit_chance` aus der `accuracy` der angreifenden Unit abgeleitet werden.
- Formel: `base_hit_chance * (0.5 + attacker.skills.accuracy)` – bei accuracy=0.5 bleibt die Chance gleich, bei 0.0 halbiert, bei 1.0 verdoppelt (geclamped auf max 0.95).

### 2. Speed -> Bewegungstempo
- Im `SimulationRoot`: der bestehende `move_speed_factor` wird mit dem `speed`-Skill der Unit multipliziert.
- Formel: `effective_speed = move_speed_factor * (0.5 + unit.skills.speed)` – bei speed=0.5 unveraendert.

### 3. Toughness -> Schadensreduktion
- Im `SimulationRoot`: wenn `damage` auf eine Unit angewendet wird, wird der finale Schaden durch `toughness` reduziert.
- Formel: `effective_damage = base_damage * (1.0 - unit.skills.toughness * 0.4)` – bei toughness=0.5 wird 20% reduziert, bei 1.0 wird 40% reduziert.

### 4. Leadership (vorbereitet, keine Wirkung)
- `leadership` hat in diesem Task noch keine Gameplay-Wirkung. Der Wert wird nur mitgefuehrt fuer spaetere FTL-Qualitaets-Effekte.

## Nicht-Ziele
- kein komplexes Balancing
- keine situationsabhaengigen Skill-Modifikatoren
- keine Skill-Entwicklung
- keine Leadership-Wirkung (folgt spaeter)

## Akzeptanzkriterien
- Units mit hoher `accuracy` treffen oefter
- Units mit hohem `speed` bewegen sich schneller
- Units mit hoher `toughness` nehmen weniger Schaden
- Die Formeln sind einfach und nachvollziehbar
- Bestehende Kampflogik, Phasen und Respawn funktionieren weiterhin

## Git-Schritte nach lokaler Pruefung
- `git status`
- `git add` nur relevante Dateien
- `git commit -m "Apply unit skills to combat and movement (TASK_047)"`
- `git push`
- `docs/IMPLEMENTATION_STATUS.md` aktualisieren
