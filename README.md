# Sternenbürgerchen · Neustart

Godot 4.6.2. Zwei Freunde, ein eigenes Shuttle und eine kleine Basis an der Rostgrenze.

**Starten:** `Spielen.cmd` doppelklicken, oder `tools/run.ps1` in PowerShell. `tools/run.ps1 -Editor` öffnet genau dieses Projekt im richtigen Editor. Die andere Godot-Installation wird nicht verändert.

**Erster Weg:** Auftragscomputer im Aufenthaltsraum → Satellitenbergung annehmen → Shuttle „Entersäbel“ → Suchgebiet → abheben und Radar auslösen → unbekannte Kontakte anfliegen → neben dem identifizierten Satelliten landen → Crew zur Bergung schicken → heimkehren und Auftrag abgeben. Die Werkstatt fertigt einfache Ausrüstung; ein Ausbau schaltet bessere Rezepte frei. Unterkünfte und Lager haben eigene Räume.

**Stationsreise:** Die größere Handelsstation besitzt ein eigenes Dock. Mit 35 % Chance wird unterwegs eine separate Raumkarte mit einem schwachen Freibeuter geladen. Rechtsklick setzt Flugziele auf einer Ebene; Jaro bedient den Turm. Sieg oder Rückzug setzt die Reise fort. Eine Niederlage bringt beide Personen und das beschädigte Schiff zur Basis zurück. Alle Orte werden einzeln geladen.

Linksklick wählt Objekte und Crew; ein gezogener Rahmen wählt mehrere Personen. **Rechtsklick setzt das Laufziel.** 1/2 wählen Ida/Jaro. WASD/Pfeile und mittlere Maus bewegen ausschließlich die Kamera. V beziehungsweise das Figur-Symbol oben wechselt zwischen freier Crewansicht und Einzelansicht mit Kamerafolge; die Bewegung bleibt Point-and-Click. Mausrad zoomt, Home zeigt den Überblick. Leertaste pausiert. F5 speichert, F9 lädt. Beim normalen Beenden wird gespeichert; beim nächsten Start wird die Karriere fortgesetzt. Ein Speicherfehler hält das Fenster offen.

**Koop-Probe:** Menü-Symbol → Koop-Verbindung → Sitzung öffnen; zweites Fenster → Beitreten (`127.0.0.1` auf demselben Rechner). Host führt Ida, Gast Jaro; Host koordiniert Reise, Markt und gemeinsame Pause. Port 27991. Die ausführliche Prüfgrenze steht in `docs/IMPLEMENTATION_STATUS.md`.

Spielstände sind von alten Projekten getrennt unter `%APPDATA%\SternenBuergerchen-Neustart\campaign.json` gespeichert. Alte v1-Saves werden in v2 übernommen. Kosten, Zeiten und Begegnungschance sind erste veränderbare Spielwerte. Bodenkampf, Hindernisnavigation, baubare Raummodule, Rekrutierung und Raumberufe folgen noch.

Die Crew verwendet den weißen Kenney-Astronauten mit Helm. Das bereitgestellte Schiff wurde in Blender zur lokalen „Entersäbel“ mit 17.879 Dreiecken verarbeitet. GLB, Blenderdatei und Vorschau liegen in `assets/local/`. Dieser Ordner ist nicht Teil des Git-Branches; ein frischer Clone verwendet das enthaltene Kenney-Shuttle. Herkunft und Wiederherstellung: `docs/ASSETS.md`.

Der Freibeuter wurde ebenfalls in Blender vereinfacht: 13.945 Dreiecke. Lokale Modelle bleiben unter `assets/local/`; Herkunft und Reproduktion stehen in `docs/FREIBEUTER_ASSET_METRICS.md`. Ohne lokale Schiffe werden Kenney-Ersatzmodelle verwendet.

**Gesamtplan fürs Handy:** [Sternenbürgerchen · Zwei Freunde. Eine Basis. Eine Zukunft.](https://sternenbuergerchen-neustart.klabauta.chatgpt.site) — privat über dein ChatGPT-Konto. `tools/build_report.py` erzeugt denselben Plan als lokale HTML mit vorhandenen Spielbildern. Technische Abnahme: `docs/ROOMS_ORBIT_ACCEPTANCE.md`.

Die neue Historie liegt im bestehenden Repository auf dem separaten Branch `codex/rostgrenze-raeume-orbit`, aufbauend auf `codex/neustart-n0-n1`. Dieser Branch ersetzt oder merged den alten Integrationsstand nicht automatisch.
