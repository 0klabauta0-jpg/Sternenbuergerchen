# Dynamische Fahrzeugkollision und verdeckte Bildpruefung

## Ziel und Ursache
Die vorherige Pruefung deckte stationaere Hex-Schiffsmasken und Bettweg-Geometrie ab, aber keine dynamischen Fahrzeugkollisionen oder sichtbare Darstellung. Diese Luecken sollen ohne Desktopuebernahme und ohne sichtbare Spielfenster untersucht werden.

## Umfang und Nicht-Ziele
Produktive Bewegungs- und Kollisionspfade fuer Shuttle, andere Fahrzeuge und Personen in Port Olisar und Heimatbasis pruefen und nachgewiesene Fehler beheben. Verdeckte Renderaufnahmen repräsentativer Zustaende intern untersuchen, sofern technisch moeglich. Keine gestalterische Neuausrichtung, keine Interaktion mit realen Spielstaenden.

## Dokumente
`docs/tasks/CAMPAIGN_COLLISION_VERIFICATION_2026_11_12.md`, `docs/dev/parallel_location_operations_contract.md`, `docs/dev/graphics_reference_revision_contract.md`.

## Akzeptanz und lokale Pruefung
Reproduzierbare Tests unterscheiden dynamische Bewegung von statischer Belegung und benoetigen konkrete Produktionsowner und nichtleere Hindernisse. Bildbelege nennen Renderweg, Kamera und dargestellten Zustand; keine Schlussfolgerung zur 3D-Physik allein aus Bildern. Headless Regressionen fuer Anwerbung, Shuttle und Betten erneut pruefen; nicht abgedeckte Szenarien dokumentieren.

## Betroffene Dateien und Risiken
Je nach Befund Bewegungs-, Kollisions- und Darstellungsowner sowie neue Verifier. Ein Headless-Renderer kann ohne Grafikgeraet nur leere Bilder liefern; kein sichtbares Fenster als Fallback. State bleibt in Simulation und Runtime, nicht im Visual.

## Nutzerkorrektur zur Basisansicht
Das Versorgungsfenster verdeckt die Welt und sein Zweck ist unklar. Es soll auf einen kleinen, beschrifteten und erneut oeffnenden Zugriff reduziert und schliessbar sein; eine knappe Erklaerung nennt Schiffsauswahl, Handel und Tanken. Ungeruestete Personen sollen einen als solchen erkennbaren Undersuit statt einer rein schwarzen Silhouette tragen. Nachweise muessen die echte Darstellung und die Umschaltung von Ausruestung getrennt betrachten.

## Nutzerkorrektur zur Bodendarstellung
Die gezeigte Basisansicht hat wahrgenommene Ueberschneidungen am Landeplatz, Steine mit unpassendem Farbschema, schlecht erkennbare Hexfelder und einen stoerenden dunklen Bodenfleck. Ursachen und Steinschatten anhand verdeckter Aufnahmen untersuchen; korrigierte sichtbare Zustaende und moegliche Grenzen dokumentieren, ohne Desktop oder Eingaben zu uebernehmen.
