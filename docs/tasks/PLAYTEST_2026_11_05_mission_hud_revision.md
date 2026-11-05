# A5-Missions-HUD: lesbare linke Auswahl und Transportkarte

## Ziel / Problem
Der aktuelle A5-Pfad besitzt weiterhin feste 52px-Aktionen, eine 272px-
Teamliste, 70px-Portraits und 128px-Bodenband. Teamparameter liegen mittig
unten. Diese historischen Grenzen sind durch die aktuelle Nutzeranweisung
überholt; auf 3440x1440 bleiben Identität und Auswahl zu klein.

## Zielvertrag vor Code
Originalquelle bleibt `docs/reports/assets/ui-2026-11-01/mockup_a5_mission_zweireihig.png`.
Die neue Nutzerkorrektur legt zusätzlich Teamparameter links unter die Karten.
Bei 720/1080/1440 Höhe liegen die quadratischen Aktionen ungefähr bei
52/64/72px, Kartenbreite bei 300/336/400px und Portraithöhe bei 80/88/96px.
Auswahl erhält eine kräftige gelbe Außenkontur plus ein Formsignal, Namen,
tatsächliche Belegung und einen kurzen bestätigten Status.

- Linker Stapel: echte vorhandene Fireteam-/Portraitcontrols; bei vielen
  Teams Scrollbereich. Darunter die bestehenden Haltung-/Feuer-/Details-
  Controls. Keine zweite Team- oder Rosterwahrheit, kein doppelter NPC-Streifen.
- Unten links zwei Aktionsreihen, daneben Ziel/Auftrag mit tatsächlichem
  Pending-/Reject-/Timeout-Feedback. Alle ursprünglichen Callbackpfade bleiben.
- Oben rechts größere korrekte Ref03-Vorschau, kurzer Transportstatus mit
  Form/Farbe, vorhandene nächste Aktion betont, Details und Mehrfachauswahl.
  Alle erweiterten Owneraktionen bleiben im existierenden Detailpopup.
- Protokoll rechts kompakt; vollständige Texte/Quellen bleiben in Details.
- FOB-Navigation wird nur bei tatsächlichem `homebase_direct` ausgeblendet;
  Node, Callback und Legacy-FOB-Pfad bleiben bestehen.
- Jede sichtbare Gruppe bleibt im Viewport, getrennt von anderen Gruppen,
  mit echten Controls und blockierter Welteingabe unter UI.

## Umfang und Nicht-Ziele
`mission_a5_hud_layout.gd`, `mission_a5_dropship_presenter.gd`, ausschließlich
`get_mission_hud_layout` im Layoutvertrag und abgegrenzte MiniCard-/Portrait-/
Nav-Präsentationsmethoden des TacticalControllers. Keine Simulation, Security-
Scopes, Transportconsumer, Orders, Ereignisfilter oder Actoränderungen.
Flight-/Base-Dateien bleiben eingefroren. Performance-Agent besitzt die
parallel benannten Security-/Transport-Hunks.

## Prüfung / Risiken
Neuer gezielter UI-Gruppenverifier zuerst auf altem Layout RED. Danach echte
Controlrechtecke, Originalcallbacks, Portraitidentitäten, Auswahl-/Details-
Pfad und unveränderte Ownerdaten bei 1280x720, 1920x1080 und 3440x1440.
Root führt alle Engine-/Vollbildläufe seriell aus. Alte geometrische Aussagen
`52px bei jeder Auflösung`, `Band <=128px`, `Teamparameter im Band` gelten
ausdrücklich nicht mehr; Interaktions- und Source-/Contextregressionen bleiben.
Container-Minima, spätere Lightrefreshes, geöffnete Popups und viele Teams
sind gezielte Risiken. Zahlenprüfungen ersetzen keine native Bildprüfung.

## Native Nachkorrektur: dynamische Detailquellen
Der echte Vollbildframe `native_visual_3440/20261105T075819Z-078ae826/
visual_captures/11_real_ground_contact.png` zeigt cyanfarbene Legacytexte über
der linken Teamauswahl. Bestätigter Writer ist
`_apply_combat_hud_detail_tooltip_label_contract`: dessen bedingungsloses
`visible = true` hebt die A5-Ausblendung beim schweren UI-Refresh wieder auf.
A5 markiert seine weiterhin vollständig aktualisierten Detailquellen explizit;
der Tooltipwriter respektiert diese Präsentationsrolle. Quelle, Tooltip und
Detailpopup bleiben vollständig. Regression ruft den tatsächlichen Writer und
danach `_update_ui` auf; Legacylabels bleiben verborgen, Details enthalten die
weiter aktualisierte Quelle. Keine Änderung an Combat- oder Commandzustand.
Root-RED vor Produktfix: **228 PASS / 3 FAIL**, ausschließlich die drei
direkten Tooltipwriter-Sichtbarkeitsfälle. Der folgende vollständige Owner-
Refresh verbirgt den Text zwar wieder; gerade dieser Zwischenzustand erklärt
das zeitweise Auftauchen im nativen Frame. Beleg:
`output/playtest_20261105/hud_dynamic_labels_red/20261105T081340Z-8b8eb4fc`.
Die Ausblendungsrolle wird nun am A5-Sink markiert und vom Tooltipwriter direkt
beibehalten. Root-GREEN: **231/231**, keine Fehlassertionen im Log
`output/playtest_20261105/hud_dynamic_labels_green/20261105T081847Z-121ee5f6/playtest_20261105_mission_hud_groups_verifier.log`.
Erneute native Bildprüfung erfolgt separat durch Root.

## Dokumente / Dateien
AGENTS, PROJECT_BRIEF, ARCHITECTURE, CODEX_RULES, IMPLEMENTATION_STATUS,
`PLAYTEST_2026_11_05_fullscreen_ux_visuals.md`,
`graphics_reference_revision_contract.md`, `ui_native_design_contract.md`,
`homebase_direct_dropship_flow_contract.md` sowie bestehende A5-Owner-/Detailgates.
Neuer Verifier: `scripts/tests/playtest_20261105_mission_hud_groups_verifier.gd`.

## Belegter Stand
Die Original-A5-Datei wurde angesehen und aktuell gehasht:
`fc9edb8b1d28921653ba5b438e7be8da4db3e0b32b8c751e9b18c4ef94918149`.
Root-RED: **177 PASS / 45 FAIL** im tatsächlichen Log
`output/playtest_20261105/registry_security_hud_red/20261105T072325Z-58ac2f54/hud_red.log`.
Root-GREEN: **222/222**, Exit 0 und keine Enginefehler,
`output/playtest_20261105/hud_green/20261105T073652Z-095d7025/playtest_20261105_mission_hud_groups_verifier.log`.
Native `06_go_movement.png` aus
`output/playtest_20261105/native_homebase_performance/20261105T073815Z-49ce2971/native_homebase_captures/`
wurde tatsächlich geöffnet: linke Auswahl/Parameter, Goldkontur, große aktive
Atlasportraits und Ref03-Transport sind sichtbar. Die Fernansicht wirkt ruhiger.
Ein optischer Folgepunkt bleibt der starke COVER-Beschnitt bei nur drei
Mitgliedern; Änderungen daran erfolgen ausschließlich nach Root-Nativefreigabe.

## Multiplayer-Lifecycle-Folgekorrektur
Root reproduzierte bei weiterhin **36/36** funktionalen Lobby-/Consentchecks
vier Enginefehler `Must be ancestor`: Der deferred Scrollaufruf hielt während
der Missionsaktivierung noch einen früheren Card-/Scrollowner.
Der Controllerhelper löst den aktuellen Widgetowner erst bei Ausführung auf,
prüft lebende Nodes, Tree-Zugehörigkeit, aktuelle Auswahl und tatsächliche
Ancestorbeziehung; für ersetzte Karten verwendet er dieselbe Fireteam-ID im
aktuellen VBox. Erst danach scrollt er die aktuelle Auswahl sichtbar.
Neuer Verifier `playtest_20261105_multiplayer_hud_lifecycle_verifier.gd` erbt
den vollständigen bisherigen ENet-/Consentverifier und ergänzt Host-/Client-
Widget-Reparent/Restore. Es werden keine Actor-, Peer- oder Transportwerte gepatcht.
Root-GREEN des neuen Gates: **44/44**, keine Enginefehler,
`output/playtest_20261105/multiplayer_followup_green/20261105T075241Z-2b0ba269/hud_multiplayer_lifecycle.log`.
Die ursprünglichen 36 Assertions bleiben vollständig erhalten. Die acht
Zusatzassertions trafen in den beiden kleinen Multiplayerkarten leere HUDs;
der im Verifier enthaltene positive Reparent-/Restorezweig wurde dort nicht
ausgeführt. Das Verschwinden der vier Startfehler ist belegt, zusätzliche
positive Widget-Lifecycleabdeckung bleibt als gezielter Folgecheck offen.
Der anschließend ergänzte echte Widgetzweig instanziiert die bestehende
`mission_reactivity_test.tscn`, wählt ihr reales Fireteam und verschiebt nur
die originale UI-Karte kurz zwischen Controlownern. Reparent-Reject,
deferred Ausführung, Restore/Scroll und Wiederauflösung einer abgelaufenen
Widgetreferenz auf dieselbe aktuelle Fireteamkarte sind nun tatsächlich
ausgeführt: **51/51**, keine Fehlassertionen im Log
`output/playtest_20261105/hud_lifecycle_live_branch/20261105T081223Z-66413e4a/playtest_20261105_multiplayer_hud_lifecycle_verifier.log`.

## Nativer Capturepfad
`playtest_20261105_fullscreen_visual_capture.gd` erbt den exakten isolierten
Normalstartpfad. Er ergänzt echte zeitliche Flugzustände und optional drei
GPU-Readbacks nach einem neuen sichtbaren echten Schussereignis. Angeforderte
0/120/900ms und tatsächliche Delays werden getrennt gespeichert; PNG-Encoding
folgt erst allen drei Readbacks. Ohne echtes Ereignis bleibt `observed:false`.
Kameraänderungen sind lesende Ansichten; Actorpositionen, HP, Zeit und Phasen
bleiben beim vorhandenen Owner. Physische Vollbildgröße, logischer Viewport,
Renderer und 1x werden getrennt erfasst. Headless wird als Bildbeleg abgewiesen.
