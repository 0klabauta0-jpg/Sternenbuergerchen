# R4: unabhaengiges Review des periodischen HUD-Verifiers

## Scope / Rollen / Pin
Review durch den Controllerwriter, der diesen Verifier nicht authored hat.
Das ist ein unabhaengiges Testreview; der eigene Controllerproduktpatch wird
hier nicht als unabhaengig abgenommen. Dessen separates Source-/Lifecycle-
Review stammt vom Perf-Auditagenten.

Gelesene Testquelle:
`scripts/tests/runtime_hitches_r4_20261107_periodic_hud_queue_verifier.gd`,
SHA256 `82ff94e036d28323aa055cd770d620878ed14d87bb18d778f6c2d7d3a9349046`.
Produktpin Controller `b247162e46edaca4e5696c9d96242384aca102ff03cb8f2e2c84c103627cddaf`,
Metadatenhelper `cabe261aaf2b83dbd77454eeca6f0d21608bd4f8f0add1b1d4b6ecfa4f73d98f`.
Keine Engine-, Test- oder Produktmutation durch dieses Review.

## Ergebnis
APPROVED scoped. Keine P1/P2-Befunde am Verifier fuer den dokumentierten
Scheduling-/Force-/Synchronitaetsvertrag.

- Force-QA primt die echten Craft-/Cards-Signaturguards, enqueued ForceTrue
  und prueft den erfolgten Transfer vom Commandpendingflag in vier Tickets.
  Anschliessend verlangt das echte `_update_ui(true,false)` unmittelbare
  Craft-/Cards-Supergrenzen. Der Fall trifft den bestaetigten Forceverlust;
  ein unveraenderter Signaturzustand kann den Fehler nicht verdecken.
- Frameguard-QA reinseriert den Controller vor dem zweiten echten Batch
  ueber `UpdateManager.mark_hud_dirty`. Sie prueft damit eine tatsaechliche
  zweite Bedienung und nicht einen leeren Batch. Der zusaetzliche Fall
  kombiniert alten Managerentry, Fullcancel und frische Generation im
  selben Frame: kein weiterer Heavyjob, aber spaeter vollstaendige Bedienung.
- Reentry wird nach dem echten Craft-Superoutput ausgeloest. Mindestens
  zwei Craft-Completions und anschliessende Konvergenz erkennen das
  Verschlucken der neu angeforderten Arbeit. Full-Reentry prueft Passschluss
  und ausbleibende spaetere Wiederbelebung alter Deferredarbeit.
- Echte synchrone Request-/Drain-/Light-/Fullgrenzen werden mit Commands,
  Effects, Tick, Plaenen sowie Position/HP/Runtime der sichtbaren Teamunits
  umklammert. Die Fixture aendert ausschliesslich Praesentationskadenz,
  Dirtyflags und Feedbacktext; keine Actor-/Gameplayfixtures.
- Freshness ist gezielt geprueft: Feedback wird nach Enqueue geaendert;
  Matrixausgabe muss das aktuelle Feedback enthalten. Selected-/Strategic-
  RAWs sind nicht leer und werden im selben aktiven ReadModel-Pass
  beobachtet. Danach muss die Passdepth null sein.

## Aussagegrenzen / gebundener Lauf
Der Verifier ruft echte Superprojektionen und den echten Managerbatch auf,
steuert deren Scheduling jedoch synthetisch. Er beweist keine vollstaendige
semantische Runtime-RAW-Paritaet unter physischer Last, keinen nativen
Frametimegewinn und keinen Lifecycle-/Contention-Stresstest. Ownerreinheit
gilt fuer die konkret erfassten synchronen Ownergrenzen, nicht saemtliche
internen Simulationsfelder. Native Messung und Nachbarmatrix bleiben eigene
Gates; der Controllerwriter fuehrte hier keine Engine aus.

Root bestaetigt GREEN59/0, errors0, stabile Quellen:
`periodic_hud_queue_green/20261107T110454Z-0a8a0ddc`. Das eigene source-only
Review ist vom separat ausgefuehrten Enginebeleg zu unterscheiden.

## Unabhaengiger Nachbar-Diffreview: Command-Batch-Scheduling
Gelesen wurde ausschliesslich die Root-Schedulingmigration des Verifiers
`continue_20261105_command_hud_batch_verifier.gd` von der erhaltenen Rawquelle
`output/runtime_hitches_r4_20261107/source_baseline/continue_20261105_command_hud_batch_verifier.gd.raw`
(SHA `4078e88c280964c30890d03ea4767eab04f46193dab3fedac3d538f5eb2f1a3b`)
auf aktuellen SHA `75f2f999c67ced0e276c97ac0a204ae509c89779e8716b355cc96c8d019b0cda`.
APPROVED scoped, keine P1/P2. Der Reviewer authored diesen Hunk nicht.

Alle43 bisherigen `_check`-Praedikate sind source-exakt weiter vorhanden;
hinzu kommen fuenf Schedulingpruefungen. Nur der Zeitpunkt der bisherigen
Flush-/Apply-/Skip-/Kartenassertions folgt nun dem tatsaechlichen Managerdrain.
Die neuen Grenzen verlangen zuerst null synchronen Heavywork und vier
pending Keys, danach exakt vier verschiedene Renderframes bis zum Abschluss.
Der Helper wartet pro Iteration auf einen echten neuen Processframe und ruft
den bestehenden Manager-HUDbatch auf. Er setzt keine Actor-/HP-/Positions-/
Gameplaytimer und veraendert keine fachlichen Zaehlererwartungen.

Move/GO bleiben oeffentliche Commands im selben Inputframe, der erste
Commit laeuft durch den echten Physicsowner. Transportforce, sichtbarer
aktueller Move/Kartenstatus, versteckte Memberinstanzen und Details-/Callback-
Paritaet bleiben streng. Controller- und Manager-Autoscheduling sind nur im
synthetischen Komponentenfixture deaktiviert; diese direkte Bedienung ist
kein Nachweis nativer Cadence, KI-Last oder physischer Langzeitbewegung.
Root-GREEN48/0, errors0/stabile Quellen:
`command_batch_schedule_green/20261107T111155Z-1915a15f`.
