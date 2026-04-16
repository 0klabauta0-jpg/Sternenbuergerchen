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
### Minimal Combat Loop Test
- Status: implementiert
- Stand: die Missions-Testszene enthaelt jetzt zwei Gegner-`TestUnit`-Instanzen mit eigener Team-ID; ein kleiner `MissionCombatLoopDriver` prueft direkten LOS-Kontakt zwischen Friendly- und Enemy-Units, enqueued darauf basierend minimale `damage`- und `bleedout`-Effects in `SimulationRoot` und markiert den Fight als beendet, sobald alle Gegner nicht mehr `fit` sind.
- Offene Punkte: keine Gegen-KI, keine Waffenvielfalt, keine Deckungslogik, keine Respawn- oder Eliminierungsmechanik und keine komplexe Team-Auswertung.
- Risiken: der Combat-Loop ist bewusst ein kleiner Integrationspfad fuer die Testszene; spaetere echte Combat-Systeme muessen den Glue-Code explizit ersetzen, statt ihn still auszubauen.
- Naechster Schritt: bei Bedarf den symmetrischen Gegnerpfad oder eine spaetere Eliminierungsstufe in eigenen Tasks aufbauen, ohne die autoritative Rolle von `SimulationRoot` aufzuweichen.

### Minimal Combat Control Behavior
- Status: implementiert
- Stand: `UnitCommand`, `UnitRuntimeStatus` und `TestUnit` tragen jetzt einen kleinen datenbasierten Feuerstatus mit `fire_at_will` und `hold_fire`; `engage_area` fuehrt auf einen expliziten `engaging`-Zustand, waehrend `move_to_position` als `pending_move` mit `hold_fire` erhalten bleibt. `RuntimeLeader` leitet diesen Status minimal aus dem aktuellen FTL-Task ab, und der bestehende `MissionCombatLoopDriver` erlaubt Angriffe nur noch bei `fire_at_will` plus engage-/holding-aehnlichem Zustand.
- Offene Punkte: keine groessere Combat-Logik, keine Rules-of-Engagement-Varianten, keine komplexe Zielwahl und keine Gegner-Ausweitung ueber den bestehenden Testpfad hinaus.
- Risiken: die Steuerung bleibt bewusst testpfadbezogen; spaetere echte Kampfsteuerung sollte diese Minimalregeln explizit ablösen statt sie still zu verkomplizieren.
- Naechster Schritt: bei Bedarf spaeter weitere Commander-/FTL-Befehlstypen mit klarer Feuerregel abbilden und nur dann eine komplexere Zielwahl ergaenzen, wenn dafuer ein eigener Task vorliegt.
### Minimal Meta Layer
- Status: implementiert
- Stand: ein kleiner menuegetriebener Meta-Layer startet jetzt ueber `res://scenes/meta/meta_layer_test.tscn`; ein `HomebaseTestScreen` zeigt die verfuegbaren Friendly-TestUnits und erlaubt eine einfache Teamzusammenstellung, ein `FOBTestScreen` zeigt das uebertragene Team und startet daraus die bestehende Missions-Testszene. Die Auswahl wird ueber einen schlanken `MetaLayerFlow` ohne Autoload oder neue grosse Szenenarchitektur an die Missionsszene weitergereicht.
- Offene Punkte: keine Persistenz, keine Skill-/Loadout-/Soziallogik, keine Reise- oder Meta-Simulation und kein Rueckweg aus der Mission in den Meta-Layer.
- Risiken: der Datenfluss ist bewusst klein und screen-getrieben; spaetere echte Meta-Systeme muessen diesen Testpfad explizit erweitern statt ihn still zu einer grossen UI- oder Persistenzschicht auszubauen.
- Naechster Schritt: spaeter nur bei eigenem Task weitere Meta-Funktionen wie Respawn-/Transferlogik oder einfache Missionsauswertung anhaengen.
### Minimal Mission Return Flow
- Status: implementiert
- Stand: der bestehende `MetaLayerFlow` bindet jetzt das Missionsende aus dem `MissionCombatLoopDriver` direkt an den Meta-Layer an, sammelt den minimalen Teamzustand der eingesetzten Friendly-Units ein und zeigt daraus einen kleinen Debrief-Screen mit Ergebnis und Rueckgabeoptionen. Die FOB kann den letzten Missionsausgang samt Teamzustand anzeigen, und sowohl der Rueckweg Debrief -> FOB als auch Debrief -> Homebase sind minimal moeglich.
- Offene Punkte: keine Persistenz, keine Nachsorge-/Heilungslogik, keine Kampagnenauswertung und kein Rueckfluss tieferer Missionsmetriken.
- Risiken: der Rueckfluss ist bewusst klein und screen-getrieben; spaetere echte Meta- oder Kampagnenlogik sollte diesen Glue-Code explizit erweitern statt ihn still zu einer grossen Ergebnisarchitektur auszubauen.
- Naechster Schritt: spaeter bei Bedarf nur in eigenen Tasks weitere Meta-Rueckfluesse wie Respawn-/Zeitlogik oder einfache Ergebnisfolgen anhaengen.

### Minimal Tactical Order Behavior
- Status: implementiert
- Stand: `RuntimeLeader` leitet jetzt fuer `defend`, `move` und `flank` kleine taktische Unterschiede in `UnitCommand` und `UnitRuntimeStatus` ab: `defend`/`hold` bleibt in Position, traegt erhoehten `cover_score` und darf feuern, `move` bleibt bei `hold_fire`, und `flank` bekommt einen seitlichen Zieloffset sowie einen kleinen `attack_bonus`. `SimulationRoot` beruecksichtigt diese Minimalwerte im bestehenden Damage-Pfad, und die Missions-Testszene zeigt jetzt drei parallele Friendly-Orders mit unterscheidbarem Verhalten.
- Offene Punkte: keine komplexe Deckungsarchitektur, keine echte Taktik-KI, keine Formation, keine Navigation und keine ausgebaute Zielpriorisierung ueber den kleinen Testpfad hinaus.
- Risiken: die Unterschiede bleiben bewusst daten- und testszenenbasiert; spaetere echte Taktiksysteme sollten diese Minimalableitungen explizit ersetzen statt sie still weiter aufzublasen.
- Naechster Schritt: spaeter nur bei eigenem Task feinere Deckungs-, Zielwahl- oder Rollenregeln ergaenzen und dabei die autoritative Rolle von `SimulationRoot` beibehalten.

### Minimal Tactical Readability
- Status: implementiert
- Stand: `TestUnit` zeigt in der Missions-Testszene jetzt kleine direkt an die Unit geheftete Status- und Event-Texte fuer `MOVE`, `DEFEND`, `FLANK`, `ENGAGE`, `DOWN` und `BLEEDOUT` sowie `HF` / `FAW` und sichtbaren LOS-Kontakt. `MissionCombatLoopDriver` erzeugt zusaetzlich eine kleine Kontaktlinie, eine kompakte Event-Anzeige, einen klaren Siegerhinweis und ein leicht entschleunigtes Angriffstempo, damit Treffer, Down/Bleedout und Combat-Ende beobachtbarer bleiben.
- Offene Punkte: keine groessere HUD-/Debug-Architektur, keine Politur, keine Animationen und keine komplexe Zeitsteuerung.
- Risiken: die Lesbarkeitshilfen bleiben bewusst testszenenbezogen; spaetere echte UI- oder Debug-Systeme sollten diesen kleinen Pfad explizit ersetzen statt ihn still zu einer grossen Overlay-Schicht auszubauen.
- Naechster Schritt: spaeter nur bei eigenem Task weitere gezielte Beobachtbarkeit wie einfache Threat-/Objective-Hinweise ergaenzen, ohne die Szene in eine Debug-Framework-Struktur zu ziehen.

### Command Feedback Marker
- Status: implementiert
- Stand: die taktische Missions-Testszene zeigt jetzt einen kleinen festen Befehlsstatus mit `MOVE ORDER`, `HOLD / DEFEND` und `FLANK`; der gelbe Marker ist ueber einen kleinen `MissionTacticalSandboxController` als `ORDER TARGET` lesbar und wechselt je nach aktivem Befehl Text und Farbe. Die Friendly-Flow-Driver lassen sich dadurch direkt und wiederholt per Debug-Tasten `1`, `2` und `3` ausloesen, ohne dass eine groessere UI- oder Commander-Schicht eingefuehrt wurde.
- Offene Punkte: keine grosse Commander-UI, keine Mausselektion, keine komplexe Marker- oder Overlay-Logik und keine ueber den Testbedarf hinausgehende Eingabearchitektur.
- Risiken: der Feedback-Pfad bleibt bewusst testszenenbezogen; spaetere echte Commander- oder Taktik-UI sollte diese kleine Debug-Steuerung explizit ersetzen statt sie still auszubauen.
- Naechster Schritt: spaeter nur bei eigenem Task weitere kleine Bedienhilfen wie Zielwechsel oder Reset ergaenzen, falls der Taktik-Slice das wirklich braucht.

### Team Identity / Roles
- Status: implementiert
- Stand: die taktische Missions-Testszene traegt jetzt einen kleinen, klar lesbaren Team-Identity-Schritt: `TestUnit` kann eine kurze Teamanzeige und Rollenbezeichnung tragen, Friendly- und Enemy-Units zeigen diese Identitaet direkt im kleinen Unit-Label, und die Szene selbst haelt zusaetzliche Mini-Uebersichten fuer `TEAM ALPHA` und `HOSTILE TEAM BRAVO`. Der bestehende Befehlsblock zeigt ausserdem jetzt `ALPHA TEAM ORDER`, damit der manuelle Sandbox-Pfad klar einer Teamseite zugeordnet bleibt.
- Offene Punkte: keine Gameplay-Wirkung aus Rollen, keine tiefere Fireteam-Struktur, keine neue Commander- oder Squad-Architektur und keine Persistenz dieser Identitaet ausserhalb der Testszene.
- Risiken: der Schritt ist bewusst rein lesbar und testszenenbezogen; spaetere echte Team-/Rollenlogik sollte diese Anzeige explizit erweitern statt aus reiner Beschriftung still Gameplay-Wahrheit abzuleiten.
- Naechster Schritt: spaeter nur bei eigenem Task Rollen minimal funktional machen, falls das fuer Fireteams oder Commander-Befehle wirklich noetig wird.

### Team Identity / Roles Mechanical Step
- Status: implementiert
- Stand: `TestUnit` traegt jetzt genau ein kleines exportiertes Feld `combat_role` mit den erlaubten Werten `anchor`, `recon` und `assault`. Dieses Feld wird ausschliesslich in der bestehenden Ableitung im `RuntimeLeader` verwendet, um `target_position`, `cover_score` und `attack_bonus` fuer bestehende Orders minimal unterschiedlich abzuleiten. In der Missions-Testszene ist `Unit Alpha = anchor`, `Unit Bravo = recon` und `Unit Charlie = assault`; dadurch fuehrt dieselbe Order jetzt zu unterschiedlich konservativen, seitlichen oder offensiven Ergebnissen, ohne eine neue Rollen- oder Skill-Architektur einzufuehren.
- Offene Punkte: keine neue Rollenarchitektur, keine Persoenlichkeiten, keine Fireteam-Logik, keine neue Commander-UI und keine tieferen Datenpipelines fuer Rollen ausserhalb der Test-Units.
- Risiken: der Schritt ist bewusst klein gehalten und haengt nur an bereits bestehenden Order-Ableitungen; spaetere echte Rollen- oder Squad-Systeme muessen diesen Minimalpfad explizit erweitern statt versteckte Regeln ueber viele Systeme zu verteilen.
- Naechster Schritt: spaeter nur bei eigenem Task weitere kleine funktionale Unterschiede ergaenzen, falls sie fuer Fireteams oder Commander-Befehle wirklich gebraucht werden.

### Minimal Fireteam Command Split
- Status: implementiert
- Stand: der taktische Sandbox-Slice kann Friendly-Orders jetzt minimal nach Fireteam filtern, ohne neue Commander- oder Squad-Architektur. `TestUnit` traegt dafuer ein kleines `fireteam_id`-Feld mit `blue` oder `gold`, die Friendly-Szene ist als `BLUE` (Unit Alpha + Unit Bravo) und `GOLD` (Unit Charlie) aufgeteilt, und der bestehende `MissionTacticalSandboxController` kann per `Q/E` zwischen `ALL`, `BLUE` und `GOLD` umschalten. `move`, `defend` und `flank` werden dadurch nur noch an die passenden bestehenden Flow-Driver weitergereicht.
- Offene Punkte: keine mehreren RuntimeLeader, keine echte Fireteam-Hierarchie, keine getrennten Commander-Panels und keine persistente Teamorganisation ausserhalb der Testszene.
- Risiken: der Schritt ist bewusst ein kleiner Sandbox-Filter auf bestehende Orders; spaetere echte Fireteam-/FTL-Struktur muss diesen Debug-Pfad explizit ersetzen statt ihn still zum Kernsystem werden zu lassen.
- Naechster Schritt: spaeter nur bei eigenem Task weitere kleine Fireteam-Funktionen wie getrennte Zielmarker oder zweite FTL-Instanzen pruefen, wenn das fuer den Vertical Slice wirklich noetig wird.

### Minimal Commander Take Order
- Status: implementiert
- Stand: der bestehende taktische Sandbox-Slice kann jetzt neben `move`, `defend` und `flank` auch den V1-Commander-Befehl `take` direkt ausloesen. Der `MissionTacticalSandboxController` bietet dafuer einen kleinen manuellen `take`-Pfad ueber Taste `4`, zeigt `TAKE / ENGAGE` im bestehenden Befehlsblock an und markiert den gelben Marker als `ENGAGE AREA`. Die Ausfuehrung laeuft weiter ueber die bereits vorhandene Kette `CommanderCommand -> CommandToFTLTaskTranslator -> RuntimeLeader -> SimulationRoot`, ohne neue Combat- oder Commander-Struktur einzufuehren.
- Offene Punkte: keine grosse Commander-UI, keine neue Zielwahl, keine komplexe Phasen- oder Objective-Logik und keine weitere Befehlsfamilie ueber die bestehenden V1-Orders hinaus.
- Risiken: der `take`-Pfad bleibt bewusst ein kleiner Sandbox-Befehl im vorhandenen Slice; spaetere echte Commander-Bedienung sollte diese Debug-Eingabe explizit ersetzen statt sie still auszubauen.
- Naechster Schritt: spaeter nur bei eigenem Task den naechsten kleinen Vertical-Slice-Baustein wie Objective-/Phase-Logik oder Siegbedingungen anschliessen.

### Minimal Mission Phase Gate
- Status: implementiert
- Stand: der taktische Sandbox-Slice nutzt jetzt das bereits vorhandene `phase`-Feld in `CommanderCommand`, `FTLTask`, `UnitCommand` und `UnitRuntimeStatus` als kleinen Missions-Phasenhaken. Der `MissionTacticalSandboxController` kann per `R/F` zwischen `APPROACH`, `ASSAULT` und `HOLD` fuer die naechste Order umschalten und gibt diese Phase an den bestehenden Command-Flow weiter. `MissionCombatLoopDriver` beruecksichtigt diese Phase minimal als Angriffsfreigabe: `APPROACH` blockiert Feuer trotz LOS, `ASSAULT` erlaubt den bisherigen Engage-Pfad, und `HOLD` laesst nur haltende bzw. engagierende Units feuern.
- Offene Punkte: keine grosse Missions- oder Objective-Logik, keine automatische Phasenumschaltung, keine neue State-Machine und keine Phase-UI ueber den kleinen Sandbox-Hinweis hinaus.
- Risiken: der Schritt bleibt bewusst ein kleiner Gate-Mechanismus fuer den bestehenden Slice; spaetere echte Missionsphasen sollten diesen Debug-/Proto-Pfad explizit ersetzen statt ihn still zu einer grossen Systemschicht auszubauen.
- Naechster Schritt: spaeter nur bei eigenem Task eine minimale Siegbedingung oder Objective-Logik an diesen Phase-Haken koppeln, wenn das fuer den Vertical Slice wirklich noetig wird.

### Minimal Objective Victory
- Status: implementiert
- Stand: der bestehende Zielmarker fungiert jetzt auch als kleiner Objective-Punkt fuer den taktischen Sandbox-Slice. `MissionCombatLoopDriver` kann Friendly-Sieg jetzt nicht nur ueber gegnerische Neutralisierung, sondern alternativ auch ueber `OBJECTIVE SECURED` aufloesen: dafuer muss mindestens eine fitte Friendly-Unit im `HOLD`-Phasenmodus den Zielmarker innerhalb eines kleinen Radius ueber einige Ticks halten, waehrend dort kein fitter Gegner contestet. Der Combat-Status und der Siegerhinweis zeigen diesen alternativen Endzustand direkt in der Szene an.
- Offene Punkte: keine grosse Objective-Architektur, keine Missionsgenerator- oder Mehrziel-Logik, keine separate Objective-UI und keine automatische Verkettung mehrerer Missionsphasen.
- Risiken: der Objective-Pfad ist bewusst nur ein sehr kleiner Vertical-Slice-Haken am bestehenden Combat-Driver; spaetere echte Siegbedingungen sollten diesen Glue-Code explizit ersetzen statt ihn still zu einem kompletten Missionssystem auszubauen.
- Naechster Schritt: spaeter nur bei eigenem Task Objective-Secure mit weiteren V1-Siegbedingungen oder einem kleinen Missionsstart-/Einsatzkontext verbinden, falls das wirklich benoetigt wird.

### Minimal Mission Start Context
- Status: implementiert
- Stand: der bestehende Einsatz startet jetzt mit einem kleinen, konkreten Missionskontext statt nur in eine nackte Testszene zu springen. `MissionTestSetup` fuellt einen kleinen Missionsbrief in der Szene mit `MISSION`, `DEPLOY`, `OBJECTIVE` und dem aktuell eingesetzten Team. `MetaLayerFlow` gibt dafuer beim Start aus der FOB minimal `Operation Sandglass`, `FOB` und `secure_target` an die Missionsszene weiter. `MissionCombatLoopDriver` nutzt diesen Kontext auch leicht mechanisch: der Objective-Siegpfad ist nur aktiv, wenn das Missionsziel `secure_target` ist.
- Offene Punkte: keine grosse Missionsstart-Architektur, keine generischen Missionsgeneratoren, keine Objective-Kette und keine ausgebaute Einsatzplanung.
- Risiken: der Schritt bleibt bewusst ein kleiner Kontext-Haken fuer den bestehenden Slice; spaetere echte Missionsstarts sollten diesen Proto-Pfad explizit ersetzen statt ihn still zu einem grossen Missionsframework auszubauen.
- Naechster Schritt: spaeter nur bei eigenem Task weitere kleine V1-Einsatzparameter wie Spawnart oder alternative Mission Goals anbinden, wenn das fuer den Slice wirklich gebraucht wird.

### Minimal FOB Respawn Hook
- Status: implementiert
- Stand: der taktische Slice hat jetzt einen kleinen autoritativen Friendly-Respawn-Haken. Wenn eine Friendly-Unit `bleedout` erreicht, fordert `MissionCombatLoopDriver` ueber den bestehenden `EventRouter` einen `fob`-Respawn an. Ein kleiner `MissionRespawnDriver` verwaltet dafuer nur eine kurze Tick-Verzoegerung und enqueued anschliessend einen `respawn`-Effect in `SimulationRoot`. `TestUnit` kann daraufhin ueber `respawn_from_checkpoint()` mit voller Health am urspruenglichen Spawnpunkt in den Slice zurueckkehren.
- Offene Punkte: keine Rover-/Homebase-Respawnpfade, keine echten V1-Zeiten aus dem Brief, keine Transportlogik, keine Respawn-UI und kein Meta-Layer-Rueckfluss dieses Hooks.
- Risiken: der Hook ist bewusst nur ein kleiner Friendly-Testpfad fuer den bestehenden Slice; spaetere echte Respawn-Systeme muessen diesen Glue-Code explizit ersetzen statt ihn still zur Voll-Loesung werden zu lassen.
- Naechster Schritt: spaeter nur bei eigenem Task den Respawn-Zieltyp, die Wartezeit oder den Meta-Rueckfluss weiter differenzieren, wenn das fuer V1 wirklich noetig wird.

### Minimal Alternate Mission Goal
- Status: implementiert
- Stand: die FOB kann jetzt zwischen genau zwei kleinen Missionszielen fuer den bestehenden Slice umschalten: `secure_target` und `neutralize_enemies`. `FOBScreen` bietet dafuer nur einen kleinen Ziel-Button, `MetaLayerFlow` reicht die Auswahl direkt in `MissionTestSetup` weiter, und der bestehende Missionsbrief zeigt das aktive Ziel in der Testszene an. Mechanisch nutzt der Slice damit bereits vorhandenes Verhalten: `secure_target` laesst den Objective-Siegpfad aktiv, waehrend `neutralize_enemies` den Einsatz auf den bestehenden Elimination-Pfad reduziert.
- Offene Punkte: keine groessere Missionsziel-Auswahl, keine Missionsgeneratoren, keine verzweigten Objective-Ketten und keine weitergehende Ergebnisdarstellung im Meta-Layer.
- Risiken: der Schritt bleibt bewusst nur ein kleiner Meta-/Mission-Glue-Haken; spaetere echte Missionsziel-Systeme sollten diese Auswahl explizit ersetzen statt den kleinen FOB-Button still zu einer grossen Missionsarchitektur auszubauen.
- Naechster Schritt: spaeter nur bei eigenem Task weitere kleine Missionsparameter wie Spawnart, Zeitdruck oder Objective-Varianten ergaenzen, wenn das fuer V1 wirklich gebraucht wird.

### Minimal Fireteam FTL Order Spread
- Status: implementiert
- Stand: der bestehende taktische Sandbox-Slice gibt Friendly-Orders jetzt nicht mehr nur technisch pro einzelner Unit weiter, sondern minimal pro Fireteam/FTL-Pfad. `MissionCommandFlowDriver` kann dafuer in einem kleinen Broadcast-Modus alle passenden Friendly-Units eines Fireteams ueber `UnitRegistry` aufloesen und fuer dieselbe Commander-Order jeweils den bestehenden `CommanderCommand -> FTLTask -> RuntimeLeader -> UnitCommand -> SimulationRoot`-Pfad ausloesen. In der Testszene gibt es dafuer jetzt einen `BLUE`- und einen `GOLD`-Fireteam-Driver statt der frueheren unitweisen Flow-Aufteilung.
- Offene Punkte: keine mehrere RuntimeLeader-Instanzen, keine echte FTL-Hierarchie pro Fireteam, keine zweite Commander-Schicht und keine persistente Fireteam-Organisation ausserhalb der Testszene.
- Risiken: der Schritt bleibt bewusst Glue-Code fuer den vorhandenen Slice; spaetere echte Fireteam-/FTL-Struktur sollte diesen kleinen Driver explizit ersetzen statt ihn still zu einer grossen Befehlsarchitektur werden zu lassen.
- Naechster Schritt: spaeter nur bei eigenem Task weitere kleine Fireteam-Schritte wie getrennte Marker oder zusaetzliche FTL-Instanzen pruefen, wenn das fuer V1 wirklich gebraucht wird.

### Minimal Order Reaction Delay
- Status: implementiert
- Stand: der bestehende Commander -> FTL -> Unit-Pfad traegt jetzt einen kleinen, rein datenbasierten Reaktionsversatz pro Unit. `RuntimeLeader` leitet dafuer `execution_delay_ticks` direkt aus bestehendem `combat_role` und `source_command_type` ab. `MissionCommandFlowDriver` stempelt daraus einen kleinen `not_before_tick` auf den bereits existierenden `UnitCommand`-Dictionary-Pfad, und `SimulationRoot` wartet damit lediglich bis zum passenden Tick, statt neue Scheduler- oder AI-Logik einzufuehren. So reagieren `anchor`, `recon` und `assault` auf dieselbe Order nicht mehr im exakt selben Tick.
- Offene Punkte: keine Unsicherheits-/Persoenlichkeitslogik, keine komplexe Befehlsverweigerung, keine neue Timing-Architektur und keine tieferen FTL-Entscheidungen.
- Risiken: der Schritt ist bewusst klein und deterministisch; spaetere echte Verhaltenssimulation sollte diesen Proto-Versatz explizit ersetzen statt viele weitere Sonderregeln auf denselben Tick-Haken zu stapeln.
- Naechster Schritt: spaeter nur bei eigenem Task weitere kleine Unterschiede wie alternative Commander-Freigaben oder echte Fireteam-FTLs pruefen, wenn das fuer V1 wirklich gebraucht wird.

### Minimal Take Role Split
- Status: implementiert
- Stand: derselbe Commander-Befehl `take` fuehrt jetzt im bestehenden Slice nicht mehr fuer alle Friendly-Units zur exakt gleichen Unit-Ableitung. `RuntimeLeader` leitet `take` jetzt rollenabhaengig aus: `anchor` bleibt als haltender Sicherungspunkt auf `hold_position`, waehrend `recon` und `assault` den Zielraum ueber `move_to_position` mit unterschiedlichen Zielversetzen anlaufen. `MissionCombatLoopDriver` erlaubt dabei nun auch bewegende `take`-Commands als mobilen Engage-Pfad, sodass `take` sich weniger nach direkter Einheitssteuerung und mehr nach indirekter Team-Interpretation anfuehlt.
- Offene Punkte: keine echte FTL-Taktikplanung, keine komplexe Bereichssicherung, keine Formation und keine feinere Zielwahl fuer `take`.
- Risiken: die Ableitung bleibt bewusst klein und rollenbasiert; spaetere echte Team- oder FTL-Entscheidungslogik sollte diese Proto-Regeln explizit ersetzen statt weitere Sonderfaelle daran anzuschrauben.
- Naechster Schritt: spaeter nur bei eigenem Task weitere indirekte Order-Unterschiede wie `defend`-/`flank`-Interpretation oder mehrere FTL-Instanzen pruefen, wenn das fuer V1 wirklich gebraucht wird.

### Minimal Objective State Clarity
- Status: implementiert
- Stand: der bestehende Objective-Punkt im taktischen Slice hat jetzt einen klaren kleinen Zustandskern `neutral / contested / secured`. `MissionCombatLoopDriver` fuehrt diesen Zustand explizit, zeigt ihn im Statusblock und ueber ein kleines `ObjectiveStateLabel` direkt am Marker an. Der bisherige Capture-Fortschritt bleibt klein und wird nur als neutraler Fortschritt angezeigt. Zusaetzlich koennen Units mit einem `take`-Command in `HOLD`-Phase jetzt auch dann zum Objective-Halten beitragen, wenn sie den Zielpunkt ueber die bewegende `move_to_position`-Ableitung erreichen.
- Offene Punkte: keine feindliche Objective-Einnahme, keine Mehrziel-Architektur, keine grosse Objective-UI und keine tieferen Missionsphasen ueber diesen kleinen Markerzustand hinaus.
- Risiken: der Schritt bleibt bewusst nur ein kleiner Vertical-Slice-Haken fuer den bestehenden Einsatzkern; spaetere echte Objective-Systeme sollten diesen Proto-Pfad explizit ersetzen statt weitere Sonderlogik auf denselben Combat-Driver zu stapeln.
- Naechster Schritt: spaeter nur bei eigenem Task den kleinen Objective-Zustand an klare Victory/Fail- und Debrief-Pfade anbinden, wenn das fuer den Mission-Loop gebraucht wird.

### Minimal Mission Fail Condition
- Status: implementiert
- Stand: der bestehende `MissionCombatLoopDriver` kann den taktischen Slice jetzt nicht mehr nur ueber `enemy_neutralized` oder `objective_secured` beenden, sondern auch ueber eine kleine Niederlagenbedingung `friendly_force_neutralized`. Dafuer nutzt der Driver denselben vorhandenen LOS-/Damage-Pfad nun auch minimal fuer gegnerisches Gegenfeuer, sobald der Friendly-Trupp tatsaechlich Orders im Einsatz hat. Wenn danach keine Friendly-Unit mehr `fit` ist, wird der Einsatz mit `team_bravo` als Sieger aufgeloest und der bestehende Debrief-/Meta-Rueckfluss kann den Verlustzustand direkt uebernehmen.
- Offene Punkte: keine tieferen Fail-Grundtypen, keine Objective-Loss-Regel fuer Feindkontrolle, keine ausgebaute Gegner-KI und keine respawn-sensitive Missionsfortsetzung nach Squad-Wipe.
- Risiken: der Schritt bleibt bewusst klein und slice-orientiert; ein kompletter Friendly-Wipe beendet die Mission aktuell sofort, noch bevor der bereits vorhandene verzoegerte FOB-Respawn den ganzen Trupp wieder in den Einsatz bringen koennte. Eine spaetere echte V1-Respawn-Policy muss diese Vereinfachung explizit ersetzen statt weitere Sonderfaelle darum zu stapeln.
- Naechster Schritt: spaeter nur bei eigenem Task den bestehenden Debrief-Rueckfluss und die Objective-/Fail-Gruende weiter schaerfen, falls das fuer den Mission-Loop wirklich benoetigt wird.

### Minimal Debrief Result Clarity
- Status: implementiert
- Stand: der bestehende Meta-Rueckfluss traegt jetzt neben `won/lost` auch das aktive Missionsziel, den konkreten Missionsendgrund und den letzten kleinen Objective-Zustand in den vorhandenen Debrief- und FOB-Pfad. `MetaLayerFlow` sammelt dafuer direkt aus dem vorhandenen `MissionCombatLoopDriver` nur `mission_goal`, `resolution_reason` und `objective_state`; `DebriefScreen` und `FOBScreen` zeigen daraus im bestehenden Textblock klarer an, ob der Einsatz z. B. ueber `OBJECTIVE SECURED`, `ENEMY FORCE NEUTRALIZED` oder `FRIENDLY FORCE NEUTRALIZED` beendet wurde.
- Offene Punkte: keine ausgebaute Debrief-Architektur, keine Missionschronik, keine tieferen Statistiken und keine neuen Panels oder Meta-Manager.
- Risiken: der Schritt bleibt bewusst nur Text-/Rueckflussklarheit im vorhandenen Screen-Pfad; spaetere echte Ergebnis- oder Kampagnenauswertung sollte diese kleinen Hilfstexte explizit ersetzen statt weitere Logik in UI-Skripten zu sammeln.
- Naechster Schritt: spaeter nur bei eigenem Task weitere kleine Missionsgruende oder Follow-up-Folgen ergaenzen, wenn das fuer den V1-Loop wirklich gebraucht wird.
