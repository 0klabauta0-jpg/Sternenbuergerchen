# QA-Paket: Befehlsruckler und Alt-Gates

Der [knappe Bericht](REPORT.md) trennt konkrete Commandkosten, Framezeiten,
normalen 1×-Gameplaylauf und kontrollierte Facing-/Air-Fixtures.

- Portables Archiv `continue_20261105.zip`: unveränderte relevante JSONs, Logs,
  Originalquellen und sieben native PNGs; große Roh-JSONs ohne zweites
  unkomprimiertes Duplikat.
- [Manifest](manifest.json): exakte Bytehashes, Originalpfade, Bilddimensionen,
  Quellenstatus und reine Archivmitglieder.
- Separate `zip_receipt.json` neben dem ZIP: Größe und SHA-256 des vollständigen Archivs.
- [Analyse](analysis.json): abgeleitete Zahlen mit reproduzierbarer 0–38-s-Auswahl.
- [Finale Quellenbindung](binding/final_source_binding.json): historische
  24 049 Pins, aktuelle 1948 Codepins und die drei expliziten Deltas.
- [Erhaltcheck](binding/preservation_check.json): 38 fremde Dateien / 437 Roster.
- [Main-Receipt](main_receipt.json): Im eingefrorenen Archiv PENDING; der
  aktuelle Status steht in der separaten `main_receipt.json` neben dem Archiv.

```powershell
python docs/qa/continue_20261105/verify_package.py --zip --originals
```

Nach Entpacken funktioniert die Prüfung auch ohne Workspace:

```powershell
python continue_20261105/verify_package.py
python continue_20261105/analyze_performance.py
```

Alle Rohkopien und ZIP-Rohmitglieder sind bytegleich; PNGs wurden nicht
bearbeitet. Neue Bericht-/Analyse-/Prüfdateien sind UTF-8 mit LF. GDScript-
Quellen erhalten nur den Dateinamenszusatz `.txt`, ihre Bytes bleiben gleich.
Damit werden die Quellen nicht als zusätzliche Godotskripte importiert.

Das ZIP wird als Arbeitsnachweis vor Main eingefroren. Die darin enthaltene
Main-Receipt bleibt der damalige PENDING-Stand. Root ergänzt die aktuelle
`main_receipt.json` **neben** dem Archiv; dafür wird das ZIP nicht neu erzeugt.
Diese Receipt ist vom unveränderlichen Payload-Hashindex ausgenommen.
Die Originale unter `output/continue_20261105` bleiben vollständig lokal erhalten.

61/61 normaler nativer Lauf, 135/0 kontrolliertes natives Facing und 155/0
kontrolliertes natives Air sind getrennte Belege. Die große Headlessmatrix
bleibt historisch 26/27; der korrigierte TASK344-Nachlauf besteht 40/0.
Commandkosten wurden gesenkt; allgemeine Frameverbesserung ist nicht belegt,
ein 288,544-ms-Hitch bleibt offen. Keine FPS-/Release-/WAN-Generalabnahme.
