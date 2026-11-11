# Lokales Orbit-Anfluglayout: unverdrahteter Authoringkandidat

scripts/mission/orbit_approach_layout.gd erzeugt ausschliesslich frische Geometriedaten. Die lokale Karte hat 512 x 256 Zellen. Die strategische Karte mit 256 x 256 Zellen und die produktiven 3 Orbitmarker bleiben unveraendert. Das Ankunftsband unten, y=224..255, ist eine technische Flaechenvorgabe. Der Runtimeowner prueft die tatsaechlich freie Bottomspawnzelle; der Helper setzt keine Schiffpositionen.

Oben mittig liegt ein nominal 256 Zellen breiter Kreislimb mit sichtbarer Sagitta 4, Kreismitte (256,-2046) und Radius 2050. Der Radius ist nicht 4. Die Spalten 128..383 enthalten konservativ geschnittene Bodyzellen in den Zeilen 0..3. Die erste freie Zelle unmittelbar UNTER der Bodymaske ist je Spalte ein Gatekandidat. Sie liegt ausserhalb der Koerpermaske; spaetere Kollisionen, Befahrbarkeit und Zugang prueft der Runtimeowner. Beide Zellmengen stammen aus derselben limb_depth_at-Unterkante, ohne hardcodierte 3-Gate-Enum.

body_map_id ist 'orbit_approach:' plus URI-kodierte kanonische Body-ID. Sie bleibt deterministisch und kollisionsfrei. Diese logische ID ist kein Dateipfad und kein Save- oder Runtimeobjekt. Leere IDs und IDs mit Randwhitespace werden abgewiesen. Jede Abfrage liefert neue Arrays und Dictionarys, keinen gemeinsam mutierbaren Simulationszustand.

Der Weltraumkampfowner besitzt spaeter Schiffposition, Rotten-/Ortzuordnung, Blockaden und verbindliche Gate-/Landezugangsfreigaben. Das Layout allein erlaubt keinen Anflug und erzeugt keine Reisephase. Warp, lokaler Flug und Saumgate bleiben ein separater produktiver Anschluss. Der bisherige orbit_quantum_travel_contract gilt bis dahin unveraendert. Quelle und kleine Pruefung: docs/tasks/ORBIT_APPROACH_LAYOUT_2026_11_11.md.
