# Weniger sichtbare Erklärungstexte

## Ziel / Ursache
Nutzersteuerung: redundante Erklärungen vergrößern Menüs. Wesentliche
Entscheidungsinformationen bleiben sichtbar, optionale Anleitung in der Hilfe.

## Umfang / Nicht-Ziele
Basis, Sternkarte, Aufträge, Hauptmenü/Teameditor, Lobby, Polisa, Raumbegegnung.
Keine Owner-, Preis-, Missions- oder Bedienregeländerung. Keine pauschale
Löschung von Warnungen, Sperrgründen, Kosten und Auftragszielen.

## Contracts / Akzeptanz
starmap_smart_mobile_contract.md und campaign_save_feedback_contract.md.
Kurze Status-/Aktionsbezeichnungen; bestehende Hover-/Kontexthilfe verwenden.
Keine sichtbaren Implementierungsdetails wie authority= oder Missionswahrheit.
Überschreiben, fehlende Speicherung und reservierte Pads bleiben verständlich.

## Dateien / Prüfung / Risiken
Root: main_menu_screen, multiplayer_lobby_screen, polisa_station_screen,
campaign_space_encounter_presenter. UX-Agent: Basis, Jobpresenter, Sternkarte.
Bestehende Menü-/Lobby-/Service-Verifier und native 720p-/1080p-Ansichten.
Keine neuen Tests, die nur verkürzte Strings wiederholen. Risiko sind zu stark
gekürzte Sperrgründe oder veraltete Hovertexte; konkrete Folgen bleiben sichtbar.
