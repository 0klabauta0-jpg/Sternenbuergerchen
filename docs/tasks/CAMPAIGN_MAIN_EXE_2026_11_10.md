# Kampagne und Skirmish nach Main / Windows-EXE

## Ziel und Ursache
Den freigegebenen Fünf-Missionen-Stand und drei Skirmish-Starts mit aktuellem Main integrieren und als neue Windows-EXE bereitstellen. Main hat inzwischen automatische Ruhe, Ressourcen- und Inventarowner weiterentwickelt.

## Umfang / Nicht-Ziele
Konflikte funktional zusammenführen; Main-Verhalten und Teams erhalten. Genau ein dauerhafter Ressourcenowner. Kampagnenstart weiterhin Pistole/leichte Rüstung, Mining-Blueprint in Mission 3. Keine neuen Modelle, keine Multiplayer-/Performance-Gesamtfreigabe und keine fremden lokalen Änderungen übernehmen.

## Quellen und betroffene Dateien
CAMPAIGN_SKIRMISH_REBUILD_2026_11_10.md; campaign_introduction_contract, location_resource_interaction_contract, skirmish_prepared_starts_contract; Supply/Resource/Personnel-Runtime, Meta-Adapter/Flow, Startkonfiguration, Daten und Konfliktdateien.

## Akzeptanz und lokale Prüfung
Gezielte gemeinsame Godot-4.6.2-Gates für Kampagnenkette, Starts, Inventar, Ruhe, Ressourcen und Checkpoint. Main/Remote identisch; Export aus sauberem Main. Neue EXE startet und enthält Kampagne sowie alle drei Skirmish-Vorlagen. Paket und Prüfnachweis außerhalb des Quellrepos, bestehende Pakete erhalten.

## Risiken / offene Punkte
Ressourcen- und Loadout-Owner dürfen beim Merge keine zweite Wahrheit erhalten. Spätere Modelle/Spezialfunktionen bleiben benannte Platzhalter. EXE-Startprobe ersetzt keinen vollständigen menschlichen Kampagnenplaytest.

## Stand
Integration und lokale Verifikation laufen im getrennten Worktree auf origin/main 1023d11c3. Ursprünglicher Arbeitsbaum bleibt unverändert.

## Reproduzierter Kartenbefund
M3: Rekrut bleibt auf isoliertem begehbarem Höhenrücken (27,-1). Echte Pfadsuche verlangt slope an Höhenübergängen; bisheriger Karten-BFS prüfte nur Höhendifferenz<=1. Akzeptanz: generierte niedrige Rücken mit begehbaren Böschungen, echte TerrainPathfinder-Traversierbarkeit im Kartengate, tatsächliche M3-Rücklieferung ohne Teleport. Main-Wrackblocker erhalten.

## Integrationsabnahme
Lokale Gates grün, einschließlich tatsächlichem ersten Ausflug55/0 und Fortsetzung123/0 mit finalem echten Continue. Native81/0; Kartenhöhe69/0. Unabhängiger Code-Review ohne offene P1/P2. QA: docs/qa/campaign_main_exe_20261110/README.md. Main/Push/Export werden aus diesem geprüften Commit abgeschlossen; Paketnachweis enthält exakte Git-/Binärhashes.
