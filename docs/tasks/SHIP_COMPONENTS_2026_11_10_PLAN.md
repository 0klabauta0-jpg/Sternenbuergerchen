# Schiffskomponenten: Ausbauplan

Status10.11.2026: vom Nutzer zusätzlich zur bestehenden Schiffsverwaltung
gewünscht, ausdrücklich zunächst planen. Keine Komponentenwirkung implementiert.

## Ziel und Nutzen
Schiffe an der Basis mit austauschbaren Komponenten ausrüsten. Konkrete
Komponente, Kompatibilität, Kosten, Bestand und resultierende Werte gemeinsam
zeigen. Pilot/FT-Mitgliedschaft, Fracht, Boarding und aktuelle Reiseroute bleiben
bei ihren bestehenden Ownern; Komponenten erzeugen keine zweite Schiffswahrheit.

## Umsetzungsschritte
1. Versionierter Komponenten-/Slotkatalog und eindeutige IDs pro Schiffmodell.
   Als erster Umfang Waffen, Schild, Antrieb, Energieversorgung prüfen; die
   genaue Slotliste/Kompatibilität ist noch festzulegen.
2. SimulationRoot-gebundener Schiffsloadoutowner, Befehle für atomaren
   Aus-/Einbau aus endlichem Basis-/Schiffslager. Nur tatsächlich geerdete,
   unbeschäftigte Schiffe; Replay/Bestand/Kapazität/Kompatibilität validieren.
3. Save-/Restoremigration mit vorhandenen Schiffen und stabilen Defaults.
4. Basiswerkstatt: Schiff/Slot wählen, echte aktuelle Komponente und Vergleich
   der resultierenden Werte, Austausch per Klick und Drag-and-drop.
5. Kampf-/Fuel-/Maneuvercontracts lesen bestätigten Komponentenstand; keine
   Statberechnung ausschließlich in der Oberfläche. Erst dann Balancing.
6. Tests: Erhaltung ohne Duplikate, falscher Slot, fehlender Bestand,
   Schiff unterwegs, veralteter Request, Save/Continue, wirkliche Runtimewirkung.

## Daten und offene Entscheidungen
Erkul-Freigabelink https://erkul.games/s/85yjk7o5 ist Ausgangsreferenz;
datierter Cutlass-Stand unter data/reference/erkul_cutlass_black_20261110.json.
Keine automatische 1:1-Übernahme in kompakte Spielkarten. Komponentenmodelle,
Slotgrößen, erste konkrete Komponenten, Ausbaukosten und Einbauzeit sind offen.
Keine zusätzlichen 3D-Modelle oder freien Gebäudebau in diesem Plan zugesagt.
Relevante Contracts: orbit_quantum_travel_contract, personnel_inventory_contract,
homebase_direct_dropship_flow_contract; bestehende Craft-/Supply-/Loadoutowner.

## Akzeptanz
Ein tatsächlich vorhandenes Schiff kann eine tatsächlich vorhandene passende
Komponente erhalten; Ursprungslager verliert genau dieses Item, ausgebaute
Komponente kehrt in ein zugängliches Lager zurück. Werte und Savezustand stimmen
in Basis und Mission überein. Main-/EXE-Abschluss erst nach eigener Umsetzung.
