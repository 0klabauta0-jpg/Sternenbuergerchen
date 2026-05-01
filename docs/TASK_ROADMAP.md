# TASK_ROADMAP

## Zweck
Diese Roadmap definiert die Reihenfolge der Tasks fuer das Projekt.

Ziel:
- kontrollierter Aufbau der Architektur
- klare Trennung von Daten, Simulation und Darstellung
- schrittweiser Uebergang von Struktur -> Integration -> sichtbares Verhalten

Diese Datei ist verbindlich fuer Codex.
Tasks duerfen nicht in anderer Reihenfolge umgesetzt werden, ausser es ist explizit angegeben.

---

# Arbeitsregeln

## Reihenfolge
- Tasks muessen strikt in der angegebenen Reihenfolge umgesetzt werden
- keine Tasks ueberspringen
- keine Tasks zusammenziehen, ausser im Batch-Mode erlaubt

## Branch-Regel
Vor jedem Task:

```bash
git checkout integration/core-foundation
git checkout -b task/<task-name>

Bei Batch-Arbeit:

git checkout integration/core-foundation
git checkout -b batch/<batch-name>
Phase 0 – Fundament (abgeschlossen)
TASK_006 Workflow Setup
TASK_001 RuntimeLeader
TASK_002 EventRouter
TASK_003 SimulationRoot
TASK_004 Registries
TASK_005 UpdateManager
Phase 1 – Integration (abgeschlossen)
TASK_007 RuntimeLeader Integration Test
TASK_008 Unit Stub + Registry Test
TASK_009 Minimaler Command-Flow
TASK_010 Tick-Verarbeitung in SimulationRoot
TASK_011 Unit-Target Command
TASK_012 Team-/FTL-Command
Phase 2 – Datenmodelle (abgeschlossen)
TASK_013 CommanderCommand
TASK_014 FTLTask
TASK_015 Command -> FTLTask Translator
Phase 3 – FTL-Datenfluss vervollstaendigen
TASK_016 – FTLTask im RuntimeLeader annehmen

Ziel:

RuntimeLeader kann FTLTask empfangen
minimaler Nachweis
keine Ausfuehrung
TASK_017 – FTLTask-Queue im RuntimeLeader

Ziel:

RuntimeLeader verwaltet Tasks
aktueller Task + Queue
keine KI
TASK_018 – FTL-State-Modell minimal

Ziel:

States definieren:
idle
moving
holding
engaging
retreating
keine echte Wirkung
TASK_019 – FTLTask -> RuntimeStatus

Ziel:

Task fuehrt zu einfachem Statuswechsel
keine Bewegung
Phase 4 – Unit-Ebene anbinden
TASK_020 – UnitCommand-Stub

Ziel:

einfache Unit-Kommandos als Daten
TASK_021 – TestUnit Runtime-Status

Ziel:

Unit hat Zustandsmodell:
idle
assigned
pending_move
holding
TASK_022 – FTLTask -> Unit-Zuweisung

Ziel:

FTL referenziert Units korrekt
keine Aktion
TASK_023 – mehrere Units pro FTL

Ziel:

2–3 Units pro Team
nur Datenfluss
Phase 5 – erste sichtbare Reaktion
TASK_024 – Missions-Testszene

Ziel:

einfache Szene mit:
FTL
Units
Ziel
TASK_025 – Move-Target als Daten

Ziel:

Zielposition speichern
keine Navigation
TASK_026 – minimaler Move im SimulationRoot

Ziel:

einfache Positionsaenderung erlaubt
kein Pathfinding
TASK_027 – erster sichtbarer Flow

Ziel:
Commander -> FTL -> SimulationRoot -> Unit

Phase 6 – taktische Grundsysteme
TASK_028 – Line of Sight minimal
TASK_029 – Fog of War minimal
TASK_030 – Treffer-/Damage-Modell minimal
TASK_031 – Down-/Bleedout-Zustaende
TASK_032 – Friendly Fire
Phase 7 – Meta-Layer
TASK_033 – Heimatbasis
TASK_034 – FOB
TASK_035 – Teamtransfer
TASK_036 – Respawn-Logik
TASK_037 – Rover/Frachter minimal
Phase 8 – Vertical Slice
TASK_038 – Fireteam-Aufteilung
TASK_039 – Phasen-Wirkung
TASK_040 – Take-Befehl und Objective
TASK_041 – Siegbedingung
TASK_042 – Respawn-Timer-Anzeige
Phase 9 – Gegner-Verhalten
TASK_043 – Einfache Gegner-Positionierung
TASK_044 – Gegner-Reaktion auf Kontakt
TASK_045 – Gegner-Wellen
Phase 10 – Unit-Identitaet
TASK_046 – Unit-Skill-Werte
TASK_047 – Skill-Wirkung im Combat
TASK_048 – Persoenlichkeitsmerkmale
TASK_049 – Heimatbasis: Unit-Uebersicht mit Skills
Phase 11 – Multiplayer-Prototyp V1
TASK_050 – Server-autoritativer SimulationRoot
TASK_051 – Host/Join mit Testteams
TASK_052 – Befehlsuebertragung ueber Netzwerk
TASK_053 – Synchronisierte Spielzustandsanzeige
Phase 12 – Terrain-System und Gameplay-Wirkung
TASK_054 – Terrain-Tile-Datenmodell und Registry
TASK_055 – Walkability und einfaches A*-Pathfinding
TASK_056 – LOS ueber Terrain-Tiles
TASK_057 – Cover aus Terrain-Tiles
TASK_058 – Hoehenstufen
TASK_059 – Strassen und Oberflaechen
Phase 13 – Map Editor
TASK_060 – Terrain-Daten als JSON-Datei
TASK_061 – Map-Editor-Szene: Tile-Auswahl und Anzeige
TASK_062 – Map-Editor: Tile-Properties bearbeiten
TASK_063 – Map-Editor: Speichern und Laden
TASK_064 – MissionTestSetup: Terrain aus JSON laden
Phase 14 – Map-Editor-Workflow und Politur
TASK_065 – Tile-Typ-Katalog und Palette
TASK_066 – Corridor-Wall Typen, Typ-Texturen und Auto-Cliff
TASK_067 – Fix Map-Editor 64x64 Flat Ground
TASK_068 – Zoom-Inversion und Auto-Wall-Overlays
TASK_068b – Drag-Painting und Hover-Preview
TASK_068c – Gitternetz-Overlay und Himmelsrichtungen
TASK_069 – Map-Editor: Auswahl, Save As und Workflow-Polish
Phase 15 – Meta-Layer-Roster-Lesbarkeit
TASK_070 – NPC-Karten-Komponente
TASK_071 – Heimatbasis: NPC-Karten und Auswahlfokus
TASK_072 – FOB: Teamkarten und Einsatzstatus
TASK_073 – Homebase: Charakterbogen und Drag-and-Drop-Teamstaging
TASK_074 – Homebase: Layout-Neuordnung und Missionsinfoleiste
TASK_075 – Homebase: Kartenverdichtung, Tooltip-Polish und Charakterbogen-Fokus
TASK_076 – Meta-Layer: Graue Kenney-UI-Rahmen
TASK_077 – FOB: Fireteam-Auswahl und Startvorbereitung
TASK_078 – Meta-Layer: Navigation und Map-Ansicht
TASK_079 – FOB: Fireteam-Management, Respawn-/Loadout-Staging und Dropship-Wartezone
TASK_080 – Meta-Layer: Transfer-Sichtbarkeit, Pool-DnD und Charakterbogen-Toggle
TASK_081 – Meta-Layer: UI-Harmonisierung fuer FOB, Homebase und Loadout

Phase 16 – Charakterbogen-Kampfwirkung
TASK_082 – Gemeinsamer Terrain-Renderer fuer Editor und Mission
TASK_085 – Charakterbogen Combat-Integration (get_combat_effects)
TASK_086 – Waffenmodell (WeaponData)
TASK_087 – Loadout-Pipeline und Waffen-Sprites

Phase 17A – Waffen und Loadout (abhaengig von 086/087)
(bereits in Phase 16 enthalten)

Phase 17B – Teamdynamik
TASK_088 – Leadership-Bonus auf Fireteam-Mitglieder

Phase 17C – Gegner
TASK_089 – Enemy Cover-Seeking
TASK_090 – Differenzierte Enemy-Typen

Phase 17D – Wahrnehmung
TASK_091 – Awareness: Detection-Delay
TASK_092 – Stealth: Reduzierte Sichtreichweite

Phase 17E – Verhaltensqualitaet
TASK_093 – Discipline: Hold-Fire-Disziplinbrueche
TASK_094 – Recognition: Friendly-Fire-Verwechslung

Phase 17F – Support-Rollen
TASK_095 – Combat Medic Support

Phase 17G – Meta-Layer Recovery
TASK_096 – Meta-Layer Recovery: Missionskarte, Dropship-LZ und Character-Sheet-Umbau

Phase 17H – Taktisches Kampfsystem
TASK_097 – Datenmodelle, engage und Ad-hoc-Vertraege
TASK_098 – TacticalInputController und Fireteam-Auswahl
TASK_099 – Wegpunktplanung, Kontextmenue und Order-Visualisierung
TASK_100 – PhaseController und globale Plan-Ausfuehrung
TASK_101 – FireteamBehaviorResolver, geplantes Flankieren und Standardverhalten
TASK_102 – AdHocOrderController und Gefechts-Sofortbefehle
TASK_103 – Suppression, Interruption und Return-to-Plan
TASK_104 – Inter-Fireteam-Koordination und Leader-initiiertes Flankieren
TASK_105 – Leader-Nachfolge, Lead-Rueckgabe und UI-Synchronisierung
TASK_106 – Dropship-LZ, Insertion und verzoegerte Aktivierung
TASK_107 – LoadoutModifierResolver und initiale Missions-Effects

Phase 17I – Gegner-Patrouillen und Editor
TASK_108 – PatrolEditorTool und Pre-Contact-Patrol

Phase 17J – Taktische Erweiterungen
TASK_109 – TacticalStanceController und TacticalStancePanel
TASK_110 – FireteamMovementController und Bewegungsmuster
TASK_111 – FireteamSecurityController und Overwatch
TASK_112 – ContactTracker und ContactMapOverlay
TASK_113 – FlankVulnerabilityResolver und Sektorstrafen

Phase 17K – Marker-Follow-up
TASK_115 – Gemeinsames Markersystem fuer Editor und Taktikkarte

Phase 17L – Architektur- und Spielgefuehl-Nacharbeit
TASK_116 – Runtime-Systeme aus scripts/tests herausloesen
TASK_117 – Dropship-Deploy als SimulationRoot-Effects
TASK_118 – Combat-Entscheidungen aus MissionCombatLoopDriver herausloesen
TASK_119 – Seeded Combat RNG und roll_override begrenzen
TASK_120 – Teamqualitaet als FTL-Ausfuehrungsfaktor

Phase 17M – Area Orders und Bewegungsrobustheit
TASK_121 – Area Order Marker
TASK_122 – Defend Area Semantik
TASK_123 – Attack Area Semantik
TASK_124 – Area Feedback in #17 Selected Fireteam
TASK_125 – Terrain Blocker Debug und Walkability Tests

Phase 17N – HPA Navigation und Performance
TASK_126 – HPA Navigation Foundation
TASK_127 – HPA Pathfinder Integration
TASK_128 – Navigation Budgeting und Debug
TASK_129 – Deckungsbewusste Pfade mit HPA und Subgoal-Vorbereitung
TASK_130 – Lokale Unit-Avoidance mit ORCA/RVO-Light

Phase 18 – Erweiterung (spaeter)
Skillsystem
soziale Dynamik
persistente Teams
Multiplayer
Map Editor
Fahrzeuge
komplexe Taktik
Phase 18A - Navigation-, Cover- und Rendering-Labs
TASK_131 - Navigation Benchmark Harness
TASK_151 - Engpass-Reservierung und MAPF-Light
TASK_152 - Seeded Cover Placement Lab
TASK_153 - 3D Transparency Material Presets

Phase 18B - Editor-Asset-Ausbau
TASK_132 - Kenney Isometric Asset Palette Expansion

Phase 18C - Tactical Mission Authoring
TASK_155 - Tactical Mission Test Presets (implementiert)
TASK_156 - Mission Scenario Data Contract (implementiert)
TASK_157 - Tactical Mission Editor MVP (implementiert)
TASK_158 - Editor-to-Live Mission Validation

Batch-Empfehlung

Codex soll Tasks in kleinen Gruppen bearbeiten:

Batch 1
TASK_016–019
Batch 2
TASK_020–023
Batch 3
TASK_024–027

Batch 4
TASK_074–077

Batch 5
TASK_078–079

Batch 6
TASK_080–081

Nach jedem Batch:

Godot starten
Fehler pruefen
ggf. Integrationsbranch aktualisieren
Definition of Done

Ein Task ist fertig, wenn:

Code kompiliert / Godot startet
Scope eingehalten wurde
keine unerlaubten Nebenumbauten
IMPLEMENTATION_STATUS.md aktualisiert
Commit + Push erfolgt
Wichtig

Diese Roadmap ist verbindlich.

Wenn ein Task:

groesser wird als erwartet
neue Architektur erfordert
bestehenden Code massiv veraendert

Dann:

stoppen
Problem melden
nicht improvisieren
