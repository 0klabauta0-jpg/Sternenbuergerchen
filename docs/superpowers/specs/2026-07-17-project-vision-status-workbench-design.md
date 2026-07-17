# Project Vision And Status Workbench Design

## Ziel

Der Report erklaert die Spielidee von `SternenBuergerchen`, ordnet den aktuellen Projektstand ehrlich ein und zeigt eine belastbare Richtung fuer die weitere Entwicklung. Er soll fuer den Projektinhaber als Arbeitsgrundlage funktionieren und zugleich fuer Aussenstehende verstaendlich und motivierend sein.

## Zielgruppe und Ton

- Primaer: Projektinhaber und Entwickler, die Entscheidungen und naechste Schritte festhalten wollen.
- Sekundaer: interessierte Spieler, Mitentwickler und externe Leser ohne Kenntnis der Task-Historie.
- Ton: klar, zuversichtlich und konkret, aber ohne Marketing-Uebertreibung oder unbelegte Fertigstellungsbehauptungen.

## Informationsarchitektur

Der Report folgt einem Commander-Briefing mit sieben Hauptbereichen:

1. **Spielidee**: Commander-Rolle, Fireteam-Hierarchie, Echtzeit-Taktik und Meta-Layer.
2. **Spielerreise**: Heimatbasis, Team und Loadout, Dropship, Einsatz, Ziel, Debrief und Entwicklung.
3. **Bereits umgesetzt**: belastbare Systeme und sichtbare Spielerpfade, getrennt nach Evidenzstufe.
4. **Teilweise umgesetzt**: funktionierende, aber noch nicht voll ausgereifte oder abschliessend sichtgepruefte Bereiche.
5. **Muss und kann**: Pflichtarbeit fuer ein ueberzeugendes Spiel getrennt von spaeteren Erweiterungen.
6. **GPT-5.6**: konkrete Verbesserungen der Entwicklungsarbeit im Vergleich zu frueheren Modellgenerationen.
7. **Naechste Schritte**: priorisierte Etappen mit lokal editierbaren Entscheidungen und Notizen.

## Evidenzmodell

Der Report unterscheidet sichtbar zwischen:

- **Implementiert und verifiziert**: durch aktuelle Verifier, Release- oder Playthrough-Belege abgesichert.
- **Implementiert im Arbeitsstand**: vorhanden, aber nicht zwingend als vollstaendiger Spielerpfad abgenommen.
- **Teilweise / weiter zu schaerfen**: spielbar oder technisch angelegt, aber mit erkennbarem Produkt-, Content-, Balance- oder UX-Bedarf.
- **Vision / Option**: sinnvoll denkbar, jedoch nicht als bestehende Funktion dargestellt.

Task-Nummern dienen als Belegdetails und nicht als primaere Erzaehlung. Der Report fasst den Stand nach Spielerwirkung zusammen.

## Visuelles Design

- Dunkle, kontrastreiche taktische Arbeitsoberflaeche mit neutralem Graphit, gebrochenem Weiss, Signalgruen, warmem Amber und sparsamem Rot.
- Keine Marketing-Landingpage und keine dekorativen Kartenstapel. Hauptbereiche sind breite, klare Baender; Karten werden nur fuer wiederholte Status- oder Prioritaetselemente eingesetzt.
- Eine kompakte Missionslinie visualisiert den Core Loop ohne externe Assets oder SVG-Illustration.
- Typografie und Abstaende bleiben bei Desktop und Mobile lesbar; Controls erhalten stabile Groessen und sichtbare Fokuszustaende.
- Der erste Viewport zeigt Spielname, Kernidee, aktuellen Reifegrad und den Einstieg in den Core Loop.

## Workbench-Funktionen

Die Seite wird von `docs/reports/_html_workbench_template.html` abgeleitet und funktioniert direkt per `file://` ohne externe Abhaengigkeiten.

- Tab- oder Ankernavigation zwischen den Hauptbereichen.
- Filter fuer Evidenzstufen und Pflicht-/Optionsarbeit.
- Editierbare Prioritaeten, Statusentscheidungen und Notizen.
- Lokale Persistenz im Browser fuer Arbeitsnotizen.
- Sichtbarer Button `JSON exportieren` mit Download- und Textfeld-Fallback.
- Optionaler JSON-Import setzt nur Workbench-Felder und erzeugt keine Gameplay-Wahrheit.
- Export nach `sternenbuergerchen.html_workbench.v1` mit eindeutiger Report-ID.

## GPT-5.6-Darstellung

Die GPT-5.6-Sektion beschreibt Verbesserungen als Arbeitsfaehigkeiten, nicht als Garantie:

- laengere Repo- und Task-Ketten konsistenter zusammenfassen;
- Architekturgrenzen und vorhandene Contracts verlaesslicher respektieren;
- End-to-End-Spielerpfade samt Verifiern gezielter reproduzieren;
- Godot-, UI-, Multiplayer- und Performancebefunde besser miteinander verbinden;
- visuelle Pruefung und technische Evidenz sauberer auseinanderhalten;
- Aufgaben kleiner schneiden und Fortschritt nachvollziehbarer dokumentieren.

Sie benennt weiterhin die Grenzen: menschliche Spielentscheidung, Geschmack, Balancegefuehl und Priorisierung bleiben beim Projektinhaber; Verifier ersetzen keinen echten Playtest.

## Nicht-Ziele

- Keine Aenderung an Runtime, Gameplay, Balancing oder UI des Spiels.
- Keine neue verbindliche Roadmap und keine Umnummerierung bestehender Tasks.
- Keine Behauptung, dass alle dokumentierten Systeme produktionsreif sind.
- Keine externen Webfonts, Skripte, Bilder oder Serverabhaengigkeiten.

## Pruefung

- Statischer Check auf Pflichtbereiche, Export-Schema und `JSON exportieren`.
- Browser-Smoke per lokalem `file://`: Navigation, Filter, Notizen, Persistenz, Export und Import.
- Screenshots bei Desktop und Mobile zur Kontrolle von Ueberlagerungen, Textfluss und erstem Viewport.
- `git diff --check` und Kontrolle, dass fremde ungetrackte Dateien unberuehrt bleiben.

