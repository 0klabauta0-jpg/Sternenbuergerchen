# R4: menschliche Gegner und echtes Schussfeedback

Untertask zu `RUNTIME_HITCHES_R4_2026_11_07.md`, Basis Main
`3b12b2878b42d1be0a7a2e8e925cf13835ff1d78`.

## Problem und aktueller Befund
Der Nutzer sieht pillenfoermige Gegner statt der vorhandenen Figuren.
Der aktuelle `TerrainMap3DView._create_unit_proxy` instanziert zwar das
korrekte Animated-Character-Modell, fuegt erfolgreichen feindlichen Modellen
aber zusaetzlich `UnitBodyReadabilityCore` hinzu. Der Core ist eine fast
deckende, unbeleuchtete CapsuleMesh (Alpha0.90, Radius0.1656,
Hoehe0.61425, MittelpunktY0.47). Er kann die menschliche Silhouette verdecken.
Dies ist ein bestaetigter Quellbefund, noch kein neuer nativer R4-Bildnachweis.

Fehlendes Muendungsfeuer und nahe ausblendende Gegner werden weiter entlang
des echten Event-/FoW-/LOS-Pfads untersucht. Es werden keine groesseren
Effekte oder Sichtweiten auf Verdacht eingebaut. Ein fehlendes Fire-Event
darf kein erfundenes Schiessen erzeugen.

## Umfang / Nicht-Ziele
Zuerst nur der eng bestaetigte Hostile-Body-Befund: Ein vorhandenes sichtbares
Menschenmodell wird nicht durch einen deckenden Pillencore ueberlagert.
Bestehender Team-Bodenring, Modelmaterial, Skeleton, Animation und Waffen-
Attachments bleiben die Anzeigen fuer Identitaet und Team. Der explizite
Missing-Asset-/Fallbackpfad bleibt separat erhalten. Keine neue Modellserie,
keine Gameplay-, Damage-, Facing-, Visibility- oder Balancingaenderung.

Enemy-Hin-und-her-Laufen und direkte Angriffsentscheidung gehoeren gemaess
Nutzerhinweis in eine eigene KI-Runde. Diese R4 aendert deren Regeln nicht
still. Folgeauftrag-Akzeptanz: normale Gegner aus ihren authored Gruppen
muessen beim Wechsel von Patrol/Contact/Attack durch echte Runtime-Commands
nachvollziehbare Ziele behalten; anhaltende Alternation identischer Wege
ohne neuen Kontaktgrund wird getrennt reproduziert. Angriff, Bewegung und
Sichtverlust sind mit Commandquelle, Tick und Ziel belegt. Kein erfundenes
Schussfeedback ersetzt eine ausbleibende Angriffsentscheidung.

## Schussfeedback: Architekturhinweis und Abgrenzung
`_rebuild_order_visuals` loescht derzeit den gemeinsamen `_order_root`
einschliesslich noch lebender `WeaponFireReadablePulse`-Nodes. Aus der
Eventliste werden global nur die letzten drei Events fuer Visuals gewaehlt;
der autoritative Driver haelt dagegen bis zu acht. Das sind konkrete
Lifecycle-/Auswahlkopplungen, aber noch kein nativer Ursachennachweis fuer
den gemeldeten fehlenden Flash. Das Metadatum `muzzle_flash_visible=true`
ist zudem keine gemessene Pixelsichtbarkeit. Der eigene Pulse-Status,
echte Event-ID, Source-FoW und native Bilder muessen gemeinsam belegt sein.

Ein gezielter Folgeschritt darf nur aus vorhandenen echten Fire-Events
leichtes, begrenztes Quellenfeedback erzeugen und darf dessen kurze
Lebenszeit nicht mit einem unrelated Order-Rebuild abbrechen. Eine
strukturelle Eventfixture ist dabei nur ein Renderer-/Lifecycle-Test.
Vier gleichzeitig sichtbare Quellen duerfen nicht durch das globale
Dreierbudget fuer aufwendige Feuerlinien ihr leichtes Muzzlefeedback
verlieren. Der vorbereitete Renderer-Verifier
`runtime_hitches_r4_20261107_muzzle_lifetime_verifier.gd` prueft diese
Quellenabdeckung, Lifecycle, Ablauf/Dedupe und den fortbestehenden
Source-FoW-Schutz; Marker `R4_MUZZLE_LIFETIME_PASS`. Root meldete echten
RED10/3, errors0, stabile Quellen: fehlende vierte Quelle, ersetzte Pulse
beim Preview-Rebuild und vorzeitiger Abbruch beim Snapshot-Rolloff.
Native Akzeptanz braucht einen neuen autoritativen Schuss im regulaeren
Missionsstart bei normalem Spielabstand, mit aufeinanderfolgenden Bildern
und explizitem Fehlbefund, falls im Beobachtungsfenster kein Event auftritt.
Keine HP-, Actor-, Positions-, Fire-Authority- oder Sichtweitenmutation fuer
diesen Nachweis; versteckte Quellen bleiben geschuetzt.

Der akzeptierte enge Entwurf trennt einen persistenten
`WeaponFireFeedbackRoot3D` vom bisherigen OrderRoot. Bis zu acht vorhandene
Events werden bereits am Payload-Eingang vor dem Debugsignatur-Earlyreturn
gelesen; schwere Feuerlinien und Labels behalten ihr Dreierbudget. Kurze
Pulse bleiben pro ID dedupliziert und auf maximal einen aktiven Pulse pro
Quelle sowie acht Quellen begrenzt. Unbekannte Quellen werden auch in der
begrenzten Empfangshistorie gestempelt; spaeterer Sichtgewinn darf alte
Events nicht frisch abfeuern. Aktives Quellenfeedback wird bei Sichtverlust
sofort verborgen. Der reine Map-/Missionkontext begrenzt die Historie und
darf einen Order-Rebuild nicht zum erneuten Eventeingang machen.

Die neue optionale native Probe
`runtime_hitches_r4_20261107_actual_fire_capture.gd` erbt die unveraenderte
normale R4-Messung. Erst NACH ihrem kompletten Messfenster sendet sie einen
weiteren regulaeren Move/GO nach live walkable bestaetigtem authored Hex
(5,15). Das aktuelle gespeicherte Hex ist frei; Enemy-Defense liegt an
diesem Bereich. Sie protokolliert nur neue autoritative Events nach diesem
GO, Pure-Pulse-Snapshots und FoW-Transitions und nimmt bei einem echten
Flash native Vollbildframes0/120/900ms auf. Kein Event/Flash innerhalb des
begrenzten Fensters ist ein expliziter FAIL, kein synthetischer Ersatz.
`--r4-fire-camera 22` bzw34 aendert die Kamera erst nach der Vergleichsmessung.
Status dieser neuen Probe: Text vorbereitet, noch nicht enginegeprueft.

Root hat den engen Produktpatch nach dem ersten nativen Perf-only-Lauf
freigegeben. Der Kontext-Verifier ist RED3/6 (unknownLaterReplay,
mapOldReplay, friendContextReplay, acht Quellen, Acht-Limit, Source-Stack).
Neue reine Visualhilfe `weapon_fire_feedback_layer.gd` besitzt maximal acht
transiente Projektionen. Der vorhandene Pulse behaelt300/720ms und seine
128-ID-Historie; Identitaet umfasst Event-ID, Source und Tick im Mapkontext.
Die regulären Meshfronten blaster-a und blaster-f erhalten lokale Marker
aus den echten GLB-Endflaechen (a:0/.0795/-.37, f:0/.0825/-.655), die den
bestehenden Mesh-/Socket-/Aim-Transform voll mitnehmen. Unbelegte Waffen
behalten einen ausdruecklichen Katalogfallback, keinen Kopflichtanker.
Der native Snapshot macht Herkunft, Weltposition und Forward-Dot lesbar.
Der zusaetzliche Source-Order-Verifier bildet den echten Controllerpfad
nach: acht frische tickbasierte Driver-Events plus hinten angehaengter
First-Exchange-Beleg. Auswahl muss nach vergleichbarem Tick erfolgen und
pro Quelle das neueste Event behalten; `created_msec` des aeusseren
Evidencewrappers ist kein Fire-Event-Tick. Ein expliziter
`presentation_history_only`-Transportmarker am angehaengten historischen
Event verhindert erstmals empfangenes Altfeuer. Controllerwriter/Root
koordiniert diesen einen Payloadmarker; die Pulsehilfe bleibt Empfaenger.
Der neue Muzzle-Anchor-Verifier liest Originalmeshmarker, Welttransforms,
Flashnachfuehrung und Front-Dot in zwei echten Visual-Aimrichtungen und
prueft dabei unveraenderte Actorwerte. Das bleibt eine Rendererfixture;
der normale native Fire-Event-/Pixelnachweis folgt separat.

## R4 Zwischenstand und offene Ursachen
- Root bestaetigte nach dem ersten engen Produktpatch Hostile23/0,
  Lifecycle13/0 und Context9/0, errors0 und stabile Quellen. Das sind
  Renderer-/Abgrenzungsgates, keine native Flashabnahme. Nach weiteren
  Quellen-/Historykorrekturen muessen sie am finalen Pin erneut laufen.
- Der reale Controllerwrapper ist im Source-Order-RED19/4 belegt:
  Historymarker fehlt, ein alter angehaengter Eintrag verdraengt Quelle0
  und erstmals empfangene History wird als frischer Pulse gezeigt.
  Historische Payloadkopie markieren und nach vergleichbarem Tick sortieren
  sind freigegeben; frische Quellsnapshots/Evidencebesitzer bleiben gleich.
- Zusaetzliche Admission-RED prueft Wiedereintritt desselben Keys bei
  unknown->known60ms und hide->show innerhalb720ms. Gewuenschtes Verhalten:
  Ein abgelehnter oder bereits verbrauchter Eingang bleibt verbraucht;
  erneuter Schuss braucht eine neue echte Eventidentitaet. Nur originale
  first-seen-Age zu bewahren reicht dafuer nicht.
  Root bestaetigte Admission-RED3/2, errors0, stabile Quellen. Freigegeben:
  einmalige first-receipt-Eligibility ueber dieselbe begrenzte128-Key-
  Kontextgeschichte; unbekannter/verbrauchter Key wird nicht reaktiviert.
- AnchorQA nach Yaw-Settling ist19/4: Flash folgt innerhalb.003 der realen
  Meshmarke; alle vier Front-Dots bleiben negativ. Keine blinde Achsen- oder
  Toleranzkorrektur. Die aktuelle Hypothese ist ein bestehender
  Animationsbesitzfehler: Clipadvance schreibt pro Frame Bones, importierter
  Shoot-Hold wird dagegen nur bei geaenderter Payloadsignatur aufgetragen.
  Die Fixture protokolliert0/3/10/settled echte Bonequaternionen, Hold-Drift,
  Posemetadata, Clipzeit und Meshfront. Erst dieser Verlauf entscheidet
  zwischen Poseueberschreibung und einem Attachment-Achsenfehler.
  Die Diagnose bestaetigt nun bis93.69Grad echten Hold-Bone-Drift bei
  Frame3 trotz pose_active=true und fortschreitendem standShoot. Kleine
  Pose-Owner-AC: Originalshoot-Importrotationen bleiben nach jeder
  kontrollierten Clipadvance in Frame0/3/10 auf den vorgesehenen Bones;
  Animation spielt weiter, Waffenroot bleibt am Socket, Actorwerte bleiben
  unveraendert. Der neue Pose-Stability-Verifier nutzt echte Bonequaternionen
  als Oracle. Erst nach seinem RED darf derselbe importierte Hold nach der
  bestehenden Advance wieder angewendet werden. Keine erfundene Handpose,
  kein Freeze und keine neue Gameplay-Facingquelle.
  Pose-Stability-RED ist durch Root9/6 (echte Boneabweichungen81-94Grad,
  Socket-/Actor-/Weiterlaufguards gruen) bestaetigt. Gewaehlte minimale
  Umsetzung: `standShoot` verwendet wie die bestehenden Bewegungs-Mischfaelle
  den vorhandenen Baker mit `upper_body_pose_animation=shoot` und
  `pose_track_scope=shoot_upper_body`. Die importierten Holdquaternionen
  werden einmalig bei Clipkonstruktion als konstante Rotationstracks
  gebacken. Basisclip/Beine/Clipzeit laufen weiter, Rohclip `shoot` bleibt
  unveraendert, keine zusaetzliche per-Frame-Bonearbeit oder Achsenkorrektur.
  Root bestaetigte danach Pose15/0 sowie402/403 gruen. Der unabhaengige
  Anchorbefund bleibt19/4 mit jetzt stabiler Frontdot-.893 fuer beide
  Richtungen/Quellen; Nachfuehrung und Socketguards sind gruen. Damit ist
  zusaetzlich eine um180Grad verkehrte sichtbare Meshfront an den beiden
  belegten blaster-a/f nachgewiesen. Freigegebener engster Assetpivotfix:
  nur deren bestehenden Loadouts erben den bisherigen Defaultattachment
  und uebersteuern dessen Child-`visual_rotation_degrees` auf0/0/0.
  Socket, Rootrotation, Position, Skalierung, Visualoffset, andere Loadouts
  und originale negative-Z-Muendungskoordinate bleiben unveraendert.
  Parallel wurde174 mit81/2 (barrel down/magazine back) rot. Die erste
  Einstufung als Childkorrektur-Regression ist noch nicht ausreichend:
  Der alte174-Check misst die WaffenROOTbasis, nicht den Meshchild.
  Der private Main3b12-Baselinelauf ist gleich81/2: keine R4-Regression.
  Die globale Childkorrektur wurde vorlaeufig zugunsten enger
  Aimed-Abgrenzung zurueckgenommen. Zwischenloesungs-AC: Idle/Ready behalten
  ihren bisherigen
  Child-Yaw180; nur `aimed` addiert fuer die beiden belegten Loadouts eine
  visuelle180Grad-Korrektur im vorhandenen Child-Aim-Yaw-Pfad. Kein Root-
  oder Socketwechsel und keine Runtimeposture-Mutation. Nach leerem
  Eventpayload/normalem Visualsync sind lokale Originalrotationen,
  Attachmentposition/-scale und Parentidentitaet wieder gleich. Ein
  anschliessender neuer Fixture-Schuss korrigiert die Front erneut ohne
  akkumulierte Rotation.
  Danach belegte der reale Idle-Axis-Inspector an denselben beiden Units
  bei lowered/idle die eigentliche alte Main-Ursache: Die sichtbare
  primaere negative-Z-Meshfront zeigt mit downDot-.959 nach oben, obwohl
  der ROOTfrontDown+.959 suggeriert. Das alte174-Oracle verwendet daneben
  den um90Grad falschen Proxy-Back und Magazine+Y statt der tatsaechlichen
  Meshgeometrie-Magazine-Y. Seine Richtungsaussage ist fachlich falsch.
  Der abgestimmte174-Test wird deshalb gegen ActualMeshfront, kanonische
  Body-Back-Achse und Magazine-Y bei unveraenderten.85/.70-Schwellen
  repariert und zuerst als RED ausgefuehrt. Bis dahin keine Produktwrites.
  Gewuenschtes finales Verhalten ist eine richtige sichtbare Meshfront
  sowohl in Idle als auch beim Aim; die globale lokale A/F-ChildYaw0-
  Korrektur ist danach voraussichtlich der kleinere gemeinsame Besitzer,
  waehrend bedingte180Grad-Metadaten und Sonderpfad entfallen koennen.
  Root bestaetigte nun das reparierte ActualMesh174-RED83/2: lowered-
  Vorbedingungen gruen, MeshfrontDown-.959, MagazineBack+.953/.946. Damit
  ist der alte Main-Meshfehler unabhaengig bestaetigt. Finale freigegebene
  Umsetzung: nur die beiden belegten A/F-Loadouts erben explizit bisherige
  Defaultattachmentwerte und setzen ChildvisualYaw0. Bedingter Aimed-
  Metadaten-/Helperzusatz wird entfernt; Root, Socket, Scale, Visualoffset,
  negative-Z-Frontpunkte und importierter Posebaker bleiben gleich. Andere
  Modelle/Loadouts erhalten weder Defaultmerge noch neue Rotation.

## Finaler fokussierter Quellstand vor nativer Wiederholung
Der globale kleine A/F-Assetpivot ist wieder der finale Kandidat, kein
bedingter Aimed-Sonderpfad. Root bestaetigte an diesem Pin:

- repariertes ActualMesh174:85/0, errors0, stabile Quellen unter
  `output/runtime_hitches_r4_20261107/attachment_actual_mesh_green/20261107T095103Z-f9993215`;
- Muzzle-Anker inklusive zweimaligem Aim/Idle-Reset:30/0 unter
  `output/runtime_hitches_r4_20261107/muzzle_anchor_global_final/20261107T095112Z-633bf83c`;
- Pose-Stabilitaet15/0 und die bestehenden Animation402/403-Gates gruen.

Diese Daten bestaetigen den alten Main-Assetfehler und das reparierte
Oracle; die vorherige Einstufung als R4-Idle-Regression ist aufgeloest.
Produkt und Verifier sind eingefroren. Aktuelle Produktpins:
Terrain`6e44848675928b97e5471ffd3e80a318367b34750d6ddc72a7c7db6e0948f7e1`,
Mapping`a7d133cdc510b71eedf4d3e7fdd08d68dc49252d0377ff9e56315bfcb6c70159`.

Der erste native Combatlauf bleibt als roter Rohbefund erhalten: frischer
echter Flash als Runtimeereignis beobachtet, aber Viewlebenszyklusfehler
bei der Bildserie und physische Kamerainputs im Messfenster. Er ist weder
gueltiger Performancevergleich noch finale Pixelabnahme. Der reparierte
native Harness fuehrt erst die komplette normale90s-/Parentbildroute aus,
danach Move/GO, beobachtet dieselbe Mission samt OneShot-Resultsignal und
guardet alle Warte-/Scenewechsel. Er verlangt mindestens einen lebenden
echten Flashframe0/120ms, kennzeichnet geschlossene Kontexte und beobachtet
anschliessend bis10s echte FoW-Transitions, sofern die Mission weiterlebt.
Sein eingefrorener Pin ist
`618fc1a53d80c17e4fc19f80c1248756179514c069892f04ec82b13e8959ab34`.
Neue native Bilder, unveraenderte Kamera im Messfenster und der echte
Fog-/LOS-Nachlauf sind weiterhin separat durch Root zu pruefen.

## Zusatzbefund: Posequelle muss denselben aktuellen Fire-Feed lesen
Root fand am Terrain6E einen verbleibenden getrennten Leser:
`_ensure_unit_proxy_payload_indexes` liest das Array rueckwaerts, nimmt
dadurch angehaengte History als Aim-Quelle und entscheidet nicht nach
autoritativen Ticks. Seine Cacheinvalidierung haengt ausserdem noch an der
schweren Order-Signatur, die nur die letzten drei Events enthaelt. Ein
neuer frueher Source im vollen Achterfeed kann dadurch einen frischen
Pulse, aber eine alte sichtbare Waffenpose erhalten.

Enger RED zuerst: echter Human-/Waffenmesh als Rendererfixture, neuer
Current-Tick vor alter History oder regulaer geshuffelten Events; History
allein erzeugt keine aktive Firepose. Bei acht Quellen und identischen
letzten drei Eintraegen aendert eine neue fruehe Quelle deren echte
Proxy-Event-ID und Meshfront, waehrend Heavy-Order-Signatur und unbeteiligte
Ordernode-IDs identisch bleiben. Actorposition, HP und Runtime bleiben
unveraendert. Geplanter Fix erst nach Root-RED: ein gemeinsamer abgeleiteter
Latest-current-Selector und eine volle Achter-Poseinputsignatur am
Payloadeingang; keine neue per-Frame-Serialisierung und kein groesseres
Trace-/Labelbudget. Root bestaetigte den echten RED unter
`fire_pose_feed_red/20261107T110042Z-9de54f60`:6/8, errors0,
stabile Quellen. Alle acht Fehler betreffen History, Reihenfolge oder die
fruehe Quelle; Heavy-/Actor-Guards sind gruen. Der enge gemeinsame Selector
und die separate Posefeedrevision sind damit autorisiert. Die volle
Signatur wird erst nach Publikation der neuen Payload aktualisiert, damit
kein waehrend des Heavy-Signaturbaus gelesener alter Index eine neue
Revision erhalten kann. Prone-Nativeharness bleibt unveraendert frozen.

Root-GREEN `fire_pose_feed_green/20261107T110510Z-2ef344e8`:14/0,
errors0, source/roster stable. Originale Meshfront und Proxy-Event-ID folgen
Current statt History, dem neuesten Tick und der erneuerten fruehen Quelle;
Heavy-Signatur, Ordernodeidentitaeten und Actorstate bleiben dabei gleich.
Produktfreeze dieses Deltas: Terrain
`FB9905172A9115C6458A90C3FDB896895C0576978BD999A6567C7711458B60F2`, Layer
`3087B4ABDCC92C93A3449187BAB623899B2D520E78F161194D77A329BE75DB84`.
Keine native Sicht-/Performanceabnahme aus diesem Rendererfixture ableiten.

## Down-/Bleedout-Beweisgrenzen vor nativer Nahaufnahme

Lesendes Nachreview der bestehenden Gates: TASK_471
(`ED0E9B24C9777519B0F4C0B9E9EB53E726B2E4852D5C5E8D3709553321F41415`)
setzt Damage in einer ausdruecklichen Fixture und prueft Vitalstate,
`unit_down_pose_active` und DOWN-Text. TASK_474
(`8149664999AA1E2107C05B58F4C095616F8025AF5CECF13E02144A50395DAA19`)
prueft synthetisch Linger/Respawning plus Metadaten und Badge; sein
Lingerfall verschiebt ausserdem den internen Testzeitstempel. Beide sind
gueltige Datenfluss-/Timingregressionen, aber messen weder Originalmodell-
identitaet noch sichtbare liegende Figur oder Bodendurchdringung.

Der neue native Harness
`runtime_hitches_r4_20261107_actual_fire_capture.gd`, Freeze
`D4AD5546B2F329C8024FFC46D0B6BD4BBF7E391FD849F6E52BFB3DF798C91B3B`,
veraendert diese Gameplaywerte nicht: normale Start-/Transport-/Move-/GO-
Route, echte neue Fireevents und vorhandene originale Actor-/Model-IDs.
Er liest Targetzustand und Model-/Proxytransforms bei0/120/900ms, versucht
bei tatsaechlichem Down/Bleedout nach900ms oder im normalen Zehnsekunden-
Nachlauf eine reine Kameranahaufnahme und stellt danach die Kamera wieder
her. Ein fehlender natuerlicher Downzustand wird als nicht verfuegbar
ausgewiesen. Static-Mesh-AABBs sind explizit keine Skinned-/Pixelmessung;
`unit_down_pose_active`, `available` und `same_original_model` alleine
akzeptieren keine liegende Silhouette. Das originale Nahaufnahme-PNG muss
nach dem Lauf geoeffnet und zusammen mit Vitalstate, Sichtbarkeit,
Modellidentitaet und Bodenposition beurteilt werden. Bis zu diesem Befund
bleibt die native Abnahme der liegenden Figur offen; kein Produktfix auf
Verdacht. Dieser Abschnitt ist ein Lesereview, keine eigene unabhaengige
Abnahme des selbst verfassten Harness oder des Posefeedtests.

## Nahe Ausblendungen: Diagnose vor Verhalten
Der gelesene Hex-FoW-/LOS-Pfad verwendet fuer Reichweiten bereits dieselbe
Registry-Metrik. Eine World-/Hex-Einheitenabweichung ist bisher nicht
bestaetigt. Beim nativen Sichtbarkeitswechsel muessen aktive Observer mit
effektiver Reichweite, Registry-Distanz, LOS-Ergebnis, Terrainblockern,
sichtbaren Target-/Tile-IDs und Proxyadmission gemeinsam erfasst werden.
Erst dieser Vergleich trennt absichtlichen Deckungs-/Haltungsverlust von
einem Fehler; keine pauschale Radiusvergroesserung.

## Vertraege
AGENTS, PROJECT_BRIEF, ARCHITECTURE, CODEX_RULES, IMPLEMENTATION_STATUS,
TASK_ROADMAP, graphics_reference_revision_contract,
unit_facing_visual_contract, combat_loop_authority_contract,
fog_of_war_modes_contract und hex_grid_v1_contract.

## Akzeptanz und lokale Pruefung
- Der neue fokussierte Verifier verwendet den realen TerrainView, echte
  Character-/Skin-/Attachmentressourcen und vorhandene Gegner-IDs/Archetypen.
  Erfolgreiche Menschenmodelle haben keinen sichtbaren Capsule-Core davor.
- Originales Model-/Waffenobjekt, Teamring und Actor-/Runtimewerte bleiben
  bei normalen visuellen Syncs identisch. Kein Headless-Mesh-PASS wird als
  native Sichtabnahme ausgegeben.
- Ein explizit simulierter fehlender Modellloader behaelt die vorhandene
  Missing-Asset-Markierung und Notdarstellung; eine neue Missing-Asset-
  Geheimroute darf nicht unbemerkt echte Gegner verschwinden lassen.
- Root fuehrt echten RED vor dem Produktpatch, danach GREEN und die
  bisherigen Enemy-Facing-/Attachment-/Down-/Bleedout-/FoW-Nachbargates aus.
  Hostile-Modell-RED laut Root21/2, errors0, stabile Quellen: exakt die
  beiden vorhandenen Humanmodelle mit sichtbarem Capsule-Core.
- Anschliessend native Vollbildbilder im echten Spielabstand22/34 oeffnen;
  Modellidentitaet, Teamlesbarkeit und menschliche Silhouette beurteilen.

## Dateien / Besitz / Risiken
Produktumfang: die beiden erfolgreichen-/Fallback-Core-Grenzen und die
enge Lifecycle-/Quellenauswahlentkopplung in
`scripts/terrain/terrain_map_3d_view.gd`, zugehoerige Pulse-Hilfe und
belegter Waffenmesh-Anker. Root haelt Produktwrites bis zum abgeschlossenen
Perf-only-Vergleich. Neuer Verifier
`scripts/tests/runtime_hitches_r4_20261107_hostile_model_verifier.gd`, Marker
`R4_HOSTILE_MODEL_PASS`. Root bleibt alleiniger serieller Engine-/Git-Runner.

Risiko: Das Entfernen des Core kann die rote Teamfaerbung kleiner machen.
Der existierende Bodenring und echte Skin bleiben deshalb im Verifier und
nativen Bildvergleich sichtbar. Keine Ersatzfigur und kein ungetestetes
Outline-/Shader-System in diesem engen Schritt. Status: enger Produktpatch
geschrieben und eingefroren; weitere Ursachenpruefung und finale Gates
offen. Alle Enginepruefungen erfolgen ausschliesslich durch Root.
