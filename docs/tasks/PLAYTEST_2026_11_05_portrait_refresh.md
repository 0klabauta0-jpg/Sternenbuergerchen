# Zusammenhaengender Portraetpass, 2026-11-05

## Ziel / Problem
Die 42 bestehenden Portraetidentitaeten zeigen uneinheitliche alte Pixel-/Bildstile.
Der aktuelle Nutzerauftrag verlangt neue, zusammengehoerige Viererboegen mit
gut lesbaren Einzelgesichtern in der Bildsprache der bestaetigten 2D-Ziele.

## Ursache / Sinnhaftigkeit
Der vorhandene Katalog ist bereits gemeinsame Identitaetsquelle. Sein Resolver
priorisiert stabile IDs. Deshalb wird die Bildzuordnung dort erneuert, ohne
Roster, gespeicherte Identitaeten oder Gameplayzustand umzuschreiben.

## Umfang / Nicht-Ziele
- Elf 2x2-Boegen A bis K: 44 unterschiedliche erwachsene Gesichter, davon 42
  den bestehenden IDs zugeordnet und zwei explizite Reserven.
- Bogen A ist die vom Root erzeugte aktuelle Stilreferenz; B bis K verwenden
  A als Bildreferenz bei built-in image_gen. Originale/Prompts/Hashes erhalten.
- Exakte AtlasTexture-Quadranten verwenden die PNGs ohne Bildbearbeitung oder
  erneute Rasterung. Alle Produktpfade bleiben projektlokale res://-Pfade.
- Bestehende 42 IDs, Tags und Kandidatenstatus erhalten. Alte explizite Pfade
  ID-loser Profile duerfen lesend als Legacy-Aliase zum selben ID-Eintrag fuehren.
- Keine Roster-/Savewrites, UI-Neuentwicklung, Engine-/Importlaeufe oder Gitaktionen
  durch diesen Untertask. Root besitzt UI/MetaProfileBuilder und native Tests.

## Relevante Dokumente
AGENTS.md, PROJECT_BRIEF, ARCHITECTURE, CODEX_RULES, IMPLEMENTATION_STATUS,
TASK_ROADMAP, PLAYTEST_2026_11_05_fullscreen_ux_visuals,
graphics_reference_revision_contract, character_roster_generation_contract,
player_roster_save_contract und ui_native_design_contract.

## Akzeptanzkriterien
1. Alle elf tatsaechlichen Projekt-PNGs wurden geoeffnet und auf vier getrennte,
   vollstaendige, klar verschiedene Gesichter, konsistente Palette und Framing
   geprueft. Sichturteil und verbleibende Unterschiede je Bogen dokumentieren.
2. 42 vorhandene IDs/Tags bleiben exakt erhalten, 42 eigene Atlasregionen sind
   zugeordnet; zwei weitere Regionen sind ohne neue Rosteridentitaet Reserve.
3. 42 Texturen laden nach dem Import in Godot als AtlasTexture mit exakter
   2x2-Region. Mindestens 30 Kandidaten bleiben verfuegbar.
4. Bekannte IDs schlagen gespeicherte Altpfade; bekannte Altpfade ohne ID
   fuehren zum aktuellen Bild derselben bisherigen Identitaet. Fremde gueltige
   res://-Pfade behalten ihren bestehenden expliziten Fallback.
5. Quellenmanifest enthaelt Prompts, Originalpfade, lokale Lieferdateien,
   SHA-256, Abmessungen, Regionzuordnung und Bildstatus. Keine Homepfade in
   produktiven Katalog-/Ressourcenreferenzen.

## Betroffene Dateien
data/portrait_identity_catalog.json, scripts/meta/portrait_identity_catalog.gd,
Assets/curated/portraits/frontier_20261105/, art/portraits_20261105/,
scripts/tests/playtest_20261105_portrait_atlas_verifier.gd.

## Lokale Pruefung
Read-only PNG-Abmessungen/SHA und Quellenmanifest statisch pruefen. Root fuehrt
Import, gezielten Atlas-/ID-/Legacy-Verifier, bestehenden TASK_233 und echte
Vollbild-Karten-/Character-Sheet-/Rosterpruefung seriell aus. Native Sicht,
Nutzerurteil und allgemeine Releaseabnahme sind getrennte offene Gates.

## Risiken / offene Punkte
Auch klare Gesichter muessen bei echten UI-Groessen nativ geprueft werden.
Alte direkte Pfadlader in Homebase/FOB/MetaFlow benoetigen Root-seitige Routing-
Anpassung zum bestehenden Katalog; der Untertask fuehrt keine zweite Wahrheit ein.
AtlasTexture vermeidet Zusatz-PNGs, der PNG-Import und Randfilter bleiben nativ
zu pruefen. Gestalterisches Nutzerurteil bleibt offen.

## Status
Akzeptanz vor Assetintegration festgehalten. Elf originale Projekt-PNGs A bis K
geoeffnet und visuell geprueft; vier vollstaendige verschiedene erwachsene
Gesichter je Bogen. Koharente Palette/Maltechnik, keine sichtbare wiederholte
Identitaet. Einige Haarspitzen haben weniger als die angestrebten sieben Prozent
Oberrand, bleiben aber vollstaendig sichtbar. Sichturteile je Bogen im Manifest.

42 Katalog-IDs/Tags/Kandidatenflags unveraendert, 44 exakte 627x627-AtlasTexture-
Ressourcen erzeugt, zwei Reserven ohne neue Rosteridentitaet. Bekannte alte
PNG-Pfade funktionieren als lesende Legacy-Aliase. Nur der unveraenderliche
Standardkatalog wird pro Prozess gecacht; Customkatalogpfade lesen frisch.
Standard-Rueckgaben sind tief kopiert, die reine Pfadauflosung liest den Cache
direkt. Keine Roster-/Savewrites oder Gitaktionen in diesem Untertask.

Statisch gruen: `python art/portraits_20261105/verify_portrait_sources.py`.
Der Marker `PORTRAIT_SOURCE_VERIFY_PASS` bestaetigt Original-SHA/Prompts,
elf PNG-Abmessungen, 44 eigene Regionen, bestehende Identitaeten und lokale
Produktpfade. `manifest.json` enthaelt die vollstaendige Quellkette;
`catalog_before_refresh.json` erhaelt die alte Zuordnung und Quelleninventur.

Gezieltes Enginegate bereit:
`scripts/tests/playtest_20261105_portrait_atlas_verifier.gd`, Marker
`PORTRAIT_ATLAS_VERIFY_BEGIN` / `PORTRAIT_ATLAS_VERIFY_PASS`, numerische RESULTS.
TASK_233 prueft weiterhin alle 99 erhaltenen Legacy-PNGs und zusaetzlich die
elf aktiven Boegen; die alte feste Assets/Char-Pfadannahme wurde auf den aktiven
kuratierten Root aktualisiert. Engine-/Importlauf, echte UI-Groessen und
Vollbildsicht prueft Root separat. Gestalterisches Nutzerurteil bleibt offen.
