# Heimatbasis: Karte, Pads und Services

Stand: 09.11.2026. Zielvertrag fuer AP3/AP5/AP7; native Abnahme ist gesondert.

Nutzerkorrektur nach dem Kampagnen-Playtest: Die Heimatbasis bleibt36x28 gross,
auch bei kleinem Startpersonal. Beide moeblierten Original-Cutaway-GLBs werden
wieder sichtbar eingesetzt; kahle Ersatzwaende sind kein freigegebener
Basisstil. Vereinfachungen fuer den Handelsposten gelten nur dort. Die
gespeicherten Navigationsfakten bleiben getrennt vom sichtbaren Mesh; ein
Pathfinder-PASS belegt keine native Passung von Tueren/Moebeln und Laufwegen.

TerrainMapData/TerrainRegistry besitzen Hexfelder, Boeden, Tueren, Aussenwaende,
Begehbarkeit und LOS. Cutaway-Darstellung liest gespeicherte Daten, aendert
keine Kollisions-/Navigationswahrheit. Beide Gebaeude besitzen erreichbare
Innenflaechen und Tueren. Zwei benachbarte Pads haben stabile IDs
homebase_pad_01 und homebase_pad_02. Commanderstart, Innenraeume, Terminals,
Pads und Servicepunkt sind zusammenhaengend erreichbar; Waende bleiben gesperrt.

Fuer die beiden eingerichteten Basisgebaeude gibt es gesonderte statische,
feinere Laufdaten bei unveraenderter physischer Kartenausdehnung. Das grobe
Kartenraster darf keine schmalen Tueren oder Moebelgaenge verdeckt ersetzen.
Unabhaengige Mesh-/Koerperabstandschecks pruefen die realen sichtbaren Modelle,
zusaetzlich zur Simulationsbewegung. Im Runtime-Hotpath gibt es keine Meshsuche.

Padbelegung bildet landing_pad_id auf tatsaechliche craft_id ab. Kein statischer
Schiffsprop ersetzt eine reale Belegung. Terminalinteraktion setzt wirkliche
Naehe voraus und oeffnet dieselben Operationsseiten wie die linke Navigation.
Versteckte Erkundung deaktiviert nur ihren lokalen Branch und Viewport.
Keine globale Pause, kein dauerhaft rendernder Zweitviewport bei anderer Seite.

In der Kampagne besitzt ein SimulationRoot-gebundener Basisowner Positionen und
laufende Basisaktionen der beiden echten Roster-IDs. Die Ansicht projiziert sie;
Ansichtwechsel stoppen ihre angeforderten Wege nicht. Auswahl per Figur oder
Personenliste umfasst auch Besatzung an Bord. Ein-/Aussteigen und Ausruestung
verwenden denselben bestehenden Operations-/Transport-/Loadoutpfad wie das
Menue. Pilotenplatzzuweisung und physische Anwesenheit sind getrennte Fakten.

Ein entfernter Terminalklick kann einen Weg zum passenden Bedienpunkt
anfordern. Erst nach bestaetigter Ankunft oeffnet die vorhandene Ansicht einmal.
Beim blossen Vorbeigehen wird nur die Interaktionsmoeglichkeit angeboten.
Originalmonitore/Arbeitstische werden genutzt; keine zusaetzlichen Standkonsolen
ueberschneiden Waende oder Moebel.

Schlafen reserviert ein freies Bett, fuehrt die Person zu dessen Zugang und
legt sie erst nach Ankunft hin. Aufwecken und Abbrechen geben die Reservierung
frei. Es gibt in dieser Fassung keine neue Heilungs-/Muedigkeitsbalance;
medizinischer Recovery-State bleibt beim bisherigen Owner.

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

Vor dem Abflug muss Fuel fuer die feste Hin- und Rueckstrecke vorhanden sein.
Die reine Vorpruefung reserviert dies als Mindestbudget, bucht aber weiterhin
nur die jeweilige tatsaechliche Strecke einmal ab. Zu wenig Rueckflugbudget
lehnt vor jeder Flug-/Auftragsmutation ab. Ein unerwartet abgelehnter Rueckflug
darf die einzige aktive Missionsinstanz nicht verwerfen.

Pruefung: gespeicherte Topologie hex_axial_v1, Inhalts-/Erreichbarkeitsorakel,
echte Craft-/Pad-ID, Busy/Payloadgates, Negativ- und Wiederholtransaktionen,
zweiter Ausflug. Technische und native Nachweise bleiben getrennt.
