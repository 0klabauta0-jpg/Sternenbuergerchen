# Native UI-Umsetzung R2 · 01.11.2026

## Ziel / Problem und Ursache
Der Nutzer beauftragt einen weiteren Pass näher an den bestätigten Bild-KI-Vorlagen sowie eine Prüfung von Logik und Funktion. R1 vereinheitlicht Theme und Controls; einige Screenfamilien behalten jedoch große Leerflächen und zu wenig Inhaltshierarchie. Der Quellenvergleich zeigt zusätzlich verlorene Löschziel-Markierung, unbeschriftete Audioregler und Fokusverlust bei Bibliotheksauswahl.

## Basis / Umfang / Nicht-Ziele
- Branch `task/ui-umsetzung-r2-20261101` von `integration/core-foundation` gestartet und bewusst bis zum noch nicht integrierten R1-Commit `80593f416` vorgezogen. Der Hauptcheckout bleibt unberührt.
- Mission: kompakte Team-/Parametergruppe, verständliche Haltung und Feuerregel, Diagnose erreichbar halten und vorhandene Command-Gates/Markierungen erhalten.
- Heimatbasis/FOB: kompakte Briefings, sichtbare Arbeitsbereiche für Personen, Teams und Transport; vorhandene Auswahl-, Zuweisungs-, Transit- und Detailpfade erhalten.
- Debrief: vorhandene Snapshotdaten als gegliederte Ergebnis-/Personen-/Ereigniskarten. Keine erfundenen Auszeichnungen oder Zeitachsen.
- Settings/Bibliothek: beschriftete Audiowerte und stabiler Tastaturfokus bei Auswahl.
- Abschließender Sichtbefund Lobby: angeschnittene Host-Zeile und unter dem Scrollfalz liegende Kernaktionen durch begrenzte Setupfläche und erreichbare Aktionsgruppen korrigieren; bestehende Netzwerk-/Bereitschaftsgates bleiben erhalten.
- Erzeugung/Speichern eines regulären Teams prüfen; einen bestätigten angrenzenden Validierungswiderspruch nur im bestehenden Datenvertrag beheben, ohne Balanceänderung.
- Keine neuen Gameplay-Owners, Netzwerkprotokolle, Simulationsregeln, Pause, Einzel-NPC-Steuerung oder Hauptbranch-Integration. Vorhandene Lobby-Transport-Stubs als Grenze dokumentieren, nicht als funktionierend ausgeben.

## Relevante Dokumente / Verträge
`docs/dev/ui_native_design_contract.md`, `docs/ui_concepts/ui_20261101/MENUES_UND_KARTEN.md`, `BILDPRUEFUNG_REVISION5.md`, bestehende Shell-/Read-only-/Transport-/Feuerregelverträge sowie Architektur und Codex-Regeln.

## Akzeptanzkriterien
1. Echte native Ansichten zeigen eine kompaktere Hierarchie entsprechend den bestätigten Vorlagen; bestehende Funktionen bleiben erreichbar.
2. Mission zeigt bestätigte Auswahl/Feuerregel und Sperren ohne optimistischen Schattenzustand. Fokussierte Löschaktion bleibt erkennbar; unveränderte Refreshes verursachen keine neuen Layoutschreibvorgänge.
3. Basis/FOB erhalten Identität, Signale und autoritative Zuweisung/Transitgrenzen; Charakterdetails bleiben lesend.
4. Debriefkarten lesen ausschließlich vorhandene Daten; leere Daten werden ausdrücklich und ehrlich angezeigt.
5. Audio zeigt Kanal und Wert. Bibliotheksauswahl bleibt mit Tastatur fortsetzbar. Relevante Save-/Cancel-/Navigation-Pfade werden gezielt geprüft.
6. Gezielte Godot-Verifier, echte Viewport-Captures und eine lokal bedienbare HTML-Workbench mit JSON-Export dokumentieren Ergebnis und Grenzen. R1-Nachweise bleiben erhalten.

## Betroffene Dateien / lokale Prüfung
Mission-Layouthelfer und Layoutvertrag; Homebase-/FOB-/Debrief-/Mainmenu-Skripte; gezielte neue bzw. semantisch aktualisierte Verifier. Root koordiniert Engineprüfungen sequenziell. Eigener Nachweisordner `docs/qa/ui_native_r2_20261101/` und eigener nativer HTML-Report.

## Risiken / offene Punkte
Historische Layouttests können absichtlich überholte Positionen erwarten; Funktionsassertions dürfen deshalb nicht entfallen. Sichtprüfung und strukturelle Tests sind getrennte Nachweise. Generierte Teamwerte zeigten in R1 einen Store-Validierungsrandfall; Ursache und Vertragsgrenze sind vor einer Änderung zu belegen. Dies ist ein Entwicklungsstand, kein Release- oder vollständiger Mehrspieler-Nachweis.


## Umsetzungsergebnis / Nachweis
- Die genannten Screenfamilien wurden nativ verdichtet; bestehende Controls und Callbackbesitzer bleiben maßgeblich. Der Layoutvergleich liegt in einer eigenen lokalen Workbench mit 17 echten Aufnahmen, R1-/Konzeptvergleich und vollständigem JSON-Export.
- Die Prüfung reproduzierte und korrigierte Save-Validierung nach Traits, verlorene Aktionsmarkierung, Bibliotheksfokus, unbeschriftete Audioentwürfe, späte Debrief-Sortierungen, FOB-Kontext nach reinem Teamfokus und angeschnittene Lobbyaktionen. Keine neue Gameplay- oder Netzwerk-Wahrheit.
- 27 gezielte Checks mit 1.731 Assertions sind im letzten jeweils akzeptierten Lauf grün; hinzu kommen 17 native Captures und 10 Offline-HTML-Checks. Source-Snapshot, Einzelreports und Hashes: `docs/qa/ui_native_r2_20261101/VERIFIKATION.json`; Ursachen/Grenzen: `FUNKTIONSREVIEW.md` und `README.md` im selben Ordner.
- Alle neuen kompakten Kernflächen wurden bei echter logischer 1920×1080 bzw. 1280×720-Geometrie geprüft. Pending-/Clientgates sind Presenter-/Contractprüfungen, kein echtes Netzwerk-End-to-End. Menschlicher Gesamtklicktest und die bestehende Lobby-Payloadanbindung bleiben offen.
- Integration/Release/EXE-Export sind nicht Teil dieses Tasks. Arbeitsstand baut bewusst auf dem noch nicht integrierten R1 auf.
