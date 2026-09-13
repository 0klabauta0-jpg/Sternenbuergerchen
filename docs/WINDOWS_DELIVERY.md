# Privater Windows-Testbuild N3 · 13.09.2026

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
