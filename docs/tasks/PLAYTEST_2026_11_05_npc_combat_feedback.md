# NPC-Identitaet und sichtbare Kampfereignisse

## Ziel / Problem
Untertask von `PLAYTEST_2026_11_05_fullscreen_ux_visuals.md`: echte Schuesse
sollen im Vollbild erkennbar sein. Down/Bleedout behaelt dieselbe Figur,
Ausstattung und Identitaet in liegender Darstellung. Formbasierte Icons
ergaenzen die vom Unit-Owner gelesenen Zustandslabels.

## Bestaetigter Codebefund / Ursache
`TerrainMap3DView._create_unit_proxy()` erzeugt fuer animierte Gegner neben
dem Modell einen sichtbaren `UnitBodyReadabilityCore` als CapsuleMesh.
`_update_unit_vital_visual()` kippt nur das Figurenmodell, senkt es dabei
pauschal ab und laesst den separaten aufrechten Kapselkoerper sichtbar.
Das vorhandene Waffenfeedback deaktiviert die Flash-Textur vollstaendig und
verwendet sehr schmale Weltlinien. Ob und wie stark diese im normalen
Vollbild verschwinden, wird vom Root separat nativ belegt.

## Umfang / Nicht-Ziele
Nur lesende NPC-/Combatdarstellung, keine Damage-, Heilungs-, Respawn-,
Sichtbarkeits-, Animationsasset- oder Waffenregeln. Collision-Capsules bleiben
unveraendert. Keine erfundenen Feuerstoesse und keine Information ueber
Unknown-Gegner. Root besitzt Engineprozesse und die Vollbildabnahme.

## Vertraege / Dokumente
AGENTS und vier Kerndokumente; `unit_facing_visual_contract.md`,
`combat_loop_authority_contract.md`, `multiplayer_snapshot_replication_contract.md`,
`graphics_reference_revision_contract.md`, `weapon_fire_vfx_inventory.md`.
Die bestehenden Runtimefiguren und ihre Materialien sind die Identitaetsreferenz;
native Vorher-/Nachherbilder kommen vom normalen Spielpfad.

## Akzeptanz
- Dasselbe originale Modell inklusive Helm und Waffe bleibt durch Down,
  Bleedout und Respawning erhalten. Seine liegende Unterkante wird gegen
  die lokale Bodenflaeche abgestuetzt; keine sichtbare aufrechte Ersatzkapsel.
- Heilung/Respawn stellt die gespeicherte Ausgangstransformation wieder her.
- Reale, sichtbare Fire-Events erzeugen genau einen zeitlich begrenzten,
  kameralesbaren Muendungsimpuls mit zugehoerigem Schusssymbol.
  Derselbe Event startet durch einen Order-Rebuild keinen neuen Impuls.
- Ohne Event kein Schusssymbol; unter FoW gesperrte Events erzeugen keines.
- Zustandsicons unterscheiden mindestens Verletzung, Down und Respawn
  durch ihre Form. Der vorhandene Zustandstext bleibt lesbar.
- Root fuehrt zuerst den neuen Verifier gegen unveraenderte Produktion aus,
  danach gezielte Regressionen und natives Vollbild mit Zeitfolge.

## Dateien / lokale Pruefung
`scripts/terrain/terrain_map_3d_view.gd`: nur abgestimmte NPC-/VFX-Methoden.
Neue kleine Visualhelper neben der Ansicht; Verifier
`scripts/tests/playtest_20261105_npc_combat_feedback_verifier.gd`.
Benachbarte Gates: TASK471, TASK474, TASK401 und TASK403. Headless beweist
Struktur/Lifecycle; echte Sichtbarkeit erfordert Root-Vollbildbilder bei
Ereignisbeginn, ca. 120 ms und nach Ablauf sowie Down/Bleedout/Heilung.

## Risiken / offene Punkte
Die eigene normale Kamera muss den Flash ausreichend zeigen. AABB-Unterkanten
sind konservative Modellgrenzen und werden nativ auf Schweben/Clipping geprueft.
Keine gestalterische Nutzerabnahme oder allgemeine Performancefreigabe.

## Status
Root hat die unveraenderte NPC-Produktion vor der Korrektur seriell geprueft:
`output/playtest_20261105/visual_red/20261105T062529Z-c624e6a0/npc_feedback.log`
zeigt 11 bestandene und sechs erwartete Fehlpruefungen ohne Parserfehler.
Fehler: fehlende Wund-/Downicons und Flash, aufrechte Kapsel, Modell unter
Boden sowie Kapsel waehrend Respawn. Der spaeter ergaenzte Heilungs-/Unknown-
Teil ist bei diesem ersten RED-Log noch nicht enthalten.

Die freigegebene Korrektur ist umgesetzt: begrenzter Eventimpuls mit SVG-
Schusssymbol, separate Source-FoW-Grenze, formbasierte Ownerzustandsicons,
ausgeblendete aufrechte Readability-Capsule bei vorhandenem liegendem Modell
und konservative Modell-Unterkantenstuetze statt pauschaler Absenkung.
Die urspruenglichen Modelle, Materialien und Anhaenge bleiben erhalten.
`git diff --check` ist ohne Befund. Quellen sind fuer Roots GREEN-Lauf
eingefroren; native Vollbild-Sichtpruefung und Nachbartests bleiben offen.
