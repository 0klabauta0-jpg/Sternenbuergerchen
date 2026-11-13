# Code-, Architektur-, UX- und Gestaltungsreview · 13.11.2026

## Ziel / Problem und Anlass
Erneuter unabhängiger Review des integrierten Mainstands 9fdeb866b auf Nutzerwunsch.
Zuerst Codebefunde prüfen und melden, anschließend Architektur, Bedienbarkeit und
visuelle Gestaltung bewerten. Vorherige grüne Einzelprüfungen sind keine Vollabnahme.

## Umfang und Nicht-Ziele
Code: Kampf/Hex/Sicht, Multiplayer, Kampagne/Speichern/Reise und UI-Eingabegrenzen.
Danach Verantwortlichkeiten und aktive Pfade, zentrale Spielerwege und vorhandene
native Bilder gegen zugeordnete Gestaltungsreferenzen. Kein Spielcode-Fix, kein
Assettausch, keine Desktopübernahme, kein Spielerprofilzugriff mit Schreibwirkung.
Reproduktionsproben verwenden private user://-Verzeichnisse; reale Profile und
Produktquellen werden vorher/nachher geprüft. Visuelle Evidenz nach Stand kennzeichnen.

## Relevante Dokumente
AGENTS.md; PROJECT_BRIEF.md; ARCHITECTURE.md; CODEX_RULES.md;
docs/dev/hex_tactical_runtime_contract.md; combat_loop_authority_contract.md;
multiplayer_authority_command_contract.md; runtime_script_layout_contract.md;
ui_native_design_contract.md; graphics_reference_revision_contract.md;
html_report_workbench_contract.md. Vorherige QA unter docs/qa/performance_review_20261113/.

## Akzeptanzkriterien
- Befunde nennen konkrete Situation, Folge, Quelle, Schwere und Evidenzsicherheit.
- Veraltete oder unerreichbare Verdachtsfälle werden nicht als aktive Bugs gezählt.
- Codeergebnisse kommen vor der anschließenden Architektur-/UX-/Gestaltungsbewertung.
- Architektur- und Geschmacksempfehlungen bleiben von Funktionsfehlern getrennt.
- Bericht nennt geprüften Commit, echte Prüfungen und Grenzen; kein behaupteter Vollspieltest.

## Betroffene Dateien und lokale Prüfung
Nur diese Taskdatei, Review-/QA-/Berichtsdateien; keine Produktdateien ändern.
Gezielte headless Reproduktionen mit tatsächlichen Scripts; Desktop unangetastet.
Vorhandene Bilder ansehen und Herkunft prüfen; falls Bericht aktualisiert wird,
Offline-/Mobile-/Exportprüfung des bestehenden Workbenchformats.

## Risiken / offene Punkte
Main ist die vom Nutzer zuletzt integrierte Basis; ältere parallele Worktrees werden
nicht still einbezogen. Keine frische GPU-/FPS- oder menschliche UX-Abnahme.
Branch: task/astra-review-20261113 ab Main 9fdeb866b.

## Ergebnis
Neun offene Codebefunde (4P1/5P2), sieben verwertbare Reproläufe, ein verworfener Fixturefehler. Alle Quell-/Originalprofilguards unverändert. Architektur, UX und Gestaltung anschließend bewertet. Keine Produktänderung. HTML/Websitepaket je49/0 geprüft; Bericht und Details siehe docs/reviews/ASTRA_REVIEW_2026_11_13.md.
