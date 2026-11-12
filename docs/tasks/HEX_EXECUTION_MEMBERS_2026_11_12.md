# AP6: Mitglieder laufender Hexaufträge

## Ziel / Ursache

FMC und automatische Waypoint-/Area-Fortsetzungen nehmen dieselben IDs erneut
aus dem aktuellen Roster. Root versieht dadurch einen alten Auftrag nach
Boarding und Readmission mit einer neuen Lifecyclegeneration. Ein Teilretirement
darf weder diesen alten Auftrag wiederbeleben noch den Auftrag der anderen
Truppmitglieder löschen.

## Umfang / Nicht-Ziele

Bestehende Execution-Dictionaries binden einmal zugelassene Empfänger an
Rootinstanz, Kontext, Actor und Lifecycle. Alle Reissue-/Kontakt-/Stancepfade
entfernen ausgeschiedene Mitglieder dauerhaft aus dieser Ausführung. Automatische
Fortsetzungen erben die verbliebenen Mitglieder; ein neuer expliziter Auftrag
darf den aktuellen Roster aufnehmen. Vollständiges Execution-Clear räumt FMC mit.
Keine zweite Personalregistry, keine neue Gruppenmitgliedschaft, keine
Planserialisierung konkreter Instanzbindungen. Keine Rampenänderung, Main,
Produktionsaktivierung, EXE oder große Tests.

## Dokumente / Contracts

Gesamtplan AP6–8; hex_tactical_runtime_contract; hex_ground_lifecycle;
Rampenvertrag und bestehender Root als alleiniger Ground-/Lifecyclebesitzer.

## Akzeptanz

- Boarding/Readmission, Actorersatz und Root-/Kontextwechsel können einen alten
  Einzel- oder Gruppenauftrag nicht erneut an die neue Präsenz ausliefern.
- Verbleibende Mitglieder behalten Ziel und Bewegung; leere Empfänger sind
  terminal, auch am nächsten automatischen Waypoint.
- Stance, Feuerregel, Kontaktstopp und Area-Occupation beachten dieselbe Bindung.
- Neuer expliziter Auftrag kann erneut zugelassene Mitglieder aufnehmen.
- Legacybewegung bleibt erhalten. Sicht und Rampenplanung bleiben Rootarbeit.

## Dateien / lokale Prüfung

Root: kopierter reiner Presence-/Lifecycleleser. FMC: private Executionbindung
und Memberbereinigung. Controller: vorhandene Execution-State-Übergänge und
Area-Commandproducer. Kleiner isolierter Verifier mit tatsächlichen Root-/FMC-
und Controllerbodies, RED/GREEN, Quellen- und Profilguards; unmittelbar
betroffenen Nachbarfall prüfen. Keine Hauptszene oder Peermatrix.

## Risiken / offen

Geerbter leerer Scope muss von fehlendem Scope unterscheidbar bleiben. Die
automatische AdHoc-Rückkehr benötigt den ursprünglichen Scope. RuntimeSelection
und AP7/8 folgen als getrennte Pakete; diese Task erklärt AP6 nicht insgesamt
für abgeschlossen.

## Ergebnis

Tatsächlicher Controller-/Root-/FMC-Verbund48/0 und Move/View-Nachbar65/0,
Quellen-/Profil-/Engine-/Leakguards grün. Originale Erst-Repros FMC2/4 und
Controller7/2; Boundingrest7/2; zusätzlicher Cross-Team-Return47/1→48/0.
Zwei enge unabhängige Readonlyreviews und gezielte Nachprüfung geschlossen.
QA hält auch nicht akzeptierte Compile-/Fixture-/Leakversuche fest.
Die geerbte Scopehülle enthält einmal gebundene return_crew für den bestehenden
Schiffsauftrag; Suppression/AdHoc erhalten sie, Portablepfade entfernen sie.
Alle Fixtures bleiben bei maximal zwölf registrierten Feldern. Kein Nachweis
einer großen Karte, nativen Darstellung oder Leistungsverbesserung.
