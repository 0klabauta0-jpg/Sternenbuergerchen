#!/usr/bin/env python3
"""Messung K1 bis K8 und Vergleichsbogen fuer die schwere Ruestung (Paket P8, R09).

Aufrufe:
  python3 tools/ruestung_ansichten_messen.py <renderordner> <ausgabeordner>
      misst Bogen und Render (vorne.png, seite.png), schreibt messung.json, vergleich.jpg, helm_gross.jpg
  python3 tools/ruestung_ansichten_messen.py helm3 <render_alt> <render_neu> <ausgabe.jpg>
      Kopfzone vorn und Seite: Bogen | alt | neu, vierfach
  python3 tools/ruestung_ansichten_messen.py extra <ordner_light> <ordner_medium> <ordner_heavy> <ausgabe.jpg>
      spielmassstab.png dreier Ruestungen, 1:1 und vierfach

Silhouette = Pixel, deren Kanalabweichung vom Hintergrund (Pixel (5, 5)) in der Summe > 36 ist.
Hoehe H = Silhouette von der obersten bis zur untersten Zeile. Zonen sind Anteile von H von oben.
"""
import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
SHEET = ROOT / "Assets" / "curated" / "ui" / "polisa_armor" / "heavy_turnaround.png"
FRONT_X = (60, 445)
SIDE_X = (985, 1265)
SHEET_Y = (10, 810)
DARK = 45
BG_SUM = 36


def load_region(img: Image.Image, xs=None, ys=None) -> np.ndarray:
    arr = np.asarray(img.convert("RGB")).astype(int)
    bg = arr[5, 5].copy()
    if xs is not None or ys is not None:
        x0, x1 = xs or (0, arr.shape[1])
        y0, y1 = ys or (0, arr.shape[0])
        arr = arr[y0:y1, x0:x1]
    return arr, bg


def silhouette(arr, bg):
    return np.abs(arr - bg).sum(axis=2) > BG_SUM


def luma(arr):
    return arr[..., 0] * 0.299 + arr[..., 1] * 0.587 + arr[..., 2] * 0.114


def longest_run(mask_row) -> int:
    best = cur = 0
    for v in mask_row:
        if v:
            cur += 1
            best = max(best, cur)
        else:
            cur = 0
    return best


def profile(img: Image.Image, xs=None, ys=None) -> dict:
    arr, bg = load_region(img, xs, ys)
    sil = silhouette(arr, bg)
    rows = np.where(sil.any(axis=1))[0]
    y0, y1 = int(rows[0]), int(rows[-1])
    h = y1 - y0 + 1
    width = np.zeros(h)
    dark_run = np.zeros(h)
    lum = luma(arr)
    for i in range(h):
        row = sil[y0 + i]
        cols = np.where(row)[0]
        if len(cols):
            width[i] = cols[-1] - cols[0] + 1
        dark_run[i] = longest_run(row & (lum[y0 + i] < DARK))
    return {"h": h, "y0": y0, "y1": y1, "width": width / h, "dark": dark_run / h}


def zone(p, a, b):
    h = p["h"]
    i0, i1 = int(round(a * h)), int(round(b * h))
    return slice(i0, max(i1, i0 + 1))


def measure(front: dict, side: dict) -> dict:
    m = {}
    dark = front["dark"]
    h = front["h"]
    rows = np.where(dark >= 0.12)[0]
    if len(rows):
        start = rows[0]
        end = start
        while end + 1 < len(dark) and dark[end + 1] >= 0.12:
            end += 1
        # kleine Luecken von bis zu 2 Zeilen schliessen
        j = end + 1
        while j < len(dark) and j <= end + 3:
            if dark[j] >= 0.12:
                end = j
                while end + 1 < len(dark) and dark[end + 1] >= 0.12:
                    end += 1
            j += 1
        m["K1_start"] = float(start / h)
        m["K1_end"] = float((end + 1) / h)
        m["K2"] = float(dark[start:end + 1].max())
    else:
        m["K1_start"] = m["K1_end"] = m["K2"] = None
    m["K3"] = float(dark[zone(front, 0.0, 0.14)].max())
    m["K4"] = float(front["width"][zone(front, 0.03, 0.22)].max())
    m["K5"] = float(front["width"][zone(front, 0.20, 0.32)].min())
    m["K6"] = float(front["width"][zone(front, 0.26, 0.30)].mean())
    m["K7"] = float(side["width"][zone(side, 0.03, 0.25)].max())
    m["K8"] = float(side["width"][zone(side, 0.22, 0.30)].min())
    return m


def judge(m: dict) -> dict:
    ok = {}
    s, e = m["K1_start"], m["K1_end"]
    ok["K1"] = s is not None and 0.15 <= s <= 0.19 and 0.19 <= e <= 0.24
    ok["K2"] = m["K2"] is not None and 0.16 <= m["K2"] <= 0.23
    ok["K3"] = m["K3"] <= 0.03
    ok["K4"] = 0.29 <= m["K4"] <= 0.33
    ok["K5"] = m["K5"] >= 0.24
    ok["K6"] = 0.27 <= m["K6"] <= 0.34
    ok["K7"] = 0.304 <= m["K7"] <= 0.334
    ok["K8"] = m["K8"] >= 0.25
    return {k: bool(v) for k, v in ok.items()}


def fmt(m, key):
    if key == "K1":
        if m["K1_start"] is None:
            return "kein Visier"
        return "%.1f-%.1f %%" % (m["K1_start"] * 100, m["K1_end"] * 100)
    return "kein Visier" if m[key] is None else "%.3f H" % m[key]


def measure_sheet():
    sheet = Image.open(SHEET)
    return measure(profile(sheet, FRONT_X, SHEET_Y), profile(sheet, SIDE_X, SHEET_Y))


def measure_render(folder: Path):
    return measure(profile(Image.open(folder / "vorne.png")), profile(Image.open(folder / "seite.png")))


def crop_figure(img: Image.Image, pad=12, xs=None, ys=None) -> Image.Image:
    arr, bg = load_region(img, xs, ys)
    sil = silhouette(arr, bg)
    rows = np.where(sil.any(axis=1))[0]
    cols = np.where(sil.any(axis=0))[0]
    x0 = (xs[0] if xs else 0) + int(cols[0]) - pad
    x1 = (xs[0] if xs else 0) + int(cols[-1]) + 1 + pad
    y0 = (ys[0] if ys else 0) + int(rows[0]) - pad
    y1 = (ys[0] if ys else 0) + int(rows[-1]) + 1 + pad
    return img.convert("RGB").crop((max(x0, 0), max(y0, 0), min(x1, img.width), min(y1, img.height)))


def head_crop(img: Image.Image, xs=None, ys=None, h_target=800, frac=0.35, margin=0.40) -> Image.Image:
    """Kopfzone (0 bis frac von H oben) mit Figurenhoehe auf h_target skaliert (entspricht vierfach bei H = 200)."""
    p = profile(img, xs, ys)
    arr, bg = load_region(img, xs, ys)
    sil = silhouette(arr, bg)
    ox = xs[0] if xs else 0
    oy = ys[0] if ys else 0
    ytop, ybot = oy + p["y0"], oy + p["y0"] + int(p["h"] * frac)
    cols = np.where(sil[p["y0"]:p["y0"] + int(p["h"] * frac)].any(axis=0))[0]
    cx0, cx1 = ox + int(cols[0]), ox + int(cols[-1]) + 1
    pad = int(p["h"] * 0.03)
    box = (max(cx0 - pad, 0), max(ytop - pad, 0), min(cx1 + pad, img.width), min(ybot + pad, img.height))
    crop = img.convert("RGB").crop(box)
    k = h_target / p["h"]
    return crop.resize((int(crop.width * k), int(crop.height * k)), Image.LANCZOS)


def row_of(images, bg=(204, 204, 204), gap=16):
    w = sum(i.width for i in images) + gap * (len(images) + 1)
    h = max(i.height for i in images) + 2 * gap
    out = Image.new("RGB", (w, h), bg)
    x = gap
    for i in images:
        out.paste(i, (x, (h - i.height) // 2))
        x += i.width + gap
    return out


def build_vergleich(folder: Path, out: Path):
    sheet = Image.open(SHEET).convert("RGB")
    top_w = 2000
    top = sheet.resize((top_w, int(sheet.height * top_w / sheet.width)), Image.LANCZOS)
    figs = [crop_figure(Image.open(folder / (n + ".png"))) for n in ("vorne", "hinten", "seite", "oben")]
    target = 470
    scaled = []
    for n, f in zip(("vorne", "hinten", "seite", "oben"), figs):
        if n == "oben":
            k = target * 0.62 / f.height
        else:
            k = target / f.height
        scaled.append(f.resize((int(f.width * k), int(f.height * k)), Image.LANCZOS))
    bottom = row_of(scaled)
    canvas = Image.new("RGB", (top_w, top.height + 520), (204, 204, 204))
    canvas.paste(top, (0, 0))
    # untere Reihe gleichmaessig auf vier Spalten verteilen
    cols = [top_w * 0.141, top_w * 0.393, top_w * 0.622, top_w * 0.868]
    for c, f in zip(cols, scaled):
        canvas.paste(f, (int(c - f.width / 2), top.height + 25 + (470 - f.height) // 2 + (0 if f.height > 400 else 60)))
    canvas.save(out, quality=88)


def build_helm_gross(folder: Path, out: Path):
    sheet = Image.open(SHEET)
    panels = [
        head_crop(sheet, FRONT_X, SHEET_Y), head_crop(Image.open(folder / "vorne.png")),
        head_crop(sheet, SIDE_X, SHEET_Y), head_crop(Image.open(folder / "seite.png")),
    ]
    row_of(panels).save(out, quality=88)


def helm3(old: Path, new: Path, out: Path, newer: Path = None):
    sheet = Image.open(SHEET)
    rows = []
    for name, xs in (("vorne", FRONT_X), ("seite", SIDE_X)):
        cols = [head_crop(sheet, xs, SHEET_Y), head_crop(Image.open(old / (name + ".png"))),
                head_crop(Image.open(new / (name + ".png")))]
        if newer is not None:
            cols.append(head_crop(Image.open(newer / (name + ".png"))))
        rows.append(row_of(cols))
    w = max(r.width for r in rows)
    canvas = Image.new("RGB", (w, sum(r.height for r in rows)), (204, 204, 204))
    y = 0
    for r in rows:
        canvas.paste(r, (0, y))
        y += r.height
    canvas.save(out, quality=85)


def extra(folders, out: Path):
    shots = [Image.open(Path(f) / "spielmassstab.png").convert("RGB") for f in folders]
    crops = []
    for s in shots:
        cx, cy = s.width // 2, s.height // 2
        crops.append(s.crop((cx - 40, cy - 50, cx + 40, cy + 50)))
    one = row_of(crops, bg=(204, 204, 204), gap=10)
    big = row_of([c.resize((c.width * 4, c.height * 4), Image.NEAREST) for c in crops], gap=10)
    canvas = Image.new("RGB", (max(one.width, big.width), one.height + big.height + 40), (30, 30, 30))
    d = ImageDraw.Draw(canvas)
    d.text((10, 6), "1:1 Spielmassstab, Figur ca. 70 px (Kamera Yaw 45 / Pitch 40): leicht | mittel | schwer R10, mit Gewehr, Idle 0.2 s", fill=(220, 220, 220))
    canvas.paste(one, (0, 22))
    d.text((10, one.height + 26), "4x (nearest)", fill=(220, 220, 220))
    canvas.paste(big, (0, one.height + 40))
    canvas.save(out, quality=85)


def main():
    if len(sys.argv) > 1 and sys.argv[1] == "helm3":
        if len(sys.argv) > 5:
            helm3(Path(sys.argv[2]), Path(sys.argv[3]), Path(sys.argv[5]), Path(sys.argv[4]))
        else:
            helm3(Path(sys.argv[2]), Path(sys.argv[3]), Path(sys.argv[4]))
        return
    if len(sys.argv) > 1 and sys.argv[1] == "extra":
        extra(sys.argv[2:5], Path(sys.argv[5]))
        return
    folder, out = Path(sys.argv[1]), Path(sys.argv[2])
    out.mkdir(parents=True, exist_ok=True)
    sheet_m = measure_sheet()
    render_m = measure_render(folder)
    sheet_ok, render_ok = judge(sheet_m), judge(render_m)
    result = {"bogen": sheet_m, "render": render_m, "bogen_ok": sheet_ok, "render_ok": render_ok}
    (out / "messung.json").write_text(json.dumps(result, indent=1), encoding="utf-8")
    print("%-4s %-14s %-14s %s" % ("Mass", "Bogen", "Render", "Render ok"))
    for k in ("K1", "K2", "K3", "K4", "K5", "K6", "K7", "K8"):
        print("%-4s %-14s %-14s %s%s" % (k, fmt(sheet_m, k), fmt(render_m, k), "ok" if render_ok[k] else "verfehlt",
                                         "" if sheet_ok[k] else "   (BOGEN VERFEHLT, Messskript pruefen)"))
    build_vergleich(folder, out / "vergleich.jpg")
    build_helm_gross(folder, out / "helm_gross.jpg")


if __name__ == "__main__":
    main()
