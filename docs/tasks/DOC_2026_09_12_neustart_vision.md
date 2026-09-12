# Neustart: Spielvision, Analyse und Arbeitsplan

## Ziel und Anlass
Der Nutzer möchte seine ursprüngliche und fortentwickelte Commander-Spielidee rekonstruieren und einen vollständigen Neustart planen: zwei befreundete NPCs, eigenes kleines Shuttle, sichtbare Slotbasis, Aufträge, Crew-Wachstum, Wirtschaft, Boden und Raum sowie Koop/PvP. Zunächst eine Rostwelt mit getrennten, taktisch ausreichend großen Einsatzkarten. Lieferumfang ist Analyse, Entwicklungsplan und lokale interaktive HTML, keine aktuelle Gameplay-Implementierung.

## Arbeitsbasis
- `integration/core-foundation` auf `3cae5a216d380b58fef92724540e95fbc49bde7e`.
- Eigener Dokumentations-Worktree `task-neustart-vision-2026-09-12`, Branch `task/neustart-vision-2026-09-12`.
- Alt-GDD, Originalnutzerwünsche vom 19.07. und 01.09.2026 und heutige Commander-Bestätigung werden mit Quellenstatus zusammengeführt.

## Umfang und Grenzen
- Historische Absichten, statisch belegter Bestand, heutige Wünsche und neue Vorschläge unterscheiden.
- Kenney/Rostwelt/Space-Opera-Konzeptbilder unverändert in eine eigenständige HTML einbetten.
- N0–N8 einschließlich früher Netzprobe N1a als überprüfbare Spielergebnisse planen; beantwortete Grundsatzfragen festhalten und verbleibende Ausführungsdetails kennzeichnen.
- Keine Runtime, Assets, alten Arbeitsbäume, fremden WIP oder alten Roadmap-Pakete ändern.

## Relevante Dokumente
`PROJECT_BRIEF.md`, `ARCHITECTURE.md`, `CODEX_RULES.md`, `IMPLEMENTATION_STATUS.md`, `GDD_STATUS.md`, `DESIGN_NOTES.md`, `dev/html_report_workbench_contract.md`, bestehende Landschaftsberichte und ausgewählte Missions-/Personalquellen.

## Dateien und Akzeptanz
- `docs/reports/STERNENBUERGERCHEN_NEUSTART_2026-09-12.html`: deutsch, offline, mobil und Desktop; Quellen, Entscheidungen, Notizen, lokale Speicherung, JSON-Export und Textfallback.
- `docs/superpowers/plans/2026-09-12-sternenbuergerchen-neustart.md`: Abhängigkeiten, vorgeschlagene Zustandsbesitzer, konkrete erste Umsetzung, Abnahmegates und Risiken.
- Diese Task-Datei und ein knapper Dokumentationseintrag in `IMPLEMENTATION_STATUS.md`.
- Browserprüfung: keine JavaScript-Fehler, keine fehlenden Bilder, keine horizontale Überbreite, Navigation/Filter/Notizen/Export funktionieren.

## Risiken / Evidenzgrenze
Keine neue Godot-Messung oder vollständige Codeprüfung. Historische Performance bleibt an ihre Mess-SHAs gebunden. Der Plan ist ein Reviewentwurf, kein umgesetzter Neustart und keine automatische Ersetzung des alten Projektbriefs. Eine bessere Modellgeneration allein ist kein Erfolgsnachweis.

## Erste Fassung: lokale Abschlussprüfung
- Playwright/Chromium über direkten `file://`-Aufruf, 12.09.2026 16:13 UTC.
- Desktop 1440x1000 und Mobile 390x844: kein horizontaler Seitenüberlauf; Screenshots angesehen.
- 13 Kapitel, 11 offene Entscheidungsfelder; sämtliche lokalen Quelllinks und Anker erreichbar, keine doppelten IDs, alle vier eingebetteten Bildverwendungen geladen.
- JavaScript-Syntax, Missionsschritte, Boden-/Raumfilter, Forschungsbaum, Notizen/Entscheidungen nach Reload, JSON-Download und Exporttext, Import-Roundtrip, ungültiger Import sowie Bilddialog erfolgreich geprüft.
- Browserfehler: 0; externe Ressourcenanfragen: 0. Testnotizen nach Prüfung entfernt.
- Unabhängiger Inhaltsreview: eine Timing-Differenz zwischen Plan und HTML korrigiert (Basis vor N3, Weltverbindung vor N4); Startschiff als frühe Entscheidung im Plan ergänzt.
- Die HTML enthält alle Inhalte und Bilder selbst. Verlinkte Markdown-Quellen und der Zusatzplan sind ergänzende lokale Dokumente.

## Revision 2: Nutzerantworten und Quellen ergänzt
- Kleine Freundesgruppe aus 2–3 NPCs, sichtbare Basis ab N1, Bauslots/Verbinder, Bett je Mitglied, Waffenkammer, Forschung, Lager und Werkstatt verbindlich übernommen.
- Interaktion konkretisiert: Werkbank/Maschine anklicken, passenden verfügbaren NPC zuweisen, zugehöriges Menü öffnen und Rezept ausführen. Arbeitsplatz bindet die Person; Produktion, Materialreservierung und Crewverfügbarkeit gehören zum gemeinsamen Spielstand.
- Pause, verzögerter Respawn, Verwundung/Evakuierung/Reparatur, früher Stationsmarkt, eine Rostwelt mit getrennten Karten und fähigkeitsabhängige Raum-Suchaufträge eingearbeitet. Besitzmodell, Respawnwerte, Multiplayer-Pausenregel, Punkteformel und Kartenmaße bleiben auszuarbeiten.
- Koop/PvP als Kernanforderungen: N1a echte Zwei-Client-Probe, N2 Boden-Koop/PvP, N6 Raum-Koop/PvP, N7 zusammenhängende Koop-Kampagne und wiederholbare PvP-Partien, N8 Solo-/Koop-Abschluss mit vorherigen PvP-Nachweisen.
- Kenney-Sammlung und ausgewählte Modelle samt sechs lokaler Pack-Lizenzen geprüft; kleine Auswahl den Basisfunktionen zugeordnet. Schiffsordner inventarisiert: 155 Dateien, darunter 122 FBX/OBJ und keine STL. Readme nennt RSI als Herkunft, gesonderte Spielnutzungserlaubnis liegt in der Sammlung nicht vor. Keine Modelle kopiert, verändert oder in Godot geprüft.
- Godot 4.6.2 als Präferenz aufgenommen; kein Enginewechsel oder Projektstart vorgenommen.

## Revision 2: Abschlussprüfung
- Playwright/Chromium, direkter lokaler `file://`-Aufruf, 12.09.2026 17:01 UTC: 13 Kapitel, 14 festgehaltene Entscheidungs-/Themenkarten und 5 verbleibende Detailparameter.
- Desktop 1440x1000 und Mobile 390x844 ohne horizontalen Seitenüberlauf. Hero, Crafting-Karte und Kenney-Auswahl per Screenshot angesehen; vier eingebettete Bildverwendungen geladen.
- Skriptsyntax, lokale Quelllinks, Anker, Missionsschritte, Berufsfilter, Forschungsbaum und Bilddialog bestanden. Keine doppelten IDs, Browserfehler oder externen Ressourcenanfragen.
- Alte v1-Notizen einschließlich Kartengrößenkommentar bleiben erhalten; alte Auswahlwerte überschreiben keine bestätigten Entscheidungen. Neue Parameter/Notizen überstehen Reload, JSON-Download/Text und Import-Roundtrip. Ungültiger Import verändert vorhandene Notizen nicht.
- Unabhängiger Inhaltsreview: Schiffskatalog bedarfsabhängig gehalten, Multiplayer-Abnahmen N6–N8 mit dem Plan angeglichen und zusätzliche Rettungs-/Reparatur-Auftragsketten von frühen Kernfunktionen unterschieden.
- Prüfartefakte liegen außerhalb des Repositorys unter `C:\Users\bjoer\.codex\visualizations\2026\09\12\01a09651-a457-70e0-8d66-a5d15acc6f31\neustart-pruefung\revision-2`. Testnotizen im isolierten Prüfprofil entfernt.


## Revision 3: übermittelter Review vom 12.09.2026, 17:27 UTC
- Ursache: Der Nutzer hat den Export aus der ersten HTML-Fassung übermittelt. Auswahlfelder, Freitext und bereits bestätigte Gesprächsentscheidungen werden zusammengeführt; keine automatische Rücknahme von Koop/PvP durch ein älteres Dropdown.
- Zwei NPCs und eigenes kleines Shuttle festgelegt. Echtzeit mit Pause ausdrücklich im Singleplayer und Multiplayer; genaue gemeinsame Pausenberechtigung bleibt offen. Kartenmaßstab meint das Gelände um Außenposten/Bunker; sichtbare Reiseübergänge und Rostwelt mit Space-Opera-Formen aufgenommen.
- Reviewstatus „Richtung passt, Details offen“, alle drei Lesemarkierungen und Fokus „Landschaft und Weltgröße“ festgehalten. Solo zuerst bedeutet N1 lokal, anschließend N1a/N2; Koop/PvP bleiben Kernziele. Die Enginewahl ist kein bereits erfolgter Versionsnachweis.
- Der semantisch unveränderte Export ist unter `docs/reports/reviews/neustart_2026_09_12_review_172730.json` archiviert. Nur HTML-Entities und Markdown-Escapes der übermittelten Darstellung wurden normalisiert. HTML, Plan und Status synchronisiert; keine Runtime geändert.
- Prüfung 12.09.2026, 17:33 UTC: Desktop/Mobile ohne Überbreite, 13 Kapitel, 14 festgehaltene Themen und 5 Detailparameter. Tatsächlichen Nutzerdatensatz importiert: Notizen, Durchsicht und Fokus korrekt übernommen; aufgezeichnete Entscheidungen bleiben geschützt. Reload, JSON-Download/Text, Import-Roundtrip, ungültiger Import, lokale Quelllinks, Bilder und Bedienfunktionen bestanden; keine Browserfehler oder externen Anfragen.
- Unabhängiger Review korrigierte letzte offene Startzahl-/Eigentumsformulierungen in N1, Schiffstabelle und Entscheidungsabschnitt. Prüfbilder/-bericht liegen im bisherigen externen Prüfverzeichnis unter `revision-3`.
