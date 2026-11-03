# Multiplayer Editor Map Transfer Contract

## Zweck
Editor-Maps werden im Multiplayer nur vor der Mission abgeglichen. Die laufenden Mission-Snapshots transportieren keine kompletten Mapdaten.

## Manifest
- `map_id`: sichere, normalisierte ID ohne Pfadbestandteile.
- `map_name`: sichtbarer Name fuer den Consent-Prompt.
- `format_version`: aktuell `1`.
- `map_hash`: SHA-256 des JSON-Texts.
- `map_size_bytes`: Payload-Groesse, V1 maximal 1 MiB.
- Optional: `scenario_file_path`, `scenario_hash`, `scenario_size_bytes`.

## Client-Check
- `known`: lokale Map mit gleicher ID und gleichem Hash vorhanden, kein Prompt.
- `missing`: keine lokale Map mit gleicher ID, Consent-Prompt.
- `hash_mismatch`: gleiche ID, anderer Hash, Consent-Prompt.
- `invalid_manifest`: kein Download, kein Missionsstart auf Clientseite.

## Consent
Download ist nie automatisch. Die Lobby zeigt Name, Hash/Groesse und Host-Hinweis. Erst `accept_download()` validiert Hash, Groesse und JSON-Struktur und schreibt nach `user://downloaded_maps/`.

## Sicherheitsgrenzen
- Kein Schreiben ausserhalb `user://...`.
- Keine Pfad-Traversal-IDs oder Backslashes.
- Keine Ueberschreibung lokaler `res://maps/...`-Editor-Dateien.
- Keine Asset-Pack-Synchronisation in diesem V1.
- Ablehnung laesst die Session im Lobby-State und markiert `can_start_client = false`.

## Runtime-Eingaenge und V1-Grenze
- Eingehende Host-Manifeste werden vor Normalisierung lokal validiert. Ein
  wiederholtes Angebot bewahrt die lokale Zustimmung oder Ablehnung; ein neues
  Angebot braucht eine neue Pruefung. Alte Dialogaktionen geben kein neues Angebot frei.
- Session-Snapshot und Missionsstart-RPC respektieren die lokale Kartenfreigabe.
  Die Lobby zeigt den aktuellen Consentzustand und laedt vor Szenenstart den
  bekannten lokalen Pfad oder den ausdruecklich akzeptierten Cachepfad.
- Wie in TASK228 bleibt der Netzwerk-Payloadtransport ausserhalb V1. Der
  Acceptbutton wartet auf Payload; `accept_pending_map_download(payload)` ist
  die vorhandene explizite Annahmegrenze. Dieser Fix fuehrt keinen Download-RPC ein.
