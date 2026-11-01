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
In Arbeit. Konkrete Prüfberichte und Commitbezug werden nach der tatsächlichen Integration ergänzt.
