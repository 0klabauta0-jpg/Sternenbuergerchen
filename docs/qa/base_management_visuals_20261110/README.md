# Basisfenster, kleine Figur und sichtbare Kampagnenfolge — 10.11.2026

Mainbasis1e3cca237. Aufbau auf den noch nicht integrierten Tasks5df2d3b6f und
9c87a06ef, aktueller Branch task/base-management-visuals-20261110.

Bilder-KI erzeugte management_concept_01 als Gestaltungsentwurf. Prompt, beide
nativen Eingabebilder und Originalausgabe erhalten; SHA256 in reference/manifest.json.
Übernommen sind Petrol/Creme/Bernstein, matte Karten, klare Überschriften und
reale Aktionsflächen. Erfundenes im Konzept wurde nicht als Inhalt umgesetzt.
Die PNGs unter images sind tatsächliche Godot-Aufnahmen, keine KI-Screenshots.

## Umsetzung
- Basisfunktionen öffnen nach rechts animierte, schließbare Seitenfenster über
  der sichtbaren Basis. Hintergrundfang verhindert Kartenbefehle dahinter.
- Tankservice unter Flugdeck, kein zweiter Schiff-Eintrag unter Basis erkunden.
- Smart Mobile, Bauen, Werkstatt, Lager, Datenterminal und Tankservice teilen eine
  gemeinsame Gestaltung. Vorhandene Nodes und Commands bleiben; Aktionskarten
  werden bei unverändertem Snapshot nicht neu gebaut. Schmale330px-Versorgung
  bleibt benutzbar, breite Seiten ordnen Rezepte nebeneinander.
- Figur90x150 statt180x300, echtes Porträt daneben. Ausrüstung vollständig seitlich,
  keine Überdeckung. Bestehende Idle-Animation einmal ausgewertet und eingefroren;
  kein neues Modell/Rig, kein laufender Modell-/Animationsprozess in der Vorschau.
- Lager bleibt freier Bestand. Slotwechsel verbraucht ein echtes Item und gibt
  das vorher getragene genau einmal zurück. Lesbare Rüstungsnamen statt Wortbruch.
- Kampagne anfangs nur Satellitendaten. Vorhandener CampaignState sperrt Folgejobs;
  UI filtert nach dessen locked-Flag. Erfolgreicher Heim-Upload macht Außenposten
  sichtbar, spätere Missionen bleiben verborgen. Erledigte Aufträge bleiben Historie.
- Erster Auftraggeber: Fragwürdige Geschäftsleute, aus separatem Inhaltskatalog.
  Kein Saveformatwechsel oder erfundene Rufmutation. Ruf pro Auftraggeber ist
  im Kampagnenplan vorgemerkt, Skala/Schwellen/Wirkung noch offen.

## Nachweise und Grenzen
- Vollständiger tatsächlicher erster Kampagnenausflug88/0: initial nur Satellit
  und richtiger Auftraggeber, Pilot in FT1, Aufsitzen/Absetzen, echte Datensicherung,
  Heimkehr, Schlafen, Upload, Belohnung, Herstellung, Checkpoint und sichtbare
  nächste Mission. Headless, Zeitfaktor4; keine erfundenen Abschlussreceipts.
- Native Seitenfenster87/0, Enginefehler0, zwei vorhandene UID-Pfadfallbackwarnungen.
  Alle sechs Ansichten in1280/1920 logischen Größen, reale Buttons in Reichweite,
  Annahme ohne Scrollen, Basis hinter den Fenstern, schmale Versorgung und
  unveränderte Bestände. Verborgener D3D12-Host1280x720.
- Native kleine Charakteransicht32/0, Enginefehler0; 1280/1920/3440 logische Größen,
  Körpergröße, bestehende Idle-Pose, echtes Porträt, keine Slotüberdeckung,
  realer Equip-Drop mit exakter Bestandswirkung. Dazu finaler Headless32/0.
- Basisverwaltung21/0; Compact-Profil22/0; Fünf-Missionen-State15/0.
- Frühe Proben deckten eine Mindestbreiten-Rückkopplung im Smart Mobile, lange
  Labelumbrüche und im neuen Verifier einen Node/RefCounted-Typfehler auf. Korrigiert,
  rote Proben nicht als Pass gezählt. Normale Missions-/Savesysteme nicht umgebaut.
- Native Bilder angesehen. Technische Abnahme ist keine gestalterische Nutzerabnahme,
  kein allgemeiner FPS-Beleg, kein Main-Merge und keine neue EXE. Nutzersaves und
  Teambibliothek unverändert; alle Tests in eigenen APPDATA-Profilen.
