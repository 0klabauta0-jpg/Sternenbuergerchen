# R3: finaler Darstellungsbesitz fuer Primary und GO

## Ziel / bestaetigte Ursache
Untertask zur autonomen R3-Runde, Basis Main173a1e3c3. Der unabhaengige
Nachreview bestaetigt in `_apply_release_firefight_command_primary_button_polish`
und `_apply_release_firefight_command_go_button_polish` einen verbleibenden
Legacy-/Native-Doppelpass. Der Primary-Textguard allein verhindert weder
`clip_text=true`, Font12 noch aktive Selbstmodulation. GO setzt weiterhin
`GO`, Font13, Clipping, Modulation und vier Fontfarben. Der vorhandene native
A5-Presenter stellt anschliessend seine Endwerte wieder her. Gleiche
Fontoverride-Aufrufe melden zudem erneut eine Themeaenderung.

## Umfang und Nicht-Ziele
Nur diese beiden Legacyfunktionen und ein neuer fokussierter Verifier.
Fuer bereits nativ besessene Primary-/GO-Controls bleiben Text, Clipping,
Font, Selbstmodulation und Fontfarben beim bestehenden nativen Presenter.
Tooltips, alle bestehenden Enhancement-Metadaten, GO-Bereitschaft, Disabled,
Callbacks und Commands behalten ihre bisherigen Pfade. Frische/Legacy-
Controls erhalten weiterhin den bisherigen vollstaendigen Polish.
Kein ROE-Umbau, kein neuer Owner, kein persistenter Cache, keine Aenderung
an Orders, Queues, Actors, Zeiten oder Simulationsfrequenz.

## Akzeptanz
- Reale vorhandene Controls in der Missionsszene bei tatsaechlichen
  logischen3440x1440,1920x1080,1280x720; aktive und inaktive Polishzustaende.
- Vor/Nach den beiden echten Legacyfunktionen keine native Presentation-
  Zwischenmutation und keine Theme-Notifications der beobachteten Buttons.
  Verglichen werden echte Ressourcen und deren Stilwerte, Text, Font,
  Farben, Clipping, Icon/Alignment und Modulation, nicht nur eine neue Meta.
- Tooltip-/Enhancement-Meta-/Gate-/Callbackdaten stimmen mit demselben
  expliziten Legacypfad ueberein. Legacytokens/-fonts/-clipping und aktive
  GO-Farben bleiben erhalten, sowohl fuer bereit als auch blockiert.
- Auch ein voller `_update_ui`-Durchlauf erreicht bei erzwungenem neuem
  visuellen Signaturpass diese Grenzen ohne Zwischenreset. Alle Ownerdaten
  bleiben synchron unveraendert.
- Root fuehrt den echten RED vor dem Produktpatch und danach GREEN sowie
  passende Nachbargates und native Vollbildmessung seriell aus.

## Dateien / Pruefung / Besitz
Perf-Owner: zwei benannte Funktionen in
`scripts/tests/mission_tactical_sandbox_controller.gd`, Produktpatch erst
nach Root-RED. Reviewer: neuer
`reference_polish_r3_20261106_command_style_owner_verifier.gd` und diese AC.
Root bleibt einziger Engine-/Git-Runner und Integrationsowner.

Der Verifier verwendet eine echte Missionsszene mit einem abgeleiteten
Beobachtungscontroller an den originalen NodePaths/Exportbindings. Nur der
Anzeigegetter fuer vorhandene Orders wird fuer die beiden Bereitschafts-
zweige kontrolliert beantwortet und der GO-Control bekommt die dazugehoerige
Disabled-Eingabe. Echte lokale Authority wird positiv geprueft und bleibt
unveraendert. Dies ist eine Presenterfixture, kein Beleg
fuer reale Orders oder physisches Spielen. Command-/Effectqueues, Planowner,
Tick und vorhandene Actorwerte werden auf Unveraendertheit geprueft.

## Vertraege und Risiken
AGENTS, ARCHITECTURE, CODEX_RULES, mission_hud_projection_authority_contract,
mission_command_feedback_contract, uebergeordnete R3-Task und Perf-Untertask.
Die Diagnosemetadaten beschreiben weiter ihre historischen Enhancement-
Werte; sie werden nicht als zweite finale native Stilwahrheit umgedeutet.
Keine pauschale Rueckgabe vor Tooltips oder Readiness. Nativer Endvergleich
und Millisekundengewinn bleiben getrennte Root-Gates.

## Reproduktion
Der erste Rootlauf `command_style_owner_red/20261106T232858Z-4740df95`
reproduzierte Stilruecksetzungen, enthielt aber noch einen eigenen Lifecycle-
Fehler im unbeobachteten fruehen GO-Override und unvollstaendige Readiness-
Preconditions. Dieser Lauf ist deshalb kein fehlerfreies Verhaltens-RED.
Der Probe delegiert unbeobachtete Aufrufe jetzt direkt an die Base und
verwendet die explizite UI-Disabled-Precondition bei positiv gepruefter
echter lokaler Authority. Die Assertions wurden nicht abgeschwaecht.

Root bestaetigt danach
`output/reference_polish_r3_20261106/command_style_owner_red_corrected/20261106T233050Z-b0aa40b4`:
82 bestanden, exakt60 Presentation-/Theme-Fehlschlaege, Exit1, Fehler0,
stabile Quellen und isolierte Nutzerdaten. Alle Readiness-, Owner-, Legacy-,
Tooltip-/Meta-/Gate-/Callback- und Viewportpruefungen bestehen.
Erst auf dieser Basis ist der enge Produktpatch fuer die beiden benannten
Legacyfunktionen freigegeben. GREEN und nativer Gewinn sind getrennte Gates;
das anschliessende Komponentenergebnis folgt unten.

Root-GREEN `command_style_owner_green/20261106T233206Z-29d021d1`:
142/142, Exit0, Fehler0, Isolation und stabile Quellen. Der Report bindet
Controller `2434f55be706c284c9838e4c58aa76ed45624d6ddfe43e730e7cf25b9c9b8235`.
Der Nachreview bestaetigt den engen Ownerguard ohne offenen P1/P2-Befund.
Nativer Gewinn, Nachbarmatrix und Mainintegration bleiben separate Root-Gates.
