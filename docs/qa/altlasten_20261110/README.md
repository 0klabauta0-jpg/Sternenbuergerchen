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

## Fortschritt
3 Controls, 4 Diagnostik, 5 Portraetexport folgen seriell.
Keine Mainintegration oder neue Release-EXE. Allgemeine Performance und native
Gestaltungsabnahme sind kein Ergebnis dieser Komponentenregressionen.
