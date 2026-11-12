# Multiplayer Runtimekontext am Startassignment

## Ziel / Ursache
Gleichnamige Roster reichen nicht als Map-/Matchidentitaet fuer eine spaetere
Fullprojection. Die Session besitzt den echten Start-/Rejoinlebenszyklus.

## Umfang / Nichtziele
Nur multiplayer_session.gd, multiplayer_lobby_screen.gd, eigener Verifier/QA.
Keine Root-/Driver-/Receiver-/Contract-/Sharedrunnerwrites oder Binderaufrufe.
Keine echten Peers, kein Gesamt-Multiplayerpass, kein Stage/Commit.

## API / Akzeptanz
get_multiplayer_runtime_context() liefert eine Kopie oder {}. Assignmentkey
multiplayer_runtime_context: schema multiplayer.runtime_context.v1,
runtime_token, map_id, map_hash und optional scenario_hash. Keine Pfade.
Neuer erfolgreicher Hoststart erzeugt einen Crypto-Token; Getter und Rejoin
erzeugen keinen. Completion/Reset loeschen. Reliable Start validiert explizit
vorhandenen Kontext vor Aktivierung; fehlender Key bleibt Legacy.

## Evidenzgrenze / relevante Quellen
docs/dev/multiplayer_session_lobby.md und
docs/dev/multiplayer_editor_map_transfer_contract.md bleiben unveraendert.
Bestehender MultiplayerMapManifest.verify_manifest prueft Manifestform; der
bestehende lokale Datei-/Downloadpfad besitzt die Inhaltspruefung. Dieser Slice
uebernimmt nur dessen akzeptierte Identitaet, verifiziert nicht nochmals Bytes.
Ohne gueltiges Manifest bleibt der alte Startweg ohne publizierbaren Kontext.
Spaetere Binderstelle ist die bestehende Assignmentanwendung vor add_child im
Lobbylaunch. AP7 Sender/Receiver und reale Netzmatrix bleiben offen.

## Lokale Pruefung / Risiken
Isolierter echter Session-Start/Receive/Completion/Reset mit kontrollierter
ausgehender RPC-Grenze; Identitaet, Rejoinassignment, Noalias, Versions-/Mapguard,
Legacy und neuer Starttoken. Lobby nur delegierender Readadapter.

## Ergebnis
QA output/native_glut_maps/multiplayer_runtime_context_20261112: 30/0;
Session/Verifier Compile 0, privater Import 0, Quelle/Realprofil/Canary gruen.
Keine echten Peers, keine Lobbyclosure geladen, kein Rootbinderaufruf.

Reviewfix: echter aktiver _receive_session_snapshot mit Subscriber war RED24/3.
Vorabvalidierung gegen vorgeschlagenes Manifest und bool Apply verhindern
Teilmutation und Signale bei Reject. QA umfasst unveraenderte Identitaet,
Assignments und Manifest-/Transferstatus auch beim leeren Completionangebot.
Ein gueltiger Snapshot mit anderem Token bindet keine neue Runtime: Getter
leer bis reliable Start, obwohl mission_assignments_changed den geprueften
Key bereits tragen kann. Spaeterer Rootbinder muss Startbindung explizit von
Assignmentupdates unterscheiden; kein End-to-end Replaypass wird behauptet.
