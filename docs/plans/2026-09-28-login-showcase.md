---
title: "Login-Showcase für Storybook und Widgetbook"
date: 2026-09-28
---

# Login-Showcase für Storybook und Widgetbook

## Ziel und Freigabegrenze

Showcase → Login → Assetry steht in beiden Galerien bereit. Die bestehende
Assetry-Anmeldung ist die visuelle Vorlage. Eine gemeinsame Fixture-ID
`showcase-login-assetry` verbindet die Web- und Flutter-Ausführung.
Der Nutzer wählte Rapid für die Galerie und am 28.09.2026 die kurze Planung der
notwendigen Flutter-API-Erweiterung. Diese Datei ist ein Regular-Entwurf;
Implementierungsfreigabe und visuelle Abnahme stehen aus.

## Befund und Entscheidung

Web-KInput unterstützt bereits native Passwortfelder. Flutter-KInput reicht
kein obscureText an sein TextField weiter. Daher wird dem vorhandenen KInput
ein optionales `obscureText` (Standard false) hinzugefügt. Im Passwortmodus sind
Autokorrektur und Vorschläge deaktiviert. Der Wert bleibt im Controller erhalten;
die Darstellung ist verdeckt. Standard-Eingaben und KSearchField bleiben gleich.
Keine zusätzliche PasswordInput- oder LoginScreen-Paketkomponente, kein neuer
Token und keine Änderung der Architektur; ein separates ADR ist nicht nötig.

## Umsetzung

1. Flutter-KInput additiv erweitern und mit einem Widget-Test Maskierung,
   unveränderten Controllerwert und normales Standardverhalten prüfen.
2. Web- und Flutter-Galerie um Showcase → Login → Assetry ergänzen. Texte,
   zweispaltiges Desktoplayout und einspaltiges schmales Layout von Assetry
   übernehmen. Vorhandene K-Komponenten und Token nutzen. Assetry-Branding ist
   ein isolierter Showcase-Override; gemeinsame Standardtokens bleiben gleich.
3. Anmelden und Passwort vergessen lösen ausschließlich lokale Demo-Rückmeldungen
   aus. Leere Pflichtfelder werden angezeigt; keine Netzwerk-Anmeldung, kein
   Logging oder Persistieren von Eingaben und keine echten Zugangsdaten.
4. Beide laufenden Galerien neben der unveränderten Assetry-Seite in drei
   Codex-Browser-Tabs öffnen und Desktop/Mobil sowie Tastaturbedienung prüfen.

## Erlaubte Pfade und Verantwortung

Ein Agent integriert sequentiell im Submodule-Branch `codex/login-showcase`.
Erlaubt: packages/flutter/k_design_ui/lib/src/forms/k_input.dart, dessen Tests,
apps/storybook/src für die neue Fixture und deren Styles/Tests,
apps/widgetbook/lib für Fixture und Navigationsregistrierung, passende
Widgetbook-Tests sowie diese Dokumentation. Keine neuen Dependencies,
Auth-Backend-Änderungen, Anpassungen generierter Dateien oder Übernahme neuer
Bibliotheks-APIs in Assetry vor visueller Abnahme. Commit, Push und Merge sind
nicht Teil dieser Freigabe.

## Prüfung und Abnahme

- Flutter-Test für Passwortmodus und Standardinput; Flutter analyze.
- Widgetbook-Test für Pflichtfelder, maskiertes Passwort und Demo-Rückmeldung.
- Storybook-Typecheck und dieselben Interaktionen im Codex-Browser.
- Responsive Prüfung bei 375 und mindestens 1024 Pixeln, keine Überläufe;
  Labels, Fokusreihenfolge, Enter-Submit und Linkbedienung prüfen.
- Abschließendes `pnpm verify` gemäß Designsystem-AGENTS.md; keine blinde
  Baseline-Aktualisierung. Bekannte oder neue Warnungen/Fehler benennen und gemäß
  Nutzerregel stoppen, keine stillen Ausnahmen. Die früheren Assetry-Worker-
  Sourcemap-/punycode-Warnungen und der HTML-Stringvergleich bleiben ein separater
  offener Consumer-Befund.
- Human Acceptance erfolgt anhand der beiden Galerien; keine echte Anmeldung
  und kein Backend-Sicherheitstest Bestandteil dieses Showcases.

## Bereits vorbereitet

Submodule sauber von master a58611ca7589ec1a07cc7f4d90ad9771cf29cc13 auf
codex/login-showcase verzweigt, ohne Implementierungsänderungen. Storybook
gestartet auf Port 6006; Widgetbook-Start auf 6007 angestoßen.

## Nächster Schritt

Human Plan Approval für „Login-Showcase für Storybook und Widgetbook“, dann
Schritte 1–4 umsetzen, prüfen und zur visuellen Abnahme bereitstellen.
