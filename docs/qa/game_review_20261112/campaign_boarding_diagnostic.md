# Erster Kampagnenstart: Boardingtimeout im Altverifier

## Problem und Ursache

`campaign_five_actual_sorties_verifier.gd` wartete beim ersten Basisboarding
60 Sekunden, obwohl Personen und Transport bereits vollständig geboardet waren.
Es handelt sich um einen **Verifierfehler**, nicht um einen nachgewiesenen
Spiel-/Navigationsfehler.

Die Aufrufreihenfolge in `_run()` ist zuerst `_prepare_initial_base()`, danach
werden Craft-/Piloten-ID aus der Operationsprojektion zwischengespeichert.
Die geerbte Initialvorbereitung setzt Craft und Team, aber noch nicht `_pilot_id`.
Der Fünf-Ausflüge-Verifier überschreibt `_base_crew_ready()` und ergänzte diesen
leeren Cachewert als erwartete Personen-ID. Keine reale Person kann ID `""`
erfüllen. Das ursprüngliche Zweipersonen-Gate hatte diese Abhängigkeit nicht.

## Reproduktion und Fix

Neues `scripts/tests/game_review_campaign_diagnostic_20261112.gd` erbt den echten
Fünf-Ausflüge-Verifier, öffnet eine neue Kampagne und sendet den realen
`base_board`-Command. Keine Positions-/Transportzustände werden erfunden. Es
protokolliert echte Owner-Snapshots, Positions-/Action-/Boardgruppen-/Command-
zustände, Physics-Tick und Transportpayload während eines begrenzten20s-Fensters.
Der Diagnosepfad lässt `_pilot_id` ausdrücklich uninitialisiert wie der erste
ursprüngliche Aufruf.

Rot: `campaign_diagnostic_red.log`, Exit1, `passed=1 failed=1`.
Bereits bei Sekunde4 sind beide echten IDs `campaign_leader` und
`campaign_pilot` an Position `(1946.3387,1266.8306)` und `aboard` auf
`dropship_1`. Payload `boarded_operator_count=1`, `boarding_progress_ratio=1`,
`can_request_mission_start=true`; Boardgruppen und Commandqueue leer,
Physics aktiv, Welt nicht pausiert. Diese Fakten bleiben bis zum Timeout stabil.

Minimaler Fix nur in
`scripts/tests/campaign_five_actual_sorties_verifier.gd::_base_crew_ready`:
aktuell zugewiesenen Pilot über `_get_assigned_pilot_id(craft)` beim bestehenden
Owner lesen, leeren tatsächlichen Pilot weiterhin ablehnen. Das Gate prüft
unverändert alle wirklichen Teammitglieder und den wirklichen Piloten sowie
den fertigen Payload. Keine Produkterwartung abgeschwächt.

Grün: `campaign_diagnostic_green.log`, Exit0,
`GAME_REVIEW_CAMPAIGN_DIAGNOSTIC passed=2 failed=0`; Abschluss bei Tick234.
Keine Script-/Runtimefehler oder Leakmeldungen im grünen Log. Genau derselbe
Diagnosepfad und weiterhin kein vorher gesetzter `_pilot_id`-Cache.

## Ausführung und Grenzen

Godot4.6.2 headless, `Engine.time_scale=4`, isolierte APPDATA unter
`docs/qa/game_review_20261112/campaign-diagnostic-profiles` beziehungsweise dessen
Unterordner `green`. Das Script verweigert den Start ohne diesen Pfadmarker.
Kein echter Spielstand und keine Produktdatei geändert. `git diff --check`
für Verifier und Diagnose ohne Befund.

Die Diagnose belegt nur das erste reale Boarding. Die komplette Folge aller
fünf Missionen ist nach dem Fixturefix erneut auszuführen; der frühere Timeout
belegt keine Fehler oder Erfolge späterer Gefechte, Reisen oder Rückkehrpfade.
