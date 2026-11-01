# Sichtpruefung der finalen normalen Kenney-Figuren

Geoeffnet wurden die vom Engine-Vorschaupfad frisch erzeugten Bilder:

- `docs/reports/assets/grafik-2026-11-01/engine_pass/crew.png`
- `docs/reports/assets/grafik-2026-11-01/engine_pass/walk_pose.png`

Der uebergeordnete Renderlauf nennt Godot 4.6.2, Forward+ / Vulkan.
Die erste Aufnahme zeigt alle vier normalen Kenney-Astronauten mit den
zugeordneten Originaltexturen. Die urspruenglichen grossen Koepfe und kompakten
Koerperformen sind erhalten; eigene Koepfe, Panzerplatten oder Manschetten
sind nicht zu sehen. Die zweite Aufnahme zeigt eine Figur seitlich in Bewegung.
In diesen beiden Bildern wurden keine offensichtlichen Gelenkkollapsen,
abgetrennten Koepfe, langen Skin-Spitzen oder losen Ausruestungsteile gefunden.
Die Stiefel schliessen an den sichtbaren Boden an.

Die dunkelrote Gesichtsfarbe rechts stammt aus der unveraenderten Originaldatei
`Assets/used/npc/animated_characters/skins/astroFemaleA.png`; auch diese PNG wurde
geoeffnet. Sie ist keine neu erzeugte Hautfarbe oder Shaderkorrektur.

Die beiden Einzelbilder ersetzen keine vollstaendige menschliche
Animationsabnahme. Die zugehoerigen technischen Nachweise sind
`stock_roundtrip.json`, `stock_manifest.json` und
`source_animation_settings.json`. Diese Sichtpruefung betrifft ausschliesslich
den finalen stock-Satz, nicht die verworfenen Eigenbau-/Umbau-Studien.
