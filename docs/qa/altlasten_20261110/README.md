# Altlasten — kontrollierte Bereinigung 10.11.2026

Basis: Main fbb7f52be, eigener task/altlasten-fuenf-schritte-20261110.
Alle Godotlaeufe 4.6.2 mit run_review2_isolated.py, frischem user://,
Canary und unveraendertem echten Rosterhash/mtime. Rohlogs liegen lokal unter
.godot/altlasten; diese Datei enthaelt nur die nachvollziehbaren Ergebnisse.

## 1. LOS / Cache
Gemeinsame Blockersuche im LineOfSightSystem; Runtime behaelt ihre bisherigen
Welthoehen, Reichweiten-, Wandsegment- und Endpointregeln. PrimaryView liest
die explizit gebundene Registry. Cache erfasst deren Identitaet und Revision;
Revision macht auch stationaere sichtbare Linien dirty. Map-only-Authoring
ohne Revisionsquelle benutzt keinen langlebigen LOS-Cache.

- Neue altlasten_los_runtime_verifier.gd: urspruenglich11/9, anschliessend20/0.
- Review entdeckte einen Hoehenrandfall bei fehlender Endpunktzelle. Neue echte
  Sparse-Fixture zuerst22/1, mit erhaltener Runtime-Welthoehe23/0.
- Prueft Square/Hex, warmen Cache offen/geschlossen, Registryersatz, reine
  Reads, mutable Editor-Map und stationaere Revision ohne neue Befehle.
- TASK456 Wandsegment-LOS/Editorinspektor, HUD Door Runtime Authority und
  CPU/HUD R7 LOS-Projektion: drei bestandene isolierte Nachbargates.
- Keine neue Gameplay-LOS-Regel, kein gemessener Performancegewinn.

Reproduktion (pro Skript, success-marker passend setzen):
`python scripts/tests/run_review2_isolated.py --project . --script res://scripts/tests/altlasten_los_runtime_verifier.gd --success-marker 'ALTLASTEN_LOS passed=' --baseline .godot/altlasten/roster_baseline.json --output .godot/altlasten/recheck --timeout 150`

## 2. Loadoutowner
Ein gemeinsamer PersonnelLoadoutState ist am SimulationRoot gebunden. Die
Homebase adoptiert denselben Owner aus dem Standalone-/Restorepfad; sie besitzt
keine kanonische Equipmentdictionary mehr. Supply und Loadout werden vor dem
Erfolgssignal synchron bestaetigt. Replay rollt kein spaeteres Loadout zurueck.
Checkpointfelder und bestehende UI-Methoden bleiben kompatibel. Bewusste
set_fireteam_context-Importe bleiben moeglich; reine Flow-Refreshes importieren
keine veralteten Loadouts.

Neue Regression zuerst4/4, Importabgrenzung11/2, final13/0. Neun bestandene
isolierte Gates: Owner13/0, TASK35014/0, TASK35214/0, TASK35436/0,
TASK53330/0, Inventartransfer17/0, reales Inventar7/0, Vorbereitung/Continue13/0,
Basis-Weltbedienung9/0. Unabhaengiger Source-Review ohne weitere Blocker.

Zwei breitere Altgates sind ausdruecklich nicht gruen:
- TASK38119/2: editor-style two-column sheet / separate values-context columns.
- BasePersonnel62/3: sleep blocks incompatible movement; continue restores
  actual sleeping person and exclusive bed; wake frees sleeping person.
Beide auf sauberem unveraendertem Main fbb7f52be mit identischen Fehlernamen
reproduziert, jeweils keine Script-/Runtimefehler. Die bestehenden manuellen
Schlaf-/Layoutregeln werden hier nicht zurueckgedreht. Insbesondere alle
Loadout-, Boarding- und zweiten Continueassertionen bestehen auch im breiten
BasePersonnel-Gate. Belege lokal unter .godot/altlasten/baseline381 und
baseline-base-personnel; Vergleich im versionierten baseline_failures.json.

## 3. Tote Bedienreste
R/F-Deskriptoren, InputMap-Eintraege und unerreichbare Eingabezweige entfernt.
Gemeinsame Phasendaten, GO, Planmodus, Kamera und Auswahl bleiben. Nur der
unerreichbare OperationsReturnButton entfaellt; benoetigte alte Panels und
NodePaths bestehen weiter.

TASK1185 zuerst116/4, danach114/0. Basis-Weltbedienung9/0. Das breitere
Homebase-Operationsgate60/3 scheitert an drei alten Breiten-/Spaltenannahmen
und ist mit denselben Fehlernamen auf sauberem Main fbb7f52be reproduziert.
Diese drei push_error-Ausgaben sind Testassertionen, keine verschwiegenen
Runtimefehler; siehe baseline_failures.json. Alle60 uebrigen Assertions,
einschliesslich Navigation und Legacy-Abgrenzung, bestehen.

## 4. Diagnosegrenze
Der803-Zeilen-Reportbuilder ist ein stateless Helper unter
scripts/mission/diagnostics. Der oeffentliche Controllergetter delegiert mit
expliziten Konstanten; alle147 Quellmethoden laufen am urspruenglichen
Controller, auch in Probe-Subklassen. Kein neuer State, Cache oder Live-HUD-Pfad.
Die eingefrorene alte Methode liegt ausschliesslich im Testoracle. Neue
Verifier und dieses Oracle sind exakt vom Runtimeexport ausgeschlossen.

Vollstaendige typed-/Variantbyte-Paritaet ueber439 Felder in fuenf Faellen:
42/0 vor und nach dem Schnitt; Aufrufreihenfolge und Runtimeowner unveraendert.
Live-Projektion163/0, TASK1043 14/0, TASK1153 40/0, TASK1174 17/0,
Exportvertrag TASK51127/0, TASK100870/0 und TASK104294/0.

67 alte Source-Guards suchen116 verschobene Reportkeys jetzt im Helper; API-
und Preloadassertionen bleiben am Controller. Fuer65 Dateien wurde unabhaengig
bytegleiche Rueckfuehrbarkeit nach Entfernung genau dieses mechanischen
Schnitts geprueft. TASK1008/1042 behalten ihre Assertions, verwenden fuer den
vollstaendigen Report aber den echten Missionscontroller statt eines
freistehenden Nodes ohne Parent. Sie laufen dadurch ohne Scriptfehler.
Inventar: diagnostic_guard_migration.json. Nicht alle67 historischen
Szenariofixtures wurden erneut abgespielt; ihre116 Strukturguards und die
vollstaendige aktuelle Reportparitaet sind separat nachgewiesen.

Zusaetzliche LOS-Reviewfaelle pruefen WeakRef-Ablauf sowie Runtime-
Zielausschluss/Same-Cell gegen Preview-Endpoint: aktuell28/0.

## 5. Portraetexport
Alias-only-Aufloesung vor den vier direkten Lade-/Existenzpruefungen; unbekannte
Pfade erhalten ihre bisherige Leer-/Fehler-/Whitespacebehandlung. Gespeicherte
Emblem-ID und Pfad werden nicht umgeschrieben. Exakt42 bereits umgeleitete
Originale sind mit kommasicheren Filtern ausgeschlossen;57 weitere Originale
bleiben nutzbar. Keine Quelldatei geloescht, keine Katalogidentitaet migriert.

Echter Godot-Exporter gegen ein eigenstaendiges Portraetprojekt mit allen99
Originalen,11 Atlasquellen und realen Importcaches: vor dem Fix168 echte
Kompatibilitaetsfehler, danach750/0 mit Produktionsfiltern. Kein loser
Quellpfad als Fallback. Alle42 alten Sidecars und.ctex-Payloads fehlen; alle42
Aliasse ueber vier Verbraucher,57 sonstige Bilder und gespeicherte Embleme
funktionieren.264 Bild-/Atlas-/Cachehashes unveraendert.

Sieben isolierte Quellgates gruen: Atlas872/0, Consumer/Return8/0,
TASK233491/0, TASK23442/0, Charaktereditor103/0, TASK51127/0,
Identitaetskonsistenz152/0. Beleg: portrait_export_verification.json.

Reproduzierbarer Packagecheck (nur temporaeres Testpaket, keine Release-EXE):
`python scripts/tests/altlasten_portrait_export_probe.py --backend exporter --phase final --filters production --label recheck --run`
Die Consumer-Methoden werden automatisch unveraendert extrahiert. Das ist ein
realer Filter-/Ressourcenbeleg, keine vollstaendige gepackte Spielszenen- oder
Releaseabnahme. Eine gesamte Buildgroessenersparnis wurde nicht gemessen.

## Abschluss
Alle fuenf Schritte in eigener Reihenfolge und eigenen Commits abgeschlossen.
Gemeinsame26er-Matrix auf Code95e4b9625:26/26, Exit0, keine Script-/Runtime-
oder Leakfehler,26 getrennte user://-Profile und unveraenderter Default-Roster.
Frischer Import ebenfalls Exit0 ohne Fehler. Unabhaengiger ganzer Branchreview
ohne actionable Befunde: REVIEW.md. Maschinenbeleg: final_verification.json.

Die drei alten Sammelgates bleiben exakt mit ihren nachgewiesenen Baseline-
Abweichungen dokumentiert. Daraus wird keine gruene Gesamtsuite gemacht.
Der803-Zeilen-Diagnoseschnitt ist eine abgegrenzte Extraktion; der uebrige
Controller bleibt gross. Kein breiter Rewrite, Mainmerge oder neuer Spiele-
Releaseexport. Die laufenden Aenderungen im urspruenglichen Checkout wurden
von dieser Arbeit nicht angefasst.

Reproduktion der positiven Matrix:
`python scripts/tests/run_review2_isolated.py --project . --manifest scripts/tests/altlasten_regression_manifest.json --baseline .godot/altlasten/roster_default_baseline.json --output .godot/altlasten/recheck-matrix --timeout 150`
Der lokale Baselinepin enthaelt vor dem Lauf den Pfad, SHA256, Laenge und mtime
von user://profiles/local_player/roster_v1.json; er ist absichtlich nicht im
Repository. Der bestehende Runner verweigert abweichende Baselines, statt
reale Profildaten automatisch zu restaurieren. Rohlogs bleiben lokal unter
.godot/altlasten; neue Werkzeuge und Manifest liegen versioniert vor.

Taskbranch: task/altlasten-fuenf-schritte-20261110 auf Mainbasis fbb7f52be.
Der finale Commit-/Pushstatus wird nach dem Gitabschluss im Chat gemeldet.
Keine Mainintegration oder neue Release-EXE. Allgemeine Performance und native
Gestaltungsabnahme sind kein Ergebnis dieser Komponentenregressionen.
