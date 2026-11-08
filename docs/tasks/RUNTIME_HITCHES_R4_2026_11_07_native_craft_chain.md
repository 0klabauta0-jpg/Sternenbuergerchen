# R4: nativer Kontextbutton im regulaeren Craft-Refresh

## Ziel / bestaetigter Quellbefund
Nach den Kartenkorrekturen liegt ein weiterer konkurrierender Presenter vor:
`_refresh_runtime_mission_hud_surfaces(true)` ruft Dynamicstyles und damit
bereits einen nativen A5-Endpass auf. Danach setzt die Hierarchie ueber
`_apply_primary_mission_interaction_semantics` den DoorBreachButton wieder auf
generischen Stil/Font13. Der abschliessende Fixed-HUD-Pass projiziert denselben
sichtbaren Kontextbutton erneut neutral mit Font12. Der fruehere dynamische
Basisskin und die Door-Affordance koennen ebenfalls diesen Endstil ersetzen.
Millisekundenanteil und tatsächliche redundante Enginebenachrichtigungen sind
noch nicht isoliert belegt; zuerst echter Boundary-RED.

## Umfang / Nicht-Ziele
Nur bereits nativ besessene Style-/Font-/Modulatefelder des sichtbaren
Kontextbuttons. Quelle, Availability, Disabled-Gate, Text, Tooltip, Metadaten,
Door-Affordance-Receipt, Help, Requires-GO und originale Callbacks bleiben im
bestehenden Owner. Unbesessene Legacybuttons behalten ihre volle Darstellung.
Keine Gameplay-/Door-/Actor-/Command-/LOS-Aenderung, kein kompletter Craft-
oder Layoutskip, kein persistenter Cache, keine Cadencereduktion. Keine neue
ROE-/Primary-Action-Umgestaltung in diesem engen Task. Produkt hold bis RED.

## Dokumente / betroffene Dateien
AGENTS, PROJECT_BRIEF, ARCHITECTURE, CODEX_RULES, IMPLEMENTATION_STATUS,
R4-Haupttask, `mission_hud_projection_authority_contract.md`, R3-Styleowner und
R4-Native-Card-Chain-Task. Produkt nach Freigabe ausschliesslich bestaetigte
Controller-Boundarys; Verifier:
`scripts/tests/runtime_hitches_r4_20261107_native_craft_chain_verifier.gd`.

## Akzeptanz / lokale Pruefung
1. Echte Missionsszene, wirkliche Controls, regulaerer erzwungener Craft-
   Refresh und echte Helper-super-Aufrufe. Nur reine UI-Interactionsnapshot-
   Eingaben variieren nutzbar/blockiert; es wird keine physische Tuer oder
   Gameplay-Availability vorgetaeuscht und kein Callback ausgefuehrt.
2. Bestehender A5-Kontextbutton hat vor/nach jeder konkurrierenden Boundary
   gleiche komplette Style-Ressourcen, Fonts, Farben und self_modulate; der
   finale Presenter muss keine gerade verworfenen Werte reparieren.
3. Finale komplette Buttonpraesentation, Metadata, Tooltip, Rects und Callback-
   Identitaeten bleiben gleich zum expliziten alten UI-Besitzpfad. Gate- und
   Quellenwechsel wirken sofort. Inputs und Runtimeowner bleiben unveraendert.
4. Unbesessener direkter Semanticsaufruf behaelt generischen Font13 und seine
   Availability-/Help-/Callbackdaten. Der native Endpass behaelt Font12.
5. Themebenachrichtigungen eines wirklich wiederholten nativen Gesamtrefreshs
   werden separat gezaehlt. RED/GREEN, Nachbargates und native Leistungswirkung
   bleiben getrennt; Root ist einziger Engine-/Gitrunner.

## Risiken / Status
Die vorhandene Hierarchie darf keine stale Gate-/Tooltip-/Semanticsdaten
behalten, nur weil ihr Stil bereits einen anderen Owner hat. Neue Guards
muessen den bestehenden nativen Besitz pruefen und echte Initialisierung oder
Legacyweiterverwendung erhalten.

## Gebundener RED und enger Patch
- Root-RED `craft_chain_red/20261107T091728Z-f2eb4753/`:15 bestanden,4 rot,
  keine Enginefehler, stabile Quellen. Blockiert/nutzbar zeigen echte
  Font12->13->12-, Style-/Farb-/Modulatewechsel; der wiederholte Craftpass
  erzeugt12 bzw.28 Themebenachrichtigungen am beobachteten Kontextbutton.
- Die drei bestaetigten Styleboundarys (dynamischer Basisskin, Authority-
  Affordance, Interaction-Semantics) lesen einen reinen Ownershiphelper.
  Er verlangt den bestehenden A5-Rootbesitz, den bestehenden DoorBreachButton
  und dessen wirklich angewandtes `native_a5_layout`-Meta. Nur native Style-
  writes entfallen; saemtliche Quellen/Gates/Texte/Tooltips/Metadata bleiben.
- Controller-Sourcefreeze inklusive separat freigegebenem Historymarker:
  `27885bd75523fab8f7eec69eb5df8863789666a1746fa1f9397a43a16aa83530`.
  Verifier seit RED unveraendert:
  `bdc4b14aa55e2247e2cfce3fa3b4919869ea8e4fbd1ef541c9515e65c19c5bec`.
  `git diff --check` sauber.
- Root-GREEN `craft_chain_green/20261107T091926Z-104ac37c/`:19/19 ohne
  Enginefehler, stabile Quellen. Der enge Sourcehunk erhielt unabhaengig
  APPROVED scoped ohne P1/P2. Nachbarn und native Leistungswirkung werden
  weiterhin separat geprueft, nicht aus dem Komponentenpass abgeleitet.
