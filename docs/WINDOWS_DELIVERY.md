# Privater Windows-Testbuild N5 · 13.09.2026

N5 wurde mit Godot4.6.2, Schema5 und Dateiversion0.5.0.0 exportiert. Das Paket enthält EXE/Engine/eingebetteten PCK, drei lokale Schiffsvorlagen, cloudflared2026.9.1, Anleitung und Lizenztexte einschließlich der zusätzlich verwendeten Factory-/Space-Module.

- ZIP `output/Sternenbuergerchen-Windows-N5.zip`: 59836709 Bytes, SHA-256 `633c815224b9f2c6295d19855e7df217bd814d467d69f886912035d501f5b966`.
- EXE SHA-256 `856ce3f52de388c43eea41589229942ed7e64242f3da4a64b811758f4f4d964e`.
- Frisch entpackt:14 Manifestdateien bytegenau/SHA-geprüft,15 Dateien einschließlich BUILD.json, keine project.godot und keine Karriere/Einladung.
- Reguläre EXE: Menü und Game über den vorhandenen Host-Einstieg in isolierter APPDATA gestartet, Exit0, echte Bilder angesehen, Enginefehlerlogs leer.
- Genau dieser exportierte PCK:25/25 Prüfungen mit tatsächlichem Menübutton, neuem Schema, neun Zielen, regionalen Preisen, Reparaturaufsatz und den lokalen Modellen. Zusätzliche Modellprüfung9/9.
- Entersäbel9714 Dreiecke/14 Meshes, Freibeuter13945, Geier17998. N5-Blend und Reimport überprüft; horizontales Profil7,5×11m.

Belege: `output/windows-n5-delivery/`. Exportlog: `output/windows-n5-export.log`. Quellprojekt:761 Kernprüfungen,159 neue/aktuelle Fensterprüfungen,12 Speicherstarts-Prüfungen,62 ENet und70 öffentliche WSS-Prüfungen über DNS-Ersatzweg. Kein zusätzlicher Internetlauf der exportierten EXE, kein Nachweis zweier Haushalte oder weiterer Hardware. Windows x86_64/OpenGL3.3, privater nicht signierter Entwicklungsbuild. ZIP und Modelle bleiben lokal; der Handybericht enthält nur Texte und Aufnahmen.

`output/windows/` ist nun N5; die N4-/N3-ZIPs und ihre folgenden Beschreibungen bleiben historisch.

---

# Privater Windows-Testbuild N4 · 13.09.2026

N4-Release mit Godot4.6.2 und Dateiversion0.4.0.0 wurde aus dem eingefrorenen Arbeitsstand exportiert. Das lokale Paket enthält Engine und eingebetteten PCK, die drei tatsächlichen lokalen Schiffsmodelle, portables offizielles cloudflared2026.9.1, Lizenztexte, deutsche N4-Anleitung und ein SHA-256-Manifest. Keine Installation von Godot ist beim Freund nötig. Kein Upload zu Git oder Site.

**Lokale Auslieferungsprüfung bestanden.** Reguläre Release-EXE, eingebetteter PCK und frisch entpacktes ZIP wurden isoliert geprüft; die N4-Laufzeit wurde während der Lieferprüfung nicht verändert.

- ZIP: `output/Sternenbuergerchen-Windows-N4.zip`,60.829.873Bytes; SHA-256 `8b1e1b05610f1d0af3d14f02f7e3255d3104ddb5ca11ffc3b14e193fc0dcf6e8`.
- EXE:109.801.512Bytes; SHA-256 `2ee124c94d44bf214f113601426ad145669b36d9d991c6d6f2c04662fe103e5e`.
- Build-ID: `N4-20260913-2ee124c94d44`.
- Unveränderter Helfer SHA-256: `2837888cc0f5d58f15b6dc478376de90b4d3ba5241c7947455d1e0a0df429712`.
- Isolierter Ordner ohne Projektdateien: `C:/Users/bjoer/AppData/Local/Temp/sternen-windows-n4-c6716f256bb14085bc9a97fe9cce8ec5`.
- Dauerhafte Belege: `output/windows-n4-delivery/`; Exportlog `output/windows-n4-export.log`.

Bereits bestätigt: Export Exit0 ohne Enginefehler; externer headless Assettest aus genau dem eingebetteten EXE-PCK9/9, darunter `assets/local/entersaebel_n4/entersaebel.glb` mit12 Meshes statt des alten Modells. Freibeuter und Geier sind ebenfalls die lokalen Originalableitungen. Das ZIP wurde frisch entpackt:12 Nutzdateien stimmen mit dem Manifest überein; zusammen mit BUILD.json enthält es13 Dateien, keinen Spielstand, keine Einladung und keine project.godot.

## Tatsächliche N4-Auslieferungsprüfung

Alle Starts verwenden neue eigene APPDATA-Unterordner und einen Paketordner ohne Checkout oder lose Projektressourcen. Die normale Nutzerkarriere bleibt unberührt.

1. Reguläre Release-EXE: echtes Hauptmenü, anschließend separater Start der tatsächlichen Game-Szene über den vorhandenen `--host`-Einstieg; beide Exit0, Fehlerlogs leer. [Menü](../output/windows-n4-delivery/standalone-menu.png), [Game](../output/windows-n4-delivery/standalone-game.png).
2. Derselbe eingebettete EXE-PCK mit einer externen temporären Godot4.6.2-Probe:22/22 Prüfungen. Tatsächlicher Menübutton lädt das Spiel; Schema4, Basiswelt, Maskierung, Helfer und drei lokale Schiffmodelle geprüft. [Ergebnis](../output/windows-n4-delivery/portable-result.json), [Schiffe](../output/windows-n4-delivery/portable-ships.png).
3. Externe Dossierprobe gegen genau diesen PCK:22/22 native Mausprüfungen, kombiniertes finales Log ohne Enginefehler. Echter Drag-and-drop von gefertigten Gegenständen, Quelle/Ziel, Mengen, gefülltem Rucksack und Rückgabe. Die Probe hält ausschließlich ihr eigenes natives Testfenster im Vordergrund und liefert vollständige Mouse-Ereignisse nach dem Warp. Vorher fehlende Hoverzuordnung wurde als Eingabeharnessproblem isoliert; keine Spielbefehle oder Bestände werden für Erfolg gesetzt. [Dossier](../output/windows-n4-delivery/portable-dossier.png), [Log](../output/windows-n4-delivery/dossier-final.log).
4. Separater headless Assettest gegen den EXE-PCK:9/9. Richtige lokale Modellpfade, vorhandene Meshes, passende horizontale Abmessungen und Bodenkontakt. [Log](../output/windows-n4-delivery/asset.log).
5. Fertiges ZIP frisch entpackt: alle12 Manifestdateien bytegenau/SHA-256 bestätigt, nur13 Archivdateien inklusive Manifest. Die daraus gestartete Release-EXE bootet headless mit Exit0 und leerem Fehlerlog. Gebündeltes cloudflared meldet tatsächlich2026.9.1. [ZIP-Metadaten](../output/windows-n4-delivery/zip.json).

| Tatsächliches Modell aus dem N4-Paket | Meshes | Dreiecke |
|---|---:|---:|
| Überarbeitete Entersäbel, `assets/local/entersaebel_n4/entersaebel.glb` | 12 | 15.705 |
| Freibeuter | 1 | 13.945 |
| Geier | 1 | 17.998 |

Alle finalen Bilder wurden angesehen. Das Release-Template erlaubt keinen externen Script-Mainloop; deshalb werden reguläre EXE-Starts und ergänzende Prüfungen ihres PCK durch die passende Godot-Konsole getrennt ausgewiesen. Kein Testcode wurde in das Produkt eingebaut. Das ZIP bleibt unverändert bei dem oben genannten Hash.

Öffentliche WSS70/70 und ENet62/62 wurden vor dem Export als eigene N4-Prozessprüfungen bestanden. Dies ist kein zusätzlicher öffentlicher Netzlauf der exportierten EXE und keine Abnahme eines zweiten Haushalts. Windows x86_64/OpenGL3.3, nicht signiert; weitere Hardware und dauerhafter Vermittlungsbetrieb bleiben ungeprüft. Der reguläre Savepfad ist `%APPDATA%/SternenBuergerchen-Neustart/campaign.json`.
`output/windows/` enthält jetzt N4. Das N3-ZIP und seine historische Prüfung bleiben unten dokumentiert; die N3-Protokolle liegen weiterhin unter `output/windows-delivery/`.

---
## Historischer privater Windows-Testbuild N3 · 13.09.2026

Der portable Release-Export liegt ausschließlich lokal unter `output/windows/`; das fertige Paket ist [Sternenbuergerchen-Windows-N3.zip](../output/Sternenbuergerchen-Windows-N3.zip), **60.094.436 Byte** (rund 57,3 MiB). Es wurde nicht zu Git oder zur Site hochgeladen.

Die einzelne `Sternenbuergerchen.exe` enthält Engine und eingebetteten PCK mit allen Spieldaten. Ein Freund benötigt weder Godot noch Python oder Blender. Ziel ist Windows x86_64 mit OpenGL 3.3. Beide Commander sollten dasselbe Paket benutzen. Dies ist ein nicht signierter privater Entwicklungsbuild.

## Paketinhalt und Herkunft

- `Sternenbuergerchen.exe`: Godot 4.6.2, aktueller N3-Arbeitsstand einschließlich finalem Internet-Gateway, Maskierung der Einladung und portablem Helferpfad.
- `tools/cloudflared.exe`: unveränderte offizielle Version 2026.9.1. Der Spielcode sucht diese Datei zuerst neben der Export-EXE; der Host startet/stoppt sie bei Bedarf, der Gast braucht sie nicht.
- `LIESMICH.txt`: deutsche Start-, Steuerungs-, Koop- und Speicheranleitung; temporäre Internetvermittlung, gleicher Softwarestand, private Einladung und eigener Gastplatz erklärt.
- `Lizenzen/`: originale Kenney-CC0-Hinweise, Godot-MIT und vollständige Godot-Drittanbietertexte, cloudflared-Apache-2.0 und Herkunftshinweise.
- `BUILD.json`: Build-ID `N3-20260913-79c8cd61a82b`, Versionen und SHA-256-Dateimanifest.

Die drei lokalen Referenzschiffe sind im privaten Paket enthalten. Ihre Blender-Bearbeitung wird nicht als freie oder eigene Ursprungslizenz ausgegeben. Das historische Hauptmenübild ist ebenfalls enthalten. Daraus wird keine allgemeine Veröffentlichungs-/Weiterverteilungslizenz dieser Vorlagen abgeleitet. Das Paket bleibt der ausdrücklich angeforderte private Testbuild.

## Tatsächliche isolierte Prüfung

Das Paket wurde in einen neuen Tempordner kopiert, ohne `project.godot`, lose Projektassets oder Checkout. APPDATA wurde für alle Probeläufe in eigene neue Unterordner dieses Tempordners gesetzt; die normale Nutzerkarriere wurde nicht verwendet.

1. **Release-EXE regulär gestartet:** tatsächliches Hauptmenü gerendert, Aufnahme geschrieben, Exit 0, Fehlerlog leer. Die finale Aufnahme wurde auch nach `output/n3-main-menu.png` übernommen.
2. **Release-EXE mit vorhandenem `--host`-Einstieg:** tatsächliche Game-Szene, Basiswelt, lokale Entersäbel und LAN-Koopfenster gerendert; Aufnahme nach drei Sekunden, Exit 0, Fehlerlog leer.
3. **Eingebetteter PCK aus genau dieser EXE:** mit einer externen temporären Probe in Godot 4.6.2 geöffnet, weiterhin aus dem isolierten Paket ohne lose Projektressourcen. **22/22 Checks bestanden**, Fehlerlog leer. Die Probe klickt den tatsächlichen Menübutton per InputEvent, lädt die Game-Szene, prüft Schema 3, Basis, Maskierung und Paketressourcen und rendert alle drei lokalen Schiffe.
4. **Fertiges ZIP frisch entpackt:** alle zwölf im Manifest aufgeführten Nutzdateien stimmen bytegenau/SHA-256 mit dem Ausgangspaket überein; der Manifest selbst ist die dreizehnte Archivdatei. Die frisch entpackte Release-EXE startet erneut headless mit Exit 0 und leerem Fehlerlog. Der gebündelte Helfer meldet tatsächlich Version 2026.9.1.

Das offizielle Release-Template erlaubt keine `--path`-Overrides und führt die externe `--script`-Probe nicht als Testmainloop aus. Deshalb sind die beiden regulären EXE-Fensterläufe und die zusätzliche PCK-Ressourcenprobe getrennt ausgewiesen. Es wurde kein Testcode ins ausgelieferte Spiel eingebaut und keine Gameplay-Datei für diese Auslieferungsprüfung geändert.

| Tatsächlich aus dem Export geladene lokale Datei | Meshes | Dreiecke |
|---|---:|---:|
| Entersäbel (`assets/local/entersaebel.glb`) | 1 | 17.879 |
| Freibeuter (`assets/local/freibeuter/freibeuter.glb`) | 1 | 13.945 |
| Geier (`assets/local/geier/geier.glb`) | 1 | 17.998 |

Alle drei wurden gemeinsam gerendert und visuell kontrolliert; es sind die lokalen Modelle, nicht die Kenney-Ersatzmodelle. [Schiffaufnahme](../output/windows-delivery/portable-ships.png), [echtes Release-Menü](../output/windows-delivery/standalone-menu.png), [echtes Release-Spiel](../output/windows-delivery/standalone-game.png), [22 Prüfungen](../output/windows-delivery/portable-result.json).

## Prüfsummen und Nachweis

- ZIP SHA-256: `dd6df23ea5437045ed98cb11ab633126da9f2f170fcb9d352bd1d4c2273458b7`
- EXE: **108.987.944 Byte**, SHA-256 `79c8cd61a82b11aa1b0d5b29eecbe7d8606c0efa538f3fcaf8961f1e6b369872`
- cloudflared SHA-256: `2837888cc0f5d58f15b6dc478376de90b4d3ba5241c7947455d1e0a0df429712`
- Dauerhafte lokale Protokollkopie: `output/windows-delivery/`; Exportlog: `output/windows-export.log`.
- Isolierte Originale: `C:/Users/bjoer/AppData/Local/Temp/sternen-windows-delivery-155f67cd6c2a4d90a3340012a5eea8eb`.

Der reguläre Spielstandpfad ist `%APPDATA%/SternenBuergerchen-Neustart/campaign.json`. Das ZIP enthält keinen Spielstand und keine Einladung. Die Internetfunktion wurde vor dem Export mit zwei tatsächlichen öffentlichen WSS-Prozessen geprüft, sowohl regulär als auch über den produktiven DNS-/TLS-Fallback, jeweils 55/55; zusätzlich ENet-LAN 69/69. Diese Netzwerkprüfung wird nicht als neuer öffentlicher Zwei-Rechner-Test des ZIP ausgegeben. Ein unabhängiger zweiter Haushalt und weitere Windows-/Grafikkartenkombinationen bleiben praktische Auslieferungsgrenzen. Details: [Internet-Abnahme](../tests/internet_report.md).
