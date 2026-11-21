"""Preserve native Tripo texels while sharing one BaseColor material.

Run only on an isolated asset copy. This module does not join meshes, change
geometry, change object transforms, or save a blend file. Blender is imported
inside atlas_materials(), so the deterministic rectangle packer can be tested
without starting Blender.

Byte-backed Blender Image.pixels contains normalized bytes, not necessarily
scene-linear samples. Use a byte-backed sRGB PNG and compare freshly decoded
PNG bytes against the source. Do not apply a manual gamma conversion or use
save_render(), which would involve render color management.
Sources: Blender source/blender/makesrna/intern/rna_image.cc (pixels get/set),
         source/blender/makesrna/intern/rna_image_api.cc (save/save_render).
"""
from __future__ import annotations

from pathlib import Path
import hashlib
import json
import math


def _contains(outer, inner):
    x, y, w, h = outer
    a, b, c, d = inner
    return x <= a and y <= b and a + c <= x + w and b + d <= y + h


def _pack_rectangles(rectangles, width, height):
    """No rotation/resizing: deterministic MaxRects best-short-side placement.

    rectangles is a sequence of (unique_key, width, height). Return key ->
    (x, y, width, height), or None when this layout cannot be packed.
    """
    if width <= 0 or height <= 0:
        raise ValueError('Atlas dimensions must be positive')
    if len({r[0] for r in rectangles}) != len(rectangles):
        raise ValueError('Rectangle keys must be unique')
    if any(r[1] <= 0 or r[2] <= 0 for r in rectangles):
        raise ValueError('Rectangle dimensions must be positive')
    free = [(0, 0, int(width), int(height))]
    placed = {}
    ordered = sorted(rectangles, key=lambda r: (-max(r[1], r[2]), -r[1]*r[2], str(r[0])))
    for key, rw, rh in ordered:
        fits = [
            (min(fw-rw, fh-rh), max(fw-rw, fh-rh), fy, fx, i)
            for i, (fx, fy, fw, fh) in enumerate(free) if rw <= fw and rh <= fh
        ]
        if not fits:
            return None
        _, _, _, _, index = min(fits)
        px, py = free[index][:2]
        taken = (px, py, rw, rh)
        placed[key] = taken
        split = []
        for fx, fy, fw, fh in free:
            if px >= fx+fw or px+rw <= fx or py >= fy+fh or py+rh <= fy:
                split.append((fx, fy, fw, fh))
                continue
            if px > fx:
                split.append((fx, fy, px-fx, fh))
            if px+rw < fx+fw:
                split.append((px+rw, fy, fx+fw-px-rw, fh))
            if py > fy:
                split.append((fx, fy, fw, py-fy))
            if py+rh < fy+fh:
                split.append((fx, py+rh, fw, fy+fh-py-rh))
        candidates = sorted(set(split))
        free = [r for i, r in enumerate(candidates)
                if not any(i != j and _contains(s, r) for j, s in enumerate(candidates))]
    return placed


def _plain(value):
    if isinstance(value, (str, bool, int, float)) or value is None:
        return value
    try:
        return [_plain(v) for v in value]
    except TypeError:
        raise ValueError(f'Unsupported shader socket default: {type(value).__name__}')


def _shader_signature(material):
    """Fail closed on unsupported shading graphs; ignore UI labels/layout only."""
    if not material.node_tree or material.animation_data or material.node_tree.animation_data:
        raise ValueError(f'{material.name}: missing shader nodes or animated material')
    supported = {'BSDF_PRINCIPLED', 'NORMAL_MAP', 'OUTPUT_MATERIAL', 'TEX_IMAGE'}
    nodes = list(material.node_tree.nodes)
    if len(nodes) != 4 or {n.type for n in nodes} != supported:
        raise ValueError(f'{material.name}: expected one node of each {sorted(supported)}')
    by_type = {n.type: n for n in nodes}
    texture = by_type['TEX_IMAGE']
    if not texture.image or texture.inputs['Vector'].is_linked:
        raise ValueError(f'{material.name}: missing image or non-default UV mapping')
    if texture.projection != 'FLAT':
        raise ValueError(f'{material.name}: atlas requires flat image projection')
    if by_type['NORMAL_MAP'].inputs['Color'].is_linked:
        raise ValueError(f'{material.name}: textured normal maps require a separate normal atlas')
    links = sorted((l.from_node.type, l.from_socket.identifier,
                    l.to_node.type, l.to_socket.identifier) for l in material.node_tree.links)
    if not any(l.from_node == texture and l.from_socket.name == 'Color'
               and l.to_node == by_type['BSDF_PRINCIPLED'] and l.to_socket.name == 'Base Color'
               for l in material.node_tree.links):
        raise ValueError(f'{material.name}: image is not the direct Base Color input')
    props = {}
    for prop in material.bl_rna.properties:
        if prop.is_readonly or prop.identifier in {'name', 'use_fake_user', 'use_nodes'}:
            continue
        if prop.type in {'BOOLEAN', 'INT', 'FLOAT', 'ENUM', 'STRING'}:
            props[prop.identifier] = _plain(getattr(material, prop.identifier))
    node_settings = {}
    for kind, node in by_type.items():
        settings = {'mute': node.mute, 'inputs': [
            (s.identifier, _plain(s.default_value)) for s in node.inputs
            if hasattr(s, 'default_value')
        ]}
        relevant = {
            'TEX_IMAGE': ('interpolation', 'projection', 'projection_blend', 'extension'),
            'NORMAL_MAP': ('space', 'uv_map'),
            'BSDF_PRINCIPLED': ('distribution', 'subsurface_method'),
            'OUTPUT_MATERIAL': ('target', 'is_active_output'),
        }[kind]
        settings.update({p: _plain(getattr(node, p)) for p in relevant if hasattr(node, p)})
        node_settings[kind] = settings
    return {'material': props, 'nodes': node_settings, 'links': links}, texture


def atlas_materials(objects, output_png: Path) -> dict:
    """Atlas compatible one-material meshes, preserving 82 independently editable parts.

    All validation and the PNG reload happen before UV/material mutation. Meshes
    must have unique datablocks and one active, finite, in-range UV layer. Images
    must be byte-backed sRGB FILE/GENERATED images. Geometry is never altered.
    The returned report describes native texel preservation, NOT mipmap-level
    filtering equivalence; inspect native renders at the intended game distance.
    """
    import bpy
    import numpy as np

    objects = sorted(list(objects), key=lambda o: o.name)
    output_png = Path(output_png).resolve()
    if not objects or output_png.suffix.lower() != '.png':
        raise ValueError('Non-empty mesh list and explicit PNG output required')
    records = []
    images = {}
    reference_signature = None
    original_materials = set()
    for obj in objects:
        if obj.type != 'MESH' or obj.data.users != 1:
            raise ValueError(f'{obj.name}: unique mesh datablock required')
        mesh = obj.data
        if len(mesh.materials) != 1 or mesh.materials[0] is None:
            raise ValueError(f'{obj.name}: exactly one assigned material required')
        if any(poly.material_index != 0 for poly in mesh.polygons):
            raise ValueError(f'{obj.name}: polygon references an unsupported material slot')
        material = mesh.materials[0]
        original_materials.add(material.name)
        signature, tex = _shader_signature(material)
        if reference_signature is None:
            reference_signature = signature
        elif signature != reference_signature:
            raise ValueError(f'{obj.name}/{material.name}: shader differs from first material')
        image = tex.image
        if image.is_float or image.colorspace_settings.name != 'sRGB':
            raise ValueError(f'{image.name}: expected byte-backed sRGB source; no implicit gamma conversion')
        if image.source not in {'FILE', 'GENERATED'} or not image.has_data:
            raise ValueError(f'{image.name}: expected a loaded still image')
        w, h = map(int, image.size)
        if min(w, h) <= 0 or len(image.pixels) != w*h*4:
            raise ValueError(f'{image.name}: missing RGBA pixels')
        uv_layer = mesh.uv_layers.active
        if uv_layer is None or len(uv_layer.data) != len(mesh.loops):
            raise ValueError(f'{obj.name}: missing or incomplete active UV map')
        normal_node = next(n for n in material.node_tree.nodes if n.type == 'NORMAL_MAP')
        if normal_node.uv_map and normal_node.uv_map != uv_layer.name:
            raise ValueError(f'{obj.name}: Normal Map uses a different UV layer')
        uv = np.empty(len(mesh.loops)*2, dtype=np.float32)
        uv_layer.data.foreach_get('uv', uv)
        uv = uv.reshape((-1, 2))
        if not np.isfinite(uv).all() or (uv < 0).any() or (uv > 1).any():
            raise ValueError(f'{obj.name}: atlas does not support out-of-range/repeating UVs')
        key = image.name
        if key not in images:
            pixels = np.empty(w*h*4, dtype=np.float32)
            image.pixels.foreach_get(pixels)
            pixels = pixels.reshape((h, w, 4))
            if not np.isfinite(pixels).all() or (pixels < 0).any() or (pixels > 1).any():
                raise ValueError(f'{image.name}: invalid byte image values')
            images[key] = {'image': image, 'w': w, 'h': h, 'pixels': pixels}
        records.append({'object': obj, 'material': material, 'uv_layer': uv_layer,
                        'uv': uv, 'image': key})

    padding = 4
    rects = [(key, item['w']+2*padding, item['h']+2*padding) for key, item in images.items()]
    placements = None
    for width, height in ((2048, 2048), (2048, 4096), (4096, 4096)):
        placements = _pack_rectangles(rects, width, height)
        if placements is not None:
            break
    if placements is None:
        raise ValueError('Native-resolution textures do not fit a 4096x4096 atlas')
    buffer = np.zeros((height, width, 4), dtype=np.float32)
    buffer[:, :, 3] = 1.0
    tile_report = []
    for key, item in images.items():
        x, y, rw, rh = placements[key]
        buffer[y:y+rh, x:x+rw] = np.pad(item['pixels'], ((padding, padding), (padding, padding), (0, 0)), mode='edge')
        tile_report.append({'source_image': key, 'x': x+padding, 'y': y+padding,
                            'width': item['w'], 'height': item['h']})
    pre_save_error = max(float(np.max(np.abs(
        buffer[t['y']:t['y']+t['height'], t['x']:t['x']+t['width']] - images[t['source_image']]['pixels']
    ))) for t in tile_report)
    if pre_save_error != 0:
        raise AssertionError('Packing changed source texel values')
    output_png.parent.mkdir(parents=True, exist_ok=True)
    atlas = bpy.data.images.new('T_Tanker_BaseColor_Atlas_Write', width=width, height=height,
                                alpha=True, float_buffer=False)
    reloaded = None
    try:
        atlas.colorspace_settings.name = 'sRGB'
        atlas.alpha_mode = 'STRAIGHT'
        atlas.pixels.foreach_set(buffer.ravel())
        atlas.update()
        atlas.filepath_raw = str(output_png)
        atlas.file_format = 'PNG'
        atlas.save()
        if not output_png.is_file() or not output_png.stat().st_size:
            raise RuntimeError('PNG export was not written')
        reloaded = bpy.data.images.load(str(output_png), check_existing=False)
        reloaded.colorspace_settings.name = 'sRGB'
        reloaded.alpha_mode = 'STRAIGHT'
        if reloaded.is_float or tuple(reloaded.size) != (width, height):
            raise AssertionError('Reloaded PNG buffer type or dimensions changed')
        reload_pixels = np.empty(width*height*4, dtype=np.float32)
        reloaded.pixels.foreach_get(reload_pixels)
        reload_pixels = reload_pixels.reshape((height, width, 4))
        max_error, max_byte_error = 0.0, 0
        for tile in tile_report:
            source = images[tile['source_image']]['pixels']
            x, y, w, h = (tile[p] for p in ('x', 'y', 'width', 'height'))
            decoded = reload_pixels[y:y+h, x:x+w]
            max_error = max(max_error, float(np.max(np.abs(decoded-source))))
            byte_error = np.abs(np.rint(decoded*255).astype(np.int16)-np.rint(source*255).astype(np.int16))
            max_byte_error = max(max_byte_error, int(byte_error.max()))
        if max_byte_error != 0 or max_error > 1e-6:
            raise AssertionError(f'PNG changed source texels: byte_error={max_byte_error}, float_error={max_error}')
        reloaded.name = 'T_Tanker_BaseColor_Atlas'
        reloaded.pack()
    except Exception:
        if reloaded is not None and reloaded.users == 0:
            bpy.data.images.remove(reloaded)
        raise
    finally:
        if atlas.users == 0:
            bpy.data.images.remove(atlas)

    shared_material = records[0]['material'].copy()
    shared_material.name = 'M_Tanker_Atlas'
    shared_texture = next(n for n in shared_material.node_tree.nodes if n.type == 'TEX_IMAGE')
    shared_texture.image = reloaded
    changed = []
    max_uv_roundtrip_error = 0.0
    try:
        for record in records:
            obj, uv = record['object'], record['uv']
            item = images[record['image']]
            x, y, _, _ = placements[record['image']]
            offset = np.array([x+padding, y+padding], dtype=np.float32)
            native_size = np.array([item['w'], item['h']], dtype=np.float32)
            atlas_size = np.array([width, height], dtype=np.float32)
            remapped = (uv*native_size+offset)/atlas_size
            recovered = (remapped*atlas_size-offset)/native_size
            max_uv_roundtrip_error = max(max_uv_roundtrip_error, float(np.abs(recovered-uv).max(initial=0.0)))
            changed.append(record)
            record['uv_layer'].data.foreach_set('uv', remapped.ravel())
            obj.data.materials[0] = shared_material
            obj.data.update()
    except Exception:
        for record in changed:
            record['uv_layer'].data.foreach_set('uv', record['uv'].ravel())
            record['object'].data.materials[0] = record['material']
            record['object'].data.update()
        if shared_material.users == 0:
            bpy.data.materials.remove(shared_material)
        raise
    return {
        'method': 'native_texel_maxrects_byte_srgb',
        'atlas_path': str(output_png), 'atlas_sha256': hashlib.sha256(output_png.read_bytes()).hexdigest(),
        'atlas_size': [width, height], 'padding_pixels': padding,
        'source_image_count': len(images), 'source_material_count': len(original_materials),
        'output_material_count': 1, 'mesh_count_preserved': len(objects),
        'source_texels': sum(i['w']*i['h'] for i in images.values()),
        'atlas_texels': width*height, 'source_texels_resampled': False,
        'max_pixel_error_before_png': pre_save_error,
        'max_pixel_error_after_png': max_error, 'max_byte_error_after_png': max_byte_error,
        'max_uv_inverse_error': max_uv_roundtrip_error,
        'shader_signature_sha256': hashlib.sha256(json.dumps(reference_signature, sort_keys=True).encode()).hexdigest(),
        'material_name': shared_material.name, 'image_name': reloaded.name,
        'tiles': sorted(tile_report, key=lambda t: t['source_image']),
        'filtering_limit': '4px edge extrusion; compare native renders, especially high mip levels and UV0/1 wrap edges',
    }
