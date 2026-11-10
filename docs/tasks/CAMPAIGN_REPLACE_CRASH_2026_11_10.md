# Absturz beim bestaetigten Kampagnenersatz

## Problem / Ziel

Neue Kampagne -> vorhandene Kampagne ersetzen beendet die freigegebene EXE
2026-11-10-orbit-base-main-r01 unkontrolliert. Vollstaendigen Menueweg sicher
bis zur neuen Mondbasis herstellen; vorhandenes Profil bei Tests erhalten.

## Status / Ausgang

Mainbasis ee0591cfedb4d28a01788defdcf23d98439d49ad, neuer Taskbranch auf genau
diesem aktuellen Main (nicht der aelteren integration/core-foundation).
Quellfix eingefroren und gezielt headless sowie nativ geprueft. Neue EXE,
deren native Releasepruefung sowie Commit/Main-/Pushabschluss sind noch offen.
Gesammelte Belege: [QA](../qa/campaign_replace_crash_20261110/QA.md).

## Belegte Ursache

Die Nutzerlogs und der erneute Lauf der tatsaechlichen r01-EXE zeigen unter
D3D12/Forward+ auf RTX4070TiSUPER Mipanforderung5 bei maximal4, ungueltige
Textur/RID und null Uniformsets. Die alte EXE endet mit0xc0000005; deren
Deeplinkprobe erreicht den gemeinsamen Basisrenderer. Der neue echte
Menue-/OK-/Szenentest reproduziert den Fehler in der Quelle mit83/12.

Erststart, Ersatz und Fortsetzen aktivieren vor abgeschlossenem Layout
16x12-Kameraziele. Das sind die Panel-Style-Mindestmasse eines noch leeren
Vorschaurechtecks; sie sind kein gueltiger Flaechenbeleg. Der absolute
Basis-Sibling folgt dem spaeteren Layout nicht synchron, sein deaktivierter
lokaler Prozess kann die Groesse nicht zeitnah nachfuehren. Bei
SubViewportContainer.stretch besitzt der Container die Allokation, nicht die
direkt gesetzte innere SubViewport.size. Fuenf Mipstufen eines halbierten
SSR/SSAO-Puffers verlangen mindestens32Pixel pro Zielachse. Die GPU-Kontrolle
isoliert die Grenze:16x16+SSAO133Rendererfehler, sonst gleich32x32 fehlerfrei.

## Umsetzung

Der Operationspresenter verwendet das reale berechnete Layoutrechteck und
aktiviert die Vorschau erst ab32Pixeln je Achse; Layout- und Snapshotpfad
fuehren die Basisflaeche synchron nach. TerrainMap3DView sichert den
streckenden Container vor Attachment auf mindestens32x32 und behaelt danach
volle1:1-Aufloesung. Parent-Viewport-size_changed wirkt auch bei deaktiviertem
Prozesszweig synchron und fordert genau ein Neuzeichnen an. Statische
Vorschauen starten dadurch keine Dauerzeichnung; SSAO bleibt aktiviert.

## Umfang / Nicht-Ziele

Nur belegte Absturzursache und noetige Lifecycle-/Rendergrenze korrigieren.
Keine neue Kampagnenmechanik, kein Grafikqualitaetsabbau als blinder Workaround,
keine Aenderung an persoenlichen Saves, kein allgemeiner Performancepass.

## Quellen / betroffene Bereiche

Pflichtdokumente; campaign_introduction_contract.md. Produktdateien:
scripts/meta/homebase_operations_presenter.gd und
scripts/terrain/terrain_map_3d_view.gd. Neue Verifier:
scripts/tests/campaign_replace_render_verifier.gd und
scripts/tests/terrain_render_target_size_verifier.gd. Der echte Menue- und
Flowpfad bleibt bestehen; keine neue Kampagnen-/Save-Mechanik.

## Akzeptanz

1. Realer Menue-/OK-Buttonpfad mit vorhandenem privaten Checkpoint erreicht die
   neue Basis ohne Prozessabbruch oder Renderingfehler.
2. Abbrechen behaelt den Checkpoint; bestaetigter Ersatz startet genau zwei
   urspruengliche neue Personen und erlaubt gueltigen neuen Basischeckpoint.
3. Fortsetzen und Start ohne vorhandenen Stand funktionieren weiterhin.
4. Betroffene Vorschau nutzt gueltige Rendergroessen und Shared-Sim-Vertrag;
   keine autoritativen Basiswege werden von UI abgebrochen.
5. Gezielt reproduzierbarer RED/GREEN-Beleg, unabhaengiger Review, passende
   Nachbarregressionen; korrigierter Main/Push und neues geprueftes EXE-Paket.

## Lokale Quellpruefung

- Echter Campaign-/New-/Replace-/Cancel-/Continue-Buttonpfad: native D3D12
  89/0, Exit0/errors0;117PreDraw-Signale,219aktiveSSAO-Samples,0unsichereZiele.
  Sechs bekannte UID-Textpfad-Fallbackwarnungen, keine Renderer-/Scriptfehler.
- Derselbe Szenen-/Checkpointpfad headless88/0; Rendergroessenowner18/0,
  darunter1280x720/1920x1080 und winzige Einzelachsen bei deaktiviertem
  Ancestor, synchron mit UPDATE_ONCE. Kein SSAO-Abschalten.
- Finale Nachbarn: Schiffs-/Shared-Sim-Vorschau37/0, Weltbedienung9/0,
  Abflug-/Overlaybedienbarkeit42/0; alle Exit0/errors0.
- Nach Erststart, Ersatz und Fortsetzen578x650 statt16x12; innere Ziele
  folgen auch nach Ansichtswechseln der vollen aeusseren sichtbaren Flaeche.

## Risiken / offenes Releasegate

Private APPDATA-Profile, Hintergrundprozesse mit niedriger Prioritaet und ohne
Desktop-Eingriffe. Native D3D12-Rendering-Evidenz von Headless-Statepruefungen
trennen. Nutzerlogs/Dumps nur lesen; Repro nicht im persoenlichen Save ausfuehren.
Die Quelle ist geprueft, eine neue EXE noch nicht. Exportidentitaet und native
Probe der neuen EXE gehoeren nach Commit/Main-/Push in den kuenftigen externen
Paketbericht
C:/dev/SternenBuergerchen-builds/2026-11-10-campaign-replace-fix-main-r02/PRUEFBERICHT.md.
Dieser Task behauptet weder Releaseabschluss noch allgemeine Performanceabnahme.
