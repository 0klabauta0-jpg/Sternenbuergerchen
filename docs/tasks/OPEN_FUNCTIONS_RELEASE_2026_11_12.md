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
