# Hexruntime-Fortsetzung — 13.11.2026

## Ziel / Ursache
Den bestehenden Hexsicht-/Belegungsplan auf dem tatsächlich fortgeschrittenen
Kandidaten weiterführen und den mobilen Reviewbericht berichtigen/ergänzen.
Die alte Reviewbasis8d0f9a597 enthält den Plan, nicht den inzwischen getrennt
integrierten AP0–AP8-Code. Keine doppelte Implementierung bereits fertiger APs.

## Ausgangsstand / Entscheidung
Read-only-AP0-Abgleich: nativer Kartenkandidat1b924b640f589c7ca5dabcc2f2da752f315d3c4b
enthält explizite Rampen97e00aba1, AP6–8-Abschluss9b85f73cc und fünfminütigen
Autosave. Historische begrenzte Evidenz: Selection16/0, Base30/0, Slice38/0,
CampaignContinue17/0+3/0. Foundation47fa17f51 ist dessen älterer Sourcezweig.
Keinen der divergierten Zweige pauschal mergen, keine fremden uncommitteten
Grafik-/QA-Dateien übernehmen. Eigener isolierter Kandidat vom gepinnten Parent.

## Umfang / Nichtziele
Begrenzte Fortsetzung des AP9-Netz-/Regressionsanteils ohne native Darstellung:
echter lokaler ENet-Transport an opt-in Hex-Ownern, zentrale Würfel-/Damage-
Authority, Seed-/RNGfortsetzung nach Save/Restore und private Gegnerdaten.
Neue Tests möglichst auf bestehendem kleinem Slice/Isolationsrunner aufbauen.
Bestätigte Fehler minimal mit ROT/GRÜN beheben. Bereits belegte unveränderte
AP0–8-Gates nicht pauschal wiederholen. HTML mobil/offline/JSON erneut prüfen.
Keine neue Rüstungs-/Schadensbalance oder D6-Regel; kein stiller Umbau der
Orbitalbegegnung, keine großflächige Aktivierung, A/B/C-Matrix, Mainintegration
oder EXE. Native/GPU-/Internet-/Latenz-/Paketverlustabnahme bleibt offen.

## Relevante Verträge
`docs/superpowers/plans/2026-11-11-hex-sight-occupancy.md`, zugehörige Spec/Task,
`docs/dev/hex_tactical_runtime_contract.md`, `docs/dev/explicit_hex_ramps_contract.md`,
AP7-Multiplayerkontext-/Projektionsverträge, Combat-Authority und HTML-Workbench.
Aktuelle AP678-Evidenz aus `docs/qa/ap678_bundle_20261112/` ist historische
Evidenz mit ihren jeweiligen Commitgrenzen, kein hier erfundener gemeinsamer Lauf.

## Akzeptanz / lokale Prüfung
- Reale Peer-/RPC-Strecke benutzt opt-in Hexzustand und produktiven Sender/Receiver.
- Clients committen/würfeln keinen zweiten Schaden; private Hexclaims/verborgene
  Gegnerdaten verlassen nicht den Host. Kontextfremde Daten werden abgewiesen.
- Save/Restore erhält den genauen nächsten Authoritywurf, nicht nur dessen Seed.
- Gültige tatsächliche Netzwerk-Movebefehle mit `fireteam_id: String` bleiben
  kanonisch exportier-/restaurierbar; falsche Typen und unbekannte Felder bleiben
  vor Mutation abgewiesen. Konkretes ROT aus dem neuen ENet-Fall: Der Codec
  meldet nach angenommenem `blue_ft`-Befehl `movement_save_unsupported_command_field`.
- Regressionen haben Assertions, Timeout, Marker, Exitcode, Fehler-/Leakprüfung,
  unveränderte Quellen/echte Profile und private Canary; keine Desktopinputs.
- HTML trennt aktuelle Ergebnisse von bisherigen26Reviewprüfungen und offenen Gates.

## Dateien / Risiken
Neue enge Verifier/Runner unter `scripts/tests/`, minimale owning Produktstellen
nur bei bestätigtem Fehler; eigene Task/QA/Doku. Reviewbericht und Evidenzindex
auf eigenem Berichtbranch. Candidate und Reviewfixes sind getrennte noch nicht
in Main integrierte Quellen; nicht als gemeinsam freigegebener Spielbuild ausgeben.
AP9 wird durch diese kleine Teilprüfung nicht insgesamt abgeschlossen.

## Abschluss dieses Pakets
Neuer echter ENet-Hexfall22/0, Movement-Save-Nachbar30/0, keine finalen
Script-/Runtimefehler oder Leaks; Quell-/Originalprofil-/Canaryguards grün.
Codecfix genau ein vorhandenes Stringfeld. Falscher Typ/unbekannte Felder weiter
negativ geprüft. Unabhängiger Review clean nach transparenter Korrektur des
neuen Nachbar-Wrappermarkers. Root verifiziert90 Quellenhashes und Loghash.
Rootrestore erhält sechs Folgewerte bei unverändertem Tick; keine generische
Live-Peer-Restore-/Rejoinbehauptung. Originale rote Reports bleiben erhalten.
Evidenz: `docs/qa/hex_enet_regression_20261113/README.md`.
