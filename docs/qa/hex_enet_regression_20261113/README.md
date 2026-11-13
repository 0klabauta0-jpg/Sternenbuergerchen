# Begrenzte Hex-ENet-Regression — 13.11.2026

Scope: `docs/tasks/HEX_RUNTIME_FOLLOWUP_2026_11_13.md`, Basis `1b924b640`.
Zwei echte lokale ENet-Peers in einem headless Prozess, sechs Hexfelder,
produktiver Rootpublisher/RPCreceiver und Driver-Sichtgetter. Keine Kartenaktivierung,
neue Kampfregeln, Mainintegration, EXE oder vollständige AP9-Abnahme.

## Bestätigter Codecfehler / gewünschter Vertrag

Der tatsächlich zugelassene Remote-Move enthält `fireteam_id: "blue_ft"`.
Rootcheckpointexport lehnt ihn mit `movement_save_unsupported_command_field` ab;
die Bewegungsabsichten-Stringallowlist kennt dieses vorhandene Commandfeld nicht.
ROT: Lauf `d6ccce19eecb4513b91e6351facc6eab`, vorherige Diagnoseläufe bleiben erhalten.
Erlaubte Korrektur: ausschließlich `fireteam_id` als String roundtrippen.
Falsche Typen und unbekannte Felder bleiben ungültig. Kein stilles Entfernen.

Sicht-/Healthfehler dieser ersten Fixture waren Vorbedingungen: drei Hex Abstand
überschreiten die vorhandene 180er-Reichweite (64 pro Hex); der Capabilityactor
benötigt wie TestUnit sowohl Snapshot- als auch Reliable-Vitalanwendung.
Das sind keine behaupteten Produktfehler und keine neuen Kampfregeln.

## Ausführung und Grenzen

`python scripts/tests/run_hex_enet_regression.py --execute`.
Ohne `--execute` nur Plananzeige. Eindeutiges frisches Privatprojekt/-profil,
Sourcehashes, echtes Profil, Canary, Zeitgrenze, Fehler-/Leakprüfung.
Jeder Lauf besitzt eigenes Verzeichnis mit unveränderten Rohlogs und JSONreport.
Keine Desktopinputs oder Darstellung, kein LAN/Internet/Paketverlustnachweis.

## Ergebnis

- Finale ENetprobe: **22/0**, Exit0, `3ac330df39b84c59bb23f3d6e07937c1/report.json`.
  Reale Loopbackverbindung/Handshake, produktive Command-/Result-/Chunk-/Vital-RPCs,
  zugelassene Hexbewegung, falscher Kontext/fremdes Team, echte Sichtwechsel.
  Eine beobachtende Rootsubklasse sammelt empfangene RPCbytes vor Normalisierung
  und delegiert unverändert an den produktiven Receiver. Verborgene ID-/Zielreferenzen,
  RNG und Claims fehlen auch im tatsächlich empfangenen Envelope; sichtbarer Gegner
  besitzt nur Displaydaten. NPCs sind ausdrücklich Capabilityactors, keine volle Mission.
- Rootcheckpoint nach dem echten Remotecommand erhält dessen `fireteam_id` und
  nach fortgeschrittenem RNGzustand exakt sechs zukünftige Würfe. Restore erfolgt
  am identischen Tick nach reinen RNGreads, kein Rewind einer laufenden Peerpartie.
  Queued Hostdamage verbraucht exakt einen Wurf; Clientqueue/-tick erzeugen weder
  Schaden noch RNGfortschritt. Health kommt über reale Snapshot-/Vital-RPCs an.
- Engster unveränderter Nachbar: `hex_movement_save_state_verifier.gd`, **30/0**, Exit0,
  `bf01721d568b44f594791a39c2f094ca/reviewed_result.json`. Der erste neue Wrapper
  erwartete irrtümlich einen nicht vorhandenen PASSmarker und meldete trotz30/0
  rot. Originalreport/-log bleiben erhalten; Zusatzbericht prüft den tatsächlichen
  strikten Summarymarker und dieselben Guards. Keine Gameplaywiederholung.
- Finale Logs ohne Script-/Enginefehler oder Leaks; Source-, Originalprofil- und
  Canaryguards grün. Erwartete `peer_team_mismatch`-Warnung gehört zur Negativprobe.
  `git diff --check` ohne Befund. Keine weiteren AP0–8-Gates wiederholt.

Ältere rote/diagnostische Läufe bleiben in eigenen Unterordnern;20/0-Zwischenlauf
`d830f55f907749f2a581d0189cd7f0ec` enthält noch keinen Raw-Envelopebeleg.
Produktänderung genau eine Stringallowlistenerweiterung in
`scripts/core/hex_movement_command_runtime.gd`. Kein Commit/Push durch Teilagenten.
