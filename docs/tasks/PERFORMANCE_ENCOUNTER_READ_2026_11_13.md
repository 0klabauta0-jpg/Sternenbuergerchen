# Schmaler Encounterread — 13.11.2026

## Ziel / Ursache
Performance-Review auf Main5196cc08b: das immer vorhandene Encounterpanel ruft
alle0,15s den vollständigen SingleplayerRuntime-Snapshot auf, auch verborgen.
Nur `space_encounter` wird verwendet. Der Gesamtgetter baut zusätzlich Fuel-,
Craft-, Services-, Basis-, Location- und Checkpointdaten auf.

## Umfang / Nichtziele
Additiver `get_space_encounter_snapshot()` im vorhandenen Runtimeadapter,
delegierend zum bestehenden Encounterowner. Presenter liest ausschließlich
diesen Getter; Kadenz, Phasen, Buttons und Commandowner bleiben erhalten.
Kein globaler Snapshotcache, keine zweite Gameplaywahrheit, keine Änderung
an Encounterkampf, Karten, Rendering, Personendarstellung oder Speicherregeln.
Einziger produktiver Konfigurationscaller ist MetaLayerFlow mit genau diesem
Adapter; kein Legacy-Fullsnapshotfallback erforderlich oder vorgesehen.

## Dokumente / Akzeptanz
PERFORMANCE_REVIEW_2026_11_13, PROJECT_BRIEF, ARCHITECTURE, CODEX_RULES,
docs/performance/performance_regression_gate.md.

- Verborgener/leerer und sichtbarer Encounterpoll erzeugen null Gesamtsnapshots.
- Kleiner Read entspricht dem tatsächlichen Encounterowner, ist aliasfrei und
  meldet vor dessen Konfiguration leer; es entsteht kein langlebiger Cache.
- entering samt Fehlerfeedback, combat/engaging, rescue_ready und alle terminalen
  Phasen behalten Text-/Button-/Sichtsemantik. Commands gehen weiter zum Runtimeowner.
- Runtimewechsel liest sofort den neuen Owner; null/freigegebener Owner blendet
  Panel ohne Aufruf eines abgebauten Objekts aus.
- CPU-Vergleich seriell durch Root mit identischer Last; Headless ist keine FPSabnahme.

## Dateien / lokale Prüfung / Risiken
scripts/meta/singleplayer_runtime_adapter.gd, campaign_space_encounter_presenter.gd;
scripts/tests/performance_encounter_read_20261113.gd und eigene QA bei Root.
Zuerst isolierte Spy-/Ownerregression durch Root ROT; erst danach freigegebener
Produktfix und GRÜN samt serieller CPUprobe. Keine Godotläufe durch Teilagenten.
Reale Panelmodell-/Renderinginitialisierung ist nicht Teil dieses Gettertests.

## Codeanschluss nach sauberem ROT
Rootprobe `red_081b4910861743b09b185fed8a7c730e`:9/5, sauberes erwartetes ROT.
Additiver Adapterread und direkter Presenteranschluss jetzt implementiert;
null/freigegebener Runtimeowner blendet die Darstellung aus. Kein Gameplaycache,
keine Kadenzänderung und kein Legacy-Gesamtsnapshotfallback. Ausführung erfolgt
ausschließlich seriell durch Root; noch kein GRÜN oder Zeitgewinn behauptet.

## Weiterer Kandidat B — ausdrücklich nicht geändert
ExplorableHomebase liest je Frame den ganzen BasePersonnel-Snapshot. Vorhandene
`get_actor`-/`get_unit_registry`-APIs liefern IDs/Posen, jedoch nicht Status,
Bed oder abgeleitete Away-Anwesenheit. `state_changed` ist bereits angeschlossen;
allein dieses Signal garantiert keine Invalidierung abgeleiteter Travelzustände.
Eine Statusprojektion müsste Kontexte, Personen-/Actorwechsel, Sleep/Board/Away
und den bestehenden5Hz-UIrefresh abdecken. Kein ausschließliches Signalcaching
ohne diesen Nachweis und keine B-Änderung in diesem kleinen Encountertask.
