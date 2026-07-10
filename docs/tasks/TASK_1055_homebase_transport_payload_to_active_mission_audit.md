# TASK_1055 - Homebase Transport Payload to Active Mission Audit

## Ergebnis

Boarding und Planning-Sync sind korrekt: `unit_alpha`, `unit_bravo`, `ft1`, Dropship-Karte und MissionSetup-Daten liegen im Planning-State vor. Nach Start/Drop bleiben jedoch `deployed_unit_ids` und Combat-Friendlies leer.

## Naechster Schritt

TASK_1056 repariert den Active-Mission-Consumer des vorhandenen Planning-/MissionSetup-Payloads; der Homebase-Handoff selbst wird nicht dupliziert.
