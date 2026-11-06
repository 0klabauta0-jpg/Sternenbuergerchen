# R3: unabhaengiges Quellreview des ersten Performance-Slices

Stand: 06.11.2026. Branch `task/reference-polish-r3-20261106`, HEAD und
Mainbasis `173a1e3c33b733a78a396a93db9cedf631d84998`.

## Urteil und Grenze

**APPROVED scoped** fuer die drei zum Review eingefrorenen Produktdeltas.
Keine belegte P1-/P2-Korrektheitsregression in diesen Deltas gefunden.
Die unten benannten P2-Arbeiten sind verbleibende Hotpath-Schuld des
Bestands, keine Voraussetzung, um diese drei Korrekturen zu uebernehmen.

Geprueft wurden der komplette Diff, `TacticalUITheme` vollstaendig sowie die
betroffenen Controller-/MissionSetup-Pfade, ihre nativen Owner, unmittelbar
benoetigte Verbraucher und die drei neuen Komponentenverifier. Das ist kein
Vollreview des gesamten historischen Controllers. Die spaetere Kamera-,
Welt-, Homebase- und Missions-UI-Revision ist hier nicht freigegeben.

Der Reviewer startete keine Engine, keinen Import und keinen Benchmark und
aenderte weder Produktdateien noch Git, Saves, Roster oder alte QA. Root
besitzt die seriellen Laeufe. Die gemeldeten 52/52 Theme-, 21/21 Fog- und
90/90 Labelchecks sowie gleiche Theme-Endwerte zwischen RED und GREEN sind
Root-Nachweise; diese wurden nicht als eigene Ausfuehrung ausgegeben.
Die native Gegenmessung und die finale Mainpruefung bleiben eigene Gates.

## Quellbindung

SHA-256 der fuer dieses Urteil gelesenen Arbeitsbaumdateien:

| Datei | SHA-256 |
| --- | --- |
| `scripts/ui/tactical_ui_theme.gd` | `87df9617a029fb292f4aa808b10422c3be082b22714112111960a603fc533729` |
| `scripts/tests/mission_test_setup.gd` | `16409c3108dbc87358a6013a3e54a9350e41cc307be59699fa5391d7a6970d84` |
| `scripts/tests/mission_tactical_sandbox_controller.gd` | `bdecc250219229874f79880e53d3c2bb211833fc46df57596798e989df35ed04` |

Die Zeilen unten gelten fuer diesen Stand. Spaetere Root-Hunks invalidieren
nicht automatisch das Urteil fuer unveraenderte Funktionen, brauchen aber
ihre eigene Quellbindung und Nachpruefung.

## Korrektheit der drei Deltas

### Theme: gleiche Endwerte und reale Override-Reparatur

`tactical_ui_theme.gd:298-320` prueft sowohl die lokale Override-Praesenz
als auch den tatsaechlichen Wert. Dadurch wird ein expliziter eigener
Override weiterhin installiert, wenn ein geerbter Wert bereits gleich ist.
Ein ersetztes fremdes StyleBox-/Font-/Color-/Size-/Constant-Override wird
beim naechsten Aufruf repariert. Ein bloss erinnerter Signaturwert wuerde
diesen Fall uebersehen; ein solcher Cache wurde nicht eingefuehrt.

Die Actiontile-Endwerte bleiben erhalten: normal/hover/pressed/
hover_pressed/disabled hatten nach dem alten zweiten Pass jeweils 4px
Contentmargin und Font11. `_style_command_button` liefert diese Werte nun
direkt (`188-193`, `251-285`). Focus behaelt wie vorher den unabhaengigen
Style mit Standardmargin. `hover_pressed` verweist auf den finalen
pressed-Style. Popup-Theme und Selection bleiben vorhanden. Farben,
Statuswechsel, Schatten und Callback-/Gameplayfelder sind unberuehrt.

Grenze: Ein Consumer, der eine gemeinsame gecachte StyleBox in-place
mutiert, verletzt bereits den bestehenden Resource-Reuse-Vertrag. Die
neuen Identityguards sind keine Reparatur fuer eine so global veraenderte
Sollressource. Eine neue Regression dieses Diffs ist daraus nicht belegt.

### Fog: ein normaler Process-Slice, Force weiterhin unmittelbar

`mission_test_setup.gd:300-319` verarbeitet vor dem 100ms-Sync genau einen
Service-Slice. Der anschliessende Sync darf einen neuen Job anfordern,
verarbeitet ihn mit `advance_work=false` aber erst im Folgeframe.
Die Jobanforderung bleibt erhalten; es gibt keinen Hunger, solange der
normale Process weiter laeuft (`1143-1168`).

Bei statischer Invalidation verzweigt `_advance...` vor dem Service nach
`_sync...(false)` und kehrt zurueck (`1148-1151`). Der Ersatzjob bekommt
ueber den unveraenderten Default einen Slice; der aeussere Process-Sync
verbraucht danach keinen zweiten. Explizites Force und Initialisierung
behalten `advance_work=true` als Default (`1044`, `1076`, `1079`, `1139`).
Der Deferred-Retry transportiert beide Argumente (`1084`), sodass ein
normaler verzogerter Sync nicht versehentlich wieder direkt servisiert.
DynamicTarget-LOS wird weiterhin vor den Pending-/Unchanged-Returns
aktualisiert (`1101`); Terrainpublikation bleibt atomar, Budget unveraendert.

Die bestehende Deferred-Wiederholung bei dauerhaft fehlender View wurde
nicht neu eingefuehrt und ist nicht durch diesen Slice geloest. Ebenso
beweist der synthetische 350ms-Check keine reale maximale Sichtlatenz bei
langsamen Frames. Das ist ein Laufzeitbeobachtungspunkt, kein neuer Befund.

### A5-Labels/Icons: finaler Besitzer mit echtem Legacy-Fallback

Die neun Primary-Labels werden nur nach abgeschlossenem A5-Setup und bei
bekanntem Eintrag in `LABELS` vom Legacy-Textreset ausgenommen
(`mission_tactical_sandbox_controller.gd:15914`, `15932-15933`). Native
`_present_primary_action` ist ihr finaler Besitzer
(`mission_a5_hud_layout.gd:281-312`). Tooltip, Disabled, Toggle, Metadaten,
Kontexttools und Callbacks bleiben im bestehenden Pfad.

Der Iconguard `15968-15977` ueberspringt ausschliesslich die vier nativ
besessenen Icons und die nativen ROE-Presenter. **Target hat keinen
`ICON_IDS`-Eintrag** und erhaelt auch bei frischem leerem Legacy-Iconcache
weiter sein echtes `COMMAND_TARGET_ICON` ueber `15980-15990`. Nur seine
finale Font-/Expansiondarstellung bleibt A5. Das verhindert einen leeren
Target-Button beim Erststart. Legacy ohne A5 behaelt BW/ST und Fontregeln.

## Verbleibende P2-Arbeiten nach Prioritaet

### P2-A: doppelte Mini-Card-Styleowner sind der engste naechste Schnitt

**Beobachtung im aktuellen Quellcode:** `_refresh_fireteam_mini_cards`
ruft bei `5009-5013` erst Status/Legacydetails, dann den 1280-Stil und
schliesslich A5-final auf. Bewegungsdaten sind Teil der Runtime-Signatur
(`5276`), sodass aktive Bewegung diese Arbeit regelmaessig erneut anlaesst.

`5727-5762` setzt Groesse, Titlefont/-farbe, Labelgroessen und Panelstyle.
`5045-5069` setzt unmittelbar danach A5-Groesse, Titlefont/-farbe und
Panelstyle erneut; `5098-5099` setzt den finalen StageLabel-Stil.
Diese direkten `add_theme_*_override`-Aufrufe umgehen die neuen idempotenten
Themehelper. Die Hoehe wird zudem erst auf alte Mindestwerte gehoben und
danach fuer A5 wieder gesenkt; das kann Sort-/Minimumsizearbeit ausloesen.

**Enger Vorschlag:** Den bereits bestaetigten A5-Besitz an dieser Stelle
auswerten und die sichtbaren A5-Controls unmittelbar durch ihren finalen
Owner stylen. Legacypfad weiterhin explizit erhalten. Direkte finale
Overrides erhalten reale Value-/Overrideguards statt einer neuen
gespeicherten State-Signatur. Statussnapshot, Tooltip, Portraits,
Charaktercallbacks, Auswahl und sofortige Aktualisierung bleiben gleich.

**Zweiter, separat abzusichernder Anteil:** `5691-5700` aktualisiert mehrere
Detailkinder, die `5057-5062` danach versteckt. Beispiele sind die vorher
sichtbar gesetzte Suppressionbar (`5830`) und der Readinessfooter (`6105`).
Die MemberStatusRow liest sogar Snapshot, Signature und defensiven
Rowsnapshot, um am Ende immer verborgen zu bleiben (`5988-6000`). Diese
reinen Controls koennen fuer effektiv verstecktes A5 enger behandelt
werden; ihre vorhandenen Tooltip-/Snapshotdaten und expliziten Diagnose-
oder Revealpfade muessen dabei frisch bleiben. Nicht mit dem ersten
Stylehunk unbemerkt mitentfernen.

**Noetiger Beweis:** Wiederholte gleiche A5-Karten und echte Runtimewechsel
mit identischen finalen Rects/Styles/Texten/Portraitidentitaeten, keinen
Zwischen-Theme-Notifications und erhaltenen Callback-/Simulationqueues;
Auswahlwechsel, Health/Vital, Contact, Boarding/Transit, Reveal und Details
einschliessen. Native Gegenmessung unter derselben Route bleibt erforderlich.

### P2-B: Strategictext zuerst lokal entdoppeln, keine Hidden-Pauschale

Root meldet fuer den versteckten Strategictext weiterhin etwa12-15ms.
Das ist hier uebernommene Laufzeitbeobachtung, kein vom Reviewer neu
gemessener Einzelursachenbeweis. Der Quellcode zeigt konkrete Wiederholungen:

- `9114` baut `interaction_density`. `9152` ruft den Station-Handoff ohne
  Override auf; `9384-9386` baut dieselbe Density erneut. Fuer diesen
  synchronen Pass den vorhandenen vierten Override des Handoffhelpers mit
  der bereits berechneten Density befuellen. Die Route-/Cuequellen koennen
  ebenfalls ueber vorhandene Overrideargumente vorwaerts gereicht werden.
- `9118`, `9126` und `9148` lesen NextInteraction/Handoff mehrfach indirekt:
  OneScreen ruft bei `25977-25978` beide auf; Handoff ruft bei `25878`
  NextInteraction erneut auf. Rein lokale explizite Inputs koennen diese
  Wiederholung vermeiden, ohne einen Wert ueber einen HUD-Pass zu halten.
- `9142`/`9161` und `9145`/`9164` fordern LoopTwo/Polish innerhalb desselben
  Builders nochmals an. Wiederverwendung muss die bestehenden Rekursions-
  fallbacks pruefen; nicht pauschal den gesamten Builder cachen.
- Die Labelcontracts bei `11333`, `11349` und `11366` lesen OneScreen,
  Preview und Decision nochmal. Bereits erzeugte Payloads als optionale
  explizite Inputs ergaenzen; Aufrufer ohne Payload behalten den bisherigen
  Diagnosepfad. Der bestehende ReadModelpass bleibt begrenzt und unveraendert.

Ein einfaches `if hidden: return` vor `4217` ist **nicht freigegeben**:
der RAW-Text geht bei `4264`/`11073` in die Live-Legacy-Matrix und bei
`11091-11106` in ihre bestehenden Contracts. Die A5-Details lesen Quelle,
Fulltext und Tooltip bei `mission_a5_hud_layout.gd:803-819`. Der aktuelle
Detailoeffner erzwingt nur bei pending Command ein Update (`15788-15795`);
nach einem Hidden-Skip waeren dort sonst veraltete Werte sichtbar.
Ein spaeteres Demandmodell braucht also eine explizite Frischebarriere am
Reveal plus eine weiter aktuelle Matrixquelle. Das waere ein eigener Slice.

### P2-C: verbliebener Target-Zwischentext, kleiner separater Hunk

Trotz des korrigierten Legacy-Labelpasses schreibt `_update_ui` noch bei
`4289-4291` direkt ST/ZL auf den nativen Target-Button. Der finale A5-Pass
setzt wieder Ziel (`mission_a5_hud_layout.gd:299-300`). Das ist kein falsches
Endbild, aber dieselbe vermeidbare Zwischenmutation. Den existierenden
Ownerhelper auch hier verwenden und per vollem `_update_ui`-Pfad pruefen.
Der neue Labelverifier prueft primaer den begrenzten Legacy-/Native-
Uebergang; er ist kein Beweis, dass jeder historische Writer entfernt ist.

### Ad-hoc-Pfad: kein wiederholter Baumaufbau belegt

`_ensure_ad_hoc_panel` kehrt bei vorhandenem Panel sofort zurueck
(`4424-4426`). `_refresh_ad_hoc_panel_visibility` aendert danach nur
Sichtbarkeit aus den vorhandenen Owner-/Plan-/Suppressiondaten
(`4763-4785`). Hier ist im gelesenen Pfad kein periodischer Panel-Neubau
belegt. Eine Optimierung nur auf Basis des Namens `ensure` waere nicht
begruendet. Feingranulare Laufzeitmessung kann den Contextgetter getrennt
bewerten; sofortiges Interrupt-/Return-to-plan-Feedback muss bestehen bleiben.

## Architektur, Testbarkeit und positive Beobachtungen

- Keine neue Gameplay-/Mission-/Unit-/Transportwahrheit, keine Commands
  oder Effects im geprueften Diff, keine SceneTree-Vollscans eingefuehrt.
- Ressourcenwiederverwendung und bestehende Owner werden genutzt; die
  Korrekturen sind klein und klar an den beobachteten Ursachen geschnitten.
- Die drei neuen Verifier beobachten reale Theme-Notifications, echte
  Fogservice-Slices mit Fullscanorakel und den Zwischenzustand vor dem
  nativen finalen Presenter. Sie spiegeln nicht bloss Settercode.
- Fixture-/Headlesspruefung, Root-Nativmessung, optische Nutzerabnahme und
  Mainintegration bleiben getrennte Aussagen.
- Keine Projekt-Spezialistkonfiguration `.ai-game-studio/project.json`
  vorhanden. Keine konkrete ADR im Task oder Diff referenziert; Architektur
  gegen `ARCHITECTURE.md` und die aktuellen Owner-/HUD-Contracts geprueft.
  Kein zusätzlicher Agent/Runner wurde im laufenden Serialfenster gestartet.

Keine Pflichtkorrektur fuer den freigegebenen Drei-Dateien-Slice. Nach
weiteren Produktaenderungen sind betroffene Abschnitte gezielt neu zu
pruefen und die Quellpins fuer das Schlussurteil zu erneuern.
