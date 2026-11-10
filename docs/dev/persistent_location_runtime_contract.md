# Langlebige Ortskarten und unabhaengige Reisen

Zielrevision 10.11.2026, aus dem Kampagnen-Playtest. Implementierungsnachweise
stehen im zugeordneten QA-Bericht; dieser Vertrag allein ist kein Fertignachweis.

## Identitaet und Besitz

- location_id bezeichnet einen gemeinsamen Ort (homebase, satellite_crash,
  trade_outpost). Pro laufendem Spiel gibt es genau eine Instanz je Ort.
- instance_id benennt diese Laufzeitinstanz, getrennt von job_id, craft_id,
  fireteam_id und unit_id. Derselbe Ort wird fuer zwei Besucher nicht geklont.
- SimulationRoot und seine gebundenen Runtimekomponenten behalten Mutations-
  autoritaet. Ortsregistry ist nur Lookup, keine versteckte Gameplayverwaltung.
- Jobabschluss, Sichtwechsel und Heimflug eines Besuchers loeschen weder andere
  Besucher noch lokale Ressourcen/Interaktionen. Inventar bleibt beim gemeinsamen
  Supply-/Containerowner; nicht pro Ansicht duplizieren.

## Reise und Ansicht

Jedes echte Schiff besitzt einen eigenen Reiseowner mit dem bestehenden
Orbit-/Quantum-/Anflugvertrag. Eine Fassade indiziert diese Owner nach craft_id;
sie erfindet keine zweite Simulation. Bestehende Ein-Schiff-Snapshots werden als
Fokusprojektion erhalten, zusaetzlich werden alle Reisen lesbar angeboten.
Zeitfortschritt erreicht alle laufenden Owner, unabhaengig vom sichtbaren Schiff.

Die Ansicht waehlt einen Ort oder ein Schiff aus. Auswahl ist weder Abflug noch
Ortswechsel. Versteckte Missionen behalten Physics-/Runtimefortschritt, aber
verlieren Kameraeingabe, HUD und Viewportrendering. UI-Polling versteckter Orte
wird deaktiviert. Ein getrennter Trupp kann am anderen Ort weiterarbeiten.

Belegte Landezonen koennen ein Schiff warten lassen; andere Reisen und Orte
bleiben unabhaengig. Ein fehlgeschlagener Rueckflug erhaelt die lokale Instanz.

## Lebenszyklus

| Zustand | Runtime | Sicht / Eingabe |
|---|---|---|
| Heimatbasis | bestehender Basisowner bleibt bestehen | nur sichtbare Erkundung rendert |
| Ort A fokussiert | normale laufende lokale Simulation | Kamera und HUD A |
| Ort B im Hintergrund | gleicher lokaler State, laufende Auftraege | keine Kameraeingabe / kein HUD B |
| Schiff im Quantum / Orbit | eigener Reiseowner | Sternkarte projiziert alle, bedient Fokus |
| Ort ohne Besucher | endlicher Ortszustand erhalten | Projektion darf entladen werden |

Ein spaeteres Entladen der Darstellung setzt keine grossen willkuerlichen
delta-Nachholschritte fuer Combat/Navigation ein. Erster begrenzter Slice darf
Missionnodes erhalten und nur Rendering abschalten; Speicher und Ticklast sind
bei 1/2/3 Orten zu messen, bevor mehr Instanzen freigegeben werden.

## Checkpoints und Netzwerkgrenze

Bestehende sichere Basischeckpoints bleiben gueltig. Bis ein vollstaendiger
Weltcheckpoint fuer alle Orte/Reisen/Container existiert, ist Speichern bei
weiteren laufenden Ortsbesuchen sichtbar gesperrt. Ein Fokuswechsel zum
heimgekehrten Schiff macht fremde Reisen nicht zu grounded und darf keinen
scheinbar vollstaendigen Checkpoint erzeugen. Persoenliche Saves nicht loeschen.

Multiplayer bleibt ein Folgeauftrag. Bereits jetzt bleiben IDs, autorisierte
Commands, gemeinsame endliche Quellen und Idempotenz erhalten. Kein zweiter
Materialvorrat je Spieler/Trupp und keine neue Netzwerkschnittstelle im UI.

## Abnahme

Zwei echte Schiffe/Trupps an A/B: Wechsel A-B-A erhaelt Positionen, Interaktion,
Belegung und Fortschritt. Ein Schiff kehrt heim, das andere bleibt am Ort.
Zweite Besucher sehen denselben Restbestand. Zwei-Personen-Startkampagne bleibt
unveraendert; Mehrtrupppruefung verwendet ein isoliertes groesseres Team.
