# Automatische Basisruhe und manuelle Kontrolle

Nutzerkorrektur 10.11.2026. BasePersonnelRuntime bleibt Absichts-/Positionsowner,
SimulationRoot fuehrt Wege aus. Nach 20 Sekunden ohne Basisauftrag sucht eine
Person mit aktiviertem Auto-Ruhen ein freies Bett und geht tatsaechlich dorthin.
Reservierungen benutzen den vorhandenen Bettowner; kein Teleport und keine
doppelte Belegung. Unterwegs, Boarding, an Bord oder auswaerts schlafen nicht.

Manuelle Befehle brechen automatischen Bettweg/Schlaf ab und setzen eine
30-Sekunden-Prioritaetsfrist. Ein ungültiger Befehl soll keine Reservierung
zerstoeren. Das auswaehlbare Kontrollkaestchen `Automatisch ruhen` gilt pro NPC;
ausgeschaltet steht die Person nach ihrem manuellen Auftrag dauerhaft still.
Abschalten bricht automatisches Ruhen ab. Explizites `Schlafen` und `Aufwecken`
bleiben unabhaengige Aktionen. NPC-Auswahl, Menue, Ausruestung und Einsteigen
bleiben verfuegbar. Der Schalter wird im vorhandenen Basischeckpoint gespeichert;
alte Checkpoints ohne dieses Feld erhalten den Standard an.

Fuer einzelne Personen ist der tatsaechliche Aufenthaltsort massgeblich. Andere
auswaerts befindliche Schiffe sperren weder freie Personen noch ihre Ruhe an der
Basis. Die existierende Ausgangskampagne behaelt exakt ihre zwei Personen.

BasePersonnelActor besitzt derzeit keine Verbrauchs-/Fatigue-/Healthwahrheit.
Darum wird kein erfundener `voll erholt`-Wert angezeigt oder neue medizinische
Wirkung durch Schlaf vergeben. Eine spaetere Anbindung benutzt deren echten
medizinischen/Beduerfnisowner.

Akzeptanz: zwei reservierte unterschiedliche Betten, tatsaechlicher Gang/Schlaf,
manuelles Aufwecken und Bewegung, Schalter aus verhindert neuen Bettweg,
Schalterzustand ueber Save/Continue, Bedienung ueber NPC und Operationsmenue.

Hexkandidat: Basisabsichten und Bettvormerkung bleiben hier; physische Belegung
und Bewegung liegen beim gemeinsamen Root/Ground. Ein eigener an den echten
Basisowner gebundener Zugang erlaubt Baseactors ohne taktische Commandmethoden.
Erst tokenisierte tatsächliche Rootankunft beendet den Bettweg. Abbruch oder
statisch gescheiterte Navigation geben Aktion und Bettvormerkung frei; vorläufiges
Warten hinter belegten Feldern bleibt ein laufender Weg. Ein freier Renderstand
ist kein Ankunftsbeleg. Produktionsbasiskarten sind noch nicht aktiviert.
