# Übersetzungen

`en.po` enthält die englische Übersetzung im gettext-Format (mit Poedit bearbeitbar). Sie steckt als Ressource `LANG_EN` in der EXE (Projektoptionen → Ressourcen), es gibt also keinen lang-Ordner neben dem Programm.

- Das Programm ist auf Deutsch geschrieben. Jeder sichtbare Text steht als `resourcestring` in `src/uMain.pas` und läuft beim Anzeigen durch `_()` aus `src/uLang.pas`. `msgid` ist der deutsche Originaltext, `msgstr` die Übersetzung.
- Fehlt eine Übersetzung oder ist sie als `fuzzy` markiert, erscheint der deutsche Text.
- Neuer Text im Programm: `resourcestring` in `uMain.pas` anlegen, mit `_()` verwenden und hier in `en.po` übersetzen. Beschriftungen aus `uMain.lfm` werden in `ApplyLanguage` gesetzt.
- Die englische LED-Info liegt in `src/info/led-info-en.html` (Ressource `LEDINFO_EN`).
- Logik darf sich nie auf übersetzten Text stützen, nur auf den Sprachcode (`LangCode`).
