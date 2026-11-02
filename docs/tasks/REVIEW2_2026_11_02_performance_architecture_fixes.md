# Review 2, 2026-11-02 - Performance und Architektur

## Ziel / Problem
Die sieben weiteren Review-Befunde auf `a7e883f1f` beheben. Zuerst den P1-Fehler
beim Wechsel zwischen aktiver Mission, Homebase und FOB, danach die sechs P2.
Alle Runtimepruefungen verwenden ausdruecklich isolierte Nutzerdaten. Die echte
Rosterdatei muss bytegleich und mit unveraenderter Schreibzeit erhalten bleiben.

## Ursachen / Umfang
1. P1: Die unsichtbare aktive Mission erbt `PROCESS_MODE_DISABLED`, waehrend ihre
   monotone Missionsuhr weiterlaeuft.
2. P2: Unit-Oberflaechenhoehen lesen pro Frame linear aus allen Terrain-Tiles.
3. P2: Minimum-Spacing prueft im Idle alle Paare plus dieselben Paare fuer Diagnose.
4. P2: Editor-Pan/Rotation fuehren vor der Kameraaktion vollstaendiges Picking aus.
5. P2: Mehrere Beobachter je Fireteam/Gegner/Tick setzen LOS-Bestaetigung zurueck.
6. P2: Wiederholte Kontaktbeobachtung verschiebt wartende Relays unbegrenzt.
7. P2: Zwei-Tick-Reassemblyfenster verwirft bei Jitter noch vollstaendig lieferbare
   Snapshot-Chunks, ohne dass ein neuerer Snapshot angewendet wurde.

## Nicht-Ziele / Architektur
Keine neuen Gameplay-Systeme, kein UI-Redesign, keine Reduktion von Sichtweite
oder Unitanzahl, keine Budgetlockerung, kein neuer Netzwerktransport. Bestehende
SimulationRoot-/Registry-/Contract-Grenzen bleiben erhalten. Kein Schreiben am
realen Roster und keine vermutete Wiederherstellung des frueheren Profilstands.
Arbeit auf `task/review2-performance-architecture-fixes-20261102`: vom Integrations-
branch angelegt und vor Aenderungen auf den integrierten Review-Main `a7e883f1f`
fast-forwarded. Main-Integration erfolgt erst auf separaten Nutzerauftrag.

## Relevante Dokumente
- `AGENTS.md`, `docs/PROJECT_BRIEF.md`, `docs/ARCHITECTURE.md`, `docs/CODEX_RULES.md`
- `docs/dev/multiplayer_snapshot_replication_contract.md`
- `docs/dev/combat_loop_authority_contract.md`
- `docs/dev/runtime_script_layout_contract.md`
- relevante Contact-/Spacing-/Terrain-/Meta-Vertraege und bestehende Verifier
- `docs/superpowers/plans/2026-11-02-review2-fixes.md`

## Akzeptanz
- Isolation vor jedem Test: separates Projekt mit eindeutigem Projektnamen,
  frischer `user://`-Ablage und Laufzeit-Guard. Quelle `project.godot` unveraendert.
  Roster-Hash/Laenge/Schreibzeit vor und nach jedem Lauf pruefen; bei Abweichung
  abbrechen, niemals automatisch eine vermutete Profilversion zurueckschreiben.
- P1: Normale Navigationsbuttons lassen aktive Simulation, Combat, Bewegung und
  Respawn weiterlaufen; Preview bleibt deaktivierbar; versteckte Eingabe/Visuals
  bleiben verborgen. Navigation erzeugt keine neue Mission und keine Pause.
- Hoehenlookups verwenden vorhandenen Index; Idle-Frames skalieren nicht mit
  Kartenflaeche. Mapwechsel/Hoehenedits bleiben sofort korrekt.
- Spacing verwendet raeumlich nahe Paare deterministisch, ohne Sicherheit bei
  Ueberlappung, Terrain, Spawn/Respawn und Reihenfolgen zu verlieren. Die reine
  globale Minimum-Diagnose bleibt ausserhalb des normalen Idle-Ticks.
- Pan/Rotation benoetigen kein Tile-Picking; regulare Auswahl/Drag/Brush behalten
  Terrain-/Hoehenkorrektheit. Zusaetzliches Picking nur bei tatsaechlichem Bedarf.
- Kontaktdaten mehrerer Observer aggregieren pro Fireteam/Gegner/Tick ohne
  Rueckstufung; Detection-Fortschritt und LOS-Zaehler bleiben korrekt.
- Wartende Relays behalten ihre frueheste Faelligkeit bei aktualisierten Daten;
  Leadership-Verzoegerung und Weitergabe nach Sichtverlust funktionieren weiter.
- Chunk-Reassembly konvergiert auch bei vier Ticks Teilpaketversatz. Stale Ticks,
  Duplikate und unvollstaendige Daten erzeugen keine Commands oder Effects;
  Speicher und Lebensdauer der wartenden Daten bleiben begrenzt.
- Alle sieben Regressionen zuerst RED und danach GREEN, relevante alte Gates
  isoliert gruen, unabhaengige Abschlussreview, gezielte Commits und Task-Push.

## Dateien / lokale Pruefung
`scripts/meta/meta_layer_flow.gd`, `scripts/terrain/terrain_map_3d_view.gd`,
`scripts/editor/map_editor.gd`, `scripts/tactical/local_avoidance_resolver.gd`,
`scripts/tactical/contact_tracker.gd`, `scripts/core/simulation_root.gd`,
neue `scripts/tests/review2_20261102_*_verifier.gd`, Isolation-Runner/Guard,
betroffene Contracts und Statusdokumente. Pruefung mit Godot 4.6.2 und strukturellen
Operations-/Zustandsregressionen; keine FPS-/GPU-Abnahme daraus ableiten.

## Risiken / offene Punkte
Runtime-Autonomie liegt teilweise im Tactical-Controller; Sichtbarkeit darf diese
nicht versehentlich abschalten. Indizes muessen dieselben Tile-Objekte lesen.
Spacing muss deterministisch bleiben. Reassembly braucht ein bewusst begrenztes
Pufferbudget. Isolation darf `user://` nicht erst nach Spielstart umleiten.

## Status
Reale Rosterdatei nur gelesen/ausserhalb des Repos gesichert;
Baseline SHA256 `d0fa4b03ff72d7cf427fd65bf6c54d4ebfc327e9f37055d657501362d189edcb`.
- Isolierter Live-Canary bestanden. Jeder Test bekommt frische Nutzerdaten;
  der echte Roster bleibt einschliesslich Laenge und Schreibzeit unveraendert.
- P1 RED 44/16 -> GREEN 60/0. Normale Navigation, Simulation/Combat, reale
  Commands/Effects, Respawn, Kamera/Input und separate CanvasLayers abgedeckt.
  Unabhaengige Source-/Evidence-Review APPROVED, keine wichtigen Befunde.
- Bestehende P1-Gates: Normalstart 40/40, Recovery 19/19, Input-Ownership 116/116.
- TASK_348 ist 14/17; ein isolierter HEAD-Baseline-Lauf zeigt exakt dieselben
  drei Fehlerlabels in derselben Reihenfolge. Keine neue P1-Regression und keine
  Abschwaechung dieses alten Tests; kein allgemeiner Release-Claim daraus.
- P1 ist separat in `13bcaf3fb` committed; danach alle sechs P2 umgesetzt.
- Neue Regressionen final: P1 60/60, Hoehe 9/9, Spacing 19/19, Picking 50/50,
  Observer 22/22, Relay 28/28, Chunks 14/14; zusammen 202/202. Alle sieben
  zuerst RED. Picking-Grenzgleichheit und Chunk-Ablauf ohne Paketverkehr wurden
  nach zusaetzlichem RED ebenfalls abgesichert.
- Gemessene Arbeit: Hoehenlookup bei 128x128/256x256 von 97530/391674 linearen
  Tile-Lesungen auf 0; Picking von 16384/65536 Polygonen auf jeweils 9.
  Spacing im 96-Unit-Idle ueber zehn Ticks von 45600 Solver- plus 45600
  Diagnosepaaren auf 0+0. Explizite globale Debug-Minimum-Messung bleibt korrekt.
  Vier-Tick-Chunkversatz: 0 -> 60/60 vollstaendig zugestellte Snapshots angewendet.
- Abschlussmatrix effektiv 55 unterschiedliche strenge Gates gruen, darunter
  Canary ohne numerische Assertions; die anderen 54 Gates bestehen 1650/1650
  Assertions. Einzelne Source-/Evidence-Reviews und Gesamt-Diff APPROVED ohne
  wichtige offene Befunde. Godot 4.6.2 headless, keine FPS-/GPU-/Release-Abnahme.
- Der erste Gesamtlauf war 53/55: HUD 26/27 wegen fehlender `icon.svg.import`
  im isolierten Overlay und Terrain 33/33 Exit0 mit falschem Manifestmarker.
  Nur Harness/Marker korrigiert; beide gezielten Wiederholungen strikt gruen,
  keine Assertions entfernt. Originalberichte bleiben erhalten. TASK_510 erhielt
  eine korrekt besessene und freigegebene Index-/Readmodel-Fixture gegen Leaks.
- Echte Rosterbytes, Laenge und Schreibzeit vor/nach jedem Test unveraendert.
  `project.godot` unveraendert. Ergebnisindex und Quellhashes:
  `output/review2_fixes_20261102/verification_summary.json`.
  Reproduzierbare Auswahl: `scripts/tests/review2_20261102_checks.json`.

## Isolationstechnik
`scripts/tests/run_review2_isolated.py` erzeugt vor jedem Prozessstart eine
separate Projektdatei mit eindeutigem Namen. Resource-Verzeichnisse und der
Importcache werden geteilt, `output`, `tmp` und Nutzerdaten bleiben getrennt.
Der zuerst konstruierte Test-Autoload beendet bei falschem `user://` den eigenen
Prozess synchron. Neue Verifier fordern diesen Guard zusaetzlich selbst an.
Ein Live-Canary und SHA256/Laenge/mtime des geschuetzten Rosters werden kontrolliert.
Quell-`project.godot` bleibt bytegleich.

Die erste Canary-Probe fand einen Konfigurationsfehler: Godot 4.6.2 ignoriert
`--script`, wenn `disable_project_settings_override=true` ist. Sie startete daher
das Menue ausschliesslich mit isolierten Daten und lief in den Timeout; der echte
Roster blieb unveraendert. Der Runner haelt diese Option nun false, setzt den
externen Override-Pfad leer und kopiert keine Root-Override-/Binary-Datei.
Der anschliessende eigentliche Canary-Verifier besteht mit Exit 0.

Aufruf fuer jeden einzelnen RED-/GREEN-/Bestandstest:

```powershell
python scripts/tests/run_review2_isolated.py --script res://scripts/tests/TEST.gd --success-marker MARKER --output output/review2_fixes_20261102/BEREICH/PHASE
```
