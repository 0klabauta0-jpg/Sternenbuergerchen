# Gebundenes Polisa-Bodenschiffsprofil — enge Owner-QA

Produktfreeze: nur die zwei reservierten Controllerbodies und der neue reine
Profilhelper. Kein Renderer-/Root-/Flow-/Ground-/Crew-/Positionsumbau.

Abschluss: **12/0**, Exitcode 0, Godot 4.6.2, sauberes Log, privates user-Profil
mit Isolationcanary; echtes Spielerprofil und kopierte Produktquellen unveraendert.
Gruener Bericht: `bound_body-592a148439e74bd2a74c99476cba0727/report.json`,
Log daneben `output.log`. Der Controller und Helper kompilieren dabei echt.

Die Probe nutzt die echten Controller-Preview-/Admit-Bodies mit FakeView, einem
aus den echten R08-Padfakten gespeisten Mapdouble und kleiner freier Registry.
Andere Carddarstellungsmethoden sind kontrolliert, kein Szenenstart und keine
echte Mesh-/Rendererabnahme. Viewbounds/Scale/Asset-ID kommen aus dem vorhandenen
Frontierkatalog; Kamera-Yaw wird im Double geaendert.

Geprueft: akzeptiertes detached Previewprofil und Admitbindung, kein Alias zum
Viewdictionary, keine Viewabfrage belegter Schiffe nach Kameradrehen, unveraenderter
belegter Footprint, relevanter Profildigest, fremde Craft-/Modell-/Assetzuordnung,
ungueltiger Zahlentyp sowie fehlendes Altprofil ohne Reparatur/Mutation.

Roter Produkt-Ausgangslauf: `bound_body-4b085d6acdb34fa483cbee09e1f983f9/output.log`
mit 0/3 (Profil fehlt in Preview/Admit, Altstand wird nicht failclosed behandelt).
Dieser Lauf hatte zusaetzlich fehlende Texturabhaengigkeiten des privaten Imports;
die drei Domainfehler wurden separat ausgegeben. Vorherige private Runneraufbauten
mussten `extends`-/TS​​CN-/Texturpreloads in die Closure aufnehmen; diese Infrastruktur-
fehler sind keine Produktbefunde. Erster sauberer Gruenlauf 11/0:
`bound_body-23a50adf1b3d40adba060c99af90ace8/`. Danach nur den vom Parent explizit
verlangten Digestcheck ergaenzt, Abschluss 12/0 oben. Kein Produktfix fuer QAfehler.

Reproduzierbar vom Projektroot:

```powershell
python output/native_glut_maps/polisa_bound_ground_body_20261112/run.py
```

Der eigene Runner kopiert nur die Resourceclosure plus JSONdaten/R08layout und
die benoetigten expliziten GLB-/Texturabhaengigkeiten in ein privates Projekt.
Kein gemeinsamer Runner wurde geaendert, keine Gitaufnahme/kein Commit.

Aktivierungsgrenze: bisher ungebundene normale Besucher blockieren Kauf bewusst
mit `ground_ship_geometry_unbound`. Ihr eigener Bindungsproducer folgt beim
Tabletopowner. Keine Save-/Grafik-/native Reise-/Performancegesamtabnahme.
