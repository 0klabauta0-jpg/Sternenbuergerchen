# UI-Referenzen und Revisionen

Dies sind externe Vorlagen und KI-Entwürfe, keine Aufnahmen der Implementation.
Die tatsächliche Umsetzung wird separat nativ gerendert und verglichen.

## Offizielle Inspiration

- RSI, How to Quantum Travel, Stand 12.06.2025:
  https://support.robertsspaceindustries.com/hc/en-us/articles/360019449994-How-to-Quantum-Travel
  Die geöffnete native Sternkarte zeigt links Zielsuche/-informationen, rechts
  Aufträge und unten Appnavigation. Im Produkt übernehmen wir die klare
  Funktionshierarchie und ergänzen den gewünschten System-/Mondbaum.
  Bilder rsi_starmap_2025.png und rsi_route_2025.png.
- RSI, Design Notes: mobiGlas, 31.01.2015:
  https://robertsspaceindustries.com/en/comm-link/engineering/14466-Design-Notes-MobiGlas
  Historische Konzepte mit technischen Linien, zurückhaltender Palette und
  eingebetteter Geräteidentität. Keine Behauptung über den heutigen Spielstand.
  Bilder rsi_mobiglas_concept_2015.jpg und rsi_starmap_concept_2015.jpg.

## Bild-KI

Built-in image_gen, 13.11.2026. Originale unter dem vom Werkzeug gemeldeten
Codex-generated_images-Pfad erhalten; Kopien hier im Repository.
Exakte Prompts: concept_v1_prompt.txt, concept_v2_prompt.txt und concept_v3_prompt.txt.

- kursbuch_smart_mobile_concept_v1.png: erster Entwurf, nicht ausgewählt;
  Nutzer verlangt kompaktere Leisten, Knöpfe und RTS-Informationsdichte.
- kursbuch_smart_mobile_concept_v2_compact.png: zweite Richtung für schmalere
  Navigation, Zeilen, dezente Primäraktion und weniger Rahmen. Die farbigen
  Orts-/Auftragsbilder bleiben ausdrücklich gewünscht. Revision 3 ergänzt diese
  Richtung um den tatsächlichen Ist-Stand und ist die aktuelle Bildreferenz.

Die gezeigten Beträge, Zeiten, Shortcuts, Beispielmission Ankunft und die
Satellitenillustration sind Entwurfsinhalt, keine neuen Spielregeln/Assets.
Bestehende native Bilder, Daten und Bindings bleiben maßgeblich. Kein
Screenshot-Slicing der RSI-Controls, kein generiertes UI als Vollbildtextur.

Technik und Akzeptanz: docs/dev/starmap_smart_mobile_contract.md.

## Revision 3 mit echtem Ist-Stand

Auf Nutzerwunsch erhielt die Bild-KI zusätzlich die tatsächlichen nativen Bilder
ui_starmap_fuel_range.png, ui_job_app_footer.png und personnel_details.png aus
review_completion_20261113 sowie V2 als Richtung. Exacte Eingaben:
concept_v3_prompt.txt und sources.json. Ausgabe:
kursbuch_smart_mobile_concept_v3_native.png.

Diese Revision erhält die vorhandenen farbigen Icons/Personen und das Basisfenster,
statt eine andere Spielwelt zu erfinden. Native Inputbilder bleiben Ist-Nachweise;
das neue Ergebnis bleibt ein KI-Zielbild. Die doppelt generierten Schiffs-/Fuel-
Controls und ungenauen Körperbeschriftungen werden ausdrücklich NICHT übernommen.
Tatsächliche Körperpositionen, Parent-IDs, Werte und Bindings kommen aus dem Spiel.
