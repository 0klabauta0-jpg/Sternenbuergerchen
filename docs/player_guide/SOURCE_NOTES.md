# Spielanleitung: Quellen und Gültigkeit

Stand der Anleitung: Windowspaket `a377c7346cf6ec27cb9156f72e36e2fd24e406e7`,
Produktbasis `39c36fa4ccd0c5c16ab357dee2b2208aeb961566`. Keine geplanten
Karten-/Fracht-/Servicefunktionen in diesem Paket behaupten. Nachfolgende
Produktänderungen brauchen eine neue Buildzuordnung. Die Anleitung ist eine
öffentliche, eigenständige Seite; Repository und Arbeitsbericht bleiben privat.

## Laufzeitquellen
- Einstieg/Kampagne: scripts/ui/main_menu_screen.gd, scripts/meta/homebase_operations_presenter.gd
- Basis, Auswahl, Reise: scripts/meta/homebase_screen.gd, scripts/meta/singleplayer_runtime_adapter.gd
- Ortsnamen: scripts/mission/campaign_display_catalog.gd
- Tasten: project.godot und produktiver Taktikcontroller
- Speichern: scripts/ui/global_escape_menu.gd und Kampagnen-/Checkpointowner
- Waffenwerte: scripts/core/weapon_data.gd (WEAPON_CATALOG)
- Vorberechnung: scripts/tactical/combat_fire_decision_resolver.gd (build_damage_effect)
- Endchance und Schaden: scripts/core/simulation_root.gd (_apply_damage_effect,
  Deckungs- und Höhenhelper), scripts/core/damage_model.gd
- Genauigkeits-/Bewegungsprofil: scripts/npc/unit_profile_math.gd, scripts/npc/test_unit.gd
- Flanke: scripts/tactical/flank_vulnerability_resolver.gd
- Raumkampf: scripts/tactical/space_weapon_resolver.gd, space_targeting_resolver.gd
- Sitzungen: scripts/multiplayer/multiplayer_session.gd und aktuelle Multiplayercontracts

## Rechnergrenze
Illustratives Modell für bereits zulässige normale Bodenschüsse. Keine Spiel-
oder RNG-Verbindung. Genauigkeitsfaktor 0,5 + Skill und Bewegungsfaktor
0,65 + 0,30 × Skill sind die Standardkurven; konkrete Runtimeprofile können
diese Faktoren überschreiben. Aggregierte Profil-/Ausrüstungsmodifier sind
bewusst Eingabewerte, kein unvollständiger zweiter Charaktergenerator.
Zieldeckung wird bereits kombiniert eingegeben. Die Chancenberechnung wird
für Dezimalbeispiele auf zwölf Nachkommastellen stabilisiert; kein bitgenauer
Replayvergleich. Strikter Vergleich Wurf < Chance; Gleichheit verfehlt.
Keine Behauptung einer einheitlichen Bodenformel für Raum-/Luftwaffen.

## Bild- und Schriftquellen
Unveränderte native Godotaufnahmen aus aktuellem Review:
- home.png: docs/qa/review_completion_20261113/graphics_after/c3aa86fb815f4272b0e81c030985ca9b/images/home_overview.png
- jobs.png: docs/qa/review_completion_20261113/starmap_after/f7d7b2a709c1417c8510d78b172f4ffb/images/smart_mobile_720.png
- starmap.png: gleicher Lauf, starmap_720.png
- Rajdhani-SemiBold.ttf: Assets/curated/smart_mobile_fonts/, originale OFL.txt mitliefern.

Nur index.html, style.css, combat.js, guide.js und assets/ werden in die
öffentliche Site übernommen. Kein QA-Profil, privater Bericht oder Log.

## Prüfung
verify_guide.cjs prüft Katalogwerte gegen GDScript, konkrete von Hand gerechnete
Fälle und Grenzen, mobile Breiten, Suche, Checkliste, Bilddialog, Tastatur,
Anker und Assets in einem frischen Headless-Chrome ohne Benutzerprofil.
Publikation zusätzlich ohne Cookie/Anmeldung per HTTP prüfen.
