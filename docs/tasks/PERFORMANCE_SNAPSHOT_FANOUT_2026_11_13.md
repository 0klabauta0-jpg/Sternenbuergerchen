# Snapshotfanout je Empfaengerteam — 13.11.2026

## Ziel / Ursache
Mainbasis5196cc08b: `_broadcast_tick_state` teilt bereits Projektionen je Team,
ruft den serialisierenden/komprimierenden Chunkpublisher jedoch einzeln je Peer.
Identische Teamdaten werden dadurch mehrfach gepackt. Nutzerauftrag Performance.

## Umfang / Nichtziele
Nur empfangsberechtigte Peers desselben Teams fuer den vorhandenen Publisher
gruppieren. Keine Aenderung an Sichtregeln, Payloads, Codec, Kompression,
RPC-Kanaelen, Tickfolge oder Reliable-Vitals. Keine dauerhaften neuen Caches.

## Vertraege / Dateien
PROJECT_BRIEF, ARCHITECTURE, CODEX_RULES, PERFORMANCE_REVIEW_2026_11_13,
docs/performance/performance_regression_gate.md; vorhandene sichtbare
Multiplayerprojektion und Runtimekontextpruefung.
`scripts/core/simulation_root.gd::_broadcast_tick_state`,
`scripts/tests/performance_snapshot_fanout_20261113.gd`.

## Akzeptanz / lokale Pruefung
- Drei echte lokale ENet-Empfaenger desselben Teams: genau ein Packaufruf,
  alle drei Peers erhalten dieselbe Teamprojektion.
- Zwei Teams: genau ein Packaufruf je Team, disjunkte Empfaengergruppen,
  eigene Daten erhalten; verborgene Gegner und deren Zielabsichten fehlen.
- Blockierter Peer: weder Chunks noch Reliable-Vitals; uebrige Empfaenger korrekt.
- Reliable-Vitals bleiben pro Peer erhalten, jeweils nur eigene sichtbare Daten.
- Ein neuer Tick nach Teamwechsel baut Gruppen frisch; keine Wiederverwendung.
- Verifier beobachtet produktiven Chunkpublisher und benutzt dessen `super` fuer
  echte Serialisierung/ZSTD/RPC sowie produktive Teamprojektion. Nur Rohzustand
  und vorhandene Host-Sichtfakten sind kontrollierte Fixtureinputs.
- ROT vor Produktfix, dann GRUEN; Root fuehrt Engines/Messungen seriell aus.

## Risiken / offene Punkte
ROT: `docs/qa/performance_review_20261113/snapshot_fanout/red_7890fabf614e4e369b1337109ad95769/`:
11 Checks, nur zwei erwartete Packaufrufbefunde; echte Zustellung,
Teamverschleierung, Blockierung und Reliable-Vitals bereits gruen.
Die erste Fixture ohne Authorityflag war ungueltig und wurde vorher korrigiert.
Produktfix vorbereitet: frische Empfaengergruppen pro Tick, Packer einmal je
Team; GRUEN und CPUvergleich werden vom Rootagent seriell ausgefuehrt.

Packaufrufzaehler belegen eingesparte Arbeit, keine native FPS-/GPUverbesserung.
Private Profile/Quellen unveraendert, Timeout, Marker, Fehler-/Leakpruefung.
Keine Commits oder Produktmutation vor aufgezeichnetem ROT.
