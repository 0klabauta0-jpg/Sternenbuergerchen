# Neustart-Arbeitsregeln

Dieses eigenständige Projekt setzt den am 12.09.2026 bestätigten Neustart um. Das Altprojekt und seine Worktrees bleiben erhalten. Vor Änderungen `docs/PROJECT_BRIEF.md`, `docs/ARCHITECTURE.md`, `docs/IMPLEMENTATION_STATUS.md` und den aktuellen Task lesen.

- Godot 4.6.2, expliziter Enginepfad aus `tools/run.ps1`.
- Nur SimulationRoot bestätigt Änderungen. UI, Weltansicht und Netzwerkclient senden Befehle oder lesen Snapshots.
- Stabile IDs; Geld, Material, Arbeitsplätze und Crewverfügbarkeit gemeinsam und genau einmal verbuchen.
- Kleine Module; kein produktiver Controller in Tests. Kenney-Quellen unverändert erhalten, Lizenzkopien mitführen.
- Konkrete Spielerwege, Save-/Transaktionsintegrität und echte Fensterläufe prüfen. Netzwerk benötigt zwei echte Prozesse.
- Nur eigene Dateien stagen. Auf `codex/`-Branches arbeiten, nach bestandener Prüfung committen und auf den eigenen Branch pushen. Nicht in main oder integration mergen.

