# Mehrschiff-Basisflow — gezielte Prüfung 12.11.2026

## Ergebnis
Godot 4.6.2 headless: **4/4 Checks, 147 positive Assertions, 0 Fehler**.
Finaler Runnerreport: `verified/20261112T224929Z-pid26060/metadata/report.json`.
Alle vier Prozesse: Exit 0, Erfolgsmarker vorhanden, `error_count=0`, keine
Script-/Enginefehler oder Leakwarnungen. `git diff --check` für betroffene Dateien sauber.

## Produktänderungen
- `explorable_homebase.gd::_personnel_action`: implizites `base_unboard` sendet
  explizit leere `craft_id`, damit der HomebaseScreen keinen Auswahldefault
  ergänzt und BasePersonnelRuntime das tatsächliche Schiff der Person auflöst.
  Explizite IDs bleiben unverändert; andere Personenaktionen behalten ihr Verhalten.
- `meta_layer_flow.gd::_seed_singleplayer_bootstrap_homebase_payload`: prüft
  sämtliche vorhandenen Teams je echtem Schiff. Nur Teams, deren sämtliche
  Mitglieder dort tatsächlich als `aboard` gespeichert sind, erhalten den
  abgeschlossenen Payload im bestehenden Owner. Kein Parallel-State.
- Fremdes WIP `set_authoring_markers_visible` in explorable_homebase bleibt erhalten.

## Regressionen / Grenzen
`game_review_multicraft_20261112.gd`: 57 Assertions. Reale Continue-Szenen,
echter Aussteigen-Button für Schiff 2, explizit falsche/richtige Schiffswahl,
unveränderte Präsenz von Schiff 1, beide Payload-/Launchgates, echte zweite
Transport-Abflug-/Landekommandos, Teilteams, über zwei Schiffe verteiltes Team.
Der Vier-Personen-/Zwei-Schiff-Checkpoint wird mit echten Campaign/Supply-Ownern
und ausdrücklich synthetischer Missionsgate-Evidenz aufgebaut und validiert.
Das ist kein neuer vollständiger Kampagnendurchlauf.

Die natürliche Buccaneer-Belohnung ist `fighter`. Der bestehende AircraftManager
sperrt Trupptransport auf diesem Typ bereits vor Continue. Der ursprüngliche
Reviewtext "zuvor möglicher Buccaneer-Abflug" war deshalb zu weitgehend.
Launch-Roundtrip verwendet ausdrücklich einen zulässigen zweiten Dropship im
validierten Checkpoint. Ein eigener Fall erhält die tatsächliche Fighter-Sperre
und prüft dennoch das funktionierende Aussteigen des echten Buccaneer-Piloten.

## ROT und Fixturekorrekturen
Unveränderter Produktcode: `red-confirmed/20261112T224407Z-pid54204/` zeigt
49 Assertions / 4 Fehler, Exit 1, keine Enginefehler. Darunter reproduzieren
der echte Aussteigen-Button und fehlende sekundäre Payload-Zuordnung die beiden
Ursachen. Zwei zusätzliche Transport-/Launch-Erwartungen dieser ersten Fixture
waren wegen des oben erklärten Fighter-Gates zu weit gefasst; finale positive
Launchprüfungen verwenden den ausdrücklich bezeichneten Transport-Checkpoint.
Vorläufe und Fehlversuche bleiben vollständig erhalten.

Angrenzende alte Tests wurden separat sachlich aktualisiert:
- base_personnel_runtime_verifier: konsistenter Pilotentausch in `craft` UND
  `fleet[0]`; divergente Owner werden zusätzlich negativ geprüft (66/0).
- world_ui: vorhandenes medictool statt nicht vorrätiger SMG für positiven
  Ausrüstungswechsel; Inventarmangel der SMG zusätzlich negativ geprüft (10/0).
- preparation_continue: derselbe reale Inventarvorbehalt und Roundtrip des
  verfügbaren medictool, weiterhin bewusst unbesetzter Pilotensitz (14/0).
Alte Fehlerlogs: `green/20261112T224520Z-pid28132/`.
Die echten Bewegungspfade zum Bett, Terminal und Pad sowie Returning-Pilot,
Boarding-Idempotenz, Orbit/Quantum/Landung sind im base_personnel-Verifier grün.

## Reproduktion / Save-Isolation
Der Root führte den einmaligen Import aus. Wiederholung:

```powershell
$env:APPDATA='C:\dev\SternenBuergerchen\docs\qa\game_review_20261112\multicraft\profiles'
python C:/Users/bjoer/.codex/skills/godot-game-verification/scripts/run_checks.py --project C:/dev/SternenBuergerchen --manifest docs/qa/game_review_20261112/multicraft/checks.json --godot godot_console.exe --skip-import --output docs/qa/game_review_20261112/multicraft/verified
```

Alle Teststände liegen tatsächlich unter diesem isolierten APPDATA/Godot-Pfad;
keine echten Spielerstände wurden verändert. Der neue Verifier verweigert einen
Start ohne diese QA-Isolation. Keine Desktop-Eingaben, kein natives Fenster,
kein Commit/Push, keine Grafik-/Performance-/Multiplayergesamtfreigabe.
