# IMPLEMENTATION_STATUS

## Template
### Bereich
- Status:
- Stand:
- Offene Punkte:
- Risiken:
- Naechster Schritt:

## Aktueller Startzustand

### TASK_001 – RuntimeLeader / FTL
- Status: implementiert
- Stand: `RuntimeLeader` als eigene `Node`-Komponente mit `class_name`, Signalen fuer Promotion, Demotion, Assignment und Command-Weitergabe sowie der API `promote()`, `demote()`, `assign(entity)` und `command(order)` eingefuehrt.
- Offene Punkte: keine FTL-Ausfuehrungslogik, keine Befehlsinterpretation, keine EventRouter- oder SimulationRoot-Anbindung, keine Szenenverdrahtung.
- Risiken: Signalvertraege und Zustandsbasis stehen, die spaetere Einbindung in autoritative Gameplay-Systeme muss konsistent bleiben.
- Naechster Schritt: RuntimeLeader an EventRouter und SimulationRoot anbinden, sobald die Folgesysteme implementiert sind.

### TASK_002 – EventRouter
- Status: implementiert
- Stand: `EventRouter` als eigene `Node`-Komponente mit Signalen fuer Squad-Commands, Unit-Ausfaelle, Threat-Meldungen, Leader-Wechsel und Respawn-Anfragen sowie schlanken Routing-Methoden eingefuehrt.
- Offene Punkte: keine RuntimeLeader-Anbindung, keine Missionslogik, kein Autoload, keine SimulationRoot- oder Registry-Integration.
- Risiken: Die Signalvertraege stehen, die spaetere Einbindung muss ohne harte Direktkopplung zwischen Runtime-Systemen, UI und Autoritaetslogik erfolgen.
- Naechster Schritt: EventRouter an kommende Systeme anbinden, sobald SimulationRoot und weitere Laufzeitkomponenten existieren.

### TASK_003 – SimulationRoot mit Command- und Effects-Queues, deterministischer Tick-Verarbeitung in `_physics_process()`, Guard-Checks, Stub-Apply-Methoden und `tick_processed`-Signal eingefuehrt.
- Offene Punkte: keine Gameplay-Mechanik, keine Missionslogik, keine Registry- oder UpdateManager-Anbindung, keine Zustandsmutation an fremden Nodes.
- Risiken: Die autoritative Verarbeitungsstruktur steht, die spaetere Befehls- und Effektsemantik muss strikt innerhalb von `SimulationRoot` bleiben.
- Naechster Schritt: konkrete Command- und Effect-Typen einfuehren, sobald die Folgesysteme definiert sind.

### TASK_013 – Commander Command Model
- Status: implementiert
- Stand: `CommanderCommand` als leichtgewichtiges datenorientiertes Modell unter `res://scripts/command/commander_command.gd` eingefuehrt; formalisiert die aktuell bekannten Commander-Befehlstypen `move`, `take`, `defend` und `flank` sowie `priority`, `unit_id`, `team_id`, optional `target_position` und `phase`.
- Offene Punkte: keine echte Befehlsausfuehrung, keine FTL-Entscheidungslogik, keine UI-Bindings und keine tiefere Command-Semantik ueber den reinen Datenvertrag hinaus.
- Risiken: Der aktuelle Vertrag ist bewusst klein und Dictionary-kompatibel; spaetere Erweiterungen muessen die bestehende `"type"`-Kompatibilitaet zu RuntimeLeader/EventRouter/SimulationRoot erhalten.
- Naechster Schritt: das Modell bei Bedarf in kleine Integrationspfade einspeisen, ohne die bestehenden Runtime-Systeme von Dictionary-Vertraegen abrupt zu entkoppeln.

### TASK_014 – FTL Task Model
- Status: implementiert
- Stand: `FTLTask` als leichtgewichtiges datenorientiertes Modell unter `res://scripts/ftl/ftl_task.gd` eingefuehrt; formalisiert die minimalen FTL-Task-Typen `seek_cover`, `move_to_area`, `engage_in_area`, `hold_position` und `retreat` sowie `priority`, `unit_id`, `team_id`, optional `target_position`, `target_area_id`, `source_command_type` und `phase`.
- Offene Punkte: keine echte Task-Ausfuehrung, keine RuntimeLeader-AI, keine Uebersetzungslogik aus Commander-Befehlen und keine UI-Bindings.
- Risiken: Das Modell ist bewusst klein und dictionary-orientiert; spaetere Erweiterungen sollten diese Datenkompatibilitaet erhalten und keine versteckte Ausfuehrungslogik in das Modell ziehen.
- Naechster Schritt: bei Bedarf spaeter einen kleinen, expliziten Uebersetzungspfad von Commander-Commands zu FTL-Tasks ergaenzen, ohne die Modelle eng zu koppeln.

### TASK_015 – Command to FTLTask Translator
- Status: implementiert
- Stand: ein schlanker `CommandToFTLTaskTranslator` unter `res://scripts/command/command_to_ftltask_translator.gd` uebersetzt gueltige `CommanderCommand`-Daten in `FTLTask`-Daten.
- Offene Punkte: keine echte FTL-Entscheidungslogik, keine Task-Queue, keine RuntimeLeader-Erweiterung und keine Ausfuehrung in `SimulationRoot`.
- Risiken: Die V1-Abbildung ist bewusst einfach und statisch; spaetere feinere taktische Zerlegung von `take` und `flank` muss explizit und separat eingefuehrt werden.
- Naechster Schritt: spaeter Integration in RuntimeLeader / SimulationRoot, ohne neue Kopplungen aufzubauen.
### TASK_018 – FTL-State-Modell minimal
- Status: implementiert
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


### TASK_020 – UnitCommand Stub (fruehe Version)
> Hinweis: Duplikat der TASK_020-Sektion oberhalb; enthaelt die urspruengliche Zusammenfassung.
- Status: implementiert
- Stand: ein minimaler `UnitCommand`-Stub wurde als leichtgewichtiges Datenmodell eingefuehrt; dient als kleine formale Grundlage fuer spaetere Unit-bezogene Runtime-Kommandos ohne echte Ausfuehrungslogik.
- Offene Punkte: keine echte Unit-Ausfuehrung, keine Bewegung, keine Kampf- oder Missionslogik.
- Risiken: Das Modell ist bewusst klein; spaetere Erweiterungen muessen kompatibel zur bestehenden Daten- und Runtime-Struktur bleiben.
- Naechster Schritt: spaeter an Runtime-Status und minimale Simulationspfade anbinden.

### TASK_021 – TestUnit Runtime Status (fruehe Version)
> Hinweis: Duplikat der TASK_021-Sektion oberhalb; enthaelt die urspruengliche Zusammenfassung.
- Status: implementiert
- Stand: fuer `TestUnit` existiert ein minimales Runtime-Statusmodell mit einfachen Zustandswerten wie `idle`, `assigned`, `pending_move` und `holding`.
- Offene Punkte: keine echte Bewegungslogik, keine KI, keine Kampfzustandslogik.
- Risiken: Der Status ist rein vorbereitend; spaetere Runtime-Uebergaenge muessen weiter ueber SimulationRoot und klar definierte Datenpfade laufen.
- Naechster Schritt: an einfache sichtbare Reaktionen und minimale Move-Tests anbinden.

### TASK_022 – FTLTask to Unit Assignment (fruehe Version)
> Hinweis: Duplikat der TASK_022-Sektion oberhalb; enthaelt die urspruengliche Zusammenfassung.
- Status: implementiert
- Stand: ein minimaler Datenfluss wurde ergaenzt, ueber den ein `FTLTask` einer `TestUnit` zugeordnet werden kann; dient nur als Referenz- und Integrationsnachweis.
- Offene Punkte: keine echte Task-Ausfuehrung, keine Taktiklogik, keine Bewegungs- oder Aktionsverarbeitung.
- Risiken: Die Zuordnung ist aktuell bewusst leichtgewichtig; spaetere Erweiterungen muessen die Trennung zwischen Datenfluss, RuntimeLeader und SimulationRoot erhalten.
- Naechster Schritt: in eine minimale sichtbare Missionsreaktion ueberfuehren.

### TASK_023 – Multiple Units per FTL (fruehe Version)
> Hinweis: Duplikat der TASK_023-Sektion oberhalb; enthaelt die urspruengliche Zusammenfassung.
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
### Minimal Combat Loop Test (Phase 6 – Zwischen-Implementierung)
- Status: implementiert
- Stand: die Missions-Testszene enthaelt jetzt zwei Gegner-`TestUnit`-Instanzen mit eigener Team-ID; ein kleiner `MissionCombatLoopDriver` prueft direkten LOS-Kontakt zwischen Friendly- und Enemy-Units, enqueued darauf basierend minimale `damage`- und `bleedout`-Effects in `SimulationRoot` und markiert den Fight als beendet, sobald alle Gegner nicht mehr `fit` sind.
- Offene Punkte: keine Gegen-KI, keine Waffenvielfalt, keine Deckungslogik, keine Respawn- oder Eliminierungsmechanik und keine komplexe Team-Auswertung.
- Risiken: der Combat-Loop ist bewusst ein kleiner Integrationspfad fuer die Testszene; spaetere echte Combat-Systeme muessen den Glue-Code explizit ersetzen, statt ihn still auszubauen.
- Naechster Schritt: bei Bedarf den symmetrischen Gegnerpfad oder eine spaetere Eliminierungsstufe in eigenen Tasks aufbauen, ohne die autoritative Rolle von `SimulationRoot` aufzuweichen.

### Minimal Combat Control Behavior (Phase 6 – Zwischen-Implementierung)
- Status: implementiert
- Stand: `UnitCommand`, `UnitRuntimeStatus` und `TestUnit` tragen jetzt einen kleinen datenbasierten Feuerstatus mit `fire_at_will` und `hold_fire`; `engage_area` fuehrt auf einen expliziten `engaging`-Zustand, waehrend `move_to_position` als `pending_move` mit `hold_fire` erhalten bleibt. `RuntimeLeader` leitet diesen Status minimal aus dem aktuellen FTL-Task ab, und der bestehende `MissionCombatLoopDriver` erlaubt Angriffe nur noch bei `fire_at_will` plus engage-/holding-aehnlichem Zustand.
- Offene Punkte: keine groessere Combat-Logik, keine Rules-of-Engagement-Varianten, keine komplexe Zielwahl und keine Gegner-Ausweitung ueber den bestehenden Testpfad hinaus.
- Risiken: die Steuerung bleibt bewusst testpfadbezogen; spaetere echte Kampfsteuerung sollte diese Minimalregeln explizit ablösen statt sie still zu verkomplizieren.
- Naechster Schritt: bei Bedarf spaeter weitere Commander-/FTL-Befehlstypen mit klarer Feuerregel abbilden und nur dann eine komplexere Zielwahl ergaenzen, wenn dafuer ein eigener Task vorliegt.
### TASK_033 – Minimal Meta Layer (Heimatbasis + FOB)
- Status: implementiert
- Stand: ein kleiner menuegetriebener Meta-Layer startet jetzt ueber `res://scenes/meta/meta_layer_test.tscn`; ein `HomebaseTestScreen` zeigt die verfuegbaren Friendly-TestUnits und erlaubt eine einfache Teamzusammenstellung, ein `FOBTestScreen` zeigt das uebertragene Team und startet daraus die bestehende Missions-Testszene. Die Auswahl wird ueber einen schlanken `MetaLayerFlow` ohne Autoload oder neue grosse Szenenarchitektur an die Missionsszene weitergereicht.
- Offene Punkte: keine Persistenz, keine Skill-/Loadout-/Soziallogik, keine Reise- oder Meta-Simulation und kein Rueckweg aus der Mission in den Meta-Layer.
- Risiken: der Datenfluss ist bewusst klein und screen-getrieben; spaetere echte Meta-Systeme muessen diesen Testpfad explizit erweitern statt ihn still zu einer grossen UI- oder Persistenzschicht auszubauen.
- Naechster Schritt: spaeter nur bei eigenem Task weitere Meta-Funktionen wie Respawn-/Transferlogik oder einfache Missionsauswertung anhaengen.
### TASK_034 – Minimal Mission Return Flow (FOB-Rueckfluss)
- Status: implementiert
- Stand: der bestehende `MetaLayerFlow` bindet jetzt das Missionsende aus dem `MissionCombatLoopDriver` direkt an den Meta-Layer an, sammelt den minimalen Teamzustand der eingesetzten Friendly-Units ein und zeigt daraus einen kleinen Debrief-Screen mit Ergebnis und Rueckgabeoptionen. Die FOB kann den letzten Missionsausgang samt Teamzustand anzeigen, und sowohl der Rueckweg Debrief -> FOB als auch Debrief -> Homebase sind minimal moeglich.
- Offene Punkte: keine Persistenz, keine Nachsorge-/Heilungslogik, keine Kampagnenauswertung und kein Rueckfluss tieferer Missionsmetriken.
- Risiken: der Rueckfluss ist bewusst klein und screen-getrieben; spaetere echte Meta- oder Kampagnenlogik sollte diesen Glue-Code explizit erweitern statt ihn still zu einer grossen Ergebnisarchitektur auszubauen.
- Naechster Schritt: spaeter bei Bedarf nur in eigenen Tasks weitere Meta-Rueckfluesse wie Respawn-/Zeitlogik oder einfache Ergebnisfolgen anhaengen.

### TASK_035 – Minimal Tactical Order Behavior
- Status: implementiert
- Stand: `RuntimeLeader` leitet jetzt fuer `defend`, `move` und `flank` kleine taktische Unterschiede in `UnitCommand` und `UnitRuntimeStatus` ab: `defend`/`hold` bleibt in Position, traegt erhoehten `cover_score` und darf feuern, `move` bleibt bei `hold_fire`, und `flank` bekommt einen seitlichen Zieloffset sowie einen kleinen `attack_bonus`. `SimulationRoot` beruecksichtigt diese Minimalwerte im bestehenden Damage-Pfad, und die Missions-Testszene zeigt jetzt drei parallele Friendly-Orders mit unterscheidbarem Verhalten.
- Offene Punkte: keine komplexe Deckungsarchitektur, keine echte Taktik-KI, keine Formation, keine Navigation und keine ausgebaute Zielpriorisierung ueber den kleinen Testpfad hinaus.
- Risiken: die Unterschiede bleiben bewusst daten- und testszenenbasiert; spaetere echte Taktiksysteme sollten diese Minimalableitungen explizit ersetzen statt sie still weiter aufzublasen.
- Naechster Schritt: spaeter nur bei eigenem Task feinere Deckungs-, Zielwahl- oder Rollenregeln ergaenzen und dabei die autoritative Rolle von `SimulationRoot` beibehalten.

### Minimal Tactical Readability (Phase 6/7 – Zwischen-Implementierung)
- Status: implementiert
- Stand: `TestUnit` zeigt in der Missions-Testszene jetzt kleine direkt an die Unit geheftete Status- und Event-Texte fuer `MOVE`, `DEFEND`, `FLANK`, `ENGAGE`, `DOWN` und `BLEEDOUT` sowie `HF` / `FAW` und sichtbaren LOS-Kontakt. `MissionCombatLoopDriver` erzeugt zusaetzlich eine kleine Kontaktlinie, eine kompakte Event-Anzeige, einen klaren Siegerhinweis und ein leicht entschleunigtes Angriffstempo, damit Treffer, Down/Bleedout und Combat-Ende beobachtbarer bleiben.
- Offene Punkte: keine groessere HUD-/Debug-Architektur, keine Politur, keine Animationen und keine komplexe Zeitsteuerung.
- Risiken: die Lesbarkeitshilfen bleiben bewusst testszenenbezogen; spaetere echte UI- oder Debug-Systeme sollten diesen kleinen Pfad explizit ersetzen statt ihn still zu einer grossen Overlay-Schicht auszubauen.
- Naechster Schritt: spaeter nur bei eigenem Task weitere gezielte Beobachtbarkeit wie einfache Threat-/Objective-Hinweise ergaenzen, ohne die Szene in eine Debug-Framework-Struktur zu ziehen.

### Minimal Tactical Input UI (Phase 6/7 – Zwischen-Implementierung)
- Status: implementiert
- Stand: die Missions-Testszene startet jetzt neutral ohne automatische Initial-Orders; drei kleine Unit-gebundene `MissionCommandFlowDriver` koennen wiederholt genutzt werden, und ein schlanker `MissionTacticalSandboxController` ergaenzt Hotkeys plus vier kleine Buttons fuer `move`, `defend`, `flank` und `take`. Die finalen Tasten sind jetzt klar: `LMB = Zielmarker setzen`, `1 = move`, `2 = defend`, `3 = flank`, `4 = take`, `Q/E = Fireteam ALL/BLUE/GOLD`, `R/F = Phase APPROACH/ASSAULT/HOLD`. Linksklick setzt den bestehenden Zielmarker direkt ueber die Canvas-/World-Koordinaten um; UI-Klicks werden ignoriert und freie Klicks auf den sichtbaren Weltbereich begrenzt. Friendly-Units nutzen in der Testszene `astronautA_SW`, Enemy-Units `astronautB_SW` statt Polygon-Placeholdern.
- Offene Punkte: die Fireteam- und Phase-Umschaltung bleibt bewusst szenenlokal; es gibt keine grosse Commander-UI, keine Auswahlarchitektur und noch keine tiefere Phase-Wirkung im Combat-Loop.
- Risiken: der UI-Pfad darf keine Gameplay-Wahrheit uebernehmen; er bleibt ein leichter Command-Ausloeser fuer den bestehenden Commander -> FTL -> Unit -> SimulationRoot-Flow. Spaetere echte Commander- oder HUD-Systeme sollten diesen kleinen Szenen-Controller explizit ersetzen statt ihn still auszubauen.
- Naechster Schritt: nur bei eigenem Task gezielt weiter verfeinern, etwa Marker-/Objective-Lesbarkeit oder spaetere echte Fireteam-/Phasenwirkung, ohne neue UI- oder Input-Architektur aufzubauen.

### Iso Map V2 Layout (Phase 5/6 – Zwischen-Implementierung)
- Status: implementiert
- Stand: die Missions-Testszene nutzt weiter `res://scenes/maps/iso_map_v2_layout.tscn`, aber die Bodenform wurde jetzt wieder explizit zu einer klaren grossen Iso-Raute aufgebaut statt zu einer asymmetrischen Freiform. Die sichtbare Bodenbasis besteht weiterhin ausschliesslich aus wiederholten `terrain_SW.png`-Kacheln; es gibt keine Gebaeude, keine Cliff-Stufen und keine zweite Hoehe. Die Richtungs-Konvention bleibt fuer diesen Pfad verbindlich: obere Kante = `N`, untere Kante = `S`, linke Kante = `W`, rechte Kante = `E`, obere linke Ecke = `NW`, obere rechte Ecke = `NE`, untere linke Ecke = `SW`, untere rechte Ecke = `SE`. `terrain_SW.png` bleibt unveraendert die Referenzkachel fuer `SW` = unten links / southwest; es wurde nichts frei gedreht. Friendly- und Enemy-Spawn sowie `objective_point` wurden in dieser klaren Rautenflaeche weiter auseinander und weniger direkt achsig gesetzt, damit die Karte ruhiger lesbar und als Testflaeche laenger beobachtbar bleibt. `MissionTestSetup` liest die Marker weiterhin direkt aus der Map-Szene und richtet Friendlies, Enemies und den Zielmarker daran aus.
- Offene Punkte: die Map ist weiterhin nur Struktur und Marker, keine Gameplay-Wahrheit; es gibt noch keine Terrain-Metadaten fuer `walkable`, `blocks_los`, `cover` oder `orientation`, keine Hindernis- oder Hoehenlogik und keine spaetere Fireteam-Flanknutzung der optionalen Flank-Anker.
- Risiken: die Karte verbessert Iso-Lesbarkeit, Spacing und Beobachtungszeit, aber LOS und Combat bleiben auf dem bestehenden Slice weiter rein systemseitig und nicht terrainbasiert. Spaetere Terrain-Daten oder feineres Encounter-Tuning sollten explizit als eigene Daten- bzw. Balancing-Tasks folgen, statt still in die Szene hineinzuwachsen.
- Naechster Schritt: nur bei eigenem Task gezielt weitere Terrain-Daten oder eine spaetere feine Layout-Iteration ergaenzen, ohne ein grosses Tile-/Registry-System vorzuziehen.

### TASK_036 – Respawn-Logik
- Status: implementiert
- Stand: `UnitVitalStatus` kennt jetzt den Zustand `respawning`; `TestUnit` hat eine `respawn(spawn_position)`-Methode, die eine Unit von `down`/`bleedout` zurueck auf `fit` setzt, Health auf Maximum zuruecksetzt und die Unit an die uebergebene Spawn-Position verschiebt. `SimulationRoot` verarbeitet jetzt einen `respawn`-Effect autoritativ. Ein neuer `RespawnManager` unter `res://scripts/core/respawn_manager.gd` verwaltet timerbasierte Respawns pro Unit mit konfigurierbarem Spawn-Typ (Rover: 30s, FOB: 150s, Homebase: 270s). `MissionCombatLoopDriver` fordert automatisch Respawns fuer eliminierte Units an und setzt den Bleedout-Tracker bei erfolgreichem Respawn zurueck. Friendlies und Enemies koennen jetzt beide bleedouten und respawnen.
- Offene Punkte: keine Respawn-Limitierung, keine Respawn-Warteschlange, keine sichtbare Timer-Anzeige und keine differenzierte Spawn-Punkt-Auswahl.
- Risiken: der Respawn-Pfad ist bewusst klein und timerbasiert; spaetere echte Respawn-Mechaniken (begrenzte Leben, Sanitaeter, Evakuierung) muessen diesen Minimalpfad explizit erweitern.
- Naechster Schritt: bei Bedarf spaeter Respawn-Timer-Anzeige oder differenzierte Spawn-Punkte in eigenen Tasks ergaenzen.

### TASK_037 – Rover/Frachter Respawn-Punkte
- Status: implementiert
- Stand: `RespawnManager` unterstuetzt jetzt drei Spawn-Typen mit den V1-Zeitwerten: `rover` (30s), `fob` (150s) und `homebase` (270s). Spawn-Positionen werden pro `team_id` gesetzt und von `MissionTestSetup` aus den bestehenden Map-Markern (`spawn_alpha`, `spawn_bravo`) automatisch uebernommen. Die Missions-Testszene nutzt standardmaessig `rover`-Respawn fuer schnelle Testzyklen.
- Offene Punkte: keine sichtbaren Spawn-Punkt-Marker in der Szene, keine Fahrzeug-Darstellung, keine Spawn-Punkt-Auswahl durch den Spieler und keine unterschiedlichen Spawn-Punkte pro Typ.
- Risiken: die Spawn-Punkte sind bewusst nur Positionsdaten ohne eigene Nodes oder Darstellung; spaetere Rover-/Frachter-Mechaniken muessen als eigene sichtbare Szenenelemente folgen.
- Naechster Schritt: spaeter bei eigenem Task sichtbare Spawn-Punkt-Marker oder Fahrzeug-Stubs in der Missionsszene ergaenzen.

### Symmetrischer Gegner-Kampfpfad (Phase 6/7 – Zwischen-Implementierung)
- Status: implementiert
- Stand: `MissionCombatLoopDriver` erlaubt jetzt bidirektionalen Kampf; Enemies koennen Friendlies angreifen, wenn sie `fit` sind und LOS-Kontakt haben. Friendlies koennen ebenfalls downed und bleedout werden, mit anschliessendem Respawn ueber den `RespawnManager`.
- Offene Punkte: keine echte Gegner-KI, keine Positionierung, keine Deckungssuche und keine Gegner-Befehlskette.
- Risiken: der Gegnerpfad ist bewusst nur ein symmetrischer Angriffspfad ohne eigene taktische Logik; spaetere Gegner-KI muss explizit und separat folgen.
- Naechster Schritt: bei Bedarf in eigenen Tasks Gegner-Verhalten oder einfache Positionierungslogik ergaenzen.

### TASK_038 - Fireteam-Aufteilung
- Status: implementiert
- Stand: `TestUnit` traegt jetzt eine eigene `fireteam_id`, spiegelt diese in `UnitRuntimeStatus` und zeigt sie in der Missions-Testszene als kleinen farbigen `BLUE`-/`GOLD`-Text direkt neben dem bestehenden Statuslabel an. `MissionTestSetup` weist Alpha und Bravo fest `blue` sowie Charlie fest `gold` zu, ohne die bestehende Driver- oder Hotkey-Logik im `MissionTacticalSandboxController` umzubauen.
- Offene Punkte: keine dynamische Fireteam-Zuweisung zur Laufzeit, keine weitergehende Fireteam-UI und noch keine Nutzung der neuen Fireteam-Daten ausserhalb der bestehenden Testszene und des Runtime-Status.
- Risiken: die Fireteam-Wirkung bleibt fuer diesen Slice bewusst auf die bestehende Auswahl-/Driver-Filterung plus sichtbare Unit-Zuordnung begrenzt; spaetere Fireteam-Mechaniken muessen die neue Datenbasis explizit nutzen, statt Logik still in UI oder Szene-Glue zu verstecken.
- Naechster Schritt: mit TASK_039 die bestehende Phasenwahl in eine kleine echte Laufzeitwirkung ueberfuehren, ohne die Commander-/Driver-Architektur zu verbiegen.

### TASK_039 - Phasen-Wirkung
- Status: implementiert
- Stand: `CommanderCommand`, `UnitCommand` und `UnitRuntimeStatus` tragen jetzt eine kleine echte Phasenwirkung. `RuntimeLeader` leitet `APPROACH`, `ASSAULT` und `HOLD` in minimale Unterschiede fuer `fire_status`, `move_speed_factor` und `cover_score` ueber, `SimulationRoot` respektiert den neuen Geschwindigkeitsfaktor autoritativ bei Bewegung, und `TestUnit` zeigt die aktive Phase als kleines zusaetzliches Label direkt an der Unit an.
- Offene Punkte: keine tiefere Combat-Loop-Interpretation jenseits der kleinen Ableitungen, keine erweiterten Rules of Engagement und keine Phase-KI fuer Gegner.
- Risiken: die Wirkung bleibt bewusst klein und datenorientiert; spaetere komplexere Phasenlogik sollte explizit auf den neuen Feldern aufbauen statt versteckte Sonderfaelle in UI oder Drivern zu sammeln.
- Naechster Schritt: den `take`-Befehl an ein echtes Objective mit Capture-Zustand anbinden.

### TASK_040 - Take-Befehl und Objective
- Status: implementiert
- Stand: ein neues `ObjectiveStatus`-Datenmodell haengt jetzt am `SimulationRoot`; pro Tick wird autoritativ geprueft, welche `fit`-Units im Capture-Radius stehen, contested-Zustaende blockieren Fortschritt und bei vollem Fortschritt wechselt der Besitzer. `MissionTestSetup` erstellt den Objective-Zustand aus dem bestehenden `objective_point`-Marker, `take` snappt den Zielmarker auf diesen Punkt, `engage_area` bewegt Units nun auch zum Objective, und ein kleines `MissionObjectiveStatusView` zeigt Besitzer und Capture-Fortschritt direkt an der Szene an.
- Offene Punkte: weiterhin nur ein Objective gleichzeitig, keine komplexere Zonen-Geometrie, keine Gegner-Capture-Orders und keine Besitzer-Boni.
- Risiken: der Objective-Pfad ist bewusst ein einzelner, leichter Vertical-Slice ohne grosse Objective-Architektur; spaetere Missionssysteme sollten den Datenvertrag explizit erweitern statt ihn still im Szenen-Glue wachsen zu lassen.
- Naechster Schritt: aus dem neuen Objective-Zustand eine echte Sieg-/Niederlagenlogik fuer den bestehenden Debrief-Flow ableiten.

### TASK_041 - Siegbedingung
- Status: implementiert
- Stand: `MissionCombatLoopDriver` unterstuetzt jetzt die Siegbedingungstypen `elimination`, `objective_capture` und `objective_defense`, prueft zusaetzlich eine Niederlage bei gleichzeitig komplett nicht mehr `fit`en Friendlies und liefert ein erweitertes `mission_result` mit `result`, `win_condition_type`, `objective_captured` und `duration_seconds`. Die Missions-Testszene nutzt standardmaessig `objective_capture`, und `MetaLayerFlow` plus `DebriefTestScreen` reichen das reichere Ergebnis bis in den bestehenden Debrief-/FOB-Rueckfluss weiter.
- Offene Punkte: keine mehrstufigen Missionsziele, keine Zeitlimit-Niederlage und keine gegnerische Objective-Logik.
- Risiken: die Missionsauswertung bleibt bewusst klein und testszenenbezogen; spaetere Kampagnen- oder Multi-Objective-Systeme muessen darauf explizit aufbauen statt den Combat-Driver schleichend zu ueberladen.
- Naechster Schritt: die bestehende Respawn-Logik fuer den Spieler sichtbar machen.

### TASK_042 - Respawn-Timer-Anzeige
- Status: implementiert
- Stand: `RespawnManager` stellt jetzt `get_pending_respawns()` und `get_remaining_time(unit_id)` bereit. Ein neues `MissionRespawnOverlay` zeigt in der Missions-Testszene aktuell laufende Respawns unter dem Command-Feedback an, waehrend `TestUnit` bei `respawning` den verbleibenden Countdown direkt im Unit-Statuslabel anzeigt. `MissionTestSetup` verdrahtet dazu den `RespawnManager` explizit an die Units.
- Offene Punkte: keine Queue-Ansicht, keine Fortschrittsbalken, keine Spawn-Punkt-Auswahl und keine groessere HUD-Struktur.
- Risiken: die Anzeige bleibt bewusst ein kleiner Polling-Overlay-Pfad fuer die Testszene; spaetere echte HUD-Systeme sollten diese Minimalanzeige explizit ersetzen statt sie still auszubauen.
- Naechster Schritt: den Vertical Slice gegen die naechsten Gegner-Tasks absichern und erst dann weitere Gegnerlogik aufsetzen.

### TASK_043 - Einfache Gegner-Positionierung
- Status: implementiert
- Stand: `MissionCombatLoopDriver` hat jetzt einen kleinen Enemy-Vormarschpfad mit `enemy_advance_enabled`, `enemy_advance_speed_factor` und `enemy_engage_distance`. `fit`e, aktive Enemy-Units enqueueen pro Tick ueber `SimulationRoot` einen `move_to_position`-Command Richtung Objective, stoppen aber bei LOS-Kontakt in Kampfdistanz und bleiben damit im bestehenden Combat-Loop feuersauber eingebettet. Nach Respawn oder Wellenaktivierung greifen dieselben Regeln automatisch erneut.
- Offene Punkte: keine Pfadplanung, keine Deckungssuche, keine Gegner-Befehlskette und keine feinere Zielwahl ueber den bestehenden Contact-Check hinaus.
- Risiken: die Bewegung bleibt bewusst ein sehr einfacher Objective-Marsch; spaetere KI- oder Terrain-Systeme muessen diesen Slice explizit ersetzen oder erweitern, statt Logik schleichend im Combat-Driver anzusammeln.
- Naechster Schritt: auf eingehenden Schaden eine kleine Repositionierung fuer Enemies aufsetzen.

### TASK_044 - Gegner-Reaktion auf Kontakt
- Status: implementiert
- Stand: `MissionCombatLoopDriver` reagiert jetzt auf eingehenden Schaden von Enemy-Units mit einer kleinen Repositionierung ueber den bestehenden `SimulationRoot.enqueue_command()`-Pfad. Die Zielposition wird bevorzugt weg vom bekannten Angreifer aufgebaut, faellt sonst auf einen zufaelligen Offset zurueck und ist ueber `enemy_reposition_*`-Exports fuer Distanz, Cooldown und Bewegungsgeschwindigkeit klein konfigurierbar.
- Offene Punkte: keine echte Deckungssuche, keine Retreat-Logik, keine Gruppenreaktion und keine taktische Bewertung des neuen Standorts.
- Risiken: der Reaktionspfad ist bewusst ein lokaler, eventgetriebener Minimal-Offset; spaetere Gegnerlogik sollte darauf explizit aufbauen statt viele Sonderfaelle in den Hit-Callback zu schieben.
- Naechster Schritt: Enemy-Spawns in einfache Wellen staffeln, damit die Mission zeitlich getragen wird.

### TASK_045 - Gegner-Wellen
- Status: implementiert
- Stand: ein neuer `EnemyWaveController` unter `res://scripts/tests/enemy_wave_controller.gd` staffelt Enemy-Units jetzt in konfigurierbare Wellen mit `wave_count`, `units_per_wave`, `wave_delay_seconds` und `first_wave_delay_seconds`. Noch nicht gestartete Units bleiben unsichtbar und aus dem `UnitRegistry` abgemeldet; beim Wellenstart werden sie an ihre Spawn-Position gesetzt, sichtbar, wieder registriert und vom bestehenden Enemy-Vormarsch uebernommen. Ein kleines Szenenlabel zeigt `WAVE x/y`, und der `MissionCombatLoopDriver` laesst Elimination-Sieg erst nach letzter Welle und ohne ausstehende Enemy-Respawns zu.
- Offene Punkte: keine dynamische Wellenzusammenstellung, keine verschiedenen Gegnertypen, keine Spawn-Richtungswahl und kein eigener Reinforcement-UI-Flow ausser der kleinen Szenenlesbarkeit.
- Risiken: der Wave-Controller bleibt bewusst ein leichter Testszenen-Node; spaetere Missions- oder Encounter-Systeme sollten ihn explizit ablösen oder erweitern statt Wellenlogik verteilt ueber Setup, Combat-Driver und Szene zu verstecken.
- Naechster Schritt: individuelle Skill-Werte an Units haengen, bevor diese das Gameplay beeinflussen.

### TASK_046 - Unit-Skill-Werte
- Status: implementiert
- Stand: `UnitSkills` unter `res://scripts/npc/unit_skills.gd` formalisiert jetzt `accuracy`, `speed`, `leadership` und `toughness` mit kleinem Dictionary-Roundtrip. `TestUnit` traegt dazu exportierte Skillwerte, baut daraus beim Initialisieren ein `UnitSkills`-Objekt und zeigt einen kompakten Skill-Hinweis direkt im bestehenden Debug-Label an. `MissionTestSetup` weist Friendlies und Enemies ueber `UnitRosterPresets` feste, leicht unterschiedliche Presets zu.
- Offene Punkte: noch keine Laufzeitentwicklung der Werte, keine Balancing-Arbeit und noch keine direkte Leadership-Wirkung.
- Risiken: die Skills sind bewusst kleine statische Unit-Daten; spaetere Progression oder Balancing-Systeme muessen diese Datenbasis explizit erweitern statt sie still in Szene-Properties zu zerstreuen.
- Naechster Schritt: die neuen Skillwerte in Trefferchance, Bewegung und Schadensreduktion einspeisen.

### TASK_047 - Skill-Wirkung im Combat
- Status: implementiert
- Stand: `SimulationRoot` leitet Trefferchance, Bewegungstempo und Schadensreduktion jetzt direkt aus den individuellen Unit-Skills ab. `accuracy` skaliert die `hit_chance` der angreifenden Unit mit Clamp auf 0.95, `speed` multipliziert den bestehenden `move_speed_factor`, und `toughness` reduziert den finalen Schaden nach einer einfachen, nachvollziehbaren Formel. `leadership` wird weiter mitgefuehrt, hat in diesem Slice aber noch keine eigene Wirkung.
- Offene Punkte: kein tieferes Balancing, keine situationsabhaengigen Modifikatoren und keine Fuehrungsqualitaets-Logik.
- Risiken: die Formeln sind bewusst einfach und testszenenfreundlich; spaetere Kampf- oder AI-Systeme sollten klare Erweiterungsschritte waehlen statt diese Minimalformeln still zu ueberladen.
- Naechster Schritt: einfache Persoenlichkeitsmerkmale auf die Skillbasis aufsetzen.

### TASK_048 - Einfache Persoenlichkeitsmerkmale
- Status: implementiert
- Stand: `UnitTrait` unter `res://scripts/npc/unit_trait.gd` liefert jetzt eine kleine Trait-Factory fuer `aggressive`, `cautious`, `steady`, `reckless` und `calm` samt Skill-Modifikatoren und Kurz-Tags. `TestUnit` kann ueber `trait_ids` bis zu zwei Traits laden, die effektiven Skills beim Initialisieren anpassen und ihre Tags im Debug-Label anzeigen. `UnitRosterPresets` vergibt dazu unterschiedliche Trait-Kombinationen an die Friendly-Units; Enemies bleiben im V1-Pfad traitlos.
- Offene Punkte: keine sozialen Beziehungen, keine Synergie-Effekte, keine Laufzeitveraenderung und kein Trait-Balancing.
- Risiken: Traits bleiben bewusst ein leichter Skill-Modifikator ohne eigene Gameplay-Subsysteme; spaetere Charakter- oder Squad-Systeme muessen diese kleine Datenbasis explizit weiterdenken statt versteckte Nebenlogik in `TestUnit` zu sammeln.
- Naechster Schritt: die neuen Unit-Details in der Homebase sichtbar machen.

### TASK_049 - Heimatbasis: Unit-Uebersicht mit Skills und Traits
- Status: implementiert
- Stand: `HomebaseTestScreen` zeigt in der Checkbox-Liste jetzt pro verfuegbarer Unit eine kompakte Detailzeile mit Skill-Kurzform und Trait-Tags. Die Daten werden bewusst aus `TestUnit`-Instanzen im Szenenbaum gelesen: dafuer baut der Screen einen kleinen unsichtbaren Preview-Root mit `TestUnit`-Kindern aus den `UnitRosterPresets` auf und liest daraus die gleichen Summary-Methoden wie in der Missionsszene. `MetaLayerFlow` bezieht die verfuegbaren Homebase-Units jetzt direkt aus denselben Presets.
- Offene Punkte: keine Sortierung, keine Vergleichsansicht, keine tiefe Detailseite und keine optionale Farbcodierung.
- Risiken: der Homebase-Pfad bleibt bewusst eine kleine Listenlesbarkeit ohne neue Registry oder Persistenzschicht; spaetere Meta-UI sollte diesen Preview-Ansatz explizit ersetzen, wenn ein echtes Daten-/Roster-System eingefuehrt wird.
- Naechster Schritt: den Slice lokal gegen Mission und Meta-Layer pruefen und dann fuer die naechsten Netzwerk-/Terrain-Aufgaben stabilisieren.

### TASK_050 - Server-autoritativer SimulationRoot
- Status: implementiert
- Stand: `SimulationRoot` besitzt jetzt `is_server_authoritative`, eine RPC-faehige `request_command()`-Einspeisung, Peer-zu-Team-Mapping und einen vorbereiteten Tick-Broadcast. Im Multiplayer-Modus verarbeitet nur noch der Server Commands und Effects lokal; Clients speichern den letzten Server-Snapshot und erhalten zusaetzlich zuverlaessige Vital-Updates. Ohne aktiven Peer oder bei deaktivierter Authority bleibt der bisherige Singleplayer-Pfad unveraendert.
- Offene Punkte: keine Latenz-Kompensation, keine Ownership-Uebertragung und keine generische Netzwerk-Abstraktionsschicht ausserhalb dieses Testslices.
- Risiken: der Authority-Pfad bleibt bewusst klein und direkt an der Missions-Testszene orientiert; spaetere groessere Multiplayer-Systeme sollten den Datenvertrag explizit erweitern, statt versteckte Sonderlogik neben `SimulationRoot` wachsen zu lassen.
- Naechster Schritt: eine minimale Host/Join-Lobby auf die neue Autoritaetsbasis setzen.

### TASK_051 - Host/Join mit Testteams
- Status: implementiert
- Stand: unter `res://scenes/tests/lobby_test.tscn` gibt es jetzt einen kleinen `LobbyTestScreen` mit `Host`, `Join` und host-only `Start Mission`. Host und Joiner verbinden sich lokal ueber `ENetMultiplayerPeer` auf Port `7777`, sehen denselben Status und starten dieselbe Missionsszene; `SimulationRoot` wird dabei server-autoritativ initialisiert. Bei Disconnect oder Verbindungsfehler wird sauber in die Lobby zurueckgekehrt.
- Offene Punkte: nur localhost/LAN-V1, keine Teamauswahl, kein Matchmaking, kein Session-Browser und kein reconnect.
- Risiken: die Lobby ist bewusst ein sehr kleiner Testszenen-Flow ohne Meta-Layer-Integration; spaetere echte Multiplayer-Menues sollten diesen Pfad explizit ersetzen statt ihn still auszubauen.
- Naechster Schritt: die bestehende Befehlskette ueber RPC an den Server umleiten.

### TASK_052 - Befehlsuebertragung ueber Netzwerk
- Status: implementiert
- Stand: `MissionCommandFlowDriver` schickt `UnitCommand`-Dictionaries im server-autoritativen Modus jetzt nicht mehr direkt an `enqueue_command()`, sondern an `SimulationRoot.request_command()` bzw. per `rpc_id(1, ...)` an den Host. `SimulationRoot` validiert Command-Typ, `unit_id` und Team-Zugehoerigkeit gegen das Peer-Mapping. `MissionCombatLoopDriver`, `RespawnManager` und `EnemyWaveController` fuehren ihre autoritativen Simulationsteile im Multiplayer nur noch auf dem Server aus; der Joiner bleibt in V1 Beobachter und bekommt keine lokale Command-Eingabe mehr.
- Offene Punkte: noch kein zweiter aktiver Commander, keine komplexere Autorisierung und keine Client-Prediction.
- Risiken: die Servervalidierung bleibt bewusst schlank und testszenenbezogen; spaetere PvP- oder Koop-Ausbaustufen sollten diese Checks explizit verstaerken statt sie ad hoc in UI oder Drivern zu verteilen.
- Naechster Schritt: den autoritativen Zustand sichtbar auf den Joiner spiegeln.

### TASK_053 - Synchronisierte Spielzustandsanzeige
- Status: implementiert
- Stand: `SimulationRoot` broadcastet jetzt pro Tick einen kompakten Snapshot fuer aktive Units (`unit_id`, Position, Runtime-/Vital-Kernstatus) plus Objective-Fortschritt an Clients; `TestUnit` kann diese Remote-Snapshots direkt anwenden und zeigt dadurch Bewegungen, Vital-Status und Respawn-Momente auch als Joiner korrekt an. `MissionCombatLoopDriver` synchronisiert Missionsresultat und Event-Feedback (`HIT`, `DOWN`, `BLEEDOUT`, `RESPAWNING`, Wellenhinweise) per RPC, sodass beide Peers denselben Debrief sehen.
- Offene Punkte: keine Snapshot-Pufferung, keine Lag-Kompensation, keine FoW-Differenzierung und keine feingranulare Kontakt-/Linien-Synchronisation.
- Risiken: der Sync bleibt bewusst ein einfacher V1-Snapshot-Pfad; spaetere groessere Multiplayer-Loops sollten diesen Datenstrom explizit weiterentwickeln statt mit immer mehr Einzelfeldern zu ueberladen.
- Naechster Schritt: nach dem Multiplayer-Prototyp den Terrain-Block gemaess Roadmap wieder lokal und datenorientiert ausbauen.

### TASK_054 - Terrain-Tile-Datenmodell und Registry
- Status: implementiert
- Stand: `TerrainTileData` unter `res://scripts/terrain/terrain_tile_data.gd` und `TerrainRegistry` unter `res://scripts/terrain/terrain_registry.gd` bilden jetzt ein kleines datenbasiertes Terrain-System mit `walkable`, `blocks_los`, `cover_value`, `height_level` und `surface_type`. Die Missions-Testszene besitzt einen eigenen `TerrainRegistry`-Node, und `MissionTestSetup` liest die bestehenden 64 Iso-Tiles aus `MapRoot/Terrain`, konfiguriert die Iso-Grid-Konvertierung passend zur bestehenden Karte und registriert alle Tiles mit Default- bzw. Szenenwerten.
- Offene Punkte: noch kein Editor fuer Terrain-Daten, keine separate Tile-Registry ueber mehrere Karten und keine Gameplay-Wirkung ausser den folgenden Terrain-Tasks.
- Risiken: die Grid-Konvertierung ist bewusst auf die bestehende 8x8-Iso-Testkarte zugeschnitten; spaetere Kartenvarianten sollten diese kleine Konfiguration explizit erweitern statt still neue Koordinatenannahmen in Mission-Glue zu streuen.
- Naechster Schritt: die neuen Tile-Daten fuer Bewegung ueber A*-Pfadsuche auswerten.

### TASK_055 - Walkability und einfaches A*-Pathfinding
- Status: implementiert
- Stand: `TerrainPathfinder` unter `res://scripts/terrain/terrain_pathfinder.gd` fuehrt jetzt eine kleine A*-Suche auf dem Iso-Grid aus und beruecksichtigt `walkable`, Hoehenunterschiede sowie vorbereitete Surface-Kosten. `SimulationRoot` nutzt die `TerrainRegistry` jetzt optional fuer `move_to_position`: wenn Terrain-Daten vorhanden sind, wird ein Wegpunktpfad aufgebaut und tile-basiert abgegangen; ohne Registry bleibt der bisherige Geradlinien-Fallback erhalten. `MissionTestSetup` markiert einige Tiles als nicht begehbar, damit der Pfad sichtbar um die Blocker fuehrt.
- Offene Punkte: keine lokale Kollisionsvermeidung zwischen Units, keine Pfad-Neuberechnung bei dynamischen Aenderungen und keine feinere Optimierung ueber den kleinen 64-Tile-Testfall hinaus.
- Risiken: der Pfad wird bewusst klein und command-lokal gespeichert; spaetere groeßere Karten oder dynamische Hindernisse sollten einen expliziten Recompute-Pfad bekommen statt diese V1-Logik still zu ueberladen.
- Naechster Schritt: Sichtlinien an die Terrain-Tiles binden.

### TASK_056 - LOS ueber Terrain-Tiles
- Status: implementiert
- Stand: `LineOfSightSystem` unterstuetzt jetzt optionale Terrain-Registries und prueft per einfachem Tile-Stepping, ob `blocks_los`-Tiles zwischen Quelle und Ziel liegen. Dabei wird die vorbereitete Hoehenregel direkt beruecksichtigt: hoehere Einheiten koennen ueber niedrigere Hindernisse hinwegsehen. `MissionCombatLoopDriver` gibt die `TerrainRegistry` an alle LOS-Aufrufe weiter, sodass Contact und Enemy-Hold-Checks auf der Testkarte jetzt von Terrain-Blockern beeinflusst werden.

### Wall-Overlay-System im Map-Editor
- Status: implementiert
- Stand: Der Map-Editor unterstuetzt jetzt individuelle Wand- und Eckenstuecke als Overlay-Sprites ueber dem Terrain.

#### Tile-Katalog (`data/terrain_tile_catalog.json`)
9 Eintraege: `ground_flat`, 4 gerade Mauern (`wall_straight_se/sw/ne/nw`), 4 Ecken (`wall_corner_se/sw/ne/nw`).
Wand-Tiles haben kein eigenes `texture_path` — der Boden zeigt `terrain_SW.png`, die Mauer wird als Overlay daruebergelegt.

#### Namenskonvention
- **Gerade Mauern**: `wall_straight_XX` — XX ist die Laufrichtung der Mauer (SE = Mauer laeuft von NW nach SE).
- **Ecken**: `wall_corner_XX` — XX ist die Grid-Richtung, `display_name` zeigt die visuelle Position:
  - `wall_corner_se` = "Ecke Ost" (rechts)
  - `wall_corner_sw` = "Ecke Sued" (unten)
  - `wall_corner_ne` = "Ecke Nord" (oben)
  - `wall_corner_nw` = "Ecke West" (links)

#### Kenney-Sprite-Zuordnung
Die Kenney `corridor_wallCorner_XX.png`-Dateien benennen die Innenseite der Kurve. Im Code werden sie daher gegenlaefig gemappt:
- `wall_corner_se` -> `WALL_CORNER_NW` (corridor_wallCorner_NW.png)
- `wall_corner_sw` -> `WALL_CORNER_NE` (corridor_wallCorner_NE.png)
- `wall_corner_ne` -> `WALL_CORNER_SW` (corridor_wallCorner_SW.png)
- `wall_corner_nw` -> `WALL_CORNER_SE` (corridor_wallCorner_SE.png)

#### Sprite-Platzierung
- Alle Sprites: `centered = false`, Position = `world_position - KENNEY_DIAMOND_CENTER`
- `KENNEY_DIAMOND_CENTER = Vector2(256, 315)` — Diamant-Mitte aller Kenney 512x512-Sprites
- `WallContainer` hat `y_sort_enabled = true` und `z_index = -13` — suedlichere Mauern ueberdecken noerdlichere korrekt

#### Tile-Datenfelder — aktuelle Semantik und Grenzen

| Feld | Typ | Aktuell | Gameplay-Wirkung |
|------|-----|---------|-----------------|
| `surface_type` | String | Pro Tile, nicht pro Objekt | Beeinflusst Bewegungsgeschwindigkeit und Pfadkosten (`road`=1.4x, `sand`=0.6x, `rock`=0.8x) |
| `walkable` | bool | Ganzes Tile blockiert | Pathfinder lehnt Tile komplett ab — keine Richtungsinformation |
| `blocks_los` | bool | Ganzes Tile blockiert | LOS-System prueft pro Tile — keine Richtungsinformation |
| `cover_value` | int 0-100 | Pro Tile | Combat: -0.35 Hit-Chance fuer Ziel, +0.05 fuer Angreifer, -0.2 Schaden (max 80) |
| `height_level` | int 0-2 | Terrainhoehe (Gelaende) | Pathfinding: max 1 Level Differenz bei Cliff, +0.5 Kosten pro Level. Combat: +0.1 Accuracy-Bonus pro Level ueber Ziel |
| `object_height` | int 0-3 | Objekthoehe (Mauer, Fels) | LOS: Blocker-Hoehe = `height_level + object_height`. Pathfinding: nicht verwendet |
| `edge_type` | String | "cliff" oder "slope" | Cliff: blockiert Bewegung bei height_diff > 1, Overlay mit `terrain_sideCliff_*.png`. Slope: immer begehbar, +1.0 Kosten pro Level, Overlay mit `terrain_side_*.png` |

#### Objekt-Typen im Katalog

| type_id | display_name | object_height | cover | blocks_los | Beschreibung |
|---------|-------------|--------------|-------|------------|-------------|
| `rock_small` | Fels klein | 1 | 30 | nein | Kleiner Fels, bietet Deckung aber blockiert nicht LOS |
| `rock_large` | Fels gross | 2 | 50 | ja | Grosser Fels, blockiert LOS und bietet starke Deckung |
| `wall_straight_*` | Mauer XX | 2 | 0 | ja | Gerade Mauerstuecke |
| `wall_corner_*` | Ecke XX | 2 | 0 | ja | Eckverbindungen |

**Bekannte Design-Luecken:**
- `walkable` und `blocks_los` sind nicht richtungsabhaengig. Eine Mauer SW blockiert aktuell das ganze Tile statt nur die NW-SE-Kante. Fuer feingranulare Wandmechanik muesste ein edge-basiertes System (`blocked_edges: ["nw-se"]`) eingefuehrt werden.
- `surface_type` beschreibt aktuell den Boden unter der Mauer (z.B. "rock"), nicht das Mauerobjekt selbst.
- Offene Punkte: keine Raycasts, keine partielle Deckung, keine feingranulare Sichtkanal- oder FOW-Regel pro Spieler.
- Risiken: der LOS-Pfad bleibt bewusst grob tile-basiert; spaetere komplexere Hindernisse oder echte FoW-Systeme muessen diesen einfachen Sichtpfad explizit erweitern statt ihn nebenbei auszutauschen.
- Naechster Schritt: Terrain-Cover mit der bestehenden Command-/Phase-Coverlogik kombinieren.

### TASK_057 - Cover aus Terrain-Tiles
- Status: implementiert
- Stand: `SimulationRoot` addiert jetzt Terrain-Cover vom Tile der Ziel-Unit auf den bestehenden `cover_score` aus Command und Phase und klemmt den effektiven Cover-Wert auf maximal 80. `MissionTestSetup` versieht mehrere Tiles mit leichter oder mittlerer Deckung, und `TestUnit` zeigt den aktuellen effektiven Deckungswert direkt im Debug-Label als `COV:x` an.
- Offene Punkte: keine richtungsabhaengige Deckung, keine zerstoerbaren Cover-Objekte und keine Deckungssuche-KI.
- Risiken: Terrain-Cover bleibt bewusst symmetrisch und tile-zentriert; spaetere echte Deckungssysteme sollten diesen V1-Wert explizit differenzieren statt Command- und Terrain-Cover still zu vermischen.
- Naechster Schritt: Hoehenstufen auch fuer Bewegung und Trefferqualitaet auswerten.

### TASK_058 - Hoehenstufen
- Status: implementiert
- Stand: die Testkarte besitzt jetzt mehrere Tiles mit `height_level` 1 und 2; `MissionTestSetup` moduliert diese Tiles leicht heller, damit Hoehenzonen sichtbar bleiben. `TerrainPathfinder` blockiert Bewegungen ueber Cliffs mit Hoehenunterschied > 1, `LineOfSightSystem` nutzt Hoehen fuer Blockadeentscheidungen, und `SimulationRoot` gibt Angreifern auf hoeherem Terrain einen Accuracy-Bonus bzw. bei Hoehennachteil eine kleine Penalty. `TestUnit` zeigt die aktuelle Hoehenstufe als `H:x` direkt im Debug-Label.
- Offene Punkte: keine Rampen-/Treppenlogik, keine echte Iso-Stack-Darstellung und keine weiteren Hoehenfolgen wie Fallschaden.
- Risiken: die Hoehenzonen bleiben bewusst eine leichte 2D-Modulation ueber dem bestehenden Kartensprite; spaetere Karten sollten diese Datenbasis behalten, statt Hoehen still in separate Spezialpfade aufzuteilen.
- Naechster Schritt: verschiedene Oberflaechentypen auf Bewegung und Pfadkosten anwenden.

### TASK_059 - Strassen und Oberflaechen
- Status: implementiert
- Stand: `TerrainTileData` kennt jetzt die Oberflaechentypen `ground`, `road`, `sand` und `rock` samt Speed- und Pfadkostenfaktoren. `SimulationRoot` multipliziert das Bewegungstempo mit dem aktuellen Surface-Speed-Faktor des Tiles unter der Unit, `TerrainPathfinder` bevorzugt dadurch Strassen und meidet Sand oder Fels, und `MissionTestSetup` markiert mehrere Strassen-, Sand- und Felszonen mit passender Farbmodulation direkt auf der Testkarte. `TestUnit` zeigt den aktuellen Surface-Code samt Speed-Faktor, z.B. `RD:1.4`, im Debug-Label.
- Offene Punkte: keine Audio-/Sichtbarkeitsfolgen, keine fahrzeugspezifischen Terrain-Regeln und keine dynamischen Oberflaechenveraenderungen.
- Risiken: die Oberflaechenwirkung bleibt bewusst ein einfacher Bewegungs- und Kostenmodifikator; spaetere Systeme fuer Wetter, Fahrzeuge oder Spezialeinheiten sollten diese Daten explizit erweitern statt neue, parallele Terrain-Kategorien einzufuehren.
- Naechster Schritt: den Terrain-Slice lokal stabil halten und erst danach den spaeteren Multiplayer-Block gemaess Roadmap angehen.


### TASK_065 - Tile-Typ-Katalog und Palette
- Status: implementiert
- Stand: `TerrainTileCatalog` unter `res://scripts/terrain/terrain_tile_catalog.gd` laedt Tile-Typ-Definitionen aus `res://data/terrain_tile_catalog.json`. Jeder Typ definiert einmalig `type_id`, `display_name`, `surface_type`, `walkable`, `blocks_los`, `cover_value` und `height_level`. Der Map-Editor zeigt links eine Palette (`ItemList`) mit allen verfuegbaren Tile-Typen. Bei Auswahl eines Typs wird automatisch der Brush-Modus aktiviert; Klick auf ein Tile uebertraegt alle Eigenschaften des Typs. Das Property-Panel zeigt bei selektiertem Tile den erkannten Typ-Namen oder `(custom)` an.
- Offene Punkte: keine Typ-Referenz in der Map-JSON (Tiles speichern weiterhin alle Eigenschaften inline), keine benutzerdefinierten Typen zur Laufzeit, kein Tile-Preview in der Palette.
- Risiken: der Katalog ist bewusst ein reiner Editor-Workflow; Runtime-Code hat keinen Katalog-Bezug und bleibt von Inline-Daten abhaengig.
- Naechster Schritt: bei Bedarf Map-JSON auf Typ-Referenzen umstellen und Katalog in Runtime-Loading einbinden.

### TASK_066 - Corridor-Wall Typen, Typ-Texturen und Auto-Cliff
- Status: implementiert
- Stand: Der Tile-Katalog (`terrain_tile_catalog.json`) enthaelt jetzt 14 Tile-Typen mit optionalem `texture_path` (ground, road haben eigene Texturen). Tile-Sprites zeigen die Typ-Textur wenn vorhanden, sonst Fallback mit Modulate-Farbe. Cliff-Overlays (`terrain_sideCliff_SE/SW/NE/NW.png`) werden automatisch an Kanten mit Hoehendifferenz gezeichnet; Cliff-Corner-Pieces an Ecken wo zwei Cliff-Kanten aufeinandertreffen. Wall-Overlays (`corridor_wall_SE/SW/NE/NW.png`) analog fuer Tiles mit `blocks_los=true` an Kanten zu Nicht-Wall-Nachbarn.
- Offene Punkte: Wall- und Cliff-Sprites sind Kenney-Assets die als vertikale Panels designed sind, nicht als ISO-Bodenplatten - die visuelle Passung ist naeherungsweise.
- Risiken: die Overlay-Logik ist eng an 4-Nachbar-Adjazenz gebunden; diagonale oder mehrlagige Overlays braeuchten eine erweiterte Kantenlogik.

### TASK_067 - Fix Map-Editor 64x64 Flat Ground
- Status: implementiert
- Stand: Map-Editor erzeugt jetzt standardmaessig 64x64 Grids mit Zoom 0.3 statt 8x8. `create_empty()` setzt `type_id="ground_flat"` als Default fuer neue Tiles, damit die Palette-Erkennung korrekt funktioniert.
- Offene Punkte: keine.

### TASK_068 - Zoom-Inversion und Auto-Wall-Overlays
- Status: implementiert
- Stand: Zoom-Richtung korrigiert (WHEEL_UP = hineinzoomen, WHEEL_DOWN = herauszoomen). Wall-Overlays werden jetzt korrekt bei `_rebuild_tile_sprites()` und `_refresh_tile_visual()` aktualisiert.
- Offene Punkte: keine.

### TASK_068b - Drag-Painting und Hover-Preview
- Status: implementiert
- Stand: Linksklick-Halten und Ziehen malt durchgehend Tiles im Brush-Modus (`_is_painting` Flag, Motion-Handler). Halbtransparentes Hover-Preview-Sprite zeigt den ausgewaehlten Tile-Typ an der Mausposition, solange Brush aktiv ist.
- Offene Punkte: keine.

### TASK_068c - Gitternetz-Overlay und Himmelsrichtungen
- Status: implementiert
- Stand: `GridOverlay` Node2D zeichnet feine weisse Diamant-Umrisse (12% Opacity, 1px) ueber jedem Tile (z_index 10). Kompass-Labels N/O/S/W an den vier Ecken der ISO-Diamant-Karte, 80px, halbtransparent. Richtungsmapping: Grid +x=SE, +y=SW (aus Cliff-Overlay-Logik abgeleitet).
- Offene Punkte: keine.

### Fix - Cliff/Wall Overlay Separation und Corner-Replacement
- Status: implementiert
- Stand: Wall-Tiles (blocks_los) bekommen nur noch Wall-Overlays, keine Cliff-Overlays. Cliff-Kanten werden nicht zu Wall-Nachbarn gezeichnet. Corner-Pieces ersetzen die beiden geraden Panels (Wall und Cliff) statt sich darüberzustapeln. Drag-Painting funktioniert jetzt ohne vorherige Tile-Selektion (Guard von `_has_selected_tile()` auf `_has_selected_type()` geaendert).
- Offene Punkte: Wall-/Cliff-Corner-Zuordnung (welches Corner-Piece an welcher Ecke) muss visuell geprueft und ggf. korrigiert werden.
- Naechster Schritt: Wall-Richtungsmapping anhand der tatsaechlichen Sprite-Orientierung verifizieren und ggf. korrigieren.

### Edge-Type System (Cliff vs Slope)
- Status: implementiert
- Stand: Jedes Tile hat ein `edge_type` Feld ("cliff" oder "slope", Default: cliff). Im Map-Editor wahlbar ueber "Kante:" Dropdown. Cliffs blockieren Bewegung bei height_diff > 1 und rendern `terrain_sideCliff_*.png`. Slopes sind immer begehbar (kosten aber 1.0 pro Level statt 0.5) und rendern `terrain_side_*.png`. Das hoehere Tile bestimmt den edge_type fuer die Kante.
- Offene Punkte: Inner-Corner-Pieces (`terrain_sideCornerInner_*.png`) noch nicht implementiert, Side-End-Pieces (`terrain_sideEnd_*.png`) noch nicht implementiert.
- Naechster Schritt: Inner Corners fuer komplexe Huegelformationen implementieren.

### Brush-Size System
- Status: implementiert
- Stand: Im TopBar neben dem Brush-Button ein BrushSize-Dropdown mit 1x1, 3x3 und 5x5. Gilt fuer beide Modi: Brush-Paint (Typ auf Karte malen) und Property-Panel-Aenderungen (Height, Edge-Type, Surface etc. auf selektiertes Tile + Radius anwenden). Radius 0/1/2 entspricht der jeweiligen Brush-Groesse.
- Offene Punkte: Kein visuelles Brush-Preview auf der Karte (nur Hover-Preview fuer 1x1). Undo speichert nur das Center-Tile.
- Naechster Schritt: Optional visuelles Brush-Preview, Multi-Tile-Undo.