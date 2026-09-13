# Architektur und Schnittstellen

## Aktuelle Verträge: Schema v3, Boden und Internet

[contracts/N3_GROUND.md](contracts/N3_GROUND.md) definiert aktuelle Regionen, IDs, Commands, Ressourcen, Rüstung, Miete und Kampf. [N3_SKILLS_MENU.md](N3_SKILLS_MENU.md) erklärt die tatsächlichen Charakterwirkungen; [INTERNET_COOP.md](INTERNET_COOP.md) den Internet-Gateway. Die v2-Ergänzungen aus [N2_ORBIT.md](contracts/N2_ORBIT.md) bleiben Grundlage, soweit v3 sie nicht ausdrücklich erweitert. Gesamtprüfung: [N3_ACCEPTANCE.md](N3_ACCEPTANCE.md).

`SimulationRoot` ist die einzige autoritative Mutationsstelle. `ground_operations.gd` führt Bodenkampf, Gewinnung, Aufzug, Genesung und Mietzeit aus; `ground_state.gd` ergänzt v3 und migriert validierte v2-Daten. `orbit_operations.gd` führt Flug/Radar/Raumkampf aus. Der aktuelle Validator prüft v3 einschließlich Gesundheit, Bindungen, Ressourcen und Mietschiff. Eingefrorene `legacy_validator_v1/v2.gd` und zugehörige Kataloge prüfen Altformate vor der Kette v1→v2→v3. `stage_state.gd` verwendet dabei bewusst den eingefrorenen v2-Katalog. Karriere, Arbeitsreservierungen und Anfragebelege bleiben erhalten.

`Catalog` besitzt Karten-/Raumpositionen und gemeinsame Hindernisrechtecke aus `ground_catalog.gd`. `ground_navigation.gd` berechnet Laufwege mit 0,6 m Abstand und prüft gerade Schusslinien gegen diese Rechtecke. Der Renderer stellt dieselben Rechtecke dar und baut nur die bestätigte aktive Region: base, rust, station, space, bunker_surface, bunker_depths, distribution oder tradepost. Transparente Frontwände sind ausschließlich Darstellung. Sonstige Landschaftsdekoration und gegenseitige Figuren-/Schiffskollision gehören noch nicht zur Autoritätsnavigation.

UI und Welt senden ausschließlich Befehle über `session_gateway.gd` und lesen Snapshots. Der Gateway verwendet wahlweise ENet/LAN oder WebSocket über einen temporären eigenen Cloudflare-Tunnel. Internetauthentifizierung prüft Einladung, Protokoll und Snapshot-Schema vor Peerfreigabe; danach stammen Absenderrechte ausschließlich aus der Verbindung. DNS-/TLS-Ersatzweg behält die Zertifikatsprüfung bei. Expliziter Disconnect und direkte Session-Freigabe räumen Authentifizierung, Peer und eigene Helfer auf. Die Simulation bleibt unabhängig vom Transport.

Host würfelt Raumkontakte einmalig und speichert den Wurf; Clients würfeln weder Begegnungen noch Schaden. Besitz bestimmt Arbeiter und Bodenschützen. Ida fliegt, Jaro bedient den Turm. Rüstung, Werkzeuge und drei Fähigkeiten haben die im Katalog abgeleiteten Wirkungen; es gibt noch keine XP-, Trait- oder PvP-Regeln. Pause hält auch Kampf, Genesung und Mietzeit an; Netzwerk/Oberfläche laufen weiter.

## Basis-API und historischer v1-Vertrag

Die folgende Basis-API bleibt erhalten. Der dargestellte v1-Snapshot und ursprüngliche Rezept-/Regionenkatalog dokumentieren das Altformat; Erweiterungen und aktuell gültige Felder stehen in den aktuellen Verträgen oben.

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

Commands: `move {unit_id,position:[x,z]}`, `accept_contract`, `assign_work {unit_id,recipe_id}`, `cancel_work`, `travel {destination}`, `salvage {unit_id}`, `cancel_salvage`, `claim_contract`, `trade {side:buy|sell,item,amount:int}`, `transfer {item,amount:int,direction:load|unload}` (Basis, Host), `toggle_pause`. Rezept-IDs `toolkit`, `repair`, `cutter`. Senderprüfung gilt auch für indirekte Zuweisungen. Besitz und Arbeitsbindung werden zentral geprüft. Pause stoppt Reise, Bewegung, Bergung und Crafting; Netzwerk/Oberfläche bleiben aktiv.

`scripts/world/world_view.gd` extends Node3D; class_name RestartWorld. API `present(snapshot:Dictionary)`, `focus_unit(unit_id:String)`, `focus_home()`; Signale `object_selected(kind:String,id:String)` und `ground_clicked(position:Vector2)`. Baut sichtbare Karten/Kamera, NPC-Modelle, Kenney-Objekte; Snapshot bestimmt sichtbare Positionen. Klick trifft IDs, Boden-Rechtsklick liefert Wegziel. Kamera: WASD/Pfeile, Mausrad, mittlere Maus/Drag, Home. Welt besitzt keine Gameplay-Daten. Typen kind=`unit` oder `object`; id=crew/landmark IDs. Aktive Auswahl als optionale Methode `set_selection(kind,id)`.

`scripts/ui/game_hud.gd` extends CanvasLayer: zeigt Snapshot und sendet Commands; `scripts/game.gd` verbindet Welt, HUD, Simulation und Netzwerk. `scripts/network/session_gateway.gd` vermittelt dasselbe Commandformat, setzt Absender aus der Verbindung und überträgt Snapshots.

Historisches N1-Ruling: offener Boden mit nur visuellen Felsen, noch ohne Hindernisnavigation oder Kampf. N3 ersetzt diese Grenze für die gemeinsam katalogisierten Hindernisse und führt einfachen Kampf ein. Startwerte bleiben Balancevorschläge im Katalog.

Point-and-Click-Ergänzung: `RestartWorld.units_selected(ids:Array[String])`, `set_selected_units(ids)` und `set_control_mode(follow:bool,unit_id)` trennen Gruppenauswahl und Kamerafolge. `ground_clicked` gilt in beiden Ansichten. `scripts/game.gd` leitet pro gewählter eigener Figur einen normalen `move`-Command weiter; Gruppen erhalten versetzte Ziele. WASD beeinflusst ausschließlich die lokale Kamera. Es gibt keinen parallelen Richtungssteuerungs-RPC oder gespeicherten Tastenstatus.

Weltkamerafokus zusätzlich über `focus_object(id)`. Toolbar, Ziele und angeklickte Modelle adressieren dieselben Landmark-IDs. HUD-Icons und Porträts sind Darstellung; Material, Besitz, Arbeitsbindung, Credits und Mission werden unverändert im Kern geprüft.
