# Polisa: Tankservice und offene Schiffsausruestung

## Ziel / Ursache
Der feste +10-Tankknopf scheitert bei weniger als10 fehlenden Einheiten; Tankstand,
Kosten und gelandeter Cargo-Bestand sind in Polisa nicht sichtbar. Der Schiffs-
ausruestungsbereich besitzt noch keinen Hardpoint-/Loadoutowner oder Verbraucher.

## Basis / relevante Dokumente
Bewusst auf dem noch nicht integrierten task/native-glut-maps-20261110 nach Polisa
R02. PROJECT_BRIEF, ARCHITECTURE, CODEX_RULES, IMPLEMENTATION_STATUS,
ACTIVE_WORKPLAN_2026_11_11, POLISA_STATION_2026_11_11,
orbit_quantum_travel_contract, singleplayer_locations_jobs_contract und
polisa_ship_equipment_contract. Root hat diesen kleinen Fallback freigegeben.

## Umfang / Nichtziele
Polisa liest Fuel, Capacity und Preis aus Supply via Adapter. Der Tankknopf
fordert min(10,fehlendeMenge) ueber denselben refuel-Command an, mit sichtbaren
Kosten. Voller Tank, fehlender Stationsservice, unbekanntes Schiff und fehlendes
Geld sperren die Aktion. Cargo-Mengen und Ankaufbestand werden sichtbar.
Kein Supply-/Tabletop-/Combatumbau, keine Modelle, keine lokale Schiffsabholung,
keine neuen Komponenten oder Balancewerte. Schiffsausruestung bleibt offen.

## Akzeptanz
- Tank95/100 fordert5 statt10 an; bestehender Owner akzeptiert und berechnet5.
- Tank100/100 und fehlender LandedService senden keinen UI-Tankcommand.
- Snapshot zeigt tatsaechlichen Tank des fokussierten Polisa-Schiffs.
- Warenankauf zeigt die tatsaechliche endliche Schiffslager-Menge.

## Dateien
scripts/ui/polisa_station_screen.gd; scripts/meta/singleplayer_runtime_adapter.gd;
scripts/tests/polisa_services_remainder_check.gd; dieser Task;
docs/dev/polisa_ship_equipment_contract.md; eigene QA unter
 docs/qa/polisa_services_remainder_20261111/.

## Lokale Pruefung / Risiken
Nur kleiner isolierter Domain-/UIcommand-Check und Check-only, git diff --check.
Native Reise/Schalter/Shop/SaveContinue und Layout bleiben spaeter; die Anzeige
ersetzt keine autoritative Revalidierung bei Klick. Keine Main-/EXE-Freigabe.

Reviewfolge: Adapter-Lifetime/Methoden und Snapshot-Dictionary werden vor dem
Tankaufruf geprueft. Zusaetzliche Nulladapterprobe: finale kleineDomain11/0.
