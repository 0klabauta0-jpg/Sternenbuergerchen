# SPIKE - Unity Commander Flow Prototype

## Ziel / Problem
Pruefen, ob die zentrale SternenBuergerchen-Spielidee in Unity sinnvoll spielbar prototypisiert werden kann:

- Roster mit Charakterwerten lesen
- daraus Fireteams bilden
- Fireteams ausruesten
- Fireteams auf Dropships setzen
- ein oder mehrere Dropships auf Mission schicken
- Missionen als isometrische 3D-Ansicht mit auftragsgesteuerter Fireteam-Fuehrung erleben

## Sinnhaftigkeit / Ursache
Der Spike ist ein Engine-Vergleich fuer Spielgefuehl und Arbeitsfluss. Er ist keine Migration und keine Abkehr von Godot. Entscheidend ist, ob Unity den Commander-Flow und die indirekte Kontrolle schnell und lesbar darstellen kann.

## Umfang
- Sidecar-Unity-Projekt lokal ausserhalb dieses Godot-Repositories unter `C:\dev\SternenBuergerchen_UnityCommanderFlow`.
- Das Godot-Repository trackt keine Unity-Projektdateien, Unity-Assets, Unity-Caches oder Unity-Builds mehr.
- Lokale Sidecar-Assets aus einem kleinen CC0-Subset von Quaternius.
- Kleines Daten-/Simulationsmodell in C#, damit UI nicht die Gameplay-Wahrheit ist.
- Zwei Fireteams, zwei Dropships und mehrere gleichzeitig laufende Missionsinstanzen.
- Command Buttons fuer Move, Take, Defend, Engage und Flank.
- Isometrische 3D-Kamera mit Kachelkarte, Units, Dropship, Gegnern, Objective und Log.
- Runtime-Missionseditor fuer Kacheltypen, LZ, Objective und Gegner-Spawns.

## Nicht-Ziele
- Keine Godot-Code-Migration.
- Kein Ersatz fuer bestehende Godot-Tasks oder Contracts.
- Kein finaler Map Editor, keine finale Persistenz, Multiplayer oder Balancing.
- Keine Uebernahme des alten DOCX als technische Wahrheit.

## Relevante Dokumente
- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/DESIGN_NOTES.md`
- `docs/User-Handbuch.md`
- `docs/GDD_STATUS.md`
- `sternenbuerger-gdd.docx` nur als Inspirationsquelle fuer Spielgefuehl

## Akzeptanzkriterien
- Unity-Projekt oeffnet eine spielbare Spike-Szene.
- Der Spieler kann mindestens ein Fireteam aus Roster-NPCs erstellen.
- Loadout-Aenderungen veraendern sichtbare Teamwerte.
- Ein Fireteam kann einem Dropship zugewiesen und auf eine Mission geschickt werden.
- Mindestens zwei Missionen koennen parallel im Modell existieren und weiterlaufen.
- Missionen zeigen Fireteam, Dropship, Gegner/Objective und Command-Ziele isometrisch in 3D.
- Commands werden nicht als Einzelunit-Micro umgesetzt, sondern als Fireteam-Auftraege.
- Runtime-Editor-Aenderungen liegen im MissionCatalog und werden beim Missionsstart in MissionState kopiert.
- Ein lokaler Unity-Batch-Verifier prueft den Kernflow.

## Betroffene Dateien
- `.gitignore`
- `docs/tasks/SPIKE_unity_commander_flow.md`
- `docs/IMPLEMENTATION_STATUS.md`
- externer lokaler Ordner `C:\dev\SternenBuergerchen_UnityCommanderFlow`

## Lokale Pruefung
- Unity Batchmode Verifier ueber `SternenBuergerUnitySpike.Editor.SpikeFlowVerifier.Run`.
- Unity Scene Builder ueber `SternenBuergerUnitySpike.Editor.SpikeSceneBuilder.Build`.
- Windows-Player-Build ueber `SternenBuergerUnitySpike.Editor.SpikePlayerBuilder.BuildWindows`.
- Pure-C# Verifier ueber `dotnet run --project C:\dev\SternenBuergerchen_UnityCommanderFlow\Verifier\SpikeVerifier.csproj`.
- `git diff --check`.

## Risiken / offene Punkte
- Unity-Editor- und Package-Generierung erzeugt lokale Cache-Dateien, die ignoriert bleiben muessen.
- Der externe Unity-Ordner ist lokale Arbeitsablage und wird nicht durch dieses Git-Repository versioniert.
- Der Spike bewertet Spielgefuehl und Arbeitsfluss, nicht Produktionskosten einer Migration.
- UI/IMGUI ist fuer schnelle Bewertung gebaut, nicht als finale Unity-UI.
- Die importierten Quaternius-Assets sind als Sidecar-Subset dokumentiert; vor Produktivnutzung Lizenz-/Quelllinks erneut pruefen.
