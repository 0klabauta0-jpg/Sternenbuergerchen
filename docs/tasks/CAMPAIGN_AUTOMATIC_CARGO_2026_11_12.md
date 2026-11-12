# Automatischer Frachttransfer

## Ziel und Ursache
Spieler sollen nicht jeden gekauften Gegenstand einzeln verschieben muessen: Ein erkennbarer Auftrag beim Frachtaufzug bzw. Schiff verlagert Fracht selbststaendig und nachvollziehbar zum Aufzug, zum Schiff oder zwischen Schiffen.

## Umfang / Nicht-Ziele
Autoritative, zeitlich fortschreitende Auftraege mit Start, Anzeige und Abschluss bzw. konkreter Blockade, unter Beachtung lokaler Erreichbarkeit, Kapazitaet, vorhandener Bestaende und doppelter Auftraege. Keine unmittelbare Scheinanimation als Nachweis eines Transportes; keine parallele Inventarwahrheit in UI oder Visual. Waehrend Uebertragungen muessen Wegflug und Speichern einen sicheren Zustand behalten.

## Contracts
`docs/dev/parallel_location_operations_contract.md`, `docs/dev/player_roster_save_contract.md`, bestehender Inventar- und Frachtvertrag; Nutzerkorrektur 12.11.

## Akzeptanz und Pruefung
Alles zwischen Aufzug und lokalem Schiff in beide Richtungen und zwischen zugaenglichen Schiffen; Fortschritt ohne wiederholte Eingaben, volle Zielcontainer, verschwindende Quelle, gesperrte Schiffe, Wiederholung und Save/Continue sauber behandeln. Automatik ueber Schiff-/Frachtansicht auffindbar. Simulation und UI gezielt pruefen; Grenzen echter Frachtaufzug-/Traganimation offenlegen.

## Betroffene Dateien und Risiken
Supply-/Inventarowner, Simulation/Runtime-Adapter, Checkpoint und Fracht-/Schiffsbedienung. Bisheriger Einkauf legt laut bestehendem Pfad Waren direkt im Schiff ab; der angezeigte Aufzug kann visuelles Feedback sein. Eine eigene autoritative Aufzugskapazitaet und Transportkette duerfen nicht nur vorgetaeuscht werden.

## Stand 12.11.
Neue Kampagnenkaeufe auf Polisa gehen in den persistierten Aufzugscontainer; bestehende Schiffsbestaende und alte Kaufbelege bleiben unveraendert. Ein Auftrag bucht zeitlich einzelne Gegenstaende zwischen zugaenglichen Containern ueber den Supply-Owner. Es kann jeweils ein Auftrag laufen; aktive oder blockierte Auftraege sperren betroffene Schiffsabfluege und sichere Checkpoints. Abbruch behaelt bereits transportierte Ware. Bei Blockade ist Abbruch und erneuter Start erforderlich; eine physische Traeger-/Aufzugsbewegung ist nicht implementiert. `automatic_cargo_transfer_verifier.gd` und `automatic_cargo_ui_verifier.gd` bestanden; `polisa_real_roundtrip_verifier.gd` prueft Kauf, Aufzug, Transfer, Abflug-/Speichersperre und Heimkehr in einer Kampagnenszene.
