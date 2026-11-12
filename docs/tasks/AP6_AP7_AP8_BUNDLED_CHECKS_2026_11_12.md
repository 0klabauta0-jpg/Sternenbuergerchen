# AP6/AP7/AP8: vorbereiteter enger Prüfblock

## Ziel und Ursache

Die zusammenhängenden Codeblöcke werden zuerst fertiggestellt. Danach soll ein
serieller kleiner Verbundlauf den aktuellen Parent prüfen, ohne historische
Einzelmatrizen oder native große Karten erneut durchzulaufen.

## Umfang und Nicht-Ziele

Nur neuer Bündelrunner, Manifest und eigene QA-Anleitung. Bestehende isolierte
Runner und Verifier werden unverändert aufgerufen. Keine Produktänderung, kein
Testlauf bei dieser Vorbereitung, keine EXE/GPU/Performance-/Vollabnahme.
Bewusste Arbeitsbasis: gemeinsamer task/native-glut-maps-20261110 mit paralleler
AP7-Checkpoint- und AP8-Netzimplementierung; kein Wechsel des gemeinsamen Branchs.

## Verträge

AGENTS, PROJECT_BRIEF, ARCHITECTURE, CODEX_RULES; Hex-Taktik-/Lifecyclevertrag;
HEX_RUNTIME_SELECTION_2026_11_12; HEX_EXECUTION_MEMBERS_2026_11_12;
BASE_ACTION_CHECKPOINT_V2_2026_11_12; bestehende Prepared-Ground-/Movement-QA.

## Akzeptanz

- Ohne --execute nur Plananzeige, keine Godotprozesse oder Ergebnisdateien.
- Fälle ausschließlich nacheinander, mit Zeitgrenze, Exitcode, Originalreport
  und Quellprovenienz. Vorhandene Profil-/Canary-/Quellguards bleiben Pflicht.
- Fehlende oder unveränderte alte Reports sind kein Pass. Fehler stoppen den
  Lauf; nicht ausgeführte und noch nicht angeschlossene Fälle bleiben sichtbar.
- AP8 und Root-Checkpoint bleiben bis zum abgestimmten Runneranschluss pending;
  Teilpässe werden nicht als vollständiges AP7/AP8 oder native Abnahme bezeichnet.
- Default nur RuntimeSelection und unmittelbar betroffener BaseV2-Nachbar plus
  künftig neuem Composite. Alte Mission-/Medical-/FMC-/Visit-Nachbarn ausschließlich
  optional mit --extended, kein automatischer Wiederholungslauf.
- Feste alte QA-Ergebnisdateien werden vor einem späteren Lauf archiviert;
  weder historische Ergebnisse noch Baselines gelten als aktueller Beleg.

## Dateien / lokale Prüfung

scripts/tests/run_ap678_bundle.py; docs/qa/ap678_bundle_20261112/manifest.json
und README.md. Jetzt nur statische Python-/JSON-Prüfung, kein Runnerstart.

## Risiken / offen

Quellen müssen vor dem späteren Lauf eingefroren sein. Bestehende Spezialrunner
verwenden teilweise feste QA-Logpfade und zählen konkrete Assertions: sie können
nach den neuen Codeblöcken berechtigt rot werden. Keine automatische Anpassung
oder Wiederholung. Der kommende AP8-Netzrunner und Root-Checkpointanschluss
werden erst mit den tatsächlichen APIs ergänzt.

## Gemeinsamer begrenzter Abschluss 12.11.2026

Code integriert; kleine Funktionsfälle Selection16/0, Base30/0, AP8-Root/Net38/0 und CampaignContinue17/0+3/0 mit sauberen Logs/Quell-/Profil-/Canaryguards. Originalberichte, genaue Commitgrenzen und Fixtureeinschränkungen: `docs/qa/ap678_bundle_20261112/README.md`. Dieser spätere Nachweis ersetzt den obigen Codefreeze-/Vorbereitungsstatus; keine AP9-/Native-/echtePeer-/Leistungsfreigabe, kein Mainmerge oder EXE.
