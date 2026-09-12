# Sternenbürgerchen · Neustart

Godot 4.6.2. Zwei Freunde, ein eigenes Shuttle und eine kleine Basis an der Rostgrenze.

**Starten:** `Spielen.cmd` doppelklicken, oder `tools/run.ps1` in PowerShell. `tools/run.ps1 -Editor` öffnet genau dieses Projekt im richtigen Editor. Die andere Godot-Installation wird nicht verändert.

**Erster Weg:** Auftragstafel → Satellitenbergung annehmen → Shuttle „Entersäbel“ → Absturzstelle → Ida/Jaro wählen → Satellit bergen → Shuttle → Heimat → Auftrag abgeben. Werkbank anklicken, geeigneten NPC zuweisen und herstellen/reparieren. Die Handelsstation bietet Materialkauf und Warenverkauf.

Linksklick wählt Objekte und Crew; ein gezogener Rahmen wählt mehrere Personen. **Rechtsklick setzt das Laufziel.** 1/2 wählen Ida/Jaro. WASD/Pfeile und mittlere Maus bewegen ausschließlich die Kamera. V beziehungsweise das Figur-Symbol oben wechselt zwischen freier Crewansicht und Einzelansicht mit Kamerafolge; die Bewegung bleibt Point-and-Click. Mausrad zoomt, Home zeigt den Überblick. Leertaste pausiert. F5 speichert, F9 lädt. Beim normalen Beenden wird gespeichert; beim nächsten Start wird die Karriere fortgesetzt. Ein Speicherfehler hält das Fenster offen.

**Koop-Probe:** Menü-Symbol → Koop-Verbindung → Sitzung öffnen; zweites Fenster → Beitreten (`127.0.0.1` auf demselben Rechner). Host führt Ida, Gast Jaro; Host koordiniert Reise, Markt und gemeinsame Pause. Port 27991. Die ausführliche Prüfgrenze steht in `docs/IMPLEMENTATION_STATUS.md`.

Spielstände sind von alten Projekten getrennt unter `%APPDATA%\SternenBuergerchen-Neustart\campaign.json` gespeichert. Kosten, Zeiten und kleine Startkataloge sind erste veränderbare Spielwerte. Kampf, Ausbau/Rekrutierung und Raumberufe sind spätere Etappen.

Die Crew verwendet den weißen Kenney-Astronauten mit Helm. Das bereitgestellte Schiff wurde in Blender zur lokalen „Entersäbel“ mit 17.879 Dreiecken verarbeitet. GLB, Blenderdatei und Vorschau liegen in `assets/local/`. Dieser Ordner ist nicht Teil des Git-Branches; ein frischer Clone verwendet das enthaltene Kenney-Shuttle. Herkunft und Wiederherstellung: `docs/ASSETS.md`.

Die neue Historie liegt im bestehenden Repository auf dem separaten Branch `codex/neustart-n0-n1`. Dieser Branch ersetzt oder merged den alten Integrationsstand nicht automatisch.
