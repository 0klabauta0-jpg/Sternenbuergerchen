# Multiplayer-Disconnect: lokale Netfox-Uhr vor Peerfreigabe stoppen

## Problem und bestätigte Ursache
Zwei echte native Peers erreichen Ready 2, Drop und dieselben acht IDs.
Beim anschließenden öffentlichen Lobby-Disconnect meldet jedoch nur der
Client mehrfach `get_unique_id` und RPC ohne Peer, danach eine Resource-Leak.
Beleg: `output/playtest_20261105/multiplayer_fullscreen_current_display/
20261105T084403Z-dab2e1b1/client.log`.

`MultiplayerSession._clear_multiplayer_peer` setzt den Peer unmittelbar null.
Netfox `NetworkEvents` stoppt die Clientuhr normalerweise über das Signal
`server_disconnected`; ein selbst ausgelöster lokaler Close garantiert diesen
Remoteevent nicht. Die bereits gestartete `NetworkTimeSynchronizer._loop`
wartet auf ihren Timer und läuft bei weiterhin `_active` erneut ohne Peer.
Die vorhandene öffentliche `NetworkTime.stop()` stoppt Synchronizer,
Tickratehandshake und Tickzustand. Diese API gehört deshalb vor die lokale
Peerfreigabe im Sessionowner, nicht in einen UI-/Testcleanup-Sonderpfad.

## Vertrag und Umfang
Vor dem Entfernen des zugehörigen MultiplayerPeers stoppt der Sessionowner
die öffentliche Netfox-Uhr. Er greift nur zu, wenn Session und globaler
Netfox-Autoload exakt dieselbe MultiplayerAPI besitzen. Andere in-process
Test-/Teilbäume mit eigenem MultiplayerAPI dürfen eine fremde Uhr nicht
stoppen. Bestehende Ready-, Rejoin-, Assignment-, Mission- und Resetregeln
bleiben unverändert. Kein Addonpatch und keine zweite Netzwerkautorität.
Der öffentliche Netfoxstop emittiert laut lokalem Quellcode keine eigenen
Sessionevents; er setzt das Syncflag, löst den Handshakehandler und setzt die
Clock zurück. Der Produktpfad wartet nicht und bleibt synchron. Der vorhandene
native Probe wartet anschließend lang genug, damit die gestoppte Timer-
Coroutine regulär auslaufen kann.

## Akzeptanz und Prüfung
Der bestehende normale Zwei-Prozess-Harness ist der reale RED-/GREEN-Pfad.
Retry4 belegt bereits 18 Enginefehler und die Resource-Leak beim öffentlichen
Lobby-Disconnect; dieser härtere Beleg wird nicht durch eine zweite künstliche
Clientfixture ersetzt. Der unveränderte strikte `no_engine_diagnostics`-Check
muss nach dem Fix bei normalem Client-Disconnect und Drain grün werden.
Zusätzlicher kurzer Einprozess-Verifier: echte Root-ENet-Hostclock läuft;
eine separate Session mit fremder MultiplayerAPI darf sie nicht stoppen.
Eigener öffentlicher Rootdisconnect stoppt Tickzustand und Synchronizer,
danach mindestens zwei Syncintervalle keine weiteren Ticks. Das ist die
Ownership-/Stopregression, kein Ersatz für den nativen Clientbeleg.
Root führt GREEN und Ready-/Rejoin-/Autoloadnachbarn aus; keine eigenen Engines.

## Dateien, Dokumente und Risiken
Produkt: nur `scripts/multiplayer/multiplayer_session.gd`, Peerfreigabehelper.
Neu: `scripts/tests/playtest_20261105_multiplayer_disconnect_owner_verifier.gd`.
Verbindlich: vier Kerndokumente, Vollbildtask, `multiplayer_session_lobby.md`
und lokale Netfox `network-time.gd`, `network-events.gd`,
`network-time-synchronizer.gd`. Risiken: gestoppte Coroutine braucht noch einen
Timerumlauf zum Drain; vorzeitig beendeter Prozess wäre kein Leaknachweis.
Ready/Rejoin/Autoload-Nachbarn und unveränderte isolierte Saves separat prüfen.

## P2-Nachbefund: sofortiger Hostneustart
Unabhängiger Review bestätigt einen Integrationssonderfall des neuen Stops:
`start_host()` auf aktivem Host oder Disconnect und `start_host()` im selben
Frame entfernen und ersetzen den Peer, bevor `NetworkEvents` seine gecachte
Serverkante verarbeiten kann. Seine Servermarkierung bleibt wahr; ein neues
automatisches Startsignal bleibt aus. Der Stop muss erhalten bleiben, jedoch
muss der neue echte Host nach der normalen Eventverarbeitung wieder ticken.
Der Ownershipverifier ergänzt beide öffentlichen Szenarien vor dem Fix;
keine Addonänderung und kein manuelles Emittieren von NetworkEvents-Signalen.
Eine verzögerte Reparatur darf nur den weiterhin identischen Hostpeer und
dieselbe MultiplayerAPI betreffen und keinen bereits gestarteten Clocklauf
doppelt starten. Disconnect vor Ausführung darf die Clock nicht reaktivieren.

Der unveränderte Ownershipverifier reproduziert den Nachbefund mit 12 PASS
und vier FAIL unter `output/playtest_20261105/final_followups/
20261105T090756Z-efccce3e/disconnect_restart_red.log`: Beide öffentlichen
Hostwechsel gelingen, jedoch bleiben Clock und neue echte Ticks aus.
Akzeptanz: Alle 16 bestehenden Assertions müssen nach der Korrektur bestehen.
Der Hoststart plant dafür nur eine einmalige Prüfung nach zwei
`process_frame`-Grenzen. Normale Netfox-Events bekommen zuerst Gelegenheit zum
Start. Schwache Referenzen auf ursprünglichen Peer und MultiplayerAPI sowie
Host-, Tree- und Ownershipprüfung verwerfen überholte Aufträge; nur beim
weiterhin identischen verbundenen Host darf ein öffentlich noch nicht
abgeschlossener Initialsync die öffentliche `NetworkTime.start()` auslösen.
Frischer Hoststart und der reale native Clientlauf bleiben zusätzliche Gates.
