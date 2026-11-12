# AP6: gebundene Empfänger laufender Aufträge

Source auf unintegrierter Rampenbasis97e00aba14; vorheriger SourceHEADd4059437e.
Keine Main-/Produktionskarten-/EXE-Aktivierung, kein großer Test oder FPS-Beleg.

Tatsächlicher Root/FMC/Controller48/0, direkt betroffener Move/View-Nachbar65/0.
424 beziehungsweise113 konkrete Runtimequellen;410 tatsächliche Workspacequellen
gemeinsam geschützt. Fehlende Sparseabhängigkeiten des Controllerfalls stammen
ausschließlich aus dem gepinnten eigenen HEAD, mit separaten Gitprovenienzen.
Keine Parent-Flow-Pinübernahme und keine extrahierten Controllerfunktionskörper.

Alle finalen Prüfungen: privates UUID-Projekt und Profil, Originalprofil unverändert,
Quellenhashes unverändert, Enginefehler-/Leakguard, Laufzeit-/Importgrenze30s je
Prozess. Maximal zwölf registrierte Felder je Fixture; kein Hauptszenenstart.
Bekannte Fixtureeingaben sind Roster/Leader, UI-/Feedbackantworten, Arearesolver-
Assignments und Craftkontext. Root, Ground, Actorlebenszyklus, FMC und die
geprüften Controllerproducer/-fortsetzungen sind tatsächliche Implementierungen.

Originale Repros (im ZIP unverändert):

- FMC alter Auftrag nach Boarding/Readmission:2/4, danach6/0.
- Controller automatische Waypointfortsetzung und fehlender FMC-Fullclear:7/2.
- Retirement der gesamten laufenden Boundingteilgruppe:7/2, danach9/0.
- Truppübergreifende Returncrew nach Suppression:47/1, danach48/0.

Zusätzliche Fälle: Stance/Feuerregel/Kontakt; Bounding und Caterpillar; Kontaktstopp
mit Moverretirement, Stance-/FireRulewechsel und anschließender Fortsetzung;
Actor-/Root-/Kontextwechsel; Legacy und Legacy→Hex; Area/Occupation; stationärer
Computer-USE; Suppression und AdHoc-Rückkehr; terminaler Scope; Scopefreiheit
portabler Daten; verbleibender Koordinationspartner; normale und unterbrochene
truppübergreifende Schiffsrückkehr. Zwei enge unabhängige Readonlyreviews,
konkrete Befunde geschlossen und Reviewfollowup ohne weitere konkrete Befunde.

`original_runs.zip` enthält17 Originalversuche einschließlich verworfener
Compile-/Fixture-/Diagnosekandidaten. Zu breite textuelle Callsiteersetzungen
verursachten einen korrigierten Argumentfehler; ein Fixtureoverride hatte zunächst
eine falsche Signatur. Zwei Fixtureversuche benutzten einen belegten
Readmissionanker; korrigiert auf den tatsächlich freigegebenen Anker und jetzt
explizit als Voraussetzung geprüft. Ein Kandidat hatte33/0 Assertions, wurde aber
wegen zweier unparenteter lazily erzeugter Readmodel-Nodes verworfen. Die Fixture
stellt beide tatsächlichen Models jetzt als Scenechildren bereit; kein zusätzlicher
Produktfix dafür. Der Verbosediagnoselauf zeigt die ursprünglichen Leaks. Diese
Versuche sind keine akzeptierten GREENs und keine sauberen Produkt-REDs.

Rampen-, Terrain-, Ground-/Movementprepared- und medizinische Bodies bleiben
unverändert. RuntimeSelection und AP7/8 sind weiterhin offen.
