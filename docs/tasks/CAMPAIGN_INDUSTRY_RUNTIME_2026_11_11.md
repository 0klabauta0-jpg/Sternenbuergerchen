# Industrie-Fortsetzung: Bergungswerkzeug

## Ziel / Ursache / Arbeitsbasis
Auf dem bestehenden task/native-glut-maps-20261110 folgt auf Schutztechnik ein
kleiner echter Industriezweig. Die Workbench nennt research_industry nach
Werkstatt und gefertigtem Mining-Tool. Das bestehende Wrack freighter_wreck_01
verlangt bereits salvage_tool; dieses bekannte Werkzeug kann der vorhandene
Supply-Fertigungsowner ohne neue Runtime-Struktur herstellen.

## Umfang / konkrete Akzeptanz / erste Balance
- research_industry heißt jetzt präzise Bergungswerkzeug entwickeln: Werkstatt
  entwickelt und Mining-Tool nachweislich gefertigt, nicht lediglich gekauft.
- Entwicklung kostet einmal160Cr (Workbenchvorschlag); Bauplan salvage_tool.
- Einzelherstellung kostet40Cr (erster eigener Balancewert); kein Gratisitem.
- Bestehende Werkstatt zeigt Forschung und Herstellen über denselben Owner.
- Sperrtext nennt das tatsächlich fehlende Werkzeug. Schutztechnik bleibt gleich.
- Supply-Replay, endliches Lager, Heimatpflicht und Forschungsbelege gelten weiter.
- Alte Forschungsstände ohne Industrieknoten bleiben gültig.

## Dateien / relevante Verträge
Daten: data/singleplayer/research.json. Reine Projektion:
scripts/mission/campaign_research_catalog.gd. Bestehender Werkstattpresenter:
scripts/meta/singleplayer_services_presenter.gd (minimaler Aktionseintrag).
Eigene kleine Probe scripts/tests/campaign_industry_slice_check.gd und QA unter
docs/qa/campaign_industry_runtime_20261111.
ARCHITECTURE.md, campaign_introduction_contract.md,
singleplayer_locations_jobs_contract.md, CAMPAIGN_RESEARCH_RUNTIME_2026_11_11,
ACTIVE_WORKPLAN_2026_11_11 und campaign_research_workbench.html sind Bezug.

## Nicht-Ziele / Risiken / lokale Prüfung
Keine Rohstoffverarbeitung, neuen Aufträge, Fahrzeuge, Modelle, Schiffskomponenten
oder Combatänderung. Der breite Workbenchvorschlag zu Verarbeitung/Prospector/
Vulture bleibt offen. Bestehende Kaufangebote behalten ihre bisherigen Regeln;
Forschung öffnet hier die eigene Herstellung. Keine neue Supply-Wahrheit.
Nur kleine Supply-Domainprobe und betroffene Script-Compilechecks; keine nativen
Reisen/Werkstattklicks, GPU/Gefechte, Benchmarks oder Save-Matrix. Native Bedienung,
realer Ressourcenweg und Balance bleiben später gemeinsam abzunehmen.
Keine Mainintegration, kein Commit/Push durch diesen Teilagenten.

## Enger Ergebnisnachweis
Umgesetzt wie oben. Industrie-Domainprobe22/0, unveränderte Schutztechnikprobe24/0;
Katalog/Presenter check-only jeweilsExit0 ohne Script-/Enginefehler/Warnungen.
Eine anfängliche raw-Reward-Fixture wurde auf den vorhandenen CampaignNormalizer
berichtigt; Produktrestore unverändert. QA samt Diagnose-/Finalbelegen:
docs/qa/campaign_industry_runtime_20261111/README.md. Native/Gesamtabnahme offen.
