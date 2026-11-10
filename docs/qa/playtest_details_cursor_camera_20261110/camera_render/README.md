# Kameradarstellung: nativer Vergleich, 10.11.2026

## Beobachtung und Ursache

Nutzerreferenz: `C:/Users/bjoer/AppData/Local/Temp/codex-clipboard-4737cc11-b708-4d63-a6c4-627a42c309a1.png`, SHA-256 `685dea489f235a878f138ae01c100fafb75d1ce9a6f2f93d6d8fd71a389e2b44`.
Sie zeigt die stark herausgezoomte Basis. Die folgenden Bilder sind **native Godot-Aufnahmen der realen Basis**, keine Konzeptbilder und keine nachbearbeiteten Vergleiche.

Die Laufzeitprobe widerlegt eine absichtliche geringe Renderauflösung: äußerer Basis-Viewport, Container und innerer 3D-Viewport jeweils 1920×1080, `stretch_shrink=1`, `scaling_3d_scale=1.0`. Im ursprünglichen inneren Viewport waren MSAA, FXAA und TAA ausgeschaltet. Der Boden verwendet einen prozeduralen Shader; der separate Nearest-Filter des Stations-Colormaps erklärt dessen Sandkörnung nicht.

Die feinen Weltkoordinaten-Rauschfelder und Reliefnormalen wurden unabhängig vom Bildschirmfußabdruck ausgewertet. Zusätzlich verwendete die Körnchen-Kantenglättung Ableitungen einer an Zellgrenzen springenden `fract`-Koordinate. Native gleiche Bildausschnitte zeigen: 2× MSAA glättet Geometriekanten, beseitigt aber das Bodenrauschen allein nicht. Die Shaderrevision reduziert dessen hochfrequenten Anteil bei Verkleinerung. Das erklärt einen Teil des pixeligen Eindrucks; winzige Modelle erhalten dadurch keine zusätzlichen geometrischen Details. Die separate Beschriftungsänderung wird hier nicht abgenommen.

## Tatsächliche Revision

- `TerrainMap3DView`: 2× MSAA im erzeugten 3D-Viewport; native Auflösung bleibt erhalten. Kein bildweiter Blur oder Supersampling.
- `frontier_ground.gdshader`: kontinuierliche Bildschirmableitungen bestimmen den Detailfußabdruck. Feines Grit-/Krusten-/Pflasterrauschen und Relief werden bei Unterabtastung zurückgenommen. Körnchenkanten benutzen kontinuierliche Koordinaten; schmale Risse werden nach ihrem Bildschirmfußabdruck geglättet. Aufgelöste nahe Details bleiben bestehen.
- Unveränderte Meshes, GLBs, Palette, Beleuchtung und Kameraposition je Vergleichspaar. Kein Asset-Neuentwurf und keine Änderung an fremden Quellständen.

Die Kamera bleibt innerhalb aller Paare bei Yaw 24° und Pitch-Parameter 40° (effektiv ungefähr 35° Elevation unter der vorhandenen Projektionsformel). Dieser zuvor geänderte Blick ist für Vorher und Nachher identisch. Die Qualitätsrevision dreht die Szene nicht und kann deshalb die optische Wirkung des Winkels getrennt von der Rasterqualität beurteilen lassen. Zoomgröße 60 zeigt die Übersicht, Größe 16 den nahen Ausschnitt am selben Kartenmittelpunkt.

## Bilder und Messung

| Datei | Zustand |
| --- | --- |
| `baseline_size60_aa_off.png` | Übersicht, ursprünglicher Shader und AA aus |
| `candidate_size60_msaa_2x.png` | Identische Übersicht, Shaderrevision und 2× MSAA |
| `baseline_size16_msaa_2x.png` | Nahansicht, ursprünglicher Shader, 2× MSAA |
| `candidate_size16_msaa_2x.png` | Identische Nahansicht, Shaderrevision, 2× MSAA |

`metadata.json` enthält Renderer, Treiber, Größen, Quell-/Bildhashes und alle acht Rohaufnahmen. Vollständige OFF/2×-Paare beider Shader und Zoomgrößen verbleiben unter `C:/tmp/sb-camera-render-quality/shader_comparison/`. Die ursprüngliche Shaderquelle für die Reproduktion liegt hier als `baseline_frontier_ground.gdshader.txt` (unveränderte Bytes, SHA-256 im Metadatensatz).

GPU: NVIDIA RTX 4070 Ti SUPER; Godot 4.6.2, Windows, D3D12, Forward+. Szene nach Aufbau eingefroren; je Paar gleiche Kamera, Beleuchtung und Materialroute. Alle acht PNG-Schreibvorgänge `OK`, nativer Prozess Exit 0, keine Shader-Compilefehler beobachtet. Originale geöffnet: ruhigere ferne Bodenstruktur, unverändert klare Gebäudeformen; nahe Details bleiben sichtbar. Restkörnung ist weiterhin vorhanden. Keine menschliche Stilfreigabe.

Zur begrenzten Quantifizierung wurde für feste Bildrechtecke die Standardabweichung des diskreten Luma-Laplacians `4C-N-S-W-E` verglichen (Luma hier RGB-Mittelwert, Werte 0–255). Verglichen werden jeweils ursprünglicher und revidierter Shader mit **demselben 2× MSAA**; dadurch wird der Shader getrennt von AA betrachtet:

| Zoom / Rechteck `(x0,y0,x1,y1)` | Vorher | Nachher |
| --- | ---: | ---: |
| 60 / Boden `(400,150,650,300)` | 25,15 | 21,28 |
| 60 / Boden `(1100,650,1400,800)` | 25,50 | 21,14 |
| 60 / Gebäude `(990,410,1090,460)` | 101,55 | 101,53 |
| 16 / Boden `(100,850,350,1020)` | 21,55 | 19,85 |
| 16 / Gebäudewand `(1100,120,1180,180)` | 71,77 | 71,77 |

Die fernen Bodenproben enthalten damit etwa 15–17 % weniger hochfrequente Variation. Die nahe Gebäudewand ist pixelidentisch; es wurde kein bildweiter Weichzeichner angewendet. Diese Stichproben sind weder ein allgemeines Qualitätsmaß noch eine vollständige Alias-/Flimmerprüfung.

90 Prozess-Frameintervalle pro Konfiguration ergaben p50 etwa 0,87–1,04 ms und schwankende p95 bis 9,56 ms. Sie enthalten Scheduler-/Render-Warteeffekte und sind **kein GPU-Benchmark oder allgemeiner Performancevergleich**. Es folgt daraus keine Performance-/Releasefreigabe.

## Wiederholung und gezielte Verifikation

```powershell
$env:APPDATA = 'C:/tmp/sb-camera-render-profile'
& 'C:/Users/bjoer/AppData/Local/Microsoft/WinGet/Links/godot_console.exe' --path . --script res://scripts/tests/playtest_camera_render_quality_probe.gd --resolution 1920x1080 -- output=C:/tmp/sb-camera-render-repeat baseline_shader=docs/qa/playtest_details_cursor_camera_20261110/camera_render/baseline_frontier_ground.gdshader.txt
```

`playtest_cursor_camera_verifier.gd`: **52 bestanden, 0 fehlgeschlagen** nach Shader-/MSAA-Revision, isoliertes APPDATA. Enthält Weltpunktanker für Zoom/Pan, Square/Hex, Canvas-/Viewport-Transformationen, Grenzen, echte Viewport-/GUI-Eingabeverteilung, Fokus-/Release-Verhalten, Q/E und MSAA-Konfiguration. `git diff --check` für die betroffenen Dateien ohne Fehler.

Diese gezielten Nachweise ersetzen keine Prüfung der gesamten Kampagne, anderer GPUs, langfristiger Bewegung oder eine persönliche Winkel-/Stilabnahme.
