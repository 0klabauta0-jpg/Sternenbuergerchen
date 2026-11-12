# Ground: vorbereiteter Restore für den Rootverbund

## Ziel und Ursache

Der atomare Rootverbund muss Ground und Movement vor jedem Livewrite vorbereiten
und validieren können. Der bestehende direkte Restore bleibt kompatibel.

## Umfang und Vertrag

Nur `scripts/core/hex_ground_runtime.gd`, eigener Verifier und eigene QA.
`prepare_restore_state(state)` liefert ein opakes RefCounted-Handle; der private
Kandidat entsteht durch den bestehenden V1/V2-Savevalidator. Der Getter
`get_prepared_restore_ground(handle)` leiht diesen detached Ground ausschließlich
zum Lesen für Movementprepare. Mutation macht die Vorbereitung ungültig.
`validate_prepared_restore(handle)` prüft Liveowner, Registry, Map, Epoch,
Revision, Tick, Terrain und alle beteiligten Groundwerte. Der öffentliche
`publish_prepared_restore(handle)` validiert erneut; Root darf nach ALLEN
Ownervalidierungen den privaten assignments-only Tail
`_publish_prepared_restore(handle, validation)` aufrufen. Kein Callback/await
zwischen Validierung und Tail. Das ist eine vertrauenswürdige Inprocessgrenze,
keine Sicherheitsbarriere gegen beliebigen Code im selben Prozess.

Das Zielground bleibt detached: Livepublish verwendet einen separat vorbereiteten
Wertpatch. Die Liveinstanz/Registry wird nicht ersetzt. Handles sind einmalig,
an ihre tatsächliche Objektidentität gebunden und nach Clear/Reconfigure ungültig.
Maximal32 gleichzeitig gehaltene Vorbereitungen; tote Handles werden beim
nächsten Prepare entfernt. Kein globaler RNG und keine SceneTree-Suche.

## Nichtziele

Kein Root-/Movement-/Baseanschluss, keine Änderung bestehender Save-/Restore-
oder Bewegungsbodies, kein Checkpointformatwechsel, keine Kartenaktivierung,
kein vollständiger AP7-/AP8-/Netzwerk- oder nativer Nachweis.

## Quellen und Akzeptanz

AGENTS, PROJECT_BRIEF, ARCHITECTURE, CODEX_RULES, IMPLEMENTATION_STATUS;
`docs/dev/hex_tactical_runtime_contract.md`, AP7 im Hex-Sicht-/Belegungsplan.
V1/V2-Zielvalidierung wiederverwenden. Prepare/Getter/Validate schreiben keinen
Livezustand. Fremde, veränderte, verbrauchte oder stale Handles werden ohne
Teilwrite abgelehnt. Tick/Terrain/Revision/Reconfigure und Kandidatenmutation
sind abgedeckt; gültiger Publish erhält Owneridentität und hat keine Aliase.

## Lokale Prüfung und Risiken

Kleine private Groundfixture und Einzelcompile; keine großen Suites/GPU.
Rootintegration muss alle Owner vor erstem Write validieren und anschließend
ohne Reentry die privaten Tails ausführen. Getter ist keine Mutationsfreigabe.
Coldpath-Fingerprints sind bewusst vollständig; nicht im Simulationstick nutzen.

## Stand / Freeze

Implementiert auf gemeinsamem Taskbranch nach Ground-V2 `8d333eb95`.
Eigene private Probe14/0, Import und Einzelcompile Exit0; Quellhash-, echtes
Originalprofil- und privater Canaryguard jeweils true. Nachweise unter
`output/native_glut_maps/hex_ground_prepared_restore_20261112/`.
Kein Root-/Movementproduktanschluss; Parent koordiniert den atomaren Verbund.
Bestehende `export_state`/`restore_state` und Bewegungsbodies unverändert.
Kein Stage/Commit, keine große Suite/GPU/EXE.
