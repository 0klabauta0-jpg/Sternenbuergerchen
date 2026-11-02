# Pass05: unterschiedliche geschlossene Aussenhuellen

P4 verwendete zwei fast gleiche Kastenformen mit identischen Dachplatten und flach aufgesetzten Fenstern/Toren. Nach geoeffnetem Vergleich mit Rostgrenze und Freihafen wurde nur der vorhandene Godot-Builder `scripts/terrain/frontier_closed_buildings.gd` ueberarbeitet. Kenney-basierte GLBs, Figuren, Schiffe und Gameplay bleiben unveraendert. Dies ist ein grafischer Kandidat, keine Nutzerabnahme.

Das Habitat hat nun drei verschieden angeordnete gefaste Petrol-Dachfelder um einen tieferen Servicekanal, ein kompaktes Life-Support-Modul, einen getragenen Eingangsvorbau und eine teilweise warm belegte Fenstergruppe. Die Halle hat eine echte asymmetrische Hoehenstaffelung aus hoher Lagerbay und niedrigerem Buero, ein schweres gegliedertes Torportal, einen Dachmonitor/Technikzug und tragende Fassadenrippen. Beide erhalten tiefe Fensterbrauen/-baenke, grosse leicht unterschiedliche Materialkassetten und einen dunklen geerdeten Sockel. Einzelne warme Streifen/Fenster sind schwach emissiv; keine Omni-/Spot-/sonstigen Lichtknoten wurden hinzugefuegt und globales Licht/Environment bleiben unveraendert.

| Eigene Godot-Aussenhuelle | Habitat | Halle |
|---|---:|---:|
| Dreiecke | 2588 | 2508 |
| Meshes | 57 | 58 |
| Breite | 2,585 m | 3,845 m |
| Hoehe | 1,202557 m | 1,616800 m |
| Frontueberstand inkl. Schrift | 0,218 m | 0,213 m |
| Seitlicher Ueberstand | 0,085 m | 0,085 m |
| Hoehe ueber Original-BBox | 0,150807 m | 0,146800 m |

Alle Mesh- und Schrift-AABBs bleiben innerhalb der urspruenglichen XZ-Huelle plus 0,22 m und der Originalhoehe plus 0,20 m. Bodenminimum ist Y0. Die vorhandene 0,30-m-Navreserve und die autoritativen Kartenfakten werden nicht geaendert. Alle Huellenteile haengen am bestehenden Shell-Root, sodass C weiterhin die gesamte Aussenhuelle ausblendet und das originale Schnittmodell zeigt. `DoorFrame` und `FrontWindowFrame` sowie ihre Abstandsregression bleiben erhalten. Kein neuer Innenraum-, Tor-, Simulations-, Collision- oder Navigationszustand.

Die eigene Godot-Geometrieprobe besteht 21/21 Pruefungen: endliche Vertices/Normalen, keine degenerierten Dreiecke, stimmige clockwise-Normalen, geschlossene verschweisste Topologie pro Mesh, Bounds/Hoehen, Fensterabstand, Display-Hierarchie und konservative AABB-Verbindung der Komponenten. Die unveraenderte P4-Regression besteht 22/22 einschliesslich Closed/Cutaway-Verhalten und Fenster/Tor-Abstand. Ein anfangs gefundener 3-cm-Unterstand der Portalstuetzen wurde korrigiert; der erste Rohbericht bleibt als `qa/initial_geometry_raw.json` erhalten.

Die Topologiepruefung ist keine boolesch vereinigte Gebaeudehuelle. AABB-Konnektivitaet ist eine konservative Montagepruefung und kein exakter Kontakt-/Schnitt-/Z-Fight-Oracle. Absichtliche Ueberlappungen von Sockel, Kassetten und tragenden Modulen sind die Konstruktion. Die tatsaechlich geoeffneten nativen Front-/Heck-/Spielabstandsaufnahmen zeigen keine fehlenden, umgedrehten oder sichtbar schwebenden Teile. Allgemeine Performance-, Gameplay- und Releaseabnahme werden nicht behauptet.

`qa/` enthaelt zehn echte isolierte Godot-4.6.2-Forward+/Vulkan-Aufnahmen als Vorher/Nachher-Paare. Kamera-Transform, Orthogroesse, Aufloesung 1280x900 und FrontierArtProfile-Licht/Environment sind pro Paar gleich. Das sind eigenstaendige Modell-Lookproben; die gemeinsame Produktionsszene und ihre finalen Pass05-Captures betreut Root. Der Vorher-Builder liegt bytegetreu in `source/frontier_closed_buildings_before.gd`, der neue editierbare Stand in `source/frontier_closed_buildings_pass05.gd`. `manifest.json` haelt Quellen, Hashes, Roh-QA, Bilder und Grenzen fest.

Restabstand zu den Vorlagen: kompaktere, sauberere und regelmaessigere Baugruppen; wenig Gebrauchsspuren und zurueckhaltende Rueckfassaden. Funktionsgruppen im Hof sowie Boden-/Felskontakte werden im uebergeordneten Umgebungspass bearbeitet. Die geschlossenen Daecher sind aus Schnitt-/Industrievorlagen abgeleitet, keine identisch vorgegebene Aussenansicht.

Reproduktion ohne Import aus dem Repository-Root:

```powershell
$buildingsGodot = 'C:/Users/bjoer/AppData/Local/Programs/Godot/Godot_v4.6.2-stable_win64_console.exe'
$buildingsProbe = 'art/frontier_illustrated_20261101/environment/pass05/buildings/look_probe.gd'
& $buildingsGodot --headless --path . --script $buildingsProbe
& $buildingsGodot --headless --path . --script scripts/tests/frontier_pass04_verifier.gd
& $buildingsGodot --path . --rendering-method forward_plus --rendering-driver vulkan --resolution 1280x900 --script $buildingsProbe -- --render
python art/frontier_illustrated_20261101/environment/pass05/buildings/finalize_manifest.py
```

Erzeugte Bilder vor der Manifestfinalisierung tatsaechlich oeffnen. Native Captures mit den anderen Agenten koordinieren. Arbeit auf dem bestehenden unintegrierten Branch `task/grafikreferenzen-20261101`; kein Commit/Push durch diesen Teilauftrag.
