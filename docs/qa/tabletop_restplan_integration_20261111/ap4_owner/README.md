# AP4 Ownerintegration: begrenzter gemeinsamer Nachweis

Gezielt e8088870b und21779cbaf uebernommen als c69269578 und8eabf50cd. Root besitzt bereits30840746c sowie4753975d8/472f1ad8f; deren Cherrykopien aus dem Quellchat wurden nicht erneut uebernommen.

Unabhaengiger Readonly-Integrationsreview fand genau einen Blocker: Ownerpruning uebergibt sparse Segmentschedules an den Planerhelper; direkter schedules[id]-Zugriff scheiterte nach dem letzten Ausstiegssegment. Quellchat reproduzierte den Enginefehler trotz36 bestandener Assertions und lieferte21779cbaf mit schedules.get(id,[]) und echter Ausstiegsfixture. Quell-GREEN36/0, Runner ohne Scriptfehler. Root hat nur den engen Patch und dessen Einbindung gelesen, keine grosse Matrix wiederholt.

Zusammenfuehrung: nur .gitattributes-Appendkonflikt, Stations- und Owner-Evidenzattribute beide erhalten. Root/GroundRuntime/Pathfinder im gemeinsamen Stand frisch check-only Exit0, keine Scriptfehler; Logs daneben. Terrainv3/H+.5 und Authoring-Endpunktregeln bleiben erhalten. Registry-gepruefter Runtime-Step beruecksichtigt beidseitige Walkabilityoverrides, etwa fuer offene Tueren.

Grenze: keine Actorbewegung oder Kartenaktivierung. AP5 und vollstaendige persistente Korridorcacheanbindung folgen weiter im Tabletop-Chat. Dies ist kein nativer Gefechts-, FPS-, Save- oder Multiplayernachweis. Polisa-Portalvisuals sind offene statische Durchgaenge mit Terrainblockern, keine neue Tuerzustandswahrheit.
