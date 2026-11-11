# Hex-Facing und restliche AP3-Sichtverbraucher

## Status

Owner und Consumer hinter dem Versionsgate implementiert. Kleine Cases:
Facing24/0, Security34/0, Consumer39/0; finale Quellenbindung/Integration
gesondert dokumentiert in docs/qa/hex_facing_security_20261111.
Frischer Review: Projektionsrand, Kontextrest, veraltete Richtungsdeckung,
gleiche-Tick-Absichten und Halbsektorverteilung mit RED/GREEN abgesichert.
Keine Karte aktiviert. Sandboxhooks zunächst statisch geprüft; keine native
Missions-/GPU-/Performanceabnahme. Producerlücke und Bewegungsmalus bleiben
im Contract ausdrücklich gekennzeichnet.

## Ziel / Ursache

Den gesicherten Reader-Zwischenschritt2a0ffeef8 um autoritative Blickabsichten,
Sicherung, Overwatch und Flankierungsleser ergänzen. Ein durchgehend aktiver
Hexmodus braucht diese Consumer vor einer Kartenaktivierung; andernfalls
würden aktuelle Sicht und Sicherungs-/Reaktionsauswertung auseinanderlaufen.

## Umfang und Nicht-Ziele

SimulationRoot besitzt die wartenden Facingabsichten und committet sie vor
den Sichtverbrauchern eines Ticks. Logische Unitrichtung bleibt nur im
HexGroundRuntime. Interne Sicherungsaufträge haben Vorrang vor freien
Geräuschreaktionen; geänderte Aufträge/Mapkontexte verwerfen veraltete
Absichten. Geräusche liefern höchstens einen Reaktionshinweis, keinen
bestätigten Feind. Vorhandene Skill-/Auftragsregeln wiederverwenden; fehlenden
Gameplay-Geräuschproducer offen dokumentieren, keine neue Geräuschphysik.

Alle betroffenen Legacyzweige behalten bisherige Semantik. Keine Karte
aktivieren, keine neue Waffenbalance, keine Reservierungs-/Bewegungsarbeit
AP4/5 oder Lifecycle-/Savearbeit AP6/7 in diesem Schritt. Große Tests/AP9 später.

## Verträge und Zuständigkeit

- docs/superpowers/plans/2026-11-11-hex-sight-occupancy.md, restliches AP3
- docs/dev/hex_tactical_runtime_contract.md
- docs/dev/explicit_hex_ramps_contract.md
- docs/dev/contact_report_contract.md

Besitz: SimulationRoot und neue core/tactical-Helper. Der Kartenchat hat
MissionTestSetup sowie zwei enge Hooks im MissionTacticalSandboxController
ausdrücklich für diesen Anschluss freigegeben; keine parallele Bearbeitung.
Basis, Polisa, Supply, Save, Orbit und Editor bleiben dort.

## Akzeptanz

- Sicht liest die im Simulationsowner committete Richtung; Visual-Metadaten
  setzen keine zweite logische Blickrichtung.
- Replays/gleiche Absicht erzeugen keine doppelte Mutation, ungültige oder
  veraltete Absichten verändern keine Unit.
- Sicherung benutzt zugelassene Zellmitten und individuelle Kegel; eine
  360°-Truppsicherung macht keinen Einzel-NPC allsehend.
- Overwatch liest logische Feldwechsel und dieselbe aktuelle Sichtquery;
  reine Renderbewegung löst keinen Schuss aus.
- Flankierung liest logische Zellmitten und dieselben Sicherungszuweisungen.
- Noise-/Reaktionshook hält Auftrag und bestehende Skillkadenz ein und
  publiziert keinen bestätigten Kontakt allein aus dem Hinweis.

## Dateien / lokale Prüfung

SimulationRoot, HexGroundRuntime, HexSightRuntimeAdapter, die drei Tactical-
Resolver, CombatLoopDriver sowie die zwei abgestimmten Securityhooks im
MissionTacticalSandboxController. Kleine isolierte Cases im bestehenden
run_hex_tactical_check.py; neue RED/GREEN-Fixtures vor Implementierung.
Keine vollständige Szene, keine große Matrix und kein Performanceversprechen.

## Risiken / offene Punkte

Bestehende Sicherungswinkel sind Weltprojektion; Umrechnung in Hexrichtung
muss dieselbe Registrymetrik berücksichtigen. Eigene Halbhöhen der Rampen
bleiben unverändert. Vollständige Aktivierung hängt weiterhin an AP4–8.
