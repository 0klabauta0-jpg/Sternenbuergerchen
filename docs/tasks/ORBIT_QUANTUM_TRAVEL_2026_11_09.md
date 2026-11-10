# Mondbasis, Sternkarte und Quantum-Reise

Stand: 09.11.2026. Vom Nutzer mit „Ja, genau so umsetzen“ freigegeben.
Status: implementiert und technisch geprueft; QA unter
`docs/qa/orbit_quantum_20261109/README.md`. Native Nutzerabnahme separat.
Basis: Main `b548b5556`, eigener Branch `task/orbit-quantum-travel-20261109`.
`integration/core-foundation` ist Vorfahr und liegt 111 Commits zurueck; die
aktuelle Kampagneneinfuehrung und Ortskarten liegen bereits auf Main.

## Ziel / Problem und Ursache

Der Spieler hebt von seiner kleinen Mondbasis ab, erreicht den Mondorbit,
reist auf einer gemeinsamen Sternkarte zum Planetenorbit und waehlt dort
Handelsposten oder Satelliten-Absturzstelle. Bisher bindet der Abflug bereits
einen konkreten Ort und startet sofort die Missionsinstanz. Das verdeckt die
Reise und erlaubt die gewuenschte spaete Zielwahl nicht.

## Freigegebener Entwurf und Ansatz

Ein Planet, ein kleiner Mond mit Heimatbasis, zwei bestehende Zielorte auf dem
Planeten. Ein Zielklick startet einen kurzen Quantum-Sprung. Abbrechen behaelt
die erreichte Position; ein erneuter Zielklick startet von dort einen neuen
Sprung. Erst im Zielorbit werden die zugehoerigen Ortsanfluege bedienbar.
Ausdrueckliches „Anflug starten“ verlaesst sichtbar die Sternkarte und laedt
erst dann Karte/Szenario. Rueckkehr fuehrt ueber Planeten- und Mondorbit.

Ansatz: autoritativer, an SimulationRoot gebundener Reiseowner neben den
vorhandenen Kampagnen-/Versorgungsownern; bestehende Transport-/Payloadpfade
bleiben Besitzer ihrer Daten. UI zeichnet nur Snapshots und sendet Commands.
Eine nur vorgeschaltete Animation wuerde die Mission weiter zu frueh starten;
freie manuelle Schiffssteuerung wurde zugunsten des Quantum-Zielklicks verworfen.

Konkrete Implementierungsentscheidung: ein Sprung dauert zunaechst 3 Sekunden.
V1 zeigt ein Schiffssymbol und unterstuetzt einen aktiven Reiseausflug.
Die existierenden streckenbezogenen Fuel-Buchungen erfolgen beim Ortsanflug
und Rueckflug genau einmal; Abbruch/Neustart erzeugen keine weiteren Kosten.

## Umfang / Nicht-Ziele

Enthalten: Abheben ohne vorgewaehlte Ortskarte; Sternkarte; abbrechbarer und
erneut startbarer Quantum-Flug; planetare Zielwahl; sichtbare Ladegrenze;
Rueckweg; bestehende Kampagnensperren und Basis-Checkpoints erhalten.
Keine weiteren Himmelskoerper, Missionen, Raumkaempfe, Art-Assets, Midflight-
Savegames, Multiplayer-Reiseregeln oder allgemeine Performancearbeiten.
Skirmish-/Multiplayer-Karten ausserhalb dieser Ortsreisen behalten ihren Pfad.

Nutzerergaenzung: Die Schiffsvorschau in Basis-/Trupp-/Ausrustungsansichten
folgt dem tatsaechlichen Standort: Schiff auf seinem Landepad, solange es dort
steht; Weltraumdarstellung nach dem Abheben. Operationsansichten bleiben auf
der Reise erreichbar, ohne dies als Heimkehr oder neuen Savepunkt zu werten.

## Relevante Contracts / Dokumente

- `docs/PROJECT_BRIEF.md`, `docs/ARCHITECTURE.md`, `docs/CODEX_RULES.md`
- `docs/dev/singleplayer_locations_jobs_contract.md`
- `docs/dev/homebase_direct_dropship_flow_contract.md`
- `docs/dev/campaign_introduction_contract.md`
- `docs/dev/orbit_quantum_travel_contract.md`
- `docs/superpowers/plans/2026-11-09-orbit-quantum-travel.md`

## Akzeptanzkriterien

Weitere freigegebene UX-Arbeiten stehen in `UI_CLARITY_2026_11_09.md`.
Ergaenzter Nutzerauftrag: verschiebbare Karte und Zoom genau zum Mauszeiger;
mehr Abstand zwischen Mond und Planet. Vorlaeufige deutsche Namen: `Glut`
und `Glut I`. Drei als spaeter markierte, noch nicht aktive Orbitbereiche
reservieren Platz auf einer groesseren Bahn. Raumkampf und Generierung von
Weltraumkarten sind ausdruecklich Zukunftsumfang, keine aktiven V1-Mechaniken.
Nutzerreferenz fuer die Sternkarte: <https://scplanner.org/#/karte>, am
09.11.2026 in Galaxie- und Systemansicht betrachtet. Uebernommen werden
dunkler Raum, dezentes schraeges Raster, projizierte Orbitbahnen, leuchtende
Marker und kompakte rechte Detailflaeche. Eigene schematische Godot-Zeichnung;
keine externen Assets oder Ortsdaten. Umfang bleibt ein Planet/ein Mond.

1. Reales startbereites Schiff hebt in den Mondorbit ab; keine aktive Mission,
   laufender Missionstimer oder aktivierter Auftrag allein durch Abheben.
2. Zielklick startet 3-s-Quantum; Abbruch stoppt exakt an erreichter Position;
   gleicher/anderer Zielklick startet dort neu. Keine Teleportation bei Abbruch.
3. Ortsanflug nur im passenden Orbit und bei gueltigen Voraussetzungen.
   Auswahl allein laedt keine Karte. Sichtbarer Uebergang vor Instanziierung.
4. Satelliten- und Handelsanflug verwenden unveraenderte Karten/Szenarien,
   echte Missions-/Versorgungs-/Payloadbelege und vorhandene Fuel-Regeln.
5. Rueckweg erreicht zuerst den Planetenorbit, dann per Quantum den Mondorbit;
   erst Landung bestaetigt Heimkehr und ermoeglicht Basischeckpoint.
6. Doppelklick, stale Commands, ungueltige IDs und gesperrter Handel koennen
   weder Missionsinstanz noch Belohnung/Fuel-Buchung duplizieren.
7. Vorhandene Kampagnen-/Skirmish-Regressionspfade laufen, persoenliche
   Nutzerdaten und fremde unversionierte Dateien bleiben erhalten.
8. Schiffsvorschau und Sternkarte lesen denselben Reise-/Craftzustand;
   Vorbereitung zeigt reales Pad, Reise zeigt Weltraum, Landung wieder Pad.
9. Mausrad-Zoom behaelt den Kartenpunkt unter dem Mauszeiger; Ziehen verschiebt
   die Ansicht. Gesamtansicht setzt nur die Kamera zurueck. Auswahl/Hits und
   Schiffsdarstellung verwenden denselben Transform; Owner-State bleibt gleich.

## Betroffene Dateien

Neue Reise-/Systemdefinition, SimulationRoot-Commandrouting, Runtimeadapter,
MetaLayerFlow, neue Sternkartenansicht und Regionalkartenwrapper, gezielte
Domain-/UI-/Flow-Verifier sowie betroffene Loop-Smokes und Dokumentation.
Details und Schnittstellen stehen im Implementierungsplan.

## Lokale Pruefung

Tests zuerst rot, dann gruen: autoritative Reise, echter Flow inkl. spaetem
Laden, UI-Aktionen und kompletter Rueckweg. Bestehende Auftrag-/Fuel-/Kampagnen-
und Skirmish-Smokes mit isolierten Profilen; Godot headless, Hintergrund und
niedrige Prioritaet. `git diff --check`. Native Gestaltungsabnahme getrennt.

## Risiken / offene Punkte

Transportphasen und Ergebnis-/Heimkehrpfad muessen an der Orbitgrenze getrennt
werden, ohne zweite Craft-/Fuel-Wahrheit. Intro verlangt weiterhin Satellit
und reale Heimkehr vor Handel. Nur Basischeckpoint, kein Fortsetzen im Orbit.
Aktuelle Nutzersteuerung vom 10.11.2026 ersetzt die fruehere Exportgrenze:
**Noch keine EXE erstellen.** Erst den Abschluss des Chats
`Einzelspieler: Basis, Orte und UI — Umsetzungsplan For agen…`
(`01a1c1d2-5f36-72d0-8c82-570dd6bd95d2`) abwarten, beide Arbeitsstaende
integrieren, Konflikte loesen, gemeinsam pruefen, auf Main committen und
pushen. Erst aus diesem gemeinsamen Main wird die neue EXE erstellt.
Unser gepruefter Produktcommit ist `7011ce4b2`. Bisher kein Export erfolgt;
nur separate Exportcheckouts wurden vorbereitet.
