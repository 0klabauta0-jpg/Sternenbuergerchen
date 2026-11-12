# AP6: fremde Schiffsflächen und reguläre Profilbindung

## Ziel / Ursache

Gruppen dürfen nicht in fremden geparkten oder bereits reservierten Schiffsflächen
eingesetzt werden. Eine angenommene Landung darf umgekehrt keine tatsächlichen
oder zugesagten NPCplätze blockieren. Die bisherige FieldLandingprüfung beschreibt
sieben Zellen und Sicherheitsabstand, keine vollständigen größeren Schiffskörper.

## Umfang / Nicht-Ziele

Reine begrenzte Ableitung von Hexsperren aus vorhandenen Landeständen und ihren
einmal angenommenen Profilen. Position/Phase bleiben im bisherigen Controller.
Root prüft Gruppenplätze und Claims; keine zweite Schiffspositionsregistry.
Normale tatsächliche Polisa-Ankünfte binden ebenfalls ein geprüftes Profil beim
angenommenen neuen Landevorgang, damit der bestehende lokale Kaufweg konsistent ist.
Keine neue Modellkunst, Meshphysik, Kartenaktivierung, Main, EXE oder große Probe.

## Dokumente / Abhängigkeiten

- `docs/dev/polisa_bound_ground_body_profile_contract.md`
- `docs/dev/hex_tactical_runtime_contract.md`
- `docs/dev/explicit_hex_ramps_contract.md`
- `docs/tasks/HEX_GROUND_LIFECYCLE_2026_11_11.md`
- Parent `4af353f24`: reiner Profilvalidator, hier als `65208a9d3` übernommen.
- Der bestehende reine `polisa_station_craft_runtime.gd` wird unverändert aus
  demselben Parentstand für `projected_body` verwendet. Keine neue Parallelformel.
- Parent `244a7354a`: nur die beiden reservierten lokalen Polisa-Admitbodies;
  regulärer Producer muss vor einer gepaarten produktiven Aktivierung folgen.

## Akzeptanz

- Fremde angenommene LZ/parkende Schiffe blockieren; eigenes aussteigendes Schiff
  wird anhand tatsächlicher Sequenz-Craft-ID ausgenommen. Unbemannte Käufe zählen.
- Gebundener Body bleibt bei Kamerawechsel unverändert; fehlende oder falsche
  Geometrie wartet geschlossen und wird nicht aus aktueller Kamera repariert.
- Zellableitung prüft nur lokale Rastergrenzen, maximal4096 Kandidaten. Ganze
  Hexflächen einschließlich Randkontakt zählen, keine reine Mittelpunktprobe.
  Budget-/Koordinatenfehler liefern keine abgeschnittene freie Teilfläche.
- Gruppenplanung überschreitet diese Sperren nicht und bleibt vollständig/atomar.
- Endgültige abweichungsbereinigte LZ prüft alle NPC-/Slot-/Kanten-/Passageclaims
  vor Ownerwrite; Registry-/Kontextbezug muss stimmen.
- Neue reguläre Ankunft bindet detached validiertes Profil genau beim erfolgreichen
  Landeauftrag. Abgelehnte oder wiederholte Versuche ändern keinen Landestand.
- Offene Schiffs-/NPC-/Basissaves werden nicht implizit erweitert. Setup/Base und
  AP7/8 bleiben weitere Pakete, große AP9-Abnahme später.

## Dateien / lokale Prüfung

Neuer reiner `scripts/mission/hex_ground_ship_footprint.gd` und kleiner Verifier;
vorhandener Profil-/Bodyhelper, Root/Admission und konkrete Controller-Lande-/
Aussteigegrenzen. Kleine isolierte Fixture mit höchstens12 Feldern, keine Hauptszene.
Quellen-/Profilguards, gezielter RED/GREEN und enger Review vor Commit.

## Risiken / offene Punkte

Der Renderer liefert den Geometriebeleg für neue echte Ankünfte; bereits akzeptierte
Profile werden ausschließlich gebunden gelesen. Der vorhandene Parent besitzt die
beiden lokalen Kauf-Admitbodies, Space besitzt Pilot-/Reisegates. Deren aktuelle
Crew-/Visitregeln werden beim Integrationspatch nicht ersetzt. Abgeleitete Sperren
werden am vorhandenen Owner gecacht, nicht als per-frame Kartenrebuild erzeugt.

## Erster geprüfter Teil: Raster und Rootausschluss

Reiner Bodyraster und optionale Root-Ausschlussmaske:52/0 einschließlich42
vorhandener Moveprüfungen, alle Guards und enger Review ohne Befund. Kanonischer
gebundener Profil-/Bodyvertrag, Mittelpunkt verfehlter Randübertritt, Randkontakt,
Budget vor Loop, falsche Craftbindung, tatsächlicher Rootumweg und blockierter
Gruppenanker sowie abweichender Registryursprung/-maßstab geprüft.

Noch offen: konkrete Auswahl/Cache der Schiffslandestände, Consumer an den
Aussteigephasen, Landeclaimguard und einmalige reguläre Profilbindung. Keine
Produktionsaktivierung durch diesen reinen Daten-/Planungsteilschritt.

## Zweiter geprüfter Teil: tatsächlicher Producer und Consumer

Auswahl akzeptierter Landestände, begrenzter abgeleiteter Cache und tatsächlicher
Consumer sind angeschlossen. Nur ausgewählte, noch nicht akzeptierte wartende
LZ zählen nicht als physischer Rumpf. Fehlende Profile tatsächlich vorhandener
Schiffe werden weiterhin geschlossen abgelehnt. Neues Profil erst nach allen
normalen Startguards; Replays binden es nicht aus veränderter Kamera neu.

Hexlandungen prüfen das endgültige LZ gegen fremde akzeptierte Körper und alle
Rootclaims. Beide Touchdownpfade wiederholen diese aktuelle Claimprüfung, ohne
das angenommene Profil neu zu binden. Abgeleitete Einzelraster sind begrenzt
gecacht. Ein NPC, der nach dem Start in die Fläche läuft, hält den Touchdown an.
Die Maske ist hier eine Eingabe der Gruppenadmission und Landungsprüfung;
allgemeine Schiffskörper als dauerhafte Ground-Navigationsblocker sind damit
noch nicht eingeführt.

Enger Producer66/0, Transportcontrollerregression73/0; Reviewbefunde mit
tatsächlichem RED62/4→GREEN66/0 geschlossen. QA `hex_ship_producer_20261112`.
Der gemeinsame Parent besitzt den tatsächlichen Renderergetter (`b9f194d9e`)
und den Kartenidentitätspfad (`55ccb737a`); die Sourcefixture liefert eine bekannte
Projektion. Älteren Renderer hier nicht breiter migriert. Gemeinsamer Anschluss,
Setup/Base, AP7/8 und spätere große Abnahme bleiben ausdrücklich getrennt.
