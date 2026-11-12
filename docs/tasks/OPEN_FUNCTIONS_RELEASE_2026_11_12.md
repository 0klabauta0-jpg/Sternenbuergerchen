# Offene Funktionen und Testpaket – 12.11.2026

## Ziel und Ursache
Nach Main95abade90 offene Einsatzfunktionen abschließen und die vom Nutzer jetzt
beauftragte Windows-Test-EXE bereitstellen. Die Editor-Importwarnung wird zuerst
reproduziert; ihre Ursache ist noch offen.

## Umfang und Grenzen
Root untersucht Import/Shutdown und verantwortet genau ein neues Paketverzeichnis.
Companion implementiert vollständiges Einsatz-Save/Continue und integriert allein
auf Main. Weltraumchat ergänzt reguläre Luftunterstützung und Radar. Gemeinsame
Owner-Methoden werden abgestimmt; keine alten Gesamtdateien über neue schreiben.
Keine Fahrzeugmodellrunde, keine breiten Gefechts-/Performance-/Netzwerktests.
Bestehende Arbeitsverzeichnisse, Nutzerspielstände und Pakete bleiben erhalten.

## Verträge und Dateien
PROJECT_BRIEF, ARCHITECTURE, CODEX_RULES, IMPLEMENTATION_STATUS;
CHAT_CAMPAIGN_MAIN_INTEGRATION_2026_11_12.md;
data/export_runtime_package_contract.json;
scripts/tools/export_runtime_release.ps1 und release_runtime_start_check.ps1.
Weitere Fehlerdateien erst nach tatsächlichem Reproduktionsbefund benennen.

## Akzeptanz und lokale Prüfung
- Importwarnung anhand vollständiger ausführlicher Godot4.6.2-Logs einordnen und
  bei bestätigtem Produktfehler gezielt korrigieren.
- Einsatz-Save/Continue und Luft/Radar mit gezielten Nachweisen zusammenführen.
- Export aus sauberem gemeinsamem Commit, eigenes Verzeichnis, PCK-Hash und
  Build-Provenienz; Paketvollständigkeit und tatsächlichen Paketstart prüfen.
- Keine allgemeine Spiel-/Performanceabnahme aus diesen Prüfungen ableiten.

## Risiken/offen
Editor-Plugins können von Runtimewarnungen getrennte Ursachen haben. Missions-
Snapshots müssen alle zuständigen Owner transaktional wiederherstellen; ein
Szenenpfad oder Teilzustand erfüllt den Auftrag nicht. Große Tests bleiben später.

## Importbefund und Korrektur
Godot4.6.2 meldet beim Editor-Ende genau einen SceneTreeTimer mit Referenz1.
Ohne ausschließlich das Terrain3D-Editorplugin tritt er nicht auf. Der verzögerte
Szenenwechsel-Vorschaurefresh wartete auf einen SceneTreeTimer, der bei sofortigem
Importende noch ausstand. Der Plugin-Owner besitzt nun einen abbrechbaren Timer;
Shutdown stoppt ihn, schnelle Szenenwechsel bündeln den Vorschaurefresh.
Betroffene Produktdatei: addons/terrain_3d/src/editor_plugin.gd.

Direkter Vergleich mit demselben gefüllten Importcache: alter Code exit0 mit
ObjectDB-/SceneTreeTimer-Leak; neuer Code exit0 ohne ObjectDB-/Ressourcenleck,
Script-/Parse-/Compilefehler oder ERROR-Zeilen. Logs liegen in
docs/qa/open_functions_release_20261112/import-cached-{before,after}.log.
Verblieben sind bestehende AssetPlacer-UID-Fallbackwarnungen und die ausführliche
Engine-Diagnose eines verwaisten StringName Node; kein verschwiegener Nullwarnungslauf.
Paketabhängigkeitsprüfung: 7 Assertions, Marker vorhanden, exit0, keine Fehler oder
Leaks; Report package-contract-report.json im selben QA-Verzeichnis.
Der Erstimport überschritt bei96% das300s-Limit; Resume beendete die ausstehenden
Assetimporte. Dieser abgebrochene Erstlauf zählt nicht als erfolgreicher Gate.
Noch kein EXE-Export oder allgemeiner nativer Editor-/Spielnachweis.

## Abgestimmter zusätzlicher Save-Baustein
Companion hat Root explizit den Registry-/Navigations-Checkpoint übertragen:
space_ship_registry.gd und additive Navigation-APIs in space_combat_state.gd,
mit kleinen eigenen Verifiern. Der bereits getrennte Systems-Checkpoint bleibt
beim Companion; Codec-Abhängigkeit wird als dessen Commit übernommen.
Registrykandidaten binden tatsächliche restaurierte Flugowner; Pose, Footprint,
Belegung, Revisionen und Claims müssen übereinstimmen. Vorbereitung mutiert keine
Live-Welt. Runtimebezüge in Aufträgen werden ausdrücklich neu gebunden und bei
fehlendem/falschem Kontext abgewiesen. Erst die globale Missionstransaktion beim
Companion veröffentlicht den Kandidaten; dieser Teil allein schaltet kein Save frei.

Registry35/0 und Navigation17/0 unter Godot4.6.2, isoliertes Profil, je60s-Limit,
keine Script-/Parse-/Compile-/ERROR-/Leakzeilen. Logs/Report im QA-Verzeichnis.
Unabhängiges lesendes Review: keine kritischen/wichtigen Befunde. Der danach
ergänzte Air-Rebind-Fall bindet echte separat erzeugte SimulationRoot-Instanzen;
er ist ein Owner-Test und kein physischer Flug-/Gesamtmissionsnachweis.

APIs für den Join:
- Registry export_checkpoint_index() und static prepare_checkpoint_candidate(state, flights).
- Combat export_navigation_checkpoint() und static
  prepare_navigation_checkpoint_candidate(state, flights, control_bindings = {}).
- candidate.validate_navigation_checkpoint_candidate(state, control_bindings = {})
  unmittelbar vor der globalen Publikation wiederholt Frische/Bindungen prüfen.
- control_bindings pro craft enthält equipment_owner und für Luftaufträge
  mission_root. Diese Owner müssen von der Gesamttransaktion zuvor fachlich
  restauriert/validiert sein. Ausrüstungs-Snapshot, Masse, Hull/Power und Footprint
  werden abgeglichen; alte Prozess-IDs/WeakRefs werden nicht deserialisiert.
- Systems-Checkpoint bleibt separat: legitime Hardware aus restaurierter
  Ausrüstung an Candidate binden, Systems vorbereiten/prüfen, erst im gemeinsamen
  signal-/await-freien Veröffentlichungsteil übernehmen. Keine Live-Publikation
  in Registry-/Navigation-Vorbereitung, kein neuer Root-/UI-State in diesem Patch.

## Delegierter Transport-Checkpoint: Join-Vertrag
Additive Methoden am echten Mission-Tactical-Controller delegieren an
scripts/mission/transport_checkpoint.gd. Kein Flug-/Radar-/Root-/Actor-Verhalten
wird hier umgeschrieben. Schema mission_transport_checkpoint.v1 verwendet den
gemeinsamen typisierten Codec. Crew kommt aus singleplayer_visit_identities und
dem tatsaechlich zugewiesenen Kartenpiloten; Actor-Referenzen in Primär- und
Parallelsequenzen werden als Unit-IDs gespeichert und an echte Ziel-Actors gebunden.

APIs: export_transport_checkpoint(); prepare_transport_checkpoint_candidate(state,
bindings) -> {ok,candidate}; validate_transport_checkpoint_candidate(candidate,
bindings) -> {ok}; _publish_transport_checkpoint(candidate) -> void.
bindings enthaelt actors={unit_id:restaurierter Actor}, simulation_root=zugehoeriger
Ziel-Root, visits=kanonische restaurierte Besuchsidentitaeten und
craft_identities={craft_id:{model_id:kanonisches Modell aus Schiff-/Inventarowner}}.
Fuer die gemeinsame Transaktion zusaetzlich presence_bindings={unit_id:bool embarked}
mit exakt allen lokalen Crew-/Pilot-IDs und pilot_bindings={craft_id:pilot_id} aus
dem bereits validierten Flow-Pilotowner liefern. Ohne presence_bindings verlangt
Prepare bereits passende Actor-Metadaten; Capture prueft diese immer tatsaechlich.
Prepare/Validate schreiben nichts. Publish setzt dropship_embarked-Metadaten erst
im gemeinsamen signal-/await-freien Veroeffentlichungsteil. Position, Sichtbarkeit,
Runtime-Registrierung, Inventar und Actor-Spielzustand bleiben beim Companion.

Die deaktivierte neue Missionsinstanz muss bereits die echten restaurierten Actors
im richtigen Root-Lookup binden. Parent-Metadaten campaign_ground_pilot_id,
singleplayer_mission_identity, location_id und MissionSetup-Szenario sowie
selected_team_unit_ids/selected_team_fireteam_ids/selected_team_unit_configs,
selected_fireteam_definitions und member_loadouts sind Teil des Companion-Joins.
Vor dem Umschalten alle Ownerkandidaten erneut validieren; dann Transport intern
publizieren. Complete-Sequenz, Position=LZ, Karten, Landungsprojektion und Bootstrap-
Flags werden direkt wiederhergestellt: kein Drop-/Arrival-/Bootstrap-Aufruf.
Danach bestehende UI-/World-Projektion gezielt finalisieren. Physische Root-/Hex-
Präsenz und Claim-Restauration bleiben eigene globale Gates, kein UI-Ersatz.

Bewusst abgewiesen: laufender An-/Abflug, Landen/Unloading, Hex-Admission,
Aufsitzen/Rueckweg und ausstehende Boarding-/Deployment-Effekte. Keine stille
Verwerfung laufender Aktionen. Getrennte Primär-/Parallelschemata bewahren echte
Polisa-parked_sequence-Felder sowie progress/service_reentry. Kandidaten pruefen
Zielowner-Frische, Actor-Identitaet/Lifecycle, Crew-/Pilot-/Schiffsbindungen.

Gezielter realer Controller/SimulationRoot/TestUnit-Ownerverifier einschliesslich
echtem Polisa-parked_sequence-Builder: scripts/tests/transport_checkpoint_verifier.gd.
Godot4.6.2, isoliertes APPDATA tmp/open-functions-release/transport-profile,
60s-Hardlimit, vollstaendige Logs transport-checkpoint{,.stderr}.log unter
docs/qa/open_functions_release_20261112. Dieser Nachweis ist kein nativer
Gesamtmissions-, Flug-, Save-Continue- oder EXE-Nachweis; Companion prueft den Join.

Transport-Geometrienachtrag: Der echte polisa_ground_body_profile-Vertrag besitzt
native AABB-Bounds. Ausschliesslich im bekannten ground_body_profile.bounds-Slot
werden diese lokal als sechs endliche Zahlen unter transport_aabb_v1 codiert und
nach Decode wieder als native AABB aufgebaut. Bestehendes read_bound prueft danach
positive Ausdehnung, Craft/Modell und tatsaechliche Assetidentitaet. Keine globale
Codec-Erweiterung. Frischer Verifier46/0, exit0; echtes TerrainMap3DView-
get_station_craft_body_projection mit realem Schiffsmesh und from_projection-
Builder, exakter Geometrie-Roundtrip sowie fuenf korrupte Bounds-/Asset-Faelle.

Transport-Nachtrag echter Satellitenweg: Derselbe reguläre Orbit-/Anflug-/Drop-
Ablauf reproduzierte invalid_checkpoint_value nach vollständigem Deployment.
Die rekursive reine Typdiagnose meldete exakt
fields._field_landing_by_craft.dropship_1.&ok als StringName-Schlüssel.
Der bestehende Nicht-Hex-Pfad erzeugt ihn durch landing.ok=true. Nur dieser bekannte
Schlüssel wird jetzt explizit als String auf Wire plus
transport_ok_key_kind_v1=StringName gespeichert und beim Decode mit ursprünglichem
Schlüsseltyp wiederhergestellt. Unbekannte StringName-Schlüssel bleiben gesperrt.
Keine generische Stringifizierung und keine globale Codecänderung. Der fokussierte
Ownerverifier prüft55/0 einschließlich ursprünglichem Assignment, Typerhalt,
korruptem Marker/Wert und weiter gesperrten fremden StringName-Schlüsseln.

Echter Nachweis nach Fix: regulärer Basis-/Boarding-/Orbit-/Quantum-/Anflug-/Drop-
Weg mit unveränderten echten Actors im Companion-Checkout; korrigierter Helper
wurde per absolutem load aus dem Root-Worktree am selben tatsächlichen Controller
geprüft, ohne Companion-Produktdateien zu ändern. Altes Controllerexport scheitert
reproduziert, korrigiertes Capture liefert mission_transport_checkpoint.v1.
JSON Prepare/Validate und interne Veröffentlichung erhalten Grounded-Phase und
beide ursprünglichen Actoridentitäten:38/0, exit0, TRANSPORT_TRUE_LANDING_PASS.
Profil transport-value-verified, APPDATA unter tmp/open-functions-release,90s-Limit.
Logs transport-true-landing-verified{,.stderr}.log und exakter Probequelltext
transport-true-landing-probe.gd.txt im bestehenden QA-Ordner. Zwei bekannte Szenen-
UID-Pfadfallbackwarnungen; keine Script-/Parse-/Compile-/ERROR-/Leakzeilen.

Genauigkeitsgrenze ausdrücklich erhalten: Ein zusätzlicher bitexakter Vergleich
fand allein lz_accuracy_radius im letzten Floatbit abweichend nach JSON-Parsing,
auch mit full_precision=true. Der echte abschließende Vergleich bindet Zahlen
mit absolut <=1e-12, alle anderen Typen/Werte/IDs exakt. Vorher-/Default-Precision-
und Full-Precision-Diagnoselogs bleiben separat erhalten. Dies ändert keine Actor-
Positionen/HP/Bewegung/Zeiten oder Aktionen für einen künstlichen Pass. Kein
vollständiges Missions-Save/Continue und kein EXE-Nachweis aus dieser Transportprobe.
