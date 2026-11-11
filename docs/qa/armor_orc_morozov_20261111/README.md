# R04 — technischer Rüstungsentwurf, keine Stilabnahme

11.11.2026, isolierter Taskbranch auf290fa0fb6. Dieser Ordner erhält den
Root-Entwurf als **Vorher-Vergleich**. Der Nutzer bestätigte die 2D-Vorlagen,
verlangte aber deutlich mehr Nähe der 3D-Modelle dazu. Astra Ultra arbeitet
deshalb an R05. Die folgenden technischen Ergebnisse geben R04 keine
gestalterische Freigabe und gelten nicht automatisch für R05.

## Vorgaben und Quellen

Kenney-Körper, Rig und Proportionen bleiben. Leicht ist eine sparsamere
ORC-Ableitung; mittel erhält stärkere Platten und Beine; schwer folgt der
Morozov-Konstruktion mit hohem Kragen. Die verworfene Schweißerbrille und der
große Mundblock wurden entfernt. Die drei aktuellen KI-Tafeln, zwei frühere
Tafeln, vollständige Prompts, Eingaben und Originale stehen unter
[art/armor_orc_morozov_20261111](../../../art/armor_orc_morozov_20261111/README.md).
Die generierten oberen Ansichten sind geneigt, nicht maßhaltig orthografisch.

## Technische R04-Nachweise

- Blender5.1.1:27 Teile, keine Geometrie-/UV-/Normalenfehler. Zentrierte
  tragbare Teile erhalten absichtlich keine Bodenpivots. Bei acht schweren
  Teilen werden geschlossene verdeckte Kontaktflächen der Befestigungsbänder
  akzeptiert; rund100 Dreiecke je schwerem Outfit. Kein Z-Fighting-Befund.
- Ein gecachter geskinnten Outfitmesh mit höchstens fünf Materialflächen,
 9/15/20 Segmente und3098/6056/9656 Dreiecke für leicht/mittel/schwer.
- Frischer Godot4.6.2-Import Exit0. Bekannte UID-Fallbacks der Editor-Addons
  und ObjectDB-Warnung beim Editorende; kein vollständiger Editor-Gesamt-PASS.
- Native D3D12 Forward+, RTX4070TiSUPER,1920×1080: Poseprüfung110/0, Exit0,
  keine Script-/Enginefehler. Beide vorhandenen Rigs, tatsächliche Proxy-
  Erzeugung, Stand/Lauf/Feuer/Rückseite/Kopfdrehung25°. Shared Mesh/Skin,
  Flächenzahl, Kopfabdeckung und Heavy→Medium→Suit-Wiederherstellung geprüft.
  Spätere Präzisierung: Die alphabetische Namenssuche des damaligen Harnesses
  wählte beim Einsatz zunächst crouchWalk. Das ist eine nützliche zusätzliche
  Extrempose, aber kein eindeutiger Nachweis des normalen Walk-Clips. Der Root-
  Verifier bevorzugt für R05 ausdrücklich walk und protokolliert den Clipnamen.
- Native tatsächliche Kampagnenszene und Inventaroperation16/0, Exit0.
  Besitz/Blueprint/Herstellung, endlicher Bestand, kanonischer Wechsel,
  tatsächlicher Ablegenbutton, Rückgabe, Chipfach, Legacy-Restore und echte
  Basisprojektion. Der Reward ist ein markierter Domainfixture, kein neuer
  durchgespielter Satellitenausflug; Autosave für das Fixture gestoppt.
  Privates APPDATA unter output/native_glut_maps. Zwei bekannte Homebase-
  UID-Fallbackwarnungen, keine Scriptfehler.
- Dieselben Programme headless110/0 und15/0, Exit0. Der zusätzliche Welt-
  Rendercheck gehört zum nativen Lauf.

## Bilder und Vergleich

[Vorne](native_front.png), [Dreiviertel](native_quarter.png),
[Seite](native_side.png), [Hinten](native_rear.png), [Oben](native_top.png).
Die reine Modellvergleichsprobe blendet nur Waffen und Teamsockel aus. Sie
ändert keine Rüstung und keinen Gameplayzustand. Die gesonderte Poseprobe
zeigt bestehende Waffen-/Feueranimationen. Sämtliche Bilder wurden geöffnet;
Material- und Wire-Vierwinkelbilder der drei Helme und Torsos sind erhalten.

[Interaktiver Vergleich](../../reports/armor_comparison_20261111.html) nach
Repo-Workbench-Vorlage: Blickrichtung, R04/R05, Graustufen, lokale Prüfnotizen
und JSON-Export/-Import. Die Figuren werden im Browser ohne Verzerrung auf
gleiche sichtbare Höhe eingepasst; Kopf und Stiefel bleiben vollständig.
Export/Notizen liegen unter den Bildern und verdecken sie nicht. Original-
PNG-Dateien bleiben unverändert.44 Browserchecks für R04: alle15 Klasse/
Blickrichtung-Kombinationen, gleiche Figurenhöhe/vollständige Bounds,
Dialog, Graustufen, lokale Notizen, Download-/Text-Export, validierter Import,
Desktop1600×1000 und schmale Ansicht390×844; keine Browserfehler. Für R05 nach
Übernahme eigener Bilder erneut prüfen.
`workbench_roundtrip.json` enthält ausschließlich die automatisierten Browser-
Testnotizen und Testurteile; diese sind keine Nutzerentscheidung oder Stilfreigabe.

## Offene Formfehler und Grenzen

R04 hatte trotz technischer PASS noch aufgesetzt wirkende Platten,
unzureichende Schulterdächer, eine zu wannenförmige ORC-Krone und schwache
Übergänge. Diese Befunde begründen die kreative R05-Neumodellierung.
Einzelbilder beweisen keine vollständige Animationstauglichkeit; Sitz-/
Transportextreme und breite Gefechtsframerate bleiben gesonderte Aufgaben.
Kein Main-/EXE-Schritt.

Aktualisierung: R05 ist produktiv im isolierten Taskstand übernommen. Eigene
Prüfungen und neue Bilder unter `../armor_kenney_r05_20261111/README.md`;
die obigen R04-Ergebnisse bleiben historische Vergleichsevidenz.
