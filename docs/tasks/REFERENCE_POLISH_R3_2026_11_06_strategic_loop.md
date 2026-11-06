# R3: lokaler Next-Loop-Readout im Strategic-RAW

## Ziel / bestaetigter Befund
Untertask zu `REFERENCE_POLISH_R3_2026_11_06.md`. Der aktuelle Strategic-RAW-
Builder ruft Loop-two-Line und Polish-Line im aktiven Combat-Zweig und ohne
CONTACT-FIRE-Fruehrueckgabe nochmals danach auf. Beide Helfer lesen ohne
Override ihren gesamten Next-Loop-Snapshot neu. Dessen First-Decision-/Visual-
Polish-Quelle ist nicht durch die vorhandene Firefight-Projektion abgedeckt.
Damit entstehen zwei bis vier gleichartige Quellaufbauten in einer synchronen
RAW-Assembly. Dies ist ein Codebefund, noch keine Millisekundenmessung.

## Enger Entwurf / Nicht-Ziele
Nur innerhalb eines Strategic-RAW-Aufrufs den bestehenden Next-Loop-Snapshot
und die beiden daraus abgeleiteten Zeilen teilen. Keine neue gespeicherte
Gameplay-/UI-Wahrheit, kein zeitlicher oder persistenter Cache, kein Weglassen
von versteckten Contracts. Der erste Quellaufbau muss unter dem bestehenden
HUD- oder Polish-Build-Depth-Guard stattfinden. Sind beide bereits aktiv,
bleiben beide Zeilen leer, ohne eine neue ungeschuetzte Quellabfrage.
Die bestehenden expliziten Helfer, ihre Overrides und Guard-Semantik bleiben
fuer andere Aufrufer erhalten. Gleiches Ergebnis und Guard-Evidenz haben vor
einer moeglichen Teilzeitreduktion Vorrang.

## Akzeptanz
- Eine gueltige Strategic-RAW-Assembly liest ihren Next-Loop-Snapshot hoechstens
  einmal; beim bestehenden beidseitigen Guard gar nicht. Ein zweiter eigener
  RAW-Aufruf muss selbst wieder frisch lesen.
- Normaler Zustand, aktives Combat ohne Kontakt, CONTACT-FIRE-Fruehrueckgabe
  und die drei Guardkombinationen behalten byte-identischen RAW-Text gegen
  dieselben realen Helfer mit dem vorherigen ungekuerzten Quellfallback.
- Die Quellabfrage laeuft unter einem bestehenden Build-Depth-Guard; geschuetzte
  rekursive Helferaufrufe bleiben blockiert und erzeugen keine Rekursion.
  Nach jedem Durchlauf sind alle vorherigen Guard-Tiefen wiederhergestellt.
- Commands, Effects, Actorpositionen/Vitaldaten, Planowner und Tick bleiben
  unveraendert. Explizite Source-/Text-Overrides und Legacy-Helfer bleiben nutzbar.
- Produkt beginnt erst nach Roots fokussiertem echten RED; final folgen
  Nachbargates, unabhaengiges Review und native normale1x-/Kamera34-Messung.

## Dateien / Besitz
Controller: `scripts/tests/mission_tactical_sandbox_controller.gd`, nur lokaler
Strategic-Readout und dazu notwendiger schmaler Guard-Helfer. Neuer Verifier:
`scripts/tests/reference_polish_r3_20261106_strategic_loop_verifier.gd`.
Root besitzt alle Engine-/Git-Schritte und gibt Produkt nach echtem RED frei.

## Pruefung / Grenzen
Der Verifier verwendet die reale Missionsszene und deren echte Next-Loop-
Getter. Kontrollierte Combat-Anzeigeinputs ergaenzen reine Branchfixtures;
sie erzeugen weder Kontakt noch Feuer oder physisches Spiel. Die alte
Helfer-Fallbackroute bleibt das RAW-Text-Orakel. Komponenten-GREEN ist kein
FPS-, Multiplayer-, Main- oder Releasebeweis. Alte QA und Saves bleiben erhalten.

## Dokumente / Risiko
AGENTS, Haupttask, HUD-Projection-Authority-Contract und Command-Feedback-
Contract gelten weiter. Hauptgefahr ist ein vor die bisherigen Rekursions-
Guards gezogener Quellaufbau oder ein ueber mehrere Assemblies behaltener
Fallback. Beides muss der fokussierte Verifier erkennen. Status: nur AC/Test,
noch keine Produktfreigabe oder bestandenes RED/GREEN behauptet.

## Nachweis / Stand
Root bestaetigte echtes RED unter
`output/reference_polish_r3_20261106/strategic_loop_red/20261106T232439Z-2f475508`:
63 bestanden, 12 erwartete Fehlschlaege, Enginefehler0/stabile Quellen.
Quellaufrufe waren real4, NoCombat2, CombatNoContact4, ContactEarly2,
HudGuard2 und PolishGuard2 statt jeweils1; beide Guards blockierten korrekt0.
RAW-Orakel und Reentry-Guards stimmten bereits vollstaendig.
Danach gab Root den engen Produktpatch frei. Strategic-RAW teilt nun einen
lokalen Readout mit seinen beiden Zeilen. Der erste Quellaufbau steht unter
dem vorhandenen verfuegbaren HUD-/Polish-Depth-Guard; die vorherigen Tiefen
werden vor der Ausgabe wiederhergestellt. Leere Quellen bleiben leer.
Quellen und Verifier sind fuer Roots serielles GREEN eingefroren, ohne dass
dieser Task bereits bestandene Gegenmessung oder Mainintegration behauptet.

Root-GREEN ist gegen das echte Log geprueft:
`strategic_loop_green/20261106T232654Z-14b2f7ba` unter derselben Ausgabebasis,
55 bestanden,0 fehlgeschlagen, Exit0/Enginefehler0/stabile Quellen.
Alle sechs nicht vollstaendig blockierten Faelle lesen exakt eine Quelle;
beide Guards aktiv lesen0. RAW ist in jedem Fall identisch, Tiefen und
Reentry-Sperren bleiben erhalten, die naechste Assembly liest wieder frisch.
Die Zahl einzelner Assertions sinkt von75 auf55, weil der Check seine zwei
Guardpruefungen fuer jeden tatsaechlichen Quellaufruf wiederholt; die mehrfachen
Aufrufe entfallen jetzt. Kein Testfall wurde entfernt.
Quellen bleiben eingefroren. Native Teilzeitgewinne sind weiterhin ein
getrennter, von Root auszufuehrender Nachweis.

Finale Freeze-Bindung nach dem separat freigegebenen Primary-/GO-Polishpass:
Controller SHA256
`2434f55be706c284c9838e4c58aa76ed45624d6ddfe43e730e7cf25b9c9b8235`,
Next-Loop-Verifier SHA256
`ff5dd5162121954e77e6755dc0979467f21b971643d504a0db7cbc71a6516563`.
Root fuehrt den aktuellen Gesamtstand noch durch40 Regressionen und zwei
native90-s-Vergleiche; Quellen/Verifier bleiben waehrenddessen unveraendert.
