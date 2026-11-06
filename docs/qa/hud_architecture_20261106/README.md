# HUD-Architektur: Belege vom 06.11.2026

[Bericht mit Ergebnissen und Grenzen](REPORT.md) · [Analyse](analysis.json) ·
[Dateimanifest](manifest.json) · [Portables ZIP](hud_architecture_20261106.zip).
Die Main-Quittung `main_receipt.json` liegt separat neben dem eingefrorenen
Archiv. Sie wird nach dem Main-Smoke ergaenzt und ist kein Teil seiner Pins.

Echte 3440x1440-PNGs: [Homebase vorher](raw/images/before_homebase.png),
[Homebase nachher](raw/images/after_homebase.png), [Mission nachher](raw/images/after_go.png).
Der Missionsvergleich vorher ist im ZIP unter `raw/images/before_go.png`.
Alle Bilder sind unveraenderte native Dateien. Das Paket enthaelt die fuer
die Analyse noetigen Rohdaten, einschliesslich der getrennten Fehlversuche.

Im Repository bytegenau gegen die Originalpfade und das ZIP pruefen:

```powershell
python docs/qa/hud_architecture_20261106/verify_package.py --zip --originals
python docs/qa/hud_architecture_20261106/analysis_work.py --self-check
```

Das ZIP in einen neuen Ordner entpacken. Innerhalb des entpackten
`hud_architecture_20261106`-Ordners pruefen und die Analyse ohne Engine
reproduzieren:

```powershell
python verify_package.py
python analysis_work.py --project-root . --final output/hud_architecture_20261106/final_native_audited/20261106T144051Z-f2bdfc4c/audited_performance.json --final-confirmed --output analysis_reproduced.json
```

`analysis_reproduced.json` ist eine neue lokale Ausgabedatei; die eingefrorene
`analysis.json` wird nicht ersetzt. `--originals` benoetigt den urspruenglichen
Workspace. Verifikation und Analyse starten weder Godot noch Git und schreiben
keinen Gameplay-State. Einzelne grosse Rohdateien liegen komprimiert nur im
ZIP, damit Daten nicht unnoetig doppelt im Repository gespeichert werden.
