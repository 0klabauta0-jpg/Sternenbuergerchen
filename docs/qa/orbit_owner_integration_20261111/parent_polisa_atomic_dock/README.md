# Polisa: Dock-/Undocktransaktion im gemeinsamen Ownerstand

Source ea831d115 plus Reviewkorrekturen a906edb49/b1d1991ad als
2eaf34cbb/ffdd3cc2e/b0aa558b0 integriert. Unabhaengiger Review fand zuerst den
Flowkontext nach synchronem Departureevent; Parentnachpruefung fand dieselbe
Grenze im Campaignobserver. Beide neuen Stationszweige erzeugen Flowidentitaet
jetzt vor externen Events, danach kein veralteter Begin-Callback. Legacy-Surface-
Reihenfolge durch diese Fixes nicht geaendert. Enger Folge-Review geschlossen.

Frische private Parentpruefungen: `python scripts/tests/run_orbit_owner_integration_check.py polisa_atomic`
und direkt betroffener Nachbar `... approach_cancel`. Beide Exit0, Logs sauber,
Quellen-/Profil-/Canaryguards true. Exakte getestete Quellhashes in den Reports.
Dockprobe verwendet echte Root/Fleet/Flight/Supply/Campaignowner mit kontrolliertem
Pilot-/Visit-/Flowadapter. Oeffentliche Adapteroperation prueft konkrete
Flowidentitaet vor Events und reentrantes Finish auch im Campaignmodus. Weitere
Checks: Abbruch, Fremdtransfersequenz, Wiederanflug ohne zweite Hinbuchung,
fehlender Pilot, belegtes Rueckkehrgate, Return-Fuel/Replay/Events genau einmal.

Separat UI785b73306: expliziter lokaler Stationsbutton mit frischem Roottarget,
10/0 und Compile0 nach unabhaengigem Review; controlled Provider/Commandrecorder.
Kein gemeinsamer nativer UI-/AP6-Stationsbesuch oder vollstaendiger Boardingweg
wird durch diese beiden begrenzten Proben nachgewiesen. Gekaufte Schiffe ohne
inaktiven Actor gehoeren zum gesonderten Erstaufnahmepaket. Kein Featureflag-
oder LiveJSONwechsel, kein EXE-Build, keine grosse Gefechts-/Leistungsabnahme.
