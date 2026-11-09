# Basis, Abflug und Charakterbogen: deutsche, kompakte Orientierung

Stand: 09.11.2026. Zusaetzlicher Nutzerauftrag waehrend der Quantum-Reise-
Umsetzung. Grundlage: `ORBIT_QUANTUM_TRAVEL_2026_11_09.md` auf demselben Taskbranch.
Status: implementiert, echte Flow-/Layout-/Profilregressionen bestanden;
`docs/qa/orbit_quantum_20261109/README.md`. Native Gestaltung noch offen.

## Ziel / Problem und Ursache

Der Nutzer meldet eine leere Schiffsvorschau bei Einsatz/Abflug, einen unklaren
Startweg wegen gesperrter FOB, breite Schaltflaechen im Mobilgeraet sowie viele
englische und schwer erklaerbare Charakterwerte. Besonders die Piloteneignung
ist aus dem bisherigen langen Charakterbogen schwer nachvollziehbar.

Die Pad-Viewport-Wiederverwendung konnte nach einem Ansichtswechsel verborgen
bleiben. Das Mobilgeraet legte alle Buttons in einen expandierenden VBox.
Der Charakterbogen zeigt viele Gruppen gleichzeitig und vermischt Startrolle,
aktuelle Verwendung und berechnete Eignung. Die Startrolle wird vor den Werten
vergeben; Biografie ist kein Beleg fuer eine durch Werte verursachte Berufswahl.

## Umfang / Nicht-Ziele und Ansatz

- Schiff auf realem Pad bzw. im Weltraum aus dem gemeinsamen Owner-Snapshot;
  Vorschau in Trupp/Ausruestung und Abflug, auch bei schmaler Aufloesung.
- Sichtbarer Abflug-Sperrgrund aus autoritativer, nur lesender Bereitschaft;
  kein FOB-Schritt und keine Hoverpflicht. Hinweise ueberdecken keine Aktionen.
- Deutsche Namen und Texte in den betroffenen Basis-/Abflug-/Mobilgeraet-/
  Versorgungs-/Charakteransichten, z.B. Entermesser statt Cutlass; IDs bleiben.
- Mobilgeraet begrenzt die Lesebreite und nutzt kompakte, natuerlich breite
  Aktionen. Keine bildschirmbreiten Einzelbuttons fuer kurze Aktionen.
- Charakterbogen: Startrolle, aktuelle Aufgabe, berechnete Eignung getrennt;
  kurzer Ueberblick, aufklappbare Details, deutsche Eigenschaften/Effekte.
  Piloteneignung erklaert dieselben echten Faktoren wie der bestehende Resolver.

Keine neue Generierung, Wertebalance oder nachtraeglich erfundene Karriere.
Gespeichert sind effektive Werte; historische Vor-Trait-Basiswerte werden nicht
rekonstruiert. Teameditor bleibt editierbar. Interne IDs/Debugtexte/Quellnamen
bleiben stabil. Keine neue Sprachwahl- oder Uebersetzungsinfrastruktur.

## Relevante Dokumente

`docs/PROJECT_BRIEF.md`, `docs/ARCHITECTURE.md`, `docs/CODEX_RULES.md`,
`docs/dev/orbit_quantum_travel_contract.md`, vorhandene Charakter-/Trait-/
Rangabzeichen-/Kontexthilfevertraege und `docs/qa/campaign_intro_20261109/`.

## Akzeptanz

1. Reales ausgewaehltes Schiff/Pad stimmt vor Abflug und nach Landung;
   Weltraumdarstellung stimmt in Orbit, Quantum und nach Abbruch.
2. Abflugvorschau bleibt bei wiederholtem Trupp/Abflug-Wechsel sichtbar.
3. Start sperrt mit sichtbarem Grund bei fehlendem Auftrag/Pilot/Boarding;
   nach Vorbereitung ist der sichtbare Abflug erreichbar, ohne FOB.
4. Hinweisfenster kollidieren bei 1280x720 und 1920x1080 nicht mit Abflugaktionen.
5. Mobilgeraet-Aktionen bleiben kompakt und funktional; keine Textabschneidung.
6. Charakter zeigt getrennte Startrolle/Aufgabe/Eignung. Beispiele mit gleichem
   Rollennamen aber anderen Werten oder anderer Zuweisung bleiben unterscheidbar.
7. Eignungsdetails und bekannte Eigenschaftseffekte sind deutsch und korrekt;
   numerische Scores und Profile bleiben unveraendert. Details sind aufklappbar.
8. Bestehende Editor-/Loadout-/Truppinteraktionen und persoenliche Daten bleiben.

## Betroffene Dateien

`homebase_operations_presenter.gd`, `homebase_screen.gd`,
`campaign_tutorial_presenter.gd`, `singleplayer_job_board_presenter.gd`,
`singleplayer_services_presenter.gd`, `character_sheet_view.gd`,
`character_sheet_formatter.gd`, `npc_rank_badge_resolver.gd`, zugehoerige
Anzeige-/Kontexthilfedaten und gezielte UI-/Profil-/Layoutverifier.

## Lokale Pruefung / Risiken

Gezielte RED/GREEN-Verifier fuer reale Vorschau, Start-Bedienbarkeit,
Mobilgeraet-Rechtecke und echte Charakterprofile; bestehende Flightdeck-,
Charakter-, Badge-/Trait- und Kampagnengates. Headless/private Testprofile;
native Fensteraufnahme der laufenden alten EXE war nicht moeglich (Timeout).
Headless-Layoutpruefungen ersetzen kein subjektives Gestaltungsurteil.
