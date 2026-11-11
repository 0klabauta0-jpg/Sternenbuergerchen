# Kompakter Erfahrungs-Readout: begrenzte Uebergabe

Produktdateien: skirmish_start_configuration.gd (read-only Match ueber denselben Vorlagenpatch), character_sheet_formatter.gd (Vorlage/Individuell und kanonische Profilwirkung), character_sheet_view.gd (bestehender Werte-Foldout/Tooltip). Ein veralteter Labelassert in skirmish_points_start_test.gd wurde an Entspricht Vorlage: Mittelerfahren angepasst. Keine Runtimegetter/-formel/-owner, Preise oder Speicherfelder veraendert.

Privater kleiner Datenfixture24/0, Editorimport und Run Exit0. Prueft die drei Stufen fuer Operator/Pilot/FTL, echten Profilbuilder, jede Gruppenabweichung, gleiche Mittelwerte ohne erfundene Stufe, kanonische Gruppen statt veralteter Flataliase, keine erneute Traitwirkung, Eingangsdaten/Historie/Loadout unveraendert, unabhaengige Rueckgaben und ungueltige Werte. Drei Produktdateien separat check-only Exit0; Logs daneben. Keine grosse Suite, native Layout-/Klick-, Save- oder Gefechtsabnahme.

Reproduktion: aus Projektwurzel `python output/native_glut_maps/profile_readout_20261111/run_private_check.py`. Der Runner kopiert nur noetige GDScripts in project/, erzeugt ein privates minimales Godotprojekt und benutzt eigenes APPDATA. project/ und profiles/ sind Scratch und NICHT integrieren.

Exakte Uebergabe: drei Produktdateien, ein bestehender Verifierassert, docs/tasks/PROFILE_READOUT_FOLLOWUP_2026_11_11.md und docs/dev/profile_readout_contract.md sowie hier verifier.gd, run_private_check.py, private_check.log, die drei *_compile.log, README.md und manifest.json. Quellen in manifest.json SHA256-erfasst; kein Commit/Push.

Offen bleibt die eigentliche Reduktion interner Faehigkeits-/Balanceachsen und deren AP5-/Combatabgleich. Dieser Slice ist eine ehrlichere kompakte Anzeige. Die aeltere Passage in skirmish_prepared_starts_contract.md zur geschaetzten Drei-Stufen-Anzeige muss Root bei Integration an den neuen profile_readout_contract anpassen; diese bestehende globale Contractdatei wurde vom Teilagenten nicht editiert.
