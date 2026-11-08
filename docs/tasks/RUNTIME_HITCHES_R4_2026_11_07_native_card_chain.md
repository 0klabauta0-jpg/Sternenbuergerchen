# R4: konkurrierende Mini-Card-Presenter vor dem A5-Endpass

## Ziel / Ursache
Nach dem ersten R4-Pass ist der native Karten-Endpass bei identischem Input
ruhig (Root:33/33), der echte Mini-Refresh bleibt im Vollbildprofil jedoch bei
7.233ms. Der regulaere `_refresh_fireteam_mini_cards` ruft vorher weiterhin
Legacy-Status-/Suppression-/Readiness-/Badge-/Stance-/Leaderhelfer auf. Diese
setzen Visibility oder Stage-Text, bevor der A5-Endpass sie wieder auf seine
finale Darstellung zuruecksetzt. Ob und wo echte Controls dadurch invalidiert
werden, wird zuerst mit einem frischen realen Refresh-RED gemessen.

## Umfang / Nicht-Ziele
Nur konkurrierende Visibility-, Text- und Styleprojektion auf existierenden
A5-Karten vermeiden. Das vorhandene `native_a5_portrait_team_card`-Meta bleibt
der UI-Besitzindikator. Legacyquellen, Metadaten, Tooltipdaten, Callback- und
Controlidentitaeten bleiben verfuegbar. Nichtnative Karten behalten den alten
Pfad. Keine ganze Refresh-Auslassung, keine neue persistente Runtime-/Framecache,
keine Cadence-, Actor-, Simulations-, Command-, Statusprioritaets- oder Layout-
aenderung. Root bleibt alleiniger Engine-/Gitrunner; Produkt ist bis RED hold.

## Dokumente / Dateien
AGENTS, PROJECT_BRIEF, ARCHITECTURE, CODEX_RULES, IMPLEMENTATION_STATUS,
R4-Haupttask, `mission_hud_projection_authority_contract.md`,
R4-Native-Card-Projection-Task. Produkt nach separater Freigabe ausschliesslich
`scripts/tests/mission_tactical_sandbox_controller.gd` bzw. konkret bestaetigter
Themehelper. Test:
`scripts/tests/runtime_hitches_r4_20261107_native_card_chain_verifier.gd`.

## Akzeptanz / lokale Pruefung
1. Test-only Controller-Subclass nutzt den echten regulaeren Mini-Refresh in
   der realen Missionsszene mit normalerweise initialisierten Runtimequellen.
   Existierende native Karten und wirkliche Helper-super-Aufrufe werden an
   ihren Grenzen beobachtet; keine Actor-/HP-/Positions-/Uhr-/Authoritypatches.
2. Bei gleicher frischer Quelle entstehen keine konkurrierenden A5-Visibility-
   oder StageText-Zwischenzustaende und keine redundanten Themebenachrichtigungen.
   Der Test betrachtet den ganzen Aufrufweg statt nur den Endpass.
3. Finale komplette Controlpraesentation (Ressourcen, Texte, Metadaten, Tooltips,
   Callbacks und Rects) bleibt gleich zu einem expliziten Legacy-Oracle. Dieses
   variiert nur den vorhandenen UI-Kartenbesitz waehrend der einzelnen
   konkurrierenden Helper und laesst ihre echten Implementierungen rechnen.
4. Vorhandene Actor, Tick, Plaene, Command-/Effectqueue bleiben durch den
   Presenter unveraendert. Oeffentliches Move/GO liefert den zweiten frischen
   Inputfall; der Vergleich findet synchron ohne Physicsfortschritt statt.
5. Frische und unbesessene Karten behalten volle Initialisierung, Legacydaten
   und Callbacks. Vorherige33/33, Command31/31 und R3-Ownership sind Nachbarn.
   Native Millisekunden und Framehitches werden danach getrennt gemessen.

## Risiken / Status
Ein pauschaler Skip kann versteckte Daten oder spaeter sichtbare Legacykarten
veralten lassen. Deshalb nur besessene Praesentationsfelder begrenzen und die
echten Quellen/Metadata weiterhin projizieren. Component-RED/GREEN und native
Leistungswirkung sind getrennte Nachweise.

## Gebundener RED und Umsetzung
- Root-RED `output/runtime_hitches_r4_20261107/card_chain_red/20261107T091004Z-8e9c7028/`:
  12 bestanden, 3 fehlgeschlagen, keine Enginefehler und stabile Quellen.
  Idle und oeffentliches Move/GO zeigen echte StageText-, MemberLabel-,
  SuppressionBar-, LeaderPortrait- und ReadinessFooter-Zwischenprojektionen.
  Der echte Gesamtrefresh hat bereits null Themebenachrichtigungen; der neue
  Befund sind konkurrierende Visibility-/Textprojektionen und deren Layoutarbeit.
- Exklusiv freigegebener enger Patch: Die vier bestaetigten Helper behalten
  Quellen, Metadaten, Tooltips, Callbacks und Legacyberechnung, ueberlassen
  jedoch die besessenen A5-Felder ihrem finalen Presenter. Neu erzeugte, im
  nativen Pfad ausgeblendete Controls werden vor AddChild unsichtbar gesetzt.
  Keine ganze Refresh-/Helper-Auslassung und kein zusaetzlicher Cache.
- Controller-Sourcefreeze SHA256
  `5a7c791ca6958bdcf94593f571308977974ce8e23b8c40786bf12a13935cf3bf`.
  Verifier seit RED unveraendert SHA256
  `87a86030af26ec46f82de841324211643d2fd3b0a63b3802b748afce9b3a2179`.
  `git diff --check` sauber.
- Root-GREEN `card_chain_green/20261107T091219Z-c3875a19/`:15/15 ohne Enginefehler.
  Unabhaengiges Source-Review des engen Vier-Helper-Hunks: APPROVED scoped;
  keine P1/P2. Nachbarn und nativer Nachlauf werden separat gebunden. Der
  anschliessende einzelne History-Transportmarker im Controller ist ein
  anderer Task und aendert diesen geprueften Kartenhunk nicht.
