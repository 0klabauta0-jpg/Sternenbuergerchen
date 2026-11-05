# Unabhaengiges Schlussreview, 05.11.2026

**APPROVED im beauftragten Scope: keine P1-/P2-Befunde.**

Lesend gegen den aktuellen `git diff HEAD` und die neuen, noch nicht in HEAD
vorhandenen Visualhelper geprueft. Datum UTC: 2026-11-05T08:08:03.626153+00:00.
Keine Engine gestartet und keine Produkt-, Test-, Git- oder Savedaten geaendert.
Nur diese Reviewdatei angelegt.

## Scope und Urteil
- **Registry:** Bucketindex enthaelt Tile-Referenzen, keine zweite Gameplay-
  Wahrheit. Register/Replace/Notify/Clear invalidieren. Walkability/Cover werden
  nach der raeumlichen Kandidatenauswahl frisch aus den vorhandenen APIs gelesen.
  Sortierte Originalindizes erhalten Dictionary-Insertion als Tie-Breaker.
  Negative Radien und nicht endliche Positionen behalten den bisherigen Filter;
  breite Abfragen fallen auf den geordneten Vollfilter zurueck.
- **Security:** Combat fragt State/Facing/Badges weiterhin sofort ab. Nur
  Ordervisual/Statusprojektion wird pending gesammelt und vom bestehenden
  0.20-s-Entry geflusht. Pending bleibt auch nach dem Entfernen eines Zustands
  erhalten. Der echte Combatconsumer nutzt den neuen Entry mit Legacyfallback.
- **Meta/Transport:** Verdeckte Basisdarstellung wird dirty; Normalisierung und
  Transfer-/Recovery-Owner laufen weiter. `_show_homebase` macht die Basis vor
  ihrem erneuten Refresh sichtbar. Delta-Whitelist wird vollstaendig vor Mutation
  geprueft; fremde Planaenderungen benutzen den bestehenden Vollpfad. Der enge
  Pfad laedt keine Order-/Phasenausfuehrung neu. Kein persistenter Parallelplan.
- **NPC/Combatvisuals:** Urspruengliches Figurenmodell und Anhaenge bleiben
  erhalten. Nur Readabilitycore, Modellpose und lokale Bodenzustellung aendern
  sich; Vitals/Collision bleiben beim Owner. Statusicons folgen dessen Badge.
  Schussimpulse benoetigen reale Events und vorhandene Source-/FoW-Freigabe,
  sind zeitlich begrenzt und an den Ordervisual-Owner gebunden. Mapidentitaet
  trennt die begrenzte Eventhistorie; Kindknoten werden mit ihrem Owner entfernt.
- **Flug/Grid:** Phasen/LZ/Positionen werden lesend projiziert. Keine Actor-,
  Transport-, Landerechts- oder FoW-Mutation. Schub ist ein Kind der sichtbaren
  Ref03-Instanz; Bodenzustand/Unsichtbarkeit stoppen Darstellung. Shader nutzt
  statische, depth-tested Edgequads mit Pixelabdeckung; kein Kamerarebuild.
- **Maplimit:** Ein begrenztes gemeinsames 4-MiB-Limit deckt die aktuelle GM01.
  ID-/Hash-/Groessen-/Struktur-/Consentpruefung und user-Cachegrenze bleiben
  erhalten. Der fehlende Netzwerk-Payloadtransport wird nicht als neuer Download
  ausgegeben. Contract und spezieller Untertask stimmen mit dem Patch ueberein.
- **Profiling:** Neue Zeitmessungen und Summensnapshots sind an die standard-
  maessig ausgeschalteten Diagnoseflags gebunden. Keine dauernde Vollerfassung
  oder zusaetzliche Gameplay-Mutation durch den Profiler gefunden.

## Gelesene gezielte Evidenz / Grenzen
Task-/Akzeptanztexte fuer Performance, NPCfeedback, Flug/Grid und Maplimit sowie
Registry-Ein-/Ausgabeäquivalenztest, Meta-Hitch-Regression, Security-Batch-Test
und Source-FoW-/Impulsregression gelesen. Die Tests wurden in diesem Review
nicht erneut gestartet; Root besitzt die seriellen Engine- und Vollbildlaeufe.
Die neuen Hooks machen Invalidierung, Atomizitaet, Pending-Flush und Lifecycle
gezielt pruefbar. Kein konfiguriertes `.ai-game-studio/project.json` und keine
scopebezogene ADR-Referenz in den gelesenen Aenderungen gefunden; aktuelle
Projektarchitektur und konkrete Contracts sind hier die Leitplanken.

Der eigene Homebase-/Portraetcode wird durch den anderen Reviewer bewertet.
Beim grossen TacticalController betrifft dieses Urteil Security-Refresh und
Transportdelta sowie deren aufgerufene bestehende Consumer, keine Vollabnahme
seiner gesamten historischen Implementierung. Native Grafik-/Eingabeakzeptanz,
fortgesetzte reale Bewegung, allgemeine FPS, Mehrrechnerbetrieb und Release
bleiben eigene Nachweise. Historische Baselinefehler werden nicht umgedeutet.

## Gepruefter Quellstand
| Datei | SHA-256 |
|---|---|
| `scripts/terrain/terrain_registry.gd` | `4699ae88a883007dea2f96aaa752dffd8ab27f1dc328bd8c22d6d010c6c5c55f` |
| `scripts/meta/meta_layer_flow.gd` | `2a203278aa7d6ccf58a161c1f2c055ee63b3da7e938e3de94f18e91702843604` |
| `scripts/tests/mission_tactical_sandbox_controller.gd` | `adf4f3570cc31af34ecec418ec1b7d8daa39f600fb317c126cafc9d1a838707f` |
| `scripts/tests/mission_combat_loop_driver.gd` | `3988295faae51aeb42b7c612726895faea1f1c6c1e1954fbb579e86e6ce1cf1e` |
| `scripts/terrain/terrain_map_3d_view.gd` | `d0dc3fe2fc5995bbb63e7c624756d733801c0ab0038656ca379be10c47e6b0b5` |
| `scripts/terrain/unit_feedback_icons.gd` | `f13ea48c688dd1f70c458098ffcb80fb8494ce27203caeab27ffa30dfa71e14c` |
| `scripts/terrain/weapon_fire_feedback_pulse.gd` | `9a9fb6d808a52892c09292d0ac13ebc9da0492e8931507e4da42cc4a08bd6142` |
| `scripts/terrain/mission_flight_visual.gd` | `eb2ad6375bb125ef65c6fac1de5a70e767f312e6d2df1d3d78e5aa84e94723c0` |
| `shaders/terrain/hex_grid_coverage.gdshader` | `024bc445d68393a7bacc001cd799c8f0865f91e6dd3602d150e9914578b48b8b` |
| `scripts/multiplayer/multiplayer_map_manifest.gd` | `e40ee1230a585d52f470622eb3909c0fbf331efbdd1c4d9a1baea91b5b24818f` |
