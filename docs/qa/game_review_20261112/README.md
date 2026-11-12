# Spielreview und Regressionen — 12.11.2026

## Arbeitsbasis / Ergebnis
Godot4.6.2, Ausgangspunkt `cfddc129b` auf noch nicht integriertem Kampagnen-
und Hexplanstand. Eigener Branch `task/game-review-fixes-20261112`.
Final: **26/26 ausgewählte Runtimechecks bestanden**, keine Script-/Runtime-
oder Leakwarnungen in deren finalen Läufen. Zusammengeführt mit Herkunftspfaden
in `final_checks.json`; keine allgemeine Releasefreigabe.
Zwei echte Mehrschiff-Ownerfehler und irreführende Szenenslot-Beschriftungen
behoben. Bestehendes fremdes Terrain-/Shader-/Playtest-WIP erhalten.
Mobilbericht: `../../reports/SPIELREVIEW_2026_11_12.html`.

## Änderungen und Nachweise
- `multicraft/README.md`: zwei Produktfixes, ROT und finale vier Regressionen
  mit147Assertions; synthetisch vorbereiteter validierter Vierpersonenzustand,
  reale Continue-Szenen, reale Controls, Bewegung und Flugkommandos.
- `shell-red/20261112T224315Z-pid55656`: vier erwartete UI-Verhaltensfehler,
  acht bestandene Prüfungen, keine Enginefehler. `shell-green` und finaler
  `broad`-Shellcheck: korrigierte Beschriftungen und13Assertions einschließlich
  weiterlaufender Physik bei ESC/Einstellungen. Hauptmenü kann sich nicht als
  laufende Mission merken. Keine neue Mission-State-Savefunktion implementiert.
- `combat_audit.md`: aktive Boden-Combat-/RNG-/Hex-/Multiplayerpfade,
  bewusste Legacygrenzen und separate deterministische Orbitalbegegnung.
- `broad/20261112T224505Z-pid12628`:16Checks;14direkt grün, zwei eigentlich
  assertiongrüne Verifier wegen falsch gewähltem Runner-Erfolgsmarker rot.
  `followup` wiederholt genau diese beiden mit ihren wirklichen Markern:
  Hexbewegung25/0, HPA332/0. Keine Produktassertion dafür angepasst.
- `followup/20261112T224635Z-pid15408`: zusätzlich echter ENet-RPC-Transport31/0,
  Raumbegegnung, Skirmish97/0 und Kampagnen-Handoff. Chain54/0 war nur wegen
  falschem Marker rot; korrekt wiederholt in
  `final/20261112T225039Z-pid56488/metadata/report.json`.
- `campaign_boarding_diagnostic.md`: initialer echter Fünf-Ausflüge-Verifier
  erkannte abgeschlossenes Boarding wegen noch leerem Piloten-ID-Cache nicht.
  Roter/grüner Diagnosevergleich beweist den Fixturefehler, nur Testcode geändert.
  Vollständiger Wiederholungslauf unter
  `campaign-verified/20261112T225406Z-pid56764/metadata/report.json`:
  **230Assertions, 0Fehler**, fünf reale Aufträge, Heimkehr/Uploads,
  Rekruten/Pad/Schiff und vier Personen/zwei Schiffe nach echtem Continue.
  Headless bei4x Simulationsgeschwindigkeit, kein menschlicher Playtest.

## Reproduzieren
Alle Spieltests wurden mit separater APPDATA innerhalb dieses QA-Ordners
ausgeführt. Originale Spielerprofile wurden weder geladen noch überschrieben.
Das neue Mehrschiff-/Diagnosescript verweigert unisolierte Ausführung.

```powershell
$env:APPDATA = 'C:\dev\SternenBuergerchen\docs\qa\game_review_20261112\broad-profiles'
python C:\Users\bjoer\.codex\skills\godot-game-verification\scripts\run_checks.py --project . --godot godot_console.exe --manifest docs/qa/game_review_20261112/broad_checks.json --skip-import --output docs/qa/game_review_20261112/broad
```

Runner verlangt Exit0, Erfolgsmarker, eingehaltenes Zeitlimit und keine
Script-/Runtime-/Leakfehler. JSON-Reports enthalten Logpfade/Fehlerliste/Zeiten.
Ein vorheriger Import liegt in `import.log`/`import-godot.log`: Exit0, jedoch
ObjectDB-Leakwarnung beim Editorende nach Plugin-Unload (Ursache offen). Das wird
ausdrücklich nicht als sauberer Import-PASS bezeichnet. Runtimegates separat.

## Berichtprüfung
`build_report.py` leitet die selbständige HTML-Datei vom Repositorytemplate ab,
übernimmt dessen lokalen JSON-Export und liest die finalen Runnerreports.
`verify_report.cjs` prüft einen privaten headless Chrome per `file://`, offline,
bei320/390/768/1440px alle Tabs auf Breitenüberlauf, JSON-Download mit Checkbox,
Select, Umlauten, Notizen und sichtbarem Textfallback.39Assertions grün.
`mobile_verification.json`, `report_mobile_390.png`; keine Desktopsteuerung.
Keine externen Skript-/Font-/Netzwerkabhängigkeiten des Berichts.

## Aussagegrenzen / nächste sinnvolle Arbeiten
- Kein menschlicher Komplettplaytest, keine Stil-/GPU-/allgemeine FPSfreigabe.
- Echter lokaler ENet-Test nutzt zwei Multiplayer-Subtrees und kleine Units,
  keine vollständige Zwei-Rechner-Lobby-/Missionspartie oder Internet/NAT-Test.
- Hexsicht/Feld-/Kantenreservierungen AP0–AP8 sind nach aktuellem Stand geplant,
  nicht durch diesen Review als fertig erklärt. AreaOrder ist Zielschablone;
  orbitaler Kampf verwendet feste Hüllenschäden, keinen Boden-Damage-RNG.
- Natürliche Buccaneer ist Fighter. Der frühe Reviewtext über ihren zuvor
  möglichen Truppabflug war zu weit; zulässiger zweiter Transport und bestehende
  Fighter-Sperre werden ausdrücklich getrennt geprüft.
- Checkpoint-JSON-Aufbereitung alle250ms ist Profilingkandidat ohne gemessenen
  neuen FPSgewinn. Native UI-/Grafikprüfung und Netz-Latenz/Verlust bleiben offen.
- Temporärer SetThreadExecutionState-Prozess verhindert Standby während des
  Auftrags ohne permanente Änderung der Energieeinstellungen; nach Abschluss
  beendet. Unveränderte rohe Engine-Logs behalten originale nachlaufende
  Leerzeichen; Quell-/Doku-Whitespaceprüfung schließt ausschließlich diese
  Rohlogs aus.
