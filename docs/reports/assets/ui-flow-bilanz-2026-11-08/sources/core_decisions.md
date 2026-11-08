# DECISIONS

## Format
- Datum:
- Entscheidung:
- Warum:
- Auswirkung:

## Bisher fest
- Godot 4.6.2 wird verwendet
- Codex arbeitet lokal gegen `C:\dev\SternenBuergerchen`
- Spieler ist Commander
- direkte Steuerung nur bis FTL
- Echtzeit ohne Pause
- Heimatbasis und FOB bleiben menügetrieben
- Multiplayer-Prototyp V1 mit Testteams
- Friendly Fire ist an
- Damage ist datenbasiert
- Respawn ist unbegrenzt mit Zeitverzögerung

## Architektur-Entscheidungen
- SimulationRoot ist die einzige autoritative Stelle fuer State-Mutationen; keine Gameplay-Wahrheit in UI oder Szenen-Glue
- Server-autoritativer SimulationRoot im Multiplayer: nur der Server verarbeitet Commands/Effects, Clients erhalten Snapshots
- Isometrisches 2D-Grid als Koordinatensystem; Tile-Positionen werden ueber konfigurierbare Iso-Konvertierung abgebildet
- A*-Pathfinding auf dem Iso-Grid mit drei Kostenvariablen: walkable, Hoehenunterschied, Surface-Kosten
- Datenbasiertes Combat statt Physik-Ballistik: Trefferchance und Schaden ueber Formeln mit Skill-, Cover- und Terrain-Modifikatoren
- Unit-Skills (accuracy, speed, leadership, toughness) als statische Werte pro Unit; beeinflussen Combat und Bewegung direkt
- Persoenlichkeitsmerkmale (Traits) als Skill-Modifikatoren ohne eigene Gameplay-Subsysteme
- Phasensystem (APPROACH, ASSAULT, HOLD) beeinflusst Feuerverhalten, Geschwindigkeit und Deckungswerte
- Fireteams (BLUE, GOLD) als Untereinheiten fuer selektive Befehlsvergabe
- Terrain-Daten (walkable, blocks_los, cover_value, height_level, surface_type) als leichtgewichtige RefCounted-Objekte in TerrainRegistry
- Respawn-Timer-Staffelung: Rover 30s, FOB 150s, Homebase 270s
- Host/Join ueber ENetMultiplayerPeer auf Port 7777 fuer V1; kein Matchmaking
- Multiplayer V1 bleibt Godot High-Level Multiplayer/ENet Direct-IP mit optionalem UPnP; Node.js/WebSocket ist keine aktuelle Architekturvorgabe
- `sternenbuerger-gdd.docx` ist Alt-GDD/Design-Inspiration und Migrationsquelle; bindend werden Inhalte erst nach Ueberfuehrung in Markdown-Docs/Tasks/Decisions
- Terrain-Konfiguration als JSON-Datei unter `res://maps/`; kein Godot-Resource-Format, damit auch externe Tools die Daten lesen koennen
- Map Editor als Runtime-Szene im Spiel, kein Godot-EditorPlugin; interner Workflow-Editor, nicht spielerseitig in V1
