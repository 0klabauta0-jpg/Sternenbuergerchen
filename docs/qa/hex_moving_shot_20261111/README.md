# AP5 Bewegungsschuss und einmalige Profilreads

Basis5a8544fea. Vorläufiger Faktor0.65..0.95 aus kanonischer Coreaccuracy
senkt nur bei tatsächlich bewegtem Hexangreifer die fertige Trefferchance,
einschließlich Zentrierphase. Weiterhin bestehender Min-/Maxclamp und ein Wurf;
Stationär/Legacy Faktor1. Keine neue FireRule oder Schadens-/Rüstungsmechanik.

Kleine isolierte Godot4.6.2-Privatprojekte mit tatsächlichen Produktionsquellen:
`python scripts/tests/run_hex_tactical_check.py --case CASE`.

| Case | Bestanden / fehlgeschlagen |
|---|---:|
| moving_shot |65 /0|
| movement_consumers |65 /0|
| consumers |39 /0|

MovingShot und MoveConsumers enthalten jeweils dieselben42 Basisprüfungen;
die Zahlen sind keine addierbare Menge unabhängiger Tests. Alle Prozesse0,
Profil-/Quell-/Canaryguards grün, keine Script-/Leakfehler. Manifest mit exakten
Quellhashes, shot_runs.zip mit unveränderten Reports/Logs aller Versuche.

MovingShot: vier Felder, tatsächliche Rootqueue/UnitRegistry/Move/Hold/Damage,
gezählter CapabilityActor mit kanonischen Mathprofilen. Niedriger/höherer Skill,
geändertes Profil im nächsten Effect, Halt/Zentrierung, gefälschtes Renderflag,
Legacy, tatsächlicher Treffer und Selfdamage. Tatsächlicher TestUnitgetter liest
altes Bundle mit Core0.9 gegen Legacy0.1 ohne Bundlemutation. Opt-inprofil wird
einmal je Beteiligtem/Effect gelesen, bei Selfdamage einmal insgesamt. Ein
absichtlich abweichender Legacybulk-/Einzelgetteractor behält die alten Werte und
liest ausschließlich benötigte Rollenfelder, keinen Bewegungsskill. Erzwungene
Rolls verbrauchen kein RNG; normaler Effect verbraucht genau einen Wurf.

RED42/1 fehlender abgeleiteter Profileffekt, dann46/1 fehlende Damageanbindung;
erster GREEN60/0. Frischer Review fand zwei P2: unbeabsichtigt geänderte
Einzelgetterpräzedenz und zusätzlich gelesene unbenötigte Rollen-/Skillfelder.
Echte Repro63/2→65/0: expliziter TestUnit-Opt-in, Rollenfallbacks lazy und
Bewegungsfallback nur bei Groundbewegung. Enger Nachreview ohne neue Befunde;
Reviewer ohne Engine oder Dateiänderungen.

Kein persistenter Profilcache: nur lokale Schussdaten. Dadurch entfallen
wiederholte kanonische Getter und der zweite Höhenlookup desselben Hitcontexts.
Der gezählte Callumfang ist belegt; eingesparte Millisekunden oder FPS wurden
nicht gemessen. Keine native Gefechts-/Balance-/Performanceabnahme, keine Karte
aktiviert. Türguard/Backoff, Lifecycle/Save/Netzwerk und große AP9-Tests später.
