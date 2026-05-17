# Fireteam Behavior Modes Contract

## Zweck

Dieser Contract beschreibt die erste kontrollierte Runtime-Regel fuer `Move`, `Engage`, `Take` und `Defend` im Mission-Tactical-Pfad. Er ersetzt keine spaetere Charakterbogen-Balance, legt aber fest, welche sichtbaren C/N/A-Werte aktuell gelten und wo Legacy-Fallbacks auffallen muessen.

## Autoritaet

- Gameplay-Zustand bleibt bei `SimulationRoot`, Runtime-Controllern und Command-Daten.
- UI setzt Befehle und zeigt Diagnose, speichert aber keine zweite Wahrheit.
- Der sichtbare Pfad ist `MissionTacticalSandboxController -> FireteamMovementController -> SimulationRoot.enqueue_command()`.
- `FireteamSecurityController` liefert nur Defense-/Security-Snapshots; er mutiert keine Unit-Kommandos.

## Gemeinsame C/N/A-Werte

Die C/N/A-Werte sind seit TASK_451 globale Haltungsprofile. Move, Engage, Take und Defend lesen fuer dieselbe Haltung dieselben Boni und Mali; der Command beschreibt die Absicht, nicht eigene Speed-/Sichtwerte.

| Modus | Speed | Sicht | Deckung | Aim-Bereitschaft | Kontakt-Initiative | Team-Zielhilfe |
|---|---:|---:|---:|---:|---:|---:|
| C | 35% | 100% | 75% | 75% | -0.30s | +5% |
| N | 65% | 80% | 45% | 30% | +0.30s | 0% |
| A | 100% | 50% | 20% | 35% | 0.00s | -3% |

Command-spezifisch bleiben Bewegung, Waffe, Zielpolitik und Sequenzlogik. Beispiel: `Move C` nutzt dieselben C-Werte wie `Engage C`, bewegt aber als Positionswechsel; `Engage C` nutzt diese Werte in einer Kampfbewegung mit `fire_at_will`.

## Workbench-Ebenen

Die Formation-Workbench trennt drei Dinge, die im Runtime-Verhalten spaeter zusammenkommen, aber nicht dieselbe Datenform haben:

- `Stance-Grundprofil`: globale C/N/A-Boni und -Mali wie Speed, Sicht, Deckungsprioritaet, Aim-Bereitschaft, Kontaktzeit und Zielhilfe. Diese Werte gelten nicht pro Command unterschiedlich.
- `Standbild-Formation/Sicherung`: wer steht wo, wer ist Buddy mit wem, und wer schaut in welchen Sektor. Das kann die Workbench mit Mannequins und Facing-Griffen darstellen.
- `Ablaufsequenz`: raupenartig, ueberschlagend, Bounding, Fireline/Rush oder Rollenwechsel. Das sind zeitabhaengige Abfolgen wie "A deckt, B bewegt, dann Wechsel" und gehoeren nicht als Formations-Preset in die Standbild-Workbench.

TASK_453 legt die naechste Arbeitsgrenze fest: Die bestehende Formation-Workbench bleibt fuer statische Positionen und Blickrichtungen. Raupenartig, ueberschlagend, Bounding, Fireline, Regroup und Kontaktpausen brauchen eine eigene Doctrine-/Sequence-Ebene mit Phasen, Rollen, Triggern und Abbruchbedingungen.

Terrain bleibt fuer diese Fireteam-Regeln autoritativ ueber `TerrainRegistry`, Tile-Daten, LOS-System, Pathfinder und Combat Resolver. Das installierte Terrain3D-Plugin darf spaeter als Visual-/Authoring-Hilfe geprueft werden, wird aber nicht still zur zweiten Gameplay-Wahrheit fuer Sicht, Cover oder Bewegung.

Fuer den kommenden Terrain-/LOS-Slice gilt als Zielbild: Vollblocker wie Felsen oder hohe Objekte duerfen weiter ueber Tile-/Objektfelder blocken. Mauern und Zaunsegmente sollen dagegen als gerichtete Kanten-/Segment-Blocker modelliert werden, damit Sicht entlang einer Mauer moeglich bleibt. Eine LOS blockiert erst, wenn der Sichtstrahl ein Wandsegment kreuzt; reines paralleles Entlangsehen oder ein sauberer Blick auf derselben Mauerseite bleibt frei. Ecken brauchen eine explizite Toleranzregel: ein einzelner knapp beruehrter Eckpunkt blockt nicht automatisch, geschlossene Doppel-Ecken duerfen blocken.

Startwerte fuer das globale Workbench-Stance-Profil:

| Haltung | Speed | Sicht | Deckung | Aim-Bereitschaft | Kontaktzeit | Zielhilfe |
|---|---:|---:|---:|---:|---:|---:|
| C | 35% | 100% | 75% | 75% | -0.30s | +5% |
| N | 65% | 80% | 45% | 30% | +0.30s | 0% |
| A | 100% | 50% | 20% | 35% | 0.00s | -3% |

Character-Sheet-Hooks bleiben explizite Folgearbeit: `Speed`, `Awareness`, `Recognition`, `Initiative`, `Leadership`, `Speech Quality`, `Accuracy` und `Contact Stability` duerfen diese Werte spaeter skalieren, aber nicht still in UI-Code versteckt werden.

## Befehlsbedeutung

- `Move`: Positionswechsel. C sichert mit Waffe im Aim, N laeuft normal, A laeuft schneller mit reduziertem Sichtfenster.
- `Defend`: Punkt oder Area halten und nach aussen sichern. Wenn kein Folgeauftrag aktiv ist, faellt das Fireteam automatisch in `Defend`.
- `Take`: Punkt oder Area kontrollieren/besitzen. Das Team bewegt sich hinein und bleibt dort als Kontrollpraesenz.
- `Engage`: Feindkontakt bekaempfen, ohne Besitzpflicht fuer eine Area.
- `Flank`: bleibt in diesem Contract ausgeklammert.

## Engage Doctrine V1

`Engage` ist Kampfbewegung, nicht Besitz. Das Fireteam bekaempft Feinde auf dem Weg zum Ziel und im markierten Gebiet. Ein Gegner im aktiven Engage-Gebiet wird bei der Zielwahl gegenueber einem Gegner ausserhalb des Gebiets bevorzugt.

- `C`: kurze Buddy-Bounds. Zwei Mitglieder bewegen, zwei decken. Deckung ist hoch priorisiert; alle Waffen bleiben im Aim. Das Team rueckt nur abschnittsweise vor.
- `N`: normales Bounding. Buddy-Teams wechseln Bewegung und Sicherung, Feuer erfolgt sobald LOS und Waffenreichweite reichen.
- `A`: Fireline/Rush. Alle Mitglieder ruecken gemeinsam in breiter Linie vor; Wirkung geht vor Deckung, Waffen bleiben im Aim.

Fuer `Engage` gilt `fire_at_will`. Sicht-/Schussentscheidung bleibt Combat-Loop-Wahrheit: freie LOS, aktive Waffe, Waffenreichweite, Vital-State und Kontaktstatus muessen passen.

## Formation / Spacing Baseline

Die Formation-Workbench-Exporte aus TASK_445/TASK_446 liefern fuer den aktuellen Runtime-Start folgende Zielwerte:

| Befehl | Modus | Zielbild | Spacing |
|---|---:|---|---:|
| Move | C | parallele Buddy-Line, vorsichtig | 80 |
| Move | N | parallele Buddy-Line, normal | 117 |
| Move | A | breite schnelle Line | 117 |
| Engage | C | Buddy-Bounds, versetzt | Slot 74 |
| Engage | N | Buddy-Bounds, normal | Slot 139 |
| Engage | A | breite Fireline | Slot 93 |
| Take | C | vorsichtige Buddy-Entry-Paare | Slot 78 |
| Take | N | Bounding-Clear-Paare | Slot 110 |
| Take | A | Assault-Line | Slot 70 |
| Defend | C | enge 360-Sicherung | Slot 72 |
| Defend | N | balancierte 360-Sicherung | Slot 84 |
| Defend | A | nach vorne betonte Flankensicherung | Slot 90 |

Diese Werte sind Welt-Einheiten fuer Formation-Zielslots, keine Tile-Wahrheit und keine Kollisionsregel. Sie sollen sichtbaren Gaensemarsch vermeiden und Buddy-Zweierteams lesbar halten. Wenn Pathing oder Local Avoidance die Einheiten spaeter wieder zusammenzieht, muss das in einem eigenen Slice repariert werden.

### Runtime-Uebernahme aus Workbench `_05`

TASK_451 uebernimmt den Export `fireteam_formation_tuning_2026-05-17T08-46-56-746Z_05` als erste Runtime-Baseline. Direkt importiert sind:

- Stance-Grundwerte C/N/A fuer Speed, Sicht, Deckung, Aim-Bereitschaft, Kontakt-Initiative und Team-Zielhilfe.
- Exakte statische Zielslots fuer `Move C/N/A`, `Engage C/N/A` und `Take A`.
- Formation-Metadaten im Movement-Snapshot: `formation_preset_key`, `formation_slot_source` und `formation_leader_slot`.
- Command-Felder: `contact_initiative_seconds`, `aim_readiness_percent` und `team_target_support_percent`.

### TASK_452 Startpresets

TASK_452 ergaenzt sinnvolle Runtime-Startpresets fuer `Take C/N` und `Defend C/N/A`, damit keine dieser Basis-Kombinationen mehr stumm auf die alte Fallback-Formation faellt. Diese Startwerte sind bewusst noch keine Workbench-Exporte, sondern pruefbare Baseline-Kandidaten fuer den naechsten Godot-Playtest.

### TASK_457 Contact-/Engage-Runtime

TASK_457 koppelt die vorhandenen Contact-Workbench-Werte enger an den sichtbaren Runtime-Pfad:

- `aim_readiness_percent` wirkt im Combat-Loop als Delta auf die erste Kontakt-/Zielverzoegerung. Mehr Aim-Bereitschaft beschleunigt das Erfassen, weniger verzoegert es.
- Ein Wert von `0` bleibt kompatibel als nicht gesetzter/neutraler Altwert, damit alte Commands ohne Workbench-Profil keinen stillen Malus bekommen.
- Weapon-Fire-Events bleiben fuer ein kurzes Debug-Fenster im Snapshot, damit Muzzleflash und rote Schusslinie im manuellen Fenster lesbar sind.
- Nach einem abgeschlossenen Engage-Area-Befehl bekommt ein pending Waypoint im selben Plan Vorrang vor der naechsten Area/default Area.
- Der 3D Unit-Proxy-Snapshot exportiert Aim-Readiness und sichtbaren Aim-Override als Diagnosewerte.

### TASK_458 Contact-Decision-Diagnose

TASK_458 macht die letzte Combat-Entscheidung sichtbar, ohne neue Gameplay-Wahrheit in UI oder HUD zu legen:

- Der Mission-Combat-Loop exportiert `get_contact_decision_diagnostics_snapshot()` als read-only Diagnose.
- Gruende sind unter anderem `fired`, `cooldown`, `no_contact_pair`, `no_damage_effect` und `invalid_contact_pair`.
- Der Snapshot enthaelt Angreifer, Ziel, Waffe, Kontaktstatus, LOS-State, Range-State, Cooldown, aktiven Friendly-/Enemy-Count und bei Schuss den Fire-Event-Bezug.
- Fuer `no_contact_pair` wird ein erster Kandidat mit Blockgrund dokumentiert, damit im Playtest sichtbar wird, ob eher Bereitschaft, LOS, Range oder Zielzustand blockiert.
- Mission Control darf daraus nur Text bauen, z.B. `CONTACT FIRE`, `CONTACT WAIT` oder `NO FIRE <Grund>`.

### TASK_459 Engage-Orientation/Enemy-Proxies

TASK_459 legt fuer die 3D-Lesbarkeit fest:

- Aktive Fire-Events und bestaetigte/spotted Kontakte gewinnen fuer Aim-/Facing-Visuals vor altem Security-Facing, Move-Ziel oder Area-Ziel.
- Defense-/Security-Facing bleibt nur dann sichtbar fuehrend, wenn kein aktiver Kontakt/Fire-Event fuer die Unit vorliegt.
- Hostile Units muessen mindestens einen sichtbaren Body-/Readability-Core zeigen. Der Core ist ein Debug-/Lesbarkeitsfallback, keine neue Gameplay-Wahrheit.

### TASK_460 Movement-/Avoidance-Stabilitaet

TASK_460 bindet den vorhandenen Local-Avoidance-Pfad an die Fireteam-Bewegungscommands an:

- Move-, Engage- und Take-Bewegungscommands setzen command-lokal `local_avoidance_enabled = true`.
- Hold-/Cover-Commands bleiben ohne Movement-Avoidance-Opt-in.
- `SimulationRoot` darf den Avoidance-Resolver fuer ein command-lokales Opt-in vorbereiten, auch wenn der globale Root-Schalter fuer Tests oder andere Szenen aus ist.
- Der Debug-Snapshot markiert `command_local_avoidance_enabled`, damit im Playtest sichtbar wird, ob der Pfad wirklich aktiv ist.
- Avoidance-Korrekturen behalten einen Mindestanteil Bewegung in Zielrichtung, damit das Team ausweicht, aber nicht dauerhaft am Zielabschluss vorbeischiebt.

Das ist keine neue Pathfinding-Architektur. Wenn Einheiten danach weiter haengen, wird der Befund getrennt nach Terrain-Pfad, Zielslot, Sequenzfortschritt oder Kontakt-/Facing-Regel geschnitten.

### TASK_461 Engage-Visual/Stuck-Hotfix

TASK_461 stabilisiert die sichtbare Engage-Runtime nach dem manuellen Drill-Befund:

- Fireteam-Movement-Zielslots werden gegen `TerrainRegistry.resolve_walkable_target()` normalisiert, bevor die UnitCommands an `SimulationRoot` gehen.
- Der MovementController nutzt diese normalisierten Zielslots auch fuer seine Completion-Pruefung. Damit wartet ein Engage-/Take-Wegpunkt nicht mehr auf eine blockierte Originalposition, waehrend die Runtime bereits zur walkable Ersatzposition bewegt hat.
- Aktive Bewegung/Zielrichtung gewinnt fuer Aim-/Facing-Visuals vor altem Security-Facing, solange kein FireEvent oder bestaetigter Kontakt vorliegt.
- Hostile Units muessen im 3D-View-Fenster einen gut sichtbaren Readability-Core zeigen. Dieser Core bleibt ein Visual-Fallback, keine Gameplay-Wahrheit.
- Weapon-Fire-VFX darf nicht komplett verschwinden, wenn die Muzzle-Textur fehlt. Bloom und Trace bleiben sichtbar; der Snapshot markiert `muzzle_texture_missing`.

### TASK_462 Auto-Defend nach Zielabschluss

TASK_462 macht den Abschlusszustand explizit:

- Ein Fireteam-Wegpunkt darf abschliessen, wenn der MovementController `finished` meldet oder alle aktuellen Movement-Zielslots weich erreicht sind.
- GO-Continue nutzt denselben Zielabschlussentscheid. Ein sichtbar erreichtes, aber noch klemmendes `Move`/`Engage` bleibt nicht dauerhaft `ACTIVE`.
- Wenn danach kein weiterer Waypoint, Defend-Area oder Attack-Area existiert, wird automatisch `DEF 360` angewendet.
- Default-Defend-Hold-Commands tragen `source_task_type = auto_defend`, `security_mode = 360`, `fire_at_will` und verteilte Facing-Winkel fuer die Mitglieder.
- Dieser Default ist ein Abschluss-/Sicherungszustand, keine neue Area-Besitzlogik.

## Kontakt-Initiative V0

`Kontakt-Initiative` beschreibt die Zeit vom ersten sichtbaren oder suspekten Kontakt bis zum ersten koordinierten Schuss. Sie ersetzt nicht die Waffen-Feuerrate und nicht die harte Combat-Wahrheit. Ein Schuss bleibt nur moeglich, wenn LOS, Waffenreichweite, Vital-State, Fire-Status und Kontaktstatus passen.

Die Regel hat zwei Ausgaben:

- `contact_initiative_seconds`: Sekunden bis zur ersten sinnvollen Feuerfreigabe.
- `aim_readiness_percent`: Waffen-/Zielbereitschaft aus dem Haltungsprofil. Dieser Wert wird transportiert, im RuntimeStatus gehalten, im 3D-Visualpfad sichtbar ausgewertet und wirkt seit TASK_457 als Delta auf die erste Kontakt-/Zielverzoegerung. Hohe Werte koennen eine sonst gesenkte Waffe visuell auf Aim heben; die finale Animations-/Aim-Timing-Formel bleibt Folgearbeit.
- `team_target_support_percent`: Zielhilfe-/Feuerleitbonus fuer den ersten koordinierten Burst. Dieser Wert wirkt seit TASK_451 als Runtime-Hook auf die Trefferchance im `CombatFireDecisionResolver`.

Startformel fuer die Workbench und den naechsten Runtime-Slice:

| Faktor | Bedingung | Zeit | Zielhilfe |
|---|---|---:|---:|
| Basis | Kontakt sichtbar/suspekt | 2.00s | 0% |
| FOV fokussiert | Ziel im FOV, FOV <= 30 deg | -0.35s | +4% |
| FOV normal | Ziel im FOV, FOV <= 60 deg | -0.15s | +2% |
| FOV breit | Ziel im FOV, FOV > 60 deg | +0.05s | 0% |
| Ziel ausserhalb FOV | Scan/Drehung noetig | +0.75s bis +1.10s | -6% |
| Gute Feuerdistanz | laut gemeinsamem Distanz-C/N/A-Profil | Profilwert | Profilwert |
| Sehr nah | laut gemeinsamem Distanz-C/N/A-Profil | Profilwert | Profilwert |
| Randbereich | laut gemeinsamem Distanz-C/N/A-Profil | Profilwert | Profilwert |
| Ausser Waffen-/Sichtreichweite | laut gemeinsamem Distanz-C/N/A-Profil, nur Diagnose, noch kein Schuss | Profilwert | Profilwert |
| Buddyteam aktiv | feste Zweierteams | -0.35s | +8% |
| Buddy-Paar bestaetigt | beide Buddy-Mitglieder haben Ziel im FOV | zusaetzlich -0.15s | zusaetzlich +5% |
| Lose Wolke | keine festen Buddyteams | +0.55s | -4% |

Gemeinsames Distanz-C/N/A-Profil:

Diese Distanzwerte werden nicht pro Command gespeichert. Move, Engage, Take und Defend lesen fuer dieselbe Haltung dieselben Distanz-Mali und Distanz-Boni. Der Command beschreibt die Absicht; C/N/A beschreibt die Distanzbewertung.

| Haltung | Sehr nah bis | Gute Feuerdistanz | Klare Sicht bis | Gut Zeit/Zielhilfe | Nah Zeit/Zielhilfe | Rand Zeit/Zielhilfe | Ausser Waffe | Ausser Sicht |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| C | 20% Waffen-RW | 40-75% Waffen-RW | 70% Sicht-RW | -0.35s / +6% | +0.15s / -2% | +0.45s / -3% | +0.85s / -6% | +0.95s / -8% |
| N | 20% Waffen-RW | 35-75% Waffen-RW | 70% Sicht-RW | -0.25s / +4% | +0.10s / -2% | +0.35s / -3% | +0.80s / -6% | +0.95s / -8% |
| A | 15% Waffen-RW | 25-85% Waffen-RW | 80% Sicht-RW | -0.15s / +2% | +0.00s / -1% | +0.25s / -4% | +0.70s / -7% | +0.90s / -9% |

Command-/Stance-Bewegung addiert auf die Reaktion:

| Befehl | C | N | A |
|---|---:|---:|---:|
| Move | +0.05s | +0.25s | +0.45s |
| Engage | +0.10s | 0.00s | +0.20s |
| Take | +0.20s | +0.25s | +0.40s |
| Defend | -0.30s | -0.15s | 0.00s |

Das Ergebnis wird fuer die Startregel auf `0.35s..5.00s` begrenzt. Zielhilfe wird fuer die Startregel auf `-12%..+22%` begrenzt.

Spaetere Charakterbogen-Hooks:

- `Awareness` und `Recognition` reduzieren Kontaktbestaetigung und Friendly-/Enemy-Lesen.
- `Initiative` und `Speed` reduzieren die Umsetzungszeit vom Erkennen zur Aktion.
- `Speech Quality`, `Leadership` und Fireteam-Cohesion verstaerken Buddy-/Team-Zielhilfe.
- `Accuracy` und Waffenhandhabung wirken nicht auf die Kontakt-Initiative selbst, sondern auf den spaeteren Treffer-/Aim-Teil.
- `Contact Stability`, Suppression und Morale koennen die Reaktion unter Feuer verlangsamen oder stabilisieren.

## Take Doctrine V1

`Take` ist Besitz/Kontrolle. Das Fireteam will den Punkt oder die Area haben, Gegner dort entfernen und danach eine verteidigbare Praesenz herstellen. Anders als `Engage` sucht `Take` nicht primaer maximale Waffenreichweite, sondern technische Optimalreichweite und Raumkontrolle.

- `C`: kurze Buddy-Bounds von der freundlichen Seite. Deckung hat hohe Prioritaet, Waffen bleiben im Aim, Feuer wird durch 60% der Waffenreichweite begrenzt.
- `N`: normales Bounding/ueberschlagenes Vorgehen. Das Team erreicht die Area zuegig, deckt sich gegenseitig und feuert bis 70% der Waffenreichweite.
- `A`: Sturm-/Fireline. Alle Mitglieder ruecken gemeinsam breiter vor, Deckung ist nachrangig, Feuer ist bis 85% der Waffenreichweite erlaubt.

Die Reichweitenfaktoren sind erste technische Startwerte fuer die Befehlspolitik, nicht finale Waffenballistik. Ein spaeterer Kontakt-/Suppression-Slice darf "wird beschossen" als Ausnahme fuer frueheres Feuer ergaenzen.

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
