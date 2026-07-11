# TASK_1109 - Multi-Dropship Fireteam Selection HUD Consistency

## Status: IMPLEMENTIERT

## Ziel / Problem
Bei mehreren Dropships muss der Spieler ein eingeschifftes Fireteam direkt aus seiner Schiffsunterkarte waehlen koennen. Der Craft-Wechsel darf gleichzeitig die Passagiere anderer Schiffe nicht aus der globalen Embarked-Wahrheit verlieren und dadurch als Boden-Fireteams anzeigen.

## Sinnhaftigkeit / Ursache
Die aeussere Dropship-Karte ist klickbar, die darin gerenderte Fireteam-Payload-Karte bisher nicht. `_apply_mission_dropship_card_selection()` ersetzt ausserdem `_embarked_unit_ids` durch den Payload des gerade ausgewaehlten Schiffs, obwohl weitere Schiffe parallel Passagiere tragen koennen.

## Umfang
- Fireteam-Payload-Karte in jeder Dropship-Karte klick- und tastaturwaehlbar machen.
- Auswahl setzt Craft und genau ein Fireteam gemeinsam.
- Embarked-State als Vereinigung aller nicht deboardeten Kartenpayloads erhalten.
- Zwei gleichzeitig eingeschiffte Fireteams wechselnd pruefen.
- Gemischten Zustand pruefen: ein Fireteam deployed, eines weiterhin embarked.
- #17-Hinweis, Member-Cards und linke Boden-Mini-Liste konsistent halten.

## Nicht-Ziele
- Keine Aenderung an Drop-Sequenz, LZ, Movement oder Combat.
- Keine neue Transport- oder Selection-Wahrheit im UI.
- Kein automatisches Multi-Select mehrerer Fireteams.
- Kein Redesign der Dropship-Karte.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_1108_embarked_selected_fireteam_hud_contract_reconciliation.md`
- `docs/tasks/TASK_1058_embarked_fireteam_selected_hud_truth.md`
- `docs/dev/homebase_direct_dropship_flow_contract.md`

## Akzeptanzkriterien
- Klickbare Fireteam-Payload-Karte waehlt zugehoeriges Craft und Fireteam.
- Wechsel Blue -> Gold -> Blue behaelt beide Teams als embarked und ausserhalb der Boden-Mini-Liste.
- #17 zeigt fuer das jeweils eingeschiffte Team den Dropship-Hinweis.
- Nach Blue-Deboarding zeigt Blue Member-Cards, waehrend Gold weiterhin Hinweis und keine Boden-Mini-Card zeigt.
- Auswahl erzeugt keine SimulationRoot-Commands oder Effects.

## Betroffene Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_1109_multi_dropship_fireteam_selection_hud_consistency.gd`
- Status-, Roadmap- und HTML-Arbeitsreport-Dokumentation

## Lokale Pruefung
- TASK_1109 Verifier
- TASK_503 Embarked/Deployed HUD Truth
- TASK_396 Multi-Dropship Deboarding
- TASK_180 Fixed HUD Verifier
- Multiplayer-HUD-/Authority-Smoke
- `git diff --check`

## Risiken / offene Punkte
Parallel aktive Drop-Sequenzen halten zusaetzliche Runtime-Payload-Zustaende. Der Union-Resolver muss Karten- und Sequenzdaten lesen, ohne bereits deboardete Units wieder als embarked einzutragen.

## Ergebnis
- Jede Dropship-Payload-Karte kann ihr eigenes Craft und genau ein Fireteam per Maus oder Tastatur auswaehlen.
- Der HUD-Resolver vereinigt Karten- und aktive Sequenzpayloads nur fuer die Darstellung. Die schiffspezifische Drop-Sequenz bleibt unveraendert und autoritativ getrennt.
- Bereits deboardete Units werden aus der HUD-Embarked-Menge entfernt; dadurch bleiben gemischte Zustaende aus Boden- und Schiffs-Fireteams konsistent.
- Runtime-Signaturen berechnen die vereinigte HUD-Sicht einmal je Refresh und reichen sie an die Unit-Signaturen weiter.
- Die Auswahl erzeugt keine SimulationRoot-Commands oder Effects.

## Verifikation
- TASK_1109: 18/18
- TASK_503: 10/10
- TASK_396: 17/17
- TASK_180: 98/98
- TASK_399: 9/9
- TASK_1104: 31/31
