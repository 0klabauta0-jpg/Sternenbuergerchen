# Weapon Visuals Inventory

Datum: 2026-05-06
Status: TASK_190 implementiert

## Zweck
Dieses Inventar dokumentiert die kleine Weapon-Pack-Auswahl fuer sichtbare Loadout- und 2.5D-Waffen. Die Assets bleiben Darstellung; Combat-Werte, Commands und Effects bleiben bei den bestehenden Runtime-Systemen.

## Quelle
| Feld | Wert |
| --- | --- |
| Bundle | Kenney `Weapon Pack (1.0)` |
| Lizenz | Creative Commons Zero, CC0 |
| Projektquelle | `Assets/Weapon Pack/` |
| Zielpfad | `Assets/used/npc/weapon_pack/` |

## Importiertes Subset
| Asset | Zweck |
| --- | --- |
| `models/sniper.glb` | 2.5D-Visual fuer `sniper` / `sniper_rifle`. |
| `models/rocketlauncherModern.glb` | 2.5D-Visual fuer `rocket_launcher` / `panzerfaust`. |
| `previews/sniper.png` | #13 LOADOUT Preview fuer Sniper. |
| `previews/rocketlauncherModern.png` | #13 LOADOUT Preview fuer Rocket Launcher. |
| `License.txt` | Lizenznachweis. |

## Runtime-Vertrag
- Stabile neue IDs: `sniper`, `rocket_launcher`.
- Aliase: `panzerfaust`, `raketenwerfer`, `rocket`, `rocketlauncher` -> `rocket_launcher`; `sniper_rifle`, `scharfschuetzengewehr`, `praezisionsgewehr` -> `sniper`.
- Visual-Loadouts: `sniper_rifle` am `RightHandSocket`, `rocket_launcher` am `BackSocket`.
- Keine absoluten lokalen Pfade in Runtime-Mapping oder Tests.
- Keine neue Projektil-, Splash-Damage- oder Munitionslogik in TASK_190.

## Pruefung
Der TASK_190-Verifier prueft IDs, Aliase, Preview-Pfade, Visual-Mapping, Resource-Ladung, Scale-Grenzen, Missing-Asset-Diagnose und dass Visual-Loadouts keine SimulationRoot-Commands oder Effects erzeugen.
