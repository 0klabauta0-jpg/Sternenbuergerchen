# AP5 Stop-/Zentrierkern: begrenzte Integration

Quelle d00eba780, Integration fd8ed553a. Unabhaengiger Readonlyreview ohne Blocker; zwei frische check-only-Laeufe fuer SimulationRoot und HexGroundRuntime: Exit0, keine Scriptfehler (Logs neben dieser Datei).

Der Kern gibt zukuenftige Reservierungen mitsamt abhaengiger Routenkette frei und behaelt das aktuelle logische Feld. Die Zentrierphase gilt bis zum festgelegten Tick weiterhin als Bewegung. Geometrie entsteht beim Commit/bei Revision, nicht beim Renderlesen. Zwei Roots bleiben getrennte Owner. Ansicht oder Selektion loesen keinen Stop aus.

Quellchat meldete kleine Kernel-/Projektions-/Reservierungsproben; deren Matrix wurde hier ausdruecklich nicht wiederholt. Dieser Anschluss aktiviert weder Actorbewegung noch Karten. Kein nativer Bewegungs-, Gefechts-, Save-/Netz- oder Performance-Nachweis. Grosse Tests auf Nutzerwunsch spaeter.
