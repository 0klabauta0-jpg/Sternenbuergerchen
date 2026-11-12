# AP6: stabile Personen bei RuntimeSelection

## Ziel / Ursache

Der tatsächliche Missionssetup aktualisiert Slots nach ihrer Position. Entfernte
Personen behalten Root-/Ground-/Commandbindungen; IDwechsel können alte Lookup-
Aliase hinterlassen. Umordnen derselben Auswahl darf Personen, Zustand und Auftrag
nicht austauschen. Neu aktivierte Personen müssen dieselbe Rootadmission wie der
initiale Setup verwenden.

## Umfang / Nicht-Ziele

Separater Hexzweig für apply_runtime_selection_contract. Vollständige Vorprüfung
der gewünschten IDs, Kapazität und exakten Root-/Registry-/Actorbindung vor
Mutationen. Bestehende IDs nach Person wiederverwenden, auch staged. preserve_existing
steuert vorhandenen Gearrefresh, niemals einen stillen Präsenz-/Auftragsreset;
refresh_existing_ids ist ein expliziter Gear-/Fireteamrefresh. Entfernte oder
umbenannte Slots verlieren alte Ground-/Move-/Known-/Registrybindungen. Neue
direkte Akteure bleiben verborgen bis zur atomaren Zulassung; Deferredakteure
bleiben ohne Ground/RuntimeRegistry. Deklarierte Clients bleiben Präsentation.
Keine neue Personal-/Visitregistry, Legacyänderung oder neue Medizin-/Heillogik.
Kein Main, Produktionsflag, EXE oder großer Test.

## Contracts / Besitz

Projektarchitektur, Hexruntime-/Lifecycle-/Rampenvertrag, initialer MissionSetup,
Wellenretirement und gebundene Auftragsempfänger. Root besitzt Gameplay und
Lookups; Setup orchestriert Auswahl und existierende Adapter. Parent hat die
neue additive TestUnit-Identityresetkante sowie Setup/Root ausdrücklich für
dieses Paket freigehalten. Alte Weapon-/Medical-/Remote-/Flowbodies erhalten.

## Umsetzung

TestUnit erhält eine vorbereitete stille Änderung von ID/Team/Runtime-Command-
State mit eigenem Validate/Publish/Finalize. Vitalmodell, HP und medizinische
Historie bleiben erhalten. Root validiert die ganze Änderung vor Release alter
Präsenzen und veröffentlicht alle Lookup-/Actormodelle vor ersten Signalen.
Keine Heilung durch deactivate_for_wave, kein ungültiger Nullcommand-Setter.
Setup schützt Fortsetzungen gegen Reentry, Root-/Kontext-/Lifecyclewechsel und
verwendet den vorhandenen begrenzten Pendingadmissionpfad statt Renderteleports.

## Akzeptanzkriterien

- [a,b]→[b,a] mit preserve_existing erhält exakt dieselben Actors, Health, Ziele
  und Präsenz; staged Personen zählen ebenfalls als bestehend.
- Entfernen nur von b lässt a unverändert und entfernt b auch bei noch laufendem
  Auftrag vollständig aus den bisherigen Root-/Registrybindings.
- Fremde Registry-/Knownziele, doppelte IDs und Überkapazität weisen vollständig
  ab; fremde Akteure und andere Visits bleiben erhalten.
- Neu verwendeter Slot trägt weder alten Command noch Kontakt/Bewegungsintent.
  Keine HP-/Vitaltransition durch Identitätsreset.
- Direkte Aktivierung bei Platzmangel wartet verborgen, ohne Doppelplan pro Frame.
  Deferred und Client publizieren keine lokalen Ground-NPCs.
- Reentry und Callbackscopewechsel führen zu keiner alten Fortsetzung.

## Dateien / lokale Prüfung

MissionTestSetup, ausschließlich neue TestUnit-/Root-Identityhelper sowie reine
atomare Lookup-Batchkante der UnitRegistry und exakter Remove-/Entityleser am
vorhandenen RuntimeLeader (keine zweite Mitgliedschaft), kleiner
Verifier/Runner, QA und Contracts/Status. Tatsächlicher TestUnit und Setup mit
Root/Ground/Registry, bekannte Roster-/Gear-/Markerinputs; höchstens zwölf Felder
je Fixture. RED/GREEN, Quellen-/Profilguards, unmittelbarer Setupnachbar; aktueller
Parent-Visitextensioncaller bei verfügbarer enger Probe separat prüfen.

## Risiken / offen

Synchronous Setter-/Readabilitysignale erst nach vollständig gültigen Modellen;
Actor-, Slot- und Personidentität nicht verwechseln. Keine neue Speicher-/Medical-
Mitgliedschaftswahrheit; AP7 muss pending bzw. nichtportable Runtimearbeit passend
behandeln. AP6 erst nach diesem Paket beurteilen; AP7/8 folgen, große Tests später.

## Codeabschluss / verlegte Prüfung

Als zusammenhängendes AP6-Paket implementiert. Unveränderte Personen werden
auch bei preserve_existing=false nicht aus Ground/Command/Lifecycle genommen;
dieses Flag steuert Gearrefresh. Vollständiger Szenarioreset bleibt beim
Rootconfigure/initialen Setup. Der gemeinsame reine FOB-Configbuilder erhält
den Legacyanwendungspfad; medizinische und Weaponbodies bleiben unverändert.

Vorhandene tatsächliche Evidenz6/7→13/0. Enge Readonlyreviews und gezielte
Callbackrepros ergaben danach13/3: Identitysetter emittierten in der Modellphase,
gepufferte Auswahl trat in neuen Root ein, Registrywechsel ließ alte Folgewrites
zu. Codefixes: Setter nur während vorbereiteter Modellphase stumm, Identitätssignal
im guarded Finalize nach vollständigen Bindings; Requestaufnahme und Commitreceipt
binden konkrete Owner/Registry/Leader und Actorleben. Reentry anderer Auswahl wird
höchstens einmal unmittelbar geleert, Rest im bestehenden Prozesspfad.

Nach neuer direkter Nutzersteuerung keine weitere Randfall-/Review-/Testschleife:
die drei Korrekturen nur syntaktisch geprüft, Gameplaynachprüfung gemeinsam nach
AP7-/AP8-Codeblöcken. Client, vollständiger Platzmangel, zusätzliche Caller- und
medizinische Nachbarabnahme sind noch Teil dieser gebündelten Prüfung. Keine
vollständige AP6-Verifikationsfreigabe oder gemessene Performanceverbesserung.
