# Kampagne und Forschung als lokale Workbench

Stand 11.11.2026, task/native-glut-maps-20261110. Ausgangsstand 820a91caf.
Die Seite unter docs/reports/campaign_research_workbench.html funktioniert direkt
per file://. Keine externen Abhängigkeiten, keine Spielstandsmutation, kein Hosting.
Abgeleitet von _html_workbench_template.html nach html_report_workbench_contract.

18 Knoten: zwölf vorhandene, zusammengefasste Kampagnen-/Fertigungsschritte und
sechs ausdrücklich vorgeschlagene Fortsetzungen. Fünf Aufträge kommen direkt aus
jobs.json, ihre Ziele aus job_briefings.json. Drei Rezeptpreise aus der bestehenden
CAMPAIGN_RECIPES-Deklaration. Personal/Kiste/zweites Pad erklären die weiteren
bestehenden Voraussetzungen. Die Aufnahme am Außenposten ist im Spiel bereits
vor Ausflugsabschluss möglich; diese Planübersicht bündelt den vollständigen Ausflug.
Fünf Quellhashes und die unveränderte Baseline werden mit exportiert.

Editierbar sind Titel, Art, Voraussetzungen, Beschreibung, Belohnung, Kosten,
Creditbelohnung, Playtest, Entscheidung und Notiz. Neue Schritte, Suche, Filter,
Planspiel, lokale Wiederaufnahme und JSON-Roundtrip sind vorhanden. Zyklen bleiben
als bearbeitbare Entwurfsfehler sichtbar; Abschlüsse im Kreis und dessen abhängige
Abschlüsse werden zurückgenommen. Fehlender oder beschädigter Import ersetzt den
aktuellen Stand nicht. Vorschläge werden durch lokale Zustimmung nicht implementiert.

Playwright CLI, Chromium, lokales file://, Desktop 1600×1000 und schmal 390×844.
23 Interaktionsprüfungen erfolgreich, null Browserfehler/-warnungen im finalen Lauf.
results.json, probe.js, roundtrip.json und beschädigtes Importfixture liegen bei.
Desktop-/Mobilbilder wurden geöffnet. Der erste Test hatte eine asynchrone
Import-Race im Verifier; auf den sichtbaren Abschluss gewartet und frisch wiederholt.
Die Dateiansicht wurde mit der vorgesehenen CLI-Dateizugriffsoption geprüft.

Forschungsvorschlag: Bauplan bergen → an der Basis entwickeln → einzelne Ausrüstung
fertigen. Schutz, Industrie und Mobilität/Flotte bieten Fortsetzung nach den fünf
Aufträgen. Kosten neuer Forschung sind eigene Balancevorschläge, keine bestätigten
Spielwerte. Creditvorschau berücksichtigt keine Fuel-/Handelsausgaben und keine
wiederholte Produktion. Der Runtime-Forschungsbaum bleibt eine Folgeintegration.
