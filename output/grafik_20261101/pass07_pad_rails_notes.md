# P07 pad rail endpoint correction

Only `scripts/terrain/frontier_outpost_pad.gd::_ramp` rail placement changed.
The ramp's actual horizontal span is 1.01 m (the existing 0.05 m deck overlap
plus 0.96 m exterior run), with a 0.146 m drop. Rails now derive their 3D length
(1.0204979 m), midpoint Y (0.087 m), X midpoint and signed slope (8.225 degrees)
from those existing ramp endpoints. Width, height, material, deck, ramp face,
returned reservation and pivot remain unchanged.

Frozen runtime SHA256:
`1301ddd9ddf8b17490615ab5bb50419d0e05b58f958586dae658e81209679772`.
Before snapshot SHA256:
`0f2ac2200330f473c1fcd2fa3c57ef779a530f55c0d9c62991ba5713b24805b2`.

`probe_pass07_pad_rails_verifier.gd` produced **56 passed / 0 failed** on Godot
4.6.2 official, marker `FRONTIER_PASS07_PAD_RAILS`. Both real pad sizes and their
mirrored access sides were checked. Rail centerline endpoint errors are below
0.00001 m. All other mesh vertex/normal arrays, returned reservations and pivots
compare equal to the before builder. Box transforms are finite. As an ordinary
tilted 14 mm box, a rail's corner projects about 1.001 mm beyond its centerline
end; this is bounded by half-thickness*sin(slope), not a longer rail run or a
changed navigation reservation. See `pass07_pad_rails_report.json`.

`probe_pass07_pad_rails_native.gd` produced eight isolated Forward+/Vulkan PNGs
(RTX 4070 Ti SUPER, 1600x900), marker `FRONTIER_PASS07_PAD_RAILS_NATIVE`, without
script/runtime errors. All eight were actually opened: east/west access,
join-detail/game-distance, before/after. Cameras, ground, light and materials
match within each pair. The previously short upper rail ends now reach their
corresponding deck-overlap ends; no new gross inverted/floating rail defect is
visible. See `pass07_pad_rails_native.json` and
`pass07_pad_rails_{east,west}_{join,game}_{before,after}.png`.

These are isolated pad proofs. The existing thin ramp face/toe-ground gap and
path-to-ramp height/width transition are not redesigned here; Root owns their
fresh path integration check. No map, movement, collision or gameplay facts
were changed. No Godot editor/import pass or Git command was run for this fix.

Reproduce structural QA with:
`godot_console.exe --headless --path <project> --script res://output/grafik_20261101/probe_pass07_pad_rails_verifier.gd`.
Reproduce native pairs with the same command using
`res://output/grafik_20261101/probe_pass07_pad_rails_native.gd` and replacing
`--headless` with `--rendering-driver vulkan --rendering-method forward_plus
--resolution 1600x900`.
