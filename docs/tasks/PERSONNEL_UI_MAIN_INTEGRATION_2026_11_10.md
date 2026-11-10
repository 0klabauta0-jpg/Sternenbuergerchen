# Personal-/Basis-UI nach Main integrieren — 10.11.2026

## Ziel / Ursache
Nutzer beauftragt die Mainintegration des geprüften gemeinsamen Charakterbogens
und seiner noch nicht integrierten Vorgängerschritte.

## Umfang / Nicht-Ziele
Aktueller Main/origin/main 1e3cca237; Kandidat 2ea460017 (fünf direkte Nachfolger:
5df2d3b6f, 9c87a06ef, 0c7510f79, e004843e7, 2ea460017).
Vorbereitung auf task/personnel-ui-main-integration-20261110, danach geprüfter
Fast-forward von Main. Keine zusätzliche Produktänderung, keine EXE, keine
Spielstand-/Teamänderung und keine Bereinigung fremder Arbeitsverzeichnisse.

## Contracts / Dateien
PROJECT_BRIEF, ARCHITECTURE, CODEX_RULES, IMPLEMENTATION_STATUS, TASK_ROADMAP;
docs/dev/homebase_direct_dropship_flow_contract.md und die fünf Task-/QA-Nachweise.
Nur Integrationsdokumentation in dieser Runde; bestehende Produktdateien unverändert.

## Akzeptanz / lokale Prüfung
Main ist Vorfahr des Kandidaten, kein divergierender Remote-Commit, keine
Produktkonflikte. Frischer nativer tatsächlicher Satellitenausflug, gemeinsame
Charakter-/Inventarcommands, Auftragsfolge/Heimupload, dazu gezielte UI-/Profil-
und drei Skirmish-Startprüfungen. Rohlogs mit isolierten Testprofilen dokumentieren.
Produktbaum nach Integration identisch zu 2ea460017; origin/main entspricht lokalem
Main nach normalem Push. Bestehende Worktrees und Nutzerspielstände erhalten.

## Risiken / offene Punkte
Native versteckte Hostfenster prüfen Rendering und Commands, keine ästhetische
Nutzerabnahme oder allgemeine Performancefreigabe. Alte Basistestabweichungen
sind separat dokumentiert; kein vollständiger Altverifier-/Multiplayerlauf.
Neue EXE ist ein eigener beauftragter Folgeschritt.

## Ergebnis
Frischer nativer Satellitenausflug102/0, Basisfenster111/0, Compact25/0 und
Skirmishstarts209/0. Native Enginefehler0; zwei bekannte UID-Pfadfallbacks.
Produktbaum unverändert zu 2ea460017. QA und Nachweisgrenzen:
docs/qa/personnel_ui_main_integration_20261110/README.md.
