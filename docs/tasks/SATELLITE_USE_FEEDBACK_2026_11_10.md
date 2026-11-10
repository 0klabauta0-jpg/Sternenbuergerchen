# Satellitendaten: Bedienweg und sichtbarer Abschluss — 10.11.2026

## Problem / Ursache
Nutzer erreicht blockiertes Satellitenfeld nicht; Nachbarfeld/Rechtsklick/GO
erscheint wirkungslos. Unklar, ob Aufnahme läuft, abgeschlossen oder blockiert.
Vorhandene Tests rufen Use direkt auf und belegen keinen echten Mausweg.
## Umfang / Nichtziele
Realen Rechtsklick einschließlich Loslassen über Viewport nachstellen,
begehbare Nachbarfelder und gültige Reichweite prüfen. Aktion und Fortschritt
sichtbar; Abschluss sagt Daten gesichert und Heimtransport/Upload. Keine
Inventarattrappe, kein Betreten von Wrackkollision, kein automatischer Erfolg.
Bestehende Runtimegates/GO/Dauer/Heimupload bleiben verbindlich.
## Quellen / Dateien
mission_interaction_point_contract, campaign_stationary_use_verifier,
MissionContextCursor, MissionTacticalSandboxController, Szenario satellite_recovery.
## Akzeptanz / Prüfung
Echter Maus-Input von erreichbarer Nachbarposition erzeugt Use; GO führt nach
realer Dauer zum selben Runtimeabschluss. Out-of-range wird als Annäherung mit
klarer Folgeaktion angezeigt. Sichtbare Zustände vorbereitet/läuft/gesichert
und Sperrgrund. Gezielte Eingabe-/Interaktions- und Kampagnenregression.
## Risiken / offen
Bisheriger Bericht kein Beweis für aktuellen Benutzerspielstand; tatsächlicher
Zustand wird aus Missionsruntime gelesen. Aktueller Arbeitsbranch enthält den
parallel beauftragten Flugdeck-/Pilotumbau; beide Änderungen getrennt prüfen.

## Abschluss / Prüfbeleg
Quellstand umgesetzt und gezielt geprüft. Ergebnisse, native Bilder und
Baselinegrenzen: docs/qa/flugdeck_basis_data_20261110/README.md.
Kein Mainmerge/EXE-Export in diesem Folgeabschluss.
