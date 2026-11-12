# Polisa: absichtlich roter AP6-Visitnachweis

Der Lauf gegen die private Kopie von Parent `2bfebc601` ergibt **4 PASS / 3 FAIL**
und Godot-Exit 1. Das ist ein gezielter Reproduktionsstand, keine Suite- oder
Spielwegfreigabe. Der reale Flow/Controller/Root/Ground/Registry-Pfad wird mit
einem Actor- und Darstellungsfixture ausgeführt. Einzelheiten stehen in der
[Taskdatei](../../tasks/SPACE_POLISA_LOCAL_DOCK_2026_11_12.md).

Reproduktion mit einer bereits erstellten privaten Kopie desselben Parentstands,
inklusive Szenen, referenzierter Assets/Importe und LimboAI-Extension, und mit
der Probe `scripts/tests/polisa_real_visit_board_retire_probe.gd`:

```powershell
./docs/qa/polisa_visit_board_retire_20261112/run_probe.ps1 `
  -PrivateProject '<absolute private Projektkopie>' `
  -EvidenceDirectory '<absoluter privater Ausgabepfad>'
```

Der Runner verwendet ein eigenes `APPDATA`, prüft fünf konkrete Quellblobs
gegen den Git-Basisstand und deren SHA-256 vor/nach dem Lauf sowie den
Testskripthash. Er erwartet Godot-Exit 1; sein eigener Exit 0 bedeutet nur,
dass dieser rote Befund und die genannten Prüfungen wie erwartet vorliegen.
Ein Hash des tatsächlichen Nutzerprofils wurde **nicht** erhoben. Die private
Projektkopie samt Assets und Extension ist nicht Teil dieses QA-Artefakts.
