# N8 Arbeitsstand — 21.09.2026

Plan: N8_IMPLEMENTATION_PLAN.md. Basis: 61f77cd. Keine finale Abnahme, kein N8-Paket veröffentlicht.

## Nachgewiesen in dieser Sitzung
- Core-Spielweg: 106/106, einschließlich realem Rampenzugang zur Werkbank.
- Welt: 320/320, 30 Ziele und 44 Regionsebenen; alle Interaktionen und echte Wege geprüft.
- Crew-Navigation: 173/173 (langsamster Pfad 1530 ms); Altsave-Migration: 67/67.
- Energie: 34/34, Strommangel/Reservierung/Restore, Solarausbau, endlicher Anlagenkauf bis großer Fusion und identische Netzwerk-Wiederholung.
- Forschung: 10/10. Team-Kampagne: 21/21. Weltintegrität: 21/21.
- Neue gezielte Tests: terrain_levels_test, flight_terrain_test, site_state_test und n8_legacy_team_test grün.
- 16 echte Prozesse: ENet sternen-team16-efdf4cb2fd25466dab84db90658764b2; WebSocket sternen-team16-65ebd9b3609e44c080f4a7fd0a01e011 (Temp-Verzeichnisse).
- Native Referenz-UX: 9/9; actual renderer captures output/n8-*.png.

## Korrekturen und Entscheidungen
- Feste 20-s-Annahme im Cutter-Test durch begrenztes Warten auf Arbeitsabschluss ersetzt: neue Rampen verlängern den tatsächlichen Laufweg.
- Varianten-Hochflächen versetzt, nachdem vollständige Wegprüfung abgeschnittene Händlerzugänge zeigte.
- Fehlende N8-Ortsdaten vor der aktuellen Save-Prüfung ergänzen; beschädigte N8-Daten nicht reparieren. Neue Legacy-Team-Probe reproduzierte und prüft den Fix.
- Inaktive Ortskontakte müssen Typ, Position und Entdeckungsstatus erfüllen; gezielte Rot-Grün-Probe.
- Reservierte Anlagenflächen bleiben als Fundamente sichtbar, auch wenn das Modell noch nicht gebaut ist.
- Flugdarstellung verwendet vorausschauenden Höhenabstand über dem ganzen Rumpf; ebene Landeflächen bleiben erforderlich.

## Noch vor Freigabe zu erledigen
- Frische Codeprüfung ausgewertet: Legacy-Validierung vor Erweiterung, Varianten-Werkzeugprüfung und gemeinsame Wrackreste korrigiert; gezielte Regressionstests grün.
- Referenzstil/Architektur noch nicht als erreicht abnehmen. Geländeübergänge und Gebäudedichte kritisch vergleichen.
- Sender II schaltet Fernziele frei; sichtbare Antennenstufe, zusätzliche garantierte Bauplanfunde und Zugang vom gewählten Heimatplaneten prüfen.
- Hauptgebäude/Innenräume der Varianten stärker unterscheiden; wiederholbare Auftragsinstanzen fehlen noch.
- Abschließende Fensterläufe, eigenes N8-Paket und mobiler Bericht; N7 unverändert verfügbar halten.

## Gemeinsame Wirtschaft und neue Waren
- Nahrung (`food`) und medizinische Güter (`medical_supplies`) sind kauf-/verkaufbare Frachteinträge mit eigenen Icons und regionalen Preisen. Medizinische Güter sind getrennt von Medgun-Ladungen; kein Hunger- oder Verbrauchssystem ergänzt.
- Händlerbestand pro benanntem Ort gilt für alle Teams. Kauf verringert ihn, Verkauf führt Ware zurück. Auch Energieanlagen und angebotene Baupläne sind endlich.
- Alle 300 Sekunden Simulationszeit trifft Nachschub in Höhe eines halben Standardbestands ein, begrenzt auf den Standardbestand. Pause stoppt den Timer. Bestände und Timer werden gespeichert und geladen.
- Ressourcen und Wrackreste gehören zum gemeinsamen Weltzustand; keine getrennte Beute je Team.
- Aktueller Regressionslauf: Welt 320/320, Navigation 173/173, Migration 67/67, Energie 34/34; Ortsdaten-, Legacy-Team-, gemeinsame Markt-, Varianten-Ausrüstungs- und Handelswarentests ohne Fehler.
- Nach Einführung der Waren erneut 16 echte lokale Netzwerkprozesse bestanden: ENet `sternen-team16-e1a7ecfa141647c892924b5eaddf4be4`, WebSocket `sternen-team16-c86c9d1dc4514bf99b1d6bc474a353c0` (Temp-Evidenz). Das ist kein Test zwischen zwei entfernten Internetanschlüssen.
- Spieländerungen weiterhin lokal im N8-Arbeitsstand; kein neues Windows-Paket veröffentlicht. Privater Handybericht unter https://sternenbuergerchen-neustart.klabauta.chatgpt.site/n8.html am 21.09.2026 erfolgreich veröffentlicht. Enthält echte Aufnahmen, direkte Referenzvergleiche und ausdrücklich offene Arbeiten.

## Umgesetzt: automatische, überfallbare NPC-Verladung
- Handel und Basislager/Schiffstransfers buchen nicht mehr unmittelbar ans Ziel. NPCs tragen reale Kisten, mit Pause, Abbruch, Verwundung, gegnerischer Aufnahme und korrekter einmaliger Warenvergabe.
- Kauf reserviert gemeinsamen Händlerbestand; Verkauf bezahlt erst bei tatsächlicher Lieferung. Geteilte Frachtwelt, aktive Träger und offene Aufträge sind speicherbar. Start/Reise warten auf Abschluss oder Abbruch.
- Nachweise und genaue Grenzen: [N8_FREIGHT.md](../N8_FREIGHT.md). Neue Kern-, Überfall-, Konkurrenz-, native Maus- und Zwei-Prozess-Netzwerkproben bestanden; 16-Prozess-ENet und WebSockets ebenfalls grün.
- Frischer gezielter Review fand eine Übernahme kämpfender PvP-NPCs durch automatische Verladung. Rot-Grün-Test hinzugefügt und behoben: der Kern erhält die tatsächlich durch PvP gebundenen Figuren als abgeleitete Ausschlussliste. Bestehende Angriffe bleiben bestehen.
- Grenzen: Mining-/Bergungs-Ausgabepfade sind noch keine Feldlogistikkette; die persönliche Missions-Blackbox ist noch nicht zwischen Karrieren übertragbar. Normale Handelswaren sind stehlbar. Kein Schiffsenterungssystem, keine Laderoboter oder großen begehbaren Frachträume.
