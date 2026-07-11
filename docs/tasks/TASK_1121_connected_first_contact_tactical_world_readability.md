# TASK_1121 - Connected First Contact Tactical World Readability

## Ziel / Problem
Im echten TASK-1119-Produktcapture sind lokale Fireteam- und Contact-Daten korrekt, die taktische Welt bleibt jedoch hinter dem Multiplayer-Lobby-Hintergrund verborgen. Der GOLD-Capture kombiniert ausserdem die sichtbare Host-Mission mit der GOLD-UI statt Welt und HUD desselben Peers zu zeigen.

## Sinnhaftigkeit / Ursache
`_set_lobby_panel_visible(false)` blendet nur das Lobby-Panel aus. Der vollflaechige `Background` und `BackgroundShade` bleiben als Control-Layer sichtbar und verdecken die Mission. Der Capture-Helfer setzt Missionssichtbarkeit fest auf `index == 0`, unabhaengig von der aufgenommenen Perspektive.

## Umfang
- Lobby-Panel, Hintergrund und Shade als gemeinsame Lobby-Chrome ein-/ausblenden.
- Beim Missionsstart muss die lokale Mission frei sichtbar sein; bei Disconnect, Mission-Ende oder Rueckkehr erscheint die Lobby wieder vollstaendig.
- Real-Window-Capture zeigt Mission und Tactical UI desselben Ziel-Peers.
- Bestehende Primary-3D-Kontakt-, Fire- und FOW-Visuals bleiben die einzige taktische Weltdarstellung.

## Nicht-Ziele
- Keine neue Kontakt-, Combat- oder Multiplayer-Wahrheit.
- Kein weiteres Fire-Visual-Polish-Flag und kein paralleles Overlay-System.
- Kein Umbau des Missionslayouts oder der Lobbybedienung.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_1119_connected_first_contact_three_peer_product_visual_playtest.md`
- `docs/tasks/TASK_1120_connected_first_contact_event_log_dedupe_hud_declutter.md`
- `docs/ARCHITECTURE.md`
- `scripts/mission/mission_primary_view_bridge.gd`

## Akzeptanzkriterien
- Lobby-Panel, Background und Shade sind in der Lobby sichtbar und waehrend einer Mission verborgen.
- Rueckkehrpfade stellen alle drei Lobby-Layer wieder her.
- BLUE- und GOLD-Capture zeigen jeweils Ziel-Mission und Ziel-HUD desselben Peers.
- Die Mission ist im sichtbaren Bild nicht nur ein atmosphaerischer Lobby-Hangar.
- Keine Commands, Effects, RPCs oder Gameplay-State-Mutationen entstehen.
- Drei-Peer-Produktlauf und Performance-Gate bleiben gruen.

## Betroffene Dateien
- `scripts/ui/multiplayer_lobby_screen.gd`
- `scripts/tests/task_1119_connected_first_contact_three_peer_product_visual_playtest.gd`
- `scripts/tests/task_1121_connected_first_contact_tactical_world_readability.gd`
- Status-, Roadmap- und HTML-Berichtsdokumentation

## Lokale Pruefung
- TASK_1121 headless.
- TASK_1119 headless und Real-Window je BLUE/GOLD.
- Lobby-/Multiplayer-Regressionsverifier.
- TASK_222 Performance-Gate.
- `git diff --check`.

## Risiken / offene Punkte
Die Lobby-Chrome darf beim Mission-Ende nicht verborgen bleiben. Der Capture muss alle nicht gewaehlten Missions- und UI-Layer ausblenden, ohne deren Netzwerkprozesse zu stoppen.

## Ergebnis / Verifikation
- Der Lobby-Hintergrund und sein Shade folgen jetzt derselben Sichtbarkeitsgrenze wie das Panel. Missionsstart blendet alle drei aus; Disconnect, Mission-Ende und Rueckkehr stellen alle drei wieder her.
- Der Drei-Peer-Capture zeigt nur die Mission des Ziel-Peers und dessen Tactical UI. Netzwerkprozesse der anderen Peers laufen weiter, ihre Welten werden lediglich nicht gerendert.
- Neue Full-HD-Belege zeigen BLUE und GOLD auf der echten 3D-Taktikkarte statt vor dem Hangarbild: `tmp/task_1119_product_first_contact_blue.png` und `tmp/task_1119_product_first_contact_gold.png`.
- TASK_1121: 7/7. TASK_1119: 21/21 headless und 22/22 je Real-Window-Perspektive. TASK_1104: 31/31. TASK_1120: 11/11. TASK_222: 82/82.
- Sichtbare Folgearbeit: Compatibility-Rendering ueberstrahlt helle Stationsassets, der Kamerarahmen enthaelt viel leere Flaeche und mehrere Weltlabels ballen sich am oberen Kontaktpunkt. Im BLUE-Event-Log kann die starre Fuenf-Sekunden-Bucket-Grenze zwei zeitlich nahe Contact-Gruppen erzeugen.
