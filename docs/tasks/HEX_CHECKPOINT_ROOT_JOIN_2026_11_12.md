# AP7: Rootcheckpoint und tatsächlicher Speicher-/Startpfad

## Ziel / Ursache

Ground, Movement und Base haben vorbereitete kanonische Speicherkerne. Ohne
Root-/Store-/Startloaderanschluss bleiben sie ungenutzt; Legacybaseexport verliert
laufende Aktionen. Ungültige neue Blöcke müssen vor CampaignStart- und Liveowner-
Mutationen abgewiesen werden, gültige Zustände müssen vollständig weiterlaufen.

## Umfang / Nicht-Ziele

Ein zusammenhängender Rootcheckpointblock für freigeschaltete Hexkontexte:
Terrainoverrides/Türen, Ground/Facing/Segmente/Passagen, akzeptierte ursprüngliche
Bewegungsziele samt Wait/Backoff, Tick und exakter RNGzustand, Baseaktionen V2.
Nur kanonische Daten, keine Queues, Pathfinder, Sichtcaches oder Instanzkennungen.
Bestehende Home-/all_grounded-/Away-/Pendinggates erhalten. Keine generischen
Mehrort- oder Gefechtssaves, keine Aktivierung einer Karte aus einem Save.

## Contracts / Abhängigkeiten

Hexruntime-/Rampenvertrag; Ground V2/Prepared bereits Source; Parent Movement
f24656107 +2eab1f01b als Source d2d24dd6c/aa22c661a; Base18c619f86 als185ef3f4d
nur additive254+6Produktzeilen plus eigene Task/QA, keine Legacy-/Remotebodies.
AP7_PARENT_KERNEL_INTEGRATION_2026_11_12 des Parentb60645d7f; vorhandener
CampaignCheckpointStore/CampaignStartConfiguration/SingleplayerRuntimeAdapter.

## Architektur / Arbeit

Root koordiniert vollständige Prepare-/Validate-Phasen vor erster Modellmutation;
Terrain-/Ground-/Movement-/Basezustände publizieren danach ohne Callbacks.
Ground-/Registryobjekte erhalten, abgeleitete Revisionswerte nach geprüfter
semantischer Karten-/Rasterbindung portabel auf Zielowner beziehen. Rootprojektion,
Actors und öffentliche Basissignale erst nach sämtlichen Modellen. Änderungen
von Türen/Overrides erhalten denselben Rampen-/Neighborowner, keine zweite
Geometrie. Pendingrespawn/-boarding/-retirement/-selection/-admission abweisen.

Store prüft unbekannte/ungültige Blockversionen und Pflichtkeys vor Normalisierung.
Continue führt vollständige Hexvorprüfung mit temporären tatsächlichen Candidate-
Ownern vor CampaignStart.configure-Livewrites aus. Danach echter Bootstrap mit
ursprünglichem Transport-/Rosterowner und dem vorbereiteten Rootrestore; Basis
verwendet die feine384x392-Navigation16x8, keine coarseRenderkarte.

## Netzaufteilung

Parent liefert getrennt95e22ad14: Root-Kontext/Sender/Receiver/Commands, Driver-
Sichtgetter, Session/Lobby/READY und reine Sendestellen. Source verändert diese
Methoden nicht, sondern übernimmt später Commitdeltas. Bind vor Aktivierung;
kein Legacyfallback in gebundenem Kontext. refresh_multiplayer_replica_presence
ist nach vollständiger Client-Actor-/Known-/Registrypublikation vorhanden.
clear_multiplayer_runtime_context nur bei wirklichem wiederverwendetem Missions-
reset, niemals initialem Mapconfigure nach Pre-add Binder.

## Akzeptanz

- Kein Teilrestore nach ungültigen Blöcken/Claims/Actor-/Map-/Frame-/Ownerbindungen.
- Terrain/Ground/Move/Base/Tick/RNG bilden beim ersten Ereignis denselben Zustand.
- Save/load erhält Originalziele, Wartesemantik, Passagen, Facing und Baseaktionen.
- RNGzustand als strikt geprüfte64-Bit-Dezimalzeichenfolge, keine verlorenen Bits.
- Legacy ohne neuen Block bleibt verwendbar; V2 niemals alten Baseloader geben.
- Home-/Away-/Pendinggates bleiben wirksam; Rootcache und alte queued Arbeit
  werden passend ungültig, persistente Modelle erhalten keine UIkopie.

## Dateien / Prüfung / Risiken

Root und enges Transaktionsmodul, Terrain-/Preparedowneranschluss, CheckpointStore,
Startkonfiguration und Adapter-Checkpoint-/Configureabschnitte. Parent hält seine
Orbit-/Travel- und Netzmethoden; keine Wholefileübernahme. Syntax-/Integrations-
blocker sofort beheben, Gameplayprüfungen nach neuer Nutzersteuerung erst nach
AP7-/AP8-Codeblöcken bündeln. Kein weiterer Mikroreview-/Randfallzyklus, keine
große Karte/Peermatrix/GPU-/Performancefreigabe, Main oder EXE.

## Aktueller Codeblock / Übergabe

Root-/Terrain-/Ground-/Movement-/Base-/Actor-Anschluss implementiert. Registry-
Overridecandidate verwendet dieselben statischen logischen Felder; die originale
Registry und Ground-/Movementobjekte bleiben beim Commit erhalten. Statische
Kartenbindung ist nach Rasterkoordinaten geordnet; Overridequellenmetadaten und
Türen werden mitgespeichert. Terrainrevisionen werden erst nach exakter Karten-
und Rasterbindung auf den Zielowner bezogen. Base validiert Movement gegen den
vorbereiteten Registryowner. Gespeicherte Transportdaten sind ein portabler
Read-Witness und müssen dem tatsächlich vorbereiteten Transportkontext gleichen.

Root veröffentlicht Modelle vollständig vor Projektion/Actors/Basesignal; alte
Kontexte und Personenlebenszeiten werden ungültig. Fertige/abgebrochene Befehle
werden nicht als aktive Actorbefehle reaktiviert. Root-Shapeprüfung ist statisch
verfügbar. CampaignCheckpointStore, CampaignStartConfiguration und Adapter sind
ab jetzt ausschließlich Parentarbeit; keine Sourceänderungen an diesen Dateien.
Parent baut CandidateBootstrap über vorhandenes Base.configure mit leerem Legacy-
Checkpoint und passendem reinem Roster-/Transportprojektionskontext.

Codeprüfung: `git diff --check` ohne Befund. Ausführung und Gameplayprüfungen
ausdrücklich bis Zusammenführung mit Loader/Netz/AP8 zurückgestellt. Kein
Testbestanden-, Performance-, Main-, EXE- oder Integrationsfreigabestatus.

Vor gemeinsamem Testfreeze: Transport-Witness erst nach erfolgreicher strikter
Baseprepare lesen, damit ein unvollständiger V2-Block strukturiert abgewiesen
wird. Die Reihenfolge aller Modellmutationen bleibt unverändert.
