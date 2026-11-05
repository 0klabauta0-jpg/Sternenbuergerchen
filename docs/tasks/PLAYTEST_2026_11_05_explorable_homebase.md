# Begehbare Heimatbasis

## Ziel / Problem
Die ausdrücklich gewünschte Heimatbasis soll als tatsächlicher kleiner Ort
begehbar sein. Personal, Team, Flightdeck und Einsatz bleiben gleichzeitig
über ihre bestehenden Meta-Owner und gut erreichbare Controls bedienbar.
Die aktuelle Nutzeranweisung ersetzt dafür die alte UI-first-Begrenzung.

## Bestand und Entscheidung vor Code
`scenes/tests/frontier_art_preview.tscn` besitzt bereits einen nativen
Art-/Hexausschnitt mit `SimulationRoot`, `UnitRegistry` und synthetischen
Actors. Dieser Preview ist ein Testfixture, keine produktive Basis.
`maps/frontier_workyard_24x20.json` ist eine gespeicherte 24x20-Hexkarte mit
Terrainwahrheit, Straße und Utility-Objekt. Eine neue, getrennte Basiskarte
wird daraus abgeleitet; das Original bleibt unverändert. Bestehende
Frontier-Gebäude, Commanderfigur und Cutlass werden direkt wiederverwendet.

Die neue Control-Szene kapselt ihren Runtimezweig und Viewport. Ein einziger
ephemerer Commander-Actor wird in einer lokalen `UnitRegistry` registriert.
Nur die bestehende `SimulationRoot` bewegt ihn per `move_to_position` und
bestehender Terrainnavigation. Die Welt zeigt diese tatsächliche Position.
WASD und Rechtsklick erzeugen Commands; sie verschieben kein Anzeigesprite.

## Umfang / Nicht-Ziele
Neue gespeicherte Basiskarte, einbettbare `ExplorableHomebase`-Control-Szene,
vier erreichbare Konsolen, sichtbare Servicedrohne und gezielter Verifier.
Keine Änderungen an HomebaseScreen, MetaFlow, Missioncontroller oder Core.
Keine zweite Roster-, Loadout-, Inventar-, Transport-, Missions- oder
Multiplayerwahrheit. Der ephemere Commander ist kein persistierter Operator.
Keine neuen GLBs oder Bildgenerierung; vorhandene aktive Quellen bleiben.

## Vertrag / API
- `set_active(bool)` aktiviert nur den lokalen Basiszweig. Deaktivierung
  stoppt Basiscommands, Avatarticks und Drohnenanimation. Missionszeit bleibt
  allein beim ursprünglichen Mission-Owner; kein SceneTree-Pause.
- `terminal_open_requested(id: String)` liefert ausschließlich `personnel`,
  `team`, `flightdeck`, `mission` an den vorhandenen Meta-Presenter.
- `exploration_exit_requested` lässt den Host zur Übersicht wechseln.
- `get_exploration_snapshot()` liefert tatsächliche Actorposition, Quelle,
  Kartenbounds, Terminals, Aktivität und Simulationsdiagnose read-only.
- Eingabe gilt nur bei aktiver sichtbarer Welt und Fokus im Welt-Control.
  Über Root-UI oder Textfeldern entstehen keine Basis-Movecommands.
- Terminalinteraktion benötigt tatsächliche Nähe; Welt-Hotspots und E sowie
  der klare Übersichts-Exit sind sichtbar. Root behält direkte Navigation.
- Authored Servicedrohne ist ein dekorativer Visual-Owner mit lokaler
  Meshbewegung und Schub, ohne Combat- oder Registryidentität.

## Akzeptanz / Prüfung
Gezielter Strukturverifier lädt die Szene, prüft gespeicherte Kartenquelle,
Registryidentität, Simulationsbewegung über mehrere echte Physicsframes,
Blockerabweisung, Terminalnähe, Ownerpause und unveränderte Actoridentität.
Keine Tests setzen Actorpositionen oder überspringen Simulationsphasen.
Native Root-Prüfung im Vollbild: Gehen, Zielklick, Konsole/Exit, UI-Grenze,
sichtbarer Drohnenhover und gleiche Landschaft bei 1440-Höhe/Ultrawide.
Technische Prüfung ersetzt weder native Bildprüfung noch Nutzerurteil.

## Dateien / Risiken
Neue `scripts/meta/explorable_homebase.gd`, lokale Actor-/Art-Helper,
`scenes/meta/explorable_homebase.tscn`,
`maps/homebase_frontier_exploration.json` und gezielter Verifier.
Verschachtelter Viewport kapselt den bestehenden CanvasLayer-Renderer;
Auflösung, Darstellungskosten und Eingabekoordinaten nativ prüfen.
Quellenpfade und SHA-256 gehören in das Kartensource-Manifest/Snapshot.

## Dokumente
AGENTS, PROJECT_BRIEF, ARCHITECTURE, CODEX_RULES, IMPLEMENTATION_STATUS,
Haupttask `PLAYTEST_2026_11_05_fullscreen_ux_visuals.md`,
`graphics_reference_revision_contract.md`, `terrain_truth_visual_audit_contract.md`,
`homebase_direct_dropship_flow_contract.md`, `flight_altitude_layer_contract.md`.

## Authored Quellenstand
Original-Workyard SHA-256:
`de2845f4b653e081161cbc6a3787e3b123c8e31948d0144f7ed9af64da185952`.
Die neue Datei enthält 480 gespeicherte Hexfelder, 69 reservierte Gebäude-/
Schiffzellen und vier Konsolen. Eine unabhängige reine JSON-Nachbarschaftssuche
erreicht alle vier Konsolen und alle 411 begehbaren Felder vom Commanderstart.
Das ist ein Contentcheck, kein nativer Laufbeweis.
Alle fünf vorhandenen GLB-Quellen (drei Strukturen, Cutlass und Operator)
wurden aktuell gegen die im Mapmanifest gespeicherten SHA-256 geprüft.
Die geschlossenen Außenhüllen reuse `frontier_closed_buildings.gd`, darunter
die aktuelle Review8-Halle mit geneigten Tealdachflächen. Ihre Hüllen liegen
innerhalb der gespeicherten Quellbounds plus 0.22m Reservation.
Der abgestellte Cutlass ist ein statischer Asset-Prop ohne Craft-/Payload-ID;
er erzeugt keinen Transportstatus. Die Servicedrohne besteht aus drei
dekorativen primitiven Meshes und einem gelesenen Motion-/Schubhelper.

## Technischer Zwischenstand
Rootlauf
`output/playtest_20261105/assets_base_first/20261105T070340Z-070396a7/explorable_base.log`
besteht mit **25/25**, ohne Parse-/Scriptfehler. Er prüft tatsächliche
SimulationRoot-Bewegung über 90 Physicsframes, registrierte Identität,
gespeicherte Blocker, reale Terminalnähe, unveränderte Position/Ticks beim
Deaktivieren und tatsächliche zeitliche Drohnen-Meshbewegung.
Der zugehörige Report bestätigt isolierte Nutzerdaten und das unveränderte
normale Roster einschließlich Bytes, Länge und Schreibzeit. Das Gesamtreport-
Ergebnis enthält andere Agentenslices und ist keine gemeinsame All-green-
Freigabe. Native Vollbild-Eingabe-, Bild- und Ultrawide-Prüfung bleiben beim Root.

## Nativer Vollbild- und Eingabebeleg
Root hat die echte Basis unter Windows/Vulkan im **3440x1440**-Vollbild
geprüft: **86/86**, Exit 0 ohne Fehlassertionen,
`output/playtest_20261105/native_base_controls/20261105T080323Z-11f16fe6`.
Der Lauf umfasst tatsächliche D-/Rechtsklickbewegung, E-Terminal und Exit
über die bestehende Commander-/Commandruntime. Der frühere pinke
Fallbackblockerbefund ist von Root im Visualowner der Basis korrigiert:
die vorhandenen 69 unwalkable Zellen bleiben erhalten und werden dem
bereits vorhandenen externen GLB-Stageowner zugeordnet. Keine Transport-,
Roster- oder Inventarwahrheit wurde dafür angelegt.
Die dekorative Servicedrohne nutzt den vorher technisch geprüften
Motion-/Schubhelper; sie bleibt ein Prop ohne Fighter-/DroneRegistry.
Die native Prüfung ersetzt keine gestalterische Nutzerabnahme.
