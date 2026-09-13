# Temporärer Internet-Koop · 13.09.2026

Das Spiel kann einen zweiten Commander über eine öffentliche WSS-Einladung verbinden. Host und Gast benutzen weiterhin denselben Session-Gateway und autoritativen `SimulationRoot.submit(command, sender)`. Beide verbundenen Commander führen sämtliche Crew, Arbeit, Schiff, Handel und gemeinsame Pause. Der Host bleibt Simulations-, Sitzungs- und Dateiautorität. N4 verwendet Schema4; der Handshake liest die Version aus dem tatsächlichen Snapshot.

## Bedienung und portabler Helfer

Im Koopfenster Internet wählen, Sitzung öffnen, auf „Internet bereit“ warten und die Einladung ausdrücklich kopieren. Der Freund fügt den vollständigen Link ein. Der Host lässt das Spiel offen. Schließen/Wechsel zu Solo oder LAN beendet den eigenen Tunnel. Eine neue Internetsitzung erzeugt einen neuen Schlüssel und eine neue Adresse. Reconnect verwendet die Einladung derselben noch laufenden Sitzung.

Der Host benötigt das portable offizielle `cloudflared.exe`. Zuerst wird `tools/cloudflared.exe` neben der exportierten Spiel-EXE gesucht, danach `%LOCALAPPDATA%/SternenBuergerchen-Neustart/tools/cloudflared.exe`. Einmalige Vorbereitung aus dem Checkout:

```powershell
powershell -ExecutionPolicy Bypass -File tools/install_cloudflared.ps1
```

Das Skript lädt die offizielle Windows-amd64-Datei der Version 2026.9.1 und prüft SHA-256 `2837888cc0f5d58f15b6dc478376de90b4d3ba5241c7947455d1e0a0df429712`. Es installiert keinen Dienst, ändert weder PATH noch Router und benötigt keinen Cloudflare-Account. Der Gast benötigt den Helfer nicht. Quelle und Lizenz: [Cloudflare-Downloadübersicht](https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/downloads/), [offizielles Release](https://github.com/cloudflare/cloudflared/releases/tag/2026.9.1).

## Gateway-Vertrag

Bestehende Methoden `start_host(port=27991)` / `join_host(address,port=27991)` behalten den ENet-LAN-Weg. Internet und LAN sind alternative Sitzungsmodi, keine zwei parallel belegbaren Gastplätze.

- `start_internet_host(cloudflared_path="",port=27992)->Error`: startet den WebSocket-Server ausschließlich an 127.0.0.1 und den eigenen Hintergrundprozess. OK bedeutet Start angenommen; die Einladung wird erst nach registrierter Edge-Verbindung und bestätigter öffentlicher DNS-Antwort freigegeben. Abbruch nach höchstens 75 Sekunden.
- `invitation_ready(invitation:String)`: vollständige Einladung nur für die explizite Kopieraktion.
- `internet_invitation()->String`: während der Vorbereitung leer, danach `wss://<zufall>.trycloudflare.com#<64 Hexzeichen>`.
- `join_internet(invitation:String)->Error`: prüft Syntax vor Sitzungswechsel; OK bedeutet Verbindungsversuch. Bestehende `connection_changed`, `snapshot_received`, `command_result` melden das tatsächliche Ergebnis.
- `disconnect_session()`: beendet Authentifizierung, Peer und eigene Hilfsprozesse/Weiterleitungen. Auch direkte Node-Freigabe bereinigt Peer/Auth ohne notwendige vorgelagerte UI-Aktion.
- `transport_name()->String`: solo, lan oder internet.
- `start_websocket_host(port=27992)->Error`: loopbackgebundener Transport für gezielte Tests oder einen ausdrücklich verwalteten Reverse Proxy. Seine lokale Einladung beginnt mit `ws://127.0.0.1`; unverschlüsselte entfernte WS-Einladungen werden abgelehnt.

Einladungen sind Zugangsdaten. Sie erscheinen nicht in Statusmeldungen, Karriere-Saves, Command-Receipts oder normalen Logs. Der URL-Fragmentteil wird nie als HTTP-URL an Cloudflare geschickt. Tests löschen ihre eigene Einladungsdatei nach dem Lauf.

## Authentifizierung und unveränderte Spielautorität

Vor `peer_connected`, Besitzvergabe, Snapshots und RPC-Zugriff läuft SceneMultiplayer-Authentifizierung: gemeinsames Protokoll, tatsächliches Snapshot-Schema, frische 256-Bit-Challenge und gegenseitiger HMAC-SHA256-Nachweis des Einladungsschlüssels. Eine aufgezeichnete Antwort gilt nicht für die nächste Challenge. Gleichzeitige Anmeldeversuche sind begrenzt; es existiert genau ein bestätigter Gastplatz. Timeout: acht Sekunden. Objektdekodierung bleibt ausgeschaltet. Grundlage: [SceneMultiplayer 4.6](https://docs.godotengine.org/en/4.6/classes/class_scenemultiplayer.html).

Nach Anmeldung wird der Absender ausschließlich aus der Verbindung abgeleitet. Der Kern prüft Sitzungsmitgliedschaft, Ressourcen, Tätigkeits-/Sitzbindungen, Pause, Spielregeln und Idempotenz wie im LAN. owner ist in N4 keine Crew-Befehlssperre; gemeinsame Rechte ermöglichen kein PvP. Internetbefehle sind zusätzlich auf 4096 Byte und 30 Pakete pro Sekunde begrenzt; darüber erfolgt eine Gateway-Ablehnung ohne Kernmutation. Snapshots werden wie zuvor bei geänderter Revision maximal zehnmal pro Sekunde gesendet. WebSocket-/Weiterleitungspuffer sind auf 1 MiB begrenzt. Das ist kein allgemeiner Last- oder DDoS-Nachweis.

## DNS und TLS

Ein neuer Quick-Tunnel-Name kann verzögert auflösbar sein. Der Host wartet vor Freigabe der Einladung auf eine erfolgreiche öffentliche Auflösung. Der Gast versucht zunächst normales WSS; bei Verbindungsfehler folgt genau ein weiterer Versuch mit geleertem Godot-DNS-Cache. Nur für `*.trycloudflare.com` folgt bei erneutem Fehler ein automatischer Fallback im selben Godot-Prozess.

Der Fallback fragt Google Public DNS per HTTPS nach dem Domainnamen, ohne Einladungsschlüssel und mit `edns_client_subnet=0.0.0.0/0`. Vorübergehende negative Antworten werden begrenzt wiederholt. Danach verbindet `StreamPeerTLS` zur aufgelösten IP mit dem **ursprünglichen Domainnamen als SNI und Zertifikatsprüfnamen**. Ein nur lokal gebundener TCP-Listener führt die unveränderten WebSocket-Daten weiter und ersetzt ausschließlich den lokalen HTTP-Hostheader. Es gibt keinen Python-Prozess und keine Gastinstallation. Quelle: [Google DoH-JSON-API](https://developers.google.com/speed/public-dns/docs/doh/json).

Zertifikatsprüfung wird weder für DNS noch Spieltransport abgeschaltet. Der direkte IP-Ansatz mit `WebSocketMultiplayerPeer.handshake_headers` wurde verworfen: Godot schreibt einen festen Hostheader aus der URL und hängt Zusatzheader an; zwei Hostheader werden von Cloudflare abgewiesen. Quellen: [Godot-WebSocket-Quellcode](https://github.com/godotengine/godot/blob/4.6-stable/modules/websocket/wsl_peer.cpp), [TLS-Hostnameprüfung](https://github.com/godotengine/godot/blob/4.6-stable/modules/mbedtls/tls_context_mbedtls.cpp), [WebSocketMultiplayerPeer 4.6](https://docs.godotengine.org/en/4.6/classes/class_websocketmultiplayerpeer.html).

## Betriebsgrenzen und Alternativen

Quick Tunnels sind ein temporäres frühes Angebot für Entwicklung und Tests, ohne SLA oder Verfügbarkeitsgarantie. Adressen ändern sich beim Neustart. Cloudflare nennt maximal 200 gleichzeitig offene Anfragen; WebSockets werden unterstützt. Ausgehende Tunnelverbindungen und HTTPS müssen im jeweiligen Netz erlaubt sein. Cloudflare vermittelt und terminiert den öffentlichen TLS-Abschnitt; es handelt sich nicht um Ende-zu-Ende-Verschlüsselung zwischen den beiden Spielen. Quellen: [Quick-Tunnel-Grenzen](https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/do-more-with-tunnels/trycloudflare/), [WebSocket-Unterstützung](https://developers.cloudflare.com/cloudflare-one/faq/cloudflare-tunnels-faq/), [Firewall-Anforderungen](https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/configure-tunnels/tunnel-with-firewall/).

Ein bestehendes eigenes `.cloudflared/config.yaml` kann Quick Tunnels verhindern; das Spiel verändert diese Datei nicht. Normales Spielende und Sitzungswechsel räumen den gestarteten Helfer auf. Bei hartem Prozessabsturz kann ein gestarteter Helfer zurückbleiben; die WebSocket-Spielinstanz ist dann geschlossen. Stabile Räume, Einladungsverwaltung, garantierte Verfügbarkeit und kontrollierter Relay-Betrieb bleiben eine spätere Dienststufe.

WebRTC wäre eine andere Transportbasis, benötigt für native Godot-Programme aber eine Erweiterung sowie Signaling und gegebenenfalls TURN-Betrieb. Ein privates VPN wie Tailscale erhält ENet, erfordert jedoch Konten und Clientinstallation auf beiden Seiten. Beide Varianten wurden deshalb für den gewünschten direkten Einstieg ohne dauerhafte Zusatzinstallation zurückgestellt. Quellen: [Godot WebRTC](https://docs.godotengine.org/en/4.6/tutorials/networking/webrtc.html), [Tailscale-Einstieg](https://tailscale.com/kb/1017/install).

## Reproduzierbare Abnahme

```powershell
& 'C:/Users/bjoer/AppData/Local/Programs/Godot/Godot_v4.6.2-stable_win64_console.exe' --headless --path . --script res://tests/internet_gateway_test.gd
./tests/internet_run.ps1 -Public
./tests/internet_run.ps1 -Public -ForceDnsFallback -Port 28129
./tests/network_run.ps1 -Port 28128
```

Die Runner starten nur eigene Prozesse, verwenden neue Tempordner und isolieren APPDATA. Beide Internetvarianten verwenden einen tatsächlich öffentlichen Cloudflare-Tunnel. `-ForceDnsFallback` wählt gezielt den produktiven Fallback, ohne Verbindungsbestätigung oder Spielzustand vorzugeben. Der funktionale Test benutzt echte Corebefehle und vergangene Simulationszeit: gemeinsame Befehle für beide Figuren, kein PvP, identische doppelte Receipt, gemeinsame Pause, monotone Save-Restore-Revision, Reconnect, reale Rüstungsherstellung am Lagerzugang, tatsächliches Einsteigen und Gastbefehle für Launch/Orbit/Reise/Landung/Handel. Drei vollständige Snapshot-Paare werden verglichen.

Aktuell N4:70/70 öffentliche WSS-Checks,62/62 ENet-Produktfensterchecks und15/15 Gatewaychecks. Der separat erzwungene produktive DNS-/TLS-Ersatzweg ist ein historischer N3-Nachweis; er wurde nicht als zusätzliche N4-Abnahme gezählt. Ergebnisse und lokale Evidenzpfade stehen in [internet_report.md](../tests/internet_report.md). Zwei Prozesse auf diesem Rechner durchlaufen tatsächlich das öffentliche Internet; ein unabhängiges zweites Heimnetz und dessen eigene Firewall/Provider wurden damit noch nicht abgenommen.
