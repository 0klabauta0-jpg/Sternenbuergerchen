# R3: fokussierte UI-/Kamera-Quellpruefung

Geprueft am2026-11-07: `scripts/ui/native_ui_icons.gd`, die neuen
Icon-/Minimum-/Teamrahmenpfade in `scripts/ui/mission_a5_hud_layout.gd` sowie
`_frame_reference_mission_camera` und sein unmittelbarer Aufrufer in
`scripts/tests/mission_test_setup.gd`. Dazu die beiden R3-Tasks und ihre
fokussierten Verifier. Gemeinsames Theme, Rahmenzeichner und bestehende
Kamera-Framing-API wurden als Abhaengigkeiten lesend verfolgt.

## Aktuelle P1-/P2-Befunde

Keine konkreten aktuellen P1-/P2-Fehler im geprueften Aenderungsumfang
festgestellt. Die Glyphen werden einmalig gecacht, bestehende Iconressourcen
bleiben erhalten, und die UI-Aenderungen schreiben weder Commands noch
Simulation-/Transport-/Loadoutdaten. Sie erhalten die vorhandenen
Buttoninstanzen, Callbacks und Disabled-Gates. Die native Slotgroesse wird
auch nach generischer Themeformatierung wiederhergestellt; der bekannte
52px-Minimumfall ist im aktuellen Verifier enthalten.

Der Teamrahmen liest sein ruhiges Darstellungsflag im vorhandenen passiven
Zeichner; kein zweiter Control-/Inputbaum entsteht. Der neue Kameraeinstieg
ist an die exakte GM01-Layout-ID gebunden, verwendet vorhandene Marker und
die bestehende Hex-/Kamera-API. Nur erfolgreiches Framing setzt das Flag am
konkreten View; Wiederholung desselben Helpers ueberspringt weitere
Framing-/Fokuswrites und bewahrt dadurch spaetere manuelle Kameraaenderungen.

## Nachweisgrenze

Diese Pruefung startet keine Engine und ist keine visuelle oder physische
Spielabnahme. Die Kamera-Fixture belegt den Helper und sein Wiederholungs-
verhalten; ein normaler nativer Einstieg mit anschliessendem Pan/Zoom bleibt
der separate Nachweis fuer den gesamten View-/Setup-Pfad. Die neuen Glyphen,
die GO-Lesbarkeit und der ruhigere Teamkopf brauchen Roots echte Vollbildbilder.
Der korrigierte logische Viewport der Missions-UI-Fixture und ihre drei
Zielgroessen wurden bei der Quellpruefung beruecksichtigt.
