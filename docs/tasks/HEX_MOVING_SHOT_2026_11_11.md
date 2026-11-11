# AP5 Skillabzug beim Bewegungsschuss

Ziel: Der bestehende autoritative Damagepfad erlaubt weiterhin die bereits
entschiedenen Schüsse; bei tatsächlich bewegtem Hexangreifer sinkt die Chance
skillabhängig. Kein zusätzlicher Wurf, keine UI-/Renderbewegungswahrheit.
Basis5a8544fea, kein aktiver Produktionsmodus. Verträge: Hexruntime, AP5 und
combat_loop_authority_contract.md; UnitProfileMath/Coreaccuracy bleibt Quelle.

Vorläufiger Kandidat: Genauigkeitsskill0..1 ergibt Faktor0.65..0.95 auf die
bisher fertig berechnete Chance, anschließend bestehende Min-/Maxgrenzen.
Das entspricht35%..5% relativem Abzug, keine endgültige Balanceentscheidung.
Stationär/Legacy Faktor1. Bewegung schließt Ground-Zentrierphase ein.
Auftrag/FireRule entscheidet weiterhin, ob überhaupt ein Schuss entsteht.

Umfang: zusätzlich abgeleiteter Combat-Effekt aus Coreaccuracy, kompatibler
TestUnitreader für vorhandene Bundles und ein pro Damageeffect lokaler Snapshot
der Angreifer-/Zielprofile. Bestehende mehrfache Profilgetter im selben Schuss
werden dadurch einmal gelesen; kein dauerhafter Statcache/Invalidierungsvertrag.
Hitcontext und read-only Auflösung erklären Faktor und logischen Bewegungsstatus.

Dateien: UnitProfileMath, TestUnit, SimulationRoot, kleiner hex_moving_shot-
Verifier/isolierter Runner, Runtimecontract/QA. Akzeptanz: kanonische Accuracy
statt abweichendem Legacywert, geringer werdender Abzug bei höherem Skill,
Bewegung/Centering/Halt/Legacy, tatsächlicher Damage/Chance und keine zusätzliche
RNGnutzung. Profil pro Beteiligtem höchstens einmal pro Effect, neue Effects
lesen geänderte Profile frisch; Fallbacks erhalten bisherige Gettersemantik.

Prüfung: nur kleine Root-/Registry-/Actor-/Profilfälle mit höchstens vier Feldern,
betroffene Move-/Consumer-Nachbarn und enger Review. Keine Gefechts-/Framerate-
oder Balanceabnahme. Nichtziele: Rüstungs-/Schadenssystemumbau, neue Waffen-/
Skillprogression, Türguard/Backoff/Lifecycle/Save/Netzwerk und große Tests.

Ergebnis: vorläufiger Faktor und kanonischer TestUnitreader angeschlossen,
profilabhängige Trefferchance und Hitcontext/Auflösung aus einem Effectsnapshot.
Expliziter Opt-in `get_damage_profile_snapshot()` vermeidet Änderungen der alten
Einzelgetterpräzedenz bei anderen Actors. Rollenfallbacks bleiben lazy, der
Bewegungsskill wird nur bei tatsächlicher Angreiferbewegung gelesen.
MovingShot65/0 (einschließlich42 Basis), MoveConsumers65/0, SightConsumers39/0,
alle Guards grün. Zwei Review-P2 zu Getterpräzedenz und unnötigen Reads sauber
63/2→65/0 geschlossen. QA hex_moving_shot_20261111, keine Balance-/Lastabnahme.
