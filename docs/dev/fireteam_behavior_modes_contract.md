# Fireteam Behavior Modes Contract

## Zweck

Dieser Contract beschreibt die erste kontrollierte Runtime-Regel fuer `Move`, `Engage`, `Take` und `Defend` im Mission-Tactical-Pfad. Er ersetzt keine spaetere Charakterbogen-Balance, legt aber fest, welche sichtbaren C/N/A-Werte aktuell gelten und wo Legacy-Fallbacks auffallen muessen.

## Autoritaet

- Gameplay-Zustand bleibt bei `SimulationRoot`, Runtime-Controllern und Command-Daten.
- UI setzt Befehle und zeigt Diagnose, speichert aber keine zweite Wahrheit.
- Der sichtbare Pfad ist `MissionTacticalSandboxController -> FireteamMovementController -> SimulationRoot.enqueue_command()`.
- `FireteamSecurityController` liefert nur Defense-/Security-Snapshots; er mutiert keine Unit-Kommandos.

## Gemeinsame C/N/A-Werte

| Befehl | Modus | Speed | Sicht | Deckung | Angriff | Bewegung | Waffe |
|---|---:|---:|---:|---:|---:|---|---|
| Move | C | 65% | 120% | 0 | 0 | engage | aimed |
| Move | N | 100% | 100% | 0 | 0 | travel | lowered |
| Move | A | 120% | 65% | 0 | 0 | run | lowered |
| Defend | C | 80% | 120% | +15 | -0.03 | engage | aimed |
| Defend | N | 100% | 100% | 0 | 0 | tactical | ready |
| Defend | A | 110% | 85% | -10 | +0.04 | engage | aimed |
| Take | C | 70% | 115% | +10 | 0 | engage | aimed |
| Take | N | 100% | 100% | 0 | 0 | travel | ready |
| Take | A | 120% | 75% | -12 | +0.06 | run | aimed |
| Engage | C | 75% | 115% | +10 | +0.02 | engage | aimed |
| Engage | N | 100% | 100% | 0 | 0 | engage | aimed |
| Engage | A | 115% | 80% | -8 | +0.08 | run | aimed |

## Befehlsbedeutung

- `Move`: Positionswechsel. C sichert mit Waffe im Aim, N laeuft normal, A laeuft schneller mit reduziertem Sichtfenster.
- `Defend`: Punkt oder Area halten und nach aussen sichern. Wenn kein Folgeauftrag aktiv ist, faellt das Fireteam automatisch in `Defend`.
- `Take`: Punkt oder Area kontrollieren/besitzen. Das Team bewegt sich hinein und bleibt dort als Kontrollpraesenz.
- `Engage`: Feindkontakt bekaempfen, ohne Besitzpflicht fuer eine Area.
- `Flank`: bleibt in diesem Contract ausgeklammert.

## Defense

- Sichtbarer Text ist `DEF 360` oder `DEF <Richtung>`, nicht `OVW`.
- Bei `DEF 360` verteilen sich die ersten vier Mitglieder auf Nord, Ost, Sued und West.
- Mitglieder scannen leicht links/rechts um ihre Grundrichtung.
- Directional Defense verteilt mehrere Mitglieder ueber den Zielsektor statt alle exakt auf denselben Punkt zu richten.
- `overwatch_ready` bleibt aus Kompatibilitaetsgruenden im Snapshot, wird in diesem neuen Basisverhalten aber nicht aktiv gesetzt.

## Fehlerverhalten

`move`, `defend`, `take` und `engage` duerfen im Mission-Tactical-Pfad nicht still in alte Flow-Driver-Ausfuehrung fallen. Wenn der neue Runtime-Pfad nicht starten kann, muss ein sichtbarer `BEHAVIOR ERROR` entstehen.

## Offene Balance

Die Werte sind Startkonstanten. Spaetere Charakterbogen-Werte wie Speed, Sight, Leadership, Accuracy oder Traits duerfen sie skalieren, muessen das aber explizit und testbar tun.
