# Mainintegration: Hex-Follow-up und Review — 13.11.2026

Abschlussprüfung: fünf Runtimegruppen207/0, alle Quellen-/Profil-/Canaryguards
grün, keine finalen Enginefehler/Leaks. HTML offline/mobil/JSON wird mit39
Assertions geprüft. Exakte Fälle und die nicht saubere vollständige
Editorimportgrenze stehen in `docs/qa/main_hex_review_20261113/README.md`.

## Ziel / Ursache / Basis
Ausdrücklicher Nutzerauftrag: geprüfte Arbeit in Main integrieren. Ausgang ist
frisch gefetchtes origin/main b1f47750b. Die Taskzweige divergieren stark und
werden nicht mitsamt alten Vorfahren gemergt. Integration auf eigenem Branch
task/main-integration-hex-review-20261113 im sauberen vorhandenen Taskworktree.
Die sechs fremden Änderungen in C:/dev/SternenBuergerchen bleiben unangetastet.

## Umfang / Nichtziele
Gezielte Übernahme des Codecfixes/enger Regressionen02e75d4f1 und des mobilen
Berichts c27528594. Die früheren Reviewfixes8d0f9a597 gegen aktuelle Mainowner
prüfen und nur weiterhin zutreffende Deltas übernehmen. Keine ganzen älteren
Root-/UI-/Terrainkörper, kein Grafik-WIP, keine Produktionskartenaktivierung,
keine neue Würfel-/Kampf-/Savebalance, kein EXE-/Desktop-/GPU-Schritt.
Aktuelle Main-Kampagnen-, Orbit-, Missionssave- und Sternkartenpfade erhalten.

Frische ENet-Verbundprüfung21/1 belegt eine vorhandene Main-Anschlusslücke:
Groundfacing wechselt und Tick34 wird übertragen, aber der produktive Driver
nutzt noch ausschließlich Legacyterrain-/Reichweiten-LOS. Vorhandenen
HexSightRuntimeAdapter eng an dessen Sichtgetter anbinden; opt-in Hexblick muss
verdeckte Gegner verbergen, Legacy ohne aktiveHexruntime unverändert behandeln.
Keine vollständigen alten Driver-/Cache-/Erkennungsbodies übernehmen.

## Dokumente / Akzeptanz
AGENTS, PROJECT_BRIEF, ARCHITECTURE, CODEX_RULES, aktueller Status/Roadmap,
HEX_RUNTIME_FOLLOWUP_2026_11_13 und beteiligte Movement-Save-/Authorityverträge.
Sourceverhalten nach Konfliktauflösung erneut auf tatsächlichem Mainverbund
prüfen: ENet22, MovementSave30, zutreffende Mehrschiff-/UI-/Save-Nachbarn.
Marker, Exitcode, Fehler-/Leakfreiheit, Originalprofil-/Quell-/Canaryguards.
HTML-Workbench aktualisieren und offline/mobil/JSON prüfen. Main und origin/main
müssen denselben geprüften Abschlusscommit enthalten; kein Forcepush.

## Dateien / Risiken / lokale Prüfung
Produkt: gezieltes Stringcodec-Feld, ggf. aktuelle Personen-/Payload-/Shellhunks.
Verifier/Runner, eigene Task/QA, IMPLEMENTATION_STATUS und HTMLbericht.
Große divergierende Branchbäume und veraltete Testvorbedingungen erfordern
Ownerprüfung statt pauschaler Konfliktwahl. Historische QA bleibt als solche
erkennbar; Integration erhält eigene frische Logs unter docs/qa/main_hex_review_20261113/.
