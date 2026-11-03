# Native Bildnachprüfung der begrenzten Runde

Nach Dokumentaudit und direktem Originalvergleich wurden die neuen unveränderten Engine-PNGs tatsächlich geöffnet: reguläre Mission bei 1920×1080 und 1280×720, Heimatbasis des normalen Starts, belegte FOB sowie Personen-Debrief und Heimatbasis-Fixture bei kleiner Auflösung. Alle vier Originalziele wurden zuvor direkt angesehen; Brückenbilder ersetzen sie nicht.

| Bereich | Beobachtete Änderung | Verbleibender Abstand |
|---|---|---|
| Mission | Zwei echte Reihen 52px-Aktionen, 128px-Randband; Ziel/Team weiter nach links. Gestufte Rahmen und Petrol-Protokoll ordnen die Flächen. | Linke Truppkarte und Transportkarte bleiben textlastig; Weltmodelle und Kamera unterscheiden sich stark vom Original. |
| Hexraster | Einzelne Hexfelder sind nun auf Sand und Serviceflächen in beiden nativen Auflösungen erkennbar. | In großen Übersichten wirkt das Raster stellenweise kräftig; die gewünschte Dezenz bleibt ein Nutzerurteil. Keine Bildschirmraum-Breitenregel und keine vollständige Zoomabnahme. |
| Heimatbasis / FOB | Gemeinsame gefaste Rahmen, getrennte Kartenköpfe und Portraitfenster sind sichtbar; reale Auswahl- und Ausrüstungskarten behalten ihre Controls. | Lange beziehungsweise leere Spalten und die entfernte untere Bühne bleiben. Explizite kleine Karten-Overrides und vorhandene Pixelportraits entsprechen noch nicht den großen illustrierten Identitätskarten. |
| Debrief | Ergebnis-/Personen-/Rückwegkarten gehören erkennbar derselben Rahmenfamilie an; 1280er Rückwege bleiben im Dialog. | Zentrierter Dialog mit freien Ergebnisflächen, kleiner Szenenminiatur und scrollbarer Personenliste unterscheidet sich weiterhin von der großflächigen Originalkomposition. |

Die Sichtmaske bleibt aktiv. Der entfernte temporäre schwarze Aufbaukasten ist keine Abschaltung des FoW. Die warme 8%-Bodenabtönung und der unabhängige dynamische Gegnerfilter sind in dieser Runde unverändert. Standbilder beweisen keine vollständige zeitliche Flackerfreiheit.

## Konkreter Ansatz für die größere Modellrunde

Der sichtbare Gebäudestand ist nicht einfach die geladene GLB: `scripts/terrain/frontier_gm01_layout.gd::_add_structure` lädt `structures_pass04/habitat_cutaway_01.glb` und `freihafen_hall_01.glb`, berechnet deren Bounds, baut dann eine `ClosedExterior`-Hülle und setzt `visual.visible = false`. Die tatsächlich sichtbaren Habitat-/Hallenhauptformen stammen aus `scripts/terrain/frontier_closed_buildings.gd` (`_build_habitat`, `_build_hall`, `_add_front`).

Die bisherigen engen Bounds-/Höhenmargen sind technische Entscheidungen dieses Builders, kein allgemeines MD-Verbot gegen tiefere Portale, gestaffelte Dächer oder passendere Silhouetten. Die Vorlage soll weiterhin eine geschlossene spielbare Außenansicht erhalten; die verborgene Schnittansicht einfach einzublenden wäre keine referenztreue Lösung. Formrevisionen müssen sichtbare Hülle und gespeicherte Solid-/Deckungsfakten zusammenhalten: bei geänderten Fußabdrücken den bestehenden Authoringpfad `scripts/tools/build_gm01_frontier.gd` verwenden und Karten-/Nav-/LOS-Prüfungen wiederholen.

Priorität: Habitat/Halle direkt neben dem A5-Original prüfen, Hauptkörper und Portaltiefe überarbeiten; anschließend Felsstaffelung in `frontier_art_geology.gd`, Kameramaßstab und lokale Bodenkontakte. Die exakte Ref03-Cutlass bleibt erhalten. Ein bloßer Wechsel der geladenen, anschließend versteckten GLB verbessert die aktive Silhouette nicht.

## Technische Nachweise und Grenzen

- Acht gezielte Engine-Gates mit insgesamt 857 Assertions grün; normale Menü→Heimatbasis→GM01→Transport/LZ→Ausladen→Move/GO-Route zweimal mit je 51 Checks grün. Keine Actor-, Timer- oder Zeitbeschleunigungspatches.
- Sechs native Fixturebilder für FOB, Heimatbasis und Debrief bei beiden Größen separat grün; sie sind keine physische Missionsabnahme.
- Zwei frühere Normalstart-Vorläufe erfüllten ihre funktionalen Checks, wurden wegen Ogg-Bewegungs-Audioobjekten beim Prozessende verworfen. Der neue Captureadapter wartet ausschließlich **nach Freigabe der Spielszene** 350ms auf Audio-Freigabe. Beide abschließend akzeptierten Prozesse enden danach ohne Engine-/Leakwarnung. Keine Produktions-Audiologik geändert und kein Warnfilter gelockert.
- Frühere rote Layout-/Metadatenläufe bleiben als Rohbelege erhalten, zählen nicht als finale Abnahme. Details in `REVIEW.md`; gewählte Pfade im QA-README und Quellenmanifest.
- Lokale HTML-Exportlogik wurde in Node mit synthetischem DOM geprüft. Kein Browserlayout-/echter Browserdownload-, Gesamtleistungs-, Kampagnen-, Mehrspieler-, EXE- oder Releasebeleg. Keine gestalterische Nutzerfreigabe behauptet.
