# 3D Transparency Material Presets

Stand: 2026-05-06

Dieses Dokument beschreibt die gemeinsamen Transparenz-Presets fuer 3D-Assets in Godot 4.6.x. Die Presets sind reine Rendering-/Asset-Regeln. Sie erzeugen keine Gameplay-Wahrheit, keine Navigation und keine Combat-Effekte.

## Presets

| Preset | Godot-Modus | Einsatz |
| --- | --- | --- |
| `cutout_scissor` | Alpha Scissor | Harte Cutouts wie Zaun, Gitter, Blattformen mit klarer Kante oder Decals mit harter Maske. |
| `dither_hash` | Alpha Hash | Weichere Vegetationskanten, Hair Cards oder verrauschte Energiekanten, wenn Blend zu teuer oder sorting-anfaellig waere. |
| `true_blend` | Alpha Blend | Echtes Halbtransparent: Glas, Hologramm, Rauch, Energieeffekte. |

## Einsatzregeln

`cutout_scissor` ist der Default fuer harte Masken. Es bleibt meist instancing-freundlicher, schreibt solide Tiefe und vermeidet viele Blend-Sorting-Probleme.

`dither_hash` ist der Mittelweg fuer weichere Kanten. Es kann sichtbares Rauschen erzeugen, ist aber oft robuster als echtes Alpha Blend bei vielen kleinen Props.

`true_blend` ist die Ausnahme fuer echte Halbtransparenz. Es kann Sorting, Overdraw und Frame-Time verschlechtern und soll nicht fuer massenhaft instanzierte Vegetation oder solide Cover-Props verwendet werden.

## Factory

`scripts/rendering/material_preset_factory.gd` erzeugt die drei Presets programmatisch:

- `MaterialPresetFactory.create_material("cutout_scissor")`
- `MaterialPresetFactory.create_material("dither_hash")`
- `MaterialPresetFactory.create_material("true_blend")`

`build_preset_contract()` liefert einen kleinen read-only Vertrag fuer Tests und Doku.

## Benchmark-Szene

`scenes/tests/transparent_material_benchmark.tscn` erzeugt beim Start drei Quad-Previews nebeneinander:

- `CutoutScissor`
- `DitherHash`
- `TrueBlend`

Die Szene ist ein visueller Material-Smoke. Sie enthaelt keine Gameplay-Callbacks und setzt keine Simulation.

## Manuelle Profiler-Hinweise

1. Szene in Godot oeffnen.
2. Sichtbar pruefen, ob alle drei Quads geladen sind.
3. Render-Profiler aktivieren.
4. Wenn viele transparente Props getestet werden, Presets duplizieren oder instanzieren und Drawcalls, Frame-Time, Overdraw und Sortierartefakte vergleichen.
5. Fuer Content-Importe zuerst `cutout_scissor` oder `dither_hash` pruefen. `true_blend` nur verwenden, wenn die Halbtransparenz wirklich gebraucht wird.

## Grenzen

- Keine automatische Konvertierung bestehender Materialien.
- Kein Shader-Komplettsystem.
- Keine Aussage ueber finale Kunstwerte einzelner Assets.
- Keine Gameplay-Kopplung an Cover, LOS oder Navigation.
