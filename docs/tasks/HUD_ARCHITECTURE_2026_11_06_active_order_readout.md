# A5: konkreter laufender Auftrag im bestehenden Readout

## Ziel / Problem
Nach GO zeigen Zielblock und Feedback parallel `Auftrag: Wird ausgefuehrt`
und `Ausfuehrung laeuft`. Die bestaetigte A5-Vorlage benennt den Auftrag
konkret, etwa `Auftrag: Bewegen`, und trennt ihn vom Ausfuehrungsstatus.

## Ursache / Sinnhaftigkeit
`_build_native_player_readout_context` zaehlt laufende ausgewaehlte Teams,
liefert aber bisher keinen Namen ihres aktiven Auftrags. Die reine
`build_player_readout`-Projektion hat daher nur den generischen Fallback.
Movement, aktive Area-Execution und ActiveBehaviorProfile besitzen die
benoetigte bestehende Auftragsinformation bereits.

## Umfang / Nicht-Ziele
Nur `_build_native_player_readout_context` in
`scripts/tests/mission_tactical_sandbox_controller.gd` und
`build_player_readout` in `scripts/ui/mission_a5_hud_layout.gd`.
Ein kurzlebiges `active_order_labels`-Feld leitet Labels ausschliesslich fuer
die ausgewaehlten tatsaechlich ausfuehrenden Teams ab. Keine neue Order-,
Mission- oder Simulationswahrheit. Keine Geometrie-, Icon-, Callback-,
Planungs-, Auswahl-, GO-, Timer- oder Actoraenderung. Root besitzt Engine/Git.

## Relevante Vertraege / Referenz
- `docs/tasks/HUD_ARCHITECTURE_2026_11_06.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/fireteam_behavior_modes_contract.md`
- `docs/dev/ui_native_design_contract.md`
- `docs/dev/graphics_reference_revision_contract.md`
- Original `docs/reports/assets/ui-2026-11-01/mockup_a5_mission_zweireihig.png`

## Akzeptanzkriterien vor Produktcode
1. Labelquelle ist zuerst der bestehende Movement-Snapshot `command_type`,
   dann die aktive Area-Execution `command_type`, dann das bestehende aktive
   Profil `metadata.origin_command_type`. Unbekannte/leere Quellen erfinden
   keinen `MOVE`-Auftrag ueber den historischen Displayname-Fallback.
2. Nur ausgewaehlte ausfuehrende Teams liefern DTO-Labels; eine aktive
   Profilrestinformation allein macht ein Team nicht ausfuehrend. Ein
   unbekannter Auftrag behaelt einen leeren Platz im Array, damit Vollstaendigkeit
   geprueft werden kann. Kein persistenter Cache und keine Rueckschreibung.
3. Ein fokussierter kuenftiger Planbefehl behaelt die bisherige Prioritaet.
   Ohne solchen Fokus erhalten alle ausgewaehlten laufenden Teams bei
   vollstaendigem gleichem Auftrag `Auftrag: Bewegen`/`Nehmen`/`Halten`/
   `Flankieren`/`Ziel bekaempfen`. Unterschiedliche vollstaendige Auftraege
   werden als `Auftrag: Verschiedene Befehle` gezeigt.
4. Teilweise laufende Auswahl behaelt `n von m Teams aktiv`; fehlende aktive
   Quellen behalten den generischen Fallback. Leere Auswahl/Planung bleibt
   unveraendert. Pending/Reject/Timeout/Observer und `Ausfuehrung laeuft`
   bleiben unveraendert.
5. Bestehendes `_note_hud_projection_build_call` bleibt erhalten. Reiner
   Readoutaufbau veraendert weder Plan, Movement-/Area-/Profilquellen noch
   Simulationqueue, und erzeugt keine Commands.

## Betroffene Dateien / Besitz
Die beiden genannten Funktionshunks, diese Task-Datei und
`scripts/tests/hud_architecture_20261106_active_order_readout_verifier.gd`.
Root aktualisiert nach belegter beabsichtigter Textaenderung selbst das
historische `continue_20261105_command_hud_batch_verifier`-Textorakel;
dessen Plan-/Actor-/GOsperren bleiben bestehen.

## Lokale Pruefung / Grenzen
Neuer Verifier zuerst RED auf dem unveraenderten Produkt. Er prueft reine
Projektionen, explizit synthetische Controller-Lesequellen und einen Move/GO
ueber bestehende oeffentliche APIs in der echten Missionsfixture. Synthetic
Executiondaten sind nur Darstellungseingaben, kein physischer Spielbeleg.
Root fuehrt isoliert RED/GREEN, bestehende R3-/Batch-Neighbors und native
Vorher/Nachherbilder seriell aus. Keine Engine-/Gitaktion dieses Agents.

## Risiken / offene Punkte
Profile koennen laenger existieren als eine Execution; deshalb bleiben sie
an das bereits bestehende Executiongate gebunden. Gemischte/unvollstaendige
Labels duerfen keinen einheitlichen Auftrag behaupten. Der groessere Abstand
von Kamera/Szenenkomposition zur Vorlage wird damit nicht geloest.

## Stand
Akzeptanz und Verifier vor Produktcode angelegt. Root fuehrte den unveraenderten
Stand isoliert aus unter
`output/hud_architecture_20261106/active_order_red_runtime/20261106T141443Z-9a759486/`.
Original-Log gelesen: 35 PASS / 11 erwartete fachliche FAIL, keine Script-/
Parsefehler. Oeffentliche Moveplanung, GO und unveraenderte Ownerquellen bestehen
bereits; die aktive konkrete DTO-/Textprojektion fehlt wie erwartet.
Danach die beiden freigegebenen Funktionshunks umgesetzt. `_note_hud_projection_build_call`
bleibt erhalten. Root-GREEN 46/46, Exit 0 und Enginefehler 0 unter
`output/hud_architecture_20261106/active_order_green/20261106T141846Z-dad19117/`.
Der bestehende Command-HUD-Batch-Neighbor besteht 40/40 unter
`output/hud_architecture_20261106/command_order_neighbor_green/20261106T141914Z-9ca4e472/`.
Root aenderte dort nur zwei Textassertions auf das beabsichtigte konkrete
`Auftrag: Bewegen`; alle Command-/Plan-/GO-Assertions blieben erhalten.
Logs mit numerischen Ergebnissen und PASS-Markern gelesen. Nativer finaler
Nachhervergleich und gestalterisches Nutzerurteil stehen noch aus.
