# R4: Nearest-Walkable-Livepruefung nach Distanzguard

## Ziel / Problem
Im normalen R4-Vollbildpfad kosten einzelne GO-Aufrufe weiter 28-38 ms allein
in Movement-Start samt Argumenten; ein Execution-Update erreicht 73,404 ms.
Die Motion-Evidence bei GO48/B dokumentiert echte Walkable- und Spacing-
Reparaturen. Diese Werte grenzen den Pfad ein, messen aber die innere
Nearest-Walkable-Zeit noch nicht separat.

## Bestaetigte Ursache / Sinnhaftigkeit
`FireteamMovementController._resolve_spacing_safe_stage_target()` kann fuer
mehrere Zielslots und Reparaturkandidaten `TerrainRegistry.resolve_walkable_target()`
aufrufen. Der Recoverypfad `get_nearest_walkable_grid()` prueft im Vorherstand jedes
Tile mit `is_walkable()`, bevor Distanz und bestehender Nearest-Tieguard
weiter entfernte Kandidaten ausschliessen. GM01 enthaelt 9.408 Tiles.
Diese Live-Walkabilityreads sind fuer bereits ausgeschlossene Kandidaten
redundant. Der Nearest-Loop selbst bleibt linear.

## Umfang / Nicht-Ziele / Owner
Root hat zunaechst ausschliesslich diese neue Task und den neuen Verifier
autorisiert. Agent erstellt keine Produktaenderung und startet weder Engine
noch Git. Root pinnt Registry und Movement, sichert den unveraenderten RED
und darf erst danach den engen Produktumfang gesondert freigeben.

Vorgeschlagener Produktumfang nur `TerrainRegistry.get_nearest_walkable_grid()`:
unveraenderte Distanzberechnung und `_is_nearest_candidate_better()` vor die
Live-`is_walkable()`-Pruefung stellen. Geblockte Kandidaten duerfen weder
`nearest_distance` noch `nearest_grid` aendern. Tile-Einfuegereihenfolge,
`0.001`-Distanzquadrattoleranz, Grid-X-/Y-Tieguard und aktuelle Tile-/Override-
Wahrheit bleiben unveraendert. Kein Cache, Spatialindex, neuer Helper im
Produkt, A*/HPA-/Movement-/Command-/HUDumbau oder Budget-/Qualitaetswechsel.

## Relevante Dokumente / Contracts
AGENTS, PROJECT_BRIEF, ARCHITECTURE, CODEX_RULES, IMPLEMENTATION_STATUS,
TASK_ROADMAP, R4-Haupttask, R4-go_timing, R4-periodic_hud_queue,
`fireteam_runtime_execution_path_contract.md`, `fireteam_behavior_modes_contract.md`,
`hex_grid_v1_contract.md`, TASK409 und TASK475.

TASK409 verlangt aktuelle Walkability auch nach direkter In-place-Aenderung
ohne Notify oder Revisionswechsel. Das neue Oracle liest deshalb fuer jede
Anfrage die echten Live-Tiles und Overrides erneut. Auch direkte Aenderungen
von World-/Gridposition werden mit dem bisherigen Loop verglichen; keine
neue Mutation-/Invalidationvorschrift wird als Voraussetzung erfunden.

## Akzeptanz / enger RED
Neuer Verifier `runtime_hitches_r4_20261107_nearest_walkable_verifier.gd`:
- Echte TerrainRegistry-Subclass zaehlt ausschliesslich `is_walkable()` und
  delegiert die Antwort an `super`; keine ersetzte Produktquery.
- Ein unabhaengiges Originaloracle kopiert den bisherigen exhaustiven Loop
  und beide Tiehelper logisch unveraendert. Die Toleranz ist `0.001` fuer
  quadratische Entfernung; das Oracle benutzt keinen Produkt-Tiehelper.
- Ergebnisparitaet auf square8 und hex_axial_v1: kleine deterministische
  breite Querysets, die echte 9.408-Tile-GM01 mit repraesentativen blockierten
  Zielen sowie innen-/aussenliegenden Anfragen, leer/all-blocked/null,
  exakte und nahe Epsilonties, nahe blockierte Kandidaten, In-place-Walkable- /
  World-/Gridposition, Runtimeoverrides, Re-register und Clear.
- `resolve_walkable_target()` behaelt seinen kompletten Ergebnisinhalt.
  Querys duerfen Tile-Daten, Overrides, Registryrevision und Dirtygrids nicht
  veraendern.
- Eine kleine Fixture mit fruehem nahem walkable Kandidaten und vielen
  weiter entfernten Tiles verlangt gleiche Auswahl bei deutlich weniger
  Live-Walkabilityreads. Der aktuelle Produktloop liefert einen echten
  Counter-RED. Keine Millisekundenschwellen oder FPSbehauptungen.
- Marker bei vollstaendigem Erfolg: `R4_NEAREST_WALKABLE_PASS`.
  Bounded Queryzahlen, keine laufende Mission, kein HPA-Build, kein Renderer.

## Betroffene Dateien / lokale Pruefung
Zunaechst ausschliesslich diese Task und der neue Verifier. Moeglicher
spaeterer Produktbereich ausschliesslich `scripts/terrain/terrain_registry.gd`.
Root fuehrt den neuen Verifier mit privatem Userpfad/Output aus; danach
TASK409, TASK125, TASK475 und passende Movement-Lifecycle-Nachbarn.
Die zwei gleichen nativen 90-s-Routen bleiben ein eigener Leistungsnachweis.

## Quellen / Risiken / offener Status
Auditfreeze vor neuem Test: Registry SHA256
`4699ae88a883007dea2f96aaa752dffd8ab27f1dc328bd8c22d6d010c6c5c55f`,
Movement `9b7f2774579ba452434669b6b65e6888fdd478067c68107183f2c9d61da2bfaa`,
Controller `b247162e46edaca4e5696c9d96242384aca102ff03cb8f2e2c84c103627cddaf`.
Ein Getter-Reordering darf den bestehenden epsilonsensitiven Vergleich nicht
neu ordnen oder durch eine andere Distanz-/Tieformel ersetzen. Verbesserte
Callcounts beweisen nur vermiedene Lookup-Arbeit, keine allgemeine
Ruckelfreiheit. Gebundene Rootlaeufe und der aktuelle offene Umfang stehen unten.

## Gebundener RED / Vorher-Nachbarn / Produkt-GREEN
Task wurde vor dem Verifier angelegt. Der eingefrorene Verifier SHA256
`35f8b9f88df374b822a68c01cea2ad5a3d7f5aeb7133c75088b6bf21c6b4cc38`
ist fuer RED und GREEN unveraendert. Unabhaengige Sourcepruefung: Original-
Nearest-Loop und beide Tiehelper stimmen nach Klassen-Deindentierung exakt
mit der Originalquelle ueberein; Testreview APPROVED scoped. NaN/INF und
nichttransitive Epsilonketten sind Sourceargumente, keine behauptete
zusaetzliche Testabdeckung.

Root-Vorher-Nachbarn `nearest_neighbors_before/20261108T100948Z-471fe547/`:
5/5 Gates gruen (TASK409, TASK125, TASK423, TASK475, TASK501). Das ist die
gezielte Nachbarmatrix vor der Produktaenderung, kein nativer Leistungsbeleg.

Root-RED `nearest_walkable_red/20261108T101203Z-7fdb8f00/`: 105 Assertions
gruen, genau zwei Counter-Assertions rot. Beide Topologien bezahlen im
Original 258 Live-Walkabilityreads fuer 258 Tiles bei gleicher Auswahl.
Die zwei protokollierten Engine-ERROR-Eintraege sind die absichtlichen
Assertion-`push_error()`-Meldungen; kein Parserfehler und kein Timeout.
Der unveraenderte RED bleibt mit Original-Registry `4699ae88...5c55f` erhalten.

Nach diesem RED fuehrte ausschliesslich Root den engen Guard-Reorder aus:
Distanz und unveraenderter Nearest-Tieguard stehen jetzt vor `is_walkable()`;
Bestwerte werden weiter erst nach erfolgreicher Live-Walkability gesetzt.
Kein Cache, keine Helper-/Movement-/Command-/Budgetaenderung. Neue Registry
SHA256 `1aa3b96e1010298d050d1aade5b27c40ddb560dccd17ac4ad1d74223d37974b7`;
Movement bleibt `9b7f2774579ba452434669b6b65e6888fdd478067c68107183f2c9d61da2bfaa`.

Root-GREEN `nearest_walkable_green/20261108T101618Z-c9a91da4/`: 107/0,
Enginefehler 0, Marker `R4_NEAREST_WALKABLE_PASS`. Beide Counterfixtures
bezahlen jetzt 2 statt 258 Live-Walkabilityreads bei gleicher Auswahl.
Alle Oracle-, vollstaendigen Resolution-, Live-In-place-, Override-,
Re-register-/Clear- und Quellreinheitspruefungen bestehen auf den gebundenen
Quellen. Die Belege liegen jeweils unter `output/runtime_hitches_r4_20261107/`.

Der Loop bleibt linear und berechnet weiter die Distanz aller Tiles.
Der nachgewiesene Gewinn ist vermiedene Lookup-Arbeit; Millisekunden- oder
allgemeine FPSwirkung folgt daraus nicht. Finale 75-Gate-Matrix laeuft;
zwei native 90-s-Nachlaeufe auf eingefrorenen Produktquellen und die daraus
abgeleitete Leistungsbewertung sind weiterhin offen. Keine Main-/Release-
oder allgemeine Ruckelfreiheitsfreigabe aus diesem fokussierten GREEN.
