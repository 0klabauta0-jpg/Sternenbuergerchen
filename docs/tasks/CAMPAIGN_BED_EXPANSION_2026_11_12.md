# Kampagnen-Bettenausbau

## Nutzerkorrektur: Unterkuenfte statt Feldbetten
Zusaetzliche Betten entstehen in weiteren Unterkunftsgebaeuden. Ein Gebaeude wird getrennt gekauft; anschliessend koennen Betten darin gebaut werden. Alte bezahlte Betten muessen ohne erneute Zahlung in gebaute Unterkuenfte ueberfuehrt werden. Keine zusaetzlichen Feldbetten im Freien. Gebaeudekapazitaet, Navigation, Darstellung, Kaufbelege und Continue muessen uebereinstimmen; Preise sind vorlaeufig. Die bisherige Beschreibung des Feldbett-Anbaus ist ueberholt.

## Nutzerkorrektur 12.11. – Unterkunft statt Feldbetten
Zusaetzliche Betten gehoeren wie die ersten in Unterkunftsgebaeude. Ein weiteres Unterkunftsgebaeude wird gebaut; darin koennen Betten eingerichtet werden. Draussen aufgestellte Feldbetten erfuellen diese Anforderung nicht. Die bisherigen Angaben zum Feldbett-Ausbau unten beschreiben den ersetzten Zwischenstand, nicht das aktuelle Ziel. Kampagnenkapazitaet, Kosten, echte Zugaenglichkeit und vorhandene Spielstaende muessen nach der Umstellung weiterhin konsistent sein.

## Ziel und Ursache
In der Heimatbasis benutzbare Schlafplaetze gegen Credits schaffen, damit angeworbenes Personal eine echte gebaute Schlafgelegenheit erhaelt. Unbezahlte automatisch nach Rosterzahl entstandene Feldbetten zaehlen bewusst nicht als gebaute Kapazitaet.

## Umfang / Grenzen
- Ein lokaler Bau-Command pro Unterkunft ueber den bestehenden Supply-/SimulationRoot-Pfad; vorlaeufig 500 Credits fuer ein Gebaeude mit zwei Originalbetten, maximal 20 gebaute Betten.
- Nur tatsaechlich begehbar platzierte Betten werden gebucht. Keine zusaetzlichen parallelen UI-/Gameplayowner; Skirmish-Verhalten bleibt unveraendert.
- Autoritative Kaufbelege bestimmen die gebaute Kapazitaet nach Save/Continue. Alte Basischeckpoints bleiben lesbar.
- Basis-Baumenue zeigt Unterkunftspreis, enthaltene Betten, Kapazitaet, Verfuegbarkeit und Rueckmeldung.

## Contracts
`docs/dev/base_automatic_rest_contract.md`, `docs/dev/campaign_introduction_contract.md`, `docs/dev/parallel_location_operations_contract.md`, `docs/tasks/CAMPAIGN_HELP_RECRUITMENT_2026_11_12.md`.

## Akzeptanz und Pruefung
Mindestens eine echte zusaetzliche Unterkunft mit erreichbaren Bettpositionen, korrekte Kosten und einmalige Request-ID, Ablehnung ohne Guthaben / Platz / lokalen Owner ohne Teilmutation, warnungsrelevante Kapazitaet und NPC-Schlaf, reproduzierbarer Export/Restore, alte Checkpoints und Skirmish unveraendert. Gezielt Godot-Domain- und UI-/Checkpointverifier ausfuehren; native Sichtpruefung separat.

## Betroffene Dateien / Risiken
Supply-State/Command-Contract, Runtime-Adapter, BasePersonnelRuntime/BaseCapacityLayout, Basisservice und Checkpointtests. Bestehende automatische Feldbetten duerfen nicht ohne Kauf als gebaut gelten. Terrain/Navigation koennen die Kapazitaet begrenzen; diese Grenze muss sichtbar bleiben.

## Umsetzung der Nutzerkorrektur
Die Kampagne nutzt keine zusaetzlichen Feldbetten mehr. Eine Unterkunft kostet vorlaeufig 500 Credits und enthaelt zwei Betten, weil das originale Habitatmodell die Betten fest mit der uebrigen Geometrie verbindet. Dadurch sind sie identisch zu den ersten Betten; ein separat darstellbarer Einzelbettkauf ist mit diesem Modell nicht belegt. Bis zu neun zusaetzliche Unterkuenfte ergeben 20 Schlafplaetze. Ein alter bezahlter Einzelbettbeleg wird ohne Nachzahlung in eine passende Unterkunft ueberfuehrt; bei einer ungeraden alten Anzahl ist der zweite sichtbare Platz ebenfalls enthalten. Die historischen internen Bett-IDs bleiben fuer gespeicherte Personen erhalten.

Headless wurden Kauf, einmalige Abbuchung, alle neun Bauplaetze, tatsaechlicher Weg und Schlaf, Save/Continue und ein synthetischer alter Spielstand mit schlafender Person geprueft. Ein Kapsel-Sweep zur ersten Unterkunft prueft die Wege zu beiden Betten gegen die importierten Gebaeudemodelle. Weitere Sicht- und Kollisionspruefungen sind separat dokumentiert; Kosten sind noch nicht balanciert.

## Geometrie und Bewegung 12.11.
Der unabhaengige Headless-Physiktest laedt die tatsaechlichen Habitat-, Werkhallen- und Tankanlagen-GLB und bildet die dargestellten Feldbetten als Boxen mit denselben Massen nach. Urspruenglich lagen die Anlaufpunkte in den Betten, und alle 18 Zusatzbettwege kreuzten Bettboxen. Die Bettdarstellung ist vom unveraenderten Bettziel abgerueckt; BaseInteriorNavigation sperrt lokal die um die Betten erweiterten Graphpunkte. Laufende Wege und durch Personen belegte Baustellen verhindern den Kauf. Bei einem durch Feldbetten versperrten Spawn wird ein naher freier Graphpunkt verwendet. Die bestehende Terrainregistry und ihre Overrides bleiben unberuehrt. Fuer zukuenftige Karten mit eigener Hex-Bodennavigation ist Bettbau gesperrt, bis deren Hindernisse entsprechend angebunden sind; die regulaere Kampagnenkarte verwendet diesen Hex-Pfad nicht.

`campaign_bed_actual_geometry_verifier.gd` prueft den schrittweisen Ausbau auf 20, Boxen gegen die drei importierten Modelle sowie Kapsel-Sweeps der Wege vom freien Spawn und zwischen allen Feldbettzielen. `campaign_bed_real_movement_verifier.gd` startet die echte Kampagnenszene und prueft bezahlten Bau, Bewegung und Schlaf, Checkpoint/Continue sowie den spaeteren Weg einer zweiten Person. Der geometrische Test verwendet die exakten Feldbett-Boxmasse und einen Charakter-Kapselproxy; er prueft keine sichtbare Darstellung und keine beliebigen Missions- oder dynamischen Fahrzeugkollisionen.
