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

### TASK_106 – Dropship-LZ, Insertion und verzoegerte Aktivierung
- Status: implementiert
- Stand: `MissionTestSetup` kann Friendly-Units jetzt standardmaessig bis zur Insertion aus `UnitRegistry`/`FTLRegistry` fernhalten (`defer_friendly_runtime_activation = true`) und blendet sie bis zum Einflug aus. `MissionTacticalSandboxController` registriert Units erst beim Deboarding autoritativ in `UnitRegistry`, bindet sie an `RuntimeLeader`/`FTLRegistry` und startet fuer das frisch eingeflogene Fireteam den aktiven Phase-Plan erst ab diesem Aktivierungszeitpunkt. Direkte Commands, Ad-hoc-Orders, Default-Behavior und Cover-Hold-Ausgaben sind vor Insertion fuer nicht aktive Fireteams gesperrt. `MissionCombatLoopDriver` verarbeitet nur Units, die in `UnitRegistry` aktiv sind, damit nicht eingeflogene Teams nicht vorzeitig am Gefecht teilnehmen.
- Offene Punkte: keine eigene Insertion-Warteschlange fuer mehrere zeitversetzte Transporter und keine erweiterte Missionsanzeige mit explizitem Aktivierungs-Timer pro Fireteam.
- Risiken: der Aktivierungspfad ist bewusst auf den bestehenden Dropship-Sequencer im Tactical-Sandbox-Controller begrenzt; spaetere echte Multi-Transport- oder Netzwerk-Synchronisierung sollte diesen Pfad explizit erweitern.
- Naechster Schritt: TASK_107 (LoadoutModifierResolver + initiale Missions-Effects) auf den jetzt zeitlich korrekten Insertion-Aktivierungszeitpunkt aufsetzen.

### TASK_107 – LoadoutModifierResolver und initiale Missions-Effects
- Status: implementiert
- Stand: Neuer `LoadoutModifierResolver` uebersetzt FOB-`member_loadouts` (`weapon_1`, `weapon_2`, `armor`) in `UnitLoadoutModifiers` pro Unit inklusive Alias-Normalisierung (`rail_gun`/`sonderwaffe` -> `special`) und fester Formeln fuer Waffen und Armor. `MissionTestSetup` baut die Modifikator-Dictionaries beim Missionsaufbau und enqueued fuer bereits aktive Friendlies initiale `apply_loadout_modifiers`-Effects. Fuer verzoegert eingeflogene Friendlies enqueued der `MissionTacticalSandboxController` denselben Effekt beim Runtime-Insert. `SimulationRoot` verarbeitet den neuen autoritativen Effect-Typ und delegiert an `TestUnit.apply_loadout_modifiers(...)`; `TestUnit` integriert die Modifikatoren in Hit-/Speed-/Damage-Taken-Effekte sowie in den effektiven Cover-Score.
- Offene Punkte: keine tiefe Distanzklassenlogik im Combat-Loop (range_class ist vorerst Datenvertrag) und keine gestaffelte Waffen-Slot-Gewichtung ueber den eingefuehrten Secondary-Weight hinaus.
- Risiken: die additive Formel ist bewusst klein und datengetrieben; spaetere Balancing-Runden sollten die Faktoren explizit feinjustieren statt implizit in Einzelpfade einzugreifen.
- Naechster Schritt: Folge-Tasks koennen `range_class` und weitere Loadout-Effekte gezielt im Combat-Resolver auswerten.

### TASK_108 – PatrolEditorTool und Pre-Contact-Patrol
- Status: implementiert
- Stand: `TerrainMapData` traegt jetzt einen Patrol-Datenvertrag (`patrol_paths`) als Dictionary `spawn_id -> waypoint[]` mit JSON-Load/Save. Der interne `MapEditor` hat ein kleines `Patrol`-Tool mit Spawn-Auswahl, sichtbarer Reihenfolge/Overlay, Hinzufuegen per Klick, Verschieben per Drag und Entfernen via `Ctrl+Klick`; Speicherung laeuft ueber die bestehende Map-JSON-Pipeline. `MissionTestSetup` uebergibt Patrol-Pfade aus der geladenen Karten-JSON an den `EnemyWaveController`. `MissionCombatLoopDriver` nutzt diese Pfade fuer pre-contact Bewegung: Enemies folgen Waypoints, bis `enemy_should_hold_position` erstmals Kontaktlage meldet, danach greifen wieder die bestehenden reaktiven Combat-Pfade.
- Offene Punkte: kein separates Patrol-Tempo pro Segment und keine erweiterten Patrol-Modi (pause/look-at), nur zyklischer Waypoint-Follow.
- Risiken: Patrol-Follow bleibt bewusst klein und nutzt den bestehenden `move_to_position`-Commandpfad; spaetere KI-Ausbauten sollten diesen Hook gezielt ersetzen statt parallel eine zweite Bewegungslogik zu bauen.
- Naechster Schritt: bei Bedarf spaetere Awareness-/Stealth-Tasks auf den vorhandenen pre-contact Patrol-Zustand aufsetzen.

### TASK_102 – Ad-hoc-Orders und Return-to-Plan
- Status: implementiert
- Stand: Ein neuer `AdHocOrderController` verwaltet laufende Sofortbefehle pro Fireteam (`flank`, `disengage`, `fall_back`, `focus_fire`, `hold_till_last_man`) ausserhalb der geplanten `FireteamOrderPlan`-Wegpunkte. Der `TacticalInputController` kann diese Befehle nur bei aktivem Kontakt ausloesen, unterbricht dabei laufende Plan-Ausfuehrung, visualisiert Ad-hoc-Orders als getrennten Overlay-Pfad und fuehrt nach Abschluss oder manuellem `Return to Plan` wieder zum naechsten pending-Wegpunkt zurueck.
- Offene Punkte: kein separates Suppression-System, keine dedizierte Beschuss-Heuristik ausser Kontaktstatus und keine komplexe Priorisierungslogik zwischen mehreren gleichzeitig konkurrierenden Sofortbefehlen.
- Risiken: die Gefechtsfreigabe basiert aktuell bewusst auf dem bestehenden Kontaktzustand pro Unit; spaetere feinere Trigger (z. B. suppressive fire ohne direkten Kontakt) muessen explizit in eigenen Tasks folgen.
- Naechster Schritt: TASK_103 fuer inter-fireteam Koordination ueber EventRouter und erweiterten Return-to-Plan-Glue umsetzen.

### TASK_103 – Suppression, Interruption und Return-to-Plan
- Status: implementiert
- Stand: `TacticalInputController` fuehrt jetzt einen laufenden Suppression-Container pro Fireteam mit Treffer-/Nahmiss-Zuwachs und trait-/leadership-abhaengigem Decay. Bei aktiver Suppression werden Fireteams in den Status `interrupted` ueberfuehrt, erhalten temporaere Malus-Werte (`move_speed_factor`, `attack_bonus`, `semi_disciplined` Fire-Discipline) und priorisieren Cover-Halten gegenueber Wegpunkt-Fortschritt; `hold_till_last_man` bleibt von Suppression ausgenommen. Nach Stabilisierung erfolgt automatisch ein Ruecksprung auf den naechsten `pending`-Wegpunkt, und ein manueller Return-to-Plan ist ueber ein neues `FireteamStatusPanel` verfuegbar.
- Offene Punkte: keine tiefe Morale-/Panik-Kaskade, keine separate Ballistik-/Munitionslogik und keine ausgebauten Mehrstufen-Reaktionen jenseits des aktuellen Suppression-Slices.
- Risiken: Suppression basiert aktuell auf Kontakt plus Health-Deltas im Testszenen-Controller; spaetere echte Gefechtsinstrumentierung sollte diese Trigger explizit in Runtime-/Combat-Systeme ueberfuehren, statt sie still im UI-nahen Glue wachsen zu lassen.
- Naechster Schritt: falls noetig, inter-fireteam Koordination ueber dedizierte EventRouter-Consumer weiter ausbauen (z. B. flankierende Entlastungsreaktionen).

### TASK_104 – Inter-Fireteam-Koordination und Leader-initiiertes Flankieren
- Status: implementiert
- Stand: Ein neuer `FireteamCoordinationManager` erkennt enge Zielraeume auf Plan-/Fireteam-Ebene und erzeugt Bounding-Zuweisungen, bei denen das Fireteam mit hoeherem `leadership` zuerst vorrueckt und das andere in Cover/Hold bleibt. `TacticalInputController` integriert diese Koordination in den aktiven Phasenlauf, rotiert Rollen nach `fireteam_ready_to_advance` und behandelt Ad-hoc-Unterbrechungen als temporaere Pause mit Rueckkehr in den Koordinationsfluss. Zusaetzlich kann ein aggressiver/reckless Leader mit `leadership > 0.7` bei aktivem Kontakt und verfuegbarem Terrainfenster autonom einen Ad-hoc-`flank` ausloesen. Alle Koordinations-/Flank-Ereignisse werden ueber erweiterte `EventRouter`-Signale kommuniziert.
- Offene Punkte: keine globale Multi-Fireteam-KI, keine persistente Koordinationshistorie und keine tiefere Gruppen-Taktik ueber den Bounding-Slice hinaus.
- Risiken: Die aktuelle Koordination bleibt bewusst leichtgewichtig und testszenenlokal; spaetere komplexere Team-Taktik sollte den Signalvertrag explizit weiterfuehren statt den Controller still zu ueberladen.
- Naechster Schritt: Falls notwendig, in Folge-Tasks dedizierte EventRouter-Consumer fuer Entlastungs-/Unterstuetzungsreaktionen zwischen Fireteams ausbauen.

### TASK_105 – Leader-Nachfolge, Lead-Rueckgabe und UI-Synchronisierung
- Status: implementiert
- Stand: `MissionCombatLoopDriver` verwaltet jetzt pro Fireteam Original-Lead, Acting-Lead und Mitgliederliste. Faellt der urspruengliche Lead aus, uebernimmt automatisch das fitte Mitglied mit dem hoechsten `leadership`, bei Gleichstand entscheidet `toughness`. Sobald der Original-Lead durch Respawn oder spaetere Insertion wieder `fit` ist, geht die Fuehrung in derselben Mission automatisch an ihn zurueck. `TacticalInputController` bindet Lead-Anzeigen und Verhaltensableitungen an den jeweils aktuellen Acting-Lead; dadurch wechseln Lead-Stern, Ad-hoc-/Koordinationsentscheidungen und Fireteam-Karten synchron mit.
- Offene Punkte: keine dauerhafte Meta-Persistenz der Missions-Nachfolge ausserhalb der laufenden Mission und keine separate manuelle Lead-Uebersteuerung.
- Risiken: die Lead-Synchronisierung bleibt bewusst missionslokal und haengt an den bestehenden Friendly-/Respawn-Pfaden; spaetere Netzwerk- oder Meta-Synchronisierung sollte diesen Vertrag explizit uebernehmen statt parallele Lead-Wahrheiten aufzubauen.
- Naechster Schritt: TASK_106 auf dem jetzt stabilen Lead-/Respawn-Pfad fuer verzoegerte Runtime-Aktivierung und LZ-Insertion aufsetzen.

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


### TASK_060 - Terrain-Daten als JSON-Datei
- Status: implementiert
- Stand: `TerrainMapData` unter `res://scripts/terrain/terrain_map_data.gd` laedt und speichert Terrainkarten unter `res://maps/` als JSON-Root mit `map_name`, `grid_size`, `tile_size`, `grid_origin` und serialisierten Tile-Eintraegen. Beim Laden werden die JSON-Daten in `TerrainTileData`-Instanzen ueberfuehrt; mit `create_empty(...)` existiert zusaetzlich ein kontrollierter Default-Pfad fuer neue Karten.
- Offene Punkte: keine separate Schema-Versionierung oder Migrationslogik fuer aeltere Kartenformate.
- Risiken: `TerrainMapData` ist inzwischen gemeinsamer Datenvertrag fuer Editor, Mission und Meta-Map; spaetere JSON-Erweiterungen duerfen deshalb keine stillen Breaking Changes fuer bestehende Karten einfuehren.
- Naechster Schritt: den JSON-Vertrag kontrolliert im Editor und in `MissionTestSetup` konsumieren.

### TASK_061 - Map-Editor-Szene: Tile-Auswahl und Anzeige
- Status: implementiert
- Stand: `res://scenes/editor/map_editor.tscn` plus `res://scripts/editor/map_editor.gd` bilden eine eigenstaendige Editor-Szene mit Kartenaufbau aus `TerrainMapData`, `Camera2D`-basierter Pan-/Zoom-Steuerung, Tile-Auswahl per Klick, visueller Outline sowie seitlichem Property- und Palette-Panel.
- Offene Punkte: keine separate read-only-Ansicht; spaetere Workflow- und Palette-Erweiterungen laufen in den Folgetasks.
- Risiken: die Szene bleibt bewusst editorlokal; Auswahl- und Anzeigezustand duerfen nicht in Runtime- oder Missionspfade auslaufen.
- Naechster Schritt: editierbare Tile-Properties auf denselben lokalen Map-Zustand legen.

### TASK_062 - Map-Editor: Tile-Properties bearbeiten
- Status: implementiert
- Stand: Das Property-Panel kann die Terrain-Eigenschaften des selektierten Tiles lokal auf `TerrainMapData` anwenden und die Visualisierung sofort aktualisieren; dazu gehoeren `walkable`, `blocks_los`, `cover_value`, `height_level`, `surface_type` und spaeter erweitert auch `edge_type`. Ein kleiner Undo-Pfad fuer den zuletzt gesicherten Tile-Zustand ist vorhanden.
- Offene Punkte: kein ausgebauter Mehrschritt-Undo-Stack und keine grossen Massenoperationen jenseits spaeterer Brush-/Selection-Erweiterungen.
- Risiken: Property-Patches bleiben bewusst editorlokal; spaetere Runtime-Regeln muessen weiterhin aus den serialisierten Tile-Daten statt aus UI-Zustand abgeleitet werden.
- Naechster Schritt: Speichern/Laden und New-Workflow auf denselben lokalen Zustand aufsetzen.

### TASK_063 - Map-Editor: Speichern und Laden
- Status: implementiert
- Stand: Der Editor kann Karten ueber `TerrainMapData.save_to_file()` speichern, ueber FileDialogs laden, neue Karten erzeugen und einen Dirty-Status im Titel fuehren; `Save`, `Load` und `New` sind an die bestehende Editor-UI angebunden, inklusive Warn-Dialog bei ungesicherten Aenderungen. Spaetere Workflow-Politur hat diesen Pfad um `Save As` und frei waehlbare Kartengroessen erweitert.
- Offene Punkte: keine Versionsverwaltung oder komplexe Dateibrowser-Logik ueber den lokalen Ressourcenpfad hinaus.
- Risiken: der Dateipfad bleibt bewusst editorgetrieben; spaetere Tooling- oder Import-Pipelines sollten denselben `TerrainMapData`-Vertrag nutzen statt parallele Speicherrouten einzufuehren.
- Naechster Schritt: `MissionTestSetup` kontrolliert auf denselben JSON-Load-Pfad umstellen.

### TASK_064 - MissionTestSetup: Terrain aus JSON laden
- Status: implementiert
- Stand: `MissionTestSetup` nutzt `map_file_path`, laedt Terrain ueber `TerrainMapData.load_from_file(...)`, konfiguriert die `TerrainRegistry` aus JSON-Metadaten und registriert alle Tiles aus der Karte. Wenn keine gueltige Datei vorliegt, bleibt der Hardcode-Pfad als Fallback aktiv; sichtbares Kartenrendering und Marker-Spiegelung greifen auf denselben geladenen Map-Zustand zu.
- Offene Punkte: der Hardcode-Fallback bleibt nur fuer Alt- oder Fehlerszenarien erhalten und sollte nicht wieder zum primaeren Kartenpfad werden.
- Risiken: solange Fallback und JSON-Pfad parallel existieren, muessen Terrain-Aenderungen bewusst im JSON-Vertrag landen, damit Editor und Mission nicht erneut auseinanderdriften.
- Naechster Schritt: darauf die Editor-Workflow-Slices und den spaeteren gemeinsamen Terrain-Renderer aufbauen.

### TASK_065 - Tile-Typ-Katalog und Palette
- Status: implementiert
- Stand: `TerrainTileCatalog` unter `res://scripts/terrain/terrain_tile_catalog.gd` laedt Tile-Typ-Definitionen aus `res://data/terrain_tile_catalog.json`. Jeder Typ definiert einmalig `type_id`, `display_name`, `surface_type`, `walkable`, `blocks_los`, `cover_value` und `height_level`. Der Map-Editor zeigt links wieder eine einfache einzelne Liste mit allen verfuegbaren Tile-Typen. Bei Auswahl eines Typs wird automatisch der Brush-Modus aktiviert; Klick auf ein Tile uebertraegt alle Eigenschaften des Typs. Das Property-Panel zeigt bei selektiertem Tile den erkannten Typ-Namen oder `(custom)` an.
- Offene Punkte: keine Typ-Referenz in der Map-JSON (Tiles speichern weiterhin alle Eigenschaften inline), keine benutzerdefinierten Typen zur Laufzeit und kein Tile-Preview in der Palette.
- Risiken: der Katalog ist bewusst ein reiner Editor-Workflow; Runtime-Code hat keinen Katalog-Bezug und bleibt von Inline-Daten abhaengig.
- Naechster Schritt: bei Bedarf Map-JSON auf Typ-Referenzen umstellen und Katalog in Runtime-Loading einbinden.

### TASK_066 - Corridor-Wall Typen, Typ-Texturen und Auto-Cliff
- Status: implementiert
- Stand: Der Tile-Katalog (`terrain_tile_catalog.json`) enthaelt jetzt 14 Tile-Typen mit optionalem `texture_path` (ground, road haben eigene Texturen). Tile-Sprites zeigen die Typ-Textur wenn vorhanden, sonst Fallback mit Modulate-Farbe. Cliff-Overlays (`terrain_sideCliff_SE/SW/NE/NW.png`) werden automatisch an Kanten mit Hoehendifferenz gezeichnet; Cliff-Corner-Pieces an Ecken wo zwei Cliff-Kanten aufeinandertreffen. Wall-Overlays (`corridor_wall_SE/SW/NE/NW.png`) analog fuer Tiles mit `blocks_los=true` an Kanten zu Nicht-Wall-Nachbarn.
- Offene Punkte: Wall- und Cliff-Sprites sind Kenney-Assets die als vertikale Panels designed sind, nicht als ISO-Bodenplatten - die visuelle Passung ist naeherungsweise.
- Risiken: die Overlay-Logik ist eng an 4-Nachbar-Adjazenz gebunden; diagonale oder mehrlagige Overlays braeuchten eine erweiterte Kantenlogik.

### TASK_067 - Fix Map-Editor 64x64 Flat Ground
- Status: implementiert
- Stand: Der Map-Editor ist nicht mehr auf 8x8 begrenzt. Fehlende Karten fallen beim Laden weiterhin auf ein 64x64-Grid mit Zoom 0.3 zurueck. Neue Karten werden dagegen ueber einen Dialog mit frei waehlbarer Breite/Hoehe angelegt; der Dialog startet standardmaessig mit 32x32. `create_empty()` setzt `type_id="ground_flat"` als Default fuer neue Tiles, damit die Palette-Erkennung korrekt funktioniert.
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
- Stand: Die frueheren per-Tile-Gitterlinien wurden zugunsten einer leichten Checkerboard-Modulation direkt auf den Bodentiles ersetzt. `GridOverlay` dient jetzt nur noch fuer die Kompass-Labels `N/O/S/W` an den vier Kartenextremen; damit bleibt die Iso-Ausrichtung lesbar, ohne viele zusaetzliche Linien- oder `Line2D`-Nodes zu erzeugen. Richtungsmapping: Grid +x=SE, +y=SW (aus der Cliff-Overlay-Logik abgeleitet).
- Offene Punkte: kein separat zuschaltbares Debug-Gitter, keine groessere Grid-HUD-Konfiguration.
- Risiken: die Gitterlesbarkeit haengt jetzt an Tile-Modulation und Kontrast der Bodentexturen; spaetere Theme- oder Texture-Wechsel muessen das explizit mitpruefen.
- Naechster Schritt: nur bei Bedarf ein optional zuschaltbares Debug-Gitter ergaenzen.

### Fix - Cliff/Wall Overlay Separation und Corner-Replacement
- Status: implementiert
- Stand: Wall-Tiles (blocks_los) bekommen nur noch Wall-Overlays, keine Cliff-Overlays. Cliff-Kanten werden nicht zu Wall-Nachbarn gezeichnet. Corner-Pieces ersetzen die beiden geraden Panels (Wall und Cliff) statt sich darüberzustapeln. Drag-Painting funktioniert jetzt ohne vorherige Tile-Selektion (Guard von `_has_selected_tile()` auf `_has_selected_type()` geaendert).
- Offene Punkte: Wall-/Cliff-Corner-Zuordnung (welches Corner-Piece an welcher Ecke) muss visuell geprueft und ggf. korrigiert werden.
- Naechster Schritt: Wall-Richtungsmapping anhand der tatsaechlichen Sprite-Orientierung verifizieren und ggf. korrigieren.

### Edge-Type System (Cliff vs Slope)
- Status: implementiert
- Stand: Jedes Tile hat ein `edge_type` Feld (`cliff`, `slope`, `none`, Default: `cliff`). Im Map-Editor ist das ueber das `Kante:`-Dropdown als `Cliff`, `Hang` oder `Keine` waehlbar. Cliffs blockieren Bewegung bei `height_diff > 1` und rendern `terrain_sideCliff_*.png`. Slopes bleiben begehbar, kosten mehr und nutzen die grossen `terrain_rampLarge_*.png`-Sprites. `none` unterdrueckt die Kanten-Visualisierung komplett. Die Palette enthaelt zusaetzlich gerichtete Cliff- und Rampen-Typen fuer `SE`/`SW`/`NE`/`NW`.
- Offene Punkte: Inner-Corner-Pieces (`terrain_sideCornerInner_*.png`) noch nicht implementiert, Side-End-Pieces (`terrain_sideEnd_*.png`) noch nicht implementiert.
- Naechster Schritt: Inner Corners fuer komplexe Huegelformationen implementieren.

### Brush-Size System
- Status: implementiert
- Stand: Im TopBar neben dem Brush-Button ein BrushSize-Dropdown mit 1x1, 3x3 und 5x5. Gilt fuer beide Modi: Brush-Paint (Typ auf Karte malen) und Property-Panel-Aenderungen (Height, Edge-Type, Surface etc. auf selektiertes Tile + Radius anwenden). Radius 0/1/2 entspricht der jeweiligen Brush-Groesse.
- Offene Punkte: Kein visuelles Brush-Preview auf der Karte (nur Hover-Preview fuer 1x1). Undo speichert nur das Center-Tile.
- Naechster Schritt: Optional visuelles Brush-Preview, Multi-Tile-Undo.

### Fix - Map-Roundtrip, Property-Patching und Undo
- Status: implementiert
- Stand: Map-JSON-Roundtrips behalten jetzt auch `edge_type` und `object_height`, damit Speichern/Laden keine Tile-Daten mehr verliert. Echte Property-Aenderungen loesen die starre Typbindung eines Tiles (`type_id = ""`), damit geaenderte Felder korrekt als Custom-Zustand behandelt werden. Undo stellt die zuletzt gesicherte Tile-Version wieder vollstaendig her, inklusive `object_height`.
- Offene Punkte: Undo bleibt weiterhin auf das gespeicherte Center-Tile begrenzt; kein kompletter Mehrfeld- oder Mehrtile-Verlauf.
- Risiken: der Patch bleibt bewusst editorlokal; spaetere Format-Erweiterungen muessen beim Roundtrip explizit mitgezogen werden.
- Naechster Schritt: nur bei Bedarf ein explizites Multi-Tile-Undo und feinere Undo-Historie als eigene Aufgabe schneiden.

### Fix - Wall/Cliff/Ramp Sprite-Zuordnung und Offsets
- Status: implementiert
- Stand: Overlay- und Objekt-Sprites werden jetzt konsistent ueber `KENNEY_DIAMOND_CENTER` positioniert; mehrere Wall-/Corner-Richtungen und Offsets wurden visuell nachkorrigiert. Der Wall-Pfad ist tile-zentriert stabilisiert, Cliff-/Corner-Offsets wurden nachgezogen, und Rampen nutzen fuer ihre vier Richtungen jetzt die grossen `terrain_rampLarge_*`-Sprites statt der generischen Side-Sprites.
- Offene Punkte: Feintuning einzelner Offsets kann bei neuen Tile-Kombinationen weiter noetig sein.
- Risiken: die Zuordnung bleibt an die Kenney-Sprite-Semantik und die aktuelle Iso-Richtungsdefinition gebunden; spaetere Asset-Wechsel muessen diese Mapping-Schicht explizit neu pruefen.
- Naechster Schritt: nur bei Bedarf weitere Corner-/Offset-Korrekturen auf Basis konkreter visueller Problemfaelle ergaenzen.

### TASK_069 – Map-Editor: Auswahl, Save As und Workflow-Polish
- Status: implementiert
- Stand: Der Editor merkt sich die zuletzt gewaehlten Surface- und Kanten-Typen auch ohne aktive Tile-Selektion. `Escape` hebt die aktuelle Palette-Auswahl auf. Ein neuer `Select`-Button neben `Brush` schaltet in einen Auswahlmodus mit Ctrl+LMB-Multiselection und gemeinsamer Outline. `Ctrl+Save` oeffnet `Save As`, `New` oeffnet jetzt einen Groessen-Dialog fuer neue Karten (Default 32x32), und `maps/Test_mission_32x32.json` dient als neue 32x32-Vorlage. Die vier Wand-Ecktypen sind in der Palette jetzt eindeutig als `Mauer Ecke ...` benannt.
- Offene Punkte: keine Drag-Selection, keine Massenoperationen auf bestehende Mehrfachauswahl und kein Multi-Tile-Undo ueber den gesamten Brush-Radius.
- Risiken: die Erweiterungen bleiben bewusst editorlokal; Runtime- und Kartenformat bleiben kompatibel, solange neue UI-Komfortfunktionen keine versteckte Semantik in die gespeicherten Tile-Daten einfuehren.
- Naechster Schritt: nur bei Bedarf Bulk-Edit auf Mehrfachauswahl, Drag-Selection und erweitertes Undo in eigene Tasks schneiden.

### TASK_070 - NPC-Karten-Komponente
- Status: implementiert
- Stand: `MetaUnitProfile` und `MetaUnitProfileBuilder` unter `res://scripts/meta/` bilden jetzt einen kleinen expliziten read-only Datenpfad fuer Meta-UI aus vorhandenen Unit-Identitaetsdaten, inklusive effektiver Skill-Zusammenfassung und Trait-Tags nach derselben Modifikatorlogik wie in `TestUnit`. Eine neue `NPCMetaCard`-Komponente unter `res://scripts/meta/npc_meta_card.gd` plus `res://scenes/meta/components/npc_meta_card.tscn` stellt Name, Skill-Kurzform, Trait-Tags und optional eine Statuszeile dar und unterstuetzt die leichten visuellen Zustaende `neutral`, `selectable`, `selected` und `disabled`. `HomebaseTestScreen` nutzt fuer seine bestehende Textlistenanzeige jetzt bereits den neuen Profilpfad statt unsichtbarer `TestUnit`-Preview-Nodes.
- Offene Punkte: die Karte ist noch nicht in Heimatbasis oder FOB als eigentliche Listen-/Grid-Darstellung eingebaut; es gibt noch keinen Auswahlfokus und keine FOB-spezifische Statusabbildung.
- Risiken: der Profilpfad ist bewusst klein und read-only gehalten; spaetere Heimatbasis-/FOB-Integration sollte denselben Datenvertrag weiterverwenden statt wieder screen-spezifische Sonderpfade aufzubauen.
- Naechster Schritt: in TASK_071 die Heimatbasis von der Checkbox-Textliste auf echte NPC-Karten plus Auswahlfokus umstellen.

### TASK_071 - Heimatbasis: NPC-Karten und Auswahlfokus
- Status: implementiert
- Stand: `HomebaseTestScreen` rendert die verfuegbaren Units jetzt als echte `NPCMetaCard`-Instanzen statt als Checkbox-Textzeilen, verwaltet einen expliziten Fokuszustand und zeigt rechts einen kleinen Detailbereich mit fokussierter Karte, Team-/Fireteam-Metadaten und Transferhinweis. Die Homebase-Szene unter `res://scenes/meta/homebase_test_screen.tscn` wurde dafuer in eine zweispaltige Struktur mit scrollbarer Kartenliste, Fokuspanel und separater Teamzusammenfassung umgebaut. Die Auswahl bleibt weiter rein UI-lokal und liefert an den `MetaLayerFlow` unveraendert nur die selektierten `unit_id`s in stabiler Roster-Reihenfolge.
- Offene Punkte: noch keine feinere visuelle Politur fuer Hover/Keyboard-Fokus, keine Detailsektion fuer weitergehende Biografie-/Loadout-Daten und noch keine FOB-spezifische Kartenwiederverwendung.
- Risiken: der Fokus- und Auswahlzustand liegt weiterhin bewusst nur im Screen; spaetere Meta-Features duerfen daraus keine zweite Gameplay-Wahrheit oder einen versteckten globalen UI-State aufbauen.
- Naechster Schritt: in TASK_072 dieselbe Kartenbasis kontrolliert in die FOB-Ansicht uebernehmen und dort missions-/transferbezogene Statusinformationen ergaenzen.

### TASK_072 - FOB: Teamkarten und Einsatzstatus
- Status: implementiert
- Stand: `FOBTestScreen` nutzt jetzt dieselbe `NPCMetaCard`-Komponente und denselben `MetaUnitProfileBuilder`-Pfad wie die Heimatbasis, um das uebertragene Team als Kartenliste statt als rohe Textzeilen darzustellen. Der bestehende Missionsrueckfluss aus `mission_result.team_states` wird pro Unit in kompakte Kartenstatus wie `READY FOR MISSION`, `FIT`, `DOWN`, `BLEEDOUT`, `RESPAWNING` oder `UNKNOWN` uebersetzt; ergaenzend zeigt die FOB eine kleine Zusammenfassung mit Teamgroesse, letzter Mission und Zahl einsatzbereiter Units sowie einen Fokusbereich fuer die aktuell betrachtete Unit. `MetaLayerFlow` liefert dafuer explizit den verfuegbaren Roster-Kontext an die FOB, ohne den bestehenden Homebase->FOB->Mission->Debrief-Flow semantisch zu aendern.
- Offene Punkte: noch keine tiefergehende After-Action-Aufbereitung, keine Rollen-/Loadout-Ansicht und keine Politur fuer alternative Statusbadges jenseits der bestehenden Kartenstatuszeile.
- Risiken: die FOB bleibt bewusst ein read-only Staging-Screen; spaetere Komfortfunktionen duerfen daraus keine zweite Teamverwaltungslogik oder verdeckte Persistenzschicht machen.
- Naechster Schritt: nur bei eigenem Folgetask weitere FOB-spezifische Komfortelemente wie Rollenhinweise oder Transfer-CTA-Politur aufbauen, ohne die bestehende Kartenbasis zu forkieren.

### TASK_073 - Homebase: Charakterbogen und Drag-and-Drop-Teamstaging
- Status: implementiert
- Stand: `HomebaseTestScreen` und `res://scenes/meta/homebase_test_screen.tscn` bilden die Heimatbasis jetzt als klare Dreispalten-Ansicht ab: links ein read-only Charakterbogen mit Portrait, Callsign, Herkunft, Alter, Rolle, Spezialisierung, Skills, Traits, Loadout und Kurzbiografie; mittig ein Drag-and-Drop-Staging-Bereich fuer das aktuelle Transferteam; rechts ein scrollbarer Pool aus 12 kompakten Portrait-Karten. `NPCCompactCard` dient dabei als kleine Quell- und Staging-Karte mit Portrait, Name und zwei kompakten Datenpunkten; ein Klick fokussiert den Charakterbogen, Drag-and-Drop ueber `HomebaseTeamDropPanel` staged Operators bis zum bestehenden 3er-Limit, und Entfernen bleibt ueber einen klaren Remove-Pfad moeglich. Der bestehende Flow bleibt kompatibel: `MetaLayerFlow` uebergibt weiter nur selektierte `unit_id`s, `MissionTestSetup` mappt diese kontrolliert auf die drei vorhandenen Friendly-Slots, und FOB, Mission sowie Debrief arbeiten dadurch mit den tatsaechlich aus dem 12er-Roster gewaehlten NPC-IDs statt implizit mit festen Homebase-Defaults.
- Offene Punkte: noch keine Drag-Reihenfolge innerhalb des Staging-Bereichs, keine Sortierung oder Filterung im Roster und keine zusaetzliche visuelle Politur fuer Hover-/Keyboard-Navigation.
- Risiken: das Teamstaging bleibt bewusst rein UI-lokal; spaetere Komfortfunktionen duerfen daraus keine persistente Barracks- oder Teamverwaltungs-Wahrheit machen.
- Naechster Schritt: nur bei eigenem Folgetask weitere Roster-Komfortfunktionen wie Sortierung, Filter oder feinere Staging-Politur ergaenzen, ohne den bestehenden Meta-/Missionspfad aufzubrechen.

### TASK_074 - Homebase: Layout-Neuordnung und Missionsinfoleiste
- Status: implementiert
- Stand: `res://scenes/meta/homebase_test_screen.tscn` ordnet die Homebase jetzt gemaess Folgetask neu an: ein eigenes Missionsinfo-Fenster liegt ueber die volle Breite oberhalb der drei Hauptfenster, links der scrollbare Portrait-Karten-Pool, mittig das Transferfenster und rechts der lesende Charakterbogen. Im Transferfenster sitzt der bestaetigende CTA jetzt oben als `Send to FOB`, waehrend der darunterliegende Drag-and-Drop-Bereich unveraendert die selektierten `unit_id`s fuer den bestehenden Flow bildet. `HomebaseTestScreen` aktualisiert zusaetzlich kompakte Missionsinfo-Texte rein aus dem vorhandenen UI-/Roster-Kontext, und der Charakterbogen nutzt jetzt einen eigenen ScrollContainer, damit die drei Hauptfenster im sichtbaren Bereich bleiben und nicht horizontal aus dem Screen gedrueckt werden.
- Offene Punkte: die Fenster sind funktional neu angeordnet, aber noch nicht visuell verdichtet; kleinere Roster-Karten, Popup-Tooltips, reduzierte Erklaertexte und die inhaltliche Fokussierung des Charakterbogens folgen erst in TASK_075.
- Risiken: die Missionsinfoleiste ist bewusst rein read-only und screen-lokal; spaetere Briefing- oder Missionsdaten duerfen daraus keine zweite Missionswahrheit im UI machen.
- Naechster Schritt: in TASK_075 die Kartenverdichtung, Tooltip-Hilfe und den fokussierteren Charakterbogen kontrolliert nachziehen.

### TASK_075 - Homebase: Kartenverdichtung, Tooltip-Polish und Charakterbogen-Fokus
- Status: implementiert
- Stand: `NPCCompactCard` unterstuetzt jetzt ueber `compact_mode` zwei Dichten derselben Kartenlogik: links im Roster kompakter mit kleinerem Portrait, engeren Innenabstaenden und reduzierter Typografie; in einer Nachpolitur wurden diese kompakten Karten nochmals leicht angehoben und zugleich auch fuer das Transferfenster uebernommen, damit links und Mitte dieselbe Kartenoptik teilen. `HomebaseTestScreen` blendet die dauerhaft sichtbaren Hilfetexte in den Fensterkoerpern aus und ersetzt sie durch deutsche Popup-Tooltips an Missionsfenster, Roster, Transferfenster, Dropzone, Charakterbogen und `Send to FOB`; diese Tooltips wurden spaeter noch bewusst blockiger auf mehrere Zeilen umgestellt. Der Charakterbogen wurde zugleich fokussiert: Callsign, Herkunft und Alter werden dort nicht mehr gezeigt, Rolle und Spezialisierung bleiben sichtbar, und die Skills erscheinen ausgeschrieben untereinander als `Accuracy`, `Speed`, `Leadership` und `Toughness`. Zusaetzlich wurden Abstaende, Mindestgroessen und Schriftgroessen in der Homebase nochmals kontrolliert verdichtet, ohne den bestehenden Drag-and-Drop-Transferfluss oder die selektierten `unit_id`s semantisch zu aendern; der Drag-Preview-Pfad der kompakten Karten wurde dabei gegen den bisherigen Buchstabe-pro-Zeile-Wrap-Bug gehaertet.
- Offene Punkte: die gemeinsame graue Kenney-Fensteroptik fuer Meta-Screens fehlt noch; das folgt erst in TASK_076.
- Risiken: die neuen Tooltips sind bewusst lokal direkt an der Homebase verdrahtet; spaetere globale Tooltip- oder Lokalisierungssysteme sollten diesen Pfad explizit uebernehmen statt verdeckt zu ersetzen.
- Naechster Schritt: in TASK_076 die vorhandenen grauen Kenney-UI-Assets als gemeinsame Meta-Fensteroptik fuer Homebase und spaeter FOB aufbauen.

### TASK_076 - Meta-Layer: Graue Kenney-UI-Rahmen
- Status: implementiert
- Stand: mit `res://scripts/meta/meta_ui_skin.gd` gibt es jetzt einen kleinen gemeinsamen Stilpfad fuer den Meta-Layer, der graue Kenney-Assets aus beiden vorhandenen UI-Packs direkt auf bestehende Screens auflegt, statt eine zweite Screen-spezifische Visual-Architektur einzufuehren. Homebase nutzt darueber nun sichtbare graue Kenney-Rahmen fuer Root-Container, Missionsinfo, Roster, Transfer, Dropzone und Charakterbogen; der CTA `Send to FOB` sowie die dynamisch erzeugten `Remove`-Buttons erhalten ebenfalls einen daran angeglichenen Button-Stil. In einer spaeteren Nachpolitur wurde der Mission-Brief-Rahmen von `button_square_header_large_rectangle` auf `button_square_header_blade_rectangle_screws` umgestellt, und der FOB-Transfer-CTA sitzt jetzt rechts im Mission Brief mit einer farblichen Neutral-/Bereit-/Pressed-Staffelung ueber Kenney-Header-Assets. FOB ist bereits auf dieselbe Stilbasis verdrahtet: Root-Screen, Fokusfenster sowie `Back to Homebase` und `Start Mission` verwenden denselben gemeinsamen Skin-Pfad, sodass TASK_077 direkt auf derselben neutral-grauen Meta-Optik aufbauen kann.
- Offene Punkte: Kartenkomponenten und feinere Meta-Panel-Strukturen sind noch nicht vollstaendig auf dieselbe Kenney-Chrome-Sprache gezogen; die aktuelle Stufe konzentriert sich bewusst auf die grossen Fensterrahmen und CTA-Flaechen.
- Risiken: der Stil wird derzeit bewusst lokal per Skript auf konkrete Screen-Pfade gelegt; wenn spaeter eine globale Theme-Ressource eingefuehrt wird, sollte sie diesen kleinen gemeinsamen Pfad sauber ersetzen statt parallel weiterzulaufen.
- Naechster Schritt: in TASK_077 die Fireteam-Vorbereitung in der FOB auf dieser nun gemeinsamen Meta-UI-Basis einfuehren, ohne die Homebase erneut mit Auswahlverantwortung zu belasten.

### TASK_077 - FOB: Fireteam-Auswahl und Startvorbereitung
- Status: implementiert
- Stand: die Homebase bleibt jetzt rein beim Teamtransfer und greift nicht mehr in die Fireteam-Startentscheidung ein; `MetaLayerFlow` initialisiert nach Homebase-Bestaetigung bewusst eine leere, explizit vorbereitbare Fireteam-Auswahl parallel zu den selektierten `unit_id`s. Die FOB hat dafuer in `res://scenes/meta/fob_test_screen.tscn` einen kleinen Fireteam-Prep-Schritt erhalten: fuer die aktuell fokussierte transferierte Person kann direkt in der FOB zwischen `UNASSIGNED`, `BLUE` und `GOLD` gewechselt werden, waehrend eine Zusammenfassungszeile die Zuordnung fuer alle transferierten Operators lesbar macht. `FOBTestScreen` fuehrt diese Auswahl als geordneten, read-only stagingnahen UI-Zustand und gibt sie beim bestaetigenden `Start Mission` explizit weiter; `MetaLayerFlow` traegt die Fireteam-IDs kontrolliert bis in `MissionTestSetup`, und `MissionTestSetup` setzt `set_fireteam_id(...)` fuer Friendly-Slots jetzt bevorzugt aus der FOB-Vorbereitung statt starr aus den Roster-Presets.
- Offene Punkte: die aktuelle Vorbereitung bleibt bewusst minimal auf `UNASSIGNED`, `BLUE` und `GOLD` begrenzt; groessere Squad-/Loadout-Oberflaechen oder komplexere Rollenlogik sind weiterhin nicht Teil dieses Pfads.
- Risiken: die Fireteam-Zuordnung wird aktuell als zur Slot-Reihenfolge paralleles Array transportiert; spaetere groessere Teamgroessen oder frei sortierbare FOB-Listen sollten diesen kleinen Datenvertrag dann explizit auf einen robusteren Mapping-Pfad anheben.
- Naechster Schritt: den neuen FOB-Vorbereitungspfad bei Bedarf spaeter sichtbarer in Missions- oder Debrief-UI aufgreifen, ohne daraus eine neue globale Persistenz- oder Managementschicht zu machen.

### TASK_078 - Meta-Layer: Navigation und Map-Ansicht
- Status: implementiert
- Stand: der Meta-Layer besitzt jetzt einen direkten Wechsel zwischen `Homebase`, `FOB` und der echten Missionskartenansicht, aber die Navigation liegt nicht mehr als separate globale Leiste ueber dem Screen. Stattdessen sitzen die drei Umschaltbuttons jetzt in den jeweiligen Briefing-Headern von Homebase, FOB und der eingebetteten Missionsvorschau; der dritte Button ist fuer den Nutzer bewusst als `Mission` beschriftet. Der fruehere read-only `meta_map_screen`-Pfad wurde wieder entfernt; stattdessen hostet `MetaLayerFlow` in `MissionHost` direkt eine Preview-Instanz von `res://scenes/tests/mission_reactivity_test.tscn`, die dieselbe Kartenbasis, NPCs und den aktuellen FOB-/Planungszustand lesbar anzeigt. Wechsel zwischen den drei Meta-Ansichten verlieren dabei weder Teamauswahl noch FOB-Vorbereitungsstand, waehrend Mission und Debrief die Navigation bewusst ausblenden.
- Offene Punkte: die Map-Ansicht ist aktuell eine reine Text-/Statuszusammenfassung ohne grafische Kartenvorschau oder Missionsplanung.
- Risiken: der Map-Pfad nutzt bewusst den bestehenden Test-Missionsbezug und keine neue globale Planungsarchitektur; falls spaeter mehrere Missionskarten dynamisch waehlbar werden, sollte der aktuelle feste Map-Referenzpfad explizit auf einen kleinen Datenvertrag angehoben werden.
- Naechster Schritt: nur bei eigenem Task eine grafischere Kartenlesbarkeit oder einfache Objective-/Spawn-Hinweise ergaenzen, ohne die Map-Ansicht in einen Editor oder Taktikplaner umzubauen.

### TASK_079 - FOB: Fireteam-Management, Respawn-/Loadout-Staging und Dropship-Wartezone
- Status: implementiert
- Stand: `res://scenes/meta/fob_test_screen.tscn` wurde von der kompakten Prep-Ansicht zu einem klaren Vier-Spalten-Screen umgebaut: links die verfuegbaren uebertragenen Operators, daneben die Fireteam-Spalte, dann ein Respawn-/Loadout-Staging-Bereich und rechts die Dropship-Wartezone. In einer anschliessenden Politur wurden die Spaltenbreiten und Aussenabstaende nochmals reduziert, der Respawn-Anteil bewusst deutlich kleiner gehalten und der Loadout-Bereich vergroessert, damit die Seiten und die Unterkante im kleineren Editorfenster weniger leicht abgeschnitten werden. Die Meta-Navigation sitzt dabei weiter im FOB-Header statt in einer separaten globalen Leiste. `res://scripts/meta/fob_screen.gd` fuehrt explizite Fireteam-Definitionen mit editierbaren Labels, einem unverlierbaren `FT1`, anlegbaren weiteren Fireteams per `+` und loeschbaren Zusatzteams per `-`. Die Zuordnung bleibt staging-first, wurde aber von Button-only auf einen kleinen Drag-and-Drop-Pfad erweitert: Operator-Portraitkarten koennen jetzt aus der Verfuegbar-Spalte oder aus bestehenden Fireteam-Mitgliedslisten direkt auf Fireteam-Karten gezogen werden; Fireteam-Karten selbst sind ebenfalls draggable und koennen in eigene Drop-Zonen fuer Respawn bzw. Loadout gezogen werden. Neu hinzugekommen sind ausserdem ein expliziter Fireteam-Lead pro Team und ein individueller Member-Loadout-State: Armor kann weiter als schneller Team-Default (`LIGHT`, `MEDIUM`, `HEAVY`) gesetzt werden, waehrend im vergroesserten Loadout-Bereich jedes Fireteam-Mitglied zusaetzlich eigene Armor- und Waffenklassen (`Maschinenpistole`, `Sturmgewehr`, `Mischung`, `Sonderwaffen`) bekommt. Rechts simuliert die kleine Dropship-Wartezone weiter einen `inbound`- und anschliessenden Boarding-Zustand fuer die aktuell aktiven Fireteams, ohne daraus eine echte Fahrzeug- oder Gameplay-Simulation zu machen. `MetaLayerFlow` behaelt diesen FOB-Zustand ueber View-Wechsel hinweg bei und uebergibt weiterhin nur die expliziten Fireteam-IDs in den bestehenden Missionspfad.
- Offene Punkte: Loadout- und Respawn-Werte bleiben bisher bewusst FOB-Meta-State ohne tiefe Missionswirkung; die Dropship-Zone ist eine lesbare Meta-Timerdarstellung, keine echte Transportmechanik.
- Risiken: die Fireteam-Labels sind editierbar, aber fuer den Missionspfad wird weiterhin die interne Fireteam-ID (`ft1`, `ft2`, ...) transportiert; spaetere Systeme muessen diese Trennung zwischen lesbarem Label und stabilem Datenwert erhalten.
- Naechster Schritt: spaeter bei Bedarf einzelne FOB-Stagingwerte gezielt im Debrief oder Missionsstart sichtbarer machen, ohne daraus direkt ein grosses Loadout-, Inventar- oder Fahrzeugsystem wachsen zu lassen.

### TASK_080 - Meta-Layer: Transfer-Sichtbarkeit, Pool-DnD und Charakterbogen-Toggle
- Status: implementiert
- Stand: `res://scripts/meta/meta_layer_flow.gd` trennt jetzt sauber zwischen Homebase-Restpool, Homebase-Staging und bereits in die FOB uebertragenen Operators. Nach `Send to FOB` verschwinden uebertragene Personen aus der Homebase und werden nur noch im FOB-Pool gefuehrt. In `res://scripts/meta/homebase_screen.gd` zeigt das linke Roster nur noch aktuell nicht gestagte Homebase-Personen; Doppelklick auf eine NPC-Karte oeffnet den Charakterbogen, waehrend ein neuer `Close`-Button im Charakterbogen ihn wieder ausblendet. In der FOB zeigt `res://scripts/meta/fob_screen.gd` die Available-Spalte nur noch unzugewiesene Operators; Mitgliedskarten koennen per Drag-and-Drop auf Fireteams und wieder zurueck in den Available-Pool bewegt werden. Der FOB-Respawnblock sitzt jetzt nochmals staerker verdichtet im Header links neben `Start Mission`, redundante Brief-Statuszeilen wurden dort ausgeblendet, und die FOB-DnD-Pfade wurden gegen Control-Hierarchie-Probleme gehaertet, indem dynamisch erzeugte Operator-Karten in der FOB Drop-Hover per `MOUSE_FILTER_PASS` an ihre Eltern weiterreichen, statt Fireteam- oder Available-Drops lokal zu verschlucken.
- Offene Punkte: Der neue Pool-Wechsel bleibt weiterhin reiner Meta-State; es gibt noch keinen Ruecktransfer von der FOB zur Homebase ausserhalb spaeterer eigener Tasks.
- Risiken: Die Operator-Pools werden jetzt explizit getrennt gehalten; spaetere Persistenz oder Kampagnenlogik muss diese Trennung bewusst uebernehmen, statt wieder still dieselbe Liste fuer Homebase und FOB zu teilen.
- Naechster Schritt: Falls gewuenscht, spaeter gezielt einen expliziten Ruecktransfer- oder Homebase-Reintegration-Task einfuehren, ohne den aktuellen Meta-State-Pfad wieder aufzuweichen.

### TASK_080 – UI-Polish: Header, Loadout, Lead-Star und Drop-Panel-Styling
- Status: implementiert
- Stand: Die FOB-Oberflaeche wurde in mehreren Bereichen visuell ueberarbeitet:
  - **Nav-Buttons** (Homebase, FOB, Mission) auf ein Drittel der urspruenglichen Hoehe reduziert (custom_minimum_size 16px, font_size 8).
  - **Respawn-Anchor-Panel** auf doppelte Breite vergroessert (90 → 180px).
  - **Loadout-Drop-Panel** an den oberen Rand des Loadout-Bereichs verschoben, sodass der Drop-Bereich sofort sichtbar ist.
  - **Dropship-Drop-Panel** visuell an das Loadout-Drop-Panel angeglichen (gleiche Margins und Schriftgroesse).
  - **Loadout pro NPC**: Jedes Fireteam-Mitglied erhaelt jetzt einen Armor-Dropdown (Light/Medium/Heavy) und zwei separate Waffen-Slots (Maschinenpistole, Sturmgewehr, Sonderwaffe). Die fruehere "Mischung"-Option wurde entfernt; das Datenmodell nutzt `weapon_1` und `weapon_2` statt eines einzelnen `weapon`-Felds.
  - **Lead-Indikator**: Der bisherige separate Lead-Button unter der NPC-Karte wurde entfernt und durch einen Stern direkt in der `NPCCompactCard` ersetzt. Grauer Stern = kein Leader, gelber Stern = Leader. Der Stern ist klickbar und loest den Lead-Toggle aus, ohne eine separate Schaltflaeche zu benoetigen.
- Offene Punkte: Die Aenderungen sind rein visuell und betreffen nur die FOB-UI; das zugrunde liegende Meta-State-Modell bleibt unveraendert, abgesehen von der Erweiterung auf zwei Waffen-Slots.
- Risiken: Die Erweiterung auf `weapon_1`/`weapon_2` ist abwaertskompatibel; bestehende Daten mit einem einzelnen `weapon`-Feld werden beim Lesen automatisch auf `weapon_1` gemappt.
- Naechster Schritt: Weitere UI-Verfeinerungen oder Gameplay-Logik koennen auf dieser Grundlage aufbauen, ohne die bestehende Architektur zu veraendern.

### TASK_081 – Meta-Layer: UI-Harmonisierung fuer FOB, Homebase und Loadout
- Status: implementiert
- Stand: Homebase und FOB nutzen jetzt dieselben kompakten Header-Proportionen. Der FOB zeigt einen verdichteten Missionsbrief mit stabil rechts sitzendem `Start Mission`, waehrend Missionsname, Map und Slot-Kontext explizit aus `res://scripts/meta/meta_layer_flow.gd` kommen. In `res://scripts/meta/fob_screen.gd` wurde die Charaktereinsicht zu einem schliessbaren Overlay ausgebaut, das per Doppelklick auf kompakte NPC-Karten geoeffnet wird und Portrait, Rolle, Status, Skills, Traits, Bio sowie Loadout-Hinweise aus dem bestehenden Meta-State rendert. NPC-Karten und Charakterboegen zeigen dabei konsistente Meta-Orte an: Homebase fuer Roster/Transfer, FOB fuer Pool/Loadout/Respawn und Rover fuer Wait-Zone, Boarding und bereits verladenen Zustand. Der Loadout-Bereich arbeitet jetzt pro Fireteam-Mitglied mit kompakter NPC-Karte, Lead-Stern sowie direkten Selektoren fuer Armor, Slot 1 und Slot 2; derselbe mitgliedsbezogene Block wird auch im Respawn-Fenster gerendert.

  Parallel wurde in `res://scripts/meta/npc_compact_card.gd` die Drag-Preview stabilisiert: kompakte Karten behalten beim Ziehen ihre Geometrie und uebernehmen nicht mehr die expandierte Breite aus Fireteam- oder Loadout-Layouts. Loadout-, Respawn- und Dropship-Panels sind direkte Drop-Ziele; Fireteams werden zwischen diesen Fenstern als Move statt als Kopie verschoben. Die Staging-Zonen besitzen eigene sichtbare Fireteam-Karten-Hosts, rendern diese aber erst nach explizitem DnD. Der Fireteam-Pool links blendet bereits gestagte Teams konsequent aus und kann selbst wieder als Rueckgabe-Ziel genutzt werden. Fuer kleine Rueckwege existieren ein `Clear` im Loadout-Staging und ein gezieltes Entfernen des fokussierten Fireteams aus der Dropship-Wartezone. Die Wait-Zone rendert sichtbare Fireteam-Karten mit Portraits, Namen und individuellen Boarding-Fortschritten; nach der automatischen Dropship-Ankunft wechselt sie erst in `ready`, und `Start Boarding` startet die eigentlichen NPC-Boarding-Timer.

  Die Homebase-Flugdeckansicht startet jetzt leer. Das obere Dropdown waehlt nur noch den Typ `Dropship` oder `Frachter`; erst `+` erzeugt die jeweilige Shipcard im Flight Deck. Entfernen, Pilot-Slot, Cargo-Dropdown und `Load` sitzen lokal in der einzelnen Shipcard, sodass Auswahl, Laden und Startzustand pro Schiff zusammenbleiben. Das gestagte Team startet ueber `Send to FOB` direkt aus der Kopfzeile des Transferfensters; der Button sitzt nicht mehr im globalen Mission-Brief. Zusaetzlich besitzt die Homebase nun ein kompaktes Missions-Dropdown im Header, das Missions-/Map-Kontext fuer Homebase, FOB, Map-Overview und den Testmissionspfad gemeinsam umstellt, ohne die Header-Zeile aufzublaehen. In einer spaeteren Recovery-Nachpflege aktualisiert `MetaLayerFlow` Homebase, FOB und Map-Ansicht waehrend laufender Transfer-Timer jetzt pro Tick, sodass Transit-Zustaende nicht erst bei Ankunft sichtbar werden. Die nummerierten Fensterueberschriften in Homebase und FOB wurden dabei wiederhergestellt, und Pilot-NPC-Karten in Homebase-Shipcards sowie FOB-Transportkarten werden waehrend des Transits jetzt gemeinsam mit der jeweiligen Shipcard sichtbar deaktiviert bzw. ausgegraut.
- Offene Punkte: Der neue Charakter-Overlay, die Homebase-Flugdeckansicht und die Karten in der Dropship-Wartezone bleiben weiterhin reiner Meta-State ohne direkte Missions- oder Persistenzwirkung. Die Meta-Map spiegelt die per-Mitglied-Loadouts jetzt direkt auf den Preview-Fireteam-Karten und zeigt laufende Homebase->FOB-Transfers als eigene Route mit separaten Team-/Pilot-Markern; weitergehende Ruecktransfers oder mehrere unterschiedliche Flugkorridore bleiben weiterhin ausserhalb dieses kleinen V1-Scope.
- Risiken: Die Mission-Kontextdaten und die neuen Homebase-Transferdauern werden aktuell bewusst noch klein und fest aus dem bestehenden Testpfad gespeist; falls spaeter mehrere Missionen oder unterschiedliche Flieger dynamisch waehlbar werden, sollte daraus ein expliziter kleiner Datenvertrag werden statt weiterer UI-String-Glue. Die Homebase-Transportanzeige bleibt ein Meta-Orchestrierungspfad in `MetaLayerFlow` und ist keine tiefergehende Transport- oder Kampagnen-Simulation.
- Naechster Schritt: Falls gewuenscht, spaeter gezielt Ruecktransfers, mehrere unterschiedliche Flieger oder eine kleine Karten-/Debrief-Sicht auf laufende Homebase-Transfers ergaenzen, ohne den aktuellen kleinen Meta-Flow zu einer grossen Persistenz- oder Transportarchitektur aufzublasen.

### TASK_082 – Gemeinsamer Terrain-Renderer fuer Editor und Mission
- Status: implementiert
- Stand: Mit `res://scripts/terrain/terrain_map_renderer.gd` existiert jetzt ein kleiner gemeinsamer Renderpfad fuer JSON-basierte TerrainMapData. Der Editor nutzt diesen Renderer fuer den kompletten Kartenaufbau aus Tile-, Cliff- und Objekt-/Wall-Overlays, statt den Full-Rebuild weiterhin nur lokal in `map_editor.gd` zu halten. Die Missions-Testszene rendert dieselbe JSON-Karte jetzt ebenfalls ueber diesen Pfad; `MissionTestSetup` registriert die Tiles weiter in der `TerrainRegistry`, laesst die sichtbare Karte aber nicht mehr aus vorplatzierten Boden-Sprites plus Modulate entstehen. Zusaetzlich traegt `TerrainMapData` jetzt einen kleinen Marker-Datenvertrag, und die zentrale 32x32-Testmap speichert `spawn_alpha`, `spawn_bravo`, `objective_point` sowie die beiden Flank-Anker direkt in derselben JSON-Datei. `MissionTestSetup` uebernimmt diese Markerpositionen in die vorhandenen Szenen-Marker, sodass bestehende NodePath-Pfade weiter funktionieren, und die read-only Meta-Map zeigt dieselben Markerkoordinaten ebenfalls aus der Map-Datei an. `res://scenes/maps/iso_map_v2_layout.tscn` bleibt damit auf Render-Container plus Fallback-Marker reduziert. In einer spaeteren Recovery-Nachpflege speichert `TerrainMapData` zusaetzlich `mission_slot_count` direkt in der JSON, der Map-Editor bietet dafuer nun ein kleines Map-Settings-Panel samt Marker-Zuweisung fuer die festen Missionsmarker, und `MetaLayerFlow` kann die Missions-Slot-Kapazitaet bei Bedarf direkt aus der Map-Datei aufloesen statt nur aus statischen Missionsdefinitionen zu lesen.
- Offene Punkte: Die laufenden Editor-Einzelupdates fuer geaenderte Tiles nutzen weiterhin ihre bestehenden lokalen Update-Helfer; der gemeinsame Pfad ist aktuell der gemeinsame Full-Rebuild und der Runtime-Aufbau. Die offen gebliebenen Marker-Themen sind inzwischen explizit als `TASK_115` ausgelagert, statt weiter als unscharfer Restpunkt in `TASK_082` zu bleiben.
- Risiken: Die Missionsmarker werden weiter aus der Map-Datei in Szenen-Marker gespiegelt, solange andere Testpfade noch NodePaths auf diese Marker erwarten. `mission_slot_count` ist bewusst nur ein kleiner Map-Metadatenvertrag; spaetere Missions- oder Kampagnenlogik sollte diesen Wert explizit weiterreichen statt erneut separate Slot-Quellen einzufuehren.
- Naechster Schritt: Bei weiterem Marker-Bedarf gezielt `TASK_115` bearbeiten und erst danach groessere Terrain-Funktionen wie mehrere Missionskarten oder graphischere Meta-Map-Vorschauen darauf aufbauen.

### TASK_085 – Charakterbogen Combat-Integration (get_combat_effects)
- Status: implementiert
- Stand: `TestUnit` bietet jetzt `get_combat_effects() -> Dictionary`, das die combat_effects-Werte (`speed_multiplier`, `hit_modifier`, `evasion_modifier`, `damage_taken_multiplier`) direkt aus dem Charakterbogen-Bundle zurueckgibt, mit sicheren Defaults bei leerem Bundle.
- Offene Punkte: keine.
- Risiken: Rein additiv; bestehende Einzelgetter bleiben weiter verfuegbar.
- Naechster Schritt: Consumers koennen `get_combat_effects()` statt der Einzelmethoden nutzen.

### TASK_086 – Waffenmodell (WeaponData)
- Status: implementiert
- Stand: Neues `scripts/core/weapon_data.gd` als statische Waffen-Registry mit drei Typen: Maschinenpistole (smg, weapon_gun_*, schnell, niedrig), Sturmgewehr (rifle, weapon_rifle_*, balanciert), Schienenkanone (rail_gun, weapon_rifle_* in 2x, langsam, hoch). `TestUnit` traegt `weapon_1_id`/`weapon_2_id` als Exports und liefert `get_active_weapon_id()`. `MissionCombatLoopDriver` nutzt aktive Waffe des Angreifers fuer damage/hit_chance/ticks statt globaler Konstanten. In `fob_screen.gd` wurde "Sonderwaffe" zu "Schienenkanone" umbenannt und weapon-ID `special` zu `rail_gun` migriert (abwaertskompatibel).
- Offene Punkte: keine (Loadout-Pipeline durch TASK_087 geschlossen).
- Risiken: Globale combat-Exports (`damage_per_hit`, `base_hit_chance`, `ticks_between_attacks`) auf `MissionCombatLoopDriver` bleiben als Fallback-Defaults erhalten, werden aber im normalen Pfad nicht mehr genutzt.
- Naechster Schritt: keiner.

### TASK_087 – Loadout-Pipeline und Waffen-Sprites
- Status: implementiert
- Stand: `meta_layer_flow.gd` liest per `_build_fob_member_loadouts()` die `member_loadouts` und `lead_unit_id` aus allen Fireteam-Definitionen der FOB-UI, baut ein flaches `{unit_id: {weapon_1, weapon_2, armor, is_fireteam_lead}}` Dictionary und uebergibt es via `mission_setup.set("member_loadouts", ...)` an `MissionTestSetup`. `mission_test_setup.gd` hat neue Property `member_loadouts: Dictionary` und ruft nach dem Roster-Preset `_apply_fob_loadout_override()` auf, das `weapon_1_id`, `weapon_2_id`, `armor` und `is_fireteam_lead` via `apply_identity_config()` auf die Unit setzt. Nur Friendlies erhalten Overrides; Enemies bleiben unberuehrt. Ohne FOB-Daten greifen die Roster-Defaults. `test_unit.gd` rendert jetzt zusaetzlich ein `WeaponVisual`-`Sprite2D` als Child der bestehenden `Visual`-Sprite, leitet die Richtung aus der aktuellen Unit-Textur ab (Fallback `SE`), nutzt `WeaponData.get_asset_path()` und `WeaponData.get_sprite_scale()` fuer Textur und Skalierung und setzt kleine Kenney-kompatible Offsets pro Iso-Richtung. Dadurch ist die Schienenkanone visuell doppelt so gross wie das Sturmgewehr.
- Offene Punkte: keine.
- Risiken: keine.
- Naechster Schritt: keiner.

### TASK_088 – Leadership-Bonus auf Fireteam-Mitglieder
- Status: implementiert
- Stand: Leadership-Bonus-System mit automatischer Lead-Nachfolge implementiert. `test_unit.gd` hat `is_fireteam_lead`-Export, `_leadership_bonus`-Feld, `apply_leadership_bonus()`, `clear_leadership_bonus()`, `get_leadership_hit_modifier()`. Der Bonus fliesst ueber `get_combat_effects()` und `_extract_unit_hit_modifier()` in SimulationRoot in die Trefferberechnung ein. `mission_combat_loop_driver.gd` verwaltet pro Tick Fireteam-Leads: wenn Original-Lead down → Unit mit hoechstem Leadership uebernimmt automatisch; wenn Original-Lead respawnt → uebernimmt sofort zurueck. Bonus = `leadership * 0.15` auf alle Fireteam-Mitglieder (nicht Lead selbst).
- Offene Punkte: keine (durch TASK_087 wird `is_fireteam_lead` jetzt aus `lead_unit_id` der FOB-Daten gesetzt).
- Risiken: keine
- Naechster Schritt: keiner.

### TASK_089 – Enemy Cover-Seeking
- Status: implementiert
- Stand: `TerrainRegistry` um `get_walkable_cover_tiles_in_radius(world_center, radius)` erweitert. `_build_enemy_reposition_target()` in `mission_combat_loop_driver.gd` sucht jetzt Cover-Tiles im Reposition-Radius, filtert nach Mindestabstand, sortiert nach Cover-Score absteigend und waehlt das beste Tile. Fallback auf bisherige Zufalls-Reposition wenn keine Cover-Tiles vorhanden. Cooldown bleibt erhalten.
- Offene Punkte: keine
- Risiken: keine
- Naechster Schritt: TASK_090 differenzierte Enemy-Typen.

### TASK_090 – Differenzierte Enemy-Typen
- Status: implementiert
- Stand: 6 Enemy-Archetypen (Standard, Scout, Heavy, Sniper, Medic, Officer) als `ENEMY_ARCHETYPES`-Array in `unit_roster_presets.gd` definiert. Jeder Archetyp hat eigene Skills, Waffe und Traits. `get_preset()` fuer `team_bravo` waehlt Archetyp per Unit-ID-Hash automatisch. Lookup-Funktionen `get_enemy_archetype_for_unit()` und `get_enemy_archetype_by_id()` ergaenzt. Friendly-Roster bleibt unberuehrt.
- Offene Punkte: keine
- Risiken: keine
- Naechster Schritt: TASK_091 Awareness/Detection Delay.

### TASK_091 – Awareness: Detection-Delay
- Status: implementiert
- Stand: Detection-Delay basierend auf dem `awareness`-Wert einer Unit implementiert. `_detection_progress`-Dictionary in `mission_combat_loop_driver.gd` trackt pro Attacker-Target-Paar verbleibende Detection-Ticks. Formel: `(1.0 - awareness) * MAX_DETECTION_DELAY_TICKS` (15 Ticks). awareness=1.0 erkennt sofort, awareness=0.0 braucht 15 Ticks. Timer wird pro Tick dekrementiert und bei LOS-Verlust zurueckgesetzt. `get_awareness()` in `test_unit.gd` ergaenzt.
- Offene Punkte: keine
- Risiken: keine
- Naechster Schritt: TASK_092 Stealth/Sichtreichweite.

### TASK_092 – Stealth: Reduzierte Sichtreichweite
- Status: implementiert
- Stand: `_get_effective_range(target)` in `mission_combat_loop_driver.gd` berechnet effektive Sichtreichweite basierend auf dem `stealth`-Wert des Ziels. Formel: `contact_range * (1.0 - stealth * 0.5)`. stealth=0.0 ergibt volle Reichweite, stealth=1.0 halbiert sie. Alle drei LOS-Checks verwenden jetzt die effektive Reichweite. `get_stealth()` in `test_unit.gd` ergaenzt.
- Offene Punkte: keine
- Risiken: keine
- Naechster Schritt: TASK_093 Discipline/Hold-Fire.

### TASK_093 – Discipline: Hold-Fire-Disziplinbrueche
- Status: implementiert
- Stand: `_check_discipline_break(unit)` in `mission_combat_loop_driver.gd` wuerfelt pro Tick bei Hold-Fire ob Unit den Befehl bricht. Formel: `DISCIPLINE_BREAK_BASE_CHANCE (0.08) * (1.0 - discipline)`. discipline=1.0 → 0% Bruch, discipline=0.0 → 8% pro Tick. Cooldown (`DISCIPLINE_BREAK_COOLDOWN_TICKS=10`) verhindert Dauerfeuer. Bruch wird als Event sichtbar. `get_discipline()` in `test_unit.gd` ergaenzt.
- Offene Punkte: keine
- Risiken: keine
- Naechster Schritt: TASK_094 Recognition/Friendly-Fire.

### TASK_094 – Recognition: Friendly-Fire-Verwechslung
- Status: implementiert
- Stand: `_check_misidentification(attacker, attacker_id)` in `mission_combat_loop_driver.gd` wuerfelt pro Tick ob ein Friendly sein Ziel verwechselt. Formel: `MISIDENTIFICATION_BASE_CHANCE (0.03) * (1.0 - recognition)`. recognition=1.0 → 0% Verwechslung, recognition=0.0 → 3% pro Tick. Naechste eigene Unit wird als Ziel gewaehlt, Effect mit `allow_friendly_fire: true` gesendet. Cooldown (`MISIDENTIFICATION_COOLDOWN_TICKS=15`) verhindert Dauerfeuer auf Eigene. Nur Friendlies koennen verwechseln, Enemies nie.
- Offene Punkte: keine
- Risiken: keine

### TASK_095 – Combat Medic Support
- Status: implementiert
- Stand: `SimulationRoot` verarbeitet `heal`-Effects autoritativ ueber `_apply_heal_effect()`. `TestUnit` unterstuetzt dafuer `apply_heal(amount, heal_context)` und kann dadurch einen `down`-Zustand wieder nach `fit` anheben, solange der Heal vor einem `bleedout` greift. Combat-Medics brauchen nun zusaetzlich ein im Waffenslot ausgeruestetes `medictool`, das im FOB-Dropdown und Resolver-Pfad als eigener Slot-Gegenstand gefuehrt wird, genau 2 Kartenfelder Heal-Reichweite nutzt und visuell als rot eingefaerbtes Pistolenmodell auftaucht. `mission_combat_loop_driver.gd` erkennt Combat-Medics ueber `role_id`/`role_name`, waehlt bevorzugt `down`-Allies und danach den am staerksten verletzten `fit`-Ally in Reichweite, und laeuft fuer dringende Ziele ausserhalb der Heal-Reichweite aktiv an. Heal-/Patch-Events bleiben sichtbar; `scripts/tests/medic_support_verifier.gd` deckt jetzt Revive-vor-Bleedout, 2-Felder-Reichweite, Tool-Zwang, Dropdown-Support, Anlauf, Priorisierung und Cooldown ab.
- Offene Punkte: keine groessere Support-Architektur, keine echte Revive-Animation und keine allgemeine Verbrauchs- oder Nachschubkette jenseits des slotgebundenen `medictool`.
- Risiken: Der Supportpfad bleibt bewusst auf Combat-Medics und das konkrete `medictool` begrenzt. Falls spaeter weitere Support-Rollen oder Verbrauchsregeln hinzukommen, sollten sie diesen kleinen Pfad explizit erweitern statt eine zweite Utility-Wahrheit aufzubauen.
- Naechster Schritt: Falls gewuenscht, spaeter eigenstaendige Folge-Tasks fuer Verbrauchslogik, Revive-Animation oder weitere Support-Rollen schneiden.

### TASK_099 – Wegpunktplanung und Order-Visualisierung
- Status: implementiert
- Stand: Der `TacticalInputController` haelt jetzt pro Fireteam und Phase echte `FireteamOrderPlan`-Daten auf Basis der Task-97-Modelle. Rechtsklick setzt Wegpunkte fuer alle aktuell ausgewaehlten Fireteams, ein kontextsensitives Kurzmenue erlaubt direkt `move`, `defend`, `engage`, `flank` und `take`, und Wegpunkte koennen nachtraeglich per Drag verschoben oder per Delete entfernt werden. Ein schlanker `FireteamOrderVisualizer` rendert die Plaene rein lesend als Linien und Symbolmarker in der Missionsszene; beim Planen werden keine Commands an SimulationRoot oder Flow-Driver gesendet.
- Offene Punkte: keine Phasen-Ausfuehrung, keine Ad-hoc-Orders, keine Pathfinding-Auswertung entlang der Wegpunkte und keine ausgebaute Kontextmenue-/Polish-Schicht ueber den kurzen Missions-Testpfad hinaus.
- Risiken: Die Planungsdaten liegen bewusst lokal im bestehenden Mission-Planning-State-Bridge-Pfad; spaetere globale Plan-Ausfuehrung muss diese Daten explizit konsumieren, statt wieder direkte Sofort-Commands aus dem Input-Controller abzuleiten. Die Visualisierung ist absichtlich rein lesend und darf spaeter nicht zum versteckten Gameplay-Treiber werden.
- Naechster Schritt: Task 100 kann auf diesem Slice aufsetzen, um einen globalen Phase-Controller und die tatsaechliche Plan-Ausfuehrung einzufuehren.

### TASK_100 – PhaseController und globale Plan-Ausfuehrung
- Status: implementiert
- Stand: Eine eigene `PhaseController`-Instanz verwaltet jetzt globale Missionsphasen getrennt vom UI-Bearbeitungskontext. Phase 0 bleibt Pre-Mission, Phase 1 existiert immer, `+ Phase` erweitert den globalen Phasenraum, und `Next Phase` ist der einzige globale Startpfad. Beim Weiterschalten startet der `TacticalInputController` alle Fireteam-Plaene der neuen Phase gleichzeitig, aktiviert Wegpunkte pro Fireteam nacheinander und erzeugt jeden Laufzeitbefehl weiter ueber `MissionCommandFlowDriver` -> Commander/FTL -> Unit -> `SimulationRoot.enqueue_command()`.
- Offene Punkte: keine Ad-hoc-Befehle, keine Suppression, keine Gegner-Phasen und keine ausgebaute Resume-/Interrupt-Logik fuer spaetere Task-101+-Verhaltensresolver.
- Risiken: Die Wegpunkt-Fertigmeldung haengt aktuell an einem schlanken Zielradius plus optionaler Haltezeit auf Fireteam-Ankerbasis. Falls spaeter echte Formations-/Suppression-/Kontaktlogik hinzukommt, muss diese Fertigbedingung bewusst erweitert werden statt still implizit zu kippen.
- Naechster Schritt: Task 101 kann jetzt auf dem globalen Phase- und Ausfuehrungsrahmen aufsetzen, um Standardverhalten und Resolver pro Fireteam sauber einzuschieben.

### TASK_101 – FireteamBehaviorResolver und Standardverhalten
- Status: implementiert
- Stand: `FireteamBehaviorResolver` leitet nun aus dem aktuellen Fireteam-Leader ein `FireteamBehaviorProfile` ab und mappt Traits, Leadership und Toughness auf Advance-Style, Cover-Prioritaet, Fire-Discipline, Cohesion und Suppression. Der `TacticalInputController` berechnet diese Profile zur Laufzeit fuer geplante Orders und Standard-Fallbacks, nutzt sie fuer leadergesteuertes `flank` mit konkreter Zielverfeinerung und sendet beim Start eines Flankierens `flank_initiated` ueber den `EventRouter`. Fireteams ohne aktive Orders fallen bei Phasenstart und nach Planende auf `hold_position` zurueck; `cautious` sucht bei Kontakt lokal Deckung.
- Offene Punkte: keine Suppression-Logik, keine Resume-/Interrupt-State-Machine und noch keine inter-fireteam Koordination ueber den Router jenseits des Flank-Startsignals.
- Risiken: Das Standardverhalten bleibt bewusst klein. `cautious` nutzt nur lokale Cover-Spruenge; spaetere Tasks muessen diesen Fallback explizit ausbauen statt daraus still eine vollstaendige KI zu machen.
- Naechster Schritt: Task 102 kann jetzt auf den aktiven Behavior-Profilen aufsetzen, um Ad-hoc-Orders und Rueckkehr in den Planfluss sauber zu implementieren.

### TASK_109 - TacticalStanceController und TacticalStancePanel
- Status: implementiert
- Stand: Ein neuer missionslokaler `TacticalStanceController` verwaltet fluechtige Stance-Anforderungen pro Fireteam (`cautious`, `normal`, `aggressive`) ausserhalb von `FireteamOrderPlan` und `PhaseState`. `MissionTacticalSandboxController` haengt diese Stances an den bestehenden `planning_state`-Bridge-Pfad, damit Preview- und aktive Missionsinstanz denselben missionslokalen Stance-Zustand teilen. `FireteamBehaviorResolver` erweitert `FireteamBehaviorProfile` um `tactical_stance` und verschiebt jetzt `advance_style`, `cover_priority` und `suppression_threshold` traitabhaengig entlang der vorhandenen `rush`/`bounding`/`creep`-Skala. In der Missions-UI gibt es ein neues `TacticalStancePanel` fuer Einzel- und Mehrfachauswahl; `FireteamStatusPanel`, Fireteam-Header und die Units selbst zeigen die aktuelle Stance als `C`/`N`/`A` bzw. `MIXED` an. Zusaetzlich liefert der Controller einen versionierten `tactical_stance_sync`-Stand fuer Preview-/Runtime-Bruecken und spaetere Multiplayer-Pfade; `SimulationRoot` nimmt die Badge-Daten direkt in die bestehenden Remote-Unit-Snapshots auf.
- Offene Punkte: keine weiteren innerhalb des TASK_109-Slices; spaetere echte Multiplayer-Eingabe fuer Stance-Aenderungen bleibt ein eigener Folgepfad oberhalb des jetzt vorhandenen Sync-Vertrags.
- Risiken: die Haltung bleibt bewusst ein fluechtiger Missionszustand im Tactical-Sandbox-Controller; spaetere tiefere Runtime- oder Netzwerkpfade sollten den vorhandenen `tactical_stance_sync`-Vertrag und die Snapshot-Felder explizit uebernehmen, statt eine zweite persistente Stance-Wahrheit aufzubauen.
- Naechster Schritt: TASK_110 auf dem jetzt vorhandenen `tactical_stance`-Feld der Behavior-Profile aufsetzen und die intra-Fireteam-Bewegungsmuster daraus konkret ausfuehren.

### TASK_110 - FireteamMovementController und Bewegungsmuster
- Status: implementiert
- Stand: Ein neuer `FireteamMovementController` fuehrt aktive Fireteam-Bewegung als eigene Laufzeit-Schicht ueber dem bestehenden Command-/Effect-Pfad aus. `MissionTacticalSandboxController` startet ihn pro geplantem oder ad-hoc-Wegpunkt mit dem bereits abgeleiteten `FireteamBehaviorProfile`, sodass `rush`, `bounding` und `caterpillar` nur noch aus dem Resolver konsumiert, aber nicht erneut berechnet werden. `rush` bewegt alle fit Members gleichzeitig und klemmt bei gerissener Kohaesion auf die langsameren Members. `bounding` bildet eine Bewegungs- und eine Deckungsgruppe, haelt den Lead standardmaessig in der Deckungsgruppe und rotiert ueber explizite `bound_complete`-Ereignisse. `caterpillar` nutzt dieselbe Laufzeitschicht fuer Einzelvorstoss mit Deckungsrestgruppe. Bei schweren Verlusten bricht der Controller koordinierte Muster kontrolliert auf `rush` herunter. Das Fireteam-Statuspanel zeigt den aktiven Bewegungsmodus als `MOVE RSH/BND/CAT`; der `EventRouter` erweitert den Vertrag um `fireteam_bound_complete`.
- Offene Punkte: Noch keine eigene In-World-Visualisierung einzelner Bound-Segmente und noch keine Nutzung bekannter Feindrichtungen fuer die Deckungsgruppe; das bleibt bei spaeteren Security-/Contact-Tasks.
- Risiken: Die Bewegungsmuster arbeiten bewusst als schlanke Laufzeit-Orchestrierung ueber `SimulationRoot.enqueue_command()`. Wenn spaetere Tasks tiefere Runtime-Status-Synchronisierung brauchen, sollte diese bewusst zentralisiert werden statt wieder verteilt in Bewegungs- oder UI-Skripten zu landen.
- Naechster Schritt: TASK_111 kann jetzt auf dem separaten Bewegungscontroller aufsetzen und Security-/Overwatch-Logik im Haltzustand ergaenzen, ohne intra-Fireteam-Movement erneut anfassen zu muessen.

### TASK_111 - FireteamSecurityController und Overwatch
- Status: implementiert
- Stand: Mit `FireteamSecurityController` gibt es jetzt einen separaten Fireteam-State fuer Sicherungssektoren im Haltzustand. `MissionTacticalSandboxController` aktualisiert diesen Zustand laufend aus aktivem Behavior-Profil, Bewegung, Suppression, Ad-hoc-Status und sichtbaren Gegnern. Fireteams waehlen nachvollziehbar zwischen `360` und `directional`, verteilen ihre fitten Members auf Sektoren und bauen bei ungesicherter Bedrohung leadership-abhaengig um. `OverwatchController` sitzt im `MissionCombatLoopDriver`, konsumiert die Security-Snapshots und enqueued vor der regulaeren Angriffsauswertung vorbereitete Reaktionsschuesse auf bewegte Feinde in beobachteten Sektoren. Die taktische Ansicht zeichnet Sicherungssektoren direkt im bestehenden `FireteamOrderVisualizer`; Statuspanel und Fireteam-Header zeigen `SEC 360`, `SEC DIR` bzw. `+OVW`.
- Offene Punkte: Noch keine tiefergehende Nutzung eines gemeinsamen Contact-Trackings oder persistenter Bedrohungsweitergabe zwischen Fireteams; das bleibt bei TASK_112. Flankenstrafen bleiben ebenfalls noch ausserhalb dieses Tasks.
- Risiken: Security und Overwatch bleiben bewusst schlanke Laufzeitschichten ueber bestehenden Combat-/LOS-Pfaden. Wenn spaetere Tasks feinere Waffen- oder Contact-Logik brauchen, sollten diese Daten zentral erweitert werden statt Overwatch zu einem zweiten Combat-System wachsen zu lassen.
- Naechster Schritt: TASK_112 kann jetzt das eigentliche Contact-Tracking und die Karten-Overlay-Intel-Schicht auf die bereits vorhandenen Security-/Overwatch-Zustaende aufsetzen.

### TASK_112 - ContactTracker und ContactMapOverlay
- Status: implementiert
- Stand: `scripts/tactical/contact_tracker.gd` fuehrt jetzt eine eigene missionslokale Kontaktlage pro Friendly-Fireteam mit `suspected`, `spotted`, `confirmed` und `lost`, inklusive letzter Position, Tick-Zeitstempel und leadership-skaliert verzogerter Weitergabe bestaetigter Kontakte. `MissionCombatLoopDriver` speist den Tracker aus bestehendem LOS und Detection-Delay, exponiert Kontakt-Snapshots und verwendet `spotted`/`confirmed` als Kontakt-Gate fuer Friendly-Feuerfreigabe; `spotted` erhaelt dabei den vorgesehenen Accuracy-Malus.
- Stand: `MissionTacticalSandboxController` reicht die Kontakt-Snapshots an `FireteamSecurityController` und ein neues `ContactMapOverlay` weiter. Das Overlay zeichnet `suspected`, `spotted`, `confirmed` und `lost` getrennt von Plan- und Security-Layern, bleibt rein lesend und aggregiert auf den aktuell ausgewaehlten Fireteam-Scope.
- Offene Punkte: Gegnerseitiges Contact-Tracking bleibt weiterhin ausserhalb dieses Scopes; der Tracker modelliert hier bewusst Friendly-Intel statt eine vollstaendige Wahrnehmungs-KI fuer beide Seiten.
- Risiken: Contact-Tracking, Security und Combat bleiben getrennte Schichten. Wenn spaetere Tasks tiefere Bedrohungslogik brauchen, sollte sie im Tracker oder Resolvern zentral erweitert werden statt erneut direkt in UI oder Overwatch auszuufern.
- Naechster Schritt: TASK_113 kann jetzt Flank-Penalties auf Basis der vorhandenen Security-Sektoren und der neuen Kontakt-/Bedrohungslage aufsetzen, ohne selbst noch Intel-Grundlagen nachbauen zu muessen.

### TASK_113 - FlankVulnerabilityResolver und Sektorstrafen
- Status: implementiert
- Stand: `scripts/tactical/flank_vulnerability_resolver.gd` fuehrt jetzt eine schmale Laufzeit-Auswertung ueber bestehende Security-Snapshots aus und erkennt Flanken ausschliesslich auf Basis von `security_mode`, `direction_angle` und `member_assignments`. Erfolgreiche Flankentreffer erzeugen einen klaren Modifier-Satz fuer Trefferchance, Schadensmultiplikator, Cover-Override und eine zeitlich begrenzte Absenkung des effektiven `suppression_threshold`, ohne selbst Security-, Contact- oder Damage-Wahrheit zu werden.
- Stand: Darauf sitzt jetzt ein kleiner Richtungs-/Morale-Folgepfad im selben Resolver: Flanken behalten die relative Angriffsrichtung (`left`, `right`, `rear`) als kurzes Richtungsgedaechtnis, und Fireteams koennen fuer wenige Sekunden `alerted` oder `shaken` bleiben. Ein Heckentreffer schaltet sofort auf `shaken`, wiederholte Seitenflanken koennen denselben Zustand nachziehen; der effektive Suppression-Schwellenwert sinkt in diesem Folgefenster weiter. `MissionCombatLoopDriver` gibt Richtung und Morale im bestehenden Flank-Payload sowie im Damage-Hit-Context weiter, `SimulationRoot` spiegelt diese Felder autoritativ durch den bestehenden Damage-Pfad, und `MissionTacticalSandboxController` zeigt Richtung, Restdauer und Morale-Kuerzel im Statusbereich.
- Offene Punkte: Gegnerseitige autonome Flankenreaktionen bleiben weiter ausserhalb dieses Scopes.
- Risiken: Flankenverwundbarkeit bleibt bewusst ein schmaler Resolver ueber vorhandene Security- und Combat-Daten. Wenn spaetere Tasks komplexere Richtungsdeckung oder groessere Morale-Ketten einfuehren, sollten sie diesen zentralen Modifier-Pfad erweitern statt zweite flank-spezifische Sonderlogik in UI, Overwatch oder DamageModel zu verteilen.
- Naechster Schritt: Die Reihe `109` bis `113` ist damit fachlich geschlossen; weitere Folgeschritte sollten nur aus neu definierten Tasks kommen statt diesen Batch still weiter auszubauen.

### TASK_115 - Gemeinsames Markersystem fuer Editor und Taktikkarte
- Status: implementiert
- Stand: `scripts/terrain/terrain_marker_catalog.gd` fuehrt jetzt einen kleinen gemeinsamen Marker-Typkatalog fuer Editor- und Mission-Marker mit Standardname, Farbe, Symbol, Kontext und Single-/Multi-Instance-Regel. `TerrainMapData` speichert Kartenmarker nicht mehr nur als nackte Positionen, sondern als Marker-Eintraege mit Typ, Name, Farbe, Symbol und Position; alte JSON-Dateien mit einfachem `x`/`y`-Markerformat bleiben rueckwaertskompatibel lesbar.
- Stand: Der Map-Editor besitzt jetzt eine echte Marker-Liste statt der alten festen Marker-Zeilen. Marker werden aus einer festen Typ-Liste angelegt, direkt auf der Karte platziert oder gezogen, per `DEL` geloescht, per Doppelklick umbenannt, auf Tile-Mitten eingerastet und auf demselben Feld nicht mehr gestapelt. Die festen Marker `spawn_alpha`, `spawn_bravo` und `objective_point` laufen ueber dieselbe Marker-Basis wie neue Editor-Typen wie `rally_point`, `danger_zone`, `loot_cache` und `recon_note`; die frueheren Flank-Anchors wurden spaeter entfernt.
- Stand: Die Taktikkarte konsumiert fuer Spielermarker denselben `mission_player`-Katalog. Das Wegpunkt-Kontextmenue wird daraus aufgebaut, neue oder verschobene Wegpunkte rasten auf Tile-Mitten ein, und `FireteamOrderVisualizer` nutzt dieselbe Symbolfamilie statt einer separaten Sondertabelle.
- Offene Punkte: Keine innerhalb des TASK-115-Slices; weitergehende Markerfamilien, echte Missionsmarker-Listen im Tactical-UI oder persistente Kampagnenmarker bleiben bewusst eigene Folgepfade.
- Risiken: Kartenmarker in `TerrainMapData` und spielerseitige Missionsmarker im Planning-State teilen jetzt Typkatalog und Symbolik, bleiben aber absichtlich getrennte Datenwahrheiten. Weitere Ausbaupfade sollten diesen Vertrag erweitern statt wieder separate Marker-Sonderlogik in Editor, Tactical-UI oder Meta-Map aufzubauen.
- Naechster Schritt: Nur bei Bedarf neue Folge-Tasks fuer zusaetzliche Marker-Typfamilien, tiefere Mission-Listenbearbeitung oder persistente Marker ueber Missionsgrenzen hinaus schneiden.

### TASK_116 - Runtime-Systeme aus scripts/tests herausloesen
- Status: implementiert
- Stand: Produktiv genutzte Tactical-/Runtime-Systeme liegen jetzt unter `scripts/tactical/` statt unter `scripts/tests`: `ad_hoc_order_controller.gd`, `contact_tracker.gd`, `fireteam_behavior_resolver.gd`, `fireteam_coordination_manager.gd`, `fireteam_movement_controller.gd`, `fireteam_security_controller.gd`, `flank_vulnerability_resolver.gd`, `overwatch_controller.gd` und `tactical_stance_controller.gd`.
- Stand: Rein lesende Visuals liegen unter `scripts/tactical/visuals/`: `contact_map_overlay.gd` und `fireteam_order_visualizer.gd`. `MissionTacticalSandboxController`, `MissionCombatLoopDriver` und die Verifier bleiben in `scripts/tests`, laden aber die produktiven Systeme aus den neuen Pfaden.
- Offene Punkte: Keine innerhalb dieses Pfad-Slices; die eigentliche Entflechtung von UI-/Driver-Gameplay-Wahrheit bleibt bewusst TASK_117 und TASK_118.
- Risiken: Der Task ist bewusst nur Move-/Import-Hygiene. Spaetere Runtime-Arbeiten sollten die neuen Produktivpfade verwenden und keine neuen produktiven Systeme unter `scripts/tests` anlegen.
- Naechster Schritt: TASK_117 kann Dropship-Deploys aus dem Tactical-Controller in autoritative `SimulationRoot`-Effects ueberfuehren.

### TASK_117 - Dropship-Deploy als SimulationRoot-Effects
- Status: implementiert
- Stand: `SimulationRoot` kennt jetzt die expliziten Effects `dropship_embark_unit` und `dropship_deploy_unit`. Bekannte, aber noch nicht in der `UnitRegistry` aktivierte Dropship-Passagiere koennen dadurch ueber `register_known_unit` positioniert, verborgen, sichtbar gemacht und beim Deboarding autoritativ in `UnitRegistry`, `RuntimeLeader` und `FTLRegistry` aktiviert werden.
- Stand: `MissionTacticalSandboxController` behaelt Dropship-Sequenz, UI-Texte, Marker und Preview-Visualisierung, enqueued in der Live-Mission aber nur noch Embark-/Deploy-/Presence-Effects. Direkte `global_position`-/`visible`-/Runtime-Status-Commits bleiben auf den non-authoritative Preview-Pfad begrenzt. Loadout-Modifier laufen nach dem Deploy weiter ueber den bestehenden Effect-Pfad.
- Offene Punkte: Die Dropship-Sequenz selbst ist weiterhin im Sandbox-Controller statt in einem eigenen produktiven Runtime-Modul gekapselt; ein tieferer Fahrzeug- oder Mission-Event-Controller bleibt bewusst ausserhalb dieses Tasks.
- Risiken: Der neue Effect-Vertrag ist V1-schmal und nimmt RuntimeLeader-/FTLRegistry-Pfade im Effect-Payload mit. Wenn spaeter echte Fahrzeug- oder Multiplayer-Flows entstehen, sollte dieser Vertrag zentral erweitert werden, statt wieder UI-nahe Sonderpfade fuer Deploy-Zustand einzufuehren.
- Naechster Schritt: TASK_118 kann Combat-Entscheidungen aus dem Mission-Driver herausloesen und damit den naechsten UI-/Testtreiber-Anteil aus der Gameplay-Wahrheit entfernen.

### TASK_118 - Combat-Entscheidungen aus MissionCombatLoopDriver herausloesen
- Status: implementiert
- Stand: `scripts/tactical/combat_fire_decision_resolver.gd` uebernimmt jetzt Zielwahl, Feuerfreigabe, Friendly-Contact-Gate und Damage-Effect-Payload-Aufbau. Der Resolver konsumiert vorhandene Callbacks fuer Detection, ContactTracker, Misidentification und FlankVulnerability, ohne selbst State zu committen.
- Stand: `scripts/tactical/medic_support_resolver.gd` uebernimmt Medic-Rollen-/Tool-Pruefung, Target-Priorisierung, Reichweitenentscheidung und Heal-/Move-Action-Auswahl. Der `MissionCombatLoopDriver` enqueued daraus weiter die autoritativen `heal`-Effects und Medic-Move-Commands.
- Offene Punkte: Enemy-Advance, Reposition-on-Damage, Bleedout-Queueing und Leadership-Nachfolge liegen weiterhin im Driver. Sie sind bewusst nicht in diesem ersten Struktur-Slice mitgezogen, damit Combat-Verhalten stabil bleibt.
- Risiken: Die Resolver arbeiten weiterhin mit Node-Referenzen und Driver-Callbacks, weil die bestehende Testmission noch keine vollstaendige produktive Combat-Context-Schicht besitzt. Spaetere Tasks sollten diese Context-Schnittstelle konsolidieren, statt neue Inline-Entscheidungen im Driver anzulegen.
- Naechster Schritt: TASK_119 kann auf dem ausgelagerten Fire-Decision-Payload aufsetzen und `roll_override`/RNG sauber deterministisch begrenzen.

### TASK_119 - Seeded Combat RNG und roll_override begrenzen
- Status: implementiert
- Stand: `SimulationRoot` besitzt jetzt einen kleinen seedbaren Combat-RNG (`combat_rng_seed`, `set_combat_rng_seed()`, `get_next_combat_roll()`) und zieht im autoritativen Damage-Pfad daraus den Trefferwurf, sobald ein Damage-Effect keinen expliziten `roll_override` mitbringt.
- Stand: Normale Fire-Decision-Payloads aus `CombatFireDecisionResolver` und Overwatch-Damage-Effects setzen keinen festen `roll_override` mehr. Der Override bleibt im Effect-Vertrag nur fuer gezielte Test-/Debug-Payloads erhalten, damit Verifier einzelne Treffer- oder Fehlschlagfaelle weiter exakt pruefen koennen.
- Offene Punkte: Kein Replay-/Rollback-Framework und keine Multiplayer-RNG-Synchronisierung jenseits des seedbaren autoritativen Pfads. Das bleibt bewusst ein spaeterer Netcode-/Server-Tick-Scope.
- Risiken: Der RNG sitzt jetzt an der richtigen autoritativen Stelle, aber die bestehende Testmission benutzt weiterhin Node-basierte Driver-/Resolver-Kontexte. Spaetere Multiplayer-Arbeit sollte den Seed-/Tick-Vertrag zentral erweitern, statt Zufallsquellen in Resolver oder UI zurueckzubringen.
- Naechster Schritt: TASK_120 kann Teamqualitaet/FTL-Ausfuehrungsfaktoren auf dem jetzt wieder probabilistischen Combat-Pfad modellieren, ohne feste Live-Rolls zu kaschieren.

### TASK_120 - Teamqualitaet als FTL-Ausfuehrungsfaktor
- Status: implementiert
- Stand: `FireteamBehaviorProfile` enthaelt jetzt einen kompakten Ausfuehrungsprofil-Satz (`order_fidelity`, `reaction_delay_seconds`, `execution_cohesion`, `execution_fire_discipline`, `contact_stability`, `initiative`, `execution_label`). `FireteamBehaviorResolver` leitet diese Werte aus vorhandenen Team-/Leaderdaten, Discipline, Recognition und Traits ab, ohne neue Persistenz oder Sozialdynamik einzufuehren.
- Stand: `FireteamMovementController` konsumiert das Ausfuehrungsprofil beim Start von Movement-/Order-Ausfuehrung. Niedrige Order Fidelity erzeugt einen kleinen deterministischen Ziel-Offset, niedrige Cohesion vergroessert Formationstreuung, und Initiative beeinflusst den Bewegungstempo-Multiplikator. Die Tactical UI zeigt diese Werte nur lesend als `EXEC`-Status mit Feedback wie `CLEAN EXEC`, `DELAY`, `SCATTER`, `LOW DISC` oder `STEADY`.
- Offene Punkte: Keine tiefere Teamchemie, keine Kampagnen-Persistenz und kein umfassendes Morale-/Social-System. Reaction Delay ist als Profilwert vorhanden, wird aber in diesem V1-Slice noch nicht als echte Startwartezeit getaktet.
- Risiken: Die Werte sind bewusst kleine Ausfuehrungsmodifikatoren. Spaetere Teamchemie sollte den vorhandenen Profilvertrag erweitern, statt UI- oder Driver-seitig neue Berechnungen einzufuehren.
- Naechster Schritt: Weitere Teamqualitaetswirkung nur als klarer Folge-Task, z.B. echte Tick-basierte Reaktionsverzoegerung oder breitere Contact-/Morale-Kopplung.

### TASK_121 - Area Order Marker
- Status: implementiert
- Stand: `AreaOrder` unter `scripts/command/area_order.gd` formalisiert den missionslokalen Datenvertrag fuer Gebietsmarker mit `area_order_id`, `fireteam_id`, `command_type`, Tile-/Polygon-Daten, `center_position`, `created_at_order_index` und `status`.
- Stand: `MissionTacticalSandboxController` haelt Area Orders getrennt von der Waypoint-Ausfuehrung im Planning-State-Feld `area_orders`. Spieler koennen per `SHIFT+Drag` einfache Rechteckgebiete aus Terrain-Tiles markieren; ohne TerrainRegistry wird ein Polygon-Fallback gespeichert. Das Kontextmenue klassifiziert Gebiete als `defend`, `engage`, `take` oder `flank`.
- Stand: `FireteamOrderVisualizer` zeichnet Area Orders als eigenen Layer getrennt von normalen Wegpunktlinien und stellt `get_visible_area_orders()` sowie Hit-Tests fuer das Area-Menue bereit. Bestehende Einzel-Wegpunkte bleiben unveraendert nutzbar.
- Offene Punkte: Keine echte Defend-/Attack-Semantik, keine Gegner-KI-Reaktion und keine Kampagnenpersistenz; diese Punkte bleiben bewusst Folge-Tasks 122+.
- Risiken: Die Area-Auswahl ist bewusst V1-schmal und rechteckbasiert. Spaetere Polygon-Editor-Funktionen sollten auf dem vorhandenen Datenvertrag aufsetzen, ohne Gameplay-Wahrheit in UI-Code zu verlagern.
- Naechster Schritt: TASK_122 kann Defend-Semantik auf Basis der gespeicherten Area Orders ergaenzen, ohne den Marker-/Planning-Roundtrip erneut zu bauen.

### TASK_122 - Defend Area Semantik
- Status: implementiert
- Stand: `scripts/tactical/area_order_resolver.gd` waehlt fuer `defend`-Area-Orders pro fittem Fireteam-Mitglied eine Halteposition. Der Resolver bevorzugt vorhandene Area-Tiles, meidet nicht-walkable Tiles ueber `TerrainRegistry`, nutzt Cover-Werte als Score und haelt den FTL in Zentrumsnaehe oder auf einer guten Coverposition.
- Stand: `MissionTacticalSandboxController` startet Defend-Area-Ausfuehrung per GO, enqueued Bewegungsbefehle ueber `SimulationRoot`, tracked den missionslokalen Area-Defense-State und schaltet nach Erreichen auf `WARTET AUF GO | HALTET GEBIET`. Ein weiterer GO kann die aktive Area-Defense wieder freigeben.
- Stand: `FireteamSecurityController` konsumiert optionalen Area-Kontext; Security-Snapshots enthalten jetzt `area_order_id`, `area_center_position` und `area_status` und nutzen das Gebiet als Anchor fuer Sektoren/Overwatch. #17 zeigt Defend-Area-Status und die Tactical-Statuszeile zaehlt offene Gebiete mit.
- Offene Punkte: Keine komplexe Gebaeuderaum-KI, keine Fortifikation und keine langfristige Munitions-/Morale-Simulation.
- Risiken: Der Pfad ist bewusst ein V1-Verteiler mit vorhandenen Terrain-/Cover-Daten. Spaetere Attack-/Take-Area-Semantik sollte den Resolver erweitern oder eigene Resolver nutzen, statt Area-Ausfuehrung in UI-Code zu verlagern.
- Naechster Schritt: TASK_123 kann `engage`/`take`-Area-Semantik auf dem vorhandenen Area-Order- und Resolver-Vertrag aufbauen.

### TASK_123 - Attack Area Semantik
- Status: implementiert
- Stand: `AreaOrderResolver` loest offensive `engage`-/`take`-/`flank`-Areas in Zielgebiet, Approach-Punkt und Fireteam-Approach-Formation auf. Der Approach entsteht auf der freundlichen Seite ausserhalb bzw. am Rand des Zielgebiets und kann ueber die vorhandene `TerrainRegistry` auf walkable Tiles geschnappt werden.
- Stand: `MissionTacticalSandboxController` startet Attack-Area-Ausfuehrung per GO, enqueued `engage_area`-UnitCommands ueber `SimulationRoot`, tracked den missionslokalen Attack-Area-State und schaltet nach Gebietssicherung auf `GESICHERT | WARTET AUF GO | HALTET GEBIET` mit Area-Security-Kontext.
- Stand: `MissionCombatLoopDriver` reicht den aktiven Attack-Area-Kontext an `CombatFireDecisionResolver` weiter. Der Resolver priorisiert Ziele innerhalb des markierten Zielgebiets, ohne die bestehende Damage-Formel oder den autoritativen Damage-Pfad zu veraendern.
- Offene Punkte: Keine Multi-Assault-Lanes, keine Smoke-/Breach-/Spezialausruestung und keine neue Gegner-KI in diesem Slice.
- Risiken: Attack Areas bleiben bewusst eine V1-Semantik ueber vorhandenen Movement-/Combat-/Security-Schichten. Spaetere Assault-Planung sollte den Resolver-Vertrag erweitern, statt ein zweites Combat- oder Bewegungssystem einzufuehren.
- Naechster Schritt: TASK_124 kann die Area-Zustaende in #17 lesbar zusammenfassen, ohne neue World-Debugtexte einzufuehren.

### TASK_124 - Area Feedback in #17 Selected Fireteam
- Status: implementiert
- Stand: #17 baut Area-Statuszeilen jetzt ueber eine gemeinsame Snapshot-Formatierung fuer geplante und aktive Defend-/Attack-/Take-/Flank-Areas. Die Anzeige enthaelt Area-Typ, Feldanzahl bzw. Take-Fortschritt, Ausfuehrungsmodus, Security-Kurzstatus, Contact-Status und GO-Wartezustand.
- Stand: Mehrfachauswahl bleibt kompakt, indem `_build_selected_waypoint_info_text()` weiter eine Zeile pro Fireteam ausgibt. Die Area-Zeilen ersetzen keine Gameplay-Wahrheit, sondern lesen nur vorhandene Area-, Security- und Contact-Snapshots.
- Stand: Das World-Overlay bleibt unveraendert reduziert; es wurden keine neuen langen NPC-Labels oder Debugzeilen ueber Figuren eingefuehrt.
- Offene Punkte: Keine neue Detailansicht, keine permanente Debug-Konsole und keine Charakterblattwerte in #17.
- Risiken: Statuszeilen koennen schnell zu dicht werden. Folgearbeiten sollten lieber kurze, spielnahe Worte ergaenzen statt rohe Debugfelder in #17 zu kippen.
- Naechster Schritt: TASK_125 kann Terrain-Blocker- und Walkability-Debugging pruefen, ohne #17 weiter auszubauen.

### TASK_125 - Terrain Blocker Debug und Walkability Tests
- Status: implementiert
- Stand: `TerrainRegistry.resolve_walkable_target()` loest Move-Zielpunkte jetzt mit Originalziel, Walkability, geblocktem Tile, stabilem Ersatz-Ziel und Blockergrund auf. `get_nearest_walkable_grid()` sortiert walkable Kandidaten deterministisch nach Distanz und Grid-Koordinaten, damit Ersatztiles bei Gleichstand nicht springen.
- Stand: `SimulationRoot` nutzt diese Zielauflosung vor dem Pfadbau. Nicht-walkable Ziele werden auf walkable Ersatzpunkte verschoben; bei nicht erreichbaren walkable Zielen gibt es keinen direkten Geradeaus-Fallback durch Blocker mehr, sondern einen stabilen erreichbaren walkable Fallback oder keinen Move-Pfad.
- Stand: Terrain-Move-Debugging ist abschaltbar in `SimulationRoot` verfuegbar und wird vom `MissionTacticalSandboxController` lesbar als Zeile mit Originalziel, Ersatz-Ziel, finalem Ziel und Grund exponiert. `task_125_verifier.gd` deckt Rock-Ziel, stabile Ersatzauflosung, Pfad um Blocker, unerreichbares Ziel ohne Tunneling und Debugtext ab.
- Offene Punkte: Kein neuer Navigation-Stack, keine Physics-Kollisionssimulation und keine Map-Editor-Ueberarbeitung. Diese Grenzen bleiben bewusst ausserhalb von TASK_125.
- Risiken: Der neue Fallback ist konservativ. Wenn ein Ziel nicht erreichbar ist, bleibt die Unit am naechsten stabil erreichbaren walkable Punkt statt optisch in Richtung Blocker weiterzudruecken.
- Naechster Schritt: Die Area-Order-Reihe 121-125 ist damit fachlich abgeschlossen; weitere Navigationsthemen sollten als eigener Task mit klarer Path-Follow- oder Nav-Stack-Zielsetzung geschnitten werden.

### TASK_126 - HPA Navigation Foundation
- Status: implementiert
- Stand: `scripts/terrain/hpa_navigation_graph.gd` baut aus der vorhandenen `TerrainRegistry` eine abgeleitete HPA-Grundlage mit deterministischen Clustern, walkable Tiles, lokalen Komponenten, Portalen und abstrakten Komponenten-Nachbarschaften.
- Stand: Portale nutzen dieselben Traversal-Regeln wie `TerrainPathfinder`, inklusive Diagonalbewegung ohne Corner-Cutting durch Blocker sowie Hoehen-/Slope-Regeln. `TerrainPathfinder` exposes dafuer eine kleine lesende API fuer Neighbor-Richtungen und Step-Pruefung.
- Stand: `scripts/tests/task_126_verifier.gd` deckt Graph-Aufbau, Cluster-Zuordnung, Blocker-Komponenten, walkable Portale, abstrakte Nachbarschaften und Diagonal-Corner-Regeln ab.
- Offene Punkte: HPA wird in diesem Task noch nicht fuer Live-Movement verwendet. Die Integration in `SimulationRoot` und lange Pfadqueries bleibt TASK_127.
- Risiken: Cluster-Groesse und Portal-Dichte sind V1-Parameter. Spaetere Performance-Arbeit sollte diese Werte ueber Messungen aus TASK_128 justieren.
- Naechster Schritt: TASK_127 kann den HPA-Graphen in einen hierarchischen Pathfinder ueberfuehren und optional im autoritativen Move-Pfad verwenden.

### TASK_127 - HPA Pathfinder Integration
- Status: implementiert
- Stand: `scripts/terrain/hpa_pathfinder.gd` setzt die HPA-Grundlage aus TASK_126 in konkrete Pfadqueries um. Same-Cluster-Wege laufen weiter direkt ueber `TerrainPathfinder`, Multi-Cluster-Wege werden ueber abstrakte Portalrouten gesucht und anschliessend aus lokalen Tile-Pfadsegmenten zusammengesetzt.
- Stand: `SimulationRoot` baut und cached den HPA-Graphen pro `TerrainRegistry` und nutzt den HPA-Pfadfinder im autoritativen Move-Pfad. Wenn Start und Ziel in unverbundenen HPA-Komponenten liegen, wird kein globaler Full-Map-Fallback gegen das unerreichbare Ziel gestartet; stattdessen wird ein stabiler walkable Fallback innerhalb der Start-Komponente gewaehlt.
- Stand: `HPANavigationGraph` exposed dafuer eine lesende `get_component_tiles()`-API. `scripts/tests/task_127_verifier.gd` deckt Same-Cluster-Pfade, Multi-Cluster-Portalpfade, disconnected early-fail, SimulationRoot-Ausfuehrung und unreachable-Fallback ab.
- Offene Punkte: Keine dynamischen Kartenupdates und keine Flow-Fields. Lokale Teilpfade nutzen weiterhin den bestehenden `TerrainPathfinder`, damit Walkability-, Hoehen- und Diagonalregeln identisch bleiben.
- Risiken: Der Graph-Cache invalidiert aktuell ueber Registry-Referenz und Tile-Anzahl, nicht ueber jede moegliche Walkability-Aenderung. Portalpfade koennen in V1 noch kantiger wirken als spaetere geglaettete Routen.
- Naechster Schritt: TASK_129 kann auf den Budget-/Debug-Messpunkten aufsetzen und deckungsbewusste Pfadkosten einfuehren.

### TASK_128 - Navigation Budgeting und Debug
- Status: implementiert
- Stand: `SimulationRoot` besitzt jetzt ein konfigurierbares Navigation-Budget fuer neue Pfadrequests pro Physics-Tick (`navigation_budget_enabled`, `navigation_max_new_path_queries_per_tick`). Wenn das Budget erschoepft ist, werden Move-Commands mit Delay-Grund deterministisch ueber die bestehende Prioritaets- und Queue-Reihenfolge in einen spaeteren Tick requeued.
- Stand: `get_navigation_debug_snapshot()` liefert lesende Metriken fuer neue Path-Requests, konkrete Pathfinder-Queries, Fallbacks, unreachable Queries, Delays, Pending Count, letzte Query-Records und die teuerste Query. Query-Records unterscheiden HPA, direkten A*, Fallback und Delay und enthalten grobe Kandidaten-/Expanded-Schaetzwerte.
- Stand: Contact-Recompute laeuft durch denselben Budgetpfad, sodass mehrere Units im Kontakt nicht mehr im selben Frame eine Pfadquery-Spitze erzeugen. `scripts/tests/task_128_verifier.gd` deckt Snapshot-Zaehler, Budget-Limit, deterministische Delay-Reihenfolge, Contact-Staffelung und unreachable-Debug ab.
- Offene Punkte: Keine Worker-Threads, keine UI-Pflichtanzeige und keine Multiplayer-Synchronisierung der Navigation-Metriken. Fallback-Kandidaten bleiben bewusst grob geschaetzt, bis TASK_129/130 echte Messdaten fuer neue Path-Schichten liefern.
- Risiken: Ein niedriges Budget kann sichtbare Startverzoegerungen bei grossen Sammelbefehlen erzeugen; der Snapshot macht diese Pending- und Delay-Gruende deshalb explizit sichtbar.
- Naechster Schritt: TASK_129 kann deckungsbewusste Pfadkosten aufsetzen, ohne CPU-Spitzen ungezaehlt zu lassen.

### TASK_129 - Deckungsbewusste Pfade mit HPA und Subgoal-Vorbereitung
- Status: implementiert
- Stand: `TerrainPathfinder` besitzt jetzt einen optionalen Cover-/Exposure-Kostenvertrag (`find_path_with_options`, `score_path`, `get_exposure_score`). Die Basisregeln fuer Walkability, Hoehen, Diagonalen und Corner-Cutting bleiben identisch; ohne Optionen laeuft der alte Pfad weiter.
- Stand: `HPAPathfinder` reicht Kostenoptionen in Same-Cluster- und lokale Portal-Segmente weiter. `HPANavigationGraph` annotiert Portale mit `mean_cover` und `min_cover`, damit spaetere Subgoal-/Portalentscheidungen bereits lesbare Cover-Metadaten besitzen.
- Stand: `SimulationRoot` kann Cover-aware Navigation ueber Export oder Command-Feld aktivieren, Hazard-Grids/-Positionen aus Commands ableiten und Risikogewichte nach `source_command_type` (`move`, `defend`, `take`/`engage`, `flank`, `rush`) setzen. Der Navigation-Debug-Snapshot enthaelt jetzt letzte Pfadmetriken wie `path_length_grid`, `exposure_sum`, `cover_sum`, Mittelwerte und `path_cost`.
- Offene Punkte: Keine echte Subgoal-Graph-Suche, keine dynamische Threat-Map aus dem Combat-Loop und keine UI-Pflichtanzeige. Threat-/Hazard-Positionen muessen in diesem Slice explizit ueber Command-Daten oder Tests kommen.
- Risiken: Hohe Exposure-/Cover-Gewichte koennen Umwege stark bevorzugen; deshalb bleiben Cover-aware Kosten standardmaessig deaktiviert und pro Command/Export steuerbar.
- Naechster Schritt: TASK_130 kann lokale Avoidance/ORCA-Light auf den resultierenden Wunschpfaden aufsetzen, ohne die globale Pfadkostenlogik zu ersetzen.

### TASK_130 - Lokale Unit-Avoidance mit ORCA/RVO-Light
- Status: implementiert
- Stand: `scripts/tactical/local_avoidance_resolver.gd` fuehrt eine kleine deterministische ORCA/RVO-Light-Schicht ein: registrierte Units werden pro Tick in einen Spatial-Grid gelegt, Nachbarn sortiert abgefragt und die lokale Wunschvelocity mit Separation-/Sidestep-Korrekturen geclippt.
- Stand: `SimulationRoot` integriert die Avoidance optional nach globalem Pfadbau und vor dem autoritativen Positions-Commit. Die Route bleibt HPA/A*, Avoidance veraendert nur die lokale Velocity zum naechsten Pathpoint. Nach jedem Move wird der Spatial-Grid aktualisiert, damit spaeter verarbeitete Commands aktuelle Positionen sehen.
- Stand: Terrain-Sicherheit prueft korrigierte Zielpositionen gegen `TerrainRegistry.is_walkable()`. Nicht-walkable Korrekturen werden verworfen oder bei komplett geblockter Bewegung auf `Vector2.ZERO` reduziert. `get_local_avoidance_debug_snapshot()` liefert Neighbor Count, Avoidance Velocity, Korrektur, Stuck-Zeit, Deadlock-Markierung, verworfene Korrekturen und Dauer.
- Offene Punkte: Kein vollstaendiger RVO2-/ORCA-LP-Solver, keine Formation-Slot-Swaps und keine tausende-Units-Optimierung. Die Schicht ist bewusst V1 und standardmaessig abschaltbar.
- Risiken: Zu starke lokale Korrekturen koennen Formationen optisch lockern; deshalb sind Radius, Nachbarschaft, Debug und Aktivierung explizit konfigurierbar.
- Naechster Schritt: Phase 17N ist damit lokal abgeschlossen; weitere Navigationserweiterungen sollten erst nach Spielgefuehl-/Performance-Review geschnitten werden.

### TASK_131 - Navigation Benchmark Harness
- Status: implementiert
- Stand: `scripts/tests/navigation_benchmark_harness.gd` fuehrt reproduzierbare Headless-Benchmarks fuer offene Pfadqueries, Korridor/Engpass-Queries, Cover-/Exposure-Routing, Navigation-Budget-Delays und lokale Avoidance-Ausfuehrung aus.
- Stand: `scripts/tests/task_131_verifier.gd` prueft, dass HPA/A*, Cover-aware HPA, Budgeting und Avoidance getrennt messbare Dictionary-Metriken liefern. Der Output enthaelt Query-Zeiten, Pfadlaengen, Exposure-/Cover-Summen, Delay-/Pending-Werte sowie Stuck-/Deadlock-Metriken.
- Offene Punkte: Keine produktive JPS-, D* Lite-, CBS- oder Reservierungslogik. Der Harness misst vorhandene Systeme und bleibt unter `scripts/tests`.
- Risiken: Benchmark-Szenarien sind kleine Laborkarten und ersetzen keine grossen Playtests in `mission_fireteam_dev_test.tscn`; sie schaffen aber eine stabile Basis fuer Folgeentscheidungen.
- Naechster Schritt: TASK_151 kann Engpass-Reservierung/MAPF-Light auf Basis der gemessenen Bottleneck- und Avoidance-Werte schneiden.

### Editor Cleanup - Flank Anchor Marker
- Status: implementiert
- Stand: Die veralteten festen Mapmarker `flank_anchor_left` und `flank_anchor_right` sind aus Marker-Katalog, Editor-Festmarkerzeilen, Standardmap und Missions-Setup-Fallback entfernt. Der eigentliche `flank`-Befehl, Flank-Areas und die Flank-Vulnerability-Logik bleiben unveraendert.
- Offene Punkte: Alte externe Karten, die diese Marker noch enthalten, laden sie nach dem Entfernen aus dem Katalog als Custom-Marker, falls sie nicht vorher bereinigt werden.
- Risiken: Keine Runtime-Abhaengigkeit wurde gefunden; die Anchors waren nur noch Editor-/Map-Altlasten.
- Naechster Schritt: Bei Bedarf alte Karten einmal im Editor neu speichern, damit die Custom-Altmarker aus den JSON-Dateien verschwinden.

### Editor Slot Limit
- Status: implementiert
- Stand: Der Map-Editor erlaubt fuer `mission_slot_count` jetzt bis zu 50 Slots pro Seite statt der bisherigen 8er-Obergrenze. Die gespeicherten Map-Daten bleiben unveraendert ein einfacher `mission_slot_count`-Wert.
- Offene Punkte: Die Meta-/FOB-UI zeigt die hoehere Kapazitaet an, erzeugt dadurch aber noch keine 50 sichtbaren Missions-Unit-Nodes.
- Risiken: Das ist zunaechst eine Editor-/Kapazitaetsfreigabe; groessere Live-Teams brauchen weiterhin passende Spawn-/Roster-/Performance-Folgearbeit.
- Naechster Schritt: Bei Bedarf separate Tasks fuer 50er-Spawnverteilung und Meta-Roster-Skalierung schneiden.

### TASK_132 - Kenney Isometric Asset Palette Expansion
- Status: implementiert
- Stand: Der Tile-Katalog enthaelt jetzt 44 kuratierte Kenney-Isometric-Asset-Tile-Typen in acht neuen Palette-Gruppen: `deko`, `technik`, `gebaeude`, `plattformen`, `pipes`, `rails`, `crater` und `fahrzeuge`. Die Auswahl nutzt vollstaendige Richtungssaetze fuer Faesser, Generatoren, Satellitenschuesseln, Gebaeude, Plattformen, Rohre, Schienen, Krater und Speeder. Diese neuen Gruppen laufen als Objekt-Layer ueber `object_type_id`: der Bodentile bleibt in `type_id` erhalten, der Renderer zeichnet danach das Objekt-Overlay in einem eigenen `ObjectContainer`, und alte bereits gemalte Objekt-`type_id`s rendern weiterhin mit Boden darunter. Die Defaults bleiben konservativ: kleine Deko blockt keine LOS, grosse Technik-/Gebaeude-/Fahrzeugobjekte sind nicht begehbar und koennen LOS/Cover liefern, flache Plattform-/Rail-/Crater-Tiles bleiben begehbar. Die Editor-Palette zeigt Kataloggruppen nun als nicht auswaehlbare Header, damit die neue Asset-Menge scanbar bleibt.
- Offene Punkte: Kein automatischer Vollimport; weitere Kenney-Familien sollten weiterhin kuratiert und mit sichtbarer Editor-Pruefung ergaenzt werden.
- Risiken: Grosse Sprites koennen visuell noch spezifische Anchor-/Offset-Nacharbeit brauchen; Gameplay-Werte sind bewusst defensive V1-Defaults und werden aktuell noch als aggregierte Tile-Felder gespeichert, nicht als getrennte Objekt-/Boden-Gameplaywerte.
- Naechster Schritt: Bei Bedarf eine zweite Palette-Erweiterung fuer Gates, Turrets, Monorail oder Desks schneiden, nachdem die aktuelle Auswahl im Editor visuell geprueft wurde.

### TASK_151-153 - Geplante Folge-Labs
- Status: geplant
- Stand: Aus den zuletzt bewerteten Vorschlaegen bleiben drei bewusst nachgelagerte Tasks offen: `TASK_151 - Engpass-Reservierung und MAPF-Light`, `TASK_152 - Seeded Cover Placement Lab` und `TASK_153 - 3D Transparency Material Presets`.
- Offene Punkte: Diese Tasks sind noch nicht implementiert und sollen erst nach Review der Navigation-/Movement-Spielgefuehlbasis gestartet werden.
- Risiken: CBS/MAPF, JPS/D* Lite, automatische Cover-Verteilung und Transparenz-Presets beruehren unterschiedliche Schichten; deshalb sind sie getrennt geplant und nicht als gemeinsamer Grossumbau gebuendelt.
- Naechster Schritt: Bei Bedarf `TASK_151` starten, wenn Engpaesse nach den Benchmark-Werten weiterhin der groesste Bewegungsschmerz sind.

### Mission Editor Authoring Audit
- Status: dokumentiert
- Stand: `docs/mission_editor_authoring_audit.md` haelt fest, dass der bestehende Map-Editor Terrain, Marker, Mission-Slots und Patrol-Pfade authoren kann, aber noch keinen eigenen taktischen Missionsszenario-Vertrag besitzt. Die LZ bleibt bewusst ausserhalb des Editor-Scopes und wird immer vom Spieler im Missionsflow gesetzt.
- Offene Punkte: Szenario-Presets, Szenario-Datenvertrag, Editor-MVP und Editor-to-Live-Validation sind noch nicht implementiert.
- Risiken: Wenn TerrainMapData, Editor-UI oder Szenario-Dateien zu viel laufenden Gameplay-State aufnehmen, entsteht eine zweite Gameplay-Wahrheit neben SimulationRoot/TacticalController.
- Naechster Schritt: `TASK_155 - Tactical Mission Test Presets` starten, bevor ein groesserer Mission-Editor gebaut wird.

### TASK_155-158 - Tactical Mission Authoring
- Status: geplant
- Stand: Vier Tasks sind geschnitten: `TASK_155 - Tactical Mission Test Presets`, `TASK_156 - Mission Scenario Data Contract`, `TASK_157 - Tactical Mission Editor MVP` und `TASK_158 - Editor-to-Live Mission Validation`.
- Offene Punkte: Noch keine Preset-Dateien, kein `MissionScenarioData`, keine Editor-UI fuer Missionsszenarien und kein Editor-to-Live-Verifier.
- Risiken: Der Authoring-Pfad muss Karten-/Szenario-Daten strikt von laufendem Tactical-State trennen. Insbesondere darf die LZ nicht im Editor oder Szenario gespeichert werden.
- Naechster Schritt: Erst `TASK_155` umsetzen, damit taktische Playtests reproduzierbare Fixtures haben, bevor der Editor-MVP erweitert wird.

### TASK_096 - Meta-Layer Recovery: Missionskarte, Dropship-LZ und Character-Sheet-Umbau
- Status: implementiert
- Stand: Der Meta-Layer fuehrt jetzt durchgaengig auf die echte eingebettete Missionskarte statt auf eine separate read-only Overview. Homebase, FOB und Mission teilen dieselbe kompakte Navigation, die Missions-Tactical-UI traegt direkt die gemeinsamen Block-Labels `#15` bis `#18`, und der Missionspfad bleibt auf dieselbe Kartenbasis, dieselben LZ-/Approach-Marker sowie denselben Dropship-Handoff verdrahtet wie die spaetere Live-Mission.
- Stand: Im FOB zeigen transitierende Operator-Karten ihren ETA-/Fortschrittszustand sichtbar ausgegraut mit Progress-Bar, Piloten zaehlen konsistent in die Missionsslot-Kapazitaet hinein, und der Character-Overlay rendert den deutschen TASK-096-Layoutblock ueber `CharacterSheetView` mit Kernwert-Balken. Die gemeinsame Dropship-Shipcard fuehrt im V1-Pfad nur noch die fachlich klaren Aktionen `Board` und `Send`; ein alter `tracked`-Button ist dort nicht mehr Teil des UI-Vertrags.
- Offene Punkte: Keine innerhalb des TASK-096-Scopes; spaetere Meta-Map-Folgearbeiten beschraenken sich jetzt auf optionale Politur wie Ruecktransfer-Varianten oder zusaetzliche Routenarten.
- Risiken: Die Meta-Ansichten bleiben bewusst Staging- und Read-Only-Schichten auf dem bestehenden Missions-/Transportzustand. Weitere Komfort- oder Kartenpolitur sollte darauf in kleinen Folge-Tasks aufsetzen, statt daraus eine zweite Missions- oder Fahrzeugwahrheit aufzubauen.
- Naechster Schritt: Nur bei Bedarf neue klar benannte Follow-up-Tasks fuer Meta-Map-Politur oder weitergehende Transfervisualisierung schneiden.
