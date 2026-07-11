# TASK_1119 - Connected First Contact Three-Peer Product Visual Playtest

## Ziel / Problem
TASK_1118 trennt BLUE- und GOLD-Kontaktfeedback in der HUD-Leseschicht. Jetzt muss der echte Produktpfad von drei Multiplayer-Lobbys bis zur laufenden Mission beweisen, dass Host, aktiver Client und Spectator jeweils die richtige lokale Perspektive erhalten und dass echte Host-Combatdaten darin lesbar bleiben.

## Sinnhaftigkeit / Ursache
Die bisherigen Belege pruefen entweder die Produkt-Lobby mit parallelen Interactions oder den Combat-Handoff in direkt erzeugten Missionsinstanzen. Damit ist noch nicht bewiesen, dass die Lobby-Zuweisung den lokalen Mission-Fokus setzt und die neue Contact-Fire-Zeile im gestarteten Produktfenster ankommt.

## Umfang
- Echte Produkt-Lobby mit Host, aktivem Client und Spectator starten.
- Lokalen Mission-Fokus aus den autoritativen Peer-Fireteam-Zuweisungen ableiten.
- BLUE und GOLD nach Missionstart als getrennte lokale Perspektiven pruefen.
- Hostautoritative Kontakte und First-Fire-Ereignisse ueber den normalen Snapshot transportieren.
- Selected Fireteam und Mission Control pro aktivem Peer auf Konsistenz pruefen.
- Je aktiver Perspektive einen Full-HD-Sichtbeleg erzeugen.

## Nicht-Ziele
- Kein neuer RPC und kein neues Snapshotformat.
- Keine Replikation lokaler UI-Auswahl.
- Kein Combat-, ROE- oder Lobby-Rewrite.
- Keine Spectator-Kommandorechte.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_1104_product_lobby_multi_client_parallel_interaction_playtest.md`
- `docs/tasks/TASK_1117_connected_post_deboard_first_contact_combat_handoff.md`
- `docs/tasks/TASK_1118_connected_first_contact_hud_perspective_visual_evidence.md`
- `docs/ARCHITECTURE.md`

## Akzeptanzkriterien
- Host und aktiver Client starten aus echten Produkt-Lobbys mit unterschiedlichen zugewiesenen Fireteams.
- Die lokale Mission fokussiert automatisch das eigene Fireteam; der Spectator erhaelt keine aktive Fireteam-Auswahl.
- Nur der Host fuehrt Combat aus; Clients erzeugen keine Commands oder Effects.
- Beide aktiven Peers lesen einen eigenen Contact-Fire-Datensatz mit passender Fireteam-ID.
- Selected Fireteam und Mission Control zeigen auf jedem aktiven Peer dieselbe Perspektive.
- Zwei Full-HD-PNGs belegen BLUE und GOLD in getrennten Renderer-Prozessen.
- Produkt-Lobby-, Combat-Handoff- und Performance-Regressionen bleiben gruen.

## Betroffene Dateien
- `scripts/ui/multiplayer_lobby_screen.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_1119_connected_first_contact_three_peer_product_visual_playtest.gd`
- Status-, Roadmap- und HTML-Berichtsdokumentation

## Lokale Pruefung
- TASK_1119 headless und Real-Window.
- TASK_1104 Produkt-Lobby.
- TASK_1117 Combat-Handoff.
- TASK_1118 HUD-Perspektive.
- TASK_222 Performance-Gate.
- `git diff --check`.

## Risiken / offene Punkte
Ein automatisierter Drei-Peer-Lauf ersetzt keinen echten Zwei-Menschen-Usability-Test. Er soll aber beweisen, dass jedes Produktfenster ohne manuellen Korrekturklick im richtigen Fireteam startet und dieselbe hostautoritative Combatwahrheit passend zu seiner lokalen Perspektive liest.

## Ergebnis
- Produktmissionen initialisieren die lokale Auswahl aus der autoritativen Peer-Fireteam-Zuweisung; Spectators starten ohne Command-Fokus.
- Eine dreisekuendige hostautoritative Startup-Grace verhindert Combat, bevor die Produktmission sichtbar bereit ist.
- Standardangriffe priorisieren nach einem Schuss zunaechst andere Fireteams, damit parallele Teams nicht durch stabile Listenreihenfolge verhungern.
- Snapshot-Normalisierung transportiert Fireteam- und Outcome-Felder. Fire-Events bleiben 72 Ticks, aber hoechstens acht Eintraege erhalten.
- BLUE und GOLD zeigen im echten Produktlauf jeweils ihre eigene Contact-Fire-Zeile in Selected Fireteam, Mission Control und Event Log.

## Verifikation
- TASK_1119 headless: 21/21.
- TASK_1119 Real-Window: 22/22 je BLUE und GOLD.
- TASK_1104: 31/31, TASK_1117: 15/15, TASK_1118: 13/13.
- TASK_168: 20/20, TASK_466: 22/22, TASK_467: 14/14, TASK_222: 82/82.
- Full-HD-Belege: `tmp/task_1119_product_first_contact_blue.png` und `tmp/task_1119_product_first_contact_gold.png`.
