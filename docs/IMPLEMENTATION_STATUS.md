# IMPLEMENTATION_STATUS

## Template
### Bereich
- Status:
- Stand:
- Offene Punkte:
- Risiken:
- Naechster Schritt:

## Aktueller Startzustand

### RuntimeLeader / FTL
- Status: implementiert
- Stand: `RuntimeLeader` als eigene `Node`-Komponente mit `class_name`, Signalen fuer Promotion, Demotion, Assignment und Command-Weitergabe sowie der API `promote()`, `demote()`, `assign(entity)` und `command(order)` eingefuehrt.
- Offene Punkte: keine FTL-Ausfuehrungslogik, keine Befehlsinterpretation, keine EventRouter- oder SimulationRoot-Anbindung, keine Szenenverdrahtung.
- Risiken: Signalvertraege und Zustandsbasis stehen, die spaetere Einbindung in autoritative Gameplay-Systeme muss konsistent bleiben.
- Naechster Schritt: RuntimeLeader an EventRouter und SimulationRoot anbinden, sobald die Folgesysteme implementiert sind.

### EventRouter
- Status: implementiert
- Stand: `EventRouter` als eigene `Node`-Komponente mit Signalen fuer Squad-Commands, Unit-Ausfaelle, Threat-Meldungen, Leader-Wechsel und Respawn-Anfragen sowie schlanken Routing-Methoden eingefuehrt.
- Offene Punkte: keine RuntimeLeader-Anbindung, keine Missionslogik, kein Autoload, keine SimulationRoot- oder Registry-Integration.
- Risiken: Die Signalvertraege stehen, die spaetere Einbindung muss ohne harte Direktkopplung zwischen Runtime-Systemen, UI und Autoritaetslogik erfolgen.
- Naechster Schritt: EventRouter an kommende Systeme anbinden, sobald SimulationRoot und weitere Laufzeitkomponenten existieren.

### SimulationRoot
- Status: implementiert
- Stand: `SimulationRoot` als eigene `Node`-Komponente mit Command- und Effects-Queues, deterministischer Tick-Verarbeitung in `_physics_process()`, Guard-Checks, Stub-Apply-Methoden und `tick_processed`-Signal eingefuehrt.
- Offene Punkte: keine Gameplay-Mechanik, keine Missionslogik, keine Registry- oder UpdateManager-Anbindung, keine Zustandsmutation an fremden Nodes.
- Risiken: Die autoritative Verarbeitungsstruktur steht, die spaetere Befehls- und Effektsemantik muss strikt innerhalb von `SimulationRoot` bleiben.
- Naechster Schritt: konkrete Command- und Effect-Typen einfuehren, sobald die Folgesysteme definiert sind.

### Commander Command Model
- Status: implementiert
- Stand: `CommanderCommand` als leichtgewichtiges datenorientiertes Modell unter `res://scripts/command/commander_command.gd` eingefuehrt; formalisiert die aktuell bekannten Commander-Befehlstypen `move`, `take`, `defend` und `flank` sowie `priority`, `unit_id`, `team_id`, optional `target_position` und `phase`.
- Offene Punkte: keine echte Befehlsausfuehrung, keine FTL-Entscheidungslogik, keine UI-Bindings und keine tiefere Command-Semantik ueber den reinen Datenvertrag hinaus.
- Risiken: Der aktuelle Vertrag ist bewusst klein und Dictionary-kompatibel; spaetere Erweiterungen muessen die bestehende `"type"`-Kompatibilitaet zu RuntimeLeader/EventRouter/SimulationRoot erhalten.
- Naechster Schritt: das Modell bei Bedarf in kleine Integrationspfade einspeisen, ohne die bestehenden Runtime-Systeme von Dictionary-Vertraegen abrupt zu entkoppeln.

### FTL Task Model
- Status: implementiert
- Stand: `FTLTask` als leichtgewichtiges datenorientiertes Modell unter `res://scripts/ftl/ftl_task.gd` eingefuehrt; formalisiert die minimalen FTL-Task-Typen `seek_cover`, `move_to_area`, `engage_in_area`, `hold_position` und `retreat` sowie `priority`, `unit_id`, `team_id`, optional `target_position`, `target_area_id`, `source_command_type` und `phase`.
- Offene Punkte: keine echte Task-Ausfuehrung, keine RuntimeLeader-AI, keine Uebersetzungslogik aus Commander-Befehlen und keine UI-Bindings.
- Risiken: Das Modell ist bewusst klein und dictionary-orientiert; spaetere Erweiterungen sollten diese Datenkompatibilitaet erhalten und keine versteckte Ausfuehrungslogik in das Modell ziehen.
- Naechster Schritt: bei Bedarf spaeter einen kleinen, expliziten Uebersetzungspfad von Commander-Commands zu FTL-Tasks ergaenzen, ohne die Modelle eng zu koppeln.

### Command to FTLTask Translator
- Status: implementiert
- Stand: ein schlanker `CommandToFTLTaskTranslator` unter `res://scripts/command/command_to_ftltask_translator.gd` uebersetzt gueltige `CommanderCommand`-Daten in `FTLTask`-Daten.
- Offene Punkte: keine echte FTL-Entscheidungslogik, keine Task-Queue, keine RuntimeLeader-Erweiterung und keine Ausfuehrung in `SimulationRoot`.
- Risiken: Die V1-Abbildung ist bewusst einfach und statisch; spaetere feinere taktische Zerlegung von `take` und `flank` muss explizit und separat eingefuehrt werden.
- Naechster Schritt: spaeter Integration in RuntimeLeader / SimulationRoot, ohne neue Kopplungen aufzubauen.
- Stand: `FTLRuntimeStatus` unter `res://scripts/ftl/ftl_runtime_status.gd` formalisiert jetzt einen kleinen Laufzeitstatus fuer FTLs mit den erlaubten Werten `idle`, `seeking_cover`, `moving_to_area`, `engaging_in_area`, `holding_position` und `retreating` sowie einem einfachen Dictionary-Roundtrip.
- Offene Punkte: noch keine RuntimeLeader-Anbindung, keine Status-Uebergaenge aus FTLTasks und keine Ausfuehrungslogik.
- Risiken: Das Modell ist bewusst klein und statuszentriert; spaetere Erweiterungen sollten keine versteckte Gameplay-Logik in den Datentraeger ziehen.
- Naechster Schritt: einen minimalen Uebergang von `FTLTask` zu `FTLRuntimeStatus` im `RuntimeLeader` abbilden.

### TASK_019 – minimaler FTLTask -> RuntimeStatus Uebergang
- Status: implementiert
- Stand: `RuntimeLeader` erzeugt jetzt beim minimalen Verarbeiten eines gueltigen `FTLTask` einen passenden `FTLRuntimeStatus`; dabei werden `seek_cover`, `move_to_area`, `engage_in_area`, `hold_position` und `retreat` auf die entsprechenden Laufzeitstatus abgebildet und ueber `runtime_status_changed(...)` signalisiert.
- Offene Punkte: keine tiefere Statusmaschine, keine Task-Abschlusslogik, keine Ausfuehrung und keine Rueckuebergaenge nach `idle`.
- Risiken: Der Uebergang ist bewusst rein datenbasiert und einseitig; spaetere komplexere Statuswechsel muessen explizit auf diesem einfachen Mapping aufbauen.
- Naechster Schritt: spaetere Statuswechsel und Task-Lebenszyklen nur dann ergaenzen, wenn dafuer ein klarer eigener Task vorliegt.

### TASK_020 – minimaler UnitCommand-Stub
- Status: implementiert
- Stand: `UnitCommand` unter `res://scripts/npc/unit_command.gd` formalisiert jetzt minimale Unit-Kommandos als Datenmodell mit den Typen `move_to_position`, `hold_position`, `engage_area`, `retreat` und `seek_cover` sowie kleinem Dictionary-Roundtrip.
- Offene Punkte: keine TestUnit-Anbindung, keine Ausfuehrung, keine Navigation und keine Runtime-Integration.
- Risiken: Das Modell ist bewusst nur ein Datentraeger; spaetere Unit-Logik muss darauf aufsetzen, ohne versteckte Wirkung in das Modell zu verlagern.
- Naechster Schritt: ein minimales Runtime-Status-Modell fuer `TestUnit` ergaenzen.

### TASK_021 – TestUnit Runtime-Status
- Status: implementiert
- Stand: `UnitRuntimeStatus` unter `res://scripts/npc/unit_runtime_status.gd` formalisiert die minimalen Unit-Zustaende `idle`, `assigned`, `pending_move` und `holding`; `TestUnit` unter `res://scripts/npc/test_unit.gd` traegt jetzt einen solchen Laufzeitstatus und signalisiert Statuswechsel ueber `runtime_status_changed(...)`.
- Offene Punkte: noch keine FTLTask-Zuweisung, keine UnitCommand-Anbindung und keine Ausfuehrungslogik.
- Risiken: Der Unit-Zustand ist bewusst klein und datenbasiert; spaetere Command- oder Simulationslogik darf diesen Datentraeger nicht still zur Gameplay-Wahrheit ausbauen.
- Naechster Schritt: einen minimalen FTLTask -> Unit-Zuweisungspfad ergaenzen.

### TASK_022 – FTLTask -> Unit-Zuweisung
- Status: implementiert
- Stand: `RuntimeLeader` kann den aktuell gehaltenen `FTLTask` jetzt minimal auf die aktuell referenzierte `TestUnit` abbilden; dafuer wird ein einfacher `UnitCommand` erzeugt und ueber `assign_current_ftl_task_to_unit()` an die Unit uebergeben.
- Offene Punkte: noch keine Mehrfach-Unit-Verteilung, keine Registry-Anbindung und keine Ausfuehrungslogik.
- Risiken: Die Abbildung bleibt bewusst direkt und lokal; spaetere komplexere Verteilung oder feinere Unit-Kommandosemantik muss explizit in eigenen Tasks folgen.
- Naechster Schritt: mehrere Units pro FTL als reinen Datenfluss ergaenzen.

### TASK_023 – mehrere Units pro FTL
- Status: implementiert
- Stand: `RuntimeLeader` kann jetzt mehrere unit-aehnliche Referenzen ueber `add_unit_member(...)` halten und den aktuellen `FTLTask` ueber `assign_current_ftl_task_to_all_units()` minimal an 2–3 Units als reine Datenzuweisung verteilen.
- Offene Punkte: keine Registry-Nutzung, keine differenzierte Verteilung pro Unit und keine Ausfuehrungslogik.
- Risiken: Die Mehrfachverteilung ist bewusst identisch fuer alle gehaltenen Units; spaetere feinere Aufteilung oder Priorisierung muss explizit und separat eingefuehrt werden.
- Naechster Schritt: den Batch abschliessen und erst im naechsten Batch sichtbare Reaktion oder Missionsszenen ergaenzen.


### UnitCommand Stub
- Status: implementiert
- Stand: ein minimaler `UnitCommand`-Stub wurde als leichtgewichtiges Datenmodell eingefuehrt; dient als kleine formale Grundlage fuer spaetere Unit-bezogene Runtime-Kommandos ohne echte Ausfuehrungslogik.
- Offene Punkte: keine echte Unit-Ausfuehrung, keine Bewegung, keine Kampf- oder Missionslogik.
- Risiken: Das Modell ist bewusst klein; spaetere Erweiterungen muessen kompatibel zur bestehenden Daten- und Runtime-Struktur bleiben.
- Naechster Schritt: spaeter an Runtime-Status und minimale Simulationspfade anbinden.

### TestUnit Runtime Status
- Status: implementiert
- Stand: fuer `TestUnit` existiert ein minimales Runtime-Statusmodell mit einfachen Zustandswerten wie `idle`, `assigned`, `pending_move` und `holding`.
- Offene Punkte: keine echte Bewegungslogik, keine KI, keine Kampfzustandslogik.
- Risiken: Der Status ist rein vorbereitend; spaetere Runtime-Uebergaenge muessen weiter ueber SimulationRoot und klar definierte Datenpfade laufen.
- Naechster Schritt: an einfache sichtbare Reaktionen und minimale Move-Tests anbinden.

### FTLTask to Unit Assignment
- Status: implementiert
- Stand: ein minimaler Datenfluss wurde ergaenzt, ueber den ein `FTLTask` einer `TestUnit` zugeordnet werden kann; dient nur als Referenz- und Integrationsnachweis.
- Offene Punkte: keine echte Task-Ausfuehrung, keine Taktiklogik, keine Bewegungs- oder Aktionsverarbeitung.
- Risiken: Die Zuordnung ist aktuell bewusst leichtgewichtig; spaetere Erweiterungen muessen die Trennung zwischen Datenfluss, RuntimeLeader und SimulationRoot erhalten.
- Naechster Schritt: in eine minimale sichtbare Missionsreaktion ueberfuehren.

### Multiple Units per FTL
- Status: implementiert
- Stand: der grundlegende Datenfluss fuer mehrere `TestUnit`-Instanzen unter einem FTL / Team wurde hergestellt; mehrere Units koennen demselben FTL-Kontext zugeordnet werden.
- Offene Punkte: keine Formation, keine echte Untereinheitensteuerung, keine taktische Verteilung.
- Risiken: Bisher nur Integrations- und Strukturbeweis; spaetere Gruppenlogik darf nicht still in Registries oder RuntimeLeader versteckt werden.
- Naechster Schritt: mehrere Units in einer minimalen Missions-Testszene sichtbar reagieren lassen.

### TASK_024 – minimale Missions-Testszene
- Status: implementiert
- Stand: eine minimale Start- und Testszene unter `res://scenes/tests/mission_reactivity_test.tscn` haelt jetzt `SimulationRoot`, `EventRouter`, `UnitRegistry`, `FTLRegistry`, `UpdateManager`, einen `RuntimeLeader`, drei `TestUnit`-Instanzen und einen einfachen Zielmarker zusammen; ein kleiner Setup-Node registriert Units und FTL ueber direkte Referenzen.
- Offene Punkte: noch keine Move-Daten, keine sichtbare Reaktion, keine echte Missionslogik und keine autoritative Positionsveraenderung.
- Risiken: die Szene ist bewusst nur ein kontrolliertes Integrationsfeld; spaetere sichtbare Reaktion muss weiter ohne globale SceneTree-Suchen und ohne verdeckte Logik im Setup-Glue folgen.
- Naechster Schritt: eine minimale Zielposition als Daten an die Unit-Ebene haengen.

### TASK_025 – Move-Target als Daten
- Status: implementiert
- Stand: `UnitRuntimeStatus` und `TestUnit` koennen jetzt optional eine `target_position` als reinen Datenwert halten; bei einem `UnitCommand` mit Zielposition wird dieser Wert in den Runtime-Status der Unit uebernommen.
- Offene Punkte: noch keine autoritative Bewegung, keine Navigation und keine sichtbare Reaktion in der Szene.
- Risiken: die Zielposition ist bewusst nur vorbereitende Datenhaltung; spaetere Bewegung darf weiterhin nur ueber `SimulationRoot` committen.
- Naechster Schritt: einen minimalen autoritativen Move-Pfad im `SimulationRoot` ergaenzen.

### TASK_026 â€“ minimaler Move im SimulationRoot
- Status: implementiert
- Stand: `SimulationRoot` kann jetzt einen minimalen `move_to_position`-Command ueber direkte `UnitRegistry`-Referenz verarbeiten und eine `TestUnit` als `Node2D` in kleinen Schritten pro Physics-Tick Richtung `target_position` bewegen.
- Offene Punkte: keine Navigation, keine Kollisionslogik, kein Pathfinding, keine Formationen und keine Abschlusslogik bei Zielerreichung.
- Risiken: die Bewegung ist bewusst nur ein sehr kleiner Testpfad; spaetere echte Fortbewegung darf nicht durch versteckte Nebenlogik ausserhalb von `SimulationRoot` wachsen.
- Naechster Schritt: den ersten sichtbaren Commander -> FTL -> Unit-Flow ueber diesen Move-Pfad integrieren.

### TASK_027 â€“ erster sichtbarer Commander -> FTL -> Unit-Flow
- Status: implementiert
- Stand: ein kleiner `MissionCommandFlowDriver` erzeugt jetzt einen `CommanderCommand`, leitet ihn ueber `RuntimeLeader.command(...)` und `EventRouter` in den bestehenden `CommandToFTLTaskTranslator`, laesst den resultierenden `FTLTask` im `RuntimeLeader` in einen `UnitCommand` uebergehen und enqueued diesen anschliessend in `SimulationRoot`; in der Testszene reagiert `UnitAlpha` dadurch sichtbar mit Bewegung Richtung Zielmarker.
- Offene Punkte: keine Formation, keine Taktiklogik, keine Mehrfachverteilung ueber den Commander-Pfad und keine Missionsmechanik.
- Risiken: der sichtbare Flow ist bewusst ein einzelner Happy Path fuer `move`; spaetere Kommandotypen und Team-Flows muessen explizit und separat folgen.
- Naechster Schritt: nach Batch-Abschluss Godot-Start und Integrationsstand erneut pruefen, bevor weitere sichtbare Systeme folgen.

### TASK_028 – minimales LOS-System
- Status: implementiert
- Stand: `LineOfSightSystem` unter `res://scripts/core/los_system.gd` liefert jetzt einen sehr kleinen geometriebasierten Sichtliniennachweis zwischen zwei Punkten, einer `Node2D` und einer Zielposition oder zwei `Node2D`-Referenzen auf Basis einer einfachen Distanzgrenze.
- Offene Punkte: keine Hindernispruefung, keine Raycasts, keine Performance-Optimierung und keine Kopplung an spaetere Combat- oder FOW-Systeme.
- Risiken: der Sichtkontakt ist bewusst nur ein Distanz- und Referenznachweis; spaetere echte Deckungs- oder Blockerlogik muss explizit und separat folgen.
- Naechster Schritt: eine minimale Fog-of-War-Sichtbarkeit auf diesem LOS-Nachweis aufbauen.

### TASK_029 – minimales Fog of War
- Status: implementiert
- Stand: `FogOfWarSystem` unter `res://scripts/core/fog_of_war_system.gd` verwaltet jetzt einen kleinen booleschen Sichtbarkeitszustand pro `team_id` und `target_id` und kann diesen direkt aus dem bestehenden `LineOfSightSystem` aktualisieren.
- Offene Punkte: keine Darstellung, keine Shader, keine Mehrbeobachter-Aggregation und kein finales FOW-System.
- Risiken: das System ist bewusst nur ein datenbasierter Sichtbarkeitscontainer; spaetere echte FOW-Darstellung oder Kartenlogik muss separat und explizit darauf aufsetzen.
- Naechster Schritt: einen minimalen Treffer-/Damage-Pfad auf dem bestehenden Test- und Simulationsaufbau ergaenzen.

### TASK_030 – minimales Treffer-/Damage-Modell
- Status: implementiert
- Stand: `DamageModel` unter `res://scripts/core/damage_model.gd` liefert jetzt einen kleinen datenbasierten Treffer- und Schadenspfad; `SimulationRoot` kann `damage`-Effects minimal autoritativ anwenden und `TestUnit` haelt dafuer einfache Health- und Hit-Daten.
- Offene Punkte: keine Waffenlogik, keine Projektilsimulation, keine Ballistik und noch keine Down-/Bleedout-Zustaende.
- Risiken: der Pfad ist bewusst klein und testorientiert; spaetere Combat-Erweiterungen muessen weiterhin ueber `SimulationRoot` laufen und sollten diesen Utility-Charakter nicht zu einem grossen Framework aufblasen.
- Naechster Schritt: den minimalen Zustandsfluss `fit -> down -> bleedout` auf dem neuen Damage-Pfad ergaenzen.

### TASK_031 – Down-/Bleedout-Zustände
- Status: implementiert
- Stand: `UnitVitalStatus` unter `res://scripts/npc/unit_vital_status.gd` formalisiert jetzt die minimalen Zustände `fit`, `down` und `bleedout`; `TestUnit` wechselt bei tödlichem Schaden von `fit` nach `down`, und `SimulationRoot` kann diesen Zustand über einen kleinen `bleedout`-Effect weiter nach `bleedout` schieben.
- Offene Punkte: keine Revive-Mechanik, keine Sanitätslogik, keine Evakuierung und keine komplexen Down-State-Regeln.
- Risiken: der Zustandsfluss ist bewusst nur ein sehr kleiner Testpfad; spätere Combat- und Support-Systeme müssen diese Minimalzustände explizit erweitern statt sie implizit zu überladen.
- Naechster Schritt: einen minimalen Friendly-Fire-Fall im bestehenden Damage-Pfad berücksichtigen.
### TASK_032 – Friendly Fire
- Status: implementiert
- Stand: `SimulationRoot` beruecksichtigt jetzt bei `damage`-Effects einen minimalen Friendly-Fire-Fall auf Basis von `attacker_team_id`, Ziel-`team_id` und `allow_friendly_fire`; gleiche Teams koennen damit gezielt blockiert oder als erlaubter Friendly-Fire-Treffer im Hit-Kontext markiert werden.
- Offene Punkte: keine komplexe Teamlogik, keine Projektile, keine Deckungs- oder Identifikationsregeln und keine weitergehende Combat-Auswertung.
- Risiken: der Pfad bleibt bewusst klein und regelbasiert; spaetere echte Kampf- oder Teammechaniken muessen diesen Minimalfall explizit erweitern statt ihn still zu verkomplizieren.
- Naechster Schritt: Batch abschliessen, Godot-Start pruefen und danach erst mit Meta-Layer oder erweiterten Taktiksystemen weitermachen.
