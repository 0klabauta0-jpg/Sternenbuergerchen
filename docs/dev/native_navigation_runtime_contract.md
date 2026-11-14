# Native Navigation Runtime Contract

## Owner und Standardpfad
`SimulationRoot` besitzt die Navigationsentscheidung und verwendet standardmaessig
`NativeNavigation` fuer die inkrementelle RegionalHexSearch des produktiven
HexGround-Pfads sowie HPA, direkte A*-Anfragen und Erreichbarkeitspruefungen bei
Ersatzzielen. Registry, HPA-Graph und Simulation behalten ihre bisherigen Rollen;
die GDExtension besitzt ausschliesslich abgeleitete Daten.
`native_navigation_enabled = false` ist ein Entwickler-/Vergleichsschalter, keine
zusatzliche Spieleroption. Fehlende Extension, nicht unterstuetzte Eingaben und
angeforderte mutable Diagnose-Dictionaries verwenden den bestehenden GDScriptpfad.
HPA-Status, Unreachable-/Ersatzzielregeln, Querybudget und Command-Autoritaet bleiben.

`HexMovementCommandRuntime` erzeugt Suchjobs ueber den Root. Jeder native Job
haelt eigene Frontier, Kostenoptionen und sparse Kosten-Caches; alle Jobs eines
Roots teilen denselben vorbereiteten Terrain-Snapshot ohne Kopie. Native und
GDScript behalten stabile Gleichstandsreihenfolge, Nearest-Reachable-Ergebnis
und dieselbe Anzahl Expansionen pro Slice. Die bestehenden 24 Expansionen pro
Hex-Job und 96 pro Tick sowie Ground-Reservierung/Ankunft bleiben unveraendert.
`blocked_grids` prueft Schluesselmitgliedschaft auch bei false-Werten. Kantenkosten
verwenden die kanonische Standhoehe, einschliesslich expliziter Rampen auf H+0,5.

## Laden und Revisionen
Der Missionladeabschluss ruft `SimulationRoot.prewarm_navigation(registry)` nach
Terrainregistrierung, initialen Szenario-/Tuer-Overrides und weiterer synchroner
Setup-Arbeit auf, bevor `_is_initialized` gesetzt und der erste Gameplaytick
freigegeben wird. Die Methode baut den nativen Terrain-Snapshot. Ein HPA-Graph
wird nur fuer den Legacy-HPA-Pfad vorbereitet; produktives HexGround und grosse
Regionalpfade verwenden ihn nicht. Sie erzeugt keinen Bewegungsbefehl und
verbraucht kein Querybudget.

Die erste normale Anfrage und Optionswechsel verwenden diese Daten weiter.
Registryidentitaet/-revision und Graphidentitaet/-revision steuern Invalidierung;
reine Kostenoptionen verursachen keinen neuen Terrainaufbau. Vorbereitung oder
Graphzugriff ohne gueltige Terrainregistry loescht vorbereitete Owner-/Adapterdaten.
Allein das Entfernen der NodePath-Bindung loest noch keinen Cacheabbau aus.
Zur Laufzeit geaendertes Terrain
wird beim naechsten betroffenen Suchaufruf weiterhin synchron aktualisiert.
Ein zukuenftiger anderer Loader mit SimulationRoot-Suche muss nach seinen finalen
Terrainmutationen dieselbe Vorbereitung aufrufen.

Auf aktuellem Main verwendet auch die reale Basisbewegung HexGround.
`BasePersonnelRuntime.configure` bereitet nach Konfiguration/Personenaufnahme
und vor Aktivierung der Physik vor. `BaseInteriorNavigation`/Godot-AStar2D bleibt
fuer Clearance und Zielaufloesung sowie den unversionierten Legacyweg bestehen.
Eine Ansicht mit Personnel leiht dessen Owner. Editor-/Taktik-Analysehilfen
bleiben ihre bisherigen GDScriptnutzer.

Checkpoint-Commit/Finalize kann Terrainoverrides wiederherstellen. Der Root
bereitet danach erneut vor, ausschliesslich nach vollstaendig erfolgreicher
Veroeffentlichung ausserhalb der callbackfreien Transaktion. Abgelehnte,
wiederholte oder durch Kontextwechsel ueberholte Finalisierungen bauen nichts
auf. Die bestehende Restore-Autoritaet wird dadurch nicht erweitert.

## Beobachtbarkeit und Grenzen
Die native Terrainvorbereitung baut gerichtete Nachbarkanten ueber den
zustandslosen `NativeTerrainBuilder` aus gepackten Feldern. GDScript liest
weiterhin effektive Walkability, Hoehen, Oberflaechen und Overrides der Registry.
Nur die exakte kanonische `TerrainRegistry` mit unterstuetzten Hoehen-/Rampenwerten
verwendet diesen Builder. Abgeleitete/andere Reader, ausgeschalteter Builder,
fehlende Methode oder abgelehnte Eingaben verwenden die urspruengliche
GDScript-Kantenschleife. `native_terrain_builder_enabled` ist ein interner
Vergleichsschalter. Die bestehenden DLL-freien Navigationsfallbacks bleiben.

Diese Optimierung fuehrt keine inkrementellen Terrainupdates ein: Eine neue
Revision baut weiterhin einen vollstaendigen Snapshot. Queryoptionen allein
loesen weiterhin keinen Terrainaufbau aus. Native Suchjobs, Gleichstandsfolge,
Budgets, Rampenregeln und Gameplay-Autoritaet bleiben unveraendert.
Die Debugfelder `terrain_builder`, `terrain_extract_usec`, `terrain_edges_usec`
und `terrain_load_usec` trennen Wiederverwendung, Extraktion, Kanten und Laden.
Nachweis: `docs/qa/native_terrain_visibility_20261114/README.md`.

`get_navigation_backend_debug_snapshot()` zeigt Backend/Fallbackgrund, Snapshot-
Zaehler und den letzten Prewarmbericht mit Dauer und Registryrevision.
`get_navigation_debug_snapshot().navigation_backend` und Queryhistory zeigen die
gleiche Auswahl. Die Anzeige ist keine zweite Gameplay-Wahrheit.

Die Vorbereitung laeuft synchron waehrend des Ladens. Sie verschiebt Arbeit vom
ersten Befehl in die Ladephase, beseitigt aber nicht alle Ladekosten. Plattform-
und Eingabegrenzen stehen in `native/navigation/README.md`; Windows x64 ist die
getestete native Plattform. Kein automatischer Anspruch auf identische Diagnose-
Arbeitszaehler, allgemeine FPS oder alle Multiplayer-/Save-Continue-Pfade.

## Pruefung
`native_navigation_runtime_verifier.gd`: normale Move-Queue, Abschluss, Budget-/
Fallback-/Revision-/Optionswechsel. `native_navigation_load_verifier.gd`: echter
GM01-JSON-/Missionladeablauf mit isolierter Darstellung und spaetem Override.
DLL-freie Prozesse pruefen beide Pfade erneut. `native_navigation_runtime_benchmark.gd`
misst echte Befehls-Ticks einschliesslich Pfadbewertung und Bewegung; Vorbereitung
wird separat sowie in kumulativen Gesamtkosten ausgewiesen.
Main-Paritaet prueft zusaetzlich Rampen, Blocker, interleavte Suchjobs und jeden
Slice, echte HexGround-Commands bis Ankunft und Checkpoint-Vorbereitung.
Historische HPA-Evidenz: `docs/qa/native_navigation_runtime_20261114/README.md`.
Aktuelle Mainintegration: `docs/qa/native_navigation_main_20261114/README.md`.
