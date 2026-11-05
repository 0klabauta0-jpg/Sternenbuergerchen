# Aktuelle GM01 im Multiplayer anbieten

## Ziel / Ursache
Der lokale Multiplayerpass entdeckt eine alte 1-MiB-Grenze: Die aktive,
unveraenderte GM01 hat 2.425.578 Bytes und ihr Manifest wird als
`map_size_invalid` verworfen. Die vorhandene Standardkarte muss im normalen
Host/Join-Pfad als gleiche lokale Karte erkannt werden.

## Umfang / Nicht-Ziele
Manifest und Payloadvalidierung erhalten dieselbe begrenzte 4-MiB-Obergrenze.
Hash, exakte Groesse, sichere IDs, JSONpruefung, Consent und privater Cache
bleiben erhalten. Kein automatischer Download, kein neuer Payload-RPC,
keine Veraenderung der GM01 oder Gameplayfakten.

## Dokumente / Dateien
AGENTS, Architektur, Haupttask und multiplayer_editor_map_transfer_contract;
scripts/multiplayer/multiplayer_map_manifest.gd, gezielter neuer Verifier.

## Akzeptanz / lokale Pruefung
Vorher RED an der echten GM01; danach gueltiges Manifest, `known` bei genau
gleichem lokalem Hash. Neues Maximum plus ein Byte bleibt ungueltig, falsche
Hashes und unbekannte Karten behalten ihre Consentgrenze. Bestehender
TASK228 sowie Session-/Lobbyconsentgates und reale zwei Sourceprozesse.

## Risiken / offene Punkte
Die maximal akzeptierte Payload waechst auf 4 MiB. Vorhandene Pruefungen und
der fehlende Netzwerkpayloadtransport bleiben unveraendert. Beide Peers
benoetigen weiter gleiche Quellen; Versionshandshake ist separat offen.
