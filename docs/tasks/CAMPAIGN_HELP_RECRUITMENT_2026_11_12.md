# Kampagnenhilfe und Anwerbung auf Polisa

## Ziel und Anlass
Die optionale Kampagnenhilfe erklaert Bedienelemente und den Zusammenhang von Kauf, Frachtaufzug, Ausruestung, Boarding und Einsatz. Im Globusraum auf Polisa koennen eigene Personen teures Personal anwerben und vor der Entscheidung vergleichen.

## Umfang und Akzeptanz
- Hilfe verwendet den vorhandenen Katalog und die Hilfeeinstellung. Aus bedeutet keine kontextbezogenen Hilfe-Popups. Texte beschreiben den tatsaechlichen Ablauf.
- Ein Anwerber-Button am Globus bietet drei bis vier unterschiedliche Kandidaten; die Eignung des interagierenden eigenen NPC beeinflusst deren Qualitaet und Spezialisierung. Karten zeigen Preis und relevante Werte; Charakterboegen sind oeffenbar und mehrere Kandidaten vergleichbar.
- Credits werden genau einmal autoritativ gebucht; veraltete Angebote, fehlende Credits oder fehlender lokaler Akteur erzeugen keine Teilmutation. Angebot und Personal bleiben bei einem gueltigen Kampagnencheckpoint erhalten.
- Warnung bei unzureichender gebauter Bettenkapazitaet; die Warnung verhindert die Anwerbung nicht. Automatisch ergaenzte Betten duerfen keinen nicht existierenden Ausbau suggerieren.
- Bei vorhandenem eigenem Schiff auf Polisa bleibt die angeworbene Person zunaechst dort und kann ausgeruestet werden. Ohne solches Schiff reist sie bei Verlassen des Orts automatisch per fremder Cutlass mit Stationspilot zur Basis. Ankunft und Reise brauchen reale Laufzeit und sind auf der Karte beobachtbar.
- Ohne Bett wartet die Person am Schlafgebaeude. Wenn sie binnen fuenf Minuten weder eine Aufgabe noch ein Bett hat, reist sie nach Polisa zurueck; mit Bett und vorhandener Ruhelogik wird sie wie anderes Personal behandelt.

## Grenzen und bestehende Vertraege
`campaign_introduction_contract.md`, `contextual_help_popup_ux_contract.md`, `parallel_location_operations_contract.md`, `orbit_quantum_travel_contract.md`, `base_automatic_rest_contract.md`, `player_roster_save_contract.md`. Gameplay-Wahrheit bleibt bei den jeweiligen Runtime- und Simulationsownern; UI zeigt Projektionen und sendet Commands. Kein Teleport statt Flug und keine UI-seitige Wirtschafts- oder Personalwahrheit.

## Betroffene Bereiche und lokale Pruefung
Kampagnenhilfe und Hilfekatalog; Stationsinteraktion und Charakteransicht; Kampagnen-, Supply-, Personal-, Reise- und Checkpointowner; gezielte Godot-Verifier fuer Angebot, Bezahlung, Speicher/Restore, Betten und Shuttleablauf sowie gerenderter Spielpfad. Altstaende und bestehende Missions-Rekruten regressionspruefen.

## Risiken und offene Punkte
Der urspruengliche Checkpoint akzeptierte maximal vier Personen und nur sichere Basisstaende; die erweiterte Grenze verlangt Belege und ausdrueckliche Ortszuordnung. Aktive Shuttlefahrten sperren weiterhin den Basischeckpoint. Der bisherige unbezahlte Basismodus erweitert Betten nach Rosterzahl; die Rekruten-Ruhe prueft deshalb echte gebaute Kapazitaet. Shuttlepilot ist kein Spielerpersonal; Rueckreise und Aufgabe muessen ohne doppelte Personen oder Kosten erfolgen. Balance und Flugzeit sind vorlaeufig.

## Implementierungsstand 12.11.
Die Globusinteraktion prueft ausgewaehlte, lebende lokale Hex-Person und Platz am Globus. Die Anwerbungsansicht zeigt fähigkeitsabhängige Karten, Charakterboegen, Vergleich, Preise und gebaute Bettenkapazitaet. Der Supply-Owner reserviert Credits einmalig; die abschliessende Buchung setzt den echten lokalen Actor und die bestaetigte Besuchs-Crew voraus. Ein pending Auftrag sperrt die Abreise seines Schiffs und sichere Basischeckpoints. Sichere Abwesenheitsbelege erlauben Erstattung, bei fortbestehendem Roster wird nicht still erstattet.

Sichere Basischeckpoints akzeptieren mehr als vier Personen mit validierten Anwerbungsbelegen und speichern den regenerierbar validierten Angebotsmarkt. Alte Checkpoints ohne dieses optionale Feld bleiben lesbar. `polisa_recruit_integration_verifier.gd` belegt die Registry-/Hex-Aufnahme, Einmalzahlung, Pending-Wiederholung, entfernte Basisidentitaet, Inventarzugriff und die Erstattungsgrenze mit Fixture-Crew; `polisa_recruit_ui_wiring_verifier.gd` prueft Globussignal und UI-Befehlsfluss. Beide sind keine native Gesamtspielabnahme.

Der Shuttle-Dispatcher nutzt Stationspilot, echte Hex-Wege, Boarding- und Abflugbelege und einen separaten Reiseowner. Das Heimatpad wird reserviert, die An-/Abflugprojektion liest einen zeitlichen Owner, und die Basisaufnahme verwendet einen vorbereiteten Hex-/Shuttle-Handoff. Nach fuenf Minuten ohne gebaute Bettzuweisung oder Aufgabe werden echtes Rueckboarding und Rueckflug angefordert. Mehrere wartende Rekruten werden sequenziell behandelt; das eigene Schiff wartet waehrenddessen. Sichere Basischeckpoints speichern auch Stationspersonal; waehrend laufender Shuttlefahrten bleiben sie gesperrt.

Der kombinierte Headless-Verifier `polisa_shuttle_full_loop_verifier.gd` prueft Personenaufnahme, Hinflug, Heimatlandung, 300 simulierte Sekunden ohne Bett oder Aufgabe, Rueckflug und Stationsausstieg (18/0). Er verwendet echte Laufzeit- und Bewegungsowner, aber kuenstliche Hexfelder, Padpositionen und eine leere Schiffshindernismaske. Die reale Stationskarte und die produktive Cutlass-Hexmaske werden separat geprueft; sichtbare Darstellung und polygonale Kollision sind nicht abgenommen. Ein Abbruch nach begonnenem Boarding oder Takeoff ist nicht allgemein belegt.

Der aktuelle Kampagnenausbau kostet vorlaeufig 500 Credits je Unterkunft mit zwei im Originalmodell enthaltenen Betten und erlaubt bis zu 20 Schlafplaetze; Einzelbettplatzierung und modulare Raeume sind ein separater offener Auftrag. Alte Einzelbettzahlungen werden ohne Nachzahlung migriert. Kauf, Platzmangel, Wiederholung und Save/Restore wurden headless geprueft. Weitere Pruefungen und Grenzen stehen in `CAMPAIGN_COLLISION_VERIFICATION_2026_11_12.md` und `CAMPAIGN_MODULAR_BASE_ROOMS_2026_11_12.md`. Die anderen Polisa-Handoff-Dateien beschreiben den Ausgangszustand und sind kein aktueller Fertigstellungsnachweis. Der aeltere Sternkarten- und der alte Drei-Etappen-Onboardingverifier zeigen auf dem Ausgangsstand reproduzierte Fehler; der allgemeine Hilfekatalog-Verifier meldet fuenf vorbestehende Textlaengenbefunde.
