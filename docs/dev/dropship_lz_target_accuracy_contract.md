# Dropship LZ Target Accuracy Contract

Status: implemented by TASK_311.

The commander command keeps target and landing truth separate:

- `requested_lz_position` / `target_lz_position`
- `resolved_lz_position` / `actual_landing_position`
- `landing_deviation`
- `lz_accuracy_radius`
- `multiplayer_authority = server_resolved_lz`

Pilot and team skill reduce the V1 deviation radius. The requested LZ remains visible as the command target; the resolved LZ becomes visible once calculated.
