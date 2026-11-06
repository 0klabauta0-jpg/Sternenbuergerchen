# HUD-Projektionspass: begrenzter ReadModel-Teil

## Ziel / Problem und Ursache
Ein synchroner HUD-Aufbau liest Combat-/Decision-Projektionen mehrfach.
Das vorhandene MissionHudReadModel soll innerhalb genau dieses expliziten
Lesevorgangs Ergebnisse teilen, ohne eine zweite Gameplaywahrheit zu besitzen.
Hauptauftrag: `HUD_ARCHITECTURE_2026_11_06.md`.

## Umfang / Nicht-Ziele
Nur ReadModel, Komponentenverifier und diese Teilaufgabe. Keine Controller-,
Gameplay-, Timer-, Save-, Engine- oder Git-Aktion durch den Teilbearbeiter.
Bestehende Light-/Heavy-Revisionsvertraege bleiben erhalten.

## Dokumente
AGENTS.md, PROJECT_BRIEF, ARCHITECTURE, CODEX_RULES, IMPLEMENTATION_STATUS,
TASK_ROADMAP, runtime_script_layout_contract und mission_command_feedback_contract.

## Akzeptanzkriterien
- `begin_projection_pass()` / `end_projection_pass()` begrenzen den synchronen
  Pass; nur ein aeusserster `project(key, producer)` wird gespeichert.
- Wiederholte aeusserste Aufrufe desselben Schluessels bauen einmal. Jeder
  verschachtelte Producer umgeht den Cache; rekursive Fallbacks werden nicht
  gespeichert und ersetzen keinen bereits gespeicherten aeusseren Wert.
- Dictionary-/Array-Snapshots werden beim Speichern und Ausgeben tief kopiert.
  Weder Rueckgabeaenderungen noch spaetere Quellaenderungen vergiften den Cache.
- Ausserhalb eines Passes wird jeder Producer direkt aufgerufen. Der letzte
  passende `end` verwirft alles; verschachtelte Paare schaffen keinen neuen Owner.
- Ein neuer Pass im selben Engineframe liest neu. Ein Engineframewechsel
  verwirft auch einen vergessenen offenen Pass und erfordert ein neues `begin`.
- Echte Light-/Heavy-/Fireteam-Revisionen invalidieren sofort; unveraenderte
  Lightwerte und ungueltige IDs invalidieren nicht. Aenderungen waehrend eines
  Producers duerfen dessen Ergebnis nicht nachtraeglich wieder speichern.
- Read-only-Diagnose zeigt Scope, Eintraege und Aufbau-/Hit-/Bypass-/Invalidierungs-
  zaehler; ihre Rueckgabedictionaries bleiben isoliert. Der Helper erzeugt keine
  Commands/Effects und erhaelt keine Gameplay-/Simulation-Ownerreferenz.

## Betroffene Dateien
- `scripts/tactical/mission_hud_read_model.gd`
- `scripts/tests/hud_architecture_20261106_read_scope_verifier.gd`
- diese Teilaufgabe

## Lokale Pruefung
Zuerst dynamischer API-/Verhaltensverifier auf unveraendertem Produkt (RED).
Root fuehrt alle Godot-Laeufe seriell mit geschuetzten isolierten Userdaten aus.
Danach derselbe Verifier auf dem Produktpatch (GREEN), bestehender TASK1190
und Controller-/native Integration separat. Keine FPS-/Releasebehauptung aus
diesem Komponentenverifier.

## Beobachteter Istbeleg, 2026-11-06
- RED: `output/hud_architecture_20261106/read_scope_red/20261106T134056Z-13a3c7b1/`;
  unveraendertes Produkt ohne die drei Scope-API-Methoden, Exit 1,
  keine Parser-/Runtimefehler; isolierter Runner bestaetigt die rote Erwartung.
- GREEN: `output/hud_architecture_20261106/read_scope_green/20261106T134223Z-891c2550/`;
  echter ReadModel-Verifier **34 bestanden, 0 fehlgeschlagen**, Exit 0,
  Fehlerzahl 0. Sourcepins waehrend des Laufs stabil; Originalroster einschliesslich
  SHA256, Bytezahl und mtime unveraendert.
- Benachbarter echter Commandbatch-Verifier mit Root-Controllerintegration:
  `output/hud_architecture_20261106/command_batch_neighbor/20261106T134224Z-432a3a07/`,
  vom Root seriell ausgefuehrt, Exit 0 / Fehlerzahl 0. Kein Ersatz fuer native
  Gesamtroute oder Performancebeleg.
- ReadModel-Produkthash des GREEN-Laufs:
  `c8697b17b9603d11275557fab94615bacfe0b6377ee9d66c8586eb1bebe869ae`.
  Verifierhash: `19ab3c929f96fa02df65a305368b38bef8137198f07ceacced3897e4d20d409b`.
  Produkt und Verifier danach fuer den Root-Integrationslauf eingefroren.

## Risiken / offene Punkte
Producer muessen synchron und nullaer sein; der integrierte `_update_ui`-Pfad
enthaelt kein `await`. Der Cache ist ein kurzlebiger Snapshotcontainer, keine
Runtime- oder UI-Autoritaet. Objektidentitaeten werden nicht dupliziert; erwartet
werden bestehende Dictionary-/Array-Projektionen. Native Performance misst Root.
