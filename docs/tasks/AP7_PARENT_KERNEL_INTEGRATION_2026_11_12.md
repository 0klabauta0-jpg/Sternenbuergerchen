# AP7: vorhandene Parentkerne an Root und Speicher-/Netzwege anschliessen

## Ziel / Ursache
Source besitzt Root-/Checkpoint-/Startloader- und Netzwerkverdrahtung. Die
vorbereiteten Komponenten sind im Parent bereits vorhanden und gezielt geprueft;
diese Datei benennt deren Abhaengigkeiten, damit keine zweite Implementierung
oder versehentlicher Wholefileimport entsteht.

Readonly-Abgleich am 12.11.: Source hat Groundexport und GroundPrepared bereits.
Movementexport/-Prepared, BaseV2, Sessiongetter und Visibleprojection fehlen dort
noch. Vor Import gegen tatsaechlichen aktuellen Sourcecode erneut abgleichen.

## Komponenten / selektive Reihenfolge

| Parentcommit | Produktumfang |
| --- | --- |
| 524fd61d1 + 8d333eb95 | Groundexport/-Restore, aktuelle v2 mit ganzen Passagekohorten und gemeinsamem Topologiebudget; Source bereits teilweise/vollstaendig vorhanden |
| b431a350b | GroundPrepared: prepare, validieren, Zielground lesen, stiller Tail; nicht nochmals ersetzen, wenn bereits vorhanden |
| f24656107 | Portable akzeptierte Movementintents und Preparedrestore gegen konkreten Zielground; Originalziele und Warte-/Backoffsemantik |
| 2eab1f01b | Nur wirklich aktuelle transiente Rootstempel aus portablem Movementexport auslassen |
| 18c619f86 | Separater Baseaktions-CheckpointV2 und kopierender Movement-Zielstategetter; Legacyexport/configure unveraendert |
| 0bef0e658 | Raw-Snapshotversion vor Normalisierung und begrenzter Client-Hoststate-Guard |
| 0134f53ae | Reine empfaengerbezogene V2-Projektion; braucht originale Hostreferenzen vor verlustbehaftetem V1-Normalisieren |
| 4e366661b | Reliable Sessionstart mit verifizierter Manifestidentitaet/Runtime-Token, Session-/Lobbygetter; noch kein Rootbinder |

Nur erforderliche Produktdeltas und zugehoerige Task/QA uebernehmen. Keine
Parent-Source-Datei komplett ueber die inzwischen weiterentwickelte Gegenseite
kopieren. Aktuelle Base-/Movement-APIs stehen im BASE_ACTION_CHECKPOINT_V2-Task.

## Umfang / Akzeptanz

Root bindet tatsaechliche Actors, Registry, Map und Startkontext. Alle beteiligten
Preparedhandles validieren, bevor Ground-/Movement-/Base-Modelltails beginnen.
Erst nach vollstaendigen Modellen Root-/Actorprojektion und oeffentliche Ereignisse.
Ungueltige neue oder unbekannte Bloecke vor Aktivierung ablehnen; Legacy ohne
Block erhalten. Bestehende Checkpointpflichtkeys, Home-only-/Away-/Pendinggates
nicht lockern. Tatsachenkarte der Basis ist die feine384x392-Navigation16x8,
nicht die grobe Renderkarte. Keine automatische Aktivierung aus einem Save.

Sessionkontext in Root vor Missionsaktivierung binden. Laufende Snapshot-
Assignments mit anderem Token sind kein neuer Start. Runtimekontext gilt fuer
Chunks, Vitals, direkte Unit-/Effekt-RPCs und eingehende Spielercommands; alte
Matchpakete duerfen nicht durch neue Actorstempel gueltig werden. Neuer gebundener
Kontext darf nicht kontextlos in einen Legacy-Wirepfad fallen.

Host publiziert nur eigenen Vollstate und erlaubte sichtbare Gegnerprojektionen.
Aktuelle Sicht beim vorhandenen autoritativen Owner lesen; keine zweite
Sicht-/Belegungswahrheit oder observe_pair aus einem Getter. Reservierungen und
private Lebenszyklus-/Actorobjektkennungen bleiben beim Host. Receiver leitet aus
Partial-/Rejectpayloads keine Abwesenheit ab. Gueltiger Fullscope muss auch
anfangs angelegte fremde Defaultvisuals korrekt verbergen, ohne Gameplayclaims
zu entfernen.

## Lokale Pruefung / Risiken / Nichtziele

Kleine Payload-/Save-/Rootfixture und hoechstens zwoelf Felder; bestehende
Componentbelege sind keine Root-/Startloader-/Peerfreigabe. Anschliessend AP8
mit wirklichem Checkpoint-/Publikations-/Receiveranschluss vervollstaendigen.
Keine grosse Peer-/Gefechts-/GPUmatrix, Produktionsaktivierung A/B/C, allgemeine
Mehrort-Saves, Mainintegration oder EXE. Vor jedem spaeteren EXE-Build Nutzer fragen.
