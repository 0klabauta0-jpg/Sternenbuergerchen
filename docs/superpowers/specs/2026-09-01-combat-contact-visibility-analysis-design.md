# Combat-/Contact-Visibility-Architekturanalyse - Design-Spec

**Datum:** 2026-09-01

**Status:** `DESIGN_REVIEW_PENDING`

**Dokumentationsbranch:** `task/1206-combat-contact-visibility-analysis-plan`

**Dokumentationsworktree:** `C:\dev\SternenBuergerchen-worktrees\task-1206-combat-contact-visibility-analysis-plan`

**Verifizierte Basis:** `integration/core-foundation` und
`origin/integration/core-foundation` auf
`3cae5a216d380b58fef92724540e95fbc49bde7e`

## 1. Problem und Entscheidungsbedarf

P07 bleibt nach drei bewusst seriellen Combat-Reparaturzyklen blockiert. Die
bisherigen Varianten zeigten keinen einfachen lokalen Gewinner:

- Eine Cache-Optimierung kann Fire Pair Search entlasten und gleichzeitig
  Contact Tracking oder Enemy Tactics verteuern.
- Eine fachlich plausibel wirkende Contact-Vorvalidierung kann wirkungslos
  bleiben, wenn der reale Resolver dieselben Einheiten in umgekehrter Richtung
  oder mit einem anderen Reichweitenvertrag abfragt.
- Historische Baseline und spaetere Kandidatenserie wurden zu verschiedenen
  Zeitpunkten gemessen. Ein kleiner positiver oder negativer Delta allein
  trennt daher Architekturwirkung nicht sicher von zeitlicher Messdrift.
- Das bestehende Hotspot-Profil ist auf Fire Pair Search fokussiert. Es zeigt
  nicht vollstaendig, welchem Konsumenten die Kosten fuer Key-Bau, Lookup,
  Terrain-LoS und Ergebnisbereitstellung tatsaechlich zugerechnet werden.

Ein vierter Runtime-Patch ohne vorherige Topologie- und Kostenanalyse waere
unbelegt. Diese Spec definiert deshalb eine begrenzte Analyse, deren Ergebnis
eine Architekturentscheidung und noch keine produktive Implementierung ist.

## 2. Belegte Ausgangsevidenz

### 2.1 TASK-1197-Baseline

Die gueltige 3-cold/5-warm-Serie auf Produktions-SHA
`24f340d59dddd8ef59d69e617d3eac895eadeda4` liefert:

| Scope | Minimum | Maximum | Median | Einheit |
|---|---:|---:|---:|---|
| Combat | 95.232 | 100.785 | 97.210 | usec |
| Fire Decision | 37.020 | 45.633 | 39.995 | usec |
| Fire Pair Search | 30.095 | 39.599 | 32.826,5 | usec |
| Contact Tracking | 20.269 | 23.558 | 20.885 | usec |
| Enemy Team Tactics | 20.402 | 27.397 | 23.693,5 | usec |
| Simulation | 96.461 | 103.981 | 98.802,5 | usec |
| Command Queue | 51.964 | 55.232 | 54.071,5 | usec |

Diese Serie bleibt die historische P07-Referenz. Sie darf nicht als zeitgleiche
Kontrolle fuer neue Kleindeltas ausgegeben werden.

### 2.2 Reparaturzyklus 1 - strukturierte Ergebniswiederverwendung

Produktcommit: `86fcc0e0c27d616ad1a6443c2b22b2f9291b2337`

Revertcommit: `d2a79af28d52fac579617df2a88ee61b98c3343c`

Die Variante zog Registry-Identitaet und Revisionssignatur vor den String-Key
und speicherte neben dem Key bereits das boolesche Terrain-Ergebnis. Pair
Search sank auf einen Median von 32.212,5 usec, waehrend Enemy Tactics um
5,345 Prozent stieg. Der P07-Effekt-Gate war damit rot; Produkt- und
Testcommit wurden normal revertiert.

### 2.3 Reparaturzyklus 2 - beobachtete LoS-Vorvalidierung

Produktcommit: `b52bdd06ba3f58563fbb3ac1095950a5d6bf5859`

Revertcommit: `4176fbb2f49931954dd8ff932cf880599a23edb3`

Contact Tracking legte fuer beobachtete Friendly->Enemy-Paare Positionen,
Reichweite und positives Sichtresultat ab. Der reale Resolverpfad fragte in
diesem Harness jedoch den Enemy-Fallback ab. Alle 3.735 Probes endeten deshalb
mit `missing_attacker_entry`; es gab keine effektive Wiederverwendung. Nach
direkten Vertragstests wurde die Variante ohne irrefuehrende Vollserie
revertiert.

### 2.4 Reparaturzyklus 3 - verfeinerte strukturierte Wiederverwendung

Gemessener Kandidaten-SHA: `21a86ce164fb359ea9c9d9a0594e167b22972747`

Netto-null-End-SHA des Reparaturbranches:
`6e1b3e58ceeadb23f5c527760beaad9d1328ea01`

| Scope | Kandidatenmedian | Delta zur historischen Baseline |
|---|---:|---:|
| Combat | 99.703 | +2,56 % |
| Fire Decision | 38.785,5 | -3,02 % |
| Fire Pair Search | 32.051,5 | -2,36 % |
| Contact Tracking | 22.032 | +5,49 % |
| Enemy Team Tactics | 23.244,5 | -1,90 % |
| Simulation | 100.915 | +2,14 % |
| Command Queue | 55.156 | +2,01 % |

Contact Tracking ueberschritt die 5-Prozent-Grenze von 21.929,25 usec um
102,75 usec. Alle drei Cold-FoW-Laeufe waren rot, alle fuenf Warm-Laeufe gruen;
die direkten TASK-1202-Fokuspruefungen waren 13/13 gruen. Der Kandidat wurde
trotz Pair-Verbesserung verworfen und normal revertiert.

### 2.5 Aktuelle Basiskontrolle fuer den Dokumentationstask

Im frischen TASK-1206-Worktree lief
`scripts/tests/task_1197_selected_combat_hotspot.gd` auf dem unveraenderten
Integrations-SHA mit `35 passed, 0 failed`. Die Godot-Ausgabe enthielt Fehler
zu noch nicht erzeugten lokalen Audio-Importartefakten. Sie beeinflussten den
Exit-Code und das Combat-Orakel nicht, sind aber keine Performance-Evidenz und
werden aus gewerteten spaeteren Serien ausgeschlossen.

## 3. Ziel, Ergebnis und Nicht-Ziele

### 3.1 Ziel

Die Analyse beantwortet vier Fragen:

1. Welche gerichteten Sichtabfragen wiederholen Contact Tracking, Fire Pair
   Search und Enemy Tactics innerhalb desselben autoritativen Ticks wirklich?
2. Wo entstehen ihre Kosten: Range-Reject, Signatur-/Key-Bau, Cache-Lookup,
   Terrain-LoS, Ergebnisablage oder konsumierende Nacharbeit?
3. Ist die beobachtete Pair-Verbesserung der strukturierten Wiederverwendung
   unter zeitnah gepaarter Kontrolle reproduzierbar, ohne einen anderen Scope
   ueber 5 Prozent zu treiben?
4. Welche von drei abgegrenzten Architekturen ist sicher weiterzuverfolgen -
   oder muss die Optimierung mit `NO_SAFE_FOURTH_FIX` enden?

### 3.2 Zulaessige Endergebnisse

Die Ergebnisakte nennt genau einen Wert:

- `SHARED_TICK_RESULT_CONTRACT`
- `CACHE_INTERNAL_STRUCTURED_REUSE`
- `CONTACT_DERIVED_READ_MODEL`
- `NO_SAFE_FOURTH_FIX`

Ein Architekturwert ist nur eine Empfehlung fuer einen neuen, gesondert
freizugebenden Umsetzungstask. Die Analyse selbst wird nicht in Produktion
integriert.

### 3.3 Nicht-Ziele

- keine Gameplay-, Balance-, Reichweiten-, Detection- oder Zielwahl-Aenderung
- keine Verschiebung autoritativer Mutation aus `SimulationRoot`
- keine Produktintegration des Analysezweigs
- keine gleichzeitige Optimierung von SimulationRoot, FoW oder Dynamic Overlay
- keine Ersetzung der echten 128x128-Full-HD-Manuellevidenz
- keine Freigabe von `main`, Release-Tag oder Deployment
- keine Behauptung, dass eine lokale Combat-Verbesserung alle P07-Budgets loest

## 4. Autoritaets- und Dateninvarianten

### 4.1 Autoritaet

`SimulationRoot` bleibt alleinige Stelle fuer Gameplay-Mutationen. Der
`MissionCombatLoopDriver` orchestriert bestehende Leser und Resolver, darf
aber aus einem Analysecache keine neue Gameplay-Wahrheit erzeugen.

### 4.2 Abgeleitete Sichtdaten

Ein analysiertes oder wiederverwendetes Sichtresultat ist:

- auf genau einen Simulationstick begrenzt,
- read-only,
- nicht serialisiert,
- nicht Bestandteil kanonischer Missions- oder Multiplayer-Snapshots,
- an Registry-Identitaet, Terrainrevision und beide Weltpositionen gebunden,
- standardmaessig an die geordnete Source-/Target-Richtung gebunden.

### 4.3 Fachliche Trennung

Terrain-Occlusion ist nicht gleich Angriffsgueltigkeit. Folgende Regeln bleiben
beim jeweiligen Konsumenten und duerfen nicht durch ein positives
Terrainresultat uebersprungen werden:

- effektive Contact- bzw. Weapon-Reichweite,
- Arc und Attack-Area,
- Vitalstatus,
- Detection-Fortschritt und Contact-State,
- Stealth, Discipline, Misidentification und Return Fire,
- Command-, Weapon- und Teamregeln.

### 4.4 Keine stillschweigende Richtungssymmetrie

Reine Liniengeometrie kann mathematisch symmetrisch erscheinen. Der aktuelle
Vertrag ist trotzdem gerichtet, weil Source/Target-Identitaet, Hoehenabfrage,
Reichweitenpruefung und Konsumentensemantik verschieden sein koennen. Eine
Normalisierung auf ein ungeordnetes Paar ist nur dann zulaessige Empfehlung,
wenn ein eigener Vertragstest alle der folgenden Punkte beweist:

1. A->B und B->A liefern bei identischen Positionen und derselben Revision
   ueber den gesamten Testkorpus dasselbe reine Terrainresultat.
2. Der wiederverwendende Konsument fuehrt seine eigene Richtung und Reichweite
   weiterhin aus.
3. Kein positiver Contact-Befund ersetzt einen engeren Fire-Range-Check.
4. Bewegungen innerhalb derselben Grid-Zelle invalidieren weiterhin ueber die
   exakten Weltpositionen.

Bis zu diesem Beweis bleibt jeder Reverse-Pair-Treffer reine Diagnose und darf
keinen Fast Path aktivieren.

## 5. Beobachteter Ist-Datenfluss

Der aktuelle Flow ist bewusst vor jeder Loesung zu dokumentieren:

1. `MissionCombatLoopDriver._update_contact_tracking()` iteriert aktive
   Friendlies gegen aktive Enemies und ruft `_has_valid_los(friendly, enemy)`
   auf.
2. `_has_valid_los()` prueft Vitalstatus und bestimmt die Contact-/gegebenenfalls
   Weapon-Reichweite, bevor der gemeinsame Sichtservice gelesen wird.
3. Contact Tracking baut daraus Beobachtungen und den beobachteten
   Fire-Candidate-Index.
4. Der spaetere Fire-Resolver sucht ein erstes gueltiges Paar. Im realen
   16v12-Pfad kann dabei Enemy->Friendly statt Friendly->Enemy dominieren.
5. Das bestehende `CombatVisibilityCache` memoisiert reine Terrain-Occlusion
   anhand eines ticklokalen, gerichteten Keys mit Identitaeten, Grid,
   Hoehenklassen, Revisionen und Weltpositionen.
6. Das bestehende Detailprofil wird nur waehrend des Pair-Search-Scopes
   aktiviert. Cachearbeit ausserhalb dieses Fensters ist deshalb nicht sicher
   einem Konsumenten zugeordnet.

Diese Beschreibung ist eine Ausgangshypothese. Die Analyse muss sie als
Query-Topologie-Matrix mit realen Zaehlern belegen oder korrigieren.

## 6. Zwei getrennte Messmodi

Die wichtigste Schutzmassnahme ist die Trennung von Diagnostik und gewerteter
Performance.

### 6.1 Modus T - Topologie und Kostenaufteilung

Modus T ist debug-only und darf zusaetzliche Zaehler sowie feinere Timer
aktivieren. Er beantwortet, wer welche gerichtete Abfrage ausloest. Seine
Zeitwerte sind Diagnose, nicht Releasebudget.

Jeder Sichtzugriff erhaelt genau einen Consumer-Tag:

- `contact_tracking`
- `fire_pair_search`
- `enemy_security`
- `enemy_team_tactics`
- `other_combat`

Pro Consumer und insgesamt werden mindestens erfasst:

| Gruppe | Pflichtfelder |
|---|---|
| Aufrufe | request count, unique ordered pair count, same-consumer repeat count |
| Ueberlappung | exact cross-consumer hit, reverse-pair opportunity, missing producer |
| Gueltigkeit | tick, source position, target position, registry, revision und direction mismatch |
| Reichweite | pre-cache range reject, consumer range, reused result but consumer range reject |
| Cachekosten | signature/key build count+usec, lookup count+usec, entry write count+usec |
| Geometrie | terrain LoS count+usec, cache hit, structured fast-path hit |
| Ergebnis | clear/blocked count, result materialization count, candidate accepted/rejected |

Die Ausgabe ist ein debug-only Dictionary mit `derived_only: true`,
`read_only: true` und `snapshot_serialized: false`. Paar-IDs duerfen nur in
einem begrenzten Testdump erscheinen; die normale Laufzeitschnittstelle gibt
nur aggregierte Werte aus.

### 6.2 Modus P - gepaarte Performance

Modus P deaktiviert die feinen Timer und Paar-Dumps. Nur die bereits
gate-relevanten Scopezeiten und ein minimaler Variantenzaehler bleiben aktiv.
Baseline AUS und Variante EIN laufen im selben Binary und auf demselben SHA.
Damit trifft der Instrumentierungs-Overhead beide Seiten gleich.

Eine Variante, deren Effekt nur mit den feinen Modus-T-Timern sichtbar ist,
gilt nicht als Performancegewinn.

## 7. Query-Topologie-Matrix

Vor jeder Variante wird eine Matrix erzeugt. Eine Zeile repraesentiert einen
gerichteten Produzent-/Konsument-Pfad:

| Feld | Bedeutung |
|---|---|
| producer consumer | Consumer, der das erste Terrainresultat im Tick erzeugt |
| reuse consumer | spaeterer Consumer im selben Tick |
| direction | A->B exakt, B->A reverse oder andere Einheit |
| cadence | jeder Tick, Attack-Tick oder zustandsabhaengig |
| producer range | Reichweitenvertrag des Produzenten |
| reuse range | Reichweitenvertrag des Konsumenten |
| exact overlap | gleiche IDs, Positionen, Registry und Revision |
| reverse opportunity | nur umgekehrte Richtung, noch kein gueltiger Hit |
| terrain saved | Zahl vermiedener reiner Terrain-LoS-Auswertungen |
| extra work | zusaetzliche Signatur-, Key-, Dictionary- und Materialisierungskosten |

Eine Architekturvariante darf nur fuer Matrixzeilen aktiviert werden, deren
Gueltigkeitsbedingungen explizit erfuellt sind. `missing_attacker_entry` oder
Reverse-Pair-Zaehler sind Belege gegen eine Annahme und kein Anlass, die
Gueltigkeitspruefung aufzuweichen.

## 8. Zu untersuchende Architekturvarianten

Die Varianten laufen streng seriell. Jede startet von derselben
Integrationsbasis oder einem dokumentierten, netto aequivalenten Analyse-SHA.
Es werden nie zwei Fast Paths gleichzeitig bewertet.

### 8.1 Variante A - `SHARED_TICK_RESULT_CONTRACT`

Ein kleiner, unveraenderlicher `VisibilityResult`-Vertrag wird vom gemeinsamen
Sichtservice zurueckgegeben. Er enthaelt nur:

- gerichtete Source-/Target-ID,
- beide Weltpositionen,
- Registry-Identitaet und Terrainrevision,
- Tick,
- reines Terrain-clear/blocked,
- optional den bereits erzeugten internen Cache-Key als Diagnosewert.

Konsumenten duerfen dasselbe Objekt nur bei exakter gerichteter
Gueltigkeitsgleichheit lesen und fuehren alle fachlichen Checks selbst aus.
Der Vertrag darf nicht als Event publiziert, nicht im Contact Tracker
gespeichert und nicht serialisiert werden.

**Staerke:** expliziter Vertrag und eindeutige Gueltigkeit.

**Risiko:** Objekt-/Dictionary-Materialisierung kann Contact Tracking staerker
verteuern als die gesparte String-Key-Arbeit.

**Frueher Ausschluss:** weniger als zwei reale exakte Konsumenten pro Resultat
oder Materialisierungskosten groesser als eingesparte Cachekosten.

### 8.2 Variante B - `CACHE_INTERNAL_STRUCTURED_REUSE`

Der bestehende boolesche API-Vertrag bleibt unveraendert. Nur der ticklokale
Cache haelt intern eine strukturierte, gerichtete Pair-Entry und prueft
Position, Registry und Revision vor einem erneuten String-Key-Bau. Diese
Variante entspricht der Grundidee der Zyklen 1 und 3, muss aber mit
Consumer-Zuordnung und gepaarter Kontrolle neu bewertet werden.

**Staerke:** kleinster oeffentlicher API-Eingriff.

**Risiko:** jedes erste Contact-Paar bezahlt Dictionary-, Signatur- und
Entry-Kosten, waehrend der spaetere Pair-Search-Nutzen nur fuer einen Teil der
Paare entsteht.

**Frueher Ausschluss:** Contact schreibt wesentlich mehr Entries als Pair
Search spaeter exakt wiederverwendet oder der Modus-P-Gate reproduziert die
Contact-Verschlechterung.

### 8.3 Variante C - `CONTACT_DERIVED_READ_MODEL`

Contact Tracking kann eine begrenzte ticklokale Read-Model-Sicht seiner
tatsaechlich beobachteten Paare bereitstellen. Der Fire-Resolver darf daraus
nur einen exakten gerichteten Terrainbefund lesen; Range und alle Fire-Regeln
bleiben beim Resolver.

**Staerke:** Ergebnis entsteht an einer fachlich bereits vorhandenen
Beobachtungsgrenze.

**Risiko:** Zyklus 2 belegt, dass der reale Resolverpfad eine andere Richtung
nutzen kann; dann entsteht nur Verwaltungsaufwand ohne Hit.

**Frueher Ausschluss:** weniger als 80 Prozent der bewerteten Fire-Pair-Probes
haben einen exakten gerichteten Producer-Eintrag oder ein Reverse-Hit waere
fuer den Nutzen erforderlich, ohne dass der separate Symmetrievertrag besteht.

### 8.4 Keine Mischvariante

Die Analyse fuehrt weder Variante A+B noch B+C zusammen. Wenn keine einzelne
Variante die Gates erfuellt, lautet das Ergebnis `NO_SAFE_FOURTH_FIX`. Eine
hybride Architektur waere ein neuer Designgegenstand mit neuer Freigabe.

## 9. Experimentdesign

### 9.1 Umgebungsgate

Vor jeder gewerteten Serie werden aufgezeichnet:

- exakter `HEAD`-SHA und Branch,
- Gleichheit zur vorgesehenen Analysebasis,
- sauberer Arbeitsbaum,
- Godot `4.6.2`,
- Windows-Version, CPU und RAM,
- keine fremden Godot-Prozesse waehrend des 60-Sekunden-Vorlaufs,
- erfolgreicher Import der fuer den Harness benoetigten Ressourcen,
- Exit 0 und genau eine gueltige JSON-Ergebniszeile je Lauf.

Ein Lauf mit fremdem Prozess, fehlender JSON-Zeile, falschem SHA, Importfehler
im bewerteten Pfad oder abweichender Orakelpruefsumme wird verworfen. Grund und
Wiederholung werden dokumentiert; ein verworfener Lauf wird nicht still durch
einen guenstigeren Wert ersetzt.

### 9.2 Verhaltensgate vor Zeitmessung

Baseline AUS und Variante EIN muessen im selben Build liefern:

- denselben kanonischen 600-Tick-Snapshot,
- dieselben Contact-, Detection-, Fire-, Hit-, Damage- und Missionswerte,
- dieselbe geordnete Zielauswahl,
- gruen fuer TASK-1191, TASK-1196 und TASK-1197,
- `derived_only: true`, `read_only: true`, `snapshot_serialized: false`.

Jede Abweichung beendet die Variante vor einer Performance-Serie.

### 9.3 Gewertete A/B-Folge

Nach je einem ungewerteten Smoke fuer AUS und EIN folgen 16 frische Prozesse
in dieser festen Folge:

```text
AUS, EIN, EIN, AUS,
EIN, AUS, AUS, EIN,
AUS, EIN, EIN, AUS,
EIN, AUS, AUS, EIN
```

Das ergibt acht zeitnahe Paare und je acht Werte pro Modus. Fuer jedes Paar
wird das Delta `(EIN - AUS) / AUS` berechnet. Ausgewiesen werden:

- alle Rohwerte in Ausfuehrungsreihenfolge,
- Minimum, Maximum und Median je Modus,
- Median der acht gepaarten Deltas,
- Zahl der Paare mit Verbesserung,
- historischer Vergleich zur TASK-1197-Baseline, klar als nicht gepaart
  gekennzeichnet.

Wird genau ein Paar durch aeussere Kontamination ungueltig, wird nur dieses
Paar in derselben Reihenfolge wiederholt. Bei zwei oder mehr ungueltigen Paaren
wird die ganze Serie nach einer neuen Umgebungskontrolle wiederholt.

### 9.4 Entscheidungsgates

Eine Variante kann empfohlen werden, wenn alle Gates erfuellt sind:

| Gate | Bedingung |
|---|---|
| Verhalten | vollstaendig identisches Orakel und alle Direktvertraege gruen |
| Pair Search | gepaarter Median mindestens -2,0 % und mindestens 6/8 Paare verbessert |
| Contact Tracking | gepaarter Median hoechstens +5,0 % und historisch hoechstens 21.929,25 usec |
| Fire Decision | gepaarter Median hoechstens +5,0 % |
| Enemy Team Tactics | gepaarter Median hoechstens +5,0 % |
| Combat | gepaarter Median hoechstens +5,0 % |
| Simulation | gepaarter Median hoechstens +5,0 % |
| Command Queue | gepaarter Median hoechstens +5,0 % |
| Gueltigkeit | kein ungepruefter Reverse-, Range-, Tick-, Positions- oder Revisions-Reuse |
| Architektur | keine neue Autoritaet und keine Serialisierung abgeleiteter Daten |

Erfuellen mehrere Varianten alle Gates, gewinnt in dieser Reihenfolge:

1. niedrigster gepaarter Combat-Median,
2. niedrigster gepaarter Contact-Tracking-Median,
3. kleinste oeffentliche API-Flaeche,
4. geringste Zahl neuer langlebiger Datenstrukturen.

Die Auswahl darf nicht allein auf Pair Search optimieren.

## 10. Dateikorridor fuer die spaetere Analyse

Der noch zu schreibende Luna-Ausfuehrungsplan darf fuer die Analyse hoechstens
folgende Produkt-/Testkorridore freigeben:

- `scripts/mission/combat_visibility_cache.gd`
- `scripts/tests/mission_combat_loop_driver.gd`
- `scripts/tactical/combat_fire_decision_resolver.gd`
- ein neuer direkter TASK-1206-Verifier unter `scripts/tests/`
- eine eng begrenzte Erweiterung des bestehenden TASK-1187-Messharness fuer
  den expliziten AUS/EIN-Schalter
- `docs/tasks/TASK_1206_combat_contact_visibility_architecture_analysis.md`
- eine TASK-1206-Ergebnisakte unter `docs/reports/`

Jede Variante bekommt vorab einen engeren Teilkorridor. Andere Gameplay-, UI-,
FoW-, Overlay-, SimulationRoot-, Audio- oder Release-Dateien sind gesperrt.

## 11. Branch- und Integrationsmodell

1. Die vorliegende Spec und die spaetere Plan-Datei entstehen auf
   `task/1206-combat-contact-visibility-analysis-plan`.
2. Nach schriftlicher Design- und Planfreigabe startet die Analyse auf einem
   neuen isolierten Branch
   `task/1206-combat-contact-visibility-architecture-analysis`, abgeleitet vom
   dann aktuellen `origin/integration/core-foundation`.
3. Analyse- und Variantencommits bleiben auf diesem Zweig. Reverts erfolgen
   als normale Commits; kein Reset, kein Ueberschreiben fremder Arbeit.
4. Der Analysezweig wird nicht nach `integration/core-foundation` oder `main`
   gemergt.
5. Eine empfohlene Architektur wird spaeter in einem neuen Task frisch von
   der Integrationsbasis implementiert. Analysecode wird nicht blind
   cherry-gepickt.

## 12. Luna-Orchestrierung und Eskalation

Die spaetere Ausfuehrung ist strikt seriell. Standardmodell ist
`gpt-5.6-luna` mit `low`. Pro Worker-Kapsel sind Branch, SHA, Dateikorridor,
erlaubte Aktion, Tests, Gate und Rueckgabeformat fest anzugeben.

Eskalation ist nur evidenzbasiert erlaubt:

- `medium`, wenn Messwerte, Query-Topologie oder Verhaltensorakel einander
  nach einer Wiederholungspruefung widersprechen;
- `high`, wenn eine belegte Kollision mit SimulationRoot-Autoritaet,
  Snapshotgrenze oder gerichteter Sichtsemantik nicht lokal entscheidbar ist;
- niemals `xhigh`, `max` oder `ultra`.

Nach jedem Worker prueft der Dirigent Diff, SHA, Tests und Gate selbst. Kein
Worker darf einen weiteren Worker starten. Varianten werden nicht parallel
gemessen oder implementiert.

## 13. Ergebnisakte und Rueckgabeformat

Die spaetere Ergebnisakte muss mindestens enthalten:

1. Basis-, Analyse- und Varianten-SHAs,
2. Umgebung und alle verworfenen Laeufe mit Grund,
3. Query-Topologie-Matrix,
4. Modus-T-Zaehler und Kostenaufteilung,
5. Modus-P-Rohwerte und gepaarte Deltas,
6. Orakel- und Direktvertragsergebnisse,
7. Gate-Tabelle je Variante,
8. genau einen Entscheidungswert,
9. verbleibende P07-Budgets und ausdrueckliche Releasegrenze,
10. Empfehlung fuer den naechsten separaten Task oder den Blocker
    `NO_SAFE_FOURTH_FIX`.

Die Worker-Rueckgabe bleibt kompakt und fest:

```text
STATUS: PASS | FAIL | BLOCKED
BRANCH: <branch>
BASE_SHA: <sha>
HEAD_SHA: <sha>
CHANGED_FILES: <exact list>
TESTS: <command -> result>
MEASUREMENTS: <series/report path or none>
DECISION: <one allowed value or none>
REVERTS: <sha list or none>
RISKS: <concise evidence>
NEXT_GATE: <exact gate>
```

## 14. Risiken und Abbruchbedingungen

- **Messinstrumentierung beeinflusst die Hotpath-Kosten:** Modus T und Modus P
  bleiben getrennt; nur Modus P entscheidet Performance.
- **Zeitliche Drift tarnt Kleindeltas:** feste ABBA/BAAB-Paarung im selben
  Build; historische Werte dienen nur als Zusatzvergleich.
- **Reverse-LoS wird fachlich ueberdehnt:** kein Fast Path ohne separaten
  Richtungs- und Reichweitenbeweis.
- **Contact produziert fuer ungenutzte Paare:** Hit-/Write-Verhaeltnis wird vor
  Performancebewertung gemessen; Variante wird frueh ausgeschlossen.
- **Ein lokaler Gewinn loest P07 nicht:** Ergebnisakte fuehrt alle verbleibenden
  Combat-, Simulation-, Command-, FoW- und Manuellevidenz-Gates weiter als
  offen.
- **Import- oder Fremdprozessrauschen:** betroffene Paare bzw. Serien sind
  ungueltig und werden transparent wiederholt.
- **Keine sichere Variante:** Die korrekte Endbedingung ist
  `NO_SAFE_FOURTH_FIX`, nicht ein aufgeweichtes 5-Prozent-Gate.

## 15. Design-Gate vor der Planerstellung

Vor dem Schreiben des seriellen Luna-Ausfuehrungsplans muss ein Mensch diese
Spec bestaetigen oder korrigieren. Bis dahin werden weder der Plan noch
TASK-1206-Analysecode erzeugt. Die Bestaetigung autorisiert nur die
Planerstellung; Ausfuehrung, Integration, `main` und Release bleiben separat
gesperrt.
