# Orbit UI → Owner: eine enge Integrationsprobe

Status: nach bestätigtem Produktfreeze ausgeführt: **10/0**, Godot 4.6.2,
Exitcode 0, sauberes Log. Bericht und Log im Unterordner
`ui_join-7a95e75b2de94208968504233912bedf/` (`report.json`, `output.log`).
Privates Profil mit Isolationcanary, echtes Spielerprofil unverändert,
kopierte Produktquellen vor/nach Lauf per SHA256 unverändert.

`check.gd` verbindet echte StarMapScreen und OrbitAreaCanvas mit echtem Adapter,
SimulationRoot, Fleet/Flight und Equipment. Nur der vollständige UI-Snapshotrahmen
ist kontrolliert; Areaabfragen und sämtliche UI-Commands gehen an den echten
Adapter. Der Pilotowner ist ein bewusstes kleines Anwesenheitsdouble, wie im
bestehenden `space_singleplayer_move_verifier.gd`. Ein FlowEnvelope enthält nur
`_selected_mission_id` und `_last_mission_result`, damit auch die echte
Adapter-Travelprojektion verwendet wird. Die Aufnahme benutzt den tatsächlichen
Equipment-Footprint (Cutlass: zwei Felder).

Zehn Assertions prüfen keine automatische Auswahl, explizite Auswahl des zweiten
Schiffs hinter einem geerdeten ersten Schiff, den echten lokalen Actorsnapshot,
Orbitbutton, Canvas-Move über das Screensignal und Adapter/Root, echte Bewegung
nach genau einem Ownerfortschritt und anschließendes Lesen dieser Position.
Auswahl des geerdeten ersten Schiffs darf nicht zum lokalen Schiff zurückfallen.

Isolierte Ausführung nach Freeze, vom Projektroot:

```powershell
python output/native_glut_maps/orbit_ui_owner_join_20261111/run.py
```

Erwartet: Exitcode 0, `ORBIT_UI_OWNER_JOIN passed=10 failed=0`, keine Scriptfehler.
Kein Native-/GPU-/Performancebeleg, kein Warp-/Boarding-/Savecheck und keine
Gesamtabnahme. Die Probe enthält keine Produktänderung und erzeugt keinen Commit.

Fixturekorrekturen während genau dieser Probe:

- Erster Lauf: beim Übernehmen des echten Equipment-Footprints fehlte das vom
  Admissionvertrag zusätzlich verlangte `start_hex`; Assertion, danach Timeout.
  Wieder ergänzt. Historisches Log: `ui_join-54d3e329d25344dd961c0ddef3e205dc/output.log`.
- Zweiter Lauf: alle zehn Checks bestanden, Log jedoch korrekt rot wegen eines
  nicht mitkopierten Cutlass-GLB, das die echte Systemkartenvisualisierung über
  den Katalog lädt. Historischer Bericht: `ui_join-a7f93d66d16b4de286f99710881d64a1/report.json`.
- Privater eigener Runner kopiert nun zusätzlich Shaderpreloads und genau dieses
  1,47-MB-Modell; der dritte Lauf ist der oben genannte saubere Abschluss.

Kein Produktcode wurde für einen Fixturefehler angepasst. Der gemeinsam genutzte
`scripts/tests/run_orbit_owner_integration_check.py` blieb unangetastet.
