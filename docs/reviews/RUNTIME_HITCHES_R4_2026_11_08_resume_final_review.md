# R4: unabhaengiges Abschlussreview nach Wiederaufnahme

## Ergebnis und Rollen

**APPROVED scoped. Keine bestaetigten offenen P1/P2 im unten gebundenen Scope.**

Unabhaengiger Reviewer ohne Autorenschaft an Produkt oder Tests. Ausschliesslich
lesendes Source-/Evidence-Review; keine Engine, kein Git, keine Profilierung,
kein Packaging und keine Produktmutation. Einzige eigene Datei ist dieser neue
Review. Basis laut Root und R4-Task ist Main
`3b12b2878b42d1be0a7a2e8e925cf13835ff1d78`, Arbeitsbranch
`task/runtime-hitches-r4-20261107`; Branch/HEAD wurden hier nicht per Git gelesen.

AGENTS, PROJECT_BRIEF, ARCHITECTURE, CODEX_RULES, aktueller Statusauszug,
Roadmap, R4-Haupt-/Untertasks, beide Reviews vom07.11. sowie HUD-, Combat-,
Fog- und Unit-Facing-Contracts wurden gelesen. Vorhandene Source-Baselines
wurden direkt mit den aktuellen Produkt-/Testquellen verglichen.

## Aktuell gelesene Pins

SHA256 der gelesenen Dateien, beim Review frisch aus dem Arbeitsbaum erfasst:

| Quelle | SHA256 |
| --- | --- |
| `scripts/tests/mission_tactical_sandbox_controller.gd` | `b247162e46edaca4e5696c9d96242384aca102ff03cb8f2e2c84c103627cddaf` |
| `scripts/core/fog_of_war_system.gd` | `544b976ad1f76ea430bbc5b160be107e947366a41a8ccb6ef7d0dc92cdb5b822` |
| `scripts/terrain/terrain_map_3d_view.gd` | `fb9905172a9115c6458a90c3fdb896895c0576978bd999a6567c7711458b60f2` |
| `scripts/terrain/weapon_fire_feedback_layer.gd` | `3087b4abdcc92c93a3449187bab623899b2d520e78f161194d77a329be75db84` |
| `scripts/terrain/weapon_fire_feedback_pulse.gd` | `35a6d435284e19844277fb8e57b7db1e6fde81b524d2dc25e7a6fd9a4161ab04` |
| `scripts/tactical/periodic_hud_projection_queue.gd` | `cabe261aaf2b83dbd77454eeca6f0d21608bd4f8f0add1b1d4b6ecfa4f73d98f` |
| `data/npc_unit_visual_mapping.json` | `a7d133cdc510b71eedf4d3e7fdd08d68dc49252d0377ff9e56315bfcb6c70159` |
| `scripts/tests/continue_20261105_command_hud_batch_verifier.gd` | `75f2f999c67ced0e276c97ac0a204ae509c89779e8716b355cc96c8d019b0cda` |
| `scripts/tests/task_174_character_helmet_blaster_attachment_verifier.gd` | `e3b96fcdd2ad0ae09e228fe4c25cf1da465b3bdc94402ba1639e7d56c29d4f9b` |
| `scripts/tests/package_runtime_hitches_r4_20261107.py` | `60201a2a2ba5a2f0b9f1bcdcfe5676ae197081edde06e54fa0d0e87530b3ed41` |

Die bestehenden Equalityhelper im unveraenderten `tactical_ui_theme.gd`
wurden mitgelesen; die R4-Aenderung nutzt sie im Controller. Es wird kein
neuer Theme-Produktpatch behauptet. Die sieben Produktpins oben entsprechen
den erfassten Sourceinputs der gelesenen finalen Matrix und ihres Nachlaufs.

## Source-, Autoritaets- und Lifecyclepruefung

- Fog verwendet die vollstaendige Point-LOS-API beziehungsweise die bisherige
  Terrain-API als Fallback. Der reale LOS-Body bestaetigt die bereits enthaltene
  Terrainpruefung. Keine Reichweiten-/Terrainlockerung. Frische vollstaendige
  Fogquellen bleiben publiziert; nur der nicht geometrisch konsumierte
  `last_seen_tick` entfaellt aus der dynamischen Geometriesignatur. Exakte
  Position, Detection, Team, Terrainwissen und aktuelle Sicht invalidieren weiter.
- Gemeinsame Orderquellen bleiben lokale synchrone Werte; die bestehenden
  Consumer kopieren ihre Inputs. Strategic OneScreen reicht nur seinen frischen
  lokalen NextInteraction an den reinen Handoffhelper. Standalone liest neu,
  explizit leerer Input loest keinen versteckten Runtime-Fallback aus.
- Karten-/Craftguards begrenzen konkurrierende besessene Praesentationsfelder;
  Quellen, Gates, Metadaten, Tooltips und Callbacks werden weiter projiziert.
  GO-Timing erfasst vorhandene Diagnose-/Zeit-/Zaehlerdaten und belaesst die
  Commandgrenzen. Entfernte doppelte GO-Buttonarbeit liegt weiterhin vor
  derselben Publikation im finalen Feedbackowner.
- Die vier HUD-Keys halten nur Schedulingmetadaten. Ticketentnahme vor Ausfuehrung,
  Generation, Deferredregistration und Engineframeguard erhalten Reentry und
  maximal eine periodische Phase je Renderframe. Light bleibt unmittelbar;
  Full uebernimmt Force vor Cancel und entwertet nur alte Arbeit. Jeder Job
  oeffnet/schliesst seinen eigenen frischen synchronen ReadModel-Pass.
  Sceneexit/detached und fehlender Manager besitzen explizite Grenzen.
- Pulse liegen ausserhalb des geloeschten Orderroots. Current-Auswahl nach
  Tick/stabiler Driver-ID, maximal acht Quellen, Historyausschluss,
  First-receipt-/No-Replay-Grenze, begrenzte Historie, TTL, Mapkontext und
  laufende Source-FoW-Admission bleiben getrennt. Posefeedrevision erfasst
  alle acht ausgewaehlten Quellen vor dem Heavy-Dreier-Earlyreturn.
- Muendungsmarker haengen am tatsaechlichen primaeren Waffenmesh. A/F-
  Meshchild-Yaw0 erbt die bisherigen Attachmentdefaults; Socketroot und Scale
  werden nicht als Ersatz verschoben. `standShoot` nutzt den vorhandenen
  Import-/UpperBody-Baker statt eines zweiten per-frame-Poseowners. Menschenmodelle
  verlieren nur den ueberdeckenden Hostile-Core; Missing-Asset/Fallback bleibt.

Keine bestaetigte neue Gameplayautoritaet, Actor-/Facingmutation, stale
ueber Frames gehaltene Runtimequelle oder verlorene Cancel-/Forceanforderung
in diesen geprueften Hunks.

## Tests und erhaltene rote Historie

Die gelesenen Reports bestaetigen die urspruengliche Schlussmatrix
`final_regression_matrix/20261107T110517Z-78f3a92e`:68/69. Ausschliesslich der
alte Command-Batch-Test ist dort39/4 rot. Sein separater aktueller Nachlauf
`command_batch_schedule_green/20261107T111155Z-1915a15f` ist48/0 mit Exit0,
Errors0, isoliertem Profil und identischen Produktpins. Das ergibt69 final
abgedeckte unterschiedliche Gates; die Originalmatrix wird dadurch nicht
nachtraeglich als69/69 ausgegeben.

Direkter Testdiff: Alle43 bisherigen fachlichen Command-Praedikate bleiben;
fuenf neue Checks verlangen Enqueue ohne Heavyarbeit und den echten
Managerabschluss ueber vier unterschiedliche Processframes. Nur der
Beobachtungszeitpunkt folgt dem neuen Scheduler. Move/GO, Physicscommit,
Transportforce, aktuelle Karte, Hidden-Memberidentitaeten und Details bleiben
streng. Direkter Managerdrain ist ein Komponentenfixture, kein nativer Lastbeleg.

TASK174 behaelt die Richtungsschwellen.85/.70 und alle sonstigen Gates.
Zwei zusaetzliche Vorbedingungen verlangen tatsaechlich lowered/playing-idle;
die Oracle liest sichtbare Meshfront(-Z), geometrische Magazinrichtung(-Y)
und kanonischen Proxy+X-Ruecken. Dokumentierte Original-Main81/2,
ActualMesh83/2 vor Produktfix und85/0 danach bleiben getrennt erhalten.
Das aktuelle TASK402 erwartet den datenverankerten importierten UpperBody-
Hold fuer `standShoot` und fordert echte gebackene Importtracks; die17
Rohclips und sechs Combat-Cases bleiben eigenstaendige Pruefgegenstaende.
Die aktuelle Queue-, Fog-, Pulse-, Posefeed- und Pose-Stability-QA wurde
source-seitig mitgelesen. Es wird kein eigener Engine-PASS behauptet.

## Packager und ausdrueckliche Grenzen

Der gelesene, nicht ausgefuehrte Packager bindet aktuelle Quellen aus der
R3-Pfadmenge plus expliziten R4-/Test-/Resourceinputs. Er archiviert die
Originalbytes aller R4-JSON/LOG/TXT/RAW-Dateien; `.raw` ist eingeschlossen.
Neue Artefakte entstehen ausschliesslich im neuen QA-Namespace; vorhandene
Ziele werden abgelehnt. Er loescht/restauriert nichts. Hash-/Laengen-/mtime-
Preservation vor/nach Packaging, begrenzter Streamingtransfer, ZIP-CRC-/Hash-
Readback und striktes95-MB-Budget sind vorhanden. PNGs sind explizite Auswahl.
Der Packager bescheinigt Verpackung/Preservation, keine fachlich gruene
Gesamtmatrix und keine historische Sourcegleichheit. Endmetadatenchecks
erkennen gewoehnliche Schreibdrift; es ist kein atomarer Filesystemsnapshot.

Dieser Review nimmt native Frameverteilungen, verbleibende Maximalspitzen,
reale kontinuierliche Bodenbewegung/Groundcontact, physisches gegenseitiges
Schiessen und native Pixel-/Achsenwirkung ausdruecklich nicht ab. Gelesene
synthetische Renderer-/Schedulingtests ersetzen diese Root-Gates nicht.
Kein allgemeines FPS-/Ruckelfreiheits-, UX-, EXE-, WAN- oder Releaseurteil.
Mainintegration, Push und frischer Main-Smoke sind ebenfalls keine Leistung
dieses Reviews. Ein anschliessender Movement-/Produktdelta braucht eigenes
enges Nachreview und neue passende Evidence; diese Pinfreigabe deckt ihn
nicht automatisch ab.

## Enges Nachreview: Nearest-Walkable-Guardreorder

Nach Ende des ersten Root-Profilfensters wurde ausschliesslich der neue
Registrydelta unabhaengig gelesen. **APPROVED scoped; keine bestaetigten
P1/P2 fuer diesen Delta.** Keine Produkt-/Test-/Taskmutation oder Engine-
ausfuehrung durch den Reviewer; nur dieser Abschnitt wurde ergaenzt.

Frisch gepruefte Quellen:

- Erhaltenes Original
  `output/runtime_hitches_r4_20261107/source_baseline/scripts__terrain__terrain_registry.gd.txt`:
  SHA256 `4699ae88a883007dea2f96aaa752dffd8ab27f1dc328bd8c22d6d010c6c5c55f`.
- Aktuelle `scripts/terrain/terrain_registry.gd`:
  SHA256 `1aa3b96e1010298d050d1aade5b27c40ddb560dccd17ac4ad1d74223d37974b7`.
- Unveraenderter neuer Verifier
  `scripts/tests/runtime_hitches_r4_20261107_nearest_walkable_verifier.gd`:
  SHA256 `35f8b9f88df374b822a68c01cea2ad5a3d7f5aeb7133c75088b6bf21c6b4cc38`.

Der vollstaendige direkte Registry-Dateivergleich zeigt genau einen Hunk
in `get_nearest_walkable_grid()`: Die bestehende Live-Walkabilitypruefung
steht jetzt nach unveraenderter quadratischer Distanz und unveraendertem
`_is_nearest_candidate_better()`. Dazu ein erklaerender Kommentar. Keine
anderen Registrymethoden, Comparatoren oder Datenfelder wurden geaendert.

Beide Guards sind im aktuellen Produkt rein. Das Besttuple wird weiterhin
nur aktualisiert, wenn derselbe Kandidat beide Pruefungen besteht. Ein
geblockter, geometrisch besserer Kandidat kann insbesondere weder Bestdistanz
noch Bestgrid setzen. Die Tile-Einfuegereihenfolge bleibt identisch; damit
bleibt auch die bestehende epsilonsensitive beziehungsweise nichttransitive
Tieauswahl unveraendert. Es gibt keinen neuen Sortier-/Minimierungsalgorithmus.
NaN/INF werden nicht neu normalisiert: Der erste walkable Kandidat wird wie
bisher bei leerem Besttuple akzeptiert; folgende Vergleiche verwenden exakt
die bisherige Formel einschliesslich `0.001`. Diese Nonfinite-Einordnung ist
ein Sourceargument, kein gesondert ausgefuehrter Fixturebeweis.

Die relevante Wahrheit wird weiterhin live gelesen: getypte Tile-Worldposition,
direktes `walkable` und aktuelle Runtimeoverrides. Kein Cache und keine neue
Notify-/Revisionspflicht wurden eingefuehrt. Das Reordering setzt keine neue
Gameplaymutation oder zweite Walkabilityquelle voraus.

Der schon vor Produktfix unabhaengig gelesene Verifier kopiert den originalen
exhaustiven Loop sowie beide Tiehelper source-exakt, abgesehen von der
Subclass-Einrueckung. Er liest nicht den Produktcomparator als Oracle.
Blocked-first/-better, direkte Walkable-/World-/Gridpositionsaenderung ohne
Revisionsbump, Overrides/Clear/Re-register, X-/Y-/Epsilonties, beide Topologien,
komplette Resolutionpayloads und Quellfingerprints sind vorhanden. Die
GM01-Fixture verwendet alle9408 authored Tiles und16 Anfragen; ihre aktuellen
Origin-/Halfsizeannahmen0/64/32 stimmen mit der gelesenen Karte ueberein.

Root meldete den vor Produktfix erhaltenen105/2-RED mit ausschliesslich den
beiden Counterassertions rot. Der anschliessend selbst gelesene Report/Log
`nearest_walkable_green/20261108T101618Z-c9a91da4` bestaetigt107/0, Exit0,
Errors0, Isolation und exakt den aktuellen Registry-/Verifierpin. Die zwei
258-Tile-Fixtures lesen jeweils2-mal Live-Walkability bei unveraenderter Wahl.
Das beweist vermiedene Lookup-Arbeit im fokussierten Fall. NaN/INF und eine
laengere nichttransitive Tiechain sind keine separaten Testfixtures.

Eine noch laufende erweiterte75-Gate-Matrix und nachfolgende native90-s-
Vergleiche sind hier nicht als bestanden ausgegeben. Insbesondere folgen aus
diesem Callcount-/Source-Nachreview weder native Framezeitgewinne noch eine
Abnahme verbleibender Maxima, kontinuierlicher Bodenbewegung/Groundcontact
oder physischer Kampfereignisse. Die uebrigen Grenzen dieses Reviews bleiben.
