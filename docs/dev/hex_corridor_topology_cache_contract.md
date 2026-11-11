# Budgetierter abgeleiteter Hex-Korridorcache

`HexCorridorTopologyCache` ist ein instanziierter RefCounted-Helper unter
scripts/terrain. Er besitzt ausschliesslich abgeleitete Terrainnachbarn und
vollstaendige Topologiekomponenten, keine NPCs, Zeit, Belegung, Reservierungen
oder Durchlassgruppen. Aktive Owner-/Resolverintegration ist separate Arbeit.

## Query und Kontext

`query(registry:Node, grid_points:Array, node_budget:int=64)->Dictionary`
liefert `{ok,complete,registry_id,terrain_revision,corridors,
pending_grid_points,processed_nodes}`; Fehler enthalten zusaetzlich `reason`.
Gridpunkte sind strikt Vector2i. `node_budget` wird auf0..64 begrenzt.
Registry muss hex_axial_v1 und nichtnegative ganzzahlige Revision melden.
Registryidentitaet und Revision begrenzen alle Eintraege und laufenden Jobs.
Kontextwechsel verwirft alte Daten. Ein schwacher Registryverweis haelt die
Registry nicht am Leben. Revision wird auch nach Queryarbeit erneut geprueft;
eine Aenderung verwirft die gesamte Arbeit und liefert keine Komponenten.

Neue Urspruenge werden dedupliziert. Ein serieller aktiver Komponentenjob
bleibt mit Queue/Visited ueber Aufrufe erhalten; weitere Urspruenge warten.
Ein ueberlappender Ursprung eroeffnet keinen zweiten Job. Es gibt hoechstens
64 neue Knotenklassifikationen pro Call, auch bei einem groesseren Budget.
Keine Vollkarten-/SceneTree-/get_all_tiles-Suche und kein Neustart des bisherigen
64Feldfragments bei jedem Aufruf. Bereits klassifizierte Nachbarn sind wiederverwendbar.

`complete` bedeutet: keine offenen Urspruenge oder Komponentenjobs im Kontext.
`pending_grid_points` enthaelt alle noch offenen deduplizierten Urspruenge.
`corridors` enthaelt vollstaendige Komponenten fuer die aktuellen Querypunkte
plus in diesem Aufruf fertiggestellte aeltere Jobs. Es gibt keine automatische
Vollcacheliste pro Call. Leere Querypunkte koennen angefangene Jobs fortsetzen.
Ein Warmhit liest keine neuen Nachbarn. Alle Ausgabecontainer sind Kopien.

## Komponenten

Basis sind sechs kanonische legale Hexuebergaenge des Terrainowners.
Nur Zellen mit maximal zwei legalen Anschluessen gehoeren zu schmalen Komponenten;
Zellen mit mehr als zwei Anschluessen sind Branchgrenzen und werden nicht mit
eingeschlossen oder darueber hinaus expandiert. Eine Query an einer Branchzelle
allein startet keine Suche in saemtliche angrenzenden Gaenge. Isolierte legale
Zellen sind vollstaendige Singletons. Unfertige Komponenten werden niemals
als Korridor publiziert, auch nicht wenn sie bereits64Zellen enthalten.

Record: `{cells:Array[Vector2i],endpoints:Array[Vector2i],is_cycle:bool,
directed:bool}`. Ein normaler Pfad startet am lexikographisch kleineren Ende;
Enden werden nach x, dann y sortiert. Ein Singleton hat ein Ende. Ein Zyklus
startet an seiner kleinsten Zelle und folgt dem kleineren der beiden Nachbarn;
er hat keine erfundenen Enden, `is_cycle=true`, `directed=false`.
Normale mehrzellige Pfade haben `directed=true`: dieses Ownerfeld meint eine
ableitbare geordnete Passageachse fuer spaetere Kohorten, KEINE Einbahnbegehbarkeit.
Singletons besitzen keine +/-Achse und bleiben `directed=false`. Alle legalen
Edges sind auch bei directed=true in beide Richtungen begehbar.

## Integrationsgrenze

Mit owning Chat bestaetigt: `get_legal_hex_neighbors(grid:Vector2i)->Array[Vector2i]`
liefert eine unabhaengige Kopie, nur im Hexkontext. Beide Felder muessen begehbar
sein und sowohl allows_step(from,to) als auch allows_step(to,from) erlauben.
Runtime-Übersteuerungen lesen dabei `allows_registry_step` mit beiden
Registrybegehbarkeitsgates und demselben Endpunkthöhenkern; die Authoringdefaults
bleiben unverändert.
`get_revision()->int` und Node.get_instance_id() liefern den Kontext. Zusetzlich
wird die Ursprungs-Walkability geprueft, damit eine fehlende/blockierte Zelle
nicht als isolierter begehbarer Korridor gilt.

Wenn die neue Nachbar-API noch fehlt, nutzt der Cache exakt sechs Hexrichtungen,
Registry-Walkability und TerrainTileData.allows_registry_step in BEIDEN Richtungen.
Kein alternativer Hoehenvertrag. Ein Knotenbudget meint vollstaendige lokale
Klassifikationen; jede Klassifikation prueft hoechstens sechs Anschluesse.
Typen, Hexnachbarschaft und doppelte Nachbarn werden validiert; bereits gelesene
Rueckanschluesse muessen reziprok sein. Eine inkonsistente Helperliste verwirft
alles als invalid_neighbors, statt eine gerichtete Passage zu erfinden.
Die vorhandenen Rampen-/Terrainregeln bleiben alleinige Legalitaetsquelle.
Der separat übernommene Helper verändert keine Gameplaywahrheit. Der Anschluss
liegt jetzt bei `TerrainRegistry.get_hex_corridor_topology(grid_points,budget)`.
Er ergänzt `query_complete`: nur die aktuellen Punkte müssen fertig sein,
während `complete` weiterhin alle offenen Jobs im Kontext bezeichnet. Planer
liest ausschließlich diesen Ownerreadadapter, keine ungeprüften OwnerOptions.
Ground liest dieselbe vollständige Komponente mit0 Baubudget unabhängig erneut;
eine abgeschnittene oder umsortierte Grantzellenliste wird zurückgewiesen.

Kleine private CPU-Fixture unter
output/native_glut_maps/hex_corridor_cache_20261111. Keine grosse Native-,
Gefechts-, Save-, Netzwerk- oder Performancefreigabe durch dieses Paket.
