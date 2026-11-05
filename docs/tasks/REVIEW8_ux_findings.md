# Review 8: erreichbare Evakuierung und ehrlicher Abbruchbericht

## Ziel und Basis

Belegte Bedienfehler im aktuellen A5-Missionspfad korrigieren. Basis ist
Main `93c2e6810bf3699ea4237b8a4cdc60e2412660bb`; Arbeit auf
`task/review-graphics-20261105` im isolierten Review-Worktree.
Der bereits integrierte Zweiter-Einsatz-Fix wird nicht dupliziert.
Der Gesamtauftrag steht in `REVIEW8_2026_11_05_code_ux_graphics.md`.

## Befund 1: reguläre Evakuierung im A5-HUD verdeckt

Situation: Ein Host wählt ein aktives Ground-Fireteam an einer gültigen LZ.
Der vorhandene Owner erlaubt die Evakuierung. Die einzige bisherige
`MissionEvacuationButton`-Instanz liegt jedoch unter `StrategicPanel`, das
die A5-Darstellung vollständig ausblendet. `visible=true` auf dem Button
belegt deshalb keine tatsächlich erreichbare Aktion. Der historische
TASK1069-Verifier prüft nur diese lokale Property und ruft den Request
anschließend direkt auf.

Änderung: Das vorhandene Einsatz-/Team-Detailfenster bietet den nativen
Button `Evakuieren · Einsatz abbrechen`. Beide Details-Tooltips nennen
Evakuieren. Die Anzeige liest `disabled`, lokale Sichtfreigabe und Tooltip
vom ursprünglichen Button. Während des sichtbaren getakteten Detailrefreshs
und unmittelbar vor Aktivierung aktualisiert dessen bestehender Owner die
Freigabe; so bleiben auch Bewegung und Authority-Wechsel aktuell, obwohl
der normale Craft-Controls-Cache diese Änderungen nicht vollständig enthält.
Eine gültige Aktivierung emittiert genau das ursprüngliche `pressed`-Signal.
Der Owner prüft weiterhin LZ, Auswahl, Authority und Missionszustand und
erzeugt das Ergebnis. Der ursprüngliche NodePath bleibt erhalten.

## Befund 2: bestätigter Abbruch erscheint als fehlender Bericht

Situation: Der bestehende Combat-Authority-Pfad liefert
`result=aborted`, `mission_outcome=aborted`, `win_condition_type=evacuation`.
Die native Debrief-Projektion kannte diese Werte nicht und zeigte
`Bericht unvollständig`, `Ergebnis offen` und ein Fragezeichen.

Änderung: Die Projektion zeigt `Einsatz abgebrochen`, den Chip
`Abgebrochen`, die Bedingung `Evakuierung` und das vorhandene neutrale
Endesymbol mit passendem Tooltip. Das vollständige Authority-Payload und
der Originalbericht bleiben unverändert. Sieg, Niederlage und tatsächlich
unbekannte Ergebnisse behalten ihre bisherigen Bedeutungen.

## Umfang, Nicht-Ziele und Verträge

Produktdateien:

- `scripts/ui/mission_a5_hud_layout.gd`
- `scripts/meta/debrief_screen.gd`

Gezielte Verifier:

- `scripts/tests/review8_ux_evac_reachability_verifier.gd`
- `scripts/tests/review8_ux_debrief_abort_verifier.gd`

Relevante Verträge: `mission_evacuation_abort_contract.md`,
`homebase_direct_dropship_flow_contract.md`, `ui_native_design_contract.md`;
außerdem TASK1069 und `BUGFIX_2026_11_04_a5_second_sortie.md`.
Keine neue Evakuierungs-, Missions-, Transport- oder Progressionswahrheit,
keine Kampf-/Bewegungsregeländerung, kein neuer Ablauf für PvP-Extraction.
Das zweireihige A5-Hauptlayout bleibt erhalten. Die vermutete
CraftSelector-Popup-Lifecycle-Lücke wurde nicht reproduziert und nicht
implementiert; sie ist kein bestätigter Befund dieses Slices.

## Akzeptanz und lokale Evidenz

Alle Engine-Läufe wurden zentral durch Root seriell mit isolierten
Nutzerdaten ausgeführt. Die zugehörigen `report.json` bestätigen Exitcodes,
Pfadguard und identischen Originalroster vor/nach dem Lauf.

| Prüfung | Vorher | Nachher | Evidenz unter `output/review_graphics_20261105/` |
| --- | --- | --- | --- |
| Erreichbare EVAC-Aktion | 8 PASS / 4 gewünschte FAIL | 40 PASS / 0 FAIL | `red/20261105T051523Z-22cda4e9/ux_evac_reachability.log`; `green_ux_retry/20261105T052254Z-ad8c64f9/ux_evac_reachability.log` |
| Abbruch im sichtbaren Debrief | 42 PASS / 8 gewünschte FAIL | 50 PASS / 0 FAIL | `red_debrief_corrected/20261105T051635Z-afbefd8d/ux_debrief_abort.log`; `green_ux/20261105T052020Z-1bb32bba/ux_debrief_abort.log` |

Beide Prüfungen laufen in 1920×1080 und 1280×720. Die EVAC-Prüfung öffnet
Details mit Maus-Motion/Down/Up, prüft das ganze Popup samt Position im
Root-Fenster und den gesamten Button in dessen Viewport/Clipping-Vorfahren.
Fehlende LZ, Außenbereich und Authority-Verlust sperren die Aktion.
Bewusst erzwungene disabled-Signale dürfen den Originalcallback nicht
auslösen. Der echte abschließende Mausklick erreicht zwei GUI-Mausereignisse,
aktiviert den neuen Button genau einmal und den Originalcallback genau
einmal; der Combat-Driver liefert daraufhin das bestehende Abbruchresultat.

Testdiagnose transparent erhalten: Der erste Debrief-Test hatte das
`visible=false`-Default der Szene übernommen; die korrigierte sichtbare
Fixture reproduziert ausschließlich die acht Abbruchfehler. Der erste
EVAC-Greenversuch injizierte die Maus direkt in das eingebettete
Popup-Viewport und erreichte dessen Hoverpfad nicht. Der korrigierte
Test sendet über den Embedder mit transformierten Koordinaten. Hierfür
wurde keine weitere Produktänderung nötig. Siehe die offiziellen
[Godot-4.6-Viewport-Methoden](https://docs.godotengine.org/en/4.6/classes/class_viewport.html#class-viewport-method-push-input).
Wiederholtes `notify_mouse_entered()` erzeugt im aktuellen Testhelper eine
benannte Warnung; alle Assertions und Exitcodes sind grün. Nach Beginn
der finalen gemeinsamen Matrix bleibt der Quellstand eingefroren.

## Native Bilder, Grenzen und Übergabe

Beide Verifier unterstützen optional `--ux-output=<absoluter Ordner>`.
Bei echtem DisplayServer speichern sie neue Root-Viewport-PNGs und JSON-
Metadaten für das berechtigte EVAC-Detailfenster unmittelbar vor dem echten
Klick beziehungsweise den nativen Abbruchbericht. Im Headlessmodus wird
kein Bild gespeichert. Debrief verwendet nur für diese native Captureoption
den Root-Viewport; der normale Contracttest behält seinen SubViewport.

Die Ground-Start-Fixture verwendet den vorhandenen Setup-Schalter vor
`ready`, setzt ihre LZ über den regulären LZ-Eingabepfad und patcht keine
Actorpositionen, HP, Transfers oder Timer. Der Authority-Wechsel ist ein
ausdrücklicher Contracttest. Das belegt technische Bedienbarkeit und
Ownergrenzen, keine physische Evakuierungsreise, menschliches Auffinden,
Spielspaß, allgemeine Performance oder Release-Freigabe.

Root übernimmt die frische gemeinsame Matrix, native Captures/Sichtprüfung,
Normalroute und abschließende Main-Integration. In diesem UX-Slice wurden
keine Godot-Prozesse gestartet, kein Branch gewechselt und kein Commit oder
Push ausgeführt. `git diff --check` ist sauber. Offene Schlussgates werden
im Gesamtauftrag mit ihren tatsächlich gewonnenen Belegen nachgetragen.
