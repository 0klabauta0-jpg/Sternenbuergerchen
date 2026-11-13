# Speicheranzeige und bestätigter Ausstieg

Stand: Reviewabschluss 13.11.2026. Ergänzt `campaign_introduction_contract.md` und
die Modalitätskorrektur C9; keine neue Speicherart oder Pause.

## Besitzer und Projektion

`campaign_save_projection.gd` liest die bestehenden Checkpointstores und deren
Bootstrapvalidierung. Hauptmenü und Escape zeigen dieselbe Auswahl: gültiger
passender Einsatzstand, sonst gültiger Basisstand; ein beschädigter aktiver Stand
wird nicht still übersprungen. Exakt ausrangierte Dateien und nachweislich
überholte Home-Hashes folgen weiterhin C4. Explizites `continue_home` bleibt ein
separater bestätigter Wiederherstellungsweg mit Archivierung durch den Saveowner.

Angezeigt werden Speicherart, echter Ortsname und Änderungszeit der ausgewählten
Datei, ausdrücklich in UTC. Fehlender oder nicht gültiger Stand wird benannt.
Die Anzeige ist eine lesende Vorschau; der tatsächliche Start validiert weiter
alle Runtime-Owner. Eine Anzeige legitimiert keinen Restore-Commit.

Der Flow fragt seine `CampaignStartConfiguration` für den aktuellen Saveguard
und einen lesenden Capture ab. Der Vergleich erfolgt im gespeicherten JSON-
Zahlenformat. Die Abfrage schreibt keine Dateien und verändert weder Gameplay
noch Autosaveintervall oder Save-Signatur. Sie läuft beim Öffnen/Aktivieren der
Menüaktionen, nicht pro Frame. Sperrgründe und echte Savefehler teilen denselben
Textresolver. Der eigentliche Save validiert erneut.

## Ausstieg

Ohne ausstehenden Unterschied zum gültigen Stand bleibt Beenden direkt möglich.
Bei geändertem oder momentan nicht vollständig speicherbarem Kampagnenzustand
zeigen Hauptmenü/Beenden eine Rückfrage mit dem tatsächlich fortsetzbaren Stand.
Zurück ist zuerst fokussiert. „Speichern und …“ verlässt erst nach erfolgreichem
Owner-Save; Fehler lassen Szene und Rückfrage offen. „Ohne Speichern …“ ist eine
ausdrückliche Entscheidung. Escape kehrt zum Spielmenü zurück. Die Simulation
läuft absichtlich weiter; deshalb prüft jede Ausstiegsaktion den Zustand erneut.
Auch Fensterschließen und Alt+F4 führen über dieselbe Ausstiegsprüfung. Nur der
globale Menü-Autoload bindet das Hauptfenstersignal und deaktiviert dessen
automatische Beendigung; sein Teardown gibt die vorherige Option wieder frei.

Ein laufender Skirmish-Einsatz erklärt seinen Neustart ohne Fortschrittssave.
Ein Szenenbookmark wird nicht als solcher Save angeboten. Hauptmenü und reine
Skirmish-Vorbereitung erhalten keine zusätzliche Rückfrage.

## Weitere UI-Korrekturen

- Sternkarte: fokussierbarer Schalter „Treibstoff & Reichweite“. Alt bleibt eine
  temporäre Vorschau. Ein ausdrücklich eingeschalteter Schalter übersteht die
  Abbruchbereinigung von Pointer-/Alt-Gesten beim Öffnen eines Modals.
- Smart Mobile: eine deckende Petrol-Shell mit fester Fußleiste enthält die
  echten Auftragsaktionen außerhalb des scrollenden Briefings.
- Charakteransicht: ohne gespeicherte Beziehungen eine lesbare kompakte Zeile;
  belegte Beziehungen behalten ihre Karten und tatsächlichen Profilwerte.
- Basisheader: das Standortbadge reserviert seine Textbreite, statt durch
  buchstabenweisen Umbruch die Weltansicht nach unten zu verdrängen.
- Auftragsbriefings: Himmelskörper und Einsatzort werden aus demselben
  Campaign-/Travel-Snapshot wie die Sternkarte gelesen (Job → Location → Orbit
  → Body). Die Briefingdatei liefert Ziele, keine zweite Ortszuordnung oder
  ausgeschriebenen alten Himmelskörpernamen. Alle fünf Kampagnenaufträge sind
  mit `review_completion_job_briefing_verifier.gd` abgesichert.
- Charakter-/Appfenster: vorhandene Sichtzustände unterdrücken die höher
  liegenden Kampagnenhinweise und Versorgungscontrols sofort per Sichtsignal.
  Schließen stellt die vorherigen Möglichkeiten wieder her. Kein verstecktes
  Gameplay-Pausieren und kein testseitiges Ausblenden als Produktlösung.

## Prüfung

`scripts/tests/review_completion_ux_20261113.gd` prüft reine Auswahlfälle, echte
Home-Captures/Save-/Job-/Ausstiegspfade, korrupte private Dateien und Mainmenü-
Revalidierung, 720p/1080p-Bounds sowie Fuelbedienung über Viewportevents. Native
Aufnahmen entstehen optional im isolierten Benutzerverzeichnis. Ergänzende
Nachbarn: `campaign_menu_start_test`, `astra_menu_fixes_20261113`,
`job_app_safe_area_verifier`, `character_detail_hierarchy_verifier` und echter
aktiver Kampagnen-Continue. Kein automatischer Test ersetzt die menschliche
Verständnis-/Geschmacksabnahme.
