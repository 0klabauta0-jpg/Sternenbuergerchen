# ART: Frontier-Startgrafik und Schiffe nach Main übernehmen

## Ziel / Problem
Der Nutzer verlangt ausdrücklich, die neue Grafik als Start- und Arbeitsgrundlage auf Main zu übernehmen und Cutlass/Buccaneer aus dem Astra-Chat einzubauen. Das UI wird anschließend gemeinsam angesehen.

## Basis / Ursache
Nach Fetch ist Main `633a0ea5` gemeinsamer Vorfahr von Foundation `3cae5a216` und Grafik `1327cc200`. Die autorisierte Übernahme enthält deshalb auch 1.585 bereits vorhandene Foundation- und Grafikcommits; Main besitzt keine divergierenden Commits. Neuer Branch `task/frontier-main-20261101` basiert bewusst auf dem noch nicht integrierten Grafikstand. Implementierung und Prüfung erfolgen dort; Main wird danach per Fast-forward aktualisiert. Seine ungetrackten Nebenprodukte bleiben unangetastet.

## Umfang und Nicht-Ziele
- Neuer nativer Außenpostenrender im vorhandenen Menü-Hintergrundkatalog. Das Menü lädt nur ein PNG, keine synthetische Vorschau-Simulation.
- Reguläre GM01-Startmission wählt Frontier datengetrieben. Sämtliche übrigen Kartenbytes, Mission, Team, LZ, NPCs und Szenario bleiben erhalten. GM01 bleibt eine alte Square-Karte; die neue Hex-Werft bleibt gesondert verfügbar.
- Aktive Ref03-Schiffsmodelle bytegleich übernehmen: vier Cutlass-Triebwerke und schmalere Vorderflügel; Buccaneer mit geschlossener Cockpitwanne. Gemeinsamer Visual-Katalog für Vorschau und echten Cutlass-Missionsanflug.
- Die Buccaneer ist ein übernommenes statisches Modell; das Projekt besitzt noch keinen Fighter-Spielpfad. Dieser Auftrag führt keine neue Fighter-, Kampf- oder Transportsimulation ein.
- Editierbare finale Quellen, Generatoren, Audits, Exporte und native Vergleiche erhalten. Kuratierter Adoptionsumfang wird getrennt vom vollständigen historischen Astra-Archiv benannt.
- Kein UI-Redesign und keine allgemeine Releasefreigabe.

## Relevante Dokumente
AGENTS, PROJECT_BRIEF, ARCHITECTURE, CODEX_RULES, IMPLEMENTATION_STATUS, TASK_ROADMAP; `graphics_reference_revision_contract`, `html_report_workbench_contract`, `terrain_truth_visual_audit_contract`, `homebase_direct_dropship_flow_contract`, `dropship_lz_target_accuracy_contract`.

## Betroffene Dateien
Hintergrund- und Schiffsvisualkatalog, GM01-Theme, TerrainMap3DView-Dropshipdarstellung, FrontierArtPreview, Ref03-Assetpaket, neue begrenzte Verifier/Capture-Treiber und versionierte Rohbelege, Arbeitsreport und Implementierungsstatus.

## Akzeptanzkriterien / lokale Prüfung
- Frischer Godot-4.6.2-Import. Modellidentität, Pivot Y=0, Achse +Z, Skalierung .22, Materialien, normaler Flug-Yaw und Deckkontakt prüfen. Schiffsbudget ausdrücklich <25.000 Dreiecke gemäß Astra-Auftrag; der historische R02-20k-Gate bleibt erhalten.
- Tatsächlicher MainMenu → Singleplayer → Homebase → reguläre Mission → zeitlicher LZ/Drop-Pfad. State bleibt bei vorhandenen Komponenten; kein Teleport oder erzwungenes Entladen.
- Fokussierte Grafik-/Hex-/Authority-/Editor-/Autoloadregressionen ausführen. Historische Artefakte nicht überschreiben; Writer bekommen private Ausgabepfade. TASK158/159 und Performance-Releasegrenzen bleiben getrennt sichtbar.
- Native Bilder öffnen; eigener Ref03-Gate ersetzt den engeren historischen R02-Gate transparent. Offline-Workbench mit Notizen/JSON-Export und Browserprüfung.
- Vor Abschluss Main und Remote erneut prüfen. Getesteten Branch ohne Force auf Main fast-forwarden und pushen; Main-Checkout und Remote-HEAD danach verifizieren.

## Risiken / offene Punkte
Main macht einen großen vorhandenen Versionssprung. Die bestehende Tactical-Releasefreigabe bleibt blockiert; ein Main-Merge ist keine Releasefreigabe. Die aktiven Ref03-Modelle setzen die letzten Nutzeränderungen um, sind aber keine perfekte Rekonstruktion der älteren 2D-Bilder. Keine pauschale neue Terrain- oder Kampagnenmigration.

## Ergebnis
Abgeschlossen: Code `177991ac4962c17be0d02ef909949826967c7f57` nach bestandenem Gate auf Main fast-forwarded und gepusht. Main-Checkout hat keine getrackten lokalen Änderungen. Der Abschlusscommit ergänzt die folgenden eingefrorenen Belege und die Workbench.

- Aktuelle Matrix 29/29; echtes normales Deployment/GO 33/33 headless und45/45 nativ. Main-Checkout-Startgrafik 27/27. Ref03-Modellgate86/86. Zwei historische Asset-/Budgetorakel durch neue versionierte Adoptionsgates ersetzt, keine historischen Grenzen still geändert.
- 20 gleiche native Vergleichskameras, sechs echte Startbilder, sauberes Menümotiv. 31 beim Capturen erfasste Produktionsquellen gegen gestagte Gitblobs vor Commit geprüft; endgültiger Nachweis bindet36 Sourceblobs an den Codecommit.
- Offline-Workbench204/204 Browserchecks,40Bilder/80Derivate,17Screenshots geöffnet und zwei echteJSONdownloads. FinaleHTML-SHA86edd3811d9282cbd2249450c799122a12000d405a467ce2e89557b1401c0b3d. Anfangs falsches Banner-Testorakel separat als Diagnose erhalten; unveränderteHTMLbytes danach erneut vollständig bestanden.
- Normale Editorimporte melden alte Plugin-/UID-/Shutdown-Leakdiagnosen. Recoverymode schaltet notwendige Terrain3D-Typen aus und wurde als ungeeignete Diagnose verworfen. Isolierter frischer Import identischer aktiver GLBs/PNG ist sauber, tatsächliche Spielruntime separat grün. NativeWrapper erfasste keinen gesonderten OS-Exitcode; kein erfundener Exit0-Claim.
- UI unverändert. GM01 bleibt Square8, Hex-Werft separat. Buccaneer statisch integriert, Cutlass echter Missionsanflug. Keine allgemeine Releasefreigabe.
