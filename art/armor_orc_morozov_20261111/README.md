# ORC-/Morozov-Richtung auf dem vorhandenen Kenney-Rig

Archivierter Vorher-Vergleich; aktive Modellrevision siehe
`../armor_kenney_r05_20261111/README.md`.

Revision04,11.11.2026. Drei eigene Rüstungsstufen, im isolierten Taskbranch
eingebaut. Kein neuer Körper, keine Änderung von Kopf-/Hand-/Fußgröße oder Rig.
Star-Citizen-Bilder sind Konstruktionsreferenzen; Pakethelme wurden nicht als
neue Rüstung übernommen. Das ältere Achtansichtenbild bleibt im Vorgängerpaket.

## Bildstatus und Nutzerfeedback

Die beiden ersten `medium_turnaround_ai.png` und `heavy_turnaround_ai.png`
entstanden mit der eingebauten Bilder-KI aus dem nativen Prototyp
`native_generation_input.png` sowie der jeweiligen Star-Citizen-Abbildung.
Der Nutzer fand die Bilder gut und den schweren Körper passend. Seine Korrektur:
die ORC-Fassung ähnelt bereits leicht; leicht noch schmaler/weniger,
mittel dicker/stärker. Die Schweißerbrille gefällt nicht; Mundstück unsicher.

Danach entstanden drei getrennte Revisionsaufträge mit den ersten Tafeln als
Eingaben. Aktuelle **2D-Modellvorlagen**:

- `light_turnaround_ai_r04.png`: reduzierte ORC-Abdeckung.
- `medium_turnaround_ai_r04.png`: dickere Platten, stärkere Schultern/Beine.
- `heavy_turnaround_ai_r04.png`: gleicher schwerer Körper, integriertes Visier
  statt aufgesetzter Brille, flacher Kinnschutz statt großer Atemmaske.

Alle Tafeln zeigen Vorder-/Rück-/Seiten- und obere Ansicht. Die generierten
oberen Ansichten sind bildlich geneigt und keine maßhaltigen Orthoprojektionen.
Die wiederholten Hauptformen wurden betrachtet; Details sind Modellvorgaben,
keine automatisch konsistente technische Zeichnung. Der Nutzer hat die drei
Tafeln als Richtung bestätigt; die nativen Modelle bleiben ohne Stilabnahme.
Neuere Korrekturen haben Vorrang vor älteren Tafeldetails: Auch leicht erhält
feste Wangen-/Kinnschalen. Leicht und mittel bekommen ein klares geschlossenes
Visier mit Dichtrand. Ihre Helme sollen weltraumtauglich wirken; die leichte
Form verbindet den vorhandenen Spacehelm mit ORC. Platten näher an der echten
Körperoberfläche führen und übermäßige Dicke reduzieren. R04 bleibt deshalb
ein archivierter technischer Vergleich, während Astra Ultra R05 überarbeitet.
Als zusätzliche, wahrscheinlich gemeinte Scout-Referenz dient der Field Recon
Suit von Clark Defense Systems; diese Nutzerzuordnung ist nicht bestätigt.

`prompts.json` enthält die beiden ersten vollständigen Prompts,
`prompts_user_revision.json` die drei Revisionsprompts. Werkzeug: eingebaute
`image_gen`-Bildgenerierung, kein CLI/API-Fallback. Ein Ultra-Schalter wurde vom
Werkzeug nicht angeboten und wird hier nicht als verwendeter Modus behauptet.
Originaldateien bleiben zusätzlich am generierten Codex-Speicherort erhalten.
Eingaben, Elternbilder, Ausgaben und SHA-256 stehen in `manifest.json`.

## Modelle

`build_outfit_parts.py` erzeugt eigene geformte Teile und prüft Geometrie,
UVs und Normalen. `armor_outfit_parts.blend` ist die editierbare Bibliothek;
27 Exporte liegen in `Assets/curated/personnel/armor_orc_morozov_20261111`.
Kein neuer Schutzwert, kein zusätzliches Inventar oder kostenloses Equipment.
Alte Modell-/Bildversionen bleiben in ihren bisherigen Paketen erhalten.

Der bestehende Projektor bindet9/15/20 Segmente an die tatsächlichen Knochen
für leicht/mittel/schwer. Ein gecachter skinnender Mesh je Outfit, maximal fünf
Materialflächen. Originalkopf bleibt unverändert; nur schwer projiziert eine
Version ohne Kopfpolygone unter dem geschlossenen Helm. Wechsel zu mittel,
leicht oder Anzug stellt ihn wieder her. Neutrale alte Panzeraufdrucke werden
im Unteranzugshader beruhigt, warme Haut-/Haarfarben und dunkle Gesichtszüge
bleiben erhalten. Keine State-Mutation durch das Visual.

Blender5.1.1; QA27/27 ohne Geometriefehler. Warnungen zu mittigen Wearable-
Pivots sind erwartbar. Bei acht schweren Teilen bleiben geschlossene verdeckte
Kontaktflächen der aufgesetzten Bänder erhalten: rund100 Dreiecke je schwerem
Outfit, für geschlossene einzeln editierbare Bauteile akzeptiert. Keine sichtbaren
koplanaren Flächen; keine Z-Fighting-Fehler. Dies ist keine allgemeine FPS-Freigabe.

Quellen nur als Formreferenz, keine ungeprüften aktuellen Spielwerte:

- https://starcitizen.tools/ORC-mkV
- https://starcitizen.tools/Field_Recon_Suit
- https://starcitizen.tools/Field_Recon_Suit_Helmet
- https://starcitizen.tools/Morozov-SH
- https://robertsspaceindustries.com/en/comm-link/spectrum-dispatch/19122-Portfolio-Clark-Defense-Systems-CDS

Wiederholung: Blender5.1.1 im Hintergrund mit `--python-exit-code 1 --python
art/armor_orc_morozov_20261111/build_outfit_parts.py -- C:/Temp/armor-review`.
Der Builder benötigt die lokale Blender-Asset-QA unter `.codex/skills`.
Native Nachweise: `docs/qa/armor_orc_morozov_20261111/README.md`.
