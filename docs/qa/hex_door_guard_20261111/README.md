# AP5 echter lokaler Türschlussguard

Basis a74fbab2f. Root/Ground liefern reine Claimreads, der tatsächliche Driver-
Progressproducer lehnt einen bisher offenen, künftig blockierten Türkandidaten
vor Ownerstate und Ressourcengate ab. Geometrie/Öffnungsgrenze vom vorhandenen
DoorRuntimeCollisionLOS-Helfer; keine zweite Türwahrheit oder versteckte Queue.

Isolierte Godot4.6.2-Privatprojekte mit tatsächlichen Produktionsquellen:
`python scripts/tests/run_hex_tactical_check.py --case CASE`.

| Case | Bestanden / fehlgeschlagen |
|---|---:|
| door_guard |58 /0|
| consumers |39 /0|
| reservation_owner |36 /0|

DoorGuard enthält42 Bewegungsbasisprüfungen; die Zahlen sind keine unabhängige
addierbare Gesamtmenge. Alle Prozesse0, Originalprofil-/Quell-/Canaryguards grün,
keine Script-/Leakfehler. Manifest mit finalen Quellhashes, door_runs.zip mit
unveränderten Reports/Logs aller Versuche. Keine Hauptszene oder UI gestartet.

Neun Tile, tatsächlicher Root/Registry/CapabilityActor und Drivermutation.
QuietDriver unterdrückt ausschließlich den unbeteiligten Missionsstartup;
ein Ressourcencounter beobachtet die bestehende accept_progress-Schnittstelle.
Echte Rootqueue läuft durch offene Tür; vollständiger Passagegrant schützt die
noch nicht im Dreischritthorizont zugesagte Tür. Schluss wird bei aktueller
Belegung und beim bereits hinter der Tür stehenden, noch auf der Kante laufenden
NPC abgewiesen; nach Freigabe erlaubt. Echter Damageproducer erzeugt verwundeten
Zellhalter. Owner-/Registry-/Reservierungszustand und Ressourcenverbrauch bleiben
bei Ablehnung gleich. Falsche Registry, unbekannte/ungültige Zellen,64er Budget,
fehlender/inaktiver Owner und echtes Legacy sind geprüft.

RED42/1 fehlender Reader, danach49/4 ohne tatsächlichen Producerguard (zwei Fehler
sind Folgen des ersten erlaubten Schlusses). Erstes54/1-Setup endete in einer
Sackgasse innerhalb des Grants; das war keine freigegebene Passage. Ausgangsraum
mit neun Feldern55/0. Eigener Nachfund: Opt-in mit fehlendem/inaktivem Root durfte
noch Legacy wählen, sauber56/2→58/0 geschlossen. Frischer enger Review und
Nachreview ohne Restbefunde; Reviewer ohne Engine oder Dateiänderungen.

Inputbatch64 ist begrenzt; Claimprüfung liest vorhandene aktive Segmente/Grants,
Grantmitgliedschaft kann weiterhin von Komponentengröße abhängen. Kein SceneTree-
oder Vollkartenscan, aber keine CPU-/FPSmessung oder Performancefreigabe.
Szenario-/Kartenneuaufbau und Zulassung bleiben AP6, atomarer Save-/Multiplayer-
snapshot AP7. Der lokale Türguard sichert diese Lifecyclegrenzen nicht mit ab.
Backoff und kleiner integrierter Kandidat offen. Keine Produktionskarte/Main/EXE
aktiviert, keine native/große Gefechts-/Save-/Netzwerk-/Framerateabnahme.
