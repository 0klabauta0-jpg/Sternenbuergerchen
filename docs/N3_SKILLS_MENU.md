# Hauptmenü und tatsächliche Charakterwirkung

13.09.2026. Der frühere Charakterbogen wurde erneut am intakten historischen Worktree geprüft: `C:/dev/SternenBuergerchen-worktrees/task-current-status-html-2026-08-25/scripts/meta/character_sheet_view.gd`. Seine Darstellungsgruppen umfassen Profil, Ausrüstung, Traits, Werte/Budgets, Plattformfähigkeiten und Beziehungen. Die Quellenliste und zwölf übernommenen Entwicklungsziele stehen in `docs/HISTORICAL_CREW_IDEAS.md`. Der neue Kern importiert diese alten Systeme nicht pauschal.

## Aktuell wirksame Werte

| Wert | Tatsächliche Wirkung | Ida | Jaro |
|---|---|---:|---:|
| Technik | Mindestwert für Rezepte; Abbau-/Bergezeit geteilt durch `1 + 0,1 × Technik` | 3; Zeitfaktor 0,77 | 1; Zeitfaktor 0,91 |
| Pilotieren | Geschwindigkeit im lokalen und Raumflug mal `1 + 0,04 × Pilot` | 3; +12 % | 1; +4 % bei Piloteneinsatz |
| Geschützkenntnis | Bodentreffer `10 + 2 × Wert`; Turmtreffer `7 + Wert` | 1; 12 / 8 Schaden | 3; 16 / 10 Schaden |
| Werkzeugkit | Abbau-/Bergetempo zusätzlich mal 1,2 | Nur ausgerüstetes Werkzeug zählt | Nur ausgerüstetes Werkzeug zählt |
| Schneider | Abbau-/Bergetempo zusätzlich mal 1,35 | Alternative zum Kit, kein Stapeln | Alternative zum Kit, kein Stapeln |
| Schutzrüstung | 35 % weniger eingehender Bodenschaden | Eigener Inventargegenstand | Eigener Inventargegenstand |
| Aufgearbeiteter Helm | Weitere 5 % Schutz, zusammen maximal 40 % | Basishelm hat diesen Bonus nicht | Basishelm hat diesen Bonus nicht |

Bordrollen sind in dieser Stufe fest: Ida fliegt, Jaro bedient den Turm. Die Crewakte nennt die Fähigkeit jedes Menschen; ein derzeit nicht verwendeter Bordrollenwert ist kein zusätzlicher passiver Bonus. Technik verändert die Abbau-/Bergezeit, nicht pauschal alle Werkbankzeiten. Werkstattrezepte besitzen eigene Dauer und Mindesttechnik. Technik- und Werkzeugzeitboni gelten für die neuen `gather`-Fundstellen (Erz, Schiffwrack und Materialfund). Die ursprüngliche Satelliten-/Blackboxbergung dauert weiterhin feste acht Sekunden Arbeitszeit. Es gibt noch keinen Erfahrungszuwachs: Werte steigen bislang nicht durch Wiederholen der Tätigkeit.

Rüstung ist an Werkbank Stufe I für drei Metall und zwei Bauteile herstellbar (Technik 2, zehn Sekunden) oder am Markt für 220 Credits kaufbar. Ausrüstung erfolgt an der Heimatbasis aus dem tatsächlichen Lagerbestand; die weißen Kenney-Helmfiguren erhalten riggebundene Brust- und Schulterteile. Die erste Rüstung ist ein vollständiger einfacher Satz, kein bereits fertiges System unterschiedlicher Körperteil-Slots/Rüstungsstufen.

Bei null Gesundheit folgt ein gespeicherter und pausierbarer Timer von 20 Simulationssekunden. Die Figur kehrt am Ankunftspunkt derselben Karte zurück, ohne dauerhaften Verlust oder Ausrüstungsverlust. An der Basis heilen einsatzfähige Figuren. Medizin, Evakuierungsaufträge, Liegeplätze und volle Genesungslogistik sind weitere Entwicklung.

## Wiederverwendetes Hauptmenü

Das Hintergrundbild mit der sitzenden Frau stammt aus dem intakten historischen Worktree: `Assets/curated/main_menu/sternenbuerger_main_menu_bg.jpeg`. Im alten `scripts/ui/main_menu_screen.gd` wird es als gemeinsame 2D-Textur verwendet; keine separate laufende 3D-Frau.

Original unverändert nach `assets/curated/main-menu/background.jpeg` kopiert; SHA256 `8702C2E3989B8E537656BF3824C734E2474BA797F7744B574AAD8390299A5563`. Neue Menülogik in `scripts/ui/main_menu.gd`: Karriere beginnen/fortsetzen, bewusstes Ersetzen einer bestehenden Karriere, Internet/LAN und Beenden. Ein dunkler UI-Verlauf hält die linke Bedienseite lesbar, während das Motiv rechts sichtbar bleibt. Die Figur wird weiterhin per Rechtsklick geführt; WASD steuert nur die Kamera.

Die zukünftige Charaktertiefe bleibt konkret erhalten: Erfahrung aus tatsächlichen Tätigkeiten, bessere Delegation durch Können, Bewerber/Ruf/Betten, individuelle Traits, Beziehungen, Moral/Frust und Missionsgeschichte. Keine dieser zukünftigen Wirkungen wird bereits durch die drei heutigen Zahlen behauptet.
