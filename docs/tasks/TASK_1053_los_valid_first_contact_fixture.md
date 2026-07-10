# TASK_1053 - LOS-Valid First Contact Fixture

## Befund

Der Trace nutzt jetzt die Combat-registrierten Friendlies und den echten LOS-Resolver. Im LZ-/Deboard-Flow findet `ft1` dennoch keine gueltige sichtbare Kontaktposition. Damit ist die verbleibende Luecke zwischen Deployment, Combat-Registry und First-Contact-Fixture belegt.

## Naechster Schritt

TASK_1054 auditiert die Runtime-Aktivierung von debarkierten Einheiten: Fireteam-ID, UnitRegistry, Combat-Friendly-Liste und Terrain-LOS muessen vor dem ersten Move gemeinsam bereit sein.
