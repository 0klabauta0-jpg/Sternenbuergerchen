# Unabhaengiger Nachreview: Move-Token und Netzwerk-Uhr

Status: **APPROVED im unten genannten Scope; keine verbleibenden P1/P2 gefunden.**
Basis ist der beauftragte Playtestzweig auf Original-Main
`90e1f373cd4e070a9a29135225e19cebd297b201`. Der Review hat Quellen und vorhandene
Root-Logs/JSONs gelesen; keine Engine gestartet und keine Produktdatei geaendert.

## Gepruefte Produktpins

| Datei | SHA-256 |
| --- | --- |
| `scripts/core/simulation_root.gd` | `6d42caddf414f2e303ad34b66447fcd54bfe5de170ac058c0b69a4cfd7f940bc` |
| `scripts/multiplayer/multiplayer_session.gd` | `6391d67b81de66747df15daaa6b66cbcb121e654b777dba7cf517b99239deafd` |

## Move nach untokenisiertem Hold

Ein wirklich autoritativ committed leerer Token ist jetzt von einem fehlenden
Commit unterscheidbar. Der leere Latest-Eintrag sperrt bereits wartende alte
Move-Fortsetzungen; ein spaeterer frischer vertrauenswuerdiger Enqueue kann den
Hold ersetzen. Validierung und Authority-Tickgrenze bleiben erhalten.
Navigation-Budgetrequeues erfolgen synchron innerhalb des zuvor stale-geprueften
Move-Pfades; kein legitimer verzoegerter Altproducer wurde in diesem Scope gefunden.

Token sind weiterhin keine historische Sequenzautoritaet. Ein ausdrueckliches
erneutes Enqueue eines alten Tokens wird wie schon zuvor bei tokenisierten
Commits als neuer vertrauenswuerdiger Auftrag behandelt. Der Fix behauptet weder
Replayschutz noch fuehrt er Tokenhistorie oder eine zweite Commandwahrheit ein.

Gelesene Evidenz: Empty-Token-Regression **15/15**, TASK501 **10/10** unter
`output/playtest_20261105/move_token_green/20261105T082243Z-568adf4e/`;
echte normale native Auto-DEF-/Wiederanlaufroute **87/87** unter
`output/playtest_20261105/move_autodefend_green/20261105T082350Z-c450063b/`.
Dieselben drei Actor-IDs bewegen sich nach dem neuen GO; alte Queuefortsetzungen
und neue Befehle werden getrennt geprueft. TASK468 **13/1** reproduziert sich auf
Original-Main identisch und ist kein gruener Nachbarbeleg.

## Lokaler Disconnect und sofortiger Hostneustart

Der Sessionowner stoppt die oeffentliche `NetworkTime.stop()` vor der
Peerfreigabe nur fuer dieselbe MultiplayerAPI. Der fruehere Review-P2 war real:
ein sofortiger Hostwechsel konnte der gepufferten `NetworkEvents`-Serverkante
entgehen und die soeben gestoppte Uhr nicht neu starten. Die ergaenzte Regression
reproduzierte **12/4**; die urspruenglichen Diagnosen bleiben erhalten.

Der neue einmalige Hostcheck nach zwei Processgrenzen laesst zuerst die normalen
Events starten. WeakRefs und Tree-, Peeridentitaets-, API-, Connected-, Authority-
und Rootclock-Ownershipguards verwerfen inzwischen abgeloeste Auftraege. Ein
oeffentlich bereits abgeschlossener Initialsync verhindert einen zweiten Start.
Ein Disconnect vor dem Callback kann dadurch keine veraltete Clock reaktivieren.
Addonquellen und Gameplayregeln werden nicht geaendert.

Root-GREEN **16/16**, Exit 0, keine Enginefehler, bestaetigte Isolation und
unveraenderter geschuetzter Roster:
`output/playtest_20261105/multiplayer_restart_green/20261105T091612Z-e4870192/`.
Der Test prueft einen expliziten Fremdpeer auf eigener MultiplayerAPI, beide
sofortigen oeffentlichen Hostwechsel mit echten neuen Ticks, den eigenen Stop,
vollstaendigen Sessionreset, ausbleibende Ticks ueber zwei Syncintervalle und
idempotenten Disconnect.

## Grenzen

Die Host-Ownershipprobe ersetzt den echten Zwei-Prozess-Client-Disconnect nicht.
Der finale Multiplayerlauf bleibt bis zu seinem Abschlussreport offen; dieser
Review erteilt ihm kein vorgezogenes PASS. Historische MP-FAILs, einschliesslich
der Clientdiagnostik von Retry 4, bleiben unveraendert erhalten. Keine allgemeine
Reconnect-, LAN/WAN-, Mehrrechner-, EXE-, Performance- oder Releaseabnahme.
