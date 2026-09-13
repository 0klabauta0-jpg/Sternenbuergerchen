# N4 · abschließender öffentlicher Internetlauf

13.09.2026, Godot4.6.2, `tests/internet_run.ps1 -Public -Port 28148`: **70/70 Checks bestanden (Host31/Gast39)**. Zwei echte Prozesse kommunizierten durch einen tatsächlich gestarteten Cloudflare Quick Tunnel über öffentliche WSS. Evidenz: `C:/Users/bjoer/AppData/Local/Temp/sternen-internet-eaae30024c1a416cbe2cad35b2cc0482`.

Falscher Einladungsschlüssel, abweichendes Schema und Protokoll wurden vom Host tatsächlich abgewiesen, ohne Snapshot/Commandzugriff. Danach geteilte gesamte Crew, echtes Gehen, einmalige doppelte Anfrage, weiterhin kein PvP, Pause, reale Save-Wiederherstellung, monotone Revision und Reconnect. Gefertigte Rüstung wurde am Lagerzugang angelegt; beide Figuren liefen in ihre tatsächlichen Sitze. Der Gast führte Launch → Orbit → interplanetare Reise → Landung → gemeinsamen Kauf aus. Schema4, Rüstung, neue Region und verbrauchte Credits wurden auf dem Gast bestätigt. Alle drei vollständigen Snapshotpaare sind identisch; beide Enginefehlerlogs leer.

Die produktive Authentifizierung verwendet weiterhin das tatsächliche Snapshot-Schema. Keine neuen Autoritätsausnahmen waren nötig; Sessiontexte zeigen nun geteilte Crewrechte. Der portable Tunnelhelfer wurde am Ende gestoppt, die temporäre Einladung gelöscht. Keine System-DNS-/Routeränderung und keine Abschaltung der TLS-Prüfung. Zwei getrennte Heimnetze bleiben als physischer Aufbau ungeprüft; dieser Lauf bestätigt echten öffentlichen Relayverkehr vom lokalen Rechner. Quick Tunnel bleibt ein temporärer früher Dienst ohne Verfügbarkeitsgarantie.

Vorherige Versuche werden ausdrücklich nicht als saubere Läufe gezählt: ein75s-DNS-Timeout vor Einladungsfreigabe; ein70/70-Lauf mit parallel beschädigtem UTF8-Coreimport; ein weiterer70/70-Lauf mit Race beim Lesen noch unvollständiger Test-Evidenz. Die Probe veröffentlicht JSON nun über temporäre Datei und Rename; der abschließende Lauf oben bestand einschließlich strenger Logprüfung. Dieser Harnessfix ändert keinen Produktzustand.

Zusätzlich:15/15 Gateway-Lifecycle-/Malformed-Invitechecks;62/62 echte ENet-Produktfensterchecks siehe `tests/network_report.md`. Drei bestätigte APIchecks und22 native Dossier-Mausprüfungen siehe `tests/crew_dossier_report.md`.

---

## Historische N3-Internetabnahme
# Internet-Koop-Abnahme · 13.09.2026

Godot **4.6.2.stable.official.71f334935**, portabler offizieller cloudflared **2026.9.1**, aktueller Core **Schema 3**. Keine Kern-, UI-, Welt- oder game.gd-Änderungen durch diesen Teilauftrag; keine normale Nutzerkarriere verwendet.

| Tatsächlicher Lauf | Ergebnis | Evidenzordner unter `C:/Users/bjoer/AppData/Local/Temp/` |
|---|---|---|
| Reguläres öffentliches WSS, zwei Godot-Prozesse | Host 25/25, Gast 30/30 | `sternen-internet-ced5514191fe4762bbdbac830d9e9afb` |
| Produktiver DNS-/TLS-Fallback, ausdrücklich ausgewählt, ebenfalls öffentlicher Tunnel | Host 25/25, Gast 30/30 | `sternen-internet-3019c9aed37542cfa3d54e3d40404e05` |
| ENet-LAN-Regression, zwei Prozesse | Host 43/43, Gast 26/26 | `sternenbuergerchen-network-3a33ac910df246f082dec35cd6c2d07a` |
| Gateway-Validierung und direkte Session-Freigabe | 15/15 | `tests/internet_gateway_test.gd`, frischer Headlesslauf |

Beide öffentlichen Läufe haben leere Host-/Gast-Fehlerlogs. Drei vollständige Snapshot-Paare sind jeweils identisch: gemeinsame Pause, restaurierter Save und finale neue Region mit ausgerüsteter Rüstung. Der Fallback-Lauf bestätigt über seine Statusfolge tatsächlich den produktiven DNS-Ersatzweg bei allen fünf Verbindungsversuchen; es wurde kein externer Test-Proxy und keine ausgeschaltete TLS-Prüfung verwendet.

## Geprüfter Weg

1. Produktiver Gateway startet eigenen loopbackgebundenen WebSocket-Server und cloudflared; echte Edge-Verbindung und öffentliche DNS-Antwort, erst dann Einladungsfreigabe.
2. Drei tatsächliche Authentifizierungsabbrüche am Host: falscher Einladungsschlüssel, falsches Snapshot-Schema, falsches Protokoll. Kein Snapshot, keine Crewvergabe und keine Core-Receipt an diese Versuche.
3. Richtige Einladung vergibt Jaro. Ein normaler `move` bewegt ihn tatsächlich zum Ziel. Derselbe Request wird zweimal gesendet, mit identischer Bestätigung und genau einer gespeicherten Receipt. Payload-Fälschung `sender_id:1` verschafft keinen Zugriff auf Ida; Gast-Handel wird abgelehnt.
4. Hostpause erscheint beim Gast. Echter Save, anschließender anderer Bewegungsauftrag und Load: Revision steigt trotzdem; Gast erhält den restaurierten vollständigen Snapshot.
5. Abbruch pausiert und gibt Jaro zurück. Dieselbe noch aktive Einladung verbindet erneut; Geld, Pause und Crewzustand bleiben erhalten.
6. Host startet echtes Armor-Crafting; Annäherung und Arbeit dauern tatsächlich. Anschließend Materialverbrauch, `equip armor`, normale Reise nach `tradepost` mit Boarding und Flug. Der Gast erhält Schema 3, die tatsächliche Rüstung und neue Region.

Die Runner prüfen Ergebnisse und Fehlerlogs, räumen eigene Prozesse auf und entfernen ihre temporäre Einladungsdatei. Jeder Lauf besitzt neue Temp-/APPDATA-Pfade. Einladungen/Schlüssel erscheinen nicht in den Nachweisen.

## Gefundene und behobene Probleme

- Ein Gateway-Test war vor Implementierung rot: Internet-API fehlte. Nach Umsetzung und späterem Cleanup-Ausbau 15/15.
- Neue Quick-Tunnel-Namen waren lokal zunächst NXDOMAIN. Auch einmalige autorisierte Leerung des Windows-DNS-Caches half nicht zuverlässig; keine Resolver-/hosts-/Routerkonfiguration wurde verändert. Der Host prüft jetzt die öffentliche DNS-Bereitschaft vor Einladung. Gast: Godot-Cache-Retry, anschließend begrenzter produktiver DoH-/TLS-Fallback.
- Direkter IP-Aufruf mit zusätzlichem Hostheader funktioniert nicht: Godot sendet zwei Hostheader; tatsächlicher TLS-Vergleich ergab Cloudflare 403 statt der normalen Antwort. Der Produkt-Fallback setzt genau einen korrekten Hostheader und prüft TLS weiter gegen den Originalnamen.
- Cloudflare-DoH lieferte hier einen nicht vertrauenswürdigen Zertifikatspfad. Dieser wurde nicht freigeschaltet; Google-DoH funktioniert mit normaler Zertifikatsprüfung.
- Direkte Session-Freigabe ohne `disconnect_session()` ließ einen geschlossenen Peer im SceneMultiplayer zurück. Gezielter Regressionstest zuerst rot; explizites Auth-/Peer-Aufräumen in `_exit_tree` macht ihn grün und ermöglicht danach LAN-Hosting.
- Frühe Zwischenläufe lagen noch im gleichzeitig bearbeiteten Catalog-v3/Core-v2-Zustand und lehnten deshalb Saves ab. Die finale öffentliche Abnahme läuft vollständig gegen konsistentes Schema 3.

## Grenze der Aussage

Dies sind zwei tatsächliche Prozesse auf einem Rechner mit einer tatsächlich öffentlichen Cloudflare-WSS-Strecke, einschließlich normaler und alternativer Namensauflösung. Ein separater zweiter Haushalt, ein zweiter Provider, längere Sitzungen, Paketverlust und Provider-Firewalls wurden nicht simuliert oder pauschal als bestanden erklärt. Quick Tunnel bleibt ein temporärer Prototyp ohne SLA; für stabile öffentliche Räume ist später ein betriebener Relay-/Sitzungsdienst vorgesehen. Bedienvertrag, Installation, Quellen und Betriebsgrenzen: [INTERNET_COOP.md](../docs/INTERNET_COOP.md).
