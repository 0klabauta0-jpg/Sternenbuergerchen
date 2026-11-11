# SPACE_COMBAT_2026_11_11_PLAN

## Ziel / Problem

Das vom Nutzer bestätigte Weltraumkampf-Konzept dauerhaft festhalten und einen
konkreten, kleinen und prüfbaren Umsetzungsplan erstellen. Die bisherige
Raumbegegnung ist ein begrenzter Ablauf mit festem Schaden; allgemeiner
Rottenkampf, freier Raumflug und wirksame Schiffskomponenten fehlen.

## Sinnhaftigkeit / Ursache

Die Sternkarte und Fireteam-Bediengrammatik sind vorhanden. Ohne festgelegte
Grenzen drohen doppelte Reise-/Kampfpositionen, UI-eigene Rottenzustände,
unbegrenzte Eskorteverfolgung und rein kosmetische Ausweichmanöver.
Die Planung trennt Nutzerentscheidungen, technische Zuschnitte und Balance.

## Umfang und Nicht-Ziele

Dokumentation von Rotten mit1–6Schiffen, gemeinsamen Aufträgen, einer
Kampfebene/2,5D, gekoppelt/ausgekoppelt, J-Hook und weiteren sichtbaren
Manövern, Pilotenskill, Repeatern, Waffen/Schild/Kraftwerk und VFX.
21 kleine Pakete AP00–AP20 mit Abhängigkeiten, Schnittstellen, konkreten
Prüffällen und fünf Meilensteinen.

Dieser Task ändert keinen Gameplaycode, erzeugt keine Assets/EXE, startet
keine Engine-/Performance-/Mehrspielertests und integriert nicht nach Main.

## Arbeitsbasis

Eigener Branch `task/space-combat-plan-20261111`, bewusst auf dem noch
nicht integrierten nativen Taskstand
`84dd481b187299d3832ded3596bbc01dfd62abe9`.
Die aktuelle native Sternkarte, Reiseowner und Komponentengrenze liegen dort;
`integration/core-foundation` enthält diesen aktuellen Anschlussstand nicht.
Vor Implementierung verlangt AP00 einen erneuten Abgleich mit den laufenden
Ground-/Lifecycle-/Kampagnenarbeiten.

## Relevante Contracts / Dokumente

- [Konzept](../dev/space_combat_contract.md)
- [Plan](../superpowers/plans/2026-11-11-space-combat.md)
- [Architektur](../ARCHITECTURE.md)
- [Fireteam-Verhalten](../dev/fireteam_behavior_modes_contract.md)
- [Commander-Delegation](../dev/commander_fireteam_delegation_contract.md)
- [Orbitreise](../dev/orbit_quantum_travel_contract.md)
- [Polisa-Komponenten](../dev/polisa_ship_equipment_contract.md)
- [Grafikreferenzvertrag](../dev/graphics_reference_revision_contract.md)

## Akzeptanzkriterien

- [x] Alle bestätigten Entscheidungen als F01–F16 nachvollziehbar enthalten.
- [x] F01–F16 jeweils konkreten AP zugeordnet.
- [x] Aufträge/Haltung/Feuerregel, Position/Bugrichtung sowie Gameplay/VFX getrennt.
- [x] Gemeinsamer Motionowner, Gegneraufnahme, Komponentenconsumer,
      Heimatcheckpoint, Authority und einmaliger Fortschritt konkret geplant.
- [x] APs besitzen Dateien, Schnittstellen, Abhängigkeiten, kleine Prüfungen
      und ein unabhängig bewertbares Ergebnis.
- [x] Bestehende relevante Pfade und Dokumentlinks geprüft; neue Pfade
      ausdrücklich als geplant gekennzeichnet.
- [x] Status/Roadmap als Planung aktualisiert; keinerlei Implementierung behauptet.
- [x] Begrenzter unabhängiger Dokumentreview und `git diff --check` abgeschlossen.

## Betroffene Dateien

- `docs/dev/space_combat_contract.md` (neu)
- `docs/superpowers/plans/2026-11-11-space-combat.md` (neu)
- diese Task-Datei (neu)
- `docs/IMPLEMENTATION_STATUS.md` (kleiner Statuseintrag)
- `docs/TASK_ROADMAP.md` (kleiner Planhinweis, keine Prioritätsänderung)

## Lokale Prüfung

Dokumentprüfung abgeschlossen:16/16Festlegungen zugeordnet,21AP in Reihenfolge,
18lokale Links und27bestehende Anschluss-/Prüfdateien vorhanden; keine
offenen Codefences. Jeder AP enthält Dateien, Interface, prüfbare Schritte
und Abnahme. `git diff --check` ohne Befund. Keine Engine gestartet.

Zwei begrenzte unabhängige Reviews fanden acht konkrete Lücken. Behoben:
Kontaktreaktion im Schema, vollständige Commandoperationen, Manöverowner,
Ereignisgeometrie, echter Physiktakt statt Renderdelta, gemeinsame Flight-
Objektidentität, Stückwaren-/Containermodell und gefilterte Clientpayloads.
Gezielte Nachprüfung der vier Owner-/Integrationskorrekturen: PASS ohne
wesentlichen Restbefund. Das ist ein Dokumentreview, keine Runtimeabnahme.

## Risiken / offene Punkte

Der native Quellstand ist separat und bewegt sich durch andere Tasks.
AP00 muss Integration und aktuelle Owner erneut prüfen. Schiffs-/Waffenbalance,
Manöverparameter, Effektbudgets und technische Prüfzahlen sind Startannahmen.
Native Schönheit/Bedienung, Performance und Multiplayer bleiben spätere
getrennte Nachweise. Bestehende Einschränkung auf Heimatcheckpoints bleibt.

## Git- und Abschlussstatus

Doku-Branch auf vorgenannter Basis; nur die fünf genannten Markdown-Dateien
gehören zum Abschlusscommit. Commit-/Pushbeleg stehen in Git und Abschlussantwort.
Der managed Worktree wurde durch die App angelegt, konnte nach hängender
AGENTS.override-Metadatensuche jedoch nicht als Chat-Anhang registriert werden.
Der vollständig ausgecheckte und saubere Git-Worktree wird explizit verwendet;
andere Arbeitsstände werden nicht verändert.
