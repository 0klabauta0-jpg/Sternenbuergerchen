# Mission Release Recapture Extraction Design

## Ziel
Die wiederholbare, read-only Release-Recapture-Logik fuer First Contact und First Engagement wird vom Testcontroller in einen Mission-Contract-Builder verschoben.

## Architektur
`MissionTacticalSandboxController` bleibt der Adapter fuer Runtime- und Dateievidence. Er sammelt bestehende Snapshots, Provenance, Capture-Manifest und Fensterartefakte ein. `MissionReleaseRecaptureService` bewertet nur diese Dictionaries und gibt exakt die bisherigen Contract-Strukturen zurueck.

## Schnittstelle
- `build_first_contact_recapture(execution_recapture, first_contact_readability, release_provenance, capture_manifest, host_window, client_window)`
- `build_first_engagement_recapture(first_contact_recapture, engagement_feedback, release_provenance, capture_manifest, host_window, client_window)`

## Grenzen
Der Service importiert keine Runtime-Nodes und erzeugt weder Commands noch Effects, Contacts, FireEvents, DamageEvents oder Multiplayer-Wahrheit. Oeffentliche Controller-Methoden und bestehende Snapshot-Schemas bleiben unveraendert.

## Pruefung
Ein datenreiner Test prueft beide Builder gegen kleine Handoff-Fixtures. TASK_1172 und TASK_1173 pruefen danach die echte Controller-Delegation gegen bestehende Release-Evidence.
