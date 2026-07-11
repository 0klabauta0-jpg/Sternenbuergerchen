# TASK_1108 - Embarked Selected Fireteam HUD Contract Reconciliation

## Status: IMPLEMENTIERT

## Ziel / Problem
TASK_180 erwartet fuer ein ausgewaehltes, noch eingeschifftes Fireteam Boden-Member-Cards. Das widerspricht dem neueren und bereits implementierten TASK_1058-Vertrag, der in diesem Zustand bewusst nur den Dropship-Hinweis zeigt.

## Sinnhaftigkeit / Ursache
Der historische Fixed-HUD-Verifier wurde nach TASK_1058 nicht aktualisiert. Seine linke Mini-Card-Pruefung nimmt zudem nur das erste beliebige sichtbare Fireteam und kann dadurch ein anderes Bodenteam faelschlich als das eingeschiffte Team interpretieren.

## Umfang
- TASK_180 auf den aktuellen Embarked-HUD-Vertrag abgleichen.
- Ausgewaehlte Fireteam-ID im #17-Panel erhalten.
- Genau den Hinweis `Fireteam im Dropship.` und keine Boden-Member-Cards erwarten.
- Das konkrete eingeschiffte Fireteam aus der linken Boden-Mini-Liste ausschliessen.
- TASK_503 als autoritative Regression fuer Hinweis und Deboard-Rueckkehr gemeinsam ausfuehren.

## Nicht-Ziele
- Keine Aenderung an Selection-, Deployment-, Dropship- oder Combat-Wahrheit.
- Keine Wiederherstellung der bewusst entfernten disabled Boden-Cards.
- Kein neues HUD-Panel.
- Kein manueller Sichttest.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_1058_embarked_fireteam_selected_hud_truth.md`
- `docs/tasks/TASK_503_mission_dropship_fireteam_hud_truth.md`
- `docs/dev/homebase_direct_dropship_flow_contract.md`

## Akzeptanzkriterien
- TASK_180 prueft den aktuellen Hinweisvertrag statt des ueberholten Member-Card-Vertrags.
- #17 behaelt die ausgewaehlte Fireteam-ID waehrend Inbound.
- #17 zeigt genau einen Dropship-Hinweis und null Operator-Cards.
- Die linke Boden-Mini-Liste enthaelt das eingeschiffte Fireteam nicht.
- TASK_180 und TASK_503 sind vollstaendig gruen.

## Betroffene Dateien
- `scripts/tests/task_180_mission_drop_light_fixed_hud_layout_verifier.gd`
- diese Task-Datei
- Status-, Roadmap- und HTML-Arbeitsreport-Dokumentation

## Lokale Pruefung
- TASK_180 Mission Drop Light Fixed HUD Layout
- TASK_503 Mission Dropship Fireteam HUD Truth
- TASK_396 Mission Dropship LZ/Drop Hotfix
- TASK_1107 Mission Control Fixed Layout
- `git diff --check`

## Risiken / offene Punkte
TASK_180 prueft weiterhin viele historische HUD-Bausteine in einem grossen Sammeltest. Kuenftige bewusst geaenderte Darstellungsvertraege muessen dort explizit nachgezogen werden, damit alte Erwartungen nicht als neue Produktionsfehler erscheinen.

## Ergebnis
TASK_180 prueft nun den aktuellen TASK_1058-Vertrag: Das eingeschiffte ausgewaehlte Fireteam bleibt Quelle von #17, erscheint nicht als Boden-Mini-Card und zeigt genau `Fireteam im Dropship.` statt Operator-Cards. TASK_180 ist 98/98, TASK_503 10/10 und der echte Zwei-Dropship-Deboarding-Flow TASK_396 17/17 gruen. Es war keine Produktionsaenderung erforderlich.
