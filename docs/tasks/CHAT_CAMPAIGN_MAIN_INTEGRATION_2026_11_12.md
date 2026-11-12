# Kampagnenarbeit dieses Chats auf Main integrieren

## Ziel und Ursache
Die Chat-Aenderungen aus Commit `1a8b3774d` fuer Kampagnenhilfe, Anwerbung, Shuttle, Fracht und modulare Basis auf Main uebernehmen. Der Task-Commit basiert auf 334 aelteren, nicht integrierten Commits; ein direkter Merge wuerde diese pauschal mitnehmen. Die Nutzerfreigabe umfasst die gezielte Portierung der tatsaechlich erforderlichen Grundlagen.

## Umfang und Nicht-Ziele
Nur Chat-Aenderungen und fuer deren reale Ausfuehrung erforderliche, einzeln nachvollziehbare Simulation-, Hex-, Stations-, Reise- und Datenabhaengigkeiten portieren. Andere Features, Commits und Artefakte nicht blind uebernehmen. Kein Zugriff auf den Desktop, Maus oder persoenliche Spielstaende.

## Contracts
Projektarchitektur, `docs/dev/base_automatic_rest_contract.md`, vorhandene Kampagnen-, Transport-, Inventar- und Save-Vertraege. Simulation/Runtime besitzen Gameplaywahrheit; UI liest und sendet Commands.

## Akzeptanz
Saubere Main-basierte Integration mit dokumentierten Grundlagen; bestehende Main-Funktionen erhalten. Import und relevante Runtime-Pruefungen erfassen Fehler, isolierter Spielstand, echte Kampagnen-/Shuttle-/Fracht-/Basis- und Savepfade. Vor Main-Merge Konflikte aufloesen und finalen Integrationsstand pruefen. Nicht nachgewiesene visuelle oder physikalische Aspekte explizit benennen.

## Betroffene Bereiche, Pruefung und Risiken
SimulationRoot/Hex-Owner, Missions- und Stationsdaten, Reise-/Supply-/Personalowner, Checkpoint und UI. Grosse Divergenz in zentralen Dateien erfordert gezielte Konfliktanalyse und Regressionen; nur direkte Referenzen zu kopieren belegt keine korrekte Ownerintegration. Automatisch erzeugte Importe/Testprofile nicht einchecken.

## Chatuebergreifende Koordination und Reihenfolge
Auf ausdruecklichen Nutzerauftrag aus dem Chat `Kartenumbau integrieren` werden anschliessend auch AP7 und der Fuenf-Minuten-Autosave aus `1b924b640` sowie die Weltraum-/Luftaenderungen aus dem gepinnten, remote gesicherten `a8a098fad` auf den dann integrierten Stand gebracht. Diese Basis ist kein Vorfahr des urspruenglichen Companion-Chatstands. Erst den Companion-Port stabilisieren und sichern; danach AP7/Autosave und Raum-/Lufthunks gezielt mit bestehenden Companion-Ownern zusammenfuehren, ohne gemeinsame Root-/Adapter-/Controller-/Checkpointdateien durch alte Gesamtdateien zu ueberschreiben. Gepruefte Bestandteile und weiterhin rote Grenzen getrennt ausweisen. Kein EXE-Export ohne erneute ausdrueckliche Nutzerfreigabe.

Der Nutzer hat ausserdem praezisiert, dass der gesamte Chat `Weltraumkämpfe konzipieren` beruecksichtigt werden soll. Ein vollstaendiges Paketmanifest der beteiligten Branches ist angefordert; vor Abschluss werden vorhandene, in `a8a098fad` enthaltene, hier portierte, noch fehlende und ausdruecklich unfertige Teile getrennt abgeglichen. `a8a098fad` allein ist kein Vollstaendigkeitsnachweis. Insbesondere sind Radar, aktiver Missions-Save und der auf dem Quellstand fehlgeschlagene echte Flugstart noch nicht als fertig belegt.

### Eingegangenes Weltraum-Manifest
Original-Implementierungsbranch `1358b86eb`, Komponenten-/Rettungsbranch `99d82f999`, Ground-/AP7-Basis `1b924b640`, kombinierter Luftstand `a8a098fad` (remote gesichert). `99d82f999` und `1b924b640` sind in `a8a098fad` enthalten; `1358b86eb` ist kein Vorfahr und muss inhaltlich verglichen werden. Das Source-Audit nennt fuer Kernbereiche bytegleiche oder patchaequivalente Nachfolger, aber separate Test-/Dokubelege und untracked Artefakte bleiben geschuetzt. Weitere Polisa-/Orbit-Heads wurden als patchaequivalent bzw. als Vorfahren eingeordnet.

Beim Join explizit abgleichen: Flight-/Wing-/Combat-/Registry-/Area-/Guidance-Owner und Rechte/Replay; Komponenten S1–S5, Schilde/Kraftwerke, Massen/Leistung und Equipmentsave; Buccaneer-Rettung samt Gegnerschiff, Feuer, Ergebnis, Kraftstoff und Rueckweg; Mission-Root-/Luftunterstuetzung, Boarding, Bodenbelegung, Sicht/Lasersignal und UI. Tests muessen die fertigen Teile gegen den tatsaechlichen Integrationsstand pruefen. Quellseitig weiterhin rot: echter Satellitenmissions-Luftstart `ground_unavailable` (35/36); Radar, aktiver Missions-Save/Continue, komplette native/Multiplayer-/Performanceabnahme und Release sind nicht belegt.

### Integrationsstand und Grenzen
Der echte Legacy-Satellitenanflug benoetigt keinen regionalen Chunk-Prefill: Der Fallback entscheidet anhand der geladenen Kartendaten. Intern wurden Landung, Ausstieg, Rueckweg und Boarding mit 37 erfolgreichen Pruefungen auf der unveraenderten Produktionskarte beobachtet. Das private Hex-Opt-in bleibt deaktiviert: Rueckweg zum Schiff nicht erfolgreich; der Luftstart auf Legacy-Boden meldet `ground_unavailable`. Keine Freigabe fuer die Luftunterstuetzung oder das experimentelle Karten-Opt-in.

AP7-Continue wurde in separater Projektkopie mit isoliertem Profil geprueft: 17 positive und drei negative Checks, Quelldateien und reales Profil unveraendert. Die Mehrspieler-Contracts und Session-/Lobby-Anbindung wurden gezielt portiert; vorhandene Tests und simulierte Host-/Client-Smokes bestehen. Ein Test mit zwei getrennten Netzwerkprozessen, vollstaendige native Grafik- und Performanceabnahme sowie ein Einsatz-Save bleiben offen. Godot-Editorimport meldete weiterhin die bereits vorhandene ObjectDB-Leak-Warnung; kein sauberer Importgate-Nachweis. Keine EXE erstellt.

### Nachtrag: Hex-Tuerschutz
Der historische Abgleich ergab, dass der Door-Consumer im Missionsdriver fehlte, obwohl die Ground-Owner-API vorhanden war. Der Driver prueft nun vor Ressourcenannahme und Interaktionszustandsaenderung, ob die zu schliessenden Felder durch aktuelle Belegung, Kanten oder Passageclaims geschuetzt sind. Legacy-Karten behalten ihr bisheriges Verhalten. Der uebernommene `hex_door_guard_verifier.gd` reproduzierte zuvor sechs Fehler und bestand nach der Korrektur mit 58/0. Isoliertes Profil; keine EXE.
