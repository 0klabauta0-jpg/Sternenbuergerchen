# SternenBuergerchen Unity Commander Flow Spike

## Zweck
Dieser Sidecar-Prototyp prueft den SternenBuergerchen-Spielfluss in Unity, ohne den Godot-Produktionspfad zu ersetzen.

Der Spike zeigt:

- Homebase-Roster mit Charakterwerten
- Fireteam-Bildung aus NPCs
- Loadout- und Armor-Anpassung
- Dropship-Zuweisung
- parallele Missionsstarts
- isometrische 3D-Missionsansicht mit importierten Sci-Fi-Assets
- Fireteam-Auftraege statt Einzelunit-Micro
- Runtime-Missionseditor fuer Kacheln, LZ, Objective und Gegner-Spawns

## Start
Unity 6000.4.1f1 oeffnen und dieses Projekt laden:

```text
C:\dev\SternenBuergerchen\spikes\unity_commander_flow
```

Dann Szene starten:

```text
Assets/Scenes/CommanderFlowSpike.unity
```

Auf diesem Rechner war Vulkan stabiler als der D3D12-Editorpfad. Deshalb zuerst diesen Starter nutzen:

```text
C:\dev\SternenBuergerchen\spikes\unity_commander_flow\launch_unity_spike_vulkan.cmd
```

Falls Vulkan lokal nicht passt, D3D12-Fallback:

```text
C:\dev\SternenBuergerchen\spikes\unity_commander_flow\launch_unity_spike_d3d12.cmd
```

Falls der Unity-Editor mit einem D3D11/GPU-Reset abstuerzt, Windows nach Visual-Studio-/Treiber-Installationen zuerst neu starten und danach wieder den Vulkan-Starter nutzen.

## Runtime-Editor
Im Play-Mode liegt rechts im Missionsbereich ein `Editor`-Schalter. Der Editor arbeitet auf der ausgewaehlten Mission im Katalog, nicht auf einer zweiten UI-Wahrheit.

Werkzeuge:

- `Ground`, `Road`, `Cover`, `Wall`, `Hazard`
- `LZ`, `OBJ`, `Enemy`

Mit aktiviertem Editor eine Kachel in der 3D-Ansicht anklicken. LZ und OBJ verschieben die Missionstargets, Enemy erzeugt Spawnpunkte fuer neu gestartete Missionsinstanzen. Bereits laufende Missionen behalten ihren beim Start kopierten Zustand.

Der Starter oeffnet Unity direkt und bricht ab, wenn schon ein Unity-Editor laeuft. Vorher also alle Unity-Fenster schliessen, besonders wenn oben `SternenBuergerchen - Untitled` steht.

Die Starter-`.cmd` rufen intern jeweils die gleichnamige `.ps1` auf. Wenn Windows das Konsolenfenster sofort schliesst, die `.ps1` direkt per PowerShell starten.

Wenn oben in Unity `SternenBuergerchen - Untitled` steht, ist der falsche Ordner oder eine leere Szene offen. Richtig ist das Projekt:

```text
C:\dev\SternenBuergerchen\spikes\unity_commander_flow
```

Die Titelleiste sollte danach `unity_commander_flow - CommanderFlowSpike` oder aehnlich zeigen. Alternativ im Menue `SternenBuerger > Open Commander Flow Spike Scene` auswaehlen.

## Spielablauf im Spike
1. Links im Homebase-Roster NPCs zum ausgewaehlten Fireteam hinzufuegen.
2. In der Mitte zwischen Alpha und Bravo wechseln.
3. Loadouts und Armor pro Mitglied durchklicken.
4. Ein Dropship zuweisen.
5. Rechts eine Mission waehlen und das Fireteam starten.
6. Nach LZ-Ankunft unten Befehle geben: Move, Defend, Take, Engage oder Flank.
7. Das zweite Fireteam kann mit dem zweiten Dropship parallel auf eine andere Mission geschickt werden.

## Verifier
Pure-C#-Flow:

```powershell
dotnet run --project spikes/unity_commander_flow/Verifier/SpikeVerifier.csproj
```

Unity-Batch-Flow:

```powershell
& 'C:\Program Files\Unity\Hub\Editor\6000.4.1f1\Editor\Unity.exe' -quit -batchmode -projectPath 'C:\dev\SternenBuergerchen\spikes\unity_commander_flow' -executeMethod SternenBuergerUnitySpike.Editor.SpikeFlowVerifier.Run -logFile 'C:\dev\SternenBuergerchen\tmp\unity_flow_verifier_6000.log'
```

## Windows-Player
Lokalen Windows-Player bauen:

```text
C:\dev\SternenBuergerchen\spikes\unity_commander_flow\build_unity_spike_player_windows.cmd
```

Danach ohne Editor per Vulkan starten:

```text
C:\dev\SternenBuergerchen\spikes\unity_commander_flow\run_unity_spike_player_vulkan.cmd
```

Der Build landet unter `Builds/Windows/` und bleibt lokal ignoriert.

## Bewertungshinweis
Der Spike bewertet Arbeitsfluss und Spielgefuehl. Grafik, UI-System, Editor-Persistenz und Multiplayer sind absichtlich nicht produktionsreif umgesetzt. Die importierten Quaternius-Assets liegen als Sidecar-Subset unter `Assets/Imported/Quaternius`.
