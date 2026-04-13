# TASK 001 – RuntimeLeader / FTL-Komponente

## Ziel
Eine saubere RuntimeLeader-Komponente als FTL-Kern einführen.

## Pflicht vor Beginn
- Lies `docs/PROJECT_BRIEF.md`
- Lies `docs/ARCHITECTURE.md`
- Lies `docs/CODEX_RULES.md`
- Prüfe den Git-Status
- Arbeite im lokalen Projekt `C:\dev\SternenBuergerchen`

## Aufgabe
- Erstelle eine eigene Node-/Script-Komponente für den FTL.
- Implementiere mindestens:
  - `promote()`
  - `demote()`
  - `assign(entity)`
  - `command(order)`
- Verwende Signale für:
  - promoted
  - demoted
  - assigned
  - command_issued
- Halte die API klein und klar.
- Keine direkte UI-Logik.
- Keine SceneTree-Suchen für die Kernlogik.

## Nicht-Ziele
- keine vollständige KI
- keine Combat-Logik
- kein Multiplayer
- kein HUD-Ausbau

## Akzeptanzkriterien
- RuntimeLeader existiert als eigene Komponente
- API ist vorhanden
- Signale sind vorhanden
- keine offensichtliche Direktkopplung an UI
- lokale Prüflogik dokumentiert

## Git-Schritte nach lokaler Prüfung
- `git status`
- `git add` nur relevante Dateien
- `git commit -m "Add RuntimeLeader FTL component"`
- `git push`
- `docs/IMPLEMENTATION_STATUS.md` aktualisieren
