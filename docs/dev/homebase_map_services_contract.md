# Heimatbasis: Karte, Pads und Services

Stand: 09.11.2026. Zielvertrag fuer AP3/AP5/AP7; native Abnahme ist gesondert.

TerrainMapData/TerrainRegistry besitzen Hexfelder, Boeden, Tueren, Aussenwaende,
Begehbarkeit und LOS. Cutaway-Darstellung liest gespeicherte Daten, aendert
keine Kollisions-/Navigationswahrheit. Beide Gebaeude besitzen erreichbare
Innenflaechen und Tueren. Zwei benachbarte Pads haben stabile IDs
homebase_pad_01 und homebase_pad_02. Commanderstart, Innenraeume, Terminals,
Pads und Servicepunkt sind zusammenhaengend erreichbar; Waende bleiben gesperrt.

Padbelegung bildet landing_pad_id auf tatsaechliche craft_id ab. Kein statischer
Schiffsprop ersetzt eine reale Belegung. Terminalinteraktion setzt wirkliche
Naehe voraus und oeffnet dieselben Operationsseiten wie die linke Navigation.
Versteckte Erkundung deaktiviert nur ihren lokalen Branch und Viewport.
Keine globale Pause, kein dauerhaft rendernder Zweitviewport bei anderer Seite.

## Minimalhandel und Fuel

Ein langlebiger Supply-State besitzt Credits, item_quantities und
fuel_by_craft_id. SimulationRoot/zugeordneter Runtimeowner bucht atomar.
Genau ein datenbasiertes endliches Kaufangebot mit vorhandener Item-ID und
eine Betankungsaktion. Keine Produktionsketten oder vollstaendige Lagerwirtschaft.
Mengen muessen positiv, bezahlbar und innerhalb Angebot/Fuelkapazitaet sein.
request_id ist verpflichtend; Wiederholung fuehrt keine zweite Buchung aus.
Completionbelohnungen werden je stabiler Abschluss-ID genau einmal verbucht.

Feste datenbasierte Fuelkosten je Ortsverbindung werden genau einmal vor
autorisiertem Abflug gebucht. Ablehnung und wiederholte Requests kosten nichts
zusaetzlich. Unzureichendes Fuel sperrt den Abflug mit Grund. Kein Verbrauch
im UI-/Visualtick. Startwerte erlauben den Test-Rundflug; kein neues
Notfall-/Strandingmodell. Basis und Handelsort lesen denselben Servicezustand.

Pruefung: gespeicherte Topologie hex_axial_v1, Inhalts-/Erreichbarkeitsorakel,
echte Craft-/Pad-ID, Busy/Payloadgates, Negativ- und Wiederholtransaktionen,
zweiter Ausflug. Technische und native Nachweise bleiben getrennt.
