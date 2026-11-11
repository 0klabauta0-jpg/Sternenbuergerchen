# Polisa R04 — Stationskante und fünf Frontpads

Neue Nutzerkorrektur nach R03, R03 bleibt unverändert. Private Authoringdateien
in diesem Ordner, Kandidatenausgaben unter output/native_glut_maps/polisa_r04_20261111.
Produktkarte/Visual, UI, Location und Gameplayowner bleiben bei Root.

## Ziel / Ursache
Station am oberen Weltraumkartenrand, viel freies Vorfeld darunter. Keine
hinteren Pads. Fünf Pads vor einem zentralen Sammelraum, direkte Türen zu
fünf größeren quadratischen Shops. Alle Waren/Rüstungen/Fracht aus normaler
Kamera ohne Drehung erkennbar: niedrige vordere Cutawaywände und kurze
Bodenschilder, keine hohen blickversperrenden Frontblenden.

## Maßvorschlag vor Code
Hub48×32, drei rückwärtige24×24Shops, zwei seitliche24×24Shops.
Padreihe X=-80/-44/0/44/80, Größe24×26 /32×40 /40×48 /32×40 /24×26.
Durchgehendes10breites Dockvorfeld verbindet alle fünf Pads mit dem Hub.
RingeDurchmesser52, Solarflächen14×32 mit längeren technischen Auslegern.
Lokaler Stationsursprung=(0,-64), hintere Wand beiZ=-88. Karte256×256
in rechteckigen Offsetspalten, deklarierter Weltraumrahmen ca256×222.
Globus plus Konsole bleibt etwa mannshoch, umlaufbare Zone um den Sockel.

## Gemeinsame Fakten / Verträge
layout.json besitzt lokale Rechtecke und genau einen origin_plane Offset.
Compiler übersetzt Deck-/Blocker-/Markerfakten einmal; Propcenter verwendet
denselben Ursprung, Visual bleibt lokal. Wände/Türen/Möbel aus derselben Datei.
PROJECT_BRIEF, ARCHITECTURE, CODEX_RULES, graphics_reference_revision_contract
und godot-procedural-worlds gelesen. Bestehende R07-Armorhelpers unverändert.

## Akzeptanz / lokale Prüfung
Alle begehbaren Deckzellen, fünfPads und Shopzugänge verbunden. KeinePad06,
spawn/return/service IDs erhalten. Rückwand geschlossen, kein Deck dahinter.
Ringdurchmesser mindestens48. Räume im selben Standardblick lesbar.
Zwei native Artansichten: Stationnah mit echtem Hexraster, ganze deklarierte
Map mit großem Vorfeld; Root erzeugt echtes Kaufmenü separat. Kleine Offline-
Faktenchecks, zwei Artansichten, keine Gefechte/Benchmarks/Testmatrix.

## Grenzen
Keine behauptete Caterpillar-Landbarkeit, Reise-/Shop-/Save-/NPCabnahme.
Keine Kommits/Push, keine Status-/Activeworkplanänderungen. Künstlerische
Sichtung durch Nutzer bleibt offen. GPU erst nach Rootfensterfreigabe.
