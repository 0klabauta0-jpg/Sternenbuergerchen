# Reine Motionprojektion: erster AP5-Teil

Basis04dc691bb. Keine View-/Actortransforms oder echten Commands geändert.
Root-/Groundreadadapter liefern nur eine stetige Darstellung der bereits
committeten Segmente. Keine Karte aktiviert und keine native Bewegungsabnahme.

Isolierter Godot4.6.2-Runner, drei kleine finale Cases:

| Case | Bestanden / fehlgeschlagen |
|---|---:|
| projection |56 /0|
| owner |53 /0|
| facing |24 /0|

`python scripts/tests/run_hex_tactical_check.py --case CASE` reproduziert sie
mit echten Quellen und frischen privaten Profilen. Alle finalen Canary-/Quell-/
Originalprofilguards grün, Prozess0, keine Script-/Leakfehler. Manifest nennt
ausgeführte Quellhashes; alle Originalversuche im ZIP erhalten.

Pro Bewegungsfixture zwei oder drei Tiles, sechs Rampenrichtungen auf/ab,
eine per Runtime geöffnete Raw-Blockerrampe, geknicktes H+0,5-Band und
nahtlose Folgesegmente. Fraktionale Reads verändern keinen Zustand; Plateau
bleibt bis zur Kante flach. Logischer Feldwechsel liegt auf der geteilten Kante,
vollständiges Segmentende ist separat. Unbekannte Unit/NAN ergibt keine Projektion.

Anfängliche Fixture hatte statischen Configure-Arityfehler; nicht als RED
gewertet. Danach sauberer RED0/1 wegen fehlender Projektions-API, GREEN49/0,
erweitert56/0. Frischer Review fand Nichtregionalhöhe0 als gültigen Sentinel:
RED33/1, GREEN53/0. Konfigurationsvoraussetzung entfernt; Readparameter für
Höhenskala verhindert eine zweite Terrain-3D-Mappingwahrheit. Späterer View-
Aufrufer muss sein bestehendes `_get_3d_height_step()` übergeben. Nachreview
ohne neue Defekte; Reviewer startete keine Engine und änderte keine Dateien.

Weiter offen: Root-Movebatch, tatsächliche Zielankunft, sichere gemeinsame
Stoppgrenze, Türguard, Ausschluss von Legacy-Avoidance/Spacing und Viewanschluss.
Große Karten-/GPU-/Gefechts-/Performanceprüfungen folgen später. Keine gemessene
Einsparung oder flüssige native Bewegung aus diesen Logikchecks ableiten.
