# Mondbasis, Quantum-Reise und UI-Klarheit — 09.11.2026

Freigegebener Umfang: [Orbitauftrag](../../tasks/ORBIT_QUANTUM_TRAVEL_2026_11_09.md)
und [UI-Ergaenzungen](../../tasks/UI_CLARITY_2026_11_09.md). Eigener lokaler
Branch `task/orbit-quantum-travel-20261109`, Basis Main `b548b5556`.

## Ergebnis und Besitz

Mondbasis -> Mondorbit -> kurzer abbrechbarer Quantum -> Planetenorbit ->
bewusster Ortsanflug. Abbruch behaelt die erreichte Position; Neustart beginnt
dort. Erst der sichtbare Anflug instanziiert die unveraenderten Satelliten-/
Handelskarten und startet den Missionstimer. Rueckflug erreicht den Planeten-
orbit; erst Mondorbit und Landung zaehlen als Heimkehr/Basischeckpoint.

Reisephase/Position liegen im SimulationRoot-gebundenen Reiseowner. Bestehende
Owner behalten Payload, Pilot, Fuel, Auftrag, Abschluss und Versorgung.
Kamera/Vorschau/HUD lesen Snapshots. Keine zweite Gameplaywahrheit und kein
neuer Raumkampf. Drei inaktive Orbitbereiche sind Zukunftsmarkierungen.

Schiffsvorschauen zeigen das reale Pad oder den aktuellen Weltraumzustand.
Abflug meldet den naechsten noetigen Schritt dauerhaft sichtbar; Hinweise
umgehen die Aktionen. Mobilgeraet und Schaltflaechen sind kompakter. Der
Charakterbogen trennt Startrolle, aktuelle Aufgabe und berechnete Eignung;
Details sind aufklappbar. Deutsche Anzeigeaenderungen belassen IDs, Werte,
Profile, Scores, Modelle und freie eigene Texte bei ihren bisherigen Ownern.

## Technische Belege

| Pruefung | Ergebnis | Beleg |
| --- | --- | --- |
| Echte Kampagne, zwei Ausfluege/Heimkehren und beide Checkpoint-Neuladungen | 124/124, Exit0/errors0 | [Log](raw/final-campaign-loop/campaign_intro_loop_smoke.log) |
| Freier Einzelspieler, zwei Ortsreisen, Landung, echtes Move/GO/Use, Handel und Heimkehr | 104/104, Exit0/errors0 | [Log](raw/final-skirmish-loop/playtest_20261109_singleplayer_loop_smoke.log) |
| Finale Domain-/Flow-/Sicherheits-/UI-/Kompatibilitaetsmatrix | 16 Prozesse, alle Exit0/errors0 | [Matrix](raw/final-matrix/results.json) |
| Finale Domain-/Hilfe-/Charakter-/Aircraft-/Service-Regressionen | 6 Prozesse, alle Exit0/errors0 | [Matrix](raw/final-domain-copy/results.json) |
| Deutscher Charakterbogen, Eignung und editierbarer Teameditor | 7 Gates, 1494 bestandene Assertions/0 Fehler | [Matrix](raw/character_german_final/results.json) |
| Eingefrorener Abschlussstand: Domain, Kamera, Sternkarten-UI, Charakter, realer Einstieg und Abflugbereitschaft | 6 Prozesse, alle Exit0/errors0 | [Matrix](raw/frozen-final/results.json) |

Die Kamera besteht 18/18 reale Viewport-Eingabepruefungen; die neue
Sternkartenansicht 91/91 inklusive 1280x720, 1920x1080 und eingebettet800x650.
Mausradzoom0,55–3,5 behaelt den Kartenpunkt unter dem Cursor; mittlere/rechte
Maustaste verschiebt. Himmelskoerper und Beschriftungen bleiben korrekt
klickbar. Gesamtansicht funktioniert auch bei absichtlich darueber gepannten
Zukunftslabels. Kameraaenderungen lassen Owner-Snapshots unveraendert.
Stock-Biografietext wird anhand bekannter Vorlagen nur in der Darstellung
eingedeutscht; unbekannter eigener Text inklusive Leerraum bleibt erhalten
([Zusatzpruefung](raw/character_biography_green/)).

Die echten Loops laufen bei `Engine.time_scale=1`, mit echten Szenarien,
Bewegung, zeitgesteuertem Use und Transport. Nur die vorbereitende Boarding-
Fixture verwendet den vorhandenen Zeithelper. Der Handelsrueckflug wird ueber
den real gebundenen sichtbaren Servicebutton betaetigt, nicht per ersetzendem
Direktcommand. Tests verwenden private APPDATA-Profile, Headless/Betrieb im
Hintergrund und niedrige Prozessprioritaet. Das persoenliche Spielprofil wird
nicht als Testfixture benutzt.

## Gefundene und korrigierte Grenzen

- Alter Abflug verlangte bereits das konkrete Ziel und startete sofort die
  Mission: echter RED/GREEN-Flow [rot](raw/flow-red/), [gruen](raw/flow-first-green/).
- Doppelte/veraltete Anfluganfragen konnten vor Owner-Replay erneut Fuel
  buchen: kompletter Operationsbeleg wird vor allen Seiteneffekten geprueft
  ([Safety](raw/safety-final/)).
- Zielwechsel waehrend des Anflugs bzw. Legacy-Auswahl vor dem Anflug konnte
  Karten-/Auftragsidentitaet trennen: Sperrgrenze und universeller Abgleich
  von Mission-ID, Karte und Szenario vor Fuelbuchung ([RED](raw/legacy-identity-red/)).
- `starmap` fiel in alter Transportprojektion auf `homebase` zurueck. Zustand
  bleibt erhalten und wird vor weiteren UI-Callbacks publiziert; Pilot/Payload
  lassen sich im Orbit nicht loesen ([RED](raw/launch-lock-red/)).
- Reisevorbereitung blieb nach Landung aktiv; ausserdem sperrte ein vorhandener
  Ortskatalog den sichtbaren normalen Skirmish-Start. Reisewunsch wird beendet,
  normale Missionsauswahl und realer Startbutton sind wieder bedienbar
  ([RED](raw/visible-skirmish-red/)).
- An der Oberflaeche blieb ein Schiff als Quantum-busy markiert und sperrte
  den echten Handelsrueckflugbutton: Reise-busy endet am lokalen Handoff
  ([RED](raw/surface-busy-red/), [GREEN](raw/review-fixes-green/)).
- Leere Pad-Vorschau nach Layoutwechsel: wiederverwendeter Viewport wird wieder
  sichtbar; Vorschau prueft aktuelle ausgewaehlte Craft-ID, Ort und Reisephase.

Zwei unabhaengige Quellreviews wurden bearbeitet; nach den Core-Korrekturen
und dem abschliessenden Kamerareview keine weiteren konkreten Blocker.
Der eigene Kandidatenbuild erhaelt Export-/EXE-Belege in seiner Buildablage.

## Gestaltungsreferenz und Grenzen

Nutzerreferenz: [SCplanner-Karte](https://scplanner.org/#/karte), Galaxie- und
Systemansicht am 09.11.2026 betrachtet. Eigene schematische Godot-Zeichnung:
dunkler Raum, dezentes schraeges Raster, Orbitellipsen, leuchtende Marker und
kompakte rechte Detailflaeche. Keine externen Bilder/Modelle oder Ortsdaten
aus der Seite uebernommen. Bestehende Schiffmodelle/Previews bleiben dieselben
Katalogressourcen; nur deutsche Anzeigenamen aendern sich.

Headless-Rechteck-/Eingabetests belegen technische Bediengrenzen, keine
persoenliche Gestaltungsabnahme. Die Aufnahme der bereits laufenden alten
EXE scheiterte am Capture-Timeout; deren verdecktes Hinweisfenster wurde
deshalb nicht als beobachteter Fehler ausgegeben. Die neue Start-/Hinweis-
grenze wurde am echten aktuellen Flow geprueft. Keine allgemeine Performance-,
Mehrspieler-, Raumkampf- oder Releaseabnahme. Kein Mainmerge oder Push.
