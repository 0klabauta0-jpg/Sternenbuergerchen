# TASK_144 - Editor-to-Mission 2.5D Smoke Test

## Ziel
Eine im Editor gespeicherte Karte mit Hoehen, Deckung, Objektlayern und Rampen/Treppen wird in der Mission geladen, 2.5D dargestellt und minimal spielbar validiert.

## Status: IMPLEMENTIERT

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
- [x] Smoke-Test-Map wird aus gespeicherter Datei geladen.
- [x] Mission registriert Hoehen-, Cover-, LOS- und Transition-Daten korrekt.
- [x] 2.5D-Visuals zeigen Boden und Objektlayer aus derselben Datei.
- [x] Bodenbewegung respektiert Rampen/Treppen-Regeln.
- [x] LOS/Cover-Snapshot nutzt die gespeicherten Hoehenwerte.
- [x] Verifier laeuft ohne manuelle Editorbedienung.

## Umsetzung
- `maps/task_144_2_5d_smoke.json` ist eine kleine 5x3-Smoke-Map mit flachem Boden, erhoehtem Boden, Rampe, Treppen-Transition, einem LOS-/Cover-Generator als Objektlayer und einer Plattform auf erhoehtem Boden.
- `scripts/tests/task_144_verifier.gd` laedt die Datei ueber den normalen `TerrainMapData`-Pfad, prueft Save/Load-Roundtrip, startet die Live-Mission mit dieser Map und validiert `MissionSetup`, `TerrainRegistry`, `MissionLive25DVisualBridge`, Navigation, LOS und Coverprofil.
- Der Verifier bewegt eine Mission-Unit ueber den gespeicherten Rampenpfad zum erhoehten Objective und prueft zugleich, dass ein Hoehensprung ohne Rampe/Treppe geblockt bleibt.

## Risiken
- Wenn der Editor beim Speichern Legacy-/Objektlayerwerte anders serialisiert als die Mission sie erwartet, zeigt dieser Task die Luecke bewusst frueh.
- Smoke-Test-Karte soll klein bleiben; sie ist kein Ersatz fuer echtes Leveldesign.
