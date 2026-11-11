# Einfache Erfahrungs-Vorlagen fuer eigene Teams

Problem: Punkte-Rekrutierung ist bereits dreistufig; der persoenliche Teameditor
forderte sofort viele Kern-/Verhaltens-/Fahrzeugwerte. Default ist jetzt die
vorhandene kompakte read-only Charakteransicht. Einzelwerte bearbeiten schaltet
den unveraenderten Experteneditor zu. Auswahl allein schreibt nichts. Erst
Vorlage anwenden setzt die bestehenden Faehigkeitsgruppen und nutzt die
bisherige Punkteprofilfunktion plus DerivedMath-/Roster-Speicherweg.
Identitaet, Traits, Rolle, Ausruestung, Zuordnung und Fortschritt bleiben.

Geaendert: main_menu_screen.gd, skirmish_start_configuration.gd, neuer kleiner
Datenfixture und Task. Keine alternative Preiswahrheit; im eigenen Team wird
hier kein Kauf behauptet. Interne8Kernwerte/5Verhaltensachsen bleiben erhalten.

Jetzt nur check-only exit0 und ein In-memory-Datenfixture163/0 ohne Warnung/
Engine-/Scriptfehler. Der Fixture beruehrt keine Nutzerdateien. Kein nativer
Klick-, Layout-, Save/Continue-, Gefechts- oder Performance-PASS. Diese Pruefungen
sind auf ausdruecklichen Nutzerwunsch verschoben. Kein Commit/Push durchAgent.

Bewusster Aufbau auf unintegriertem task/native-glut-maps-20261110. Andere
Agenten bearbeiten Terrain und Forschung getrennt; dieser Teil aendert keine
Kampf-/Sicht-/Hexreservierungsregeln des parallel besprochenen Tabletopplans.
