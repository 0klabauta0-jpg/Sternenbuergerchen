# Historische Crewideen für den Neustart

Aktualisierung nach Umsetzung am 13.09.2026: Die erste Crewakte zeigt inzwischen bestätigte Fähigkeiten, Aufgabe und Ausrüstung. Die folgende historische Bestandsaufnahme unterscheidet weiterhin diese ersten Profile von den umfassenderen späteren Crew- und Persönlichkeitssystemen.

Stand: 13.09.2026. Gezielter Quellenabgleich für den Gesamtplan; keine Zusage, dass alte Systeme bereits im Neustart laufen. Die bestätigten Nutzerentscheidungen im Neustartplan haben Vorrang vor historischen Konzepten. Insbesondere beginnt die neue Karriere mit Ida und Jaro; der alte Startkader von 20–30 NPCs ist kein neues Startziel.

## Quellen

Die folgenden tatsächlich vorhandenen Dateien liegen unter `C:/dev/SternenBuergerchen-worktrees/task-neustart-vision-2026-09-12/`:

- **Q1:** `docs/tasks/TASK_235_character_sheet_roster_gameplay_expansion.md`, insbesondere Zeilen 19–39 und 55–57: Charakterbogen, Status/Genesung, Beziehungen, Team- und Missionsgeschichte.
- **Q2:** `docs/content/character_sheet_loadout_help_copy.md`, Zeilen 6–37 und 62: konkrete Charakterbogenbereiche und acht Kernwerte; Darstellung liest die Profildaten.
- **Q3:** `docs/dev/character_roster_generation_contract.md`, Zeilen 18–44: Identität, Rollenmischung, Fähigkeiten, Traits, höchstens drei abgeleitete Rangabzeichen und bewusst nicht perfekte Teamvorschläge.
- **Q4:** `docs/tasks/TASK_236_fireteam_relationship_affinity_and_cohesion.md`, Zeilen 19–35: persönliche Affinität, Bindungen, Spannungen und kleine Auswirkungen auf Zusammenarbeit.
- **Q5:** `docs/tasks/TASK_237_mission_progression_xp_morale_frustration.md`, Zeilen 19–43 und 58–62: Lernen aus tatsächlichem Einsatz, begrenzte Fortschritte, Moral/Frust, Genesung und persistente Geschichte.
- **Q6:** `docs/tasks/TASK_238_personnel_events_recruit_leave_dismiss_notifications.md`, Zeilen 17–45: Bewerber, Rückkehr, Versetzungswunsch und weitere historische Personalereignisse.
- **Q7:** `docs/dev/fireteam_leader_tactical_progression.md`, Zeilen 30–72: Führungskompetenzen, begrenzte Laufzeitwirkung, Wachstum aus echten Führungssituationen.
- **Q8:** `docs/superpowers/plans/2026-09-12-sternenbuergerchen-neustart.md`, Zeilen 25–44, 139–159: ursprünglicher kleiner Aufbau, aktuelle Nutzerentscheidungen und neue Etappen für Wachstum/Forschung/Raumarbeit.

Die historischen Task-Dateien dokumentieren zum Teil damalige Implementierung und Tests. Das ist kein aktueller Laufnachweis im neuen Projekt. `docs/GDD_STATUS.md` desselben Worktrees ordnet den alten DOCX-GDD als Inspirations- und Migrationsquelle ein.

## Zwölf konkrete Spielideen

| Idee | Übernahme in den neuen Spielkreis | Einordnung |
|---|---|---|
| 1. Ein persönlicher Charakterbogen | Porträt, Name, Rolle, Fähigkeiten, Traits, aktuelle Aufgabe, Verfügbarkeit, Genesung, Teamfit und Missionsgeschichte erklären, wer diese Person ist. Kompakte Übersicht; Details erst beim Öffnen. | Historisch ausgearbeitet, im Neustart noch zu bauen. Q1/Q2. |
| 2. Lesbare Stärken und Schwächen | Alte Kernwerte: Präzision, Tempo, Zähigkeit, Aufmerksamkeit, Erkennung, Heimlichkeit, Disziplin und Führung. Ergänzend Technik, Medizin, Pilotieren und Kommunikation nach tatsächlichen Tätigkeiten. Für den Neustart wenige wirksame Werte auswählen, ohne den alten Bogen blind zu kopieren. | N1 hat nur einen Technikwert; weitere Werte Zukunft. Q2/Q3. |
| 3. Rollen und Traits ergeben geeignete Aufgaben | Techniker, Pilot, Sanitäter, Schütze, Scout und Leiter bringen unterschiedliche Eignung mit. Kandidaten und Teamvorschläge haben echte Lücken; kleine Traits prägen Verhalten. Abgeleitete Rollenabzeichen statt einer zweiten Rangrechnung. | N1 prüft technische Eignung an der Werkbank. Rollentiefe/Traits fehlen. Q1/Q3. |
| 4. Können wächst durch tatsächliche Arbeit | Bergung, Technik, Heilung, Zielbeiträge und später Führung geben kleine, begrenzte Fortschritte in der verwendeten Fähigkeit. Ein unbeteiligter NPC bekommt nicht dieselbe Lernkurve wie der tatsächlich eingesetzte. | Historisch konkret, im Neustart noch kein XP-/Lernsystem. Q5/Q7. |
| 5. Erfahrene Crew braucht weniger Einzelbefehle | Neulinge benötigen konkrete Wegpunkte und Scanaufträge; erfahrene Spezialisten können einen begrenzten Such-/Arbeitsbereich abarbeiten. Führung verbessert Kommunikation, Reaktion und Zusammenarbeit nachvollziehbar. | Im Neustartplan ausdrücklich vorgesehen, vor allem ab Raumberufen. Kein schon vorhandenes autonomes Team. Q7/Q8. |
| 6. Gemeinsam erlebte Missionen bleiben sichtbar | Kurze Missionsgeschichte und zwei bis fünf relevante persönliche Debrief-Meldungen: gelernt, gut zusammengearbeitet, verwundet, neue Spezialisierung. Das verbindet die wachsende Organisation mit bekannten Figuren. | Historischer Vorschlag für die neue Progression; N1 hat nur allgemeine Ereignismeldungen. Q1/Q5. |
| 7. Teamfit macht Zusammenstellung interessant | Kleine Bindungen wie Vertrauen, Mentor, Rivalität oder Spannung; eingespielte Gruppen koordinieren sich etwas besser. Bogen zeigt beste Bindung und größte Spannung verständlich. | Historisch ausgearbeitet; Übernahmeentscheidung und Balance noch offen. Kein Dating-/Dialogsystem vorausgesetzt. Q4. |
| 8. Moral und Frust haben erkennbare Gründe | Passende Aufgabe, Erfolg und gutes Team können helfen; dauernde Reserve, Überlastung, Verletzung und unpassende Rolle können frustrieren. Veränderungen erklären und begrenzen. | Historische Idee, kein aktueller Neustartwert. Q5. |
| 9. Verwundung führt zu Betreuung und Rücktransport | Verletzte fallen zeitweise aus, werden evakuiert und erholen sich; nach bestätigter neuer Regel kein dauerhafter Tod durch Kampf. Verzögerter Respawn und erneuter Transport schaffen Konsequenzen ohne Figurenverlust. | Nutzerbestätigt für N2; Ort, Dauer, Ausrüstung und Kosten konkretisieren. Q1/Q5/Q8, Plan Zeilen 39/51/132. |
| 10. Neue Bewerber folgen sichtbarem Wachstum | Erfolge/Ruf ziehen Bewerber an. Vor Aufnahme Fähigkeiten und Aufgaben zeigen; Schlafplätze begrenzen die Mannschaft. Wachstum von zwei auf etwa vier/sechs ist ein Balancevorschlag, kein starrer Endkader. | Im bestätigten Gesamtplan N3. N1 hat feste zwei Personen und zwei Betten. Q6/Q8, Plan Zeilen 141–150. |
| 11. Blueprint, Basis und Menschen bilden einen Fortschrittskreis | Fund aus Mission → Bauplan/Forschung → passende Maschine/Raum → geeigneter Arbeiter vor Ort → Material, Geld und Arbeitszeit → Ausrüstung für den nächsten Einsatz. Räume müssen echte Möglichkeiten freischalten. | N1 besitzt bereits die kleine Version aus Blueprint, Werkbank, Technikprüfung und Produktion. Forschung, Raum-/Maschinenbau folgen N3. Q8, Plan Zeilen 37/41/110/144–150. |
| 12. Personalentwicklung verändert Organisation und Einsatzplanung | Seltene Rückkehr-/Verfügbarkeits- oder Versetzungsnachrichten können Bedürfnisse sichtbar machen. Erfahrenere Crew kostet nach Nutzerwunsch mehr PvP-Punkte, sodass Fortschritt auch eine bewusste Auswahl bleibt. | Fähigkeiten im Punktebudget bestätigt, Formel offen. Kündigung, Entlassung oder dauerhafte Abgänge sind nur historische Ideen und ausdrücklich keine beschlossene Neustartregel. Q6/Q8, Plan Zeilen 39/53/134. |

## Tatsächlicher Neustartstand

Aktuell lokal abgeglichen mit `C:/dev/SternenBuergerchen-Neustart/docs/IMPLEMENTATION_STATUS.md`, `scripts/core/simulation_root.gd` und `scripts/core/catalog.gd`: Ida besitzt Technik 3, Jaro Technik 1; Aufträge prüfen Eignung und Verfügbarkeit. Arbeit bindet die Person und verbraucht reservierte Materialien. Die Satellitenabgabe vergibt einmalig Geld und den Schneider-Bauplan. Herstellung/Reparatur, Cargo/Markt, Pause, Save sowie der feste Koop-Platz sind vorhanden.

Nicht als geliefert darstellen: ausführliche Charakterbögen, Traits, Lernen/XP, soziale Beziehungen, Moral/Frust, Rekrutierung, Verwundung/Genesung/Respawn, Forschung oder baubare Räume. Die historische Charaktertiefe gehört als konkret beschriebene spätere Entwicklung in den Gesamtplan; sie wurde nicht durch das kleine N1-Technikfeld bereits umgesetzt.
