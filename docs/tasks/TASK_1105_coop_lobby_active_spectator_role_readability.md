# TASK_1105 - Coop Lobby Active and Spectator Role Readability

## Status: IMPLEMENTIERT

## Ziel / Problem
Die Produktlobby weist im Koop mit drei Peers zwei aktive Fireteams und einen Zuschauer korrekt zu. Die sichtbaren Texte zeigen diese Wahrheit jedoch als technische Peer-, Team- und Rollenwerte. Spieler sollen vor dem Missionsstart sofort erkennen, wer aktiv ist, wer zuschaut, welches Fireteam sie selbst besitzen und wie ein Zuschauer nachrueckt.

## Sinnhaftigkeit / Ursache
`MultiplayerSession` liefert die autoritativen Zuweisungen bereits konsistent. `MultiplayerLobbyScreen` formatiert sie noch als Debugausgabe mit Peer-IDs, `team_alpha`, Rollen-Codes und `ready=true`. Dadurch ist funktionierendes Mehrspieler-Verhalten in der eigentlichen Lobby schwer lesbar.

## Umfang
- Bestehende Peer- und Assignment-Labels als kompakte Einsatzrollen-Anzeige nutzen.
- Lokalen Peer mit `DU` markieren.
- Aktive Fireteams als `BLUE`, `GOLD` oder `RED` anzeigen.
- Zuschauer und Bereitschaft in menschlicher Sprache anzeigen.
- Koop-Zusammenfassung mit Anzahl aktiver Spieler und Zuschauer anzeigen.
- Vor Missionsstart erklaeren, dass Zuschauer bei einem freien Fireteam nachruecken.
- Read-only Lesbarkeits-Snapshot fuer Verifier bereitstellen.

## Nicht-Ziele
- Keine Aenderung an Peer-, Team-, Fireteam- oder Missionsautoritaet.
- Keine neue Lobby-Zuweisungslogik.
- Kein neues Panel und kein Umbau des Missions-HUD.
- Kein echter Drei-Fenster-Sichttest in diesem Task.

## Relevante Contracts / Dokumente
- `docs/ARCHITECTURE.md`
- `docs/dev/mission_multiplayer_team_ownership_contract.md`
- `docs/tasks/TASK_1104_product_lobby_multi_client_parallel_interaction_playtest.md`

## Akzeptanzkriterien
- Koop mit drei Peers zeigt zwei aktive Rollen und einen Zuschauer.
- Der lokale Peer ist als `DU` erkennbar.
- Der Text enthaelt keine `#<peer>`, internen Team-IDs oder `ready=true`-Ausgabe.
- Nach Premission-Disconnect wird der nachrueckende Peer als aktives `GOLD`-Fireteam gezeigt.
- Versus bleibt als eigener Modus mit aktiven und Zuschauerzahlen lesbar.
- Der UI-Snapshot ist ausdruecklich read-only und setzt keine Gameplay-Wahrheit.

## Betroffene Dateien
- `scripts/ui/multiplayer_lobby_screen.gd`
- `scenes/ui/multiplayer_lobby.tscn`
- `scripts/tests/task_1105_coop_lobby_active_spectator_role_readability.gd`
- Status-, Roadmap- und HTML-Arbeitsreport-Dokumentation

## Lokale Pruefung
- TASK_1105 Verifier
- TASK_1104 Drei-Peer-Produktlobby
- TASK_523 Team-Readability
- TASK_227 Lobby-Flow
- `git diff --check`

## Risiken / offene Punkte
Die automatischen Tests belegen Inhalt, Reihenfolge und Read-only-Grenze. Ein spaeterer echter Drei-Fenster-Sichttest muss noch Schriftgroesse, Panelhoehe und Full-HD-Lesbarkeit unter realen Spielern bewerten.

## Ergebnis
Die Produktlobby zeigt nun `EINSATZROLLEN` mit `DU`, Spielername, `HOST / BLUE`, `AKTIV / GOLD`, `ZUSCHAUER` sowie menschlicher Bereitschaft. Die Moduszeile fasst aktive und wartende Sitze zusammen; nur Koop mit wartendem Zuschauer erklaert das automatische Nachruecken. TASK_1105 ist 16/16, der echte TASK_1104-Drei-Peer-Lauf 31/31 gruen.
