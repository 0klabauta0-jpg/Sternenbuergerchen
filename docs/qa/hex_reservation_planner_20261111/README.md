# AP4 reine Reservierungsplanung: kleine lokale Pruefung

Basis 7c9b5c7b1 auf task/native-glut-maps-20261110. Keine Commits/Pushes,
kein Owner-/Runner-/Driver-/SimulationRoot-/Movementedit dieses Teilauftrags.

Reproduktion im Root dieses Worktrees:

`python docs/qa/hex_reservation_planner_20261111/reproduce_private_check.py`

Der Helfer kopiert nur die rekursive GDScript-Preloadclosure des Verifiers in
`.godot/hex_reservation_private/project`, erzeugt einen frischen eindeutigen
Privatprofilnamen und importiert/prueft dieses Minimalprojekt ohne Spielszene
oder Spielautoloads. Engine Godot4.6.2. Pro Prozess Timeout30s. Kein Zugriff
auf das echte Spielprofil; keine Behauptung einer vollstaendigen Profilinventur.
Der bestehende run_hex_tactical_check.py wird bewusst nicht veraendert.

RED: fehlende build_hex_plan-Methode, sauberer Assertionsfehler0/1 und Exit1
beobachtet. GREEN: `HEX_RESERVATION_PASS 26/0`, Import0 und Verifier0, keine
Script-/Leakfehler, siehe private_check.log. Eine lokale Compilerkorrektur
betraf nur einen doppelt benannten Fixturebezeichner, kein Produktverhalten.

Abgedeckt: langsame Kolonne und atomar gemeinsam vorgeschlagene Freigaben,
stehender Ausgang, Gegenrichtung, laufende Posthandoffkante, Prioritaet/Alter,
Budget18Requests/16bearbeitet mit vollstaendigerPendingliste, 3Schritte+Rest,
Snapshot-/Terraingates, breite Rampen mit H+0.5-Seitenverbindung, sechs gedrehte
Rampenachsen und passende Kurven, besetzter Gangausgang jenseits des Horizonts,
begrenzter Ruecksetzvorschlag, Bestandsgruppenerhalt durch Position/Segment,
Freigabe nach Raeumung und fremde Raeumung ohne Gruppenerweiterung.
Jede Terrainfixture enthaelt maximal12Felder.

Review: unabhaengig statisch, erster Freeze ohne Blocker; Budget-/Sortierungs-
befunde vor Freeze korrigiert. Nachreview der letzten kleinen Raeumausnahme angefragt; dessen Ergebnis steht
bei Uebergabe noch aus.

Finale Quellhashes SHA256:
- Resolver 67ED2A2C919205647703C5871A87A891914837A7A951C3E425C02BD679430D3E
- Verifier E3350982EA477FBFB13D9CE3ABEB337DDD6BBF2AAE47E195A1D050E18EE01C74

Grenzen: Graph und Ruecksetzvorschlag sind lokal/begrenzt, keine generelle
Deadlock- oder Performancemessung. Bestandscommit vor ausstehendem Feldwechsel
kann neue Auftraege konservativ pending halten. Atomarer Ownercommit und AP5
sind extern. Keine native/GPU/Gefechts-/Save-/Netzwerk-/FPS-Abnahme.

Root integration review: independent v1 review passed; final narrow corridor-clearing gate and its regression were read by Root after the worker freeze. No new blocker found. Original frozen hashes verified before LF normalization; source bytes and preserved original hashes are in source_manifest.json. No additional test/Godot run by Root;26/0 is the recorded private worker fixture, not a native movement or owner-commit pass.
