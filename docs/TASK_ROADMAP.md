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
```

Bei Batch-Arbeit:

```bash
git checkout integration/core-foundation
git checkout -b batch/<batch-name>
```

## Task-Hygiene
- Nicht-triviale Aenderungen brauchen eine konkrete Task-Datei unter `docs/tasks/`.
- Task-Dateien nennen relevante Contracts und Dokumente explizit.
- Review-Befunde werden vor dem Task gegen den aktuellen Code geprueft.
- Gameplay-Wahrheit bleibt bei Simulation/Runtime/Contracts/Registries; UI-Tasks duerfen keine zweite Wahrheit einfuehren.
- Hotpath-Tasks muessen SceneTree-Vollscans und per-frame Komplett-Rebuilds vermeiden.

## Aktueller Station-Route-Abnahmeblock
- TASK_721 - Station Route Two-Window Visual Findings (implementiert)
- TASK_722 - Station Route HUD Visual Polish (implementiert)
- TASK_723 - Station Route Host/Client Recapture Review (implementiert)
- TASK_724 - Station Route Recapture Visual Followup (implementiert)
- TASK_725 - Station Route Host/Client Recapture Acceptance Review (implementiert)
- TASK_726 - One-Screen Multiplayer Station Scenario Drill (implementiert)
- TASK_727 - Station Scenario F6/Host Client Playtest Notes (implementiert)
- TASK_728 - Station Scenario Playtest Findings (implementiert)
- TASK_729 - Station Scenario Visible Playtest Run Packet (implementiert)
- TASK_730 - Station Scenario Targeted Playtest Polish (implementiert)
- TASK_731 - Station Scenario Workbench Export Review (implementiert)
- TASK_732 - Station Scenario Route Cue Polish (implementiert)
- TASK_733 - Station Scenario HUD Overlap Pass (implementiert)
- TASK_734 - Station Scenario Performance Feel Pass (implementiert)
- TASK_735 - Station Scenario Current Report Sync Guard (implementiert)
- TASK_736 - Station Scenario Command Feedback Polish (implementiert)
- TASK_737 - Station Scenario Visible Cue Run Packet Refresh (implementiert)
- TASK_738 - Station Scenario Identity Cue Visibility Polish (implementiert)
- TASK_739 - Station Scenario Identity Cue Recapture Findings (implementiert)
- TASK_740 - Scenario Harness Modernization (geparkt; nur bei belegten Harness-Problemen)
- TASK_741 - Station Scenario Workbench Recapture Prefill (implementiert)
- TASK_742 - Station Scenario Cargo Endgame Cue Polish (implementiert)
- TASK_743 - Station Scenario Debrief Handoff Cue (implementiert)
- TASK_744 - Station Scenario Meta Debrief Route Smoke (implementiert)
- TASK_745 - Station Scenario Post Debrief Homebase Readability (implementiert)
- TASK_746 - Station Scenario Homebase Next Sortie Readiness (implementiert)
- TASK_747 - Station Scenario Homebase Visible Readiness Review (implementiert)
- TASK_748 - Station Scenario Homebase Readiness Visual Polish Findings (implementiert)
- TASK_749 - Station Homebase Follow-up Microcopy Polish (implementiert)
- TASK_750 - Station Homebase Host/Client Recapture Packet (implementiert)
- TASK_751 - Station Homebase Capture Metadata Hook (implementiert)
- TASK_752 - Station Homebase Recapture Workbench Prefill (implementiert)
- TASK_753 - Station Homebase Recapture Review Gate (implementiert)
- TASK_754 - Station Homebase Recapture Findings (implementiert)
- TASK_755 - Station Homebase Return Panel Polish (implementiert)
- TASK_756 - Station Homebase Real Window Recapture (implementiert)
- TASK_757 - Station Homebase Recapture Findings Refresh (implementiert)
- TASK_758 - Station Homebase Return Acceptance Review (implementiert)
- TASK_759 - Station Slice Next Playtest Target (implementiert)
- TASK_760 - Station Reentry Playtest Run Packet (implementiert)
- TASK_761 - Station Reentry Visible Playtest Findings (implementiert)
- TASK_762 - Station Reentry Targeted Polish (implementiert)
- TASK_763 - Station Reentry Fireteam Staging Polish (implementiert)
- TASK_764 - Station Reentry Loadout Bridge Polish (implementiert)
- TASK_765 - Station Reentry Dropship Boarding Bridge Polish (implementiert)
- TASK_766 - Station Reentry Start Permission Bridge Polish (implementiert)
- TASK_767 - Station Reentry Visible Playtest Review Gate (implementiert)
- TASK_768 - Station Reentry First Mission Preview Polish (implementiert)
- TASK_769 - Station Reentry Performance Feel Pass (implementiert)
- TASK_770 - Station Reentry Host Client Next Order Sync (implementiert)
- TASK_771 - Station Reentry Visible Host Client Playtest Export (implementiert)
- TASK_772 - Station Reentry Host Client Export Findings (implementiert)
- TASK_773 - Station Reentry Host Client Identity Cue Polish (implementiert)
- TASK_774 - Station Reentry Next Playable Slice Acceptance (implementiert)
- TASK_775 - Station Reentry Mission Interaction Feel Pass (implementiert)
- TASK_776 - Station Reentry Contact Pressure Feel Pass (implementiert)
- TASK_777 - Station Reentry Firefight Tension Feel Pass (implementiert)
- TASK_778 - Station Reentry Firefight Visual Playtest Packet (implementiert)
- TASK_779 - Station Reentry Firefight Visual Findings (implementiert)
- TASK_780 - Station Reentry Firefight Interaction Polish (implementiert)
- TASK_781 - Station Reentry Firefight Command Surface Recapture (implementiert)
- TASK_782 - Station Reentry Firefight Command Surface Findings (implementiert)
- TASK_783 - Station Reentry Firefight Command Surface Polish (implementiert)
- TASK_784 - Station Reentry Firefight Command Surface Playtest Packet Refresh (implementiert)
- TASK_785 - Station Reentry Firefight Command Surface Visible Findings Refresh (implementiert)
- TASK_786 - Station Reentry Firefight Host Client Polished Surface Check (implementiert)
- TASK_787 - Station Reentry Firefight Player Decision Readability Pass (implementiert)
- TASK_788 - Station Reentry Firefight Decision Evidence Packet (implementiert)
- TASK_789 - Station Reentry Firefight Decision Evidence Findings (implementiert)
- TASK_790 - Station Reentry Firefight Decision Polish Acceptance (implementiert)
- TASK_791 - Station Reentry Firefight Decision Host Client Recapture (implementiert)
- Naechster Schritt: TASK_792 - Station Reentry Firefight Decision Host Client Findings.

## Aktueller Fireteam-Arbeitsblock
- TASK_414 - Fireteam Overview HTML
- TASK_415 - Fireteam Runtime Execution Path Switch
- TASK_416 - Fireteam Command Drill Map
- TASK_417 - Fireteam Waypoint Completion Cleanup
- TASK_418 - Fireteam Mini Card Suppression Explainer
- TASK_419 - GO Recovery Action And NPC Speed
- TASK_420 - Waypoint Completion Area Followup Hotfix
- TASK_421 - Move Stance Posture Speed Sight
- TASK_422 - GO Continue Fireteam HUD Cleanup
- TASK_423 - Normal Move Parallel Spacing
- TASK_424 - Fireteam Drill Enemy Visibility Grounding
- TASK_425 - Live Move Stance Update
- TASK_426 - Cautious Move Parallel Aim
- TASK_427 - Fireteam Decision Feedback Aim Pose
- TASK_428 - Fireteam Behavior Control List
- TASK_429 - Fireteam Behavior Modes Runtime
- TASK_430 - Fireteam Task Corruption Repair
- TASK_431 - Fireteam Aim Pose And Card UI Hotfix
- TASK_432 - Fireteam Muzzle Flash And Baseline Attack Movement
- TASK_433 - Install Third Party Godot Plugins
- TASK_434 - LimboAI Enemy Behavior Adapter Smoke
- TASK_435 - Fireteam Manual Visual Regression Pass
- TASK_436 - Fireteam Sight Security Visuals
- TASK_437 - Fireteam Selection Patrol Contact Pass
- TASK_438 - Fireteam Contact Visibility Attack Visuals
- TASK_439 - Fireteam Runtime Map Flow Limbo Review
- TASK_440 - Enemy Limbo Contact Diagnostics
- TASK_441 - Fireteam Map Tool Drill Rebuild
- TASK_442 - Fireteam Engage Behavior Control
- TASK_443 - Fireteam Take Behavior Control
- TASK_444 - Fireteam Behavior Playtest Workbench HTML
- TASK_445 - HTML Report Workbench Standard
- TASK_446 - Fireteam Workbench Spacing Runtime Pass
- TASK_447 - Fireteam Contact Initiative Rules
- TASK_448 - Fireteam Workbench Profile Clarity
- TASK_449 - Fireteam Distance CNA Workbench Rules
- TASK_450 - Fireteam Stance Command Preset Workbench
- TASK_451 - Fireteam Workbench Runtime Import
- TASK_452 - Fireteam Runtime Baseline Visual Contact Pass
- TASK_453 - Fireteam Terrain LOS Sequence Direction Audit
- TASK_454 - Terrain Truth Visual Audit
- TASK_455 - Terrain Truth Editor Overlay Visibility
- TASK_456 - Wall Segment LOS And Tile Truth Inspector
- TASK_457 - Fireteam Contact Engage Runtime Pass
- TASK_458 - Fireteam Contact Decision Diagnostics
- TASK_459 - Fireteam Engage Orientation Enemy Proxy Fix
- TASK_460 - Fireteam Movement Avoidance Stability
- TASK_461 - Fireteam Engage Visual Stuck Hotfix
- TASK_462 - Fireteam Auto Defend Completion Release
- TASK_463 - Fireteam Auto Defend Guard And Enemy Model Visibility
- TASK_464 - Fireteam Contact Scan Fire Feedback Readability
- TASK_465 - Fireteam Engage Resume Contact Progress
- TASK_466 - Fireteam Live Defend Contact Fire Damage
- TASK_467 - Fireteam Engage Contact Halt Fire
- TASK_468 - Fireteam Engage Live Command Conflict Audit
- TASK_469 - Fireteam F6 Drill Combat Config
- TASK_470 - Fireteam CombatLoop Unit Bridge Recovery
- TASK_471 - Fireteam Weapon Fire VFX Hit Feedback Perf
- TASK_472 - Fireteam Contact Performance Bubble Card Readability
- TASK_473 - Fireteam Combat Feedback Runtime Overhaul
- TASK_474 - Fireteam Down VFX Performance Stabilization
- TASK_475 - Fireteam Pathfinding Avoidance Stability Pass
- TASK_476 - Fireteam Corridor Lane Cover Navigation
- TASK_477 - Fireteam Contact Cover Decision V1
- TASK_478 - Fireteam Soft Completion Final Stage Guard
- TASK_479 - Fireteam Runtime Hotpath Guards
- TASK_480 - Mission UI Hotpath Feedback Guard
- TASK_481 - Loadout Heavy Weapon Selection
- TASK_482 - Mission Briefing Data Contract
- TASK_483 - Map Editor Asset Workflow Polish
- TASK_484 - Map Editor Palette Browser Layout
- TASK_485 - Map Editor Save As and Modular Scale Fix
- TASK_486 - Map Builder Tooling Spike
- TASK_487 - Install Godot Asset Placer
- TASK_488 - Map Builder Workbench MeshLibrary MVP
- TASK_489 - Map Builder Workbench Editor Entry
- TASK_490 - Map Builder Paint Tools MVP
- TASK_491 - Map Editor Runtime Builder Workbench
- TASK_492 - Map Editor Network Drag Snap Tools
- TASK_493 - Map Editor Station Builder Focus
- TASK_494 - Station Outpost 64x64 Map
- TASK_495 - Mission Combat Driver Boundary Review
- TASK_496 - Mission Combat Registry and Elimination Hotfix
- TASK_497 - Mission TestSetup Reference Cleanup
- TASK_498 - Runtime Script Layout Alignment
- TASK_499 - Review Followup Architecture Cleanup
- TASK_500 - Gameflow Spine Hardening
- TASK_501 - Integrated Movement Command Lifecycle Hardening
- TASK_503 - Mission Dropship Fireteam HUD Truth
- TASK_504 - Startmap Expansion Performance Pass
- TASK_505 - Frontier Probe Large Map Playtest Hotfix
- TASK_506 - Tactical Decision Clarity Contract (implementiert)
- TASK_507 - Order Preview Ghosts MVP (implementiert)
- TASK_508 - Line-of-Fire / Threat Analyzer MVP (implementiert)
- TASK_509 - Combined Preview Overlay (implementiert)
- TASK_510 - Contact Report Upgrade (implementiert)
- TASK_511 - Export Runtime Package Hygiene (implementiert)
- TASK_512 - Mission Controller Boundary Slice (implementiert)
- TASK_513 - Mission Combat Resolution Boundary (implementiert)
- TASK_514 - Enemy Behavior Orchestrator (implementiert)
- TASK_515 - Combat Readability Presenter (implementiert)
- TASK_516 - Editor Builder UX Pass (implementiert)
- TASK_517 - Mission Scenario Vertical Slice (implementiert)
- TASK_518 - Mission Scenario Runtime Gates (implementiert)
- TASK_519 - Cargo Touchdown Visual/Runtime Bridge (implementiert)
- TASK_520 - Multiplayer Team Ownership Smoke (implementiert)
- TASK_521 - Builder Drag Preview Visual Polish (implementiert)
- TASK_522 - Cargo Touchdown Visual Polish (implementiert)
- TASK_523 - PvP Team Readability UI Pass (implementiert)
- TASK_524 - Export Warning Noise Cleanup (implementiert)
- TASK_525 - Team Badge / Spawn Readability Polish (implementiert)
- TASK_526 - Mission HUD Team Chip Polish (implementiert)
- TASK_527 - Briefing Minimap Team Spawn Overlay (implementiert)
- TASK_528 - Rolling HTML Status Report (implementiert)
- TASK_529 - Mission HUD Team Icon Polish (implementiert)
- TASK_530 - Briefing Panel Renderer MVP (implementiert)
- TASK_531 - Briefing Minimap Visual Renderer (implementiert)
- TASK_532 - Briefing Background / Loadout Recommendation Polish (implementiert)
- TASK_533 - Recommended Loadout Selection Bridge (implementiert)
- TASK_534 - Pre-Mission Readiness Checklist (implementiert)
- TASK_535 - Pre-Mission FullHD Startflow Visual Pass (implementiert)
- TASK_536 - Startflow Icon And Status Color Polish (implementiert)
- TASK_537 - Pre-Mission F6 Screenshot Visual Audit (implementiert)
- TASK_538 - Homebase To Mission Launch Handoff Smoke (implementiert)
- TASK_539 - Mission Insertion First Order Readability Pass (implementiert)
- TASK_540 - Mission First Move Decision Readability Pass (implementiert)
- TASK_541 - Mission First Move Execution Feedback Pass (implementiert)
- TASK_542 - Mission First Contact Readability Pass (implementiert)
- TASK_543 - Mission First Engagement Feedback Pass (implementiert)
- TASK_544 - Mission Fire And Cover Visual Polish Pass (implementiert)
- TASK_545 - Mission Fire Cover Integrated Flow Smoke (implementiert)
- TASK_546 - Mission Combat Feedback HUD Density Polish (implementiert)
- TASK_547 - Multi-Fireteam Combat HUD Consistency Smoke (implementiert)
- TASK_548 - Combat HUD Visual Detail Tooltip Pass (implementiert)
- TASK_549 - Combat HUD F6 Visual Audit (implementiert)
- TASK_550 - Combat HUD Manual Screenshot Notes Pass (implementiert)
- TASK_551 - Combat HUD Tooltip Style Polish (implementiert)
- TASK_552 - Mission Objective Interaction Readability Pass (implementiert)
- TASK_553 - Mission Cargo Extract Readability Pass (implementiert)
- TASK_554 - Frontier Probe Integrated Objective Playthrough Smoke (implementiert)
- TASK_555 - Frontier Probe Multiplayer Objective Ownership Smoke (implementiert)
- TASK_556 - Frontier Probe Host Client Objective Handoff Smoke (implementiert)
- TASK_557 - Frontier Probe Multiplayer F6 Readability Pass (implementiert)
- TASK_558 - Frontier Probe Multiplayer Manual Screenshot Notes Pass (implementiert)
- TASK_559 - Factory Colormap UID Loader Guard (implementiert)
- TASK_560 - Frontier Probe Multiplayer Teamchip Tooltip Polish (implementiert)
- TASK_561 - Frontier Probe Multiplayer Manual Visual Review Guide (implementiert)
- TASK_562 - Frontier Probe Multiplayer F6 Visual Evidence Capture (implementiert)
- TASK_563 - Frontier Probe Multiplayer F6 Evidence Report Preview (implementiert)
- TASK_564 - Frontier Probe Multiplayer Apply Visual Polish Findings (implementiert)
- TASK_565 - Frontier Probe Multiplayer Real F6 Screenshot Review Pass (implementiert)
- TASK_566 - Frontier Probe Multiplayer F6 Hover And Panel Polish Pass (implementiert)
- TASK_567 - Frontier Probe First Move Threat Preview Readability Pass (implementiert)
- TASK_568 - Frontier Probe Risky Contact Preview Fixture (implementiert)
- TASK_569 - Frontier Probe Threat Preview Visual Review (implementiert)
- TASK_570 - Hold Fire Discipline Mission Bridge (implementiert)
- TASK_571 - Fire Rule Controls Readability Polish (implementiert)
- TASK_572 - Fire Rule F6 Readability Smoke (implementiert)
- TASK_573 - Fire Rule Manual Screenshot Notes Pass (implementiert)
- TASK_574 - Fire Rule Real F6 Screenshot Review Pass (implementiert)
- TASK_575 - Fire Rule Evidence Polish Findings (implementiert)
- TASK_576 - Suppress Fire Preview Readability Spike (implementiert)
- TASK_577 - Suppress Fire Visual Evidence Pass (implementiert)
- TASK_578 - Suppress Fire Visual Polish Findings (implementiert)
- TASK_579 - Suppress Fire Manual F6 Review (implementiert)
- TASK_580 - Suppress Fire Visual Tuning Findings (implementiert)
- TASK_581 - Suppress Fire Intent Outcome Smoke (implementiert)
- TASK_582 - Suppress Fire Outcome AAR Diagnostic Stub (implementiert)
- TASK_583 - Suppress Fire AAR Report Panel Readability (implementiert)
- TASK_584 - Mini AAR Combat Metrics Shell (implementiert)
- TASK_585 - Mini AAR Debrief Screen Stub (implementiert)
- TASK_586 - Debrief Return To Homebase Handoff (implementiert)
- TASK_587 - Debrief Visual Polish Pass (implementiert)
- TASK_588 - Debrief AAR Data Bridge (implementiert)
- TASK_589 - Debrief AAR F6 Visual Evidence Pass (implementiert)
- TASK_590 - Debrief AAR Layout Polish Findings (implementiert)
- TASK_591 - Debrief AAR Player Review Notes Pass (implementiert)
- TASK_592 - Debrief Skill Progress Preview Shell (implementiert)
- TASK_593 - Skill Progress Award Contract (implementiert)
- TASK_594 - Post Mission Skill Delta Homebase Bridge (implementiert)
- TASK_595 - Homebase Progression Visual Polish (implementiert)
- TASK_596 - Homebase Progression Player Review Notes (implementiert)
- TASK_597 - Homebase Progression F6 Evidence Capture (implementiert)
- TASK_598 - Homebase Progression Evidence Polish Findings (implementiert)
- TASK_599 - Integrated Core Loop Playtest Evidence Pass (implementiert)
- TASK_600 - Integrated Core Loop Flow Polish Findings (implementiert)
- TASK_601 - Core Loop Manual FullHD Playtest Capture (implementiert)
- TASK_602 - Core Loop Transition Pacing Polish (implementiert)
- TASK_603 - Mission HUD Density Interaction Polish (implementiert)
- TASK_604 - Core Loop Host Client Feel Smoke (implementiert)
- TASK_605 - Host Client F6 Visual Review Pass (implementiert)
- TASK_606 - Host Client F6 Visual Polish Findings (implementiert)
- TASK_607 - Two Instance Host Client Runtime Smoke (implementiert)
- TASK_608 - Host Client Runtime Visual Capture (implementiert)
- TASK_609 - Host Client Runtime Visual Polish Findings (implementiert)
- TASK_610 - Host Client Two Window Playtest Notes (implementiert)
- TASK_611 - Host Client Two Window Launch Helper (implementiert)
- TASK_612 - Host Client Two Window Screenshot Review (implementiert)
- TASK_613 - Host Client Two Window Visual Polish Findings (implementiert)
- TASK_614 - Host Client Two Window Real Run Review (implementiert)
- TASK_615 - Host Client Real Run Findings (implementiert)
- TASK_616 - Host Client Visible UI Real Run Review (implementiert)
- TASK_617 - Host Client Standard Window Layout Hardening (implementiert)
- TASK_618 - Host Client Standard Capture Crop Review (implementiert)
- TASK_619 - Host Client Role Peer Badge HUD (implementiert)
- TASK_620 - Host Client Badge Re-Capture Review (implementiert)
- TASK_621 - Host Client Multiplayer Feel Review Bundle (implementiert)
- TASK_622 - Host Client Command Authority Live Interaction Review (implementiert)
- TASK_623 - Host Client Authority Visual Findings (implementiert)
- TASK_624 - Host Client Live Input Feedback Review (implementiert)
- TASK_625 - Host Client Visible Reject Feedback Polish (implementiert)
- TASK_626 - Host Client Real Click Review Evidence (implementiert)
- TASK_627 - Host Client Fireteam Eventlog Overlap Polish (implementiert)
- TASK_628 - Mission HUD Legacy Contract Refresh (implementiert)
- TASK_629 - Host Client Real Click Playtest Evidence Pass (implementiert)
- TASK_630 - Frontier Probe Mini Scenario Feel Route (implementiert)
- TASK_631 - Frontier Probe Mini Scenario Visual Feel Polish (implementiert)
- TASK_632 - Frontier Probe Mini Scenario F6 Visual Review (implementiert)
- TASK_633 - Frontier Probe Callout Layout Polish (implementiert)
- TASK_634 - Frontier Probe Real F6 Callout Sight Review (implementiert)
- TASK_635 - Frontier Probe Callout Sight Findings (implementiert)
- TASK_636 - Frontier Probe Real F6 Re-Capture (implementiert)
- TASK_637 - Frontier Probe Playfeel Next Interaction (implementiert)
- TASK_638 - Frontier Probe Debrief Handoff Feel (implementiert)
- TASK_639 - Frontier Probe Meta Debrief Route Smoke (implementiert)
- TASK_640 - Frontier Probe Post Debrief Homebase Readability (implementiert)
- TASK_641 - Frontier Probe Homebase Next Sortie Readiness (implementiert)
- TASK_642 - Frontier Probe Homebase Visible Readiness Review (implementiert)
- TASK_643 - Frontier Probe Homebase Readiness Visual Polish Findings (implementiert)
- TASK_644 - Frontier Probe Homebase Real Window Review (implementiert)
- TASK_645 - Frontier Probe Homebase Summary Next Sortie Polish (implementiert)
- TASK_646 - Homebase MissionPanel Density Playfeel Review (implementiert)
- TASK_647 - Homebase MissionPanel Density Findings (implementiert)
- TASK_648 - Homebase Next Sortie Action Cue (implementiert)
- TASK_649 - Current State Handbook Report (implementiert)
- TASK_650 - Host Client Click Feedback Followup (implementiert)
- TASK_651 - Host Client Click Followup Evidence (implementiert)
- TASK_652 - Current State Handbook Refresh (implementiert)
- TASK_653 - Frontier Probe One-Screen Playability Pass (implementiert)
- TASK_654 - Frontier Probe One-Screen F6 Playtest Notes (implementiert)
- TASK_655 - Frontier Probe One-Screen Visual Tuning Findings (implementiert)
- TASK_656 - Frontier Probe Real F6 Visual Review (implementiert)
- TASK_657 - Frontier Probe F6 Visual Polish Findings (implementiert)
- TASK_658 - Frontier Probe One-Screen Player Decision Drill (implementiert)
- TASK_659 - Frontier Probe Decision Drill F6 Evidence (implementiert)
- TASK_660 - Decision Drill Snapshot Performance Budget (implementiert)
- TASK_661 - Host Client Decision Drill Click Evidence (implementiert)
- TASK_662 - Host Client Decision Drill Real Window Capture (implementiert)
- TASK_663 - Host Client Decision Drill Visual Findings (implementiert)
- TASK_664 - Host Client Decision Drill Real Click Recheck (implementiert)
- TASK_665 - Host Client Decision Drill Technical Click Guard (implementiert)
- TASK_666 - Host Client Decision Drill Real Click Findings (implementiert)
- TASK_667 - Map Editor Persistent Palette Presets (implementiert)
- TASK_668 - Map Editor Asset Scale Override Presets (implementiert)
- TASK_669 - Map Editor Placement Rotation Overrides (implementiert)
- TASK_670 - Builder Drag Preview Handles (implementiert)
- TASK_671 - Builder Chain Auto Snapping (implementiert)
- TASK_672 - FullHD Drag Preview Art Direction (implementiert)
- TASK_673 - Mission Interaction Point Contract (implementiert)
- TASK_674 - Mission Interaction Point Bindings (implementiert)
- TASK_675 - Mission Interaction Runtime Use State (implementiert)
- TASK_676 - Mission Interaction Use Feedback (implementiert)
- TASK_677 - Mission Interaction Use Intent (implementiert)
- TASK_678 - Mission Interaction Runtime Progress (implementiert)
- TASK_679 - Mission Interaction Progress Readability (implementiert)
- TASK_680 - Mission Interaction Binding Inspector (implementiert)
- TASK_681 - Mission Interaction Binding Editor (implementiert)
- TASK_682 - Mission Interaction Binding Presets (implementiert)
- TASK_683 - Map Editor Interaction FullHD Sight Pass (implementiert)
- TASK_684 - Map Editor Interaction Focus Scroll (implementiert)
- TASK_685 - Mission Interaction Objective Gate (implementiert)
- TASK_686 - Mission Interaction Visual State (implementiert)
- TASK_687 - Mission Interaction Object Reaction (implementiert)
- TASK_688 - Mission Interaction FullHD Evidence (implementiert)
- TASK_689 - Mission Interaction Visual Polish Findings (implementiert)
- TASK_690 - Mission Interaction Manual Sight Notes (implementiert)
- TASK_691 - Mission Interaction Runtime Visual Assets (implementiert)
- TASK_692 - Door Runtime Collision/LOS Contract (implementiert)
- TASK_693 - Door Runtime State Producer (implementiert)
- TASK_694 - Door Use/Breach Command Hook (implementiert)
- TASK_695 - Door Interaction HUD Button/Shortcut (implementiert)
- TASK_696 - Door Runtime Visual Animation/Asset Swap (implementiert)
- TASK_697 - Door Interaction Multiplayer Authority Check (implementiert)
- TASK_698 - Door Authority UI Feedback (implementiert)
- TASK_699 - Multiplayer Door Feedback Capture (implementiert)
- TASK_700 - Host/Client Door Real Click Workbench (implementiert)
- TASK_701 - Door Authority Feedback Polish (implementiert)
- TASK_702 - Door Authority Compact HUD Surface (implementiert)
- TASK_703 - Door Authority Button Affordance (implementiert)
- TASK_704 - Host/Client Door Real Click Findings (implementiert)
- TASK_705 - Host/Client Door Real Click Manual Run Packet (implementiert)
- TASK_706 - Mission Door Layout/Visual Polish (implementiert)
- TASK_707 - Mission Door/Computer/Cargo Smoke (implementiert)
- TASK_708 - Station Route Visual Evidence (implementiert)
- TASK_709 - Station Route Window Playtest Notes (implementiert)
- TASK_710 - Station Route Polish Readiness Findings (implementiert)
- TASK_711 - Station Route Evidence Board Visual Polish (implementiert)
- TASK_712 - Station Route Host/Client Acceptance Packet (implementiert)
- TASK_713 - Station Route Host/Client Findings (implementiert)
- TASK_714 - Station Route Multiplayer Scenario Guard (implementiert)
- TASK_715 - Station Route Empty Event Log Polish (implementiert)
- TASK_716 - Station Route Run Readout Polish (implementiert)
- TASK_717 - Station Route Real Host/Client Click Findings (implementiert)
- TASK_718 - Station Route Door/GO/Reject Visual Polish (implementiert)
- TASK_719 - Station Route Post-Polish Recheck Guard (implementiert)
- TASK_720 - Station Route Capture Recheck + Handbuch (implementiert)
- TASK_721 - Station Route Two-Window Visual Findings (implementiert)
- TASK_722 - Station Route HUD Visual Polish (implementiert)
- TASK_723 - Station Route Host/Client Recapture Review (implementiert)
- TASK_724 - Station Route Recapture Visual Followup (implementiert)
- TASK_725 - Station Route Host/Client Recapture Acceptance Review (implementiert)
- TASK_726 - One-Screen Multiplayer Station Scenario Drill (implementiert)

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
TASK_097 – Datenmodelle, engage und Ad-hoc-Vertraege (implementiert)
TASK_098 – TacticalInputController und Fireteam-Auswahl (implementiert)
TASK_099 – Wegpunktplanung, Kontextmenue und Order-Visualisierung (implementiert)
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

Phase 18ZF - Ground Mission Default Playability
TASK_344 - Ground Mission Default Enemy Visuals (implementiert)

Phase 18ZG - NPC Movement Posture Standard Behavior
TASK_345 - NPC Standard Movement Posture Policy (implementiert)

Phase 18ZH - Homebase Direct Staging FOB Bypass
TASK_346 - Homebase Direct Staging Character Popup (implementiert)

Phase 18ZI - Homebase Direct Staging Review Followups
TASK_347 - Homebase Direct Staging Start Guard (implementiert)
TASK_348 - Homebase FOB Payload State Isolation (implementiert)
TASK_349 - Homebase Direct Staging Real Flightdeck Craft Gate (implementiert)
TASK_350 - Homebase Loadout Contract Export (implementiert)

Phase 18ZJ - Homebase Direct Review Followups
TASK_351 - Homebase Direct Payload Scope Contract (implementiert)
TASK_352 - Homebase Loadout Defaults Preserve Unit Profiles (implementiert)
TASK_353 - Shared Loadout Contract Helper (implementiert)
TASK_354 - Homebase Direct Loadout Regression Matrix (implementiert)
TASK_355 - Homebase Direct UX Payload Truth (implementiert)

Phase 18ZK - MapEditor and Homebase Performance Refactor Followups
TASK_356 - MapEditor Lazy Terrain Texture Catalog (implementiert)
TASK_357 - MapEditor Height Cliff Dirty Neighborhood Cache (implementiert)
TASK_358 - MapEditor Undo Stroke Transactions (implementiert)
TASK_359 - MapEditor Dirty UI Refresh Batching (implementiert)
TASK_360 - MapEditor Mission Scenario Panel Extraction (implementiert)
TASK_361 - NPCCompactCard Readonly Profile Reference Contract (implementiert)
TASK_362 - Homebase Aircraft State Manager Extraction (implementiert)
TASK_363 - Homebase Roster Card Pool Incremental Refresh (implementiert)

Phase 18ZL - Mission Visualization Review Followups
TASK_364 - Mission Fireteam Orientation Indicators (implementiert)
TASK_365 - Tactical Event Log Data Layer (implementiert)
TASK_366 - Tactical Event Log HUD Panel (implementiert)
TASK_367 - FTL Public Readiness Snapshot Contract (implementiert)
TASK_368 - FTL Readiness Gauge (implementiert)
TASK_369 - Fireteam Status Card Enhancement (implementiert)
TASK_370 - Fireteam Member Health Status Row (implementiert)
TASK_371 - Fire Sector Security Arc Overlay Toggle (implementiert)
TASK_372 - Mission LOS Debug Overlay Toggle (implementiert)
TASK_373 - Cover Effectiveness Readout (implementiert)
TASK_374 - Objective Countdown Indicator (implementiert)
TASK_375 - Waypoint Intent Preview (implementiert)
TASK_376 - Command Validation Bubble (implementiert)
TASK_377 - Contact Density Heat Map Layer (implementiert)
TASK_378 - MapEditor Patrol Route Preview (implementiert)
TASK_379 - MapEditor Tile Property Grid Overlay (implementiert)
TASK_380 - Terrain Adjacency Solver Indicator (implementiert)

Phase 18ZM - Homebase Manual Test UX Polish
TASK_381 - Homebase Fireteam Loadout Flightdeck Polish (implementiert)
TASK_382 - Homebase Direct Mission Flightdeck Display (implementiert)
TASK_383 - Homebase Flightdeck Fireteam Card Single Owner (implementiert)
TASK_384 - Homebase Flightdeck Boarding Hotfix (implementiert)
TASK_385 - Homebase Direct Return Isolation (implementiert)
TASK_386 - Homebase Flightdeck Member Portraits (implementiert)
TASK_387 - Homebase Flightdeck Payload Polish (implementiert)
TASK_388 - Homebase Fireteam Roster Shipcard Polish (implementiert)
TASK_389 - Homebase Card Wide Drop Targets (implementiert)
TASK_390 - Homebase Direct Mission Transit Cards (implementiert)
TASK_391 - Global Escape Menu and Button SFX (implementiert)
TASK_392 - Parallel Boarding Transit Feedback (implementiert)
TASK_393 - Direct Dropship Independence LZ Vector (implementiert)
TASK_394 - Per Craft Shipcard Commands (implementiert)
TASK_395 - Manual Dropship Parallel Flow Stabilization (implementiert)
TASK_396 - Mission Dropship LZ Drop Hotfix (implementiert)
TASK_397 - Mission Dropship UX Hotfix (implementiert)
TASK_398 - Mission Dropship Outbound Command Hotfix (implementiert)
TASK_399 - Dropship Flow Contract Performance Pass (implementiert)
TASK_400 - Agent Rules Doc Refresh (implementiert)

Phase 18ZN - Facing Sightline Debug Fixture
TASK_401 - Facing Sightline Debug Map (implementiert)

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
