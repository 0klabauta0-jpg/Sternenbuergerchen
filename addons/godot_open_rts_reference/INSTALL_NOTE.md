# godot-open-rts Reference Intake

Source: https://github.com/lampe-games/godot-open-rts
Commit: `a628ad3`

`godot-open-rts` is an upstream Godot 4.3 sample project, not a Godot EditorPlugin addon. Its scenes and scripts reference root-level paths such as `res://source/...` and `res://assets/...`.

This directory is therefore kept as an inactive reference package with `.gdignore`. The upstream project file is stored as `project.godot.reference` so the main Godot project does not detect a nested project during filesystem scans. Do not rename it back to `project.godot`, enable it, or move its files into the project root without a separate integration task.
