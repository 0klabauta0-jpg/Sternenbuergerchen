# AP6: begrenzter gemeinsamer Bodyraster

Source62b1454af als d9059a590 integriert; keine doppelte Uebernahme der bereits
vorhandenen Parent-Profil- und Bodyhelper. Enger unabhaengiger Review ohne Blocker.

Frisch im Parent: `python scripts/tests/run_hex_tactical_check.py --case ship_footprint`
52/0 einschliesslich42 vorhandener Bewegungsgrundfaelle. Exit0; alle Quell-,
Profil- und Isolationsguards gruen (siehe report.json). Reale Rootaufnahme unter
optionaler Bodyausschlussmaske, ganze Hexflaechen mit Randkontakt, abweichende
Registrymetrik und Budget-/Identitaetsfehler vor einer Teilmaske geprueft.

Noch keine konkrete Schiffslandestandsquelle oder Cache-/Consumeranbindung;
keine dauerhafte dynamische Schiffssperre durch den optionalen Planparameter.
AP6 insgesamt und AP7/AP8 bleiben offen. Keine grosse/native Gefechts- oder
Leistungsprobe, keine globale Kartenaktivierung und kein EXE-Build.
