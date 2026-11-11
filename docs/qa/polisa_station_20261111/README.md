# Polisa candidate / bounded evidence

Godot 4.6.2. Source scope and hashes: `source_manifest.json` (24 files).

- `compile.log`: check-only of 15 changed GDScripts, each exit0.
- `domain.log`: 18 checks: strategic/location definitions, trusted extra-pad
  departure, legacy two-ship checkpoint and economy migration, idempotent pad/ship
  receipts, three-ship checkpoint, serialized capacity, invalid receipt/ID rejection,
  authored marker transform, cold station primitives and menu projection.
- `map_data.json`: simple hex-neighbor flood fill: all807 walkable tiles connected,
  all three pad centers reachable from the service hall. Declared grid96x96,
  actual deck867 tiles. No A/B/C sizing change.

Run fixture (read-only source checkpoint; its SHA is not changed):
`godot_console.exe --headless --path . --script res://scripts/tests/polisa_station_domain_test.gd -- <existing two-ship checkpoint.json>`

Private APPDATA for recorded run:
`output/native_glut_maps/profiles/polisa_domain`.
The fixture deliberately funds only its disposable domain owner and stubs fleet/
construction fulfillment; this proves persistence and receipts, not actual native
boarding, construction collision, merchant Use, equipment effects or ship flight.

Still requires later native gameplay acceptance: home->Polisa->home with real
pilot/boarding/fuel, counter Use, inventory and equipment actor projection, credit/
cargo buy/sell, paid home pad construction, ship delivery/assignment/launch, save/
continue with bought ships. No FPS, combat, broad regression or EXE claim.
Root may separately inspect the frozen station art in a small native view.
Prices are initial balance values. Local station pickup and functional ship
component equipment remain explicit scope limits.

Root opened native_initial_station.png: small native art view exit0/noerrors,
not a travel/shop gameplay proof. A separate creative visual revision follows;
this initial image preserves the first functional layout.
