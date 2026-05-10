# Unified Meta Transit Progress Contract

Status: implemented by TASK_304.

Transit is represented by one shared entry per moving entity:

- `entity_id`, `entity_type`
- `source`, `destination`, `transport_id`
- `progress`, `eta_seconds`, `status`
- `ghost_on_source`, `ghost_on_destination`

UI may render source and destination ghost cards, but it must not calculate a second progress truth. Completed transit removes stale ghosts and turns the arrived entity back into the normal destination pool.
