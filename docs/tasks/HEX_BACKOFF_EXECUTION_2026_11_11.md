# AP5 vorgeschlagenes Ausweichen tatsächlich ausführen

Basis e4c098f63. Der reine Planer liefert bereits begrenzte legale
backoff_required-Pfade, der Root-Moveadapter hält bisher nur den Grund fest.
Aktive Gegenaufträge können deshalb trotz verfügbarer Ausweichstelle warten.
Verträge: hex_reservation_plan_contract.md, hex_tactical_runtime_contract.md,
explicit_hex_ramps_contract.md sowie AP5 des Arbeitsplans.

HexMovementCommandRuntime darf pro Tick höchstens ein neues Ausweichmanöver aus
einem tatsächlichen Planervorschlag aufnehmen. Nur wartende aktive Moveabsichten
ohne eigene Motionzusagen; Hold/Defend/fehlende Absicht werden nicht umgedeutet.
Unter geeigneten Kandidaten entscheidet niedrigerer Prioritäts-/Wartezeitscore,
dann stabile Unit-ID. Die geräumte Zelle muss auf dem laufenden Weg eines anderen
Teilnehmers liegen; kein grundloses Ausweichen nur wegen desselben Zielwunsches.
Der reine Vorschlag darf als Endpunkt weder die nächsten drei Übergänge noch
das Ziel eines anderen Requests belegen. Ein einmaliger kleiner Index aus
höchstens16×5 angefragten Pfadpunkten verhindert ein neues Hindernis direkt vor
dem Gegenverkehr; die gemeinsame64-Knoten-Rücksetzsuche bleibt unverändert begrenzt.
Wenn im aktuellen Tick bereits ein Planrequest vorliegt, dürfen direkt
konkurrierende, nur wegen Retrytakten wartende Requests mit gültigem Cache bis
zum bestehenden16er Limit gemeinsam mitgeprüft werden. Kein neuer Suchjob.
Ein beim Timingaufbau abgeleiteter Pfadindex vermeidet volle Pfadscans beim
Feldwechsel und bei dieser Nachbarschaftsprüfung; er wird mit dem Pfad gelöscht.

Der angenommene öffentliche Ziel-/UnitCommand bleibt erhalten. Fortschritt der
Ausweichroute setzt auch dessen Wartealter nicht zurück; erst ein zugesagter
Schritt zum ursprünglichen Ziel setzt den normalen Wartezähler zurück. Privater
Recoveryzustand hält abgeleitetes Ausweichziel, Phase und die zugehörigen
konkurrierenden Absichts-IDs. Der vorgeschlagene Pfad geht im nächsten Tick erneut durch denselben
atomaren Planer/Ownercommit, mit derselben Geschwindigkeit, Rampenregel und dem
Dreischritthorizont. Keine Teleports, Extrakollision oder zweite Feldwahrheit.
Nach Erreichen der Ausweichstelle wartet der NPC, bis die betreffende Passage
stattgefunden hat und deren Claim frei ist oder der konkurrierende Auftrag
endet/gewechselt/entfernt wird. Dann frische Navigation zum ursprünglichen Ziel.
Ein privater Reverseindex der Recoverybeobachter verarbeitet committed Feldwechsel;
kein Order×Feldwechsel-Vollscan und kein neues SceneTree-Suchen.

Neuer Auftrag/Hold/Wunde/Release/Contextende räumt Recovery samt Reverseindex auf;
Terraininvalidierung darf keinen verwaisten privaten Ausweichauftrag halten.
Readout erklärt Recoveryphase/-ziel, Ankunft gilt ausschließlich dem öffentlichen
angenommenen Ziel. AP7 muss Recoveryabsicht/Beobachtungsphase konsistent sichern
oder Restore vor Aktivierung ablehnen; Such-/Timing-/Reverseindex bleiben abgeleitet.

Dateien: HexMovementCommandRuntime, schmale reine Backoffzielwahl im vorhandenen
BottleneckReservationResolver, kleiner hex_backoff_execution_verifier und
isolierter Runner, Runtimecontract/QA. Kleiner tatsächlicher Root-/Registry-/
Actorfall mit Gegenaufträgen und Ausweichraum (höchstens zwölf Felder), Zustand
bleibt exklusiv, beide ursprünglichen Ziele werden erreicht, keine frühe Ankunft.
Weitere gezielte Fälle: Hold während Recovery und fehlende Ausweichmöglichkeit;
kanonische Root-/Rampen-/Stoppregeln bleiben bestehen. Enger Review vor Commit.

Nichtziele: allgemeiner optimaler Mehragentenplaner/Deadlockfreiheitsbeweis,
automatisches Versetzen ausdrücklich haltender NPCs, Lifecycle/Save/Netzwerk,
Kartenaktivierung und große Gefechts-/Performance-/Nativeabnahme.

Ergebnis: tatsächliches Ausweichen und Wiederaufnahme über denselben Owner
angeschlossen. Backoff55/0 inklusive42 Bewegungsbasis, reiner Planer26/0,
Reservierungsowner36/0; alle Guards grün. Getaktet fertige Gegenanfragen und
invalidierte Bay wurden51/2→53/0 durch gecachte gemeinsame Requests geschlossen;
Wartealter53/1→54/0 erhalten. Gelöschte, bereits geräumte Clearancezelle54/1→55/0:
fehlgeschlagener Claimread verwirft die private Wartebindung und plant Originalziel
neu, statt dieses zu verwaisen. Enger Review schloss den letzten vollständigen
Pfadscan durch Indexlookup; keine verbleibenden engen Befunde.
QA hex_backoff_execution_20261111. Abgeleitete Pfadindizes/Watcher bleiben Cache,
Recoverysemantik gehört weiter in den noch offenen AP7-Restorevertrag.
