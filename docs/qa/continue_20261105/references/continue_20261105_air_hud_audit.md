# Air-/HUD-Altgates: Vertrags- und Ursachenabgleich

Arbeitsbasis: Main `01ab595a7b89632629eee0ad3523281e542148a0`,
`task/continue-perf-legacy-20261105`. Zugehoeriger Auftrag:
`../tasks/CONTINUE_2026_11_05_command_hitches_and_legacy.md`.

## TASK_230: bestaetigte fehlerhafte Blackout-Ausnahme

Die Original-Main90-Evidenz unter
`output/playtest_20261105/main90_neighbor_baseline/20261105T073347Z-d1b49e05/`
zeigt 25 bestandene und zwei fehlgeschlagene Assertions: unbekannter
LZ-Marker sichtbar und kein gezaehlter Reveal-Block.

Ursache ist `TerrainMap3DView._air_layer_allows_surface_marker()`: Sie
uebernahm die eigene/neutral/unbekannte Teamausnahme des Flugkoerperpfads
ungeachtet des FoW-Modus. Dadurch wurden Primary-, Requested-, Resolved-
und Craft-LZs sowie Approach-Linien in Blackout auch ohne aktuelle
Tilesicht aufgebaut. Die getrennte Aircraft-Ausnahme in
`_air_layer_allows_air_visual_for_payload()` ist weiterhin beabsichtigt.

Ein reines Entfernen jeder Ausnahme haette die normale Erstlandung
verschlechtert: `MetaLayerFlow` liest `known_terrain` als Settingsdefault;
`MissionTestSetup._get_active_fog_observers()` nimmt nur sichtbare, fitte
Bodenunits. Vor dem ersten Deboarding gibt es noch keine solchen Observer.
Der spaetere Insertion/First-Order-Vertrag (TASK_539) verlangt bereits nach
eigener LZ-Setzung einen sichtbaren Planmarker. Der normale native
Root-Ausgangslauf unter
`output/continue_20261105/command_baseline/20261105T140839Z-190f2e29/baseline.json`
verwendet tatsaechlich `known_terrain`.

Die vom Root bestaetigte Aufloesung praezisiert daher den vorhandenen
`flight_altitude_layer_contract.md` anhand dieses spaeteren Erststartpfads:

| Modus / Zustand | Eigene LZ-/Approach-Planung | Fremde/neutrale LZ-/Approach-Marker |
| --- | --- | --- |
| `off` | sichtbar | normal sichtbar |
| `known_terrain`, ohne aktuelle Tilesicht | sichtbar auf bekanntem Terrain | verborgen |
| `unexplored_blackout`, unbekannt oder nur erkundet | verborgen | verborgen |
| aktive Tilesicht | sichtbar | bestehender Tilesichtpfad |

Craft-Eintraege uebergeben ihren eigenen Payload an den Surfacehelper,
damit ein fremder/neutrale Eintrag nicht den Besitzer des Gesamtpayloads
erbt. Gameplay, Terrainwissen, LOS, Walkability, Flugstatus und die
Aircraft-Ausnahme werden dadurch nicht geschrieben oder umdefiniert.

Der erweiterte TASK_230-Verifier prueft sieben Modus-/Besitzerfaelle mit
expliziten Primary-/Requested-/Resolved-/Craft-LZ- und Approach-Counts.
Gemischte eigene, fremde und neutrale Craft-Eintraege pruefen den Besitzer
jedes einzelnen Markers. Unveraenderte FoW-/Flugquellpayloads und alle
Tile-Dictionaries sichern die reine Anzeigegrenze ab. Die vorhandenen
Hoehen-, Friendly-Air-, Enemy-Contact- und Snapshot-Roundtrip-Pruefungen
bleiben erhalten.

Root-RED vor Produktkorrektur:
`output/continue_20261105/air_red/20261105T141059Z-ad993169/report.json`,
44 bestanden / 14 fehlgeschlagen, keine Parserfehler. Dieser erste RED
entstand noch vor der ausdruecklichen Known-Terrain-Vertragsaufloesung;
die damaligen vier Known-Terrain-Fehler sind deshalb nicht als geforderte
Produktkorrektur zu lesen. Die beiden Original- und acht zusaetzlichen
Blackout-Markerfehler belegen den korrigierten Defekt. Endgueltige
Ownership-RED-/GREEN-Laeufe werden durch den Root separat referenziert.

Der erste Root-GREEN-Versuch
`output/continue_20261105/legacy_first_green/20261105T141541Z-7b001052/`
deckte zusaetzlich den bislang vom Reveal verdeckten Invalidationfehler auf:
TASK_230 69/1, die originale Freigabe-Assertion blieb rot. Ein reiner
FoW-Refresh uebersprang immer den Drop-Rebuild und konnte daher einen
zuvor korrekt weggelassenen Marker nicht nachtraeglich erzeugen.

Ergaenzte Akzeptanz fuer diese notwendige Korrektur:

- Ein reiner Sichtgewinn erzeugt die nun erlaubten Marker; Sichtverlust
  entfernt sie; erneute Freigabe stellt sie wieder her.
- Aenderungen eines unbeteiligten Tiles erhalten dieselben Drop-Nodes und
  nutzen weiterhin den Rebuild-Skip.
- Zwei Aircraft am selben anfangs verborgenen Ort zeigen ohne erneuten
  Flugpayload erst nur das eigene, nach Tilesichtgewinn beide und nach
  Sichtverlust wieder nur das eigene Flugobjekt.
- Die Admission-Signatur betrachtet ausschliesslich Primary-/Requested-/
  Resolved-/Craft-LZ-/Approachpositionen und tatsaechliche Aircraftpositionen
  im aktuellen Drop-Payload. Keine Terrain-, SceneTree- oder Unit-Vollscans.
- Betroffen zusaetzlich `set_fog_of_war_state()` und ein kleiner reiner
  Admission-Signaturhelper in `terrain_map_3d_view.gd`; der bestehende
  FoW-Overlay-/Kontakt-/Dirty-Pfad bleibt erhalten.

Das unabhaengige Nachreview fand ausserdem einen echten P2 am bisherigen
Parentcontainer: `_refresh_drop_visual_visibility_for_fow_delta()` setzte
den gesamten `_drop_root` allein nach dem Besitzer des Gesamtpayloads
unsichtbar. Damit verschwanden sogar einzeln erlaubte eigene Craft- und
LZ-Nodes in einem gemischten fremden/neutralen Parentpayload. Die bisherigen
Counts konnten diesen Unterschied zwischen Aufbau und echter Sichtbarkeit
nicht erkennen.

Zusaetzliche Akzeptanz vor Produktkorrektur dieses Nachreviewbefunds:

- Ein eigener Aircraft und ein erlaubter fremder Aircraft sind tatsaechlich
  `is_visible_in_tree()`, auch nach unbeteiligtem Tile-Delta und einem
  Wechsel des Parentpayloadbesitzers zu fremd oder neutral.
- Sichtgewinn/-verlust betrifft nur die einzelnen neu zugelassenen oder
  ausgeblendeten Craft-/LZ-/Label-Nodes, nicht den gesamten Dropcontainer.
- Foreign-Cargo-Statuslabels pruefen dieselbe eigene Air-/Surfacefreigabe
  wie ihr tatsaechlicher Anker. Ein neutral sichtbarer Parent darf keine
  fremden Cargo-Labels auf unbekannten Tiles freigeben.
- Die Regression prueft echte Node-Sichtbarkeit einschliesslich Cargo-
  Label- und LZ-Nodes; Counts allein erfuellen diese Akzeptanz nicht.
- Die Produktkorrektur folgt erst auf den durch den Root gestarteten RED
  dieses gezielten Verifiers. Engines und Git bleiben beim Root.

Dieser RED ist bestaetigt unter
`output/continue_20261105/air_visibility_red/20261105T143049Z-f60895ab/`:
99 bestanden / 21 fehlgeschlagen. Die Fehlassertionen zeigen genau
unberechtigt sichtbare fremde Cargo-Labels unter eigenem Parent sowie
unsichtbare erlaubte Craft-/LZ-/Label-Nodes unter fremdem oder neutralem
Parent. Keine Parserfehler. Danach wurde der Parent neutral sichtbar
gemacht und jedes Cargo-Label am tatsaechlichen Air- bzw. Surfaceanker
geprueft. Die Admission-Signatur beruecksichtigt auch den Shipposition-
Fallback eines Cargo-Surfacelabels ohne explizite LZ. GREEN und native
Pruefung starten anschliessend durch den Root.

Optionaler nativer Kameravergleich derselben ausdruecklichen Testfixture:
TASK_230 mit `-- --air-fow-capture-dir=<absoluter Pfad>` starten. Die sieben
`task230_<Fall>.png` stammen aus dem tatsaechlichen Viewport. Vorher und
nachher muessen Fenster, Kamera, Fixture und Renderer gleich sein; diese
Bilder sind ein Visualvergleich der Markerpolitik, kein physischer
Missions-/Deploy-Beweis. Die normale Erstlandung bleibt ein eigener
nativer Nachbarpfad.

## TASK_436: historische Anzeigeannahme und umgangener Parentrefresh

Original-Main90: 52 bestanden / zwei fehlgeschlagen, beide an der
Coveragebar. Die uebrigen Securityrollen-, Facing-, Sichtlinien-,
Muzzle-/Trace-, Bubble-, Busch- und Patrolchecks bestanden.

Die sichtbare Coveragebar gehoert zum damaligen TASK_436-Layout. Der
spaetere A5-Auftrag `UI_2026_11_02_a5_kartenrand.md` und der aktive
`ui_native_design_contract.md` verlangen portraitgefuehrte Truppkarten
mit einem primaeren Spielerzustand. `_apply_native_a5_fireteam_card()`
zeigt deshalb bewusst nur Header, Mitgliederportraits und StageLabel.
Eine sichtbare Legacy-Diagnosebar wieder einzuschalten waere eine
Layoutregression gegen diese Nutzerentscheidung.

Die zweite alte Assertion las zudem einen unveraenderten alten
Diagnose-Snapshot: Der Test schrieb direkt in den untergeordneten
`FireteamSecurityController`, ohne das aktive Parent-Verhaltensprofil zu
aendern. `_refresh_fireteam_mini_cards()` verwendet einen Runtime-Cache
ueber Profile, Bewegung, Kontakte und Units; der direkte Child-Eingriff
aenderte diese Inputs nicht. Dies ist kein normaler Command-/Runtimepfad.

Der aktualisierte Verifier uebergibt ein echtes `FireteamBehaviorProfile`
an `_set_active_behavior_profile()` und nutzt
`refresh_fireteam_security_state()`. Er prueft weiterhin exakt vier aktive
Securitymitglieder mit Front-/beiden Flankenrollen im lesenden
Coverage-Snapshot, die Facingmetadaten aller Mitglieder, die aktuellen
vier Portraits und einen sichtbaren primaeren Status. Die Legacybar muss
im A5-Layout verborgen bleiben. Ein weiterer Kartenrefresh darf die
Securityzuweisungen nicht veraendern. Kein Cache wird fuer den Test
geleert, kein Actor versetzt und kein Runtime-/Gameplaywert neutralisiert.

Der erste Rootlauf des aktualisierten TASK_436 bestand 59/59, meldete
aber vier geleakte CanvasItems. Es waren die seit dem Original vorhandenen
vier alleinstehenden `DummyUnit`-Nodes des Assignmenttests. Der Verifier
gibt diese eigenen Testobjekte nach seinen Assertions frei; dies ist keine
Produkt- oder Gameplayaenderung. Ein frischer sauberer Lauf bleibt Pflicht.

## Besitz und Pruefgrenzen

Originalbytes beider Verifier bleiben unter
`output/continue_20261105/original_tests/*.gd.txt` erhalten. Der delegierte
Pass hat keine Engine gestartet und keine Gitoperation ausgefuehrt.
Saemtliche Engine-RED-/GREEN-, normale Erstlandungs- und native
Vergleichslaeufe sowie die abschliessende Evidencebindung gehoeren dem
Root. Verifiererwartungen und Codekorrektur allein sind keine behauptete
GREEN-, Gameplay-, Performance-, EXE- oder Releaseabnahme.
