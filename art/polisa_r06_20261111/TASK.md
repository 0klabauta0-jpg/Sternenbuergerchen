# Polisa R06 — ein großer Stationskomplex

## Problem und Ziel
Explizite Nutzerkorrektur verwirft die dreifache R05-Breite und1024erKarte. Ein zentraler großer Globusraum mit fünf einsehbaren Shops, sieben Pads, zwei geraden kräftigen Ringen und kompakten äußeren Solar-/Dockingauslegern soll auf512×256liegen. Vorhandene Personen bleiben im Maßstab.

## Umfang / Nichtziele
Privates Layout, Mapcompiler, editierbares statisches GDScriptmodell und zwei native Ansichten. Keine Produktionsdateien, UI, Runtimeowner, neuen Schiffe oder Schiffsfreigaben; kein Commit/Push. RootUI38bc35468 bleibt gültig. R05 bleibt als verworfene Quelle erhalten.

## Maß- und Kameraziel vor Code
Ein Sektor, Lobby72×44, fünf28×28Shops, L40×80 in derMitte, zweiM28×40linksnebeneinander, vierS18×20rechts2×2. RingeX±120/Yaw0/D112. SolarsX±177/44×44. AußenportsX±227, freie geometrischeAnflugreserve42×98 biszurvorderenKartenkante. GesamtXinnerhalb±249. Stationsorigin(0,-48), Rahmen[-256,-90,256,132], hintereTechnikbisZlokal−42, LFrontWelt84 und48EinheitenfreiesVorfeld.

Standardkamera zunächstSize135/Yaw24/Pitch50/Fokuslokal(0,44), angeschnitteneRinge zulässig; WholeMapSize320/Yaw0/Pitch68. Beide Bilder bleiben derselbe unverkleinerte Entwurf. DerRootView liest den lebenden station_deck_owns_flat_ground-Owner, erzeugt ein gemeinsames echtesDeckraster und verwendet deklarierteKameragrenzen.

## Grundlagen
AGENTS.md; PROJECT_BRIEF; ARCHITECTURE; CODEX_RULES; IMPLEMENTATION_STATUS; graphics_reference_revision_contract.md; Skillgodot-procedural-worlds. R05KI-Konzept und Port-Olisar-Referenzen als Stil-/Konstruktionsziel, keineMeshimporte. R04Quellenmetadaten als eingefrorener Input imPaket.

## Akzeptanz / Prüfung
Genau7Pads/5Shops/1Globus/2Ringe. AllePad-/Service-/Raumanker verbunden; TechnikgebieteausgleichenFaktengesperrt; Padreservenfrei. NativeNahansichtmitHexmuster undsichtbarerFracht/Rüstung, WholeMapmitvollständigemRahmen. KleineOfflineChecks/check-only/gezielteArtbilder; keineGefechte/Benchmark/End-to-End-Abnahme.

## Dateien / Risiken
Nurart/polisa_r06_20261111 undoutput/native_glut_maps/polisa_r06_20261111. GPUerstnachLayoutbestätigungRoot. R07-Schaukästenbleiben3statischedeaktivierteOriginalrigs. WeiteKamera machtMenschenklein; keineFigurenverkleinerungalsKaschierung. Ring-/Solar-/PortmassensindVisual, keineaktiveDockingmechanik.
