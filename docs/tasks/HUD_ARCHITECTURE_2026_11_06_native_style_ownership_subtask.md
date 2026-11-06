# A5-Primary-Styles beim vorhandenen finalen Presenter belassen

## Ziel / Problem und Ursache
Nach den ersten Style- und Projektionskorrekturen kostet der Craft-Style-Scope
weiter etwa 14 ms. Der generische Basisskin schreibt fuer neun Primary-Actions
StyleBoxen mit 8px-Randabstand und den generischen Font. Der unmittelbar folgende
native A5-Presenter schreibt dieselben Controls wieder als Action-Tiles mit
anderen Ressourcen/Randabstaenden/Fonts. Dessen Dirty-Guard erkennt diese echte
abweichende Resource-Identitaet korrekt; die Basisanwendung verursacht den Wechsel.

## Umfang / Nicht-Ziele
- Root autorisiert einen engen Guard in `_apply_dynamic_button_base_style()`:
  Nur wenn `native_a5_legacy_setup_complete` aktiv ist und der Button zu den
  vorhandenen FIRST-/SECOND-Primary-Actions des nativen Presenters gehoert, wird
  der generische Reset uebersprungen.
- `_apply_command_matrix_1280_readability()` und der vorhandene finale
  `_present_primary_action()` bleiben Owner der aktuellen nativen Darstellung.
- Keine Style-Signatur, keine neue Cache-/Gameplaywahrheit, keine Verzoegerung
  von Target-, Delete-, Sort-, Selection- oder GO-Feedback.
- Door-Affordance, ROE-Owner, Navigation und andere Controls bleiben unveraendert.
- Kein breiter Themefile-Umbau; dessen StyleBox-Ressourcen sind bereits gecacht.

## Relevante Dokumente / Contracts
`HUD_ARCHITECTURE_2026_11_06.md`, `AGENTS.md`, `../ARCHITECTURE.md`,
`../dev/mission_command_feedback_contract.md`,
`HUD_ARCHITECTURE_2026_11_06_hidden_cards_subtask.md` und die vorhandenen
TASK_1044-/TASK_1157-Style-/Command-Vertraege.

## Akzeptanzkriterien
- In nativer A5-Darstellung verursachen die neun FIRST-/SECOND-Buttons weder
  beim ersten noch beim wiederholten Dynamic-Refresh einen generischen Reset.
- Finale Ressourcenwerte, Farben, Fonts, Labels, Icons und die aktuelle GO-Sperre
  stimmen mit der bisherigen Reihenfolge Basisskin -> finaler nativer Presenter
  ueberein, auch bei geaendertem Selection-/Target-/Delete-/Sort-/Observerstatus.
- Bestehende Controls und Pressed-Callbacks bleiben identisch.
- Alle 16 uebrigen Basis-Buttons behalten ihre bisherige Behandlung.
- Ohne A5-Meta bleibt die generische Primary-Anwendung vorhanden.
- Der unveraenderte bisherige Style-Verifier besteht weiterhin 605/605.

## Betroffene Dateien / Besitz
Root/freigegebener enger Hunk: `scripts/tests/mission_tactical_sandbox_controller.gd`.
Delegiert: `scripts/tests/hud_architecture_20261106_native_style_verifier.gd` und
diese Subtask. Der native Presenter und alle Engine-/Git-Laeufe bleiben bei Root.

## Lokale Pruefung
Root fuehrt den neuen Verifier seriell mit isolierten Userdaten/Rosterguard aus.
Marker: `HUD_NATIVE_STYLE_VERIFY_PASS`. Er verwendet die echte Missionsszene
und den echten nativen Presenter. Am bestehenden Basehelper beobachtet er
Style-Resource-/Farb-/Fontaenderungen vor/nach dem realen Sink. Der alte Code
muss dort wegen des generischen Resets RED werden, ohne Parse-/Scriptfehler.

Danach bestehender Style605, fokussierte HUD-/Commandregressionen und nativer
1x-Vergleich mit identischem Workload. Eine Ressourcen-/Dispatchpruefung allein
belegt keine Einsparung von 14 ms oder allgemeine FPS-Verbesserung.

## Risiken / offene Punkte
Der Guard darf keine weiteren Controls und keinen Legacy-Modus erfassen.
Der finale A5-Presenter muss im selben synchronen Pfad weiterhin erreicht werden.
Eine spaetere Aenderung seiner Primary-Membership braucht denselben Besitzvertrag.
Generisch idempotente Theme-Setter waeren separat pruefbar, verhindern aber die
hier nachgewiesenen tatsaechlich unterschiedlichen Basis-/Native-Styles nicht.

## Ergebnisse / Evidence
- RED: 126 PASS / 8 FAIL unter
  `output/hud_architecture_20261106/native_style_red/20261106T142522Z-ae2e539d/`.
  Ausschliesslich die acht Assertions zum generischen Zwischenreset in vier
  Zustaenden wurden rot; Ausgabeparitaet und Callbacks waren bereits korrekt.
- GREEN: 134/134 unter
  `output/hud_architecture_20261106/native_style_green/20261106T142616Z-49021527/`.
  Report: Exit 0, Fehlerzahl 0, isoliert und Quellinputs stabil. Der freigegebene
  Helperguard liest nur die zentralen FIRST-/SECOND-Arrays des vorhandenen
  nativen Presenters. Legacy-Basissink und die 16 anderen Basisbuttons bleiben
  durch den fokussierten Verifier abgedeckt.
- Keine Themefile-Aenderung oder neue Style-Signatur. Alle Engine-Laeufe stammen
  von Root. Die native Performanceeinsparung wird separat gemessen.
