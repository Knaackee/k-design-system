# KMapLocationPicker – erster Storybook-Entwurf

Die ausgelieferte Web-Komponente kombiniert KMap mit einer animierten Ortsauswahl:
Auswahl zwischen Adresssuche und Standort, Suchergebnisse, Adress-Pill,
Kamerafahrt, Pin-Ankunft und Hinweis zum Verschieben.

Consumer stellen Suche, Standortermittlung und optional Reverse-Geocoding als
Callbacks bereit. Änderungen werden über onChange gemeldet; eine optionale
Bestätigung über onConfirm. Texte, Hinweis, Blur, Bewegungsdauer, Zielzoom,
Bounce und die KMap-Konfiguration sind anpassbar. Reduced Motion wird beachtet.

Storybook: Maps / Location Picker / Desktop und Mobil.
Die Beispiele verwenden drei feste Berliner Adressen und einen simulierten
Standort. Sie fragen keine echte Standortberechtigung ab.

Verifiziert: Web-Build, Web-Typprüfung, Style-Audit, 17 bestehende UI-Tests und
Storybook-Build erfolgreich. Im Browser wurden Suche, Auswahl, Darstellung von
Pill/Karte/Pin/Hinweis sowie Wiederöffnen geprüft; Desktop und schmale Ansicht
gesichtet. Keine echte Geocoding-Anbindung, keine native Touch- oder Flutter-
Verifikation. Flutter ist ein späterer Schritt.
