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
TASK_151 - Engpass-Reservierung und MAPF-Light (implementiert)
TASK_152 - Seeded Cover Placement Lab (implementiert)
TASK_153 - 3D Transparency Material Presets (implementiert)

Phase 18B - Editor-Asset-Ausbau
TASK_132 - Kenney Isometric Asset Palette Expansion

Phase 18C - Tactical Mission Authoring
TASK_155 - Tactical Mission Test Presets (implementiert)
TASK_156 - Mission Scenario Data Contract (implementiert)
TASK_157 - Tactical Mission Editor MVP (implementiert)
TASK_158 - Editor-to-Live Mission Validation (implementiert)
TASK_159 - 2.5D Editor and Mission Primary View (implementiert)
TASK_160 - Tactical Mission Playability Smoke (implementiert)

Phase 18D - Strategic Review, UI-Assets und Multiplayer-Vorbereitung
TASK_161 - Mission Runtime Boundary Cleanup (implementiert)
TASK_162 - Combat Loop Authority Split (implementiert)
TASK_163 - Map Editor Module Split (implementiert)
TASK_164 - UI Theme and Component Library (implementiert)
TASK_165 - Local Asset Curation and Import Plan (implementiert)
TASK_166 - Multiplayer Authority Command Contract (implementiert)
TASK_167 - Multiplayer Session and Lobby Extraction (implementiert)
TASK_168 - Multiplayer Snapshot Replication Contract (implementiert)
TASK_169 - Multiplayer Two-Client Playability Smoke (implementiert)
TASK_170 - Performance and Warning Budget Gate (implementiert)

Phase 18E - NPC Visual Replacement
TASK_171 - NPC Model Replacement Animated Characters (implementiert)
TASK_172 - NPC Animation Scale Helmets and Enemy Visuals (implementiert)
TASK_173 - NPC Animation Skeleton Socket Contract (implementiert)
TASK_174 - Character Helmet and Blaster Attachment Visuals (implementiert)

Phase 18F - NPC Loadout Visuals
TASK_175 - NPC Loadout Attachments (implementiert)
TASK_176 - FOB Loadout Weapon Preview Selector (implementiert)

Phase 18G - Drop Light Fixed UI Layout
TASK_177 - Drop Light Fixed UI Layout Contract (implementiert)
TASK_178 - FOB Drop Light Fixed FullHD Layout (implementiert)
TASK_179 - Homebase Drop Light Fixed FullHD Layout (implementiert)
TASK_180 - Mission Drop Light Fixed HUD Layout (implementiert)
TASK_181 - Drop Light Fixed Window Audit Patch (implementiert)

Phase 18H - Terrain Height and Hill Rules
TASK_182 - Terrain Hill Rules Contract (implementiert)
TASK_183 - Editor Hill Authoring Patch (implementiert)
TASK_184 - Gameplay Hill Semantics Patch (implementiert)
TASK_185 - Hill Visuals and Edge Lines Patch (implementiert)

Phase 18I - Mission Map NPC Behavior and Command Feedback
TASK_186 - Mission Map Unit Presence and Registry Audit (implementiert)
TASK_187 - NPC Minimum Spacing and Multiplayer Authority (implementiert)
TASK_188 - Fireteam Advance Styles Map Readability (implementiert)
TASK_189 - Medic Adjacent Tile Healing Rule (implementiert)
TASK_190 - Weapon Visual Loadout Expansion and Scale (implementiert)
TASK_191 - Command Chain Selection and Area Feedback Pass (implementiert)
TASK_192 - Mission Map NPC Behavior Playability Smoke (implementiert)

Phase 18J - Asset Intake and Availability Expansion
TASK_193 - Asset Source Inventory and Availability Matrix (implementiert)
TASK_194 - Space Modular and Station Setpiece Import (implementiert)
TASK_195 - UI Input and Cursor Asset Availability Pass (implementiert)
TASK_196 - Rank and Particle Asset Subset Import (implementiert)
TASK_197 - Curated Asset Catalog and Usage Mapping (implementiert)
TASK_198 - Asset Import Gate and Visual Smoke (implementiert)

Phase 18K - Main Menu and App Entry
TASK_199 - Main Menu Shell and Background Image (implementiert)

Phase 18L - Enemy Team Tactics Weapon Ranges and NPC Identity
TASK_200 - Enemy Team Tactics Contract and Editor Config (implementiert)
TASK_201 - Weapon Range Scale and Tile Distance Patch (implementiert)
TASK_202 - Enemy Security Direction and LOS Patch (implementiert)
TASK_203 - Enemy Cover Advance and Team Tactics Patch (implementiert)
TASK_204 - Enemy Tactics Multiplayer Authority Snapshot Patch (implementiert)
TASK_205 - Weapon Fire VFX Muzzle Flash Particles (implementiert)
TASK_206 - Enemy Visual Faction Archetypes Orange Suit (implementiert)
TASK_207 - NPC Rank Skill Badge Derivation (implementiert)
TASK_208 - Enemy Team Tactics Playability Smoke (implementiert)

Phase 18M - Comic Bubble Feedback and NPC Thoughts
TASK_209 - Comic Bubble Asset Catalog and Visual Contract (implementiert)
TASK_210 - Fireteamleader Command Feedback Bubbles (implementiert)
TASK_211 - Comic Bubble Toggles Cooldowns and Settings (implementiert)
TASK_212 - NPC Thought Bubble Hold to Peek Overlay (implementiert)
TASK_213 - Skill Based Bubble Text Resolver and Content Pass (implementiert)
TASK_214 - Comic Bubble Feedback Playability Smoke (implementiert)

Phase 18N - Deep Performance Profiling and Optimization Pass
TASK_215 - Performance Deep Pass Baseline and Research (implementiert)
TASK_216 - 2.5D Rendering Node and Draw Budget Pass (implementiert)
TASK_217 - Navigation Pathfinding LOS Performance Pass (implementiert)
TASK_218 - Simulation Combat AI Tick Budget Pass (implementiert)
TASK_219 - UI HUD Meta Comic Bubble Performance Pass (implementiert)
TASK_220 - Asset Import VRAM Shader Pipeline Stutter Pass (implementiert)
TASK_221 - Multiplayer Snapshot Serialization Performance Pass (implementiert)
TASK_222 - Performance Regression Gate and Manual Profile Checklist (implementiert)

Phase 18O - App Shell Settings Fog of War Multiplayer Maps and Editor Usability
TASK_223 - Fog of War Modes Contract and Settings (implementiert)
TASK_224 - Fog of War Tile Visibility Height Cover Runtime (implementiert)
TASK_225 - Fog of War 2.5D Visual Overlay and Contacts (implementiert)
TASK_226 - Main Menu Settings Shell Display Audio Input Gameplay (implementiert)
TASK_227 - Main Menu Multiplayer Host Join Lobby Flow (implementiert)
TASK_228 - Multiplayer Editor Map Manifest Download Consent (implementiert)
TASK_229 - Map Editor Usability Authoring Pass (implementiert)
TASK_230 - Flight Altitude Layer and Air Visibility Audit (implementiert)
TASK_231 - App Shell Game Setup Integration and Open Items Review (implementiert)

Phase 18P - Character Gameplay Roster Progression and Team Identity
TASK_232 - Start Roster Generation Contract (implementiert)
TASK_233 - Portrait Identity Catalog and Roster Presentation (implementiert)
TASK_234 - Persistent Player Roster Save and Reset (implementiert)
TASK_235 - Character Sheet Roster Gameplay Expansion (implementiert)
TASK_236 - Fireteam Relationship Affinity and Cohesion (implementiert)
TASK_237 - Mission Progression XP Morale Frustration (implementiert)
TASK_238 - Personnel Events Recruit Leave Dismiss Notifications (implementiert)
TASK_239 - Character Gameplay Bubble Mission Integration (implementiert)
TASK_240 - Multiplayer Player Roster Ownership Contract (implementiert)
TASK_241 - Character Gameplay Playability Smoke (implementiert)

Phase 18Q - Audio SFX Backgrounds Asset Locality and Alignment
TASK_242 - Audio SFX Source Inventory and Curated Import (implementiert)
TASK_243 - Audio Event Contract and Bus Setup (implementiert)
TASK_244 - Combat Movement UI SFX Integration (implementiert)
TASK_245 - Background Image Catalog and Screen Usage (implementiert)
TASK_246 - Visual Scale Alignment Asset Pass (implementiert)
TASK_247 - Used Asset Project Locality Audit Gate (implementiert)
TASK_248 - Audio Visual Import and Playback Smoke (implementiert)
TASK_249 - Post Audio Visual Performance Optimization Pass (implementiert)
TASK_250 - Asset Audio Background Playability Smoke (implementiert)

Phase 18R - Nature Kit Terrain Cliffs Ground and Vegetation
TASK_251 - Nature Kit Classic Source Inventory and Subset Import (implementiert)
TASK_252 - Nature Cliff Hill Edge Visual Mapping (implementiert)
TASK_253 - Nature Ground Surface Editor Palette Pass (implementiert)
TASK_254 - Nature Trees Rocks Vegetation Cover Props (implementiert)
TASK_255 - Nature Kit Hill Playability Visual Performance Smoke (implementiert)

Phase 18S - Automated Playability QA and UI Flow Coverage
TASK_256 - Automated Playability Coverage Contract (implementiert)
TASK_257 - Button Reachability and Interaction Verifier (implementiert)
TASK_258 - Fixed Window Clipping Scrollbar Playability Audit (implementiert)
TASK_259 - Character Card Roster Switching Playability (implementiert)
TASK_260 - Loadout Selection Decorative Weapons Weight Playability (implementiert)
TASK_261 - Cross Screen State Loss Playability Smoke (implementiert)
TASK_262 - Playability Regression Gate and Manual Open Items (implementiert)

Phase 18T - Contextual Help Popups and Explainability
TASK_263 - Contextual Help Popup UX Contract (implementiert)
TASK_264 - Contextual Help Popup Component Settings Toggle (implementiert)
TASK_265 - Character Sheet Loadout Help Content Pass (implementiert)
TASK_266 - Command Mission Editor Settings Help Content Pass (implementiert)
TASK_267 - Contextual Help Coverage Layout Verifier (implementiert)
TASK_268 - Post Help Popup Playability Regression Smoke (implementiert)

Phase 18U - Tactical Command Doctrine Fireteam Delegation and Air Asset Risk
TASK_269 - Tactical Doctrine Source Review Game Abstraction (implementiert)
TASK_270 - Commander to Fireteam Leader Delegation Contract (implementiert)
TASK_271 - Tactical Command Modes ROE Fire Rules (implementiert)
TASK_272 - Multi Fireteam Coordinated Area Plan (implementiert)
TASK_273 - Fireteam Leader Skill Tactical Progression (implementiert)
TASK_274 - Tactical Communication Feedback Layer (implementiert)
TASK_275 - Command Button Hierarchy Arrangement Overhaul (implementiert)
TASK_276 - Tactical Breakout and Exception Behavior (implementiert)
TASK_277 - Dropship Freighter Anti Armor Threat Contract (implementiert)
TASK_278 - Air Asset Loss Recovery Meta Loop (implementiert)
TASK_279 - LZ Security Air Asset Tactical Playability Smoke (implementiert)
TASK_280 - Tactical Profile Editor Scenario Authoring (implementiert)
TASK_281 - Tactical Command Multiplayer Authority Snapshot (implementiert)
TASK_282 - Tactical Overhaul Playability Performance Help Gate (implementiert)

Phase 18V - Post Tactical Docs Architecture and Sneaky Code Review
TASK_283 - Post Tactical Docs Consistency Audit (implementiert)
TASK_284 - Gameplay Truth Architecture Boundary Audit (implementiert)
TASK_285 - Tactical Decision Branch Integrity Review (implementiert)
TASK_286 - UI Feedback Truth Regression Review (implementiert)
TASK_287 - Editor Save Multiplayer Contract Regression Review (implementiert)
TASK_288 - Regression Gate Coverage Gap Audit (implementiert)
TASK_289 - Final Sneaky Code Review Patch Queue (implementiert)
TASK_290 - User Handbuch Weekly Closeout (implementiert)

Phase 18W - Editor Terrain Visual Recovery and Authoring UX
TASK_291 - Editor Terrain Visual Recovery Coordinator (implementiert)
TASK_292 - Editor Hill Cliff Grid Depth Repair (implementiert)
TASK_293 - Editor Lighting Shadow Readability Pass (implementiert)
TASK_294 - Nature Prop Scale Cover Visibility Repair (implementiert)
TASK_295 - Map Editor Paint Toolbar Tools Polish (implementiert)
TASK_296 - Map Editor Palette Taxonomy Space Station Assets (implementiert)
TASK_297 - Map Editor Inspector Collapsible Panels (implementiert)
TASK_298 - Editor Terrain Visual Playability Smoke (implementiert)

Phase 18X - Meta Userology Main Menu FOB Transfer UX
TASK_299 - Team Identity Name Generation Userology (implementiert)
TASK_300 - App Shell Return To Main Menu Navigation (implementiert)
TASK_301 - NPC Card Drag Z-Order Badges Tooltips (implementiert)
TASK_302 - Dropship Flight Deck Boarding Rename Userology (implementiert)
TASK_303 - FOB Transfer Dragdrop Card Readability (implementiert)
TASK_304 - Unified Transit Progress Ghosting Homebase FOB (implementiert)
TASK_305 - Fireteam Staging Copy Cohesion Status (implementiert)
TASK_306 - Meta Userology Playability Smoke (implementiert)

Phase 18Y - FOB VB Flightdeck Fireteam Assignment UX
TASK_307 - FOB Arrivals Unassigned Operator Pool (implementiert)
TASK_308 - Compact Flightdeck Dropship Occupants Actions (implementiert)
TASK_309 - Fireteam Assignment Board Compact Frames (implementiert)
TASK_310 - FOB Flightdeck Fireteam Userology Smoke (implementiert)

Phase 18Z - Dropship LZ Command Matrix Targeting Feedback
TASK_311 - Dropship LZ Target Pick Accuracy Contract (implementiert)
TASK_312 - Dropship Command Matrix LZ Go Layout (implementiert)
TASK_313 - Dropship Arrival Visibility Feedback Smoke (implementiert)

Phase 18ZA - FOB Fireteam Assignment Visibility Fix
TASK_314 - FOB NPC Pool Window Left Of Fireteams (implementiert)

Phase 18ZB - Mission Grid Tile Selection Visibility Fix
TASK_315 - Mission Grid Tile Selection Command Gate (implementiert)

Phase 18ZC - FOB Fireteam Staging Migration
TASK_316 - FOB Fireteam Staging Migration (implementiert)

Phase 18ZD - Manual Playtest Followups Backfill
TASK_317 - Manual Playtest Mission Fireteam FOB Payload and Bubbles (implementiert)
TASK_318 - Manual Playtest Debrief Background and Main Menu Team Library (implementiert)
TASK_319 - Manual Playtest FOB Second Dropship Assignment and Scale (implementiert)
TASK_320 - Manual Playtest Dropship Cards Per-Craft Dispatch and Return (implementiert)
TASK_321 - Manual Playtest Map Editor Station Floor Layering Undo (implementiert)
TASK_322 - Manual Playtest Map Editor Asset Import Rotation Context Menu (implementiert im Arbeitsstand)
TASK_323 - Manual Playtest Mission Command Visuals Fire Sector Dropships (implementiert im Arbeitsstand)
TASK_324 - Manual Playtest Team Editor Character Overlay Usability (implementiert im Arbeitsstand)
TASK_325 - Manual Playtest Documentation Backfill (implementiert)
TASK_326 - Manual Playtest Multiplayer Setup Asset Catalog Floor Followup (implementiert im Arbeitsstand)
TASK_327 - Manual Playtest Right Click Orders Tactics Dropship Visibility (implementiert im Arbeitsstand)
TASK_328 - Manual Playtest Marker Help Roster UPnP Followup (implementiert im Arbeitsstand)

Phase 18ZE - Manual Playtest Stabilization and Docs Truth Fix
TASK_329 - Manual Playtest Stabilization GDD Godot Fix Pass (implementiert im Arbeitsstand)

Phase 18ZF - Architecture Performance UX Followups
TASK_330 - Mission Runtime Scripts Productization Followup (implementiert im Arbeitsstand)
TASK_331 - Mission Tactical Controller Adapter Split First Slice (offen)
TASK_332 - Terrain Map Frame Budget Proxy Sync Pass (offen)
TASK_333 - Navigation Fallback Budget Contract Alignment (offen)
TASK_334 - Drop Light Layout Profiles Compact Resolution (offen)
TASK_335 - Tactical Feedback Truth Command Clarity Pass (offen)
TASK_336 - Combat Loop Tick Budget System Split (offen)
TASK_337 - Architecture Performance UX Followup Gate (offen)

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
