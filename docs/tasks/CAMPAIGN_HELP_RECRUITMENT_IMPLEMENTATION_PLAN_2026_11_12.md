# Umsetzungsplan: Kampagnenhilfe und Polisa-Anwerbung

**Ziel:** Kontextbezogene Kampagnenhilfe und dauerhafte Anwerbung mit Vergleich und realer Shuttle-Anreise.

**Grundlage:** `CAMPAIGN_HELP_RECRUITMENT_2026_11_12.md`. Arbeitsbasis ist der noch nicht in Main integrierte Port-Olisar-Commit `fed720fc0762abba66b32b1b0122b125ef68833a`.

## Reihenfolge und Pruefung

1. **Owner- und Speichervertrag:** Kandidaten, stabile Angebotsidentitaeten, Spielerpersonal und autorisierte Credits-Buchung entwerfen. Fuer Annahme, doppelte Commands, veraltete Angebote und ungenuendes Guthaben je einen Verifier schreiben; Checkpoint-Rostergrenze und Restore-Belege mit alten Staenden pruefen. Keine UI-seitige Mutation.
2. **Stationsinteraktion und Vergleich:** Autorisierten lokalen Anwerber am Globus identifizieren; dessen vorhandene Kommunikations-/Fuehrungswerte nachvollziehbar in die Angebotsqualitaet einbeziehen. Karten mit Preis und Werten, bestehende Charakterbogenansicht und nebeneinander vergleichbare Auswahl anbinden. Nicht verfuegbare lokale Interaktion erklaeren. Godot- und native UI-Pruefung einschliesslich kleiner Aufloesung.
3. **Betten und Ankunft:** Gebaute Kapazitaet von automatisch nach Rosterzahl ergaenzten Feldbetten unterscheiden und vor Anwerbung warnen. Echte Ortsidentitaet, Personentransfer, vorhandenes Spielerschiff, Stations-Shuttle, Boarding, Flug, Landung und Bedarfsrueckflug verbindlich pruefen. Fuenf-Minuten-Frist erst nach Ankunft starten; erteilte Aufgabe oder gueltiges Bett beenden den Rueckkehrgrund. Checkpoint-Sperre und Wiederherstellbarkeit fuer aktive Transporte eindeutig absichern.
4. **Kontextuelle Hilfe:** IDs und Katalogeintraege fuer Basis, Ausruestung, Einkauf, Frachtaufzug, Schiff und Anwerbung erstellen. Bestehendes Popup mit Maus/Fokus und off/compact/expanded anbinden; dynamische Controls nach Erzeugung verbinden, keinen per-frame Baumscan einfuehren. Ausschalten und Erreichbarkeit durch Tests sowie native Sichtpruefung belegen.
5. **Integration:** Bestehende Kampagnenrekrutierung, Missionen, Einkaeufe, Fracht und Reise regressionspruefen. Spielpfad mit und ohne eigenes Schiff und mit und ohne Bett durchgehen; Screenshots und Ergebnisse dokumentieren. Erst danach Integrationsstand benennen.

## Besondere Risiken
Der Shuttle-Service ist keine existierende, belegte Gesamtfunktion. Spawn eines eigenstaendigen Cutlass und Piloten, sichtbare Reise und NPC-Ortsuebernahme duerfen nicht durch Animationen oder UI-Status simuliert werden. Die bisherige Basis-Checkpointgrenze und der bisherige Kapazitaetsmechanismus widersprechen einem einfachen Einbau. Kandidatenpreise, Aktualisierungszeitpunkt und Gewichtung der Skills sind technische Balanceannahmen und muessen im Spiel sichtbar und reproduzierbar sein.
