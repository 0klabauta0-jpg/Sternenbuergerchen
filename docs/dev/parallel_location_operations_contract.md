# Parallele Ortsoperationen: Ansicht, Zugriff und Laufzeit

## Wahrheit / Identitaet
LocationRuntimeRegistry haelt die bestehenden Ortsinstanzen. Jeder lebende Ort
behaelt seinen eigenen Root-/Registry-/Actor-/Befehls-/Fortschrittszustand.
Ein Ort hat eine fachliche location_id; die Laufzeitinstanzidentitaet gilt fuer
die aktuelle Sitzung und ist kein implizites neues Spielstandsformat.

## Ansichtswechsel
open_location_view(location_id, craft_id='') wechselt nur Projektion und
Eingabefokus. Es startet keine Reise und konfiguriert, stoppt, belegt oder
loescht keinen Gameplayowner. Heimat ansehen ist auch waehrend fremder Fluege
moeglich. Bestehende Abflug-/Boarding-/Transportgates bleiben erhalten.
Verdeckte registrierte Ortsroots und taktische Ausfuehrung prozessieren weiter;
nur Kamera, View, Input und unnoetiges Rendering duerfen deaktiviert werden.

get_location_view_snapshot() ist eine reine Projektion von view/location_id/
craft_id. Serviceschiffwahl ist expliziter UI-Zustand mit gepruefter realer
Ortszuordnung; sie aendert weder Reisefokus noch Missionsidentitaet. Bei
mehreren Schiffen kein stiller erster/alter/andererCraft-Fallback. Eine
unzweideutige Einzelwahl darf beim ausdruecklichen Ort-Oeffnen initialisiert
werden, nicht als Mutation eines Snapshotgetters.

## Ereignisse und Hintergrund
Hintergrundankunft, Abflug oder Ortscallback darf eine fremde betrachtete
Mission nicht uebernehmen. Bestehender Reisefokus darf einer Ankunft nur bei
bewusst betrachteter Sternkartenreise desselben Schiffs folgen. Callback-
Kontext wird fuer den echten Ort gesetzt und danach vollstaendig restauriert.
Zeitursprung und Zeitlimit stammen vom jeweiligen bestehenden CombatLoopDriver;
kein neuer UI-Tick oder Missiontimer. Echte Missionsabbrueche, Retire-/Boarding-
regeln und Ortsteardown sind von blossen Viewwechseln getrennt.

## Lokale Aktionen
Sichtbarkeit allein ist keine Zugangsberechtigung. Werkstattaktionen brauchen
lebenden gebundenen Basisowner und gebaute Einrichtung; fremde Schiffe duerfen
diese Basisfunktion nicht global sperren. Materialien ausschliesslich aus dem
Basislager. Upload nur nach tatsaechlichem lokalen Container-/Personen-/
Heimatschiffbeleg, kein Griff in ferne Questfracht. Andere Aktionen behalten
ihre konkreten Job-, Crew-, Reisefasen- und Zugangsgates.

Polisa zeigt nur real anwesende Schiffe dieses Orts, der Benutzer waehlt das
Serviceschiff. Jede Mutation prueft erneut echten Service-/Park-/Pendingzustand.
Optionaler service_location_id-Intent bindet einen Klick an den angezeigten
Ort; ist das Schiff inzwischen woanders, keine Umleitung auf andere Dienste.
Supply bleibt Inventar-/Creditowner; UI speichert nur Auswahl und Feedback.

## Grenzen / Nachweis
Erster Slice nutzt vorhandene Reise-/Nachschick-/Ortsaufnahme- und Shopbefehle.
Keine automatische Einkaufs-KI, keine gelockerten Pilot-/Crew-/Transportregeln.
Ein spezifischer Rueckhol-Faehrbetrieb mit an Land zurueckgelassener zugewiesener
Crew waere ein eigener Transportvertrag, keine Navigationsnebenwirkung.
Checkpoint bleibt derzeit heimatgebunden; Ortswechsel ist keine Zusage fuer
unterwegs Speichern. Allgemeines BasePad-/waiting_pad-Handoff wird nicht durch
pauschale Lockerung des AllHomegates vorweggenommen.

Kleine Zwei-Orte-/Zwei-Schiffe-Proben und Sourceaudit sichern den begrenzten
Vertrag. Der echte Gesamtweg mit Hintergrundgefecht, Handel, Transport,
Save/Continue und Framezeit bleibt zur spaeteren grossen Abnahme.
