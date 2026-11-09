# Kampagneneinfuehrung — technische Pruefung vom 09.11.2026

Freigegebener Umfang: eigener Kampagnenstart mit genau zwei NPCs insgesamt (Pilot und einsatzfaehiger Leader), kleine Basis, drei aufeinander aufbauende Tutorial-Etappen, getrenntes Skirmish-Team und Basis-Checkpoints. Vertrag: `docs/dev/campaign_introduction_contract.md`.

## Bestaetigter Ablauf

Der echte Kampagnen-Zweiausflug besteht **77/77**, Exit 0: Basisvorbereitung, Satellitenflug, Landung, echtes Move/GO, zeitgesteuertes Use, Satellitenauftrag und Heimkehr; danach Handelsflug, echtes Haendler-Use, Kauf/Betankung und Heimkehr. Nach beiden Ausfluegen wird der Basis-Checkpoint geladen und ein neuer echter Flow daraus instanziiert. Fortschritt, die zwei Identitaeten, Pilot, Schiff, Fuel, Credits und Inventar bleiben erhalten. Die bestehende nichtleere `local_player`-Teamdatei bleibt bytegleich.

Log: [campaign-loop-fourth.log](raw/campaign-loop-fourth.log). Mission, Bewegung, Use und Fluege laufen bei `Engine.time_scale=1`. Nur die vorbereitende Boarding-Fixture wird ueber den vorhandenen Testhelper vorgezogen. Kein gefaelschter Sieg oder gesetzter Tutorial-Abschluss.

## Fokussierte Pruefungen

15 Gates mit Exit 0 und bestandenen Assertions: Flowstart 11, Retry-Grenze 7, Profil-Handoff 3, Singleton-Formation 4, Basiskarte 9, Domainzustand/Speichern, Menue 29, Tutorial 31, Auftrag/Ort 33, Versorgung 41, Abflug 15, Autoritaetsgrenze, Hexbewegung 25, Vorbereitung/Fortsetzen 10 sowie alter Formationsverifier 7. Rohdaten und einzelne Logs: [final-matrix.json](raw/final-matrix.json).

Der bisherige Skirmish-Zweiausflug besteht zusaetzlich **60/60**, Exit 0: [skirmish-loop-final.log](raw/skirmish-loop-final.log).

**Begrenzung:** Der alte `formation_offsets_verifier.gd` meldet nach 7/0 bestandenen Assertions ObjectDB-/Resource-Leaks beim Beenden. Das tritt identisch auf unveraendertem Main `6bf468a4c` auf; kein sauberer Teardown-PASS daraus abgeleitet. [Baseline](raw/baseline-formation_offsets_verifier.log).

Die Kartenpruefung bestaetigt eine 22x24-Hexbasis mit einem Raum, einem Pad und erreichbaren Terminals. Menue-/Roster-/Teambibliothekspruefungen und Hilfekatalogschema wurden zusaetzlich durch die jeweiligen Implementierer ausgefuehrt; deren genaue Ergebnisse sind in [menu-report.md](raw/menu-report.md) beschrieben. Ein alter Settings-Verifier erwartet einen frueheren Nodepfad; ein grosser Layout-Verifier wurde abgebrochen. Beide zaehlen nicht als bestandene neue Gates.

## Gefundene und behobene Fehler

- Der direkte Kampagnen-Handoff las zuerst das Ersatzprofil der umgangenen FOB-Anzeige. Missionen erhalten jetzt das echte autoritative Kampagnenprofil; gezielte RED/GREEN-Pruefung.
- Ein sehr fruehes GO konnte vor dem autoritativen Absetzen angenommen und von anschliessender Landungssicherung geloescht werden. GO wartet jetzt auf diese Bereitschaft; der echte Kampagnenlauf prueft den transienten Sperrgrund. Der Test wartet ebenfalls auf tatsaechlich angewendete Deploy-Effekte.
- Die Workbench-Formation wies dem einzelnen Leader einen 146 Einheiten versetzten Slot zu, ausserhalb des Interaktionsradius 96. Einpersonen-Trupps nutzen jetzt den bestehenden zentrierten Singleton-Slot; mehrkoepfige Formationen behalten ihren bisherigen Pfad. [RED](raw/single-formation-red.log), [GREEN](raw/single-formation-green.log).
- Auftrag-Retry waehrend eines Ausflugs konnte die Rueckflugbindung loeschen. Wiederannahme ist erst zuhause ohne laufenden Einsatz/Transit erlaubt; 7/0 gezielte Grenzpruefungen.
- Checkpointvalidierung weist unmoegliche Fortschrittsfakten, unbrauchbare Rollenpaare und widerspruechliche Belege vor Mutation zurueck.
- Auch eine legitime unfertige Vorbereitung bleibt erhalten: leere Zusatzgruppe, verschobener Leader, geaenderte Ausruestung und bewusst geloeste Pilotenzuweisung. Der Checkpoint liest den bestehenden Homebase-Direct-Konfigurationspfad und stellt die gespeicherte Truppzuordnung wieder her. Zehn echte UI-/Fortsetzen-Pruefungen bestehen: [preparation](raw/premerge3-campaign_preparation_continue_test.log).

Abschliessendes unabhaengiges Sourcereview: [final-review.md](raw/final-review.md), keine verbleibenden konkreten Befunde. Native Bedienung und Lernerfolg wurden damit nicht abgenommen.

## Selbst testen

1. Im Hauptmenue `Kampagne` und `Neue Kampagne` waehlen. Es gibt genau zwei NPCs und ein Schiff. Die kleine Basis und die Hilfen kennenlernen.
2. Satellitenauftrag im Smart Mobile annehmen und auf der Karte zeigen, Boarding abschliessen, abfliegen. Landen/absetzen, Leader bewegen und GO bestaetigen, Satelliten-Use und Rueckkehr ausfuehren.
3. Nach der Heimkehr `Fortsetzen` pruefen. Danach zum Handelsposten, Haendler-Use, Kaufen/Tanken und Heimkehr. Die Einfuehrung ist dann abgeschlossen.
4. Das im Hauptmenue bearbeitete Team unter `Skirmish` pruefen. Multiplayer behaelt seinen eigenen Host-/Join- und Karten-Handoff; kein neuer nativer Multiplayer-Lauf Bestandteil dieser Abnahme.

Speichern erfolgt an sicheren Basis-Meilensteinen. Ein unterbrochener Ausflug faellt beim Fortsetzen auf den letzten Basisstand zurueck; keine Wiederaufnahme mitten im Gefecht. Tests liefen ausschliesslich headless mit privaten Profilen und niedriger Prioritaet, ohne Vordergrundfenster oder Fokuswechsel. Kein Push.

Lokale Mainintegration, frischer Main-Lauf und zugehoeriger EXE-Export werden nach Abschluss separat belegt.
