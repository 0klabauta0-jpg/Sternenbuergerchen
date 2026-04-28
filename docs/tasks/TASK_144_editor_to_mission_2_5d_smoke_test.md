# TASK_144 - Editor-to-Mission 2.5D Smoke Test

## Ziel
Eine im Editor gespeicherte Karte mit Hoehen, Deckung, Objektlayern und Rampen/Treppen wird in der Mission geladen, 2.5D dargestellt und minimal spielbar validiert.

## Status: GEPLANT

## Kontext
- TASK_140 macht 2.5D-Werte im Editor bearbeitbar.
- TASK_142/143 sollen dieselben Daten in der Live-Mission sichtbar machen.
- Dieser Task schliesst die Kette Editor -> gespeicherte Map -> Mission -> 2.5D Visuals -> Bewegung/LOS.

## Umfang
1. Kleine kuratierte Smoke-Test-Map unter `data/` oder `res://` mit:
   - flachen Bodenbereichen,
   - erhoehtem Boden,
   - mindestens einer Rampe oder Treppe,
   - mindestens einem Cover-/LOS-Objekt,
   - mindestens einem Objektlayer-Asset.
2. Mission-Setup laedt diese Map ueber den bestehenden Map-Ladepfad.
3. TerrainRegistry, 2D/2.5D-Renderer und Navigation sehen dieselben Tile-Daten.
4. Minimaler Bewegungs-/LOS-Check ueber Rampe/Deckung.
5. Headless-Verifier prueft Map-Roundtrip und Missionsverdrahtung.

## Nicht-Ziele
- Kein grosser Kartenbau.
- Keine finale Balance der Cover-/Hoehenwerte.
- Keine komplette Editor-UX fuer Multi-Floor.
- Keine neuen Fireteam-Taktiken.

## Akzeptanzkriterien
- [ ] Smoke-Test-Map wird aus gespeicherter Datei geladen.
- [ ] Mission registriert Hoehen-, Cover-, LOS- und Transition-Daten korrekt.
- [ ] 2.5D-Visuals zeigen Boden und Objektlayer aus derselben Datei.
- [ ] Bodenbewegung respektiert Rampen/Treppen-Regeln.
- [ ] LOS/Cover-Snapshot nutzt die gespeicherten Hoehenwerte.
- [ ] Verifier laeuft ohne manuelle Editorbedienung.

## Risiken
- Wenn der Editor beim Speichern Legacy-/Objektlayerwerte anders serialisiert als die Mission sie erwartet, zeigt dieser Task die Luecke bewusst frueh.
- Smoke-Test-Karte soll klein bleiben; sie ist kein Ersatz fuer echtes Leveldesign.
