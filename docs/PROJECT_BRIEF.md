# Sternenbürgerchen — Neustart

Autorisiert durch „Dann leg los“ am 12.09.2026 nach Review 3 des Neustartplans. Neue Projektbasis: `C:\dev\SternenBuergerchen-Neustart`, eigener Branch `codex/neustart-n0-n1`, neue Historie im bestehenden GitHub-Repository; kein Umbau der alten Runtime.

Commander führt zunächst zwei befreundete NPCs aus einer sichtbaren kleinen Rostwelt-Basis. Zwei Betten, Lager, Werkbank und eigenes kleines Shuttle sind der Einstieg. Anklickbare Arbeitsplätze öffnen passende Menüs; geeignete Arbeiter führen die Aufträge dort aus. Satellitenbergung, Geld/Blueprint, Markt, Herstellung, Reparatur und Rückkehr schließen den ersten Spielkreis.

Rostwelt mit Space-Opera-Formen: großzügige Gebiete um einzelne Einsatzorte, entfernte Landung, klare Wege und geschichtete Felsen. Einzelne Karten und sichtbare Reiseübergänge genügen. Kenney ist die Modellbasis.

Nachgereichte Nutzerentscheidung während N1: Den bereitgestellten Cutlass-OBJ in Blender vereinfachen und als lokales Startshuttle „Entersäbel“ einsetzen. Weiße Astronauten mit Helm aus den schöneren Kenney-Figuren ersetzen die bisherigen Blocky-Figuren. Factory-Wände und eine größere Grafiküberholung sind ausdrücklich später dran. Die vom Nutzer bereitgestellte Schiffskonvertierung liegt separat unter dem Git-ignorierten `assets/local/`; reproduzierbares Werkzeug und Herkunftsnachweis werden mitgeführt, ohne aus der Konvertierung eine Veröffentlichungslizenz abzuleiten.

Echtzeit mit Pause in Solo und Multiplayer. Koop und PvP bleiben Kernziele. N1 startet lokal; danach folgt N1a als echter Zwei-Client-Nachweis vor Bunker, Kampf oder breiterem Inhalt. Spätere Etappen N2–N8 umfassen Evakuierung/Respawn, Ausbau/Rekrutierung, Raumberufe, Flotte und große kombinierte Operation.

Quelle: `C:\dev\SternenBuergerchen-worktrees\task-neustart-vision-2026-09-12\docs\superpowers\plans\2026-09-12-sternenbuergerchen-neustart.md`, Review-Commit `375f8d21e`.

Letzte Bedienentscheidung: Figuren werden ausgewählt und per Rechtsklick zu einem Laufziel geschickt. Rahmenauswahl für Gruppen; Einzelansicht schaltet Kamerafolge zu. WASD bewegt ausschließlich die Kamera. Die vorübergehend erprobte WASD-Figurensteuerung wurde auf Nutzerkorrektur entfernt.

Letzte Grafikentscheidung: Bereits jetzt eine geschlossene Basiswandkontur mit transparenten Frontwänden sowie ein schlankes Strategie-HUD mit Icons, Crewporträts, kurzen Aktionsbeschriftungen und Tooltips. Der Skill `game-ux-design` und konkrete Referenzscreens wurden dafür verwendet; dokumentiert in `docs/UX_DECISIONS.md`.
