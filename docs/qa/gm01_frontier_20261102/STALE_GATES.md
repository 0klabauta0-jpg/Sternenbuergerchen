# Vorbestehende UI-Erwartungen in alten Homebase-Gates

## Quellbeleg vor dem Briefingcache

Read-only gegen `git show HEAD:<Pfad>` geprüft. HEAD ist der unveränderte R4-Basiscommit `49220b59e418fc6d8db0037b4648de96bf798363`; die neuen Cacheänderungen sind dort noch nicht enthalten.

`scripts/meta/homebase_screen.gd` enthält bereits in diesem Commit:

- Zeile126: `_r2_briefing_details_open: bool = false`.
- Zeile2139: Detailcontrols werden nur bei geöffnetem Briefing sichtbar.
- Zeile5433: Der bereite reale Startbutton heißt `Einsatz starten`.
- Zeile3870: Der direkte Payloadtext heißt `Einsatz: … Kräfte · … Trupps · … Piloten`.

Die unveränderten alten Tests erwarten dagegen:

- TASK530 Zeile89: Briefingpanel sofort sichtbar.
- TASK534 Zeile69: Readinesspanel sofort sichtbar.
- Bootstrap-Gate: sechs Startbuttontextprüfungen erwarten `Start Mission`.
- Normal-click-Gate Zeilen89/91: `Start Mission` und Präfix `Mission payload:`.

Auch die diagnostischen Laufzeitprüfer enthalten bereits in HEAD veraltete Textbedingungen: Homebase Zeile1353 erwartet `Start Mission`; MetaFlow Zeilen5551/5561 prüfen denselben Startbuttontext und den englischen Payloadpräfix. Die dazugehörigen Status-/Failed-count-/Businessasserts werden in den Tests **nicht entfernt oder abgeschwächt**. Anpassungen dieser Diagnosebedingungen liegen beim Root-Agenten, getrennt vom Testbesitz.

## Beobachtete Fehlschläge

Die ursprünglichen Logs bleiben unter `checks_final/20261102T134942Z-pid146876/logs/` erhalten:

- `check-briefing_panel.log`:29 bestanden,1 Fehler ausschließlich initiale Panel-Sichtbarkeit.
- `check-readiness.log`:24 bestanden,1 Fehler ausschließlich initiale Panel-Sichtbarkeit; Readiness-/Boarding-/Loadout-/Startdaten bestehen.
- `check-homebase_bootstrap.log`:97 bestanden,6 Fehler in den alten Startbuttontexten; Payload-/Pilot-/Boarding-/Missionstartprüfungen bestehen.
- `check-homebase_actionable.log`:34 bestanden,6 Fehler durch veralteten Start-/Payloadtext und daraus abgeleitete diagnostische Guardresultate.

Das ist Quellbeweis für vorbestehende Widersprüche zwischen R4-UI und alten Gates, kein behaupteter erneuter Enginevergleich des HEAD-Checkouts.

## Eng begrenzte Testkorrektur

Die Paneltests prüfen jetzt zunächst den beabsichtigten gefalteten Zustand, drücken den vorhandenen `R2BriefingDetailsButton` mit seinem echten Callback und verlangen anschließend sichtbare Details und unveränderte Readiness-/Briefingdaten. Starttests verlangen ausdrücklich den tatsächlich sichtbaren, aktivierten deutschen Button `Einsatz starten`. Payload-, Pilot-, Boarding-, Missionsauswahl-, Handoff-, Startfreigabe- und diagnostische Guardasserts bleiben erhalten. Es werden weder Spielpanels dauerhaft eingeblendet noch Timer verändert.

Engine-/Regressionsergebnisse nach der Korrektur werden vom Root-Agenten separat festgehalten.
