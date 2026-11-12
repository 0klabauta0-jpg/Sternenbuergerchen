# Runtimekontext: begrenzter Sessionnachweis

30/0, Session-/Verifier-Compile jeweils 0. Privates scripts-only Projekt und
eigenes user://, Quelle/echtes Profil unveraendert, Canary vorhanden (report.json).
api_red.log archiviert die fehlende neue API vor Implementierung.

Der echte request_start_mission entscheidet mit vorhandenen Ready-/Hostgates.
Nur ausgehendes _send_start_assignments ist durch einen aufzeichnenden Transport
ersetzt. Echter Clientreceive, Completion, Neustart, Reset und Snapshotguard.
Rejoin ist hier der identische vorhandene Assignment-Sendepfad, KEIN Nachweis
der Authentifizierung/Reconnects mit echten Peers. Die dortige Weiterleitung
verwendet denselben neuen Wrapper und erzeugt keinen Token.

Manifestdaten sind bewusst kleine gueltige Formfixtures, keine Behauptung
einer erneuten Datei-/Downloadhashverifikation. Die bestehende Mapfreigabe
bleibt vorgeschaltet. Ein erster Legacytest nach incoming Manifest traf diese
bestehende Sperre; der korrekte Legacyfall beginnt mit echtem Sessionreset.

Lobbydelta ist ausschliesslich der delegierende, kopierende Getter (6 Zeilen).
Kein Lobby-/Missionsszenenstart oder Rootbinderlauf; damit auch kein Compile-
oder Laufzeitnachweis der grossen Lobbyclosure. Root/Driver/Receiver/Contracts
und Sharedrunner wurden nicht geschrieben. Kein Netzwerk-/Gesamt-AP7pass.

Aktiver echter Receive mit Signalabonnenten: active_receive_red.log 24/3
belegt den Reviewfehler vor Fix, einschliesslich leerem Manifest und leerem
Kontext bei mission_started=false. Preflight prueft jetzt den vorgeschlagenen
Kontext/Manifestverbund vor jeder Mutation; Apply meldet bool und Receive
beendet bei false ohne Assignment-/Snapshotsignal. Vorhandener Runtimekontext,
Manifest/Transferstatus und Assignments bleiben bei Reject zusammen erhalten.

Ein gueltiger Snapshot mit anderem Token ist bewusst KEIN neuer Start:
Getter bleibt leer bis zum reliable _receive_start_mission. Der bestehende
mission_assignments_changed kann diesen geprueften Assignmentkey bereits
transportieren. Spaeterer Rootbinder muss Start-/Kontextbindung von normalen
Assignmentupdates unterscheiden. Dies ist keine End-to-end Replaygarantie.
