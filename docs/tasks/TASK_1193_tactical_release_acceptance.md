# TASK_1193 - Tactical Release Acceptance Gate

## Status: IMPLEMENTIERT - RELEASE BLOCKIERT

## Ziel / Problem

Die bisherigen Tests belegen einzelne Gameplay-, Architektur- und
Performance-Contracts, aber sie liefern keine gemeinsame, ehrliche
Release-Entscheidung. Insbesondere ist 256x256 nur logisch profiliert und
manuelle Fenster-/Spieler-Evidenz darf nicht durch eine Fixture ersetzt werden.

## Entscheidung

- `128x128` ist die groesste automatisiert unterstuetzte Release-Kandidatenkarte.
- `256x256` bleibt logisch erreichbar, aber ohne vollstaendige Viewport-Abnahme
  nicht release-faehig.
- Eine Release-Freigabe verlangt gruenes automatisches Enforcer-Ergebnis und
  eine reale, SHA-gebundene 128x128-Manuell-Evidenz.

## Umfang

- TASK_411 liefert eine explizite Release-Kandidaten-Skalenentscheidung.
- Der Performance-Budgetvertrag und die manuelle Profil-Checkliste enthalten
  die harte 128x128-Grenze sowie die menschliche Abnahme.
- `run_task_1193_tactical_release_acceptance.ps1` startet die vorhandenen
  Enforcer, wertet die taktischen Budgetstatus aus und endet mit Fehler, wenn
  ein Enforcer, ein Budget oder die manuelle Evidenz fehlt.

## Nicht-Ziele

- Keine Budgetanhebung und keine neue Performance-Optimierung.
- Kein generiertes oder automatisch als menschlich ausgegebenes Playtest-Protokoll.
- Keine 256x256-Freigabe.

## Akzeptanzkriterien

- Der Runner kann nicht bei rotem Enforcer-Ergebnis erfolgreich enden.
- `synthetic_fixture`-Evidenz gilt nicht als manuelle Playtest-Evidenz.
- Die manuelle Evidenz ist SHA-, Karten- und Szenario-gebunden und muss von
  einem Menschen vorliegen; ihr Fehlen blockiert die Freigabe.
- Die Dokumentation trennt „Gate implementiert“ klar von „Release freigegeben“.

## Lokale Pruefung

- `scripts/tests/task_1193_tactical_release_acceptance.gd`
- `scripts/tests/run_task_1193_tactical_release_acceptance.ps1`
- TASK_411, TASK_1187, TASK_1192, TASK_284, TASK_832 und TASK_868
- `git diff --check`

## Ergebnis

- Der Gate startete TASK_1179, TASK_1192, TASK_284, TASK_832, TASK_868,
  TASK_411, TASK_222 und die taktische TASK_1187-Messung. Alle acht Enforcer
  selbst endeten erfolgreich.
- Der reale Gate-Lauf auf `d86c7f2fa0ea6487464c30dd526ef2555c130674` bleibt
  dennoch `blocked`: Combat-p99 110,940 ms (Ziel 8 ms),
  Simulation-p99 112,198 ms (Ziel 8 ms) und LZ-Input-p95 156,668 ms
  (Ziel 100 ms) waren ueberschritten.
- Es liegt keine echte, SHA-gebundene 128x128-Manuell-Evidenz vor.
  Der Runner erzeugt sie nicht; `synthetic_fixture=true` wird explizit nicht
  als Ersatz akzeptiert. Daher ist der Gate implementiert, aber keine
  Release-Freigabe erteilt.
