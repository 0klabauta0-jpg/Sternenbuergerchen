# Buccaneer – Refinement 02

Die Pods wurden als vollständige zusammenhängende Baugruppen verkleinert: radial 0,78, längs 0,90; ihre Achsen liegen näher am Rumpf und etwas tiefer. Hauben, Einlässe, Wartungsringe, Düsen, Verbindungsstege und Sättel folgen derselben Änderung. Die inneren Flügelwurzeln reichen weiter nach innen, während äußere Spannweite und Flügelspitzen erhalten bleiben.

Die Kanzel besitzt zwei große Seitenfenster je Seite und eine geneigte Frontscheibe. Schmale Rahmensegmente ersetzen die kleinteilige vorherige Aufteilung; der geschlossene Dachbereich ist kürzer. Die Oberseite des verdeckten Bugrumpfs wurde abgesenkt, damit sie nicht in die Seitenverglasung ragt. Die acht Teile der Dorsalkanone sind anhand ausgewerteter Geometriehashes unverändert.

| Ausgewertetes Maß | Refinement 01 | Refinement 02 |
|---|---:|---:|
| Rechte Druckhülle, Durchmesser X | 2,9281 m | 2,2839 m (−22 %) |
| Rechte Druckhülle, Höhe Z | 2,8110 m | 2,1926 m (−22 %) |
| Rechte Druckhülle, Länge Y | 5,8789 m | 5,2910 m (−10 %) |
| Kanzelbreite | 2,0429 m | 2,3152 m (+13,3 %) |
| Kanzellänge | 4,1198 m | 4,3467 m (+5,5 %) |
| Gesamtbreite / Länge / Höhe | 11,7578 / 11 / 4,1198 m | unverändert |

Diese Maße sind stilisiert und aus den Perspektivvorlagen 13/11 abgeleitet. Sie sind keine kanonische Rekonstruktion. Die Kanzel ist insgesamt weniger hoch und hat einen breiteren hinteren Schulterquerschnitt; entscheidend ist die neue Fenster- und Keilform. Messdaten und Herkunftshashes: [evaluated_proportions.json](evaluated_proportions.json).

Finale Quelle: [buccaneer_master.blend](buccaneer_master.blend), abgeleitet aus `iterations/i03/`. 88 benannte editierbare Teile in `LOW`, getrennte Baugruppen, gepackte Texturen und Bildreferenzen. 19.632 Dreiecke. Export in `Assets/curated/frontier_illustrated_20261101/ships_pass05_astra_ultra/refinement_02/buccaneer_01.glb` relativ zur Repository-Wurzel: ein Mesh, acht Materialien, neun eingebettete Texturbilder. Blender −Y vorwärts, Z oben; GLB/Godot +Z vorwärts, Y oben; gesamtes XY-Bounds-Zentrum als Ursprung, Boden Z=0.

[audit.json](audit.json): PASS, 0 Fehler, 0 Warnungen. Positionen stimmen exakt, maximale Normalenabweichung direkt 0,00008211 und nach frischem Reimport 0,00144974 bei unveränderter Grenze 0,002. UVs, Materialien und vollständige Texturpixel bestehen ebenfalls. `i01`/`i02` enthalten dokumentierte Zwischenfehler an der inneren Flügelwurzel; `i03` setzt die innere Stirnfläche tiefer in den Holm und beseitigt die fast deckungsgleichen Flächen. Es wurden keine Prüfausnahmen eingeführt.

Vergleichsbilder und Sichtprüfung stehen unter [review/buccaneer](../review/buccaneer/VISUAL_REVIEW.md). Schlichte Glaswirkung, regelmäßige Motorpanzerung und große ununterbrochene Flächen unterscheiden sich weiterhin von den gemalten Referenzen. Keine native Godot-Abnahme, Nutzerfreigabe, Animation oder fertiger Innenraum.

Reproduktion aus der Worktree-Wurzel mit Blender 5.2.3 LTS:

```powershell
$shipArt = 'art/frontier_illustrated_20261101/ships/pass05_astra_ultra/refinement_02/buccaneer'
$shipQa = 'art/frontier_illustrated_20261101/ships/pass05_astra_ultra/qa_tools'
$shipGlb = 'Assets/curated/frontier_illustrated_20261101/ships_pass05_astra_ultra/refinement_02/buccaneer_01.glb'
$blender = 'C:/Users/bjoer/AppData/Local/Programs/Blender Foundation/Blender 5.2/blender.exe'
& $blender -b --factory-startup --python-exit-code 1 -t 6 -P "$shipArt/build_buccaneer.py" -- --iteration i03 --views '' --qa
& $blender -b --factory-startup --python-exit-code 1 -t 6 -P "$shipArt/finalize_buccaneer.py"
& $blender -b --factory-startup --python-exit-code 1 -t 6 -P "$shipQa/verify_ship.py" -- --blend "$shipArt/buccaneer_master.blend" --glb $shipGlb --out "$shipArt/audit.json" --length 11
& $blender -b --factory-startup --python-exit-code 1 -t 6 -P "$shipArt/measure_proportions.py"
```

Die aktiven Skripte liegen hier; Iterationsskripte sind archivierte Momentaufnahmen. Reproduktion verändert Zeitstempel/Hashes der neu erzeugten Blend-Datei und erfordert neue Bild-/Audit-Bindungen. Die tatsächlichen Renderbefehle sind in `../review/buccaneer/package_binding.json` dokumentiert.

SHA-256 der Lieferung: Blend `06cd6c3b105b0b7450639618e2c06ddf3355a094064bbdceb5640d0a14b7450c`; GLB `27634374c9abb51e77b39fb21b4c8d810e2302c3cb000924c81d25d39d7850f6`.
