# TASK_1206 - Combat-/Contact-Visibility-Architekturanalyse

## Status

`DESIGN_REVIEW_PENDING`

TASK-1206 beginnt nicht mit einem vierten Performance-Patch. Zuerst wird die
gerichtete Sichtabfrage-Topologie zwischen Contact Tracking, Fire Pair Search
und Enemy Tactics auf derselben Integrationsbasis belegt. Anschliessend werden
hoechstens drei klar abgegrenzte, debug-gesteuerte Architekturvarianten gegen
eine im selben Build abschaltbare Kontrollvariante gemessen.

## Ausgangslage

Die TASK-1197-Baseline auf Produktions-SHA
`24f340d59dddd8ef59d69e617d3eac895eadeda4` weist fuer die relevanten
16v12-Mediane aus:

| Scope | Baseline-Median in usec |
|---|---:|
| Combat | 97.210 |
| Fire Decision | 39.995 |
| Fire Pair Search | 32.826,5 |
| Contact Tracking | 20.885 |
| Enemy Team Tactics | 23.693,5 |
| Simulation | 98.802,5 |
| Command Queue | 54.071,5 |

Drei serielle P07-Reparaturzyklen wurden verworfen und durch normale
Revert-Commits rueckgaengig gemacht:

1. Strukturierte Ergebniswiederverwendung verbesserte Pair Search auf
   32.212,5 usec, verschlechterte Enemy Tactics aber um 5,345 Prozent.
2. Eine Contact-Observation-Vorvalidierung erzeugte 3.735 Probes, traf im
   realen Resolver jedoch nur den Enemy-Fallback und meldete durchgaengig
   `missing_attacker_entry`. Deshalb gab es keine belastbare Wiederverwendung
   und keine komplette Messserie.
3. Die verfeinerte strukturierte Wiederverwendung auf SHA
   `21a86ce164fb359ea9c9d9a0594e167b22972747` verbesserte Pair Search um
   2,36 Prozent, ueberschritt mit Contact Tracking 22.032 usec aber dessen
   5-Prozent-Grenze von 21.929,25 usec. Combat, Simulation und Command Queue
   blieben ausserdem ueber ihren Releasebudgets.

Die Reparaturzweige sind sauber und gepusht; der produktive Nettodiff ist null.
`integration/core-foundation` steht unveraendert auf
`3cae5a216d380b58fef92724540e95fbc49bde7e`. `main` wird nicht beruehrt.

## Ziel

TASK-1206 liefert eine reproduzierbare Architekturentscheidung fuer genau
einen der folgenden Ausgaenge:

- `SHARED_TICK_RESULT_CONTRACT`
- `CACHE_INTERNAL_STRUCTURED_REUSE`
- `CONTACT_DERIVED_READ_MODEL`
- `NO_SAFE_FOURTH_FIX`

Die Entscheidung muss aus gerichteter Query-Topologie, identischem
Verhaltensorakel und zeitnah gepaarten A/B-Messungen hervorgehen. Eine
ausgewaehlte Runtime-Aenderung wird nicht in TASK-1206 integriert, sondern in
einem danach gesondert freizugebenden Implementierungs- und Releasepaket neu
von `integration/core-foundation` umgesetzt.

## Architekturgrenzen

- `SimulationRoot` bleibt alleinige Autoritaet fuer Gameplay-Mutationen.
- `MissionCombatLoopDriver`, Combat-Resolver, Contact Tracker und Enemy
  Tactics behalten ihre fachlichen Entscheidungen.
- Sichtdaten bleiben ticklokal, abgeleitet, read-only und werden nie Teil von
  Missions-, Multiplayer- oder Savegame-Snapshots.
- Reichweite, Arc, Vitalstatus, Stealth, Weapon-, Command- und
  Detection-Regeln werden nicht in einen Terrain-LoS-Cache verschoben.
- Source/Target-Reihenfolge bleibt semantisch gerichtet. Eine umgekehrte
  Friendly->Enemy-Abfrage darf nicht fuer Enemy->Friendly wiederverwendet
  werden, solange Richtungs- und Reichweitenkompatibilitaet nicht separat
  bewiesen sind.
- Analyseinstrumentierung ist nur bei explizitem Debug-Schalter aktiv. Sie
  aendert keine Auswahlreihenfolge, keinen Zufallspfad und keine Serialisierung.
- Der Analysezweig wird nicht in den Integrationsbranch gemergt.

## Liefergegenstaende

1. Eine schriftlich bestaetigte Design-Spec unter
   `docs/superpowers/specs/2026-09-01-combat-contact-visibility-analysis-design.md`.
2. Danach ein separater, serieller Luna-Ausfuehrungsplan unter
   `docs/superpowers/plans/2026-09-01-combat-contact-visibility-architecture-analysis.md`.
3. Bei Ausfuehrung des bestaetigten Plans: Query-Topologie-Matrix,
   Orakelprotokoll, gepaarte Messreihen, Variantenentscheidung und exakte SHAs.
4. Entweder genau eine begruendete Architekturpraeferenz oder der explizite
   Blocker `NO_SAFE_FOURTH_FIX`.

## Akzeptanz fuer die spaetere Analyseausfuehrung

- Der verwendete Start-SHA entspricht dem dann aktuellen, sauberen und
  gepushten `origin/integration/core-foundation`.
- Godot 4.6.2, Hardware, Betriebssystem und konkurrierende Godot-Prozesse sind
  fuer jede gewertete Serie dokumentiert.
- Das Richtungs-, Reichweiten-, Tick-, Positions-, Registry- und
  Revisionsverhalten jeder wiederverwendeten Sichtabfrage ist belegt.
- Baseline AUS und Variante EIN laufen im selben Build und derselben
  Instrumentierungskonfiguration in einer vorab festgelegten ABBA/BAAB-Folge.
- Das 600-Tick-Verhaltensorakel und die direkten TASK-1191-, TASK-1196- und
  TASK-1197-Vertraege bleiben bit-/wertgleich gruen.
- Pair Search verbessert sich im gepaarten Median um mindestens 2 Prozent und
  in mindestens sechs von acht Paaren, wenn eine Variante empfohlen wird.
- Contact Tracking bleibt sowohl innerhalb von plus 5 Prozent zur gepaarten
  Kontrolle als auch bei hoechstens 21.929,25 usec fuer den historischen
  P07-Vergleich. Fire Decision, Enemy Tactics, Combat, Simulation und Command
  Queue verschlechtern sich jeweils nicht um mehr als 5 Prozent.
- Reicht die Evidenz fuer keine Variante, endet TASK-1206 ohne Runtime-Patch
  mit `NO_SAFE_FOURTH_FIX`.

## Nicht im Scope

- keine Integration nach `integration/core-foundation`
- keine Aenderung an `main`
- keine Releasefreigabe und kein Tag
- keine FoW-, Dynamic-Overlay- oder SimulationRoot-Optimierung
- keine echte 128x128-Full-HD-Manuellevidenz
- keine parallelen Architekturvarianten oder gleichzeitigen Reparaturzweige

## Dokumentations-Gate dieses Branches

Dieser Branch darf zunaechst nur diese Taskdatei und die Design-Spec enthalten.
Der Luna-Ausfuehrungsplan wird erst nach menschlicher Sichtpruefung der Spec
geschrieben. Bis dahin bleibt der Status `DESIGN_REVIEW_PENDING`.
