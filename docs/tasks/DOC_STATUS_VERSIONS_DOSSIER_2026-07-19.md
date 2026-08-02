# DOC â€” Status-, Versions- und Zukunftsdossier (19. Juli 2026)

## Ziel / Problem

Das Projekt braucht eine ausführliche, interaktive HTML-Seite, die Außenstehenden
und dem Team gleichermaßen den tatsächlichen Spielstand, die Architektur, die
Produktvision und die sinnvolle Ausbaufolge erklärt. Historische Task-Mengen oder
Momentaufnahmen dürfen dabei nicht als aktuelle Release-Wahrheit erscheinen.

## Sinnhaftigkeit

SternenBuergerchen verbindet bereits Commander-Taktik, Meta-Layer, Terrain,
Netzwerkvorbereitung und eine wachsende Dokumentationsgeschichte. Ohne eine
lesbare Landkarte werden sowohl die langfristige XCOM-artige Basis-/Blueprint-
Vision als auch die kurzfristigen Evidenzgates leicht mit bereits fertigem
Gameplay verwechselt.

## Umfang

- Erzeuge `docs/reports/STERNENBUERGERCHEN_STATUS_VERSIONS_DOSSIER_2026-07-19.html`
  als lokale, interaktive Workbench nach `html_report_workbench_contract.md`.
- Erkläre Spielarchitektur, Spielerreise, aktuelle Evidenz, Systembaum,
  Forschungs-/Ausbauvision, Landschaft/Assets, Multiplayer, Performance,
  Risiken, Grenzen und priorisierte Ausbaureise.
- Berücksichtige die konkrete Branch-Evidenz N004A neben der kanonischen
  Current Truth und markiere die noch ausstehende Truth-/Evidence-Integration.
- Verwende lokale Tactical-Suite/KlabsCom-Erkenntnisse nur als Inspiration und
  offizielle Star-Citizen-/Godot-Quellen als ausdrücklich markierte
  Prinzipienstudien.
- Biete Filter, Fokuswahl, Notizen, lokale Speicherung, JSON-Import/-Export
  und zugängliche mobile Darstellung.

## Nicht-Ziele

- Kein Gameplay-, Runtime-, Asset-, Szenen- oder Contract-Umbau.
- Keine Behauptung, dass Basisbau, Ökonomie, Mining, persistente Welt oder
  großes Multiplayer bereits implementiert sind.
- Keine Änderung des unveränderlichen TASK-1181-Snapshots.
- Keine Installierung neuer Plugins oder Asset-Pakete.

## Relevante Dokumente

- `docs/DOCS_INDEX.md`, `docs/CURRENT_GAME_STATE.md`,
  `docs/PRODUCT_MILESTONES.md`, `docs/qa/CURRENT_EVIDENCE.md`
- `docs/PROJECT_BRIEF.md`, `docs/ARCHITECTURE.md`,
  `docs/visual/WORLD_ART_DIRECTION.md`
- `docs/dev/html_report_workbench_contract.md`
- `docs/tasks/TASK_N004_canonical_product_mission.md`,
  `docs/tasks/TASK_N005_frontier_desert_outpost.md`
- N004A commits `b04ceef4` und `b34e5fce`, jeweils als Branch-Evidenz

## Akzeptanzkriterien

- Die HTML unterscheidet sichtbar zwischen Gegenwartswahrheit,
  branchverifizierter Arbeit, historischen Belegen und Zukunftsvision.
- Spieler- und Systembaum, Authority-Architektur, Forschungs-/Ausbauweg,
  Landschaft, Multiplayer und Performance sind ohne Codekenntnisse verständlich.
- Jede Empfehlung zeigt Nutzen, Voraussetzung, Risiko und grobe relative
  Größenordnung statt erfundener Terminzusage.
- Der Arbeitsbereich funktioniert unter `file://`: lokale Persistenz,
  JSON-Export, Import, Reset und Entscheidungskontrollen sind vorhanden.
- Desktop und mobiles Portrait sind ohne horizontalen Überlauf lesbar;
  interaktive Kernpfade und Konsolenfehler werden geprüft.
- Der Reportindex enthält Datum, Zweck, Evidenzstatus und `supersedes`-Eintrag.

## Betroffene Bereiche

Nur `docs/reports/`, `docs/tasks/` und der Reportindex. Produktcode bleibt
unberührt.

## Lokale Prüfung

- Statische HTML-/Inhalts-/Schema-Checks und `git diff --check`.
- Browser-Smoke via lokalem `file://`: Desktop, Mobile, Tree-Filter,
  Fokuswahl, Notiz-Persistenz, JSON-Export/Import/Reset und Fehlerkonsole.
- Quellenlinks, keine doppelten IDs und kein horizontaler Überlauf prüfen.

## Risiken / offene Punkte

Der Report darf weder einen zweiten Produktplan noch eine zweite
Gameplay-Wahrheit schaffen. Alle zukunftsgerichteten Aussagen bleiben als
Vorschlag/Horizont markiert; zeitsensible externe Quellen werden mit Datum und
Link geführt.
