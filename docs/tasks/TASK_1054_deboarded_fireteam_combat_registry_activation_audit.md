# TASK_1054 - Deboarded Fireteam Combat Registry Activation Audit

## Befund

Nach der LZ-/Deboard-Stage meldet der echte Trace `deployed_ids=[]`, `combat_friendlies=[]` und keine ausstehende Runtime-Aktivierung. Der Flow erreicht somit eine aktive Mission ohne aus Homebase uebernommene Passagiere.

## Naechster Schritt

TASK_1055 prueft und repariert den Homebase-zu-Active-Mission-Transportpayload: ausgewaehlte Fireteam-Mitglieder muessen vor LZ im Dropship, nach Deboarding deployed und im Combat-Registry-Pfad sichtbar sein.
