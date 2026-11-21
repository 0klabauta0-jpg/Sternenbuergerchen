"""Measure paired native render differences on the visible ship area."""
import json
from pathlib import Path
from statistics import mean

from PIL import Image


def read_png(path: Path) -> tuple[tuple[int, int], list[tuple[int, int, int]]]:
    with Image.open(path) as image:
        rgb = image.convert("RGB")
        return rgb.size, list(rgb.get_flattened_data())


def compare(folder: Path, view: str) -> dict:
    source_size, source = read_png(folder / f"segmented_{view}.png")
    atlas_size, atlas = read_png(folder / f"atlas_{view}.png")
    if source_size != atlas_size:
        raise ValueError(f"Mismatched resolutions in {view}")
    if source[0] != atlas[0]:
        raise ValueError(f"Mismatched backgrounds in {view}")

    coverage_changes = 0
    differences = []
    for baseline, candidate in zip(source, atlas, strict=True):
        source_ship = baseline != source[0]
        atlas_ship = candidate != atlas[0]
        if source_ship or atlas_ship:
            coverage_changes += source_ship != atlas_ship
            differences.append(max(abs(old - new) for old, new in zip(baseline, candidate, strict=True)))
    if len(differences) < len(source) / 20:
        raise ValueError(f"No usable ship coverage in {view}")

    differences.sort()
    return {
        "resolution": source_size,
        "ship_pixels_in_either_image": len(differences),
        "silhouette_pixel_changes": coverage_changes,
        "exact_rgb_matches": differences.count(0),
        "mean_max_channel_delta_8_bit": mean(differences),
        "p95_max_channel_delta_8_bit": differences[int(len(differences) * 0.95)],
        "max_channel_delta_8_bit": differences[-1],
        "pixels_with_max_channel_delta_above_12": sum(delta > 12 for delta in differences),
    }


if __name__ == "__main__":
    project = Path(__file__).resolve().parent
    measurements = {view: compare(project, view) for view in ["front", "rear"]}
    (project / "render_comparison.json").write_text(
        json.dumps(measurements, indent=2) + "\n", encoding="utf-8"
    )
