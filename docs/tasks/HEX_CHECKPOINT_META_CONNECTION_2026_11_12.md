# AP7: Kampagnenspeicher und Continue an Rootcheckpoint anschließen

## Ziel / Ursache

Die kanonischen Ground-/Movement-/BaseV2-Daten müssen durch den tatsächlichen
Kampagnenspeicher und Fortsetzenpfad laufen. Der bisherige BaseV1-Export verliert
laufende Basisaktionen und darf V2 niemals als freien Positionsstand laden.

## Umfang / Nicht-Ziele

Nur CampaignCheckpointStore, CampaignStartConfiguration und Checkpoint-/Configure-
Bereiche des SingleplayerRuntimeAdapter. Optionaler hex_tactical-Block exakt
hex_tactical_checkpoint.v1 mit innerem BaseV2/Transport. Ohne Block bleibt Legacy.
Home-/all_grounded-/Away-/Pendinggates bleiben. Keine Kartenaktivierung aus Saves,
kein Map-/Root-/Base-/Actor-/Flow-/Orbitumbau, keine Mehrortsaves oder neuen Owner.
Bewusste gemeinsame Taskbasis native-glut-maps-20261110; Source liefert getrennt
hex_checkpoint_transaction und Root-API. Keine Wholefileübernahme.

## Verträge / Abhängigkeiten

HEX_CHECKPOINT_ROOT_JOIN_2026_11_12 (Source), BaseV2-/Ground-/Movementprepared,
AGENTS/ARCHITECTURE/CODEX_RULES; tatsächliche BaseInteriorNavigation384x392 mit
16x8-Zellen, nicht die gröbere Renderkarte. Root allein koordiniert Restore.

## Akzeptanz

- Unbekannter/fehlerhafter Block und doppelte BaseV1-Positionsdaten werden vor
  CampaignStart-Liveänderungen abgelehnt.
- Continue prüft denselben Block gegen tatsächliche isolierte Candidateowner
  einschließlich Map/Frame/Fingerprint/Actor-/Transportbindung vor configure.
- Der echte Livebootstrap stellt Transport/Roster her und ruft den vollständigen
  Rootrestore; inneres BaseV2 geht niemals in den Legacybaseloader.
- Hexexport verwendet Rootguard und Rootexport; alle bisherigen Homegates bleiben.
- Keine stillen Teilpässe, kein Save setzt taktische Kartenflags.

## Prüfung / Risiken

Nutzer bündelt Prüfungen nach Codeabschluss: hier keine Tests, Compiles oder
nativen Starts. Candidatebootstrap muss echte Base-/Rootowner benutzen, während
Roster-/Transporteingaben nur den validierten vorbereiteten Checkpoint projizieren.
Quellmodule und Meta-Anschluss gemeinsam integrieren; fehlende APIs fail closed.
Keine Commits/Staging, gemeinsamer Status bleibt beim Parent.

## Codeblock / späterer gemeinsamer Nachweis

Store prüft den unveränderten äußeren Kampagnenvertrag plus den optionalen
Rootblock und dessen zukünftige Roster-/Pilot-/Team-Zuordnung. Start führt den
echten isolierten Root/Base-Candidateprepare vor allen Flowänderungen aus.
Candidate-Roster und Transport sind reine kopierte Readprojektionen; Membership
liest der vorhandene HomebaseScreen-Reader ohne SceneTree-/UIaktivierung.
Base.configure erzeugt tatsächlich feine Navigation, Registry und BaseActors.
Physik wird unmittelbar deaktiviert und der ganze Candidate synchron freigegeben.

Der echte Adapter exportiert über Root und lässt den V1-Mirror weg. Continue
übergibt Base.configure ausdrücklich {}, stellt den existierenden Screenpayload
mit vorhandenen Methoden her und führt Rootprepare/validate/commit aus. Root- und
Viewersatz stoppen alte Fortsetzungen, nach Finalize erfolgt keine alte Aktivierung.
Bestehende Orbit-/Polisa-/Flow-/Controllerbodies bleiben unverändert.

Kein Test oder Compile gestartet. Der gemeinsame kleine Lauf muss reale
Store.save/load + CampaignStartconfigure + Adaptercontinue prüfen. Für den
positiven Hexfall wird eine bereits legitim opt-in gesetzte private Kopie der
echten384x392/16x8-BaseNavigation benötigt; die unveränderte Legacykarte mit
explizitem Hexblock ist ein verpflichtender Reject. Der vorbereitete AP8-Root-
Inplacefall ersetzt diesen zusätzlichen Store-/Loadernachweis nicht.

## Begrenzter Autosaveexport

Der bestehende Flow ruft Autosave pro Frame auf. Tick/RNG/Basetimer machen neue
Hexsignaturen fortlaufend unterschiedlich. Deshalb erfolgt Hexexport samt Hash
und Dateischreiben nach allen unveränderten Safetygates höchstens einmal je
1000ms, gebunden an tatsächlichen Runtime-/Root-/Kontext. Simulation bleibt
unverändert getaktet; der erste Save läuft sofort. Optionales force=true umgeht
nur das Zeitintervall, niemals Home-/Away-/Pending-/Rootguards. Legacy bleibt
unverändert. Die vorhandene eine Storeprobe prüft Folgesave und expliziten Save
ohne zusätzliche Performance-Testreihe.
