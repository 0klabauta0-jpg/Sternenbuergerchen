# Nächster spielbarer Windows-Kandidat

## Ziel / Ursache

Der Nutzer fragt nach dem aktuellen Gesamtstand und der nächsten EXE, beauftragt
weitere Tabletop-/Orbitintegration und verschiebt große Tests ausdrücklich.
Ein klar begrenzter spielbarer Kandidat soll vor weiteren Contentausbauten stehen.

Neueste ausdrückliche Nutzerentscheidung: zuerst weitere APs fertigstellen und
vor dem EXE-Build nachfragen. Auch bestandene Kandidatengates autorisieren keinen
automatischen Export. Vorbereitung und Integration dürfen weiterlaufen.

## Umfang / Nicht-Ziele

Vorhandenes Gelände/Editor, R07-Rüstungen, Polisa, lokale Schiffsabholung,
Punktestarts und bisherige Forschung erhalten. Neue Bewegung und den neuen
Orbitweg nur nach ihren erforderlichen Owneranschlüssen sichtbar aktivieren.
Keine breite Gefechts-/FPS-/Netzmatrix, keine neuen Fahrzeugmodelle, kein
fertiger Forschungsbaum als zusätzliche Buildvoraussetzung. Kein Terminschätzen
aus bloßer Zahl bestandener Checks.

## Bereits integrierter Stand

- A/B/C 512 × 256, Plateaus, breite/Eckrampen und gemeinsamer Editor.
- R07 Körper-/Rüstungsproportionen, gezeichnete Referenzen; Nutzerurteil bleibt
  getrennt von technischen Nachweisen.
- Polisa R08, Shops, Padmaßstab, lokale Schiffsabholung und explizite Crewübergabe.
- Parallele Ortsansichten, Warp-Slot D bis A, Punkte-/Erfahrungsbedienung,
  Forschungs-/Recyclingfortsetzung und lokale Planungsworkbench.
- Tabletop-Sicht, Facing/Sicherung, Zusagen, Stop/Zentrierung, echte Moveabsichten,
  Gruppen-/Viewkonsumenten und Bewegungsschuss mit vorläufiger Balance.

Diese Liste bedeutet implementiert im isolierten Taskstand, nicht vollständige
native Spielweg-/Performance-/Saveabnahme. Neue Produktionskarten sind noch nicht
für den vollständigen Tabletopmodus aktiviert.

## Erforderliche Schritte vor diesem Kandidaten

1. AP5-Code einschließlich Backoff ist integriert. AP6 enthält Gruppenplätze,
   Transportphasen und gebundene Schiffsflächen samt tatsächlichem Renderjoin.
   Noch Setup und Basisaktionen zusammenführen; AP6 nicht pauschal abschließen.
2. AP7: Ground-Roundtrip und Command-/Versionsgrenzen sind teilweise integriert;
   Passagezusagen, ursprüngliche Bewegungsabsichten, tatsächliche Base-/Checkpoint-
   Bindung und empfängerbezogene Sichtprojektion vervollständigen. Home-only-
   Speichergrenzen erhalten. Danach den kleinen AP8-Ablauf vervollständigen.
3. Orbit: gemeinsame Flight-/Travel-/Economyübergänge, getrennte Stationsdockung
   und Kauf-Erstaufnahme sind als Ownerpfade integriert. Noch produktive lokale
   Reise-/Visit-/Kaufroute paarig verbinden und Katalog V3 samt Einmarkerwechsel
   vorbereitet abstimmen. Lokaler Automatismus bleibt bis dahin ausgeschaltet,
   Livekatalog V2. Private Ownerzyklen ersetzen keinen echten Stationsbesuch.
4. Enge gemeinsame Start-/Aufnahme-/Bewegungs-/Reise-/Rückkehrprüfung, ohne volle
   Kampagne/Gefechtsmatrix. Aktivierung und offene Grenzen dokumentieren;
   große Produktionskartenaktivierung und AP9 bleiben gesondert zurückgestellt.
5. Nach konkretem Kandidatenstatus Nutzer vor dem Build fragen. Erst nach dessen
   Zustimmung Export aus sauberem gesichertem Quellstand in neuen eigenen Paketordner;
   vorhandene Pakete nicht überschreiben. EXE, PCK und benötigte DLLs zusammen,
   Provenienz mit Commit/Hashes, kleine echte Paketstartprüfung.

## Exportbestand / Dateien / Prüfung

Vorhanden: `scripts/tools/export_runtime_release.ps1`,
`scripts/tools/release_runtime_start_check.ps1`,
`data/export_runtime_package_contract.json` und Godot-4.6.2-Exporttemplates.
Der isolierte Worktree besitzt bisher kein lokales `export_presets.cfg`;
das ignorierte lokale Preset liegt im gemeinsamen Projekt. Beim späteren
Export nur erforderliche Einstellungen übernehmen und einen neuen Zielpfad
setzen. Kein globales Preset oder bisheriges Runtimepaket überschreiben.

Relevante Verträge: `hex_tactical_runtime_contract.md`,
`orbital_approach_contract.md`, `polisa_local_ship_pickup_contract.md`,
`parallel_location_operations_contract.md`. Hauptstatus: ACTIVE_WORKPLAN.

## Risiken / offene Punkte

Orbit derzeit nur Geometrie/Owner-Vorstufen; noch kein produktiver lokaler
Reiseweg. Vorhandene Home-only-Savegrenze bleibt, Away-Speichern ist eigener
späterer Ausbau. Schiffwaffen/Retirement umgerüsteter Skirmishschiffe, komplette
interne Wertevereinfachung und weitere Forschung/Modelle bleiben benannt offen.
Mainintegration ist ein eigener Integrationsschritt; ein isolierter Kandidat darf
nicht als Mainrelease bezeichnet werden. Noch keine EXE erzeugt, kein fester
Termin zugesagt. Die großen Prüfungen folgen nach dem Kandidaten.
