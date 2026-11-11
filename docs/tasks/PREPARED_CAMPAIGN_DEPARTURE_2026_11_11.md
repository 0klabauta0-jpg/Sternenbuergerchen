# Prepared Campaign Departure: unverdrahteter Ownerpatch

## Ziel / Ursache
Der kuenftige gemeinsame Abflugcommit muss Campaign-Binding, optionale Jobaktivierung und beide bestehenden Subreceipts vorab pruefen. Einzelne alte Commands emittieren ueber Root zwischen den Ownerwrites. Dieser Slice bereitet ausschliesslich einen still publizierbaren Campaignpatch vor.

## Scope / Nicht-Ziele
Nur scripts/core/singleplayer_campaign_state.gd plus eigene Dokumente und kleine QA. prepare_departure(binding_command,activation_command_or_empty,trusted_context), validate_prepared_departure(candidate,trusted_context), commit_prepared_departure sowie privater _publish_prepared_departure(candidate,validation). Kein Root-, Adapter-, Supply-, Travel-, Flight-, Karten- oder Produktcalleranschluss. Keine Aenderung bestehender Commandregeln, kein Saveformatumbau, kein globaler Status oder Commit.

## Vertrauensgrenze / Daten
configure_departure_preparation_authority(authority:Object) bindet einmalig eine WeakRef-Objectidentitaet. trusted_context bindet dieselbe authority, eine transaction_id und typed built_home_pad_ids. Kein UI-Bool als Freigabe; explizite vertraute Inprocessschnittstelle, keine Sicherheitsisolation gegen Code mit Zugriff auf dieselben Internas. Neue Integritaetssiegel verbrauchen kein globales RNG.

Private kleine Runtimekopie ohne configure/export_state/restore_state: genau die von bestehender bind/activate-Logik gelesenen zwei Locationdefinitionen, ein optionaler Job, ein Craftbinding und zwei Requestkeys. apply_command laeuft nur auf dieser privaten Kopie. Kandidat enthaelt kleine Binding-/Jobstatus-/Craft-/Receiptpatches und Revisionsdelta, keine Vollownerersetzung. Fingerprint prueft Revision, relevante Selection, Definitionen/Job/Binding, gebaute Pads und betroffene Receiptkeys. Noop-already_active kann ohne Revision einen Key schreiben und muss einen alten Kandidaten ungueltig machen.

Gruppentransaktions-ID bindet beide kompletten Commands und den gesamten normalisierten Kontext. Replay nur fuer einen eigenen vollstaendigen Gruppenbeleg. Vorhandene Legacy-Subreceipts ohne diesen Beleg werden ausdruecklich als ungeklaerter Teilstand abgewiesen. Leerer job_id erfordert leeres Activationcommand und erzeugt keinen Jobpatch. Aktivierter Job eines anderen Crafts ist kein eindeutiger vorbereitbarer Gruppenstand.

## Vertraege / Arbeitsbasis
HEAD 3fb8d2985 im gemeinsamen isolierten Integrationsworktree; PROJECT_BRIEF, ARCHITECTURE, CODEX_RULES, IMPLEMENTATION_STATUS, ORBIT_DEPARTURE_ATOMICITY_AUDIT_2026_11_11 und eigener prepared_campaign_departure_contract. Root integriert spaeter alle Owner nach gemeinsamer Revalidierung vor dem ersten Write/Event.

## Akzeptanz / lokale Pruefung
8-12 gezielte Ownerchecks: mutationsfreies Prepare, noJob, echter Job und Replay, Konflikte/Tampering, legitime Runtimepads03..06, stale Selection/Job/Binding/Pad/Receipt, already_active-Keywrite ohne Revision, Legacyteilbelegreject, lifecycle/authority und kein globales RNG. Ein Compile, keine grosse Matrix oder GPU. Tail schreibt nur vorher vorbereitete Keys ohne fallible Callbacks, Validierung, Dateizugriff oder Signal nach dem ersten Patchwrite.

## Risiken / offen
Die vertrauenswuerdigen Pad-/Personen-/Saum-/Mapbelege stammen spaeter aus Root. Dieser Campaignpatch allein macht keinen bezahlten Anflug atomar. Grosse Reise-/Save-/Netz-/Nativeabnahme bleibt offen. Kurzlebige private Gruppenbelege sind Runtimehilfen, kein neuer persistenter Campaignowner.

## Implementierter Kandidat / lokaler Beleg
Nur der vorhandene Campaignowner wurde additiv erweitert. Bestehende Commandbodies bleiben unveraendert; erfolgreiches configure/restore invalidiert lediglich die neue transiente Authority-/Epoch-/Gruppenbelegmetadaten. Die private Runtimekopie ruft weder configure noch Saveexport/-restore auf. Nur betroffene Binding-/Jobstatus-/Craft-/Receiptkeys werden nach gemeinsamer Revalidierung still veroeffentlicht. Vor dem ersten Livewrite werden Caller-Dictionarys abgetrennt.

owner_check.gd meldet 12/0, runtime_wired=false. Die Probe verwendet echte bestehende Commands; eine NoSaveOwner-Unterklasse verweigert Save-/Restorecloning. Der echte already_active-Noop schreibt den kuenftigen Activationkey bei unveraenderter Revision und invalidiert den vorbereiteten Commit. Runtimepads03..06 sind gueltig, ohne durch die engere Savevalidierung zu laufen. Einzelcompile Exit0 und Diffpruefung sauber. QA: output/native_glut_maps/prepared_campaign_departure_20261111. Kein privates Godotprofil gesetzt, kein Profilguard behauptet; reine Inmemoryownerprobe ohne Save-/Restoreaufruf. Keine Root-/Atomicmultiowner- oder produktive Reiseabnahme, kein Commit/Push.
