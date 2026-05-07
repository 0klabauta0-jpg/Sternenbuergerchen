# Animated Characters Subset

Status: TASK_171 import subset, TASK_172 visual attachment subset, TASK_173 skeleton socket contract, TASK_174 socket attachment calibration, TASK_206 faction archetype skins

## Quelle
- Lokaler Ordner: `C:\Users\bjoer\Pictures\Sternenbürger\Animated Characters Bundle`
- Bundle: `Animated Characters Bundle (4.0)`, ehemals `Kenney Character Assets`
- Autor/Distributor: Kenney, `www.kenney.nl`

## Lizenz
`License.txt` im Bundle nennt Creative Commons Zero, CC0. Nutzung fuer persoenliche, edukative und kommerzielle Zwecke ist erlaubt. Credit an Kenney ist erwuenscht, aber nicht erforderlich.

## Importiertes Subset
- `models/characterMedium.fbx`
- `models/characterSmall.fbx`
- `skins/astroMaleA.png`
- `skins/astroFemaleA.png`
- `skins/astroMaleB.png`
- `skins/astroFemaleB.png`
- `animations/idle.fbx`
- `animations/walk.fbx`
- `accessories/astroHelmet.fbx`
- `accessories/militaryHelmet.fbx`
- `License.txt`

## Verbrauchsort
`data/npc_unit_visual_mapping.json` mappt dieses Subset nur auf 2.5D-Runtime-Unit-Visuals. Gameplay-State bleibt bei `SimulationRoot`; diese Assets sind reine Darstellung.

TASK_172 nutzt die Idle-/Walk-FBX-Dateien fuer den rein visuellen `AnimationPlayer` der 2.5D-Unit-Proxies. Die Helm-FBX-Dateien werden als visuelle Attachments an den Kopf-Bone oder an einen dokumentierten `HeadAnchor` gehaengt; sie sind kein Loadout, keine Ruestung und keine Gameplay-Wahrheit.

TASK_173 definiert den visuellen Skeleton-/Socket-Vertrag fuer Folge-Attachments. `characterMedium.fbx`, `characterSmall.fbx`, `idle.fbx` und `walk.fbx` teilen die Kernbones `Hips`, `Spine`, `Head`, `LeftHand` und `RightHand`. Die 2.5D-Proxies erzeugen `HeadSocket`, `RightHandSocket`, `LeftHandSocket` und `BackSocket` bevorzugt als `BoneAttachment3D`; dokumentierte Fallback-Anker sind nur Reserve und werden im Render-Snapshot gezaehlt.

TASK_174 haengt Helme bevorzugt an `HeadSocket` und Blaster-Visuals aus `Assets/used/npc/blaster_kit/` an `RightHandSocket`. Die Helm-Kalibrierung ist kleiner und tiefer im Mapping gesetzt, damit der manuelle Sichtcheck nicht mehr mit schwebenden Riesenhelmen startet.

TASK_206 nutzt die orangefarbenen `astroMaleB`-/`astroFemaleB`-Skins als Standard-Gegenteam-Archetyp `enemy_space_suit_orange`. Die hellen A-Skins bleiben Friendly-/Default-Visuals. Die Faction-Archetypen sind reine Darstellungsdaten und werden nicht fuer Gameplaywerte ausgewertet.

## Grenzen
- Kein Komplettimport des Bundles.
- Keine Entfernung der vorhandenen Astronaut-/Fallback-Assets.
- Animationen sind rein visuelle 2.5D-Proxies und entscheiden keine Bewegung.
- Helme sind rein visuelle Attachments und veraendern keine Unit-Werte.
- Sockets sind rein visuelle Attachment-Punkte und kein Loadout- oder Combat-State.
