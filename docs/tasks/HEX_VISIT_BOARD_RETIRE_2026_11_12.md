# AP6: tatsächliches Crewboarding und Ortsretirement

## Ziel / Ursache

Normaler Polisa-Visit kann Boarding ohne Roottransition als erfolgreich melden.
Retirement entfernt Controllerprojektionen schon beim Einreihen von Embarkeffekten,
während Root noch Feld und Bewegungsauftrag hält. Die echte Space-/Flowprobe aus
a85932807 reproduziert diese Grenzen auf dem integrierten Parentstand2bfebc601.

## Umfang / Nicht-Ziele

Exakte bestehende Visit-/Crew-/Piloten-/Sequencebindung verwenden. Hexboarding
nimmt vollständige zulässige Gruppe synchron beim Root vom Boden; erst danach
Controllerindices/Schiffsprojektion und Sichtänderung veröffentlichen. Fehler vor
Commit erhalten bisherige Projektionen. Retirement räumt eigene Ground-/Move-
Bindungen vor Projektion, andere Schiffe, Crew, Orte und verbleibende lokale
Fireteampläne bleiben erhalten. Legacyqueued Weg bleibt erhalten.
Keine neue Flug-/Reise-/Membershipwahrheit, Änderungen an MetaFlow/Spaceowner,
Stationskauf-/Übergaberegeln, Produktionskennung, Main, EXE oder große Matrix.

## Abhängigkeiten / Dokumente

Gesamtplan AP6–8, hex_tactical_runtime_contract, Rampenvertrag,
hex_ground_lifecycle, tatsächliche Polisa-Probe a85932807/QA1358b86eb.
Source besitzt noch ältere Controller-Leseabhängigkeiten: selektiv exakte Crew-
Getter, Flightguard sowie Boarding-/Retirementbasis aus2bfebc601 übernehmen;
insbesondere local_team_remains erhalten. Keine Wholefileübernahme. Der echte
neue öffentliche MetaFlow-Boardingpfad fehlt in Source; für die kleine Verbundprobe
wird dieser Parent-Flow ausdrücklich als gepinnte private Eingabe verwendet.
Gemeinsamer Parentanschluss bleibt separat nachzuweisen.

## Akzeptanz / kleine lokale Prüfung

- Öffentlicher Boardingaufruf erzeugt echte Transition oder weist ab, niemals
  Erfolg mit altem Ground-/Moveclaim. Flightguard und Producer verwenden dieselbe
  Visit-/Crewgruppe, auch beim normalen nichtcampaign Polisa-Visit.
- Alle Root-/Controllergruppenmodelle stehen vor ersten Sicht-/Planungssignalen;
  aktueller Root-/Actor-/Visitwechsel kann keine alte Veröffentlichung fortsetzen.
- Tatsächlicher Flow-Visit, Root/Known/Registry/Ground und akzeptierter Moveintent;
  Actor/Card/Landezustand/UI sind bekannte Fixtureeingaben. Maximal zwölf Felder.
- Zweites Schiff/gleicher Fireteamname und fehlender Root/Actor bleiben erhalten.
  Doppelte Retirementaufrufe sind idempotent und hinterlassen keine alte Bewegung.
- RED/GREEN und unmittelbar betroffener Deploymentnachbar, Quellen-/Profilguards.
  Keine Hauptszene, Gefechte, Peermatrix, große Karte oder native Abnahme.

## Dateien / Risiken

Controller, Rootgruppenembark mit nachgelagerter reiner Projektion, kleiner
Verifier/Runner und QA. Parent behält seine neueren Space-/Flow-/Stationbodies;
Import muss anhand enger Funktions-/Hunkgrenzen erfolgen. Slotidentität und
taktisches Member-Retirement, danach AP7/8 bleiben folgende Pakete.

## Ergebnis / konkrete Callergrenze

Root/Controller mit tatsächlichem privatem Parent-Flow1645bc28a37/0, direkter
Deploymentnachbar95/0, Guards grün. QA `hex_visit_board_retire_20261112` trennt
sieben Basismethoden (einschließlich bereits im Parent geschütztem Pilotassigment)
und neue Fixes. Original4/3→7/0, Callback-/Ownershiprepros27/6→33/0,
tatsächlicher Flow-Wait/Repair und logische Feldmitte36/1→37/0.
Keine Source-Flowdatei überschrieben.

Retirement liefert `{ok,status:committed|waiting|stale,...}`. Waiting-Caller
reicht retirement_binding unverändert zurück: Rootinstance/-kontext, Actor-/
Lifecyclegenerationen und Visitfingerprint. Davor weder Location noch Remember/
Missionsabschluss publizieren, bestehende Pendingtransfer-/Savegates halten
und Retry an denselben Ort/Visit binden. Separater tatsächlicher Parentcaller
verbunden getestet: ursprünglicher Registry-API-Ausfall repariert und über
echten Retry vollständig abgeschlossen. Keine Rollbackbehauptung für Travel.
Callbackwechsel nach altem Modellcommit ergibt stale/historical_committed;
keine alte Fortsetzung in neuen Visit.

## Gemeinsame Parentintegration

Source aa4c64e2c ist selektiv uebernommen: nur der beigefuegte Controllerdelta
auf bestehendem Parent, der kleine Rootdiff und Verifier/QA/Runner. Die sieben
bereits vorhandenen Parentbasismethoden bleiben erhalten. Archivattribute aus
3760208cb erhalten den literal gespeicherten Patch. Zwei neue fehlkodierte
Messagezeilen behalten im Produkt ihre vorherigen lesbaren Parentwerte.

Der gemeinsame Runner liest standardmaessig die tatsaechliche Workspace-Flowdatei.
Nur explizites --flow-ref dient weiterhin einer ausgewiesenen privaten
Branchabhaengigkeit. Historische Source37/0 und Deployment95/0 sind unveraenderte
Sourceevidenz; der frische Parentverbund wird separat aufgezeichnet. Kein
Wholefileimport, keine Rootcheckpoint-/Netzverdrahtung oder Produktionsaktivierung.
