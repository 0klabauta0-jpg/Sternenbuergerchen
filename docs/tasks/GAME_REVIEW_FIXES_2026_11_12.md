# Spielreview und Regressionen — 12.11.2026

## Ziel / Ursache
Zwei P2-Befunde im Mehrschiff-Basisflow reproduzieren und beheben; anschließend
aktive Spielpfade auf Architektur, Performance, Bedienung und Konsistenz prüfen.
Der Nutzer autorisiert selbständiges Finden, Beheben und Testen, ohne Desktop-
Eingaben, und erwartet einen auf dem Handy lesbaren HTML-Abschlussbericht.

## Basis / Umfang
Branch `task/game-review-fixes-20261112`, Basis `cfddc129b` auf dem noch nicht
integrierten Kampagnen-/Hexplanstand. Vorhandenes fremdes Grafik-WIP bleibt erhalten.
Bereiche: Kampagne/Continue, Hex-/Schablonenkampf und Würfelentscheidungen,
konkurrierende Combat-Owner, Multiplayer/Authority, Pause, Grafik und UI.
Bestätigte lokal begrenzte Fehler erhalten Regressionen. Große Änderungen am
Spieldesign, flächige Refactors, GPU-Abnahme, Release und Mainmerge sind Nicht-Ziele.

## Verträge / Dokumente
`AGENTS.md`, `docs/PROJECT_BRIEF.md`, `docs/ARCHITECTURE.md`, `docs/CODEX_RULES.md`,
aktueller Kopf von `docs/IMPLEMENTATION_STATUS.md` und `docs/TASK_ROADMAP.md`,
`docs/dev/runtime_script_layout_contract.md`, `docs/dev/campaign_introduction_contract.md`,
`docs/dev/hex_grid_v1_contract.md`, `docs/dev/combat_loop_authority_contract.md`,
`docs/dev/multiplayer_authority_command_contract.md`,
`docs/dev/html_report_workbench_contract.md`.

## Akzeptanz
- Personenaktionen bestimmen das tatsächlich betroffene Schiff beim Owner;
  Aussteigen aus Schiff 2 funktioniert, explizite Schiffswahl bleibt gültig.
- Continue rekonstruiert den abgeschlossenen Boarding-Payload für jedes Schiff;
  unvollständige Teams werden nicht fälschlich als geboardet behandelt.
- Neue Regressionen scheitern vor dem Fix am erwarteten Verhalten und bestehen danach.
- Weitere aktive Spielpfade werden über gezielte Headless-Szenarien geprüft;
  Befunde und technische Evidenz werden von ungetesteten Annahmen getrennt.
- Mobil lesbare lokale HTML-Workbench mit Übersicht, Ergebnis/Entscheidungen,
  Notizen und funktionierendem JSON-Export; keine externen Abhängigkeiten.

## Betroffene Dateien
Primär `scripts/meta/explorable_homebase.gd`, `scripts/meta/meta_layer_flow.gd`,
gezielte neue Verifier unter `scripts/tests/`, Evidenz unter
`docs/qa/game_review_20261112/`, Bericht unter `docs/reports/`.
Weitere Produktdateien nur für im Lauf bestätigte Fehler und dokumentierte Tests.

## Plan / lokale Prüfung
- [x] P2-Repros schreiben, erwartete rote Tests dokumentieren, minimale Fixes, grün.
- [x] Combat/Hex/Würfeln/Multiplayer prüfen und aktuelle Szenarien ausführen.
- [x] Pause/Grafik/UI und übrige Einstiegspfade prüfen, Befunde verifizieren.
- [x] Angrenzende Regressionen, unabhängiger Patchreview, diff check.
- [x] HTML-Workbench und Evidenzindex erstellen und mobil/exporttechnisch prüfen.

## Abschluss / Evidenz
26/26 ausgewählte Runtimechecks grün, darunter fünf reale Kampagnenaufträge
mit230Assertions und vier gezielte Mehrschiff-/Nachbargates mit147Assertions.
Echter lokaler ENet-Snapshottransport31/0, mobiler Offlinebericht39/0.
Produktfixes: tatsächliches Schiff beim Aussteigen, vollständiger Payloadrestore
pro Schiff und eindeutige Szenenbookmark-UI. Vier veraltete Testfixtures separat
korrigiert; keine Inventar-/Fighter-/Pilotengrenze abgeschwächt.
Quell-/Evidenzindex: `docs/qa/game_review_20261112/README.md`.
Bericht: `docs/reports/SPIELREVIEW_2026_11_12.html`.
Orbitalbegegnung verwendet ausdrücklich feste Schäden statt Boden-RNG;
vollständige Hexsicht/Feldreservierung bleibt beim bestehenden AP0–AP8-Plan.
Editorimport Exit0 mit ObjectDB-Leakwarnung am Editorende, Ursache offen;
finale Runtimegates ohne diese Meldung. Keine Main-/GPU-/Releasefreigabe.

Godot 4.6.2 ausschließlich headless, sequentielle begrenzte Testläufe mit Logs,
Erfolgsmarker, Exitcode sowie Script-/Fehler-/Leakprüfung. Keine Maus-/Tastatur-
oder Fokusübernahme. Tests dürfen keine echten Spielerstände verändern.

## Risiken / offene Punkte
Headless beweist keine grafische Qualität, native Framerate oder Internet-
Multiplayerqualität. Das Repository enthält viele historische Verifier;
überholte Erwartungen werden nicht still auf grün angepasst. Kein Gesamt-PASS
ohne ausgewiesene Prüfabdeckung. Temporärer Wachhalteprozess nur während Arbeit.
