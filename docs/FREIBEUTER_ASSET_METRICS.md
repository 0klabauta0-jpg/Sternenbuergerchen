# Freibeuter — lokale Modellmetriken

13.09.2026, Blender 5.1.1. Reproduzierbares Werkzeug: `tools/prepare_freibeuter.py`.

Quelle: `C:/Users/bjoer/3D Objects/drive-download-20250521T120706Z-1-001/DRAKE/DRAKE-BUCCANEER.obj`. SHA-256: `63380da3abc131ef59ac6ce730cf884eabc76ce2a73efacd9c5428b171950191`. Original nach Konvertierung unverändert geprüft. Vom Nutzer bereitgestelltes Modell; die lokale Konvertierung begründet keine neue Veröffentlichungslizenz.

| Zustand | Vertices | Flächen / Dreiecke | Materialien |
|---|---:|---:|---:|
| Ausgangsmodell | 77.966 | 132.384 Dreiecke | 0 |
| Vereinfachtes Blender-Mesh | 6.402 | 13.945 / 13.945 | 4 |
| Exportierter und erneut importierter GLB | 41.813 | 13.945 / 13.945 | 4 |

Der GLB benötigt wegen der flachen Normalen und Materialgrenzen mehr getrennte Vertices. Seine Dreieckszahl bleibt unverändert. Silhouette mit breiten Triebwerken und schmalem Cockpit erhalten; kleine Quellendetails vereinheitlicht, vier einfache Materialfarben. Exportmaße X/Y/Z in Godot: 8,697 × 1,998 × 7,974; Y nach oben, Vorwärtsrichtung −Z, Unterkante Y=0. Die Welt skaliert Schiffe gleichmäßig und setzt eine feste Flughöhe als Darstellung.

Lokale, per `git check-ignore` bestätigte ignorierte Ausgaben:

- `C:/dev/SternenBuergerchen-Neustart/assets/local/freibeuter/freibeuter.glb`
- `C:/dev/SternenBuergerchen-Neustart/assets/local/freibeuter/source/freibeuter.blend`
- `C:/dev/SternenBuergerchen-Neustart/assets/local/freibeuter/preview.png`
- `C:/dev/SternenBuergerchen-Neustart/assets/local/freibeuter/metrics.json`

Die finale Blend-Datei am endgültigen Pfad wurde mit Blender erneut geöffnet: 6.402 Vertices, 13.945 Dreiecke, vier Materialien bestätigt. Die GLB-Datei wurde in Godot 4.6.2 importiert und im echten Raumkontakt dargestellt. Der Ordner `source/` hat `.gdignore`, damit Studio-Boden, Kamera und Blend-Datei keine zusätzlichen Spielimporte auslösen.

Echte Fensterbelege: `output/rooms-orbit/space-contact.png` zeigt Freibeuter, Entersäbel und die aus bestätigten Schusszuständen dargestellte Spur; `space-gunner.png` zeigt die kleine visuelle Turmstation mit zweitem Astronauten. Keine eigenständige Kampf- oder Crewlogik im Modell.

Die Karte-/Fensterprobe `scripts/world/world_orbit_probe.gd` erreichte 43 Prüfungen ohne Fehler über reale Commands und isolierte Karriere. `output/rooms-orbit/world-results.json` enthält zusätzlich je drei Sekunden Renderstichprobe bei festen bestätigten Snapshots (1440×900, `auto_tick=false`, 0,35 Sekunden Vorlauf; keine exklusive Hardwarebelegung):

| Ansicht | Frameabstand p95 | Szenenknoten | Godot-Objekte | Draw Calls |
|---|---:|---:|---:|---:|
| Basis | 13,480 ms | 828 | 3.113 | 598 |
| Rostkarte, weite Radaransicht | 13,491 ms | 334 | 2.430 | 359 |
| Raumkontakt | 13,427 ms | 216 | 2.106 | 230 |
| Station | 13,422 ms | 818 | 2.935 | 498 |

Das sind kurze lokale Darstellungsstichproben mit etwa 75 Bildern/s, kein Nachweis maximaler Leistung, aktiver Kampfsimulationslast oder anderer Hardware. Es hängt immer nur die aktuelle Region im Szenenbaum; kleine Felsen und Sterne werden über MultiMesh gebündelt.
