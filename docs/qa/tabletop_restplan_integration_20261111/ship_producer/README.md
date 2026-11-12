# AP6: gebundene Schiffskoerper im tatsaechlichen Controller

Source6a747246c+d18437931 als7fd42e2b6/e0f58b924 integriert. Unabhaengiger
enger Review ohne neue Blocker; identische Sanitizerfelder im Merge in Parent-
Schreibweise behalten, aktuelle Crew-/Visit-/SoloPilot-/lokale Polisa-Admitbodies
und b9f194d9e Renderer-/Visualentryanschluss erhalten.

Frisch privat im gemeinsamen Stand: `python scripts/tests/run_hex_tactical_check.py --case ship_producer`
66/0 und direkt betroffener vorhandener Nachbar `--case deployment_controller`
73/0. Exit0, Quellen und echtes Profil unveraendert, Isolation bestaetigt; genaue
Dateihashes in den Reports. Geprueft: nur angenommene Fremdlandungen als Rumpf,
Sperrprovider bei neuen Tickets, vollstaendige Rootclaims vor Landecommit und
nochmals vor beiden Touchdownpfaden, Profil unveraendert bei zwischenzeitlicher
NPCbelegung, echte Sequenz-Craft-ID fuer Eigenschiffausnahme.

Die Producerprobe verwendet kontrollierte Projektion, keine native Szene. Eigener
enger tatsächlicher Renderjoin unter output/native_glut_maps/ap6_landed_body_join_20261112
verbindet separat vorhandenen Cutlass mit dem Parentgetter. Keine generische
Schiffsnavigationssperre oder volle AP6-Gesamtabnahme: Setup/Basis und danach
AP7/AP8 bleiben offen. Grosse AP9-Tests spaeter, keine EXE/Kartenaktivierung.
