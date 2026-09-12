# Modelle und Herkunft

Kenney-Umgebung und weißer Astronaut stammen aus der lokalen All-in-1-Sammlung 3.4.0. Originaldateien wurden nicht geändert. Ausgewählte CC0-Dateien und Lizenzkopien liegen unter `assets/curated` und `assets/licenses`; Details in `assets/credits.md`.

Der weiße Astronaut verwendet characterMedium, astroMaleA und astroHelmet aus dem Animated Characters Bundle. `tools/prepare_crew.py` passt Helm und ursprüngliche Idle-/Walk-/Work-Animationen an. Die editierbare, gepackte Blenderdatei liegt in `assets/curated/crew/source`; Godot lädt das fertige GLB. Das Crewporträt wurde daraus in Blender gerendert (`tools/render_crew_portrait.py`). Die UI-Symbole in `scripts/ui/hud_icons.gd` sind eigene SVG-Linienzeichnungen.

## Lokales Startshuttle

Quelle: vom Nutzer bereitgestellte Datei `C:\Users\bjoer\3D Objects\drive-download-20250521T120706Z-1-001\DRAKE\DRAKE-CUTLASS.obj`.

`tools/prepare_shuttle.py` erstellt mit Blender 5.1.1 die lokale Entersäbel: 265.435 ursprüngliche Dreiecke → 17.879 Dreiecke, vier Materialien, GLB circa 1,39 MB. Export und gespeicherte Blenderdatei wurden erneut geladen und geprüft. Godot-Achsen: +Y oben, −Z vorne; Unterkante Y=0. Die Ursprungsdatei blieb unverändert (SHA-256 `8c9998b2d29b359a63ab9b72b6f7065fbf9ed63068b5856d7f09376035eb8a60`).

Ausführen: `& 'C:\Program Files\Blender Foundation\Blender 5.1\blender.exe' --background --factory-startup --python tools/prepare_shuttle.py` aus dem Projektordner. Das Script enthält den autorisierten lokalen Quellpfad; Ausgabe ist `assets/local/` mit `entersaebel.glb`, `.blend`, `preview.png` und `metrics.json`.

Dieses bereitgestellte Modell ist ein lokales Derivat, kein selbst entworfenes oder als CC0 ausgegebenes Schiff. Die Konvertierung und Umbenennung behaupten keine Veröffentlichungslizenz. Deshalb bleibt `assets/local/` Git-ignoriert; der Code verwendet ohne lokale Datei das mitgelieferte Kenney-Shuttle.
