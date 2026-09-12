# N0/N1-Schnittstellen

`scripts/core/simulation_root.gd` extends Node; class_name RestartSimulation. Einzige autoritative Mutationsstelle. Keine Autoloads. API:
- `snapshot() -> Dictionary` tiefe, JSON-kompatible Kopie.
- `submit(command: Dictionary, sender_id: int = 1) -> Dictionary` liefert `{ok: bool, reason: String, request_id: String}`; jeder Command hat `type` und eindeutige `request_id`. Falscher Absender, Wiederholung, fehlende Voraussetzungen sauber ablehnen bzw. idempotent beantworten.
- `advance(delta: float)` für autoritative Zeit; `_physics_process` ruft diese im Produkt auf. `auto_tick: bool = true` erlaubt gezielte Tests.
- `save_game(path: String) -> Dictionary`, `load_game(path: String) -> Dictionary`; validierte, versionierte Daten und atomarer Dateiaustausch.
- Signale `state_changed`, `notice(message: String)`.
- `set_guest(peer_id: int)` für kooperativen zweiten Platz; `clear_guest()` bei Abbruch. Solo darf Host beide NPCs führen; verbunden besitzt Host ida, Gast jaro. Reconnect vergibt denselben Gastplatz neu. Nur Host darf Sitzung/Pause/Speichern/Reise/Handel steuern. Das ist die erste veränderbare Koop-Regel, kein fertiges PvP-Regelwerk.

Snapshot-Vertrag (jede Schlüsselangabe verbindlich; Zusatzfelder zulässig):
```
schema_version:1, revision:int, time:float, paused:bool,
region:base|rust|station, credits:int,
inventory:{scrap:int,parts:int,toolkit:int,cutter:int,blackbox:int},
cargo:{scrap:int,parts:int,toolkit:int,cutter:int,blackbox:int},
blueprints:Array[String], ship:{condition:float,capacity:int},
crew:{ida:{id,name,skill:int,owner:int,position:[x,z],target:[x,z],assignment:String},jaro:{...}},
contract:{status:available|active|recovered|claimed, reward:int},
work:{active:bool,unit_id:String,recipe_id:String,remaining:float,total:float,phase:String},
salvage:{active:bool,unit_id:String,remaining:float,total:float},
travel:{active:bool,from:String,to:String,remaining:float,total:float,phase:String},
wreck_remaining:int, log:Array[String]
```
Alle Positionen sind Welt-x/z als Array; Ebene y gehört zur Darstellung. Kataloge in `scripts/core/catalog.gd` (class_name RestartCatalog): `static func recipes()->Dictionary`, `static func prices()->Dictionary`, `static func landmarks(region:String)->Dictionary`. Landmarken enthalten stationäre x/z-Arrays. Feste IDs: `workbench`, `storage`, `contracts`, `shuttle`, `market`, `satellite`, `bed_ida`, `bed_jaro`.

Commands: `move {unit_id,position:[x,z]}`, `accept_contract`, `assign_work {unit_id,recipe_id}`, `cancel_work`, `travel {destination}`, `salvage {unit_id}`, `cancel_salvage`, `claim_contract`, `trade {side:buy|sell,item,amount:int}`, `toggle_pause`. Rezept-IDs `toolkit`, `repair`, `cutter`. Senderprüfung gilt auch für indirekte Zuweisungen. Besitz und Arbeitsbindung werden zentral geprüft. Pause stoppt Reise, Bewegung, Bergung und Crafting; Netzwerk/Oberfläche bleiben aktiv.

`scripts/world/world_view.gd` extends Node3D; class_name RestartWorld. API `present(snapshot:Dictionary)`, `focus_unit(unit_id:String)`, `focus_home()`; Signale `object_selected(kind:String,id:String)` und `ground_clicked(position:Vector2)`. Baut sichtbare Karten/Kamera, NPC-Modelle, Kenney-Objekte; Snapshot bestimmt sichtbare Positionen. Klick trifft IDs, Boden-Rechtsklick liefert Wegziel. Kamera: WASD/Pfeile, Mausrad, mittlere Maus/Drag, Home. Welt besitzt keine Gameplay-Daten. Typen kind=`unit` oder `object`; id=crew/landmark IDs. Aktive Auswahl als optionale Methode `set_selection(kind,id)`.

`scripts/ui/game_hud.gd` extends CanvasLayer: zeigt Snapshot und sendet Commands; `scripts/game.gd` verbindet Welt, HUD, Simulation und später Netzwerk. `scripts/network/session_gateway.gd` vermittelt dasselbe Commandformat, setzt Absender aus der Verbindung und überträgt Snapshots.

Ruling: Primär datenbasierter offener Boden ohne begehbare Felsblockaden; Felsen begrenzen Wege sichtbar. Grenzen werden vom Kern geprüft. Keine scheinbare Deckungs-/Kampfmechanik vor N2. Startwerte bleiben Balancevorschläge im Katalog.

