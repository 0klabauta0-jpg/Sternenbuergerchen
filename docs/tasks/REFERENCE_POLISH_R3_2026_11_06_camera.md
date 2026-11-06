# R3: einmaliger GM01-Kameraeinstieg

Ziel: Figuren und Gebaeude im normalen Missionseinstieg naeher wie in der A5-2D-Vorlage lesbar zeigen. Der bisherige globale Standard 34 bleibt fuer andere Karten/Editor erhalten; nur der authored GM01-Missionseinstieg rahmt Spawn Alpha und das bekannte Missionsziel mit Groesse 22 ueber `frame_world_positions`.

Umfang: `mission_test_setup.gd` und fokussierter Verifier. Kein Gegner-Lookup, keine Actor-/Gameplay-/Mapmutation, kein Zuruecksetzen spaeterer manueller Zoom-/Pan-Eingaben. Wiederholtes Configure desselben Views darf den Kameraeinstieg nicht wiederholen. Fehlendes Map/View/Marker muss sicher bleiben.

Contracts: PROJECT_BRIEF, ARCHITECTURE, CODEX_RULES, graphics_reference_revision_contract, ui_native_design_contract. Ursache: bisher nur Zielzentrierung mit globaler Groesse 34; Bezugsobjekte wirken zu klein.

Akzeptanz: nur exakte GM01-Layout-ID; bestehende Weltkoordinaten; bestehende Hex-Projektion im View; keine neue Kameramath. Erster erfolgreich gerahmter Einstieg einmal, fehlgeschlagener Versuch wiederholbar; andere Karten unveraendert. Fokussiert RED/GREEN sowie normaler nativer Vollbildstart und separate Vergleichskamera 34. Risiko: engerer Einstieg zeigt weniger Welt; manueller Zoom bleibt vorhanden. Vollbild-PNG entscheidet die praktische Lesbarkeit.
