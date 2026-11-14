# Windows-Playtestpaket 14.11.2026

Quelle: `a377c7346cf6ec27cb9156f72e36e2fd24e406e7` auf
`task/windows-release-guide-20261114`, Produktbasis Main
`39c36fa4ccd0c5c16ab357dee2b2208aeb961566`. Der Exportcommit ergaenzt nur die
Taskbeschreibung. Fremdes WIP im Originalcheckout blieb unberuehrt.

Godot 4.6.2.stable.official.71f334935, Windows x86_64 Releasevorlage.
Bestehende Pipeline `scripts/tools/export_runtime_release.ps1` und bestehende
Exclude-/Runtimevertraege; nur lokaler Preset und lokaler Contract fuer den
eigenen datierten Ausgabeordner. Keine Produkt-/Exportquellaenderung.

Der erste native Godot-Export beendete den Export erfolgreich. Sein
PowerShell-Nachlauf scheiterte beim Provenienz-Join eines absoluten Pfads.
Deshalb wurde mit einem relativen lokalen Ausgabepfad erneut exportiert.
Beide Logs bleiben als Nachweis erhalten; der fehlgeschlagene Nachlauf wird
nicht als bestandene Pipeline gezaehlt.

`package_smoke.py` startet ausschliesslich die exportierte EXE mit dem
Paketordner als Working Directory und automatischer PCK-Aufloesung neben der
EXE. Der normale MainMenu-Einstieg laeuft fuer120Frames. Ein eigener APPDATA-
Ordner trennt die Testdaten; SHA/mtime-Guard der echten Spielprofildateien vor/nach
dem Start. Kein aktiver Desktop, keine OS-Eingabe. Die normalen Startlogs zeigen
Engine- und Netfoxinitialisierung, Exit0 und keine Fehler oder Leaks.

Der Testumfang ist Headless-Start/Laden. Er belegt keine Darstellung,
Kampagnenvollendung, WAN-Funktion oder FPS-Abnahme. Fuenf Missionen bis zum
vollstaendigen Sieg bleiben unbestaetigt.

Ergebnis und Paketpfade: `build_summary.json`, `package_smoke.json`.

Der externe Probe wurde nach75s ohne Startmarker abgebrochen und ist als
fehlgeschlagener Runner-Versuch archiviert. Ein erster --path-Versuch wurde
von der Standard-Releasevorlage abgelehnt. Beide gelten nicht als bestanden.
Der anschliessende normale Einstieg ohne Overrides bestand: Engine-/Netfoxmarker,
Exit0, keine ERROR-/Parse-/Compile-/Leakzeilen, Originalprofil unveraendert.
Keine native Screenshotabnahme; der bestehende Runner nimmt Projektchecks
und keine exportierte EXE direkt entgegen.

## Auslieferung und Anleitung

GitHub-Prerelease: https://github.com/0klabauta0-jpg/Sternenbuergerchen/releases/tag/playtest-2026-11-14
Repository bleibt privat. GitHub meldet dieselbe SHA256 wie die lokale ZIP;
`GITHUB_PUBLICATION.json` dokumentiert Quelle, Tag und Asset. EXE zuerst an den
Nutzer ausgeliefert; neue Karten-/Frachtwünsche sind nicht im Paket enthalten.

Öffentliche Anleitung: https://sternenbuergerchen-spielanleitung.klabauta.chatgpt.site
Eigene öffentliche Site, vorhandener Arbeitsbericht bleibt privat. Quelle
`docs/player_guide/`; Veröffentlichung `GUIDE_PUBLICATION.json`. Zehn Kapitel,
nativer Screenshotbestand, lokale Checkliste, Suche und Boden-Trefferrechner.
68 lokale Prüfungen bestanden (Katalogabgleich, gerechnete Grenzfälle, UI auf
320/390/768/1440px, Tastatur, Bilder und Links). Mobile und Desktopaufnahmen
geöffnet und beurteilt: lesbar, ohne Seitenüberlauf, Rechner bedienbar.
23 zusätzliche öffentliche Prüfungen bestanden, ohne Cookies oder Anmeldung.
Alle ausgelieferten JS-/CSS-/Bild-/Fontdateien bytegleich. Der erste strikte
HTML-Hashvergleich erkannte das vom Hosting angehängte Cloudflare-Schutzscript;
dieser rote Versuch bleibt erhalten. Die Folgeprüfung bestätigt den vollständigen
unveränderten Autoreninhalt und genau diesen zusätzlichen Schutzscriptbereich.
Keine Performance- oder Spielabnahme aus den Websitechecks ableiten.
