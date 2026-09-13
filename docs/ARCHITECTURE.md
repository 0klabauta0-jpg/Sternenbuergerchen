# Architektur und Schnittstellen

## Aktueller Vertrag: Schema4

[contracts/N4_CREW_TRAVEL.md](contracts/N4_CREW_TRAVEL.md) definiert Crew-/Sitzbindung, explizite Reise, gemeinsame Kooprechte, Ausrüstung, persönliche Container und Migration. Boden-/Wirtschaftsregeln aus [N3_GROUND.md](contracts/N3_GROUND.md) und Orbitgrundlagen aus [N2_ORBIT.md](contracts/N2_ORBIT.md) gelten nur, soweit N4 sie nicht ersetzt. Ältere Host-/Gast-Rollentrennung, automatisches Boarding und alte Reiseankünfte sind keine aktuellen Regeln. Prüfstand: [IMPLEMENTATION_STATUS.md](IMPLEMENTATION_STATUS.md).

## Autoritativer Kern und Module

`scripts/core/simulation_root.gd` (`RestartSimulation`, Node) ist die einzige autoritative Mutationsstelle. Es gibt keine Gameplay-Autoloads. UI, Welt und Gast besitzen keine eigene Simulation der bestätigten Welt.

- `snapshot() -> Dictionary`: tiefe JSON-kompatible Kopie; aktuelle `schema_version=4`.
- `submit(command, sender_id=1) -> Dictionary`: `{ok,reason,request_id}`. Jeder Command benötigt `type` und eine eindeutige `request_id`. Wiederholungen einschließlich Ablehnungen liefern denselben gespeicherten Beleg für denselben Absender.
- `advance(delta)`: autoritative Zeit; im Produkt durch den Physiktakt, in isolierten Proben durch echte Zeitfortschritte. `auto_tick` steuert nur den Takt.
- `save_game(path)`, `load_game(path)`: validierte versionierte Daten mit atomarem Dateiaustausch. Laden erzeugt eine Revision größer als vorheriger Live- und geladener Stand, sodass pausierte Clients den Restore erhalten.
- `set_guest(peer_id)`, `clear_guest()`: Sitzungsmitgliedschaft und Reconnect; Abbruch pausiert. Host und bestätigter Gast dürfen alle vorhandenen Figuren und gemeinsamen Gameplaybefehle steuern. `owner` ist Herkunfts-/Anzeigeinformation. Unbekannte Absender bleiben gesperrt; lokale Dateien und Sitzungsverwaltung liegen beim Host.
- Signale `state_changed` und `notice(message)` liefern Änderungs- und Fehlerrückmeldung.

`crew_travel.gd` reserviert Sitze und führt Boarding, Start, Orbit, Reise und Ankunft aus. `equipment_operations.gd` verbucht Ausrüstung, persönliche Transfers und Medgunaktionen atomar; `equipment_catalog.gd` besitzt Slotzuordnung, neue Items und Rezepte. `ground_operations.gd` führt Bodenkampf, Gewinnung, Aufzug, Genesung und Miete aus. `orbit_operations.gd` führt lokalen Flug, Radar und Raumkampf aus. Alle arbeiten am autoritativen Zustand, keine UI errechnet Geld, Schaden oder Arbeitserfolg.

## Snapshot, Navigation und Darstellung

Der Snapshot enthält Zeit/Pause/Revision, aktive Region, Credits, Basislager `inventory`, gemeinsame `cargo`, Rezepte, Auftrag, Arbeits-/Bergungs-/Reisebindungen, Ressourcen, Gegner und Miete. Die Crew enthält Fähigkeiten, Gesundheit, Tätigkeit, Position/Ziel sowie fünf Ausrüstungsslots und `backpack:{capacity,items}`. `ship.seats` führt Pilot, Gunner und zwei Passagierplätze; `ship.roles` folgt den tatsächlich reservierten Crew-IDs. `boarding` bedeutet Anmarsch, `aboard` tatsächliche Ankunft am Zugang. `ship.yaw` und `turret_yaw` sind autoritative Y-Winkel. Vollständige Felder und IDs stehen im N4-Vertrag.

Positionen sind Welt-XZ als Zahlenarrays, Flug bleibt planar. `catalog.gd` delegiert Grenzen, Räume, Landmarken und statische Hindernisse an `world_layout.gd`. Der Kern und Renderer verwenden dieselben Möbel-, Wand-, Fels- und gelandeten Schiffsumrisse. `Catalog.ship_profile(model)` definiert Größe/Zugang/Turm, `ship_access(ship)` den echten Weltzugang. `ground_navigation.gd` prüft Wege, Schusslinien und Landestellen einschließlich Ausstiegsraum. Interaktionspunkte liegen außerhalb der Objekte. Navigation nutzt räumlichen Index und gecachte Pfade; Laufpfad-Caches gehören weder in Snapshot noch Save. Figuren blockieren sich noch nicht als vollständige gegenseitige Kollisionsphysik.

Es wird genau eine aktive Region dargestellt und simuliert: base, rust, station, orbit, space, bunker_surface, bunker_depths, distribution oder tradepost. Alle Crewmitglieder wechseln gemeinsam. Transparente Frontwände sind eine Darstellungsentscheidung, keine aufgehobenen Navigationshindernisse. Vier Sitzplätze abstrahieren den Schiffsbetrieb; begehbare Schiffsinnenräume sind ausdrücklich der nächste Ausbau.

## Aktueller Befehlsweg

`board {unit_id,role}` weist einen manuellen Platz zu; fehlendes role/auto und `board_crew {unit_ids}` wählen freie Rollen nach Fähigkeiten. Bestehende Plätze bleiben reserviert, Gruppenbuchung ist atomar. `cancel_board` und `disembark` sind getrennte Befehle. `launch` erfordert Pilot und gesamte Crew tatsächlich an Bord. Danach: lokales `ship_move`, `enter_orbit`, `travel {destination}`, schwebende Ankunft, `land`, `disembark`. Automatisches Einsammeln/Aussteigen/Entladen findet nicht statt. Ein einmal gespeicherter Reisewurf entscheidet Kontakte; Clients würfeln keinen Kampf. Sitzrollen hängen an Figuren, nicht an Commander oder festen Namen.

`equip_item`, `unequip_item` und `backpack_transfer` prüfen tatsächliche Quelle/Ziel, Slot, Nähe und Kapazität. Einheiten belegen je einen Rucksackplatz; acht Plätze existieren nur bei ausgerüstetem Rucksack. Ausrüstungswechsel legt vorhandene Ware zurück, statt sie zu ersetzen. Medgun ist ein Werkzeug und verbraucht eine reale Ladung aus dem persönlichen Rucksack. Direkter `transfer` zwischen Lager und Fracht bleibt ein ausdrücklich geprüfter Heimatdockweg. Herstellung, Handel, Auftrag und neue Gewinnung bleiben normale Commands; ihre Voraussetzungen stehen im Katalog/Kernvertrag.

Pause hält Bewegung, Reise, Arbeit, Kampf, Genesung und Mietzeit an; UI und Netzkommunikation laufen weiter. Ob ein Auftrag im pausierten Zustand vorbereitet werden darf, entscheidet dessen Kernprüfung. Gemeinsame Befehlsrechte schaffen kein PvP.

## UI und Netz

`scripts/game.gd` verbindet `game_hud.gd`, Welt, Simulation und Session. `world_view.gd` projiziert Snapshots und sendet IDs, Gruppenwahl und XZ-Ziele. `ground_clicked` erzeugt normale move-/ship_move-Aufträge. WASD/Pfeile bewegen ausschließlich die Kamera; Einzelansicht bedeutet Kamerafolge. Es gibt keinen parallelen Richtungs-RPC oder gespeicherten Tastenstatus.

`boarding_menu.gd` sendet Platzwünsche, `ship_context.gd` zeigt Bindungen und Aktionen, `expedition_hud.gd` Flug/Radar/Kontakte und `travel_chart.gd` benannte Reisezielwahl. `crew_dossier.gd` verwendet den echten Astronauten im privaten Viewport; Slots und Container senden nur `action_requested`. `present_result` zeigt ausstehende Gastanfragen als wartend und erst den tatsächlichen Hostbeleg als bestätigt. Snapshots werden im Dossier nicht mutiert.

`session_gateway.gd` vermittelt unveränderte Commands über ENet/LAN oder WSS. Der Absender stammt ausschließlich aus der Verbindung. Internetauthentifizierung prüft Schlüssel, Protokoll und tatsächliches Snapshot-Schema vor Freigabe. Der DNS-/TLS-Ersatzweg behält Zertifikats-/Hostnamenprüfung. Disconnect und direkte Node-Freigabe räumen eigene Authentifizierung, Peer und Helfer auf. [INTERNET_COOP.md](INTERNET_COOP.md) beschreibt temporäre Einladungen und Betriebsgrenzen.

## Save-Migration und historische Formate

Eingefrorene `legacy_validator_v1/v2/v3.gd` und passende historische Kataloge prüfen alte Daten vor der Kette v1→v2→v3→v4. `stage_state.gd`/`ground_state.gd` erhalten ihre historischen Erweiterungsschritte; `crew_state.gd` ergänzt und migriert N4, `crew_validator.gd` prüft Sitz- und Containerbindungen. Geld, Gegenstände, Reservierungen, Unlocks und alte Anfragebelege bleiben erhalten. Alte aktive Gewinnung darf nach ihrem bisherigen Vertrag fertig werden; neue Aufträge benötigen N4-Ausrüstung. Neue Hindernisse können räumliche Korrekturen verlangen; diese werden geloggt. Ein beschädigter Save wird nicht still durch eine neue Karriere ersetzt.

N1 besaß nur drei Regionen und keinen Hindernis-/Bodenkampf. N2 ergänzte Räume/Radar/Raumkontakt; N3 Boden, Ausrüstung und Internet. Ihre damaligen Abnahmen bleiben historische Dokumente. Der aktuelle Laufzeitvertrag ist ausschließlich Schema4.
