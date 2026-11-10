# Altlasten in fuenf kleinen Schritten — 10.11.2026

## Ziel / Ursache
Die Kurzreview fand widersprechende LOS-Lesepfade, UI-eigenen Loadout-State,
unerreichbare Bedienelemente, eine vermischte Runtime-/Diagnosegrenze und
redundante Portraetressourcen. Diese fuenf Punkte werden in der vom Nutzer
bestaetigten Reihenfolge bereinigt; vorhandene Funktionen bleiben erhalten.

## Basis und Umfang
Eigener Taskbranch auf sauberem Main fbb7f52be. Die uncommittierten Arbeiten
im urspruenglichen Checkout bleiben unveraendert. Keine Mainintegration,
Assetloeschung, Spielbalanceaenderung oder neue Release-EXE in diesem Auftrag.
Ein kleiner, nachweisbarer Diagnostikschnitt ersetzt einen riskanten Rewrite.

## Verbindliche Dokumente
- docs/ARCHITECTURE.md und docs/CODEX_RULES.md
- docs/dev/terrain_truth_visual_audit_contract.md
- docs/dev/personnel_inventory_contract.md
- docs/dev/player_roster_save_contract.md
- docs/dev/runtime_script_layout_contract.md
- docs/dev/mission_command_feedback_contract.md
- docs/dev/export_runtime_package_contract.md

## Akzeptanz / Reihenfolge
1. Feuersektor-LOS liest denselben effektiven Terrain-/Tuerzustand wie Runtime-
   LOS. Cacheidentitaet umfasst Registry und Revision. Square-/Hex- und
   Wandsegmentverhalten sowie Editorbetrieb ohne Runtime bleiben erhalten.
2. Ein SimulationRoot-gebundener Personen-/Loadoutowner ersetzt UI-Wahrheit.
   Bestehende Controls, Defaults, Inventartransaktionen, Replay, unzugewiesene
   Piloten und unveraendertes Checkpointformat funktionieren weiter.
3. Nur wirkungslose Phasenbindings/-anzeigen und der unerreichbare Legacy-
   Rueckkehrbutton entfallen. GO, gemeinsame Phasendaten, Kamera, Auswahl und
   alle weiter benoetigten Homebase-Controls bleiben erhalten.
4. Der vollstaendige Debug-/Report-Feedbackbuilder wird als stateless
   Diagnostikhelper getrennt. Oeffentliche Methoden, Probe-Overrides, alle
   Snapshotfelder und die schmale Live-HUD-Projektion bleiben erhalten.
5. Nur die 42 nachweislich umgeleiteten Originalportraets werden vom Runtime-
   Export getrennt. Aliasverbraucher funktionieren ohne physische Altdatei;
   unbekannte/custom Pfade, die weiteren 57 Originale und Savewerte bleiben.

## Betroffene Dateien
LOSSystem, TerrainMap3DView, MissionTestSetup; SimulationRoot, HomebaseScreen,
SingleplayerRuntimeAdapter, CampaignStartConfiguration und neuer Loadoutowner;
project.godot, GameSettingsContract; neuer Feedback-Diagnostikhelper;
PortraitIdentityCatalog, direkte Portraet-/Emblemverbraucher und Exportvertrag.
Gezielte Verifier, diese Taskdatei und IMPLEMENTATION_STATUS.md.

## Lokale Pruefung
Godot 4.6.2. Kleine Regressionen mit echten Laufzeitklassen; LOS-/Loadoutbugs
zuerst rot reproduzieren, danach gruen. Tests mit isoliertem user:// und
geschuetztem realem Roster. Import, aktuelle Nachbargates, diff --check und
unabhaengiger Abschlussreview. Keine allgemeine Performance-/Gestaltungs-
oder Multiplayerfreigabe aus Komponentenchecks ableiten.

## Risiken / offene Punkte
Loadout-Initialisierungsreihenfolge und alte FOB-Importe; Square-/Hex-LOS und
Endpointsemantik; bestehende Source-Guards; variable Diagnostikuhren;
Kommas in Exportfiltern und gespeicherte individuelle Ressourcenpfade.
Ergebnisse und etwaige Baselinefehler werden in docs/qa/altlasten_20261110/
mit konkreten Befehlen und Reports dokumentiert.
