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

## Aktueller Kandidatenstand / erforderlicher nächster Schritt

AP6–AP8 sind fertig integriert und begrenzt geprüft: Selection16/0, Base30/0,
AP8-Root-/Netzverbund38/0 und tatsächlicher CampaignContinue17/0+3/0.
Quellen/Profil/Canary und vollständige Logs grün. Genaue Commit- und Fixturegrenzen:
`docs/qa/ap678_bundle_20261112/README.md`. Der begrenzte AP8-Kandidat braucht
keine echten Peers; reale Peer-/native-/Produktionskartenabnahme gehört AP9.

Polisa-Direktanflug und Crew-Rückflugfix sind integriert, Source-Rundlauf25/0
vorhanden. Katalog V2 und lokales Warpflag false bleiben erhalten. Neue
AP09-Weltraum-/Komponentenpakete aus dem anderen Chat sind getrennte Folgearbeit.

Jetzt Nutzer vor dem Build fragen. Zustimmung gilt für einen konkreten
Testkandidaten mit den benannten Grenzen, nicht für Mainintegration oder
Produktionskartenaktivierung. Danach neuer Paketordner, EXE/PCK/DLLs zusammen,
Commit-/Hashprovenienz und kleiner echter Paketstart. Noch kein Export erfolgt.

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
