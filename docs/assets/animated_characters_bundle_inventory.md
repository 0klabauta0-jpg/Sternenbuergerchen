# Animated Characters Bundle Inventory

Datum: 2026-05-03
Status: TASK_171 Import-Slice, TASK_172 Visual-Attachment-Slice, TASK_173 Skeleton-/Socket-Vertrag, TASK_174 Socket-Attachments

## Quelle
- Lokaler Pfad: `C:\Users\bjoer\Pictures\Sternenbürger\Animated Characters Bundle`
- Bundle: `Animated Characters Bundle (4.0)`, ehemals `Kenney Character Assets`
- Autor/Distributor: Kenney, `www.kenney.nl`

## Lizenz
`License.txt` nennt Creative Commons Zero, CC0. Nutzung fuer persoenliche, edukative und kommerzielle Zwecke ist erlaubt. Credit an `Kenney` oder `www.kenney.nl` ist erwuenscht, aber nicht erforderlich.

## Inventar
| Bereich | Dateien | MB | Inhalt |
| --- | ---: | ---: | --- |
| `Models` | 8 | 3.59 | 4 FBX-Modelle und 4 Blender-Quelldateien. |
| `Animations` | 34 | 27.97 | 17 FBX-Animationen und 17 Blender-Quelldateien. |
| `Skins` | 146 | 9.87 | PNG-Skins und SVG-Quellen, inklusive Astro-, Military-, Robot-, Alien- und weiteren Varianten. |
| `Accessories` | 43 | 3.41 | Accessory-FBX/PNG/SVG-Dateien; TASK_172 importiert nur zwei Helm-FBX-Dateien. |
| `Preview` | 4 | 0.57 | Preview-PNGs, nicht Teil dieses Slices. |

## Dateitypen
| Typ | Anzahl | Entscheidung |
| --- | ---: | --- |
| `.png` | 77 | Nur zwei Astro-Skins importiert. |
| `.svg` | 73 | Nicht importiert. |
| `.fbx` | 62 | Zwei Modelle und zwei Animations-Probes importiert. |
| `.blend` | 23 | Nicht importiert. |
| `.ai` | 1 | Nicht importiert. |
| `.txt` | 1 | Lizenzdatei importiert. |

## TASK_171 Subset
Zielpfad: `Assets/used/npc/animated_characters/`

| Datei | Zweck |
| --- | --- |
| `models/characterMedium.fbx` | Team-Alpha-Unit-Visual. |
| `models/characterSmall.fbx` | Team-Bravo-Unit-Visual. |
| `skins/astroMaleA.png` | Skin fuer Team Alpha. |
| `skins/astroFemaleA.png` | Skin fuer Team Bravo. |
| `animations/idle.fbx` | Import-Probe fuer spaetere Idle-Animation. |
| `animations/walk.fbx` | Import-Probe fuer spaetere Walk-Animation. |
| `License.txt` | Lizenznachweis im importierten Subset. |

## TASK_172 Subset
Zielpfad: `Assets/used/npc/animated_characters/`

| Datei | Zweck |
| --- | --- |
| `accessories/astroHelmet.fbx` | Rein visueller Helm fuer friendly/default Animated-Character-Proxies. |
| `accessories/militaryHelmet.fbx` | Rein visueller Helm fuer Gegner-Proxies. |

## TASK_172 Verwendung
- Die TASK_171-Modelle sind im 2.5D-Visual-Mapping von `0.66` auf `0.22` skaliert.
- `idle.fbx` und `walk.fbx` werden als rein visuelle Animationen in `TerrainMap3DView` uebernommen.
- Helme werden ueber `BoneAttachment3D` am Kopf-Bone oder ueber einen dokumentierten `HeadAnchor` angehaengt.
- Gegner-IDs `enemy_delta` und `enemy_echo` haben explizite Enemy-Visual-Mappings.
- Gameplay-State bleibt unveraendert bei `SimulationRoot`; Animationen und Helme sind reine Darstellung.

## TASK_173 Skeleton-/Socket-Vertrag
Keine neuen Asset-Dateien. Der Vertrag nutzt das bereits importierte TASK_171/TASK_172-Subset.

| Datei | Relevante Skeleton-/Bone-Namen |
| --- | --- |
| `models/characterMedium.fbx` | `Hips`, `Spine`, `Head`, `LeftHand`, `RightHand` |
| `models/characterSmall.fbx` | `Hips`, `Spine`, `Head`, `LeftHand`, `RightHand` |
| `animations/idle.fbx` | gemeinsamer Skeleton-Vertrag mit `Head` und `RightHand` |
| `animations/walk.fbx` | gemeinsamer Skeleton-Vertrag mit `Head` und `RightHand` |

`data/npc_unit_visual_mapping.json` definiert rein visuelle Sockets:
- `HeadSocket`: bevorzugt Bone `Head`, Fallback-Anker `[0.0, 1.38, 0.0]`.
- `RightHandSocket`: bevorzugt Bone `RightHand`, Fallback-Anker `[0.22, 0.84, 0.10]`.
- `LeftHandSocket`: bevorzugt Bone `LeftHand`, Fallback-Anker `[-0.22, 0.84, 0.10]`.
- `BackSocket`: bevorzugt Bone `Spine`, Fallback-Anker `[0.0, 1.05, -0.18]`.

`TerrainMap3DView` erzeugt diese Sockets als `BoneAttachment3D`, wenn der Bone vorhanden ist. Bekannte TASK_171-Modelle brauchen keinen Socket-Fallback und keinen Animation-Retarget-Fallback; beide Fallback-Arten werden trotzdem im Render-Snapshot gezaehlt.

## TASK_174 Verwendung
- Helme werden im 2.5D-Visual-Pfad bevorzugt an `HeadSocket` gehaengt, nicht mehr an einen neu erzeugten Helm-Bone-Wrapper.
- Der Default-Helm-Offset ist im Mapping nach unten kalibriert und `max_scale` wurde fuer den Socket-Sitz auf `0.010` begrenzt.
- Blaster-Visuals aus `Assets/used/npc/blaster_kit/` werden an `RightHandSocket` gehaengt.
- Helm und Blaster bleiben reine Darstellung; Gameplay-State, Loadout und Combat bleiben unveraendert bei den bestehenden Systemen.

## Importstrategie
- Kein Massenimport des Bundles.
- Keine Blender-, SVG- oder Preview-Dateien in diesem Slice; TASK_172 importiert nur zwei Helm-FBX-Accessories.
- Das Subset wird ueber `data/npc_unit_visual_mapping.json` explizit in den 2.5D-Unit-Visual-Pfad eingebunden.
- Bestehende Astronaut-/Fallback-Assets bleiben erhalten.
- Fehlende neue Assets zaehlen im `TerrainMap3DView`-Snapshot als `unit_visual_error_count` und erzeugen sichtbare Missing-Asset-Marker.
