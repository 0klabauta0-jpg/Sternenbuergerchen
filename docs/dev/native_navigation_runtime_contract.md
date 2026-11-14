# Native Navigation Runtime Contract

## Owner und Standardpfad
`SimulationRoot` besitzt die Navigationsentscheidung und verwendet standardmaessig
`NativeNavigation` fuer HPA, direkte A*-Anfragen und Erreichbarkeitspruefungen bei
Ersatzzielen. Registry, HPA-Graph und Simulation behalten ihre bisherigen Rollen;
die GDExtension besitzt ausschliesslich abgeleitete Daten.
`native_navigation_enabled = false` ist ein Entwickler-/Vergleichsschalter, keine
zusatzliche Spieleroption. Fehlende Extension, nicht unterstuetzte Eingaben und
angeforderte mutable Diagnose-Dictionaries verwenden den bestehenden GDScriptpfad.
HPA-Status, Unreachable-/Ersatzzielregeln, Querybudget und Command-Autoritaet bleiben.

## Laden und Revisionen
Der Missionladeabschluss ruft `SimulationRoot.prewarm_navigation(registry)` nach
Terrainregistrierung, initialen Szenario-/Tuer-Overrides und weiterer synchroner
Setup-Arbeit auf, bevor `_is_initialized` gesetzt und der erste Gameplaytick
freigegeben wird. Die Methode baut den HPA-Graph und den nativen Terrain-/HPA-
Snapshot. Sie erzeugt keinen Bewegungsbefehl und verbraucht kein Querybudget.

Die erste normale Anfrage und Optionswechsel verwenden diese Daten weiter.
Registryidentitaet/-revision und Graphidentitaet/-revision steuern Invalidierung;
reine Kostenoptionen verursachen keinen neuen Terrainaufbau. Vorbereitung oder
Graphzugriff ohne gueltige Terrainregistry loescht vorbereitete Owner-/Adapterdaten.
Allein das Entfernen der NodePath-Bindung loest noch keinen Cacheabbau aus.
Zur Laufzeit geaendertes Terrain
wird beim naechsten betroffenen Suchaufruf weiterhin synchron aktualisiert.
Ein zukuenftiger anderer Loader mit SimulationRoot-Suche muss nach seinen finalen
Terrainmutationen dieselbe Vorbereitung aufrufen.

Die Heimatbasis verwendet bereits `BaseInteriorNavigation` mit Godots nativem
`AStar2D`, beim Laden vorbereitetem Feinraster und fertigen Weltpfaden in Commands.
Dieser eigene Vertrag bleibt bestehen; es wird kein ungenutzter zweiter Graph
vorbereitet. Editor-/Taktik-Analysehilfen bleiben ihre bisherigen GDScriptnutzer.

## Beobachtbarkeit und Grenzen
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
Evidenz: `docs/qa/native_navigation_runtime_20261114/README.md`.
