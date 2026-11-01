# Pass07: gespeicherter Frontier-Versorgungshof

Der erste begrenzte Content-Slice laedt die Frontier-Grafik ueber die vorhandenen Karten-, Katalog-, Editor- und Missionsklassen. Die Karte hat 24x20 Axial-Hexzellen, ein originales `structures_pass04/utility_fuel_01.glb` bei 0,35 und einen gespeicherten graugruenen Strassenstreifen. Sie ist kein Ersatz fuer die reichere Grafikvorschau und keine neue Basisbau-/Innenraum-/Versorgungsmechanik.

`terrain_visual_theme_id=frontier_illustrated_v1` aktiviert das vorhandene Grafikprofil im `TerrainMap3DView`. Ein explizites `set_frontier_art_enabled(true/false)` gewinnt weiterhin; `clear_frontier_art_override()` folgt wieder dem CLI-Default `--frontier-art-v1` oder dem gespeicherten Theme. Topologie und Grafikprofil sind unabhaengig. Der Resolver in `_read_map_transform` invalidiert nur den Materialcache und ruft keinen rekursiven Render auf. Ein Wechsel zum alten Theme stellt aktive Licht-/Environmentwerte wieder her. Generische Roadmaterialien verwenden `paved_surface=true`, aber keine an feste Previewkoordinaten gebundenen Gebrauchsspuren.

Editor und MissionSetup reichen die gespeicherte Topologie nun an ihre vorhandene TerrainRegistry weiter. Fehlendes Topologiefeld bleibt `square8`. Sieben feste belegte Zellen um den Utility-Anker `(11,9)` sind im JSON als `walkable=false` gespeichert; der Renderer berechnet keine Navigation aus Meshes. Die offene Tank-/Servicegruppe bekommt in diesem Slice keine neue LOS-/Deckungsmechanik. Neue Paletteplatzierungen erhalten noch keinen automatischen mehrzelligen Footprint; der gepruefte Hof ist bewusst ein fester authorierter Kartenausschnitt. Mehrzellige Gebaeude, Rampenhoehen und vollstaendige Hex-Editortools sind Folgearbeit.

## Regulaer im vorhandenen Editor starten

1. `scenes/editor/map_editor.tscn` im Godot-Projekt starten.
2. Im vorhandenen rechten Bereich **Mission Scenario** nach unten scrollen, **Load** waehlen und `res://data/mission_scenarios/frontier_workyard_24x20.json` laden. Nicht den oberen Map-Load-Dialog fuer die Scenario-Datei verwenden.
3. **Live Test** waehlen. Die bestehende Mission `scenes/tests/mission_reactivity_test.tscn` startet mit dem geladenen Kartenpfad. Ein Fireteam auswaehlen, einen freien Ziel-Hex anklicken, Move (`BW`) und `GO` verwenden.

Die Missions-PackedScene setzt bereits vor P07 `defer_friendly_runtime_activation=false`; der Meta-Pfad setzt seinen eigenen Wert separat. Weder Editor-API noch Startpolicy wurden fuer diesen Slice geaendert. LZ ist nicht in der Karte gespeichert; dieser Nachweis prueft keine Meta-/Dropship-Deploymentkette.

Ein reproduzierbarer Authoringlauf mit vier normalen Roster-Units in BLUE laesst sich ohne neue UI starten:

```powershell
$workyardGodot = 'C:/Users/bjoer/AppData/Local/Programs/Godot/Godot_v4.6.2-stable_win64_console.exe'
& $workyardGodot --path . --script scripts/tests/frontier_runtime_map_slice_verifier.gd -- --play-workyard
```

Der Runner laedt die Scenario-Datei ueber den echten Editor und dessen unveraenderte Live-Test-Methode. Er verwendet normale Missions-NPCs, MissionTacticalController, FireteamMovementController und SimulationRoot. Er ersetzt keine Figur durch einen Preview-Akteur und teleportiert keine Figur fuer den Bewegungsbeleg. Der interaktive Modus wartet auf normale Spielerbefehle; zum Beenden Fenster schliessen.

## Belege und Grenzen

Der enge Verifier besteht 40/40 Assertions sowohl headless als auch nativ. Der native Forward+/Vulkan-Lauf auf Godot4.6.2 erzeugt vier tatsaechlich geoeffnete PNGs unter `output/grafik_20261101/pass07_runtime/`. Er prueft SaveAs/Reload aller Tilefakten, Map/Registry/View-Hexgleichheit, Legacy-/Overrideverhalten, originales GLB/Boden0, genau ein Modell, keine Missing-Mappings und einen echten MOVE->GO-Lauf. Der beobachtete Leader legt rund645 Weltkoordinateneinheiten in109 Simulations-Ticks ueber13 Zellen zurueck, mit0 reservierten Zellen und0 Nichtnachbarspruengen. Der automatische Lauf nutzt `Engine.time_scale=3`; er beendet die Probe innerhalb85 physischen Welteinheiten zum Ziel. Das ist eine beschleunigte Bewegungsdiagnose, keine Normaltempo-/vollstaendige Teamankunfts- oder Kampagnenabnahme.

Die erste Bildrunde zeigte **481 Editorwarnungen**:480 flache Zellen hatten aus `TerrainMapData.create_empty` den impliziten `edge_type=cliff` geerbt; dazu kam der fehlende Deckungsinhalt. Der Generator setzt jetzt ausdruecklich `edge_type=none`. Ein separater Red-Test hielt den Fehler fest. Finale Bilder und `editor_authoring` zeigen **0 Errors/1 Warning: `map_has_no_cover_tiles`**. Dieser ehrliche Hinweis bleibt sichtbar; es wurde keine erfundene Deckung gesetzt. Der erste Bild-/Metadatenstand bleibt unter `r01_flat_edge_warning/` erhalten.

Der weisse flache Rhombus links der Utility ist der gespeicherte Custommarker `rally_workyard`, kein Loch oder Importfallback. Die Utility-Nahkamera prueft Modellkontakt; sie schneidet Teile des HUDs und eine Figur am oberen Rand ab und ist keine UI-Abnahme. Im Missionsstart-/Move-Paar sind normale Teamproxies und Standard-HUD sichtbar; die vier Ausruestungs-Herofiguren aus der Grafikvorschau wurden damit nicht pauschal uebernommen.

Die zusaetzliche strenge12erMatrix liefert nach Reparatur einer eigenen ungueltigen Configure-vor-Tree-Probe effektiv **10 bestandene/2 weiterhin rote Altchecks**. Der CLI-Nachlauf ist streng gruen mit4/4, die separate Override-/Lichtprobe6/6. TASK158 bleibt29/13 und TASK15986/6. Beide unveraenderten Tests wurden tatsaechlich gegen ein isoliertes Gitarchiv von `501201b0c56ebf3dee7b96541381f1c6de74ee64` mit frischem Userverzeichnis ausgefuehrt: exakt dieselben Fehlerlabels und Counts. `legacy_baseline_comparison.json` dokumentiert0 neue Fehlerlabels; die alten Gates werden nicht gruen umetikettiert. Alte fehlschlagende Assertions koennen ungetestete Unterschiede verdecken; dies ist kein allgemeiner Releasebeweis.

Roots fokussierter aktueller27erNachweis ist transparent konsolidiert:26 unveraenderte Produktionschecks plus ein tatsaechlicher25/25-Hexbewegungs-Retry mit privatem Belegpfad. Der vorherige gemeinsame Belegwriter konnte seine Datei sporadisch nicht oeffnen; Erstfehler/Timeout und gruener Wiederholungslauf bleiben mit Originalhashes verlinkt. Der Harness bekam einen optionalen `--evidence-output`-Pfad und sauberen File-Close/Nullguard, keine geaenderten Simulationsassertions. `qa.parent_final` im Manifest nennt den konsolidierten Report und beide Originalberichte. Das ist ausdruecklich keine Behauptung eines einzigen komplett fehlerfreien27erErstlaufs; TASK158/159 bleiben separat rot.

Reproduktion der Karte/Checks, jeweils vom Projektroot:

```powershell
& $workyardGodot --headless --path . --script scripts/tools/generate_frontier_workyard_24x20.gd
& $workyardGodot --headless --path . --script scripts/tests/frontier_runtime_map_slice_verifier.gd
& $workyardGodot --headless --path . --script scripts/tests/frontier_runtime_map_slice_verifier.gd -- --frontier-art-v1 --cli-profile-check
python C:/Users/bjoer/.codex/skills/godot-game-verification/scripts/run_checks.py --project . --manifest art/frontier_illustrated_20261101/environment/pass07/runtime/checks.json --godot $workyardGodot --skip-import --output output/grafik_20261101/pass07_runtime/strict_runs
```

`--skip-import` gilt hier fuer den bereits importierten unveraenderten GLB-Bestand. Native Aufnahmen mit Root koordinieren. Quellen-/Kontrollhashes und genaue Grenzen stehen im `manifest.json`; Root besitzt Wege, kombinierte P07-Captures, Report und Git-Uebergabe. Bewusste Fortsetzung des unintegrierten Grafikbranches, kein pauschaler Branchmerge und keine kuenstlerische Nutzerfreigabe.
