# R4: Identische native Mini-Card-Projektion ohne Theme-Invalidierung

Untertask zu `RUNTIME_HITCHES_R4_2026_11_07.md`, Basis Main3b12b2878.
Root besitzt Engine, Git und Produktfreigabe; erster Stand nur AC/RED.

## Problem und bestaetigter Quellbefund
Der native Endpass `_apply_native_a5_fireteam_card` schreibt Panelressource,
Margins, Separation, Fonts und Farben bei jedem tatsaechlichen Kartenrefresh
erneut. Godots Theme-Override-Setter senden auch bei gleichem Wert eine
Aenderungsbenachrichtigung. Die bestehende Ressourcencache allein verhindert
diesen Aufwand nicht. Beim StageLabel schreibt `style_label` zudem erst die
normale Textfarbe und danach der Endpass die Warnfarbe bei Kontakten. Diese
Zwischenprojektion bleibt auch mit einzeln geschuetzten Settern redundant.
Die Anzahl dieser Benachrichtigungen ist fokussiert nachweisbar; ihr Anteil an
den nativen Framehitches muss anschliessend separat gemessen werden.

## Umfang und Nicht-Ziele
Nur tatsaechliche Darstellungsgleichheit im vorhandenen nativen Presenter.
Vorhandene `TacticalUITheme._override_*`-Helfer koennen die aktuellen, wirklich
besessenen Overrides pruefen. Keine neue State-/Zeitcache und kein pauschales
Ueberspringen des Presenters. Roster, Status-Contract, Callbackidentitaet,
Tooltipinhalt, Selektion und Runtime-Kommandos bleiben beim bestehenden Owner.
Keine Aenderung am Kartenmodell, an Statusprioritaeten oder am Layoutziel.

## Akzeptanz / fokussiertes RED
- Ein echter FOBFireteamCard-Controlbaum wird durch den echten nativen
  Endpass projiziert; nur die reinen Roster-/Status-Eingaben sind Fixtures.
- Wiederholung identischer Darstellung erzeugt in keinem existierenden
  Karten-Control eine Theme-Aenderungsbenachrichtigung. Die tatsaechlichen
  Ressourcenzuweisungen, Overrides, Texte, Rects, Metadaten, Tooltip- und
  Callbackidentitaeten bleiben gleich. Dies gilt auch bei Kontaktwarnung,
  Selektion, inaktivem Trupp, Beschaeftigung und Verluststatus.
- Wechsel von Selektion/Kontakten/Status werden sofort korrekt projiziert.
  Wirklich extern veraenderte oder entfernte Overrides werden beim naechsten
  Pass repariert. Ein gespeichertes Gleichheitstoken darf das nicht verhindern.
- Frische Karten erhalten weiterhin alle vom nativen Presenter besessenen
  Overrides. Eingabe-Snapshots/Roster und vorhandene Callbackidentitaeten
  bleiben unveraendert.

## Dateien, Contracts und lokale Pruefung
Produkt-Hunks nur nach Root-RED: nativer Mini-Card-Endpass und ggf. dessen
Geometriepass in `scripts/tests/mission_tactical_sandbox_controller.gd`.
Fokussierter Verifier:
`scripts/tests/runtime_hitches_r4_20261107_native_card_projection_verifier.gd`;
Marker `R4_NATIVE_CARD_PROJECTION_PASS`. Relevante Regeln: AGENTS,
ARCHITECTURE, CODEX_RULES, `mission_hud_projection_authority_contract.md`.
Root fuehrt RED/GREEN seriell aus; anschliessend echte Vollbildmessung.

## Risiken / Grenzen
Ein reparierender Pass darf nicht nur effektive Theme-Werte vergleichen,
sondern muss die besessenen Overrides pruefen. Bei Warnfarbe muss die normale
Zwischenfarbe entfallen, ohne die endgueltige Farbe zu aendern. Der Fixturetest
beweist UI-Invalidierung und Ausgabe, keine GPU-/FPS-/Spielakzeptanz. Bisher
kein Engine-RED/GREEN und kein Millisekundengewinn behauptet.
