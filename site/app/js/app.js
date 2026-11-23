/* ==============================================================================
   app.js - Hauptfenster von LedPreResistor (HTML-Version)
   ==============================================================================
   Zweck:     Übertragung von uMain.pas (Windows 2.7): verbindet Eingaben,
              Rechnung (calc.js) und Anzeige. Vier Reiter:
                0 Vorwiderstand, 1 Blinkschaltung, 2 Konstantstrom, 3 Wechselstrom
              Gerechnet wird live bei jeder Eingabe.
   Aufbau:    links Eingaben und LED-Vorschau, rechts Schaltplan und vier
              Karten, darunter Statuszeile (mit Ko-fi) und Rechenweg.
   Tasten:    Strg+1…4 bzw. Alt+1…4 (Reiter), F1 (LED-Info),
              Strg+Umschalt+C (kopieren), Pfeil hoch/runter in Feldern.
   Einstel-   Reiter, Blinkschaltung, Konstantstromquelle, Wechselstrom-
              Schaltung und Sprache im
   lungen:    localStorage des Browsers (wie LedPreResistor.ini).
   Autor:     Elospeed
   Versionen: 2.5.2-html 18.11.2026  erste Fassung (Stand Windows 2.5.2)
              2.7        23.11.2026  Reiter Wechselstrom
   ============================================================================== */
(function () {
  'use strict';
  var L = window.LPR, T = window.LPR_TEXTS, SCH = window.LPRSchem;

  /* ===========================================================================
     KONSTANTEN
     =========================================================================== */
  var APP_VER = '2.7';
  var MAX_U = 60.0, MAX_LEDS = 30, MAX_STRINGS = 20;
  var LED_GLOW = ['#FF2B2B', '#FFD000', '#25E35D', '#2F7DFF', '#FFFFFF', '#9A2A6A'];
  var C = { ok: '#3DDC84', okBack: '#10301E', warn: '#FFCC33', warnBack: '#3A3110', error: '#FF5C5C',
            errorBack: '#3A1414', bright: '#FFFFFF', deep: '#15181C', panel: '#23272E', soft: '#9AA4AE' };
  // Vorgaben der Zeitglied-Felder [Schaltung][rückwärts][Feld] (BLINK_DEFAULTS)
  function blinkDefaults() {
    return { ne555: { f: ['1', '68', '10'], r: ['1', '55', '10'] },
             multi: { f: ['33', '33', '22'], r: ['0,5', '0,5', '22'] } };
  }
  var E12_DIGITS = [10, 12, 15, 18, 22, 27, 33, 39, 47, 56, 68, 82];
  var E6_DIGITS = [10, 15, 22, 33, 47, 68];
  var BLINK_ANIM_MIN_PHASE = 0.05;

  /* ===========================================================================
     ZUSTAND
     =========================================================================== */
  var lang = 'de';
  var mode = 0;
  var reverse = false;
  var rwOpen = true;
  var bTexts = blinkDefaults();
  var circuitShown = 'ne555', reverseShown = false;
  var inp = {}, res = {}, bands = null;              // Vorwiderstand
  var bInp = {}, bRes = {}, bBands1 = null, bBands2 = null;   // Blinkschaltung
  var kInp = {}, kRes = {}, kBands = null, kBandsB = null;    // Konstantstrom
  var aInp = {}, aRes = {}, aBands = null;                    // Wechselstrom
  var blinkTimer = null, blinkStart = 0, ledLit = true, onLevel = 1.0;
  var ledCache = { key: '', on: null, off: null };
  var copiedTimer = null;

  var $ = function (id) { return document.getElementById(id); };

  /* ===========================================================================
     TEXTE (uLang, Format)
     =========================================================================== */
  function _(key) {
    var e = T[key];
    if (!e) return key;
    return lang === 'en' ? e[1] : e[0];
  }
  // Pascal-Format: %s, %d, %% der Reihe nach ersetzen
  function fmt(s) {
    var args = Array.prototype.slice.call(arguments, 1), i = 0;
    return s.replace(/%(%|s|d)/g, function (m, c) {
      if (c === '%') return '%';
      var a = args[i++];
      return c === 'd' ? String(Math.trunc(a)) : String(a);
    });
  }
  function esc(s) { return String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;'); }
  // Text mit «**fett**» und «_X» (tiefgestellt) als HTML (uRichText)
  function rich(s) {
    var out = '', bold = false, chars = Array.from(String(s));
    for (var i = 0; i < chars.length; i++) {
      var ch = chars[i];
      if (ch === '*' && chars[i + 1] === '*') { out += bold ? '</b>' : '<b class="bb">'; bold = !bold; i++; continue; }
      if (ch === '_' && i < chars.length - 1) { out += '<sub>' + esc(chars[i + 1]) + '</sub>'; i++; continue; }
      out += esc(ch);
    }
    if (bold) out += '</b>';
    return out;
  }
  // RichPlain: «**» weg, «_X» -> «X»
  function richPlain(s) { return String(s).replace(/\*\*/g, '').replace(/_(.)/g, '$1'); }
  // KeepUnits: geschützte Leerschläge zwischen Zahl und Einheit, um «→» und «=»
  function keepUnits(s) {
    var c = Array.from(s), out = '';
    for (var i = 0; i < c.length; i++) {
      var ch = c[i];
      if (ch === ' ') {
        var prev = i > 0 ? c[i - 1] : '', next = i < c.length - 1 ? c[i + 1] : '';
        if (next === '→' || prev === '→' || next === '=' || prev === '=') { out += ' '; continue; }
        if (/[0-9¼½¾⅛]/.test(prev) && next && !/[0-9 ]/.test(next)) { out += ' '; continue; }
        if ((prev === '>' || prev === '<' || prev === '≈') && /[0-9]/.test(next)) { out += '\u00a0'; continue; }
      }
      out += ch;
    }
    return out;
  }

  var F = L; // Formatierer: F.formatVolt usw.
  function seriesName(s) { return ['E12', 'E24', 'E96'][s]; }
  function bandNames(b, sep) {
    var keys = ['rsBlack', 'rsBrown', 'rsRed', 'rsOrange', 'rsYellow', 'rsGreen', 'rsBlue', 'rsViolet', 'rsGrey', 'rsWhite', 'rsGold', 'rsSilver'];
    return (b || []).map(function (x) { return _(keys[x]); }).join(sep);
  }
  function currentLed() { var i = $('comboColor').selectedIndex; return i < 0 ? 4 : i; }
  function ledColorName() {
    return _(['rsLedNameRed', 'rsLedNameYellow', 'rsLedNameGreen', 'rsLedNameBlue', 'rsLedNameWhite', 'rsLedNameInfrared'][currentLed()]);
  }
  function exactStd(line, ser, ideal, std) {
    if (std > 0 && Math.abs(ideal - std) <= 1e-6 * std) return line.replace(fmt(_('rsNextUp'), ser), fmt(_('rsExactStd'), ser));
    return line;
  }
  function mixColor(c, back, a) {
    function p(h, i) { return parseInt(h.substr(1 + 2 * i, 2), 16); }
    var r = [0, 1, 2].map(function (i) { return Math.round(p(c, i) * a + p(back, i) * (1 - a)); });
    return '#' + r.map(function (v) { return ('0' + v.toString(16)).slice(-2); }).join('').toUpperCase();
  }
  function elkoVoltText(Cf, U) {
    var V = [6.3, 10, 16, 25, 35, 50, 63, 80, 100];
    if (Cf < 1e-6 * 0.999 || !(U > 0)) return '';
    for (var i = 0; i < V.length; i++) if (V[i] >= U * 1.2) return '/' + F.formatNum(V[i], 1, 0) + ' V';
    return '';
  }
  function baseSubText(ov) {
    return ov < 1 ? fmt(_('rsBCardBaseSubLow'), F.formatNum(ov, 1, 1), Math.round(L.BJT_BETA))
                  : fmt(_('rsBCardBaseSub'), F.formatNum(ov, 1, 1), Math.round(L.BJT_BETA));
  }
  function currentSubText(R, RCalc, I) {
    if (F.formatOhm(R) === F.formatOhm(RCalc)) return fmt(_('rsCardCurrentSubExact'), F.formatMilliAmp(I));
    return fmt(_('rsCardCurrentSub'), F.formatOhm(R), F.formatOhm(RCalc), F.formatMilliAmp(I));
  }

  /* ===========================================================================
     EINSTELLUNGEN (localStorage, Fehler werden still übergangen)
     =========================================================================== */
  function readSetting(k, def) {
    try { var v = localStorage.getItem('lpr.' + k); return v === null ? def : v; } catch (e) { return def; }
  }
  function writeSetting(k, v) { try { localStorage.setItem('lpr.' + k, String(v)); } catch (e) { /* egal */ } }

  /* ===========================================================================
     AUSWAHLLISTEN
     =========================================================================== */
  function fillSelect(sel, keys) {
    var idx = sel.selectedIndex;
    sel.innerHTML = keys.map(function (k) { return '<option>' + esc(_(k)) + '</option>'; }).join('');
    if (idx >= 0) sel.selectedIndex = idx;
  }
  function fillCombos() {
    fillSelect($('comboColor'), ['rsLedRed', 'rsLedYellow', 'rsLedGreen', 'rsLedBlue', 'rsLedWhite', 'rsLedInfrared']);
    fillSelect($('comboSeries'), ['rsSeriesE12', 'rsSeriesE24', 'rsSeriesE96']);
    fillSelect($('comboCircuit'), ['rsCircuit555', 'rsCircuitMulti']);
    fillSelect($('comboConn'), ['rsConnGnd', 'rsConnVcc', 'rsConnBoth']);
    fillSelect($('comboKsq'), ['rsKsqLM317', 'rsKsqTrans']);
    fillSelect($('comboAc'), ['rsAcSimple', 'rsAcBridge']);
  }
  function isMulti() { return $('comboCircuit').selectedIndex === 1; }

  /* ===========================================================================
     LINKE SPALTE ANORDNEN (LayoutLeft)
     =========================================================================== */
  function row(cls, items) {
    var r = document.createElement('div');
    r.className = 'row' + (cls ? ' ' + cls : '');
    items.forEach(function (id) { r.appendChild($(id)); });
    return r;
  }
  function layoutLeft() {
    var box = $('leftRows'), pool = $('pool');
    while (box.firstChild) pool.appendChild(box.firstChild);
    var blink = mode === 1, ksq = mode === 2, ac = mode === 3, is555 = !isMulti();
    var add = function (el) { box.appendChild(el); };
    $('labelColor').style.display = mode === 0 ? '' : 'none';
    $('fSeries').classList.toggle('k', ksq);
    add($('headInputs'));
    if (ksq) {
      add(row('full', ['fKsq']));
      add($('headSupply'));
      add(row('', ['fU', 'fU2']));
      add($('headLed'));
      add(row('full', ['fColor']));
      add(row('', ['fUd', 'fI']));
      add(row('', ['fSeries', 'fN']));
    } else if (ac) {
      add(row('full', ['fAc']));
      add(row('', ['fU', 'fSeries']));
      add($('headLed'));
      add(row('full', ['fColor']));
      add(row('', ['fUd', 'fI']));
      add(row('', ['fN']));
    } else if (!blink) {
      add(row('', ['fU', 'fSeries']));
      add(row('full', ['fColor']));
      add(row('', ['fUd', 'fI']));
      add(row('', ['fN', 'fStrings']));
    } else {
      add(row('full', ['fCircuit']));
      add(row('', ['fU', 'fSeries']));
      add($('headTiming'));
      add(row('full', ['fMode']));
      add(row('three', ['fT1', 'fT2', 'fT3']));
      add(row('full check-row', [is555 ? 'fDiode' : 'fSym']));
      add($('headLed'));
      add(row('full', ['fColor']));
      add(row('', ['fUd', 'fI']));
      if (is555) add(row('full', ['fConn']));
    }
    // Feld «LEDs in Reihe»: im Vorwiderstand links, im Konstantstrom rechts
    $('editN').parentNode.parentNode.querySelector('input').style.width = '';
    document.body.classList.toggle('mode-blink', blink);
  }

  /* Beschriftungen, die vom Reiter abhängen (ModeCaptions, UpdateTimingLabels) */
  function modeCaptions() {
    $('headInputs').textContent = mode === 0 ? _('rsHeadInputs') : _('rsHeadCircuit');
    $('labelU').textContent = mode === 2 ? _('rsLabelFrom') : (mode === 3 ? _('rsLabelTrafo') : _('rsLabelU'));
    $('unitU').textContent = mode === 3 ? 'V~' : 'V';
    // Wechselstrom einfach (Halbwelle): das Feld ist der Spitzenstrom
    $('labelI').textContent = (mode === 3 && $('comboAc').selectedIndex === 0) ? _('rsLabelIPeak') : _('rsLabelI');
    updateTimingLabels();
  }
  function updateTimingLabels() {
    var is555 = !isMulti();
    if (reverse && !is555) {
      $('labelT1').textContent = _('rsLabelLed1'); $('unitT1').textContent = 's'; $('editT1').dataset.step = '100';
      $('labelT2').textContent = _('rsLabelLed2'); $('unitT2').textContent = 's'; $('editT2').dataset.step = '100';
    } else if (reverse) {
      $('labelT1').textContent = _('rsLabelFreq'); $('unitT1').textContent = 'Hz'; $('editT1').dataset.step = '100';
      $('labelT2').textContent = _('rsLabelDuty'); $('unitT2').textContent = '%'; $('editT2').dataset.step = '1000';
    } else {
      $('labelT1').textContent = is555 ? 'R1' : 'RB1';
      $('labelT2').textContent = is555 ? 'R2' : 'RB2';
      $('unitT1').textContent = 'kΩ'; $('unitT2').textContent = 'kΩ';
      $('editT1').dataset.step = '-1'; $('editT2').dataset.step = '-1';
    }
    $('labelT3').textContent = 'C'; $('unitT3').textContent = 'µF'; $('editT3').dataset.step = '-2';
    $('headLed').textContent = (mode === 2 || mode === 3) ? _('rsHeadLeds') : (is555 ? _('rsHeadLed') : _('rsHeadLeds'));
    $('modeParts').textContent = _('rsModeParts');
    $('modeRev').textContent = is555 ? _('rsModeFreq') : _('rsModeTimes');
    $('modeParts').classList.toggle('on', !reverse);
    $('modeRev').classList.toggle('on', reverse);
  }
  function storeTimingTexts() {
    var t = bTexts[circuitShown][reverseShown ? 'r' : 'f'];
    t[0] = $('editT1').value; t[1] = $('editT2').value; t[2] = $('editT3').value;
  }
  function loadTimingTexts() {
    circuitShown = isMulti() ? 'multi' : 'ne555';
    reverseShown = reverse;
    var t = bTexts[circuitShown][reverse ? 'r' : 'f'];
    $('editT1').value = t[0]; $('editT2').value = t[1]; $('editT3').value = t[2];
    updateTimingLabels();
    syncSymmetric();
  }
  function syncSymmetric() {
    var sym = isMulti() && $('checkSym').checked;
    $('editT2').disabled = sym;
    if (sym && $('editT2').value !== $('editT1').value) $('editT2').value = $('editT1').value;
  }

  /* ===========================================================================
     RECHNEN (Recalc, RecalcBlink, RecalcKsq)
     =========================================================================== */
  function recalc() {
    var v;
    inp = { U: 0, Ud: 0, I: 0, N: 0, series: 0, ratingW: L.RATING_REFERENCE, strings: -1 };
    v = L.parseDecimal($('editU').value); if (v !== null && v <= MAX_U) inp.U = v;
    v = L.parseDecimal($('editUd').value); if (v !== null) inp.Ud = v;
    v = L.parseDecimal($('editI').value); if (v !== null) inp.I = v / 1000;
    v = L.parseDecimal($('editN').value);
    inp.N = (v !== null && v % 1 === 0 && v >= 1 && v <= MAX_LEDS) ? Math.round(v) : 0;
    inp.series = Math.max(0, $('comboSeries').selectedIndex);
    v = L.parseDecimal($('editStrings').value);
    inp.strings = (v !== null && v % 1 === 0 && v >= 1 && v <= MAX_STRINGS) ? Math.round(v) : -1;
    res = L.calculate(inp);
    bands = res.status === 'ok' ? L.colorBands(res.std, inp.series) : null;
    recalcBlink();
    recalcKsq();
    recalcAc();
    paintAll();
  }

  function recalcBlink() {
    var v, t1 = 0, t2 = 0;
    bInp = { circuit: isMulti() ? 'multi' : 'ne555', reverse: reverse, R1: 0, R2: 0, C: 0, F: 0, duty: 0,
             diode: false, conn: 'gnd', U: inp.U, Ud: inp.Ud, I: inp.I, series: inp.series };
    if (reverse && bInp.circuit === 'multi') {
      v = L.parseDecimal($('editT1').value); t1 = v !== null ? v : 0;
      v = L.parseDecimal($('editT2').value); t2 = v !== null ? v : 0;
      if (t1 > 0 && t2 > 0) { bInp.F = 1 / (t1 + t2); bInp.duty = t1 / (t1 + t2); }
    } else if (reverse) {
      v = L.parseDecimal($('editT1').value); if (v !== null) bInp.F = v;
      v = L.parseDecimal($('editT2').value); if (v !== null) bInp.duty = v / 100;
    } else {
      v = L.parseDecimal($('editT1').value); if (v !== null) bInp.R1 = v * 1e3;
      v = L.parseDecimal($('editT2').value); if (v !== null) bInp.R2 = v * 1e3;
    }
    v = L.parseDecimal($('editT3').value); if (v !== null) bInp.C = v * 1e-6;
    if (bInp.circuit === 'ne555') {
      bInp.diode = $('checkDiode').checked;
      bInp.conn = ['gnd', 'vcc', 'both'][Math.max(0, $('comboConn').selectedIndex)];
    } else bInp.conn = 'both';
    bRes = L.calculateBlink(bInp);
    bBands1 = bBands2 = null;
    if (bRes.status === 'ok') {
      bBands1 = L.colorBands(bRes.led1.std, bInp.series);
      if (bRes.led2.used) bBands2 = L.colorBands(bRes.led2.std, bInp.series);
    }
    if (mode === 1) updateBlink();
  }

  function recalcKsq() {
    var v;
    kInp = { circuit: $('comboKsq').selectedIndex === 1 ? 'trans' : 'lm317', UMin: inp.U, UMax: 0,
             Ud: inp.Ud, I: inp.I, N: inp.N, series: inp.series };
    v = L.parseDecimal($('editU2').value);
    if (v !== null && v > 0) { if (v <= MAX_U) kInp.UMax = v; else kInp.UMin = 0; }
    kRes = L.calculateKsq(kInp);
    kBands = kBandsB = null;
    if (kRes.status === 'ok') {
      kBands = L.colorBands(kRes.std, kInp.series);
      if (kInp.circuit === 'trans') kBandsB = L.colorBands(kRes.RBStd, kInp.series);
    }
  }

  /* Wechselstrom (RecalcAc): Trafospannung direkt aus dem Feld, Grenze 42 V~
     prüft calculateAc; LED-Werte wie im Reiter «Vorwiderstand» */
  function recalcAc() {
    var v;
    aInp = { circuit: $('comboAc').selectedIndex === 1 ? 'bridge' : 'simple', U: 0,
             Ud: inp.Ud, I: inp.I, N: inp.N, series: inp.series };
    v = L.parseDecimal($('editU').value); if (v !== null) aInp.U = v;
    aRes = L.calculateAc(aInp);
    aBands = aRes.status === 'ok' ? L.colorBands(aRes.std, aInp.series) : null;
    if (mode === 3) updateBlink();
  }

  /* ===========================================================================
     FEHLERTEXTE
     =========================================================================== */
  function statusText(s) {
    switch (s) {
      case 'invalidU': return fmt(_('rsErrU'), F.formatVolt(MAX_U));
      case 'invalidUd': return _('rsErrUd');
      case 'invalidI': return _('rsErrI');
      case 'invalidN': return fmt(_('rsErrN'), MAX_LEDS);
      case 'uTooLow': {
        var t = fmt(_('rsErrUTooLow'), F.formatVolt(inp.U), inp.N, F.formatVolt(inp.Ud), F.formatVolt(inp.N * inp.Ud));
        var maxN = Math.ceil(inp.U / inp.Ud - 1e-9) - 1;
        if (maxN > 1) t += fmt(_('rsErrUTooLowMaxN'), maxN);
        else if (maxN === 1) t += _('rsErrUTooLowMax1');
        else t += _('rsErrUTooLowNoLed');
        return t;
      }
      case 'noStdValue': return _('rsErrNoStd');
      case 'invalidStrings': return fmt(_('rsErrStrings'), MAX_STRINGS);
    }
    return '';
  }
  function blinkStatusText(s) {
    var multi = bInp.circuit === 'multi';
    switch (s) {
      case 'invalidU': return fmt(_('rsErrU'), F.formatVolt(MAX_U));
      case 'invalidUd': return _('rsErrUd');
      case 'invalidI': return _('rsErrI');
      case 'invalidR1': return multi ? _('rsErrBRB1') : _('rsErrBR1');
      case 'invalidR2': return multi ? _('rsErrBRB2') : _('rsErrBR2');
      case 'invalidC': return _('rsErrBC');
      case 'invalidF': case 'invalidDuty':
        if (multi) return _('rsErrBTimes');
        return s === 'invalidF' ? _('rsErrBF') : _('rsErrBDuty');
      case 'dutyNeedsDiode': return _('rsErrBDiode');
      case 'supply555': return _('rsErrBSupply555');
      case 'current555': return _('rsErrBCurrent555');
      case 'multiVoltage': return _('rsErrBMultiU');
      case 'multiCurrent': return _('rsErrBMultiI');
      case 'uTooLow': {
        var avail = multi ? bInp.U - L.BJT_UCE_SAT : (bInp.conn === 'vcc' ? bInp.U - L.NE555_LOW : bInp.U - L.NE555_DROP_HIGH);
        return fmt(_('rsErrBUTooLow'), F.formatVolt(Math.max(0, avail)), F.formatVolt(bInp.Ud));
      }
      case 'noStdValue': return _('rsErrNoStd');
    }
    return '';
  }
  function ksqStatusText(s) {
    switch (s) {
      case 'invalidU': return fmt(_('rsErrU'), F.formatVolt(MAX_U));
      case 'invalidUd': return _('rsErrUd');
      case 'invalidI': return _('rsErrI');
      case 'invalidN': return fmt(_('rsErrN'), MAX_LEDS);
      case 'tooMuchCurrent': return _('rsErrKCurrent');
      case 'overVoltage': return kInp.circuit === 'lm317' ? _('rsErrKVoltL') : _('rsErrKVoltT');
      case 'uTooLow': return fmt(_('rsErrKUTooLow'), F.formatVolt(kRes.UMin), F.formatVolt(kRes.UNeed));
      case 'noStdValue': return _('rsErrNoStd');
    }
    return '';
  }

  function acLedVolt() {
    return aInp.N > 1 ? aInp.N + ' × ' + F.formatVolt(aInp.Ud) : F.formatVolt(aInp.Ud);
  }
  function acRatingText(w) { return w > 0 ? F.formatRating(w) : _('rsCardRatingNone'); }
  function acStatusText(s) {
    switch (s) {
      case 'invalidU': return fmt(_('rsErrAU'), F.formatVolt(L.AC_U_MAX));
      case 'overVoltage': return fmt(_('rsErrAUMax'), F.formatVolt(L.AC_U_MAX));
      case 'revTooHigh': return fmt(_('rsErrARev'), F.formatNum(aRes.IRevPeak, 1, 1) + ' A', F.formatNum(L.AC_I_REV_MAX, 1, 0) + ' A');
      case 'invalidUd': return _('rsErrUd');
      case 'invalidI': return _('rsErrI');
      case 'invalidN': return fmt(_('rsErrN'), MAX_LEDS);
      case 'tooMuchCurrent': return _('rsErrACurrent');
      case 'uTooLow': return fmt(_('rsErrAUTooLow'), F.formatVolt(aInp.U), acLedVolt(), F.formatVolt(Math.ceil(aRes.UNeedAc * 10) / 10));
      case 'noStdValue': return _('rsErrNoStd');
    }
    return '';
  }

  /* ===========================================================================
     SCHALTPLAN
     =========================================================================== */
  /* Handy: Schaltplan auf die gezeichneten Teile zuschneiden, damit die Schrift
     auf dem schmalen Bildschirm grösser wird. Auf dem PC bleibt die Vorlage. */
  function fitSchemForPhone(el) {
    var svg = el.querySelector('svg');
    if (!svg) return;
    var phone = window.matchMedia('(max-width: 760px)').matches;
    if (!svg.dataset.vb) svg.dataset.vb = svg.getAttribute('viewBox');
    if (!phone) { svg.setAttribute('viewBox', svg.dataset.vb); el.style.aspectRatio = ''; return; }
    var b;
    try { b = svg.getBBox(); } catch (e) { return; }
    if (!b || b.width < 10 || b.height < 10) return;
    var pad = 6;
    svg.setAttribute('viewBox', [b.x - pad, b.y - pad, b.width + 2 * pad, b.height + 2 * pad].map(Math.round).join(' '));
    el.style.aspectRatio = Math.round(b.width + 2 * pad + 32) + ' / ' + Math.round(b.height + 2 * pad + 32);
  }

  function paintSchematic() {
    var el = $('schem'), svg, wide = false;
    var dash = '–';
    if (mode === 0) {
      var V = { LedColor: LED_GLOW[currentLed()], LedCount: inp.N, StringCount: inp.strings };
      var name = ledColorName();
      V.UBText = 'U_B = ' + (inp.U > 0 ? F.formatVolt(inp.U) : dash);
      if (inp.N > 1) { V.LedText = fmt(_('rsSchemLedN'), inp.N, name); V.UFText = fmt(_('rsSchemUFN'), inp.N, F.formatVolt(inp.Ud)); }
      else { V.LedText = fmt(_('rsSchemLed'), name); V.UFText = fmt(_('rsSchemUF'), F.formatVolt(inp.Ud)); }
      if (inp.strings > 1) {
        V.String1Text = _('rsSchemString1');
        V.StringLastText = inp.strings === 2 ? _('rsSchemString2') : fmt(_('rsSchemStringN'), inp.strings);
      }
      if (res.status === 'ok') {
        V.RText = 'R = ' + F.formatOhm(res.R);
        V.URText = 'U_R = ' + F.formatVolt(res.UR);
        V.IText = 'I = ' + F.formatMilliAmp(res.IAct);
        V.Bands = bands;
        if (res.strings > 1) {
          V.StringsText = fmt(_('rsSchemStrings'), res.strings);
          V.IStringText = fmt(_('rsSchemIString'), F.formatMilliAmp(res.IAct));
          V.IText = fmt(_('rsSchemITotal'), F.formatMilliAmp(res.ITotal), res.strings, F.formatMilliAmp(res.IAct));
        }
      } else { V.RText = 'R = ' + dash; V.URText = 'U_R = ' + dash; V.IText = 'I = ' + dash; }
      svg = SCH.resistor(V);
    } else if (mode === 1) {
      svg = blinkSchematic(); wide = true;
    } else if (mode === 2) {
      svg = ksqSchematic(); wide = true;
    } else {
      svg = acSchematic(); wide = true;
    }
    el.innerHTML = svg;
    el.classList.toggle('wide', wide);
    el.querySelector('svg').style.inset = mode === 0 ? '20px' : '16px';
    el.querySelector('svg').style.width = 'calc(100% - ' + (mode === 0 ? 40 : 32) + 'px)';
    el.querySelector('svg').style.height = 'calc(100% - ' + (mode === 0 ? 40 : 32) + 'px)';
    fitSchemForPhone(el);
  }

  function blinkSchematic() {
    var dash = '–', ok = bRes.status === 'ok', multi = bInp.circuit === 'multi';
    var V = {}, R1 = ok ? bRes.R1 : bInp.R1, R2 = ok ? bRes.R2 : bInp.R2;
    function ohmOr(x) { return x > 0 ? F.formatOhm(x) : dash; }
    V.UBText = 'U_B = ' + (bInp.U > 0 ? F.formatVolt(bInp.U) : dash);
    if (multi) {
      V.R1Text = 'R_B_1 = ' + ohmOr(R1);
      V.R2Text = 'R_B_2 = ' + ohmOr(R2);
      if (bInp.C > 0) {
        V.CText = 'C1 = ' + F.formatCap(bInp.C) + elkoVoltText(bInp.C, bInp.U);
        V.C2Text = 'C2 = ' + F.formatCap(bInp.C) + elkoVoltText(bInp.C, bInp.U);
      } else { V.CText = 'C1 = ' + dash; V.C2Text = 'C2 = ' + dash; }
      V.Led1Text = _('rsLed1'); V.Led2Text = _('rsLed2');
      V.T1Text = 'T1 BC547'; V.T2Text = 'T2 BC547';
    } else {
      V.R1Text = 'R1 = ' + ohmOr(R1);
      V.R2Text = 'R2 = ' + ohmOr(R2);
      V.CText = bInp.C > 0 ? 'C = ' + F.formatCap(bInp.C) + elkoVoltText(bInp.C, bInp.U) : 'C = ' + dash;
      if (bInp.conn === 'both') { V.Led1Text = _('rsLed1'); V.Led2Text = _('rsLed2'); }
      else V.Led1Text = fmt(_('rsSchemLed'), ledColorName());
      if (!ok) V.UOutText = 'U_O_U_T = ' + dash;
      else if (bInp.conn === 'vcc') V.UOutText = 'Low ≈ ' + F.formatVolt(L.NE555_LOW);
      else if (bInp.U > 0) V.UOutText = 'U_O_U_T ≈ ' + F.formatVolt(bInp.U - L.NE555_DROP_HIGH);
    }
    if (ok) {
      if (multi || bInp.conn === 'both') {
        V.RV1Text = 'R_V_1 = ' + F.formatOhm(bRes.led1.R);
        V.RV2Text = 'R_V_2 = ' + F.formatOhm(bRes.led2.R);
      } else V.RV1Text = 'R_V = ' + F.formatOhm(bRes.led1.R);
      V.Bands1 = bBands1; V.Bands2 = bBands2;
    } else if (multi || bInp.conn === 'both') { V.RV1Text = 'R_V_1 = ' + dash; V.RV2Text = 'R_V_2 = ' + dash; }
    else V.RV1Text = 'R_V = ' + dash;
    V.LedColor = LED_GLOW[currentLed()];
    V.LedOff = mixColor(V.LedColor, C.deep, 0.22);
    if (blinkTimer) { V.Led1Lit = ledLit; V.Led2Lit = !ledLit; } else { V.Led1Lit = true; V.Led2Lit = true; }
    V.Diode = bInp.diode;
    V.BaseDiodes = multi && ok && bRes.baseDiode;
    V.Conn = bInp.conn;
    V.Elko = bInp.C >= 1e-6 * 0.999;
    return multi ? SCH.multi(V) : SCH.ne555(V);
  }

  function ksqVoltRange() {
    return kRes.UMax > kRes.UMin ? F.formatNum(kRes.UMin, 2, 0) + ' … ' + F.formatVolt(kRes.UMax) : F.formatVolt(kRes.UMin);
  }
  function ksqLedVolt() {
    return kInp.N > 1 ? kInp.N + ' × ' + F.formatVolt(kInp.Ud) : F.formatVolt(kInp.Ud);
  }
  function ksqSchematic() {
    var dash = '–', ok = kRes.status === 'ok', V = {}, name = ledColorName();
    V.UBText = 'U_B = ' + (kRes.UMin > 0 ? ksqVoltRange() : dash);
    V.ChipText = (ok && kRes.part === 'LM317L') ? 'LM317L' : 'LM317';
    V.RefText = lang === 'en' ? 'U_R_E_F = 1.25 V' : 'U_R_E_F = 1,25 V';
    V.RText = kInp.circuit === 'lm317' ? 'R = ' : 'R_S = ';
    if (ok) {
      V.RText += F.formatOhm(kRes.R);
      V.RSubText = 'I = ' + F.formatMilliAmp(kRes.IAct);
      V.RBText = 'R_B = ' + F.formatOhm(kRes.RB);
      V.T1Text = 'T1 ' + kRes.part;
      V.Bands = kBands; V.BandsB = kBandsB;
    } else {
      V.RText += dash; V.RSubText = 'I = ' + dash; V.RBText = 'R_B = ' + dash; V.T1Text = 'T1';
    }
    V.T2Text = 'T2 BC547';
    if (kInp.N > 1) { V.LedText = fmt(_('rsSchemLedN'), kInp.N, name); V.UFText = fmt(_('rsSchemUFN'), kInp.N, F.formatVolt(kInp.Ud)); }
    else { V.LedText = fmt(_('rsSchemLed'), name); V.UFText = fmt(_('rsSchemUF'), F.formatVolt(kInp.Ud)); }
    V.LedCount = kInp.N;
    V.LedColor = LED_GLOW[currentLed()];
    V.LedOff = mixColor(V.LedColor, C.deep, 0.22);
    return kInp.circuit === 'lm317' ? SCH.lm317(V) : SCH.ksqT(V);
  }

  function acSchematic() {
    var dash = '–', ok = aRes.status === 'ok', V = {}, name = ledColorName();
    V.UText = 'U = ' + (aInp.U > 0 ? F.formatVolt(aInp.U) + '~' : dash);
    if (ok) {
      V.UPeakText = 'Û = ' + F.formatVolt(aRes.UPeak);
      V.RText = 'R = ' + F.formatOhm(aRes.R);
      V.RSubText = aInp.circuit === 'simple' ? 'Î = ' + F.formatMilliAmp(aRes.IPeak) : 'I = ' + F.formatMilliAmp(aRes.IAct);
      V.DiodeText = 'D ' + aRes.diode;
      V.CapText = 'C = ' + F.formatCap(aRes.C);
      V.CapSubText = F.formatVolt(aRes.CVolt);
      V.UDcText = 'U_D_C = ' + F.formatVolt(aRes.UDc);
      V.Bands = aBands;
    } else {
      V.RText = 'R = ' + dash; V.RSubText = ''; V.DiodeText = 'D'; V.CapText = 'C = ' + dash;
    }
    V.DiodeSubText = _('rsACardDiode');
    V.BridgeText = 'B80C1500';
    if (aInp.N > 1) { V.LedText = fmt(_('rsSchemLedN'), aInp.N, name); V.UFText = fmt(_('rsSchemUFN'), aInp.N, F.formatVolt(aInp.Ud)); }
    else { V.LedText = fmt(_('rsSchemLed'), name); V.UFText = fmt(_('rsSchemUF'), F.formatVolt(aInp.Ud)); }
    V.LedCount = aInp.N;
    V.LedColor = LED_GLOW[currentLed()];
    V.LedOff = mixColor(V.LedColor, C.deep, 0.22);
    return aInp.circuit === 'simple' ? SCH.acSimple(V) : SCH.acBridge(V);
  }

  /* ===========================================================================
     KARTEN
     =========================================================================== */
  function card(title, value, sub, color, extra) {
    return '<div class="card"><div class="ct">' + esc(title) + '</div><div class="cv" style="color:' + (color || C.bright) + '">' +
      esc(value) + '</div>' + (sub ? '<div class="cs">' + esc(keepUnits(sub)) + '</div>' : '') + (extra || '') + '</div>';
  }
  function resistorPic(b, sub2) {
    if (!b) return '';
    return '<div class="res">' + SCH.resistorSvg(b, 150, 22) + '</div>';
  }
  function paintCards() {
    var el = $('cards'), h = '';
    el.classList.toggle('res', mode === 0);
    if (mode === 1) h = blinkCards();
    else if (mode === 2) h = ksqCards();
    else if (mode === 3) h = acCards();
    else {
      var ok = res.status === 'ok', title0 = fmt(_('rsCardStd'), seriesName(inp.series));
      if (ok) {
        var rings = bandNames(bands, ' · ');
        h += card(title0, F.formatOhm(res.R), '', C.bright,
          resistorPic(bands) + '<div class="rings">' + esc(rings) + '</div>');
      } else h += card(title0, '–', '', C.bright);
      if (ok && res.strings > 1) h += card(_('rsCardCurrent'), F.formatMilliAmp(res.IAct), fmt(_('rsCardCurrentSubStrings'), res.strings, F.formatMilliAmp(res.ITotal)));
      else if (ok) h += card(_('rsCardCurrent'), F.formatMilliAmp(res.IAct), currentSubText(res.R, res.RCalc, inp.I));
      else h += card(_('rsCardCurrent'), '–', '');
      if (ok && res.strings > 1) h += card(_('rsCardPower'), F.formatPower(res.PR), fmt(_('rsCardPowerSubStrings'), res.strings));
      else if (ok) h += card(_('rsCardPower'), F.formatPower(res.PR), _('rsCardPowerSub'));
      else h += card(_('rsCardPower'), '–', '');
      if (ok) {
        var lvl = L.loadLevelOf(res.load), vc = lvl === 'ok' ? C.ok : (lvl === 'warning' ? C.warn : C.error);
        var bar = '<div class="bar"><i style="width:' + (Math.min(1, res.load) * 100).toFixed(2) + '%;background:' + vc + '"></i><b></b></div>';
        if (res.recommendedW === 0) h += card(_('rsCardRating'), _('rsCardRatingNone'), _('rsCardRatingNoneSub'), C.error, bar);
        else if (lvl === 'ok') h += card(_('rsCardRating'), F.formatRating(res.recommendedW), fmt(_('rsCardRatingSubOk'), F.formatRating(res.refW), F.formatPercent(res.load)), vc, bar);
        else h += card(_('rsCardRating'), F.formatRating(res.recommendedW), fmt(_('rsCardRatingSub'), F.formatRating(res.refW), F.formatPercent(res.load)), vc, bar);
      } else h += card(_('rsCardRating'), '–', '');
    }
    el.innerHTML = h;
    fitCardValues();
  }
  // grosser Wert passt sich der Kartenbreite an (15 pt bis 9 pt)
  function fitCardValues() {
    var cvs = document.querySelectorAll('.card .cv');
    for (var i = 0; i < cvs.length; i++) {
      var cv = cvs[i], size = 20;
      cv.style.fontSize = '';
      while (size > 12 && cv.scrollWidth > cv.clientWidth + 0.5) { size -= 1; cv.style.fontSize = size + 'px'; }
    }
  }

  function blinkCards() {
    var ok = bRes.status === 'ok', two = bInp.circuit === 'multi' || bInp.conn === 'both', h = '', sub, t, vc;
    function pair(a, b) {
      if (a >= 0.1 && b >= 0.1) return F.formatSig(a, 3) + ' / ' + F.formatSig(b, 3) + ' s';
      return F.formatSeconds(a) + ' / ' + F.formatSeconds(b);
    }
    // 0: Frequenz
    if (ok) {
      vc = C.bright;
      sub = two ? fmt(_('rsBCardFreqSubAlt'), F.formatSeconds(bRes.T)) : fmt(_('rsBCardFreqSub'), F.formatSeconds(bRes.T));
      if (bRes.warnings.indexOf('tooFast') >= 0) { vc = C.warn; sub = _('rsBCardFreqFast'); }
      h += card(_('rsBCardFreq'), F.formatFreq(bRes.F), sub, vc);
    } else h += card(_('rsBCardFreq'), '–', '');
    // 1: Zeiten mit kleinem Rechteck-Signal
    t = two ? _('rsBCardTimesMulti') : _('rsBCardTimes');
    if (ok) {
      var wave = '';
      if (bRes.duty1 > 0) {
        var d = bRes.duty1 * 50, wc = mixColor(LED_GLOW[currentLed()], C.panel, 0.85), pts = [];
        for (var k = 0; k < 2; k++) {
          var x0 = k * 50;
          pts.push(x0 + ',16', x0 + ',0', (x0 + d) + ',0', (x0 + d) + ',16', (x0 + 50) + ',16');
        }
        wave = '<div class="wave"><svg viewBox="0 0 100 16" preserveAspectRatio="none"><polyline points="' + pts.join(' ') +
          '" fill="none" stroke="' + wc + '" stroke-width="1.6" vector-effect="non-scaling-stroke"/></svg></div>';
      }
      h += card(t, pair(bRes.TOn1, bRes.TOff1), '', C.bright, wave);
    } else h += card(t, '–', '');
    // 2: Basisstrom (Multivibrator) bzw. Tastgrad (NE555)
    if (bInp.circuit === 'multi') {
      if (ok) {
        vc = (bRes.warnings.indexOf('notSaturated') >= 0 || bRes.warnings.indexOf('baseReverse') >= 0) ? C.warn : C.ok;
        h += card(_('rsBCardBase'), F.formatMilliAmp(bRes.IB), baseSubText(bRes.overdrive), vc);
      } else h += card(_('rsBCardBase'), '–', '');
    } else if (ok) {
      sub = bInp.conn === 'vcc' ? _('rsBCardDutySubVcc') : (bInp.diode ? _('rsBCardDutySubDiode') : _('rsBCardDutySub'));
      t = bInp.conn === 'both' ? _('rsBCardDuty1') : _('rsBCardDuty');
      h += card(t, F.formatPercent1(bRes.duty1), sub);
    } else h += card(_('rsBCardDuty'), '–', '');
    // 3: Vorwiderstand
    t = fmt(_('rsBCardRv'), seriesName(bInp.series));
    if (ok) {
      var v, diff = bRes.led2.used && !L.sameValue(bRes.led1.R, bRes.led2.R);
      if (diff) v = F.formatOhm(bRes.led1.R) + ' / ' + F.formatOhm(bRes.led2.R);
      else if (bRes.led2.used) v = '2 × ' + F.formatOhm(bRes.led1.R);
      else v = F.formatOhm(bRes.led1.R);
      var P = Math.max(bRes.led1.P, bRes.led2.P), rating = L.recommendRating(P);
      var rt = rating > 0 ? F.formatRating(rating) : _('rsCardRatingNone');
      if (diff) sub = fmt(_('rsBCardRvSub2'), F.formatMilliAmp(bRes.led1.IAct), F.formatMilliAmp(bRes.led2.IAct), F.formatPower(P), rt);
      else sub = fmt(_('rsBCardRvSub'), F.formatMilliAmp(bRes.led1.IAct), F.formatPower(bRes.led1.P), rt);
      h += card(t, v, sub);
    } else h += card(t, '–', '');
    return h;
  }

  function ksqPartText() {
    var n = kRes.part;
    if (kRes.warnings.indexOf('tooHot') >= 0) return fmt(_('rsKPartTooHot'), n);
    if (kRes.warnings.indexOf('heatsink') >= 0) return fmt(_('rsKPartHeatsink'), n, String(Math.floor(kRes.heatsinkRth)));
    if (kRes.part === 'LM317L') return _('rsKPartLM317L');
    if (kRes.part === 'LM317') return _('rsKPartLM317');
    return fmt(_('rsKPartFree'), n);
  }
  function formatPowerRange(p1, p2) {
    if (Math.abs(p2 - p1) <= 0.005 * Math.max(Math.abs(p2), 1e-9)) return F.formatPower(p2);
    if (p2 >= 1) return F.formatNum(p1, 2, 0) + ' … ' + F.formatNum(p2, 2, 0) + ' W';
    return F.formatNum(p1 * 1000, 1, 1) + ' … ' + F.formatNum(p2 * 1000, 1, 1) + ' mW';
  }
  function ksqCards() {
    var ok = kRes.status === 'ok', lm = kInp.circuit === 'lm317', h = '', t, sub, vc;
    t = fmt(_('rsKCardR'), seriesName(kInp.series));
    if (ok) {
      sub = fmt(_('rsKCardRSub'), bandNames(kBands, ' · '), kRes.RRating > 0 ? F.formatRating(kRes.RRating) : _('rsCardRatingNone'), F.formatPower(kRes.PR));
      h += card(t, F.formatOhm(kRes.R), '', C.bright, resistorPic(kBands) + '<div class="rings">' + esc(keepUnits(sub)) + '</div>');
    } else h += card(t, '–', '');
    if (ok) {
      if (!lm) sub = fmt(_('rsKCardISubT'), F.formatMilliAmp(kInp.I), F.formatPercent(-L.KSQ_UBE_TC * 10 / L.KSQ_UBE_SENSE));
      else if (kRes.UMax > kRes.UMin) sub = fmt(_('rsKCardISubL'), F.formatMilliAmp(kInp.I), F.formatVolt(kRes.UMin), F.formatVolt(kRes.UMax));
      else sub = fmt(_('rsKCardISubLFix'), F.formatMilliAmp(kInp.I));
      h += card(_('rsKCardI'), F.formatMilliAmp(kRes.IAct), sub);
    } else h += card(_('rsKCardI'), '–', '');
    t = lm ? _('rsKCardLossL') : _('rsKCardLossT');
    if (ok) {
      vc = kRes.warnings.indexOf('tooHot') >= 0 ? C.error : (kRes.warnings.indexOf('heatsink') >= 0 ? C.warn : C.ok);
      sub = lm ? ksqPartText() : fmt(_('rsKCardLossSubT'), ksqPartText(), F.formatOhm(kRes.RB));
      h += card(t, formatPowerRange(kRes.PLossMin, kRes.PLossMax), sub, vc);
    } else h += card(t, '–', '');
    sub = lm ? fmt(_('rsKCardNeedSubL'), ksqLedVolt()) : fmt(_('rsKCardNeedSubT'), ksqLedVolt());
    if (ok) h += card(_('rsKCardNeed'), F.formatVolt(kRes.UNeed), sub, C.ok);
    else if (kRes.status === 'uTooLow') h += card(_('rsKCardNeed'), F.formatVolt(kRes.UNeed), sub, C.error);
    else h += card(_('rsKCardNeed'), '–', '');
    return h;
  }

  /* Karten Wechselstrom (PaintAcCards):
       Einfach:       Vorwiderstand, mittlerer Strom, Spitzenspannung, Schutzdiode
       Ohne Flackern: Vorwiderstand, LED-Strom, Elko, Gleichrichter */
  function acCards() {
    var ok = aRes.status === 'ok', simple = aInp.circuit === 'simple', h = '', t, sub;
    t = fmt(_('rsBCardRv'), seriesName(aInp.series));
    if (ok) {
      sub = fmt(_('rsKCardRSub'), bandNames(aBands, ' · '), acRatingText(aRes.RRating), F.formatPower(aRes.PR));
      h += card(t, F.formatOhm(aRes.R), '', C.bright, resistorPic(aBands) + '<div class="rings">' + esc(keepUnits(sub)) + '</div>');
    } else h += card(t, '–', '');
    if (!ok) h += card(_('rsKCardI'), '–', '');
    else if (simple) h += card(_('rsACardIAvg'), F.formatMilliAmp(aRes.IAvg),
      fmt(_('rsACardIAvgSub'), F.formatMilliAmp(aRes.IPeak), F.formatPercent(aRes.brightness), F.formatMilliAmp(aInp.I)));
    else h += card(_('rsKCardI'), F.formatMilliAmp(aRes.IAct), fmt(_('rsACardISubB'), F.formatMilliAmp(aInp.I), F.formatPercent(aRes.IRipple)));
    if (simple) {
      sub = aInp.U > 0 ? fmt(_('rsACardPeakSub'), F.formatVolt(aInp.U) + '~') : '';
      h += ok ? card(_('rsACardPeak'), F.formatVolt(aRes.UPeak), sub) : card(_('rsACardPeak'), '–', '');
      h += ok ? card(_('rsACardDiode'), aRes.diode, fmt(_('rsACardDiodeSub'), F.formatVolt(aRes.URevLed), F.formatVolt(aRes.UPeak)), C.ok)
              : card(_('rsACardDiode'), '–', '');
    } else {
      h += ok ? card(_('rsACardCap'), F.formatCap(aRes.C), fmt(_('rsACardCapSub'), F.formatVolt(aRes.CVolt)),
                     aRes.warnings.indexOf('bigCap') >= 0 ? C.warn : C.ok)
              : card(_('rsACardCap'), '–', '');
      h += ok ? card(_('rsACardBridge'), 'B80C1500', fmt(_('rsACardBridgeSub'), F.formatVolt(aRes.UDc)), C.ok)
              : card(_('rsACardBridge'), '–', '');
    }
    return h;
  }

  /* ===========================================================================
     STATUSZEILE
     =========================================================================== */
  var ICONS = {
    0: function (c) { return '<svg viewBox="0 0 12 12"><polyline points="1.5,6.2 4.6,9.2 10.5,2.8" fill="none" stroke="' + c + '" stroke-width="2"/></svg>'; },
    1: function (c, b) { return '<svg viewBox="0 0 12 12"><polygon points="6,0.6 11.6,11.2 0.4,11.2" fill="' + c + '"/><rect x="5.3" y="4" width="1.4" height="4" fill="' + b + '"/><rect x="5.3" y="9" width="1.4" height="1.3" fill="' + b + '"/></svg>'; },
    2: function (c) { return '<svg viewBox="0 0 12 12"><path d="M2 2 L10 10 M2 10 L10 2" stroke="' + c + '" stroke-width="2"/></svg>'; }
  };
  function paintStatus() {
    var s;
    if (mode === 1) s = blinkStatus();
    else if (mode === 2) s = ksqStatus();
    else if (mode === 3) s = acStatus();
    else if (res.status !== 'ok') s = { chip: '', txt: statusText(res.status), sym: 2, fore: C.error, back: C.errorBack };
    else {
      var lvl = L.loadLevelOf(res.load), txt;
      s = lvl === 'ok' ? { fore: C.ok, back: C.okBack, sym: 0 } : (lvl === 'warning' ? { fore: C.warn, back: C.warnBack, sym: 1 } : { fore: C.error, back: C.errorBack, sym: 1 });
      s.chip = fmt(_('rsStatusLoad'), F.formatPercent(res.load));
      var tr = L.pasRound(res.tempRise);
      if (res.recommendedW === 0) txt = fmt(_('rsStatusNone'), F.formatRating(res.refW), tr);
      else if (lvl === 'ok' && res.recommendedW > inp.ratingW) txt = fmt(_('rsStatusOkStd'), F.formatRating(res.refW), tr, F.formatPercent(res.loadStd));
      else if (lvl === 'ok') txt = fmt(_('rsStatusOk'), F.formatRating(res.refW), tr);
      else txt = fmt(_('rsStatusWarn'), F.formatRating(res.refW), tr, F.formatRating(res.recommendedW));
      txt += '   ·   ' + fmt(_('rsStatusTotal'), F.formatPower(res.PTotal));
      if (res.strings > 1) txt += ' ' + fmt(_('rsStatusStrings'), res.strings);
      s.txt = txt;
    }
    var chip = $('chip');
    chip.style.color = s.fore; chip.style.borderColor = s.fore; chip.style.background = s.back;
    $('chipIco').innerHTML = ICONS[s.sym](s.fore, s.back);
    $('chipText').textContent = s.chip;
    $('statusText').textContent = s.txt;
    $('statusText').title = s.txt;
  }
  function collect() {
    var chips = [], texts = [];
    return { add: function (a, b) { chips.push(a); texts.push(b); }, chips: chips, texts: texts };
  }
  function blinkStatus() {
    if (bRes.status !== 'ok') return { chip: '', txt: blinkStatusText(bRes.status), sym: 2, fore: C.error, back: C.errorBack };
    var c = collect(), w = bRes.warnings;
    if (w.indexOf('supply555') >= 0) c.add(_('rsChipSupply'), fmt(_('rsWarnSupply'), F.formatVolt(bInp.U)));
    if (w.indexOf('baseReverse') >= 0) c.add(fmt(_('rsChipBase'), F.formatVolt(bRes.URev)), fmt(_('rsWarnBase'), F.formatVolt(bRes.URev)));
    if (w.indexOf('notSaturated') >= 0) c.add(_('rsChipSat'), _('rsWarnSat'));
    if (w.indexOf('r1Small') >= 0) c.add(_('rsChipR1'), _('rsWarnR1'));
    if (w.indexOf('rHigh') >= 0) c.add(_('rsChipRHigh'), _('rsWarnRHigh'));
    if (w.indexOf('tooFast') >= 0) c.add(_('rsChipFast'), _('rsWarnFast'));
    if (c.chips.length) {
      var txt = c.texts[0];
      if (c.chips.length > 1) txt += fmt(_('rsMoreHints'), c.chips.length - 1);
      return { chip: c.chips[0], txt: txt, sym: 1, fore: C.warn, back: C.warnBack };
    }
    if (bRes.baseDiode) return { chip: _('rsChipOkMulti'), txt: fmt(_('rsHintBase'), F.formatVolt(bRes.URev)), sym: 0, fore: C.ok, back: C.okBack };
    return { chip: bInp.circuit === 'multi' ? _('rsChipOkMulti') : _('rsChipOk555'), txt: _('rsOkTolerance'), sym: 0, fore: C.ok, back: C.okBack };
  }
  function ksqStatus() {
    if (kRes.status !== 'ok') return { chip: '', txt: ksqStatusText(kRes.status), sym: 2, fore: C.error, back: C.errorBack };
    var c = collect(), w = kRes.warnings;
    if (w.indexOf('tooHot') >= 0) c.add(_('rsKChipTooHot'), fmt(_('rsKWarnTooHot'), F.formatPower(kRes.PLossMax)));
    else if (w.indexOf('heatsink') >= 0)
      c.add(_('rsKChipHeat'), fmt(_('rsKWarnHeat'), kRes.part, F.formatPower(kRes.PLossMax), String(Math.floor(kRes.heatsinkRth)),
        kInp.circuit === 'lm317' ? _('rsKTabOut') : _('rsKTabCollector')));
    if (w.indexOf('minLoad') >= 0) c.add(_('rsKChipMinLoad'), _('rsKWarnMinLoad'));
    if (w.indexOf('baseHigh') >= 0)
      c.add(_('rsKChipBase'), fmt(_('rsKWarnBase'), F.formatOhm(kRes.RB), F.formatPower(kRes.PRB),
        kRes.RBRating > 0 ? F.formatRating(kRes.RBRating) : _('rsCardRatingNone')));
    if (w.indexOf('rPower') >= 0) c.add(_('rsKChipRPower'), fmt(_('rsKWarnRPower'), F.formatPower(kRes.PR)));
    if (c.chips.length) {
      var txt = c.texts[0];
      if (c.chips.length > 1) txt += fmt(_('rsMoreHints'), c.chips.length - 1);
      return { chip: c.chips[0], txt: txt, sym: 1, fore: C.warn, back: C.warnBack };
    }
    var t;
    if (kRes.UMax <= kRes.UMin) t = _('rsKOkFix');
    else if (kInp.circuit === 'lm317') t = fmt(_('rsKOkRangeL'), F.formatPercent(kRes.RvRise), F.formatVolt(kRes.UMax));
    else t = fmt(_('rsKOkRangeT'), F.formatPercent(kRes.RvRise), F.formatVolt(kRes.UMax), F.formatPercent1(kRes.ksqRise));
    return { chip: _('rsKChipOk'), txt: t, sym: 0, fore: C.ok, back: C.okBack };
  }

  /* Statuszeile Wechselstrom (AcStatus): Fehler rot, Hinweise gelb, sonst grün */
  function acStatus() {
    if (aRes.status !== 'ok') return { chip: '', txt: acStatusText(aRes.status), sym: 2, fore: C.error, back: C.errorBack };
    var c = collect(), w = aRes.warnings;
    if (w.indexOf('dim') >= 0) c.add(_('rsAChipDim'), fmt(_('rsAWarnDim'), F.formatPercent(aRes.brightness)));
    if (w.indexOf('rPower') >= 0) c.add(_('rsAChipRPower'), fmt(_('rsAWarnRPower'), F.formatPower(aRes.PR), F.formatNum(Math.ceil(2 * aRes.PR), 0, 0) + ' W'));
    if (w.indexOf('bigCap') >= 0) c.add(_('rsAChipBigCap'), fmt(_('rsAWarnBigCap'), F.formatCap(aRes.C)));
    if (c.chips.length) {
      var txt = c.texts[0];
      if (c.chips.length > 1) txt += fmt(_('rsMoreHints'), c.chips.length - 1);
      return { chip: c.chips[0], txt: txt, sym: 1, fore: C.warn, back: C.warnBack };
    }
    return { chip: _('rsAChipOk'), txt: aInp.circuit === 'simple' ? _('rsAOkSimple') : _('rsAOkBridge'), sym: 0, fore: C.ok, back: C.okBack };
  }

  /* ===========================================================================
     RECHENWEG
     =========================================================================== */
  function rechenwegLines() {
    if (res.status !== 'ok') return [statusText(res.status)];
    var r = [], ser = seriesName(inp.series), over, stepW, stepLoad, s4, s4n, s6, pct;
    if (inp.N > 1) r.push(fmt(_('rsStep1N'), F.formatVolt(inp.U), inp.N, F.formatVolt(inp.Ud), F.formatVolt(res.UR)));
    else r.push(fmt(_('rsStep1'), F.formatVolt(inp.U), F.formatVolt(inp.Ud), F.formatVolt(res.UR)));
    r.push(exactStd(fmt(_('rsStep2'), F.formatVolt(res.UR), F.formatNum(inp.I, 4, 3), F.formatOhm(res.RCalc), ser, F.formatOhm(res.R)),
      ser, res.RCalc, res.R));
    if (res.strings > 1) r.push(fmt(_('rsStep3Strings'), F.formatVolt(res.UR), F.formatOhm(res.R), F.formatMilliAmp(res.IAct), res.strings, F.formatMilliAmp(res.ITotal)));
    else r.push(fmt(_('rsStep3'), F.formatVolt(res.UR), F.formatOhm(res.R), F.formatMilliAmp(res.IAct)));
    if (res.recommendedW > inp.ratingW) { stepW = inp.ratingW; stepLoad = res.loadStd; }
    else { stepW = res.refW; stepLoad = res.load; }
    over = stepLoad > L.LOAD_WARN ? _('rsStep4Over50') : '';
    if (res.recommendedW > 2 * inp.ratingW + 1e-9 && res.PR > 0)
      over = fmt(_('rsStep4Over50Next'), F.formatRating(res.recommendedW / 2), F.formatPercent(res.PR / (res.recommendedW / 2)));
    s4 = res.strings > 1 ? 'rsStep4Strings' : 'rsStep4';
    s4n = res.strings > 1 ? 'rsStep4NoneStrings' : 'rsStep4None';
    if (res.recommendedW === 0) r.push(fmt(_(s4n), F.formatVolt(res.UR), F.formatMilliAmp(res.IAct), F.formatPower(res.PR)));
    else r.push(fmt(_(s4), F.formatVolt(res.UR), F.formatMilliAmp(res.IAct), F.formatPower(res.PR),
      F.formatRating(stepW), F.formatPercent(stepLoad), over, F.formatRating(res.recommendedW)));
    r.push(fmt(_('rsStep5'), F.formatPower(res.PR), L.pasRound(L.RTH_QUARTER_WATT * 0.25 / Math.max(res.refW, 0.001)),
      L.pasRound(res.tempRise), F.formatRating(res.refW)));
    pct = res.PTotal > 0 ? L.pasRound(res.PLed / res.PTotal * 100) : 0;
    s6 = res.strings > 1 ? 'rsStep6Strings' : 'rsStep6';
    r.push(fmt(_(s6), F.formatPower(res.PLed), F.formatPercent(pct / 100), F.formatPower(res.PTotal - res.PLed),
      F.formatPercent((100 - pct) / 100), F.formatPower(res.PTotal)));
    return r;
  }

  function blinkRechenwegLines() {
    if (bRes.status !== 'ok') return [blinkStatusText(bRes.status)];
    var r = [], R = bRes, I = bInp, ser = seriesName(I.series), S, dHigh, sf, avail;
    if (I.circuit === 'ne555') {
      if (I.reverse) {
        S = 1 / (I.F * Math.log(2) * I.C);
        dHigh = I.conn === 'vcc' ? 1 - I.duty : I.duty;
        r.push(fmt(_(I.diode ? 'rsBStep555Rev1D' : 'rsBStep555Rev1'), F.formatFreq(I.F), F.formatCap(I.C), F.formatOhm(S)));
        r.push(fmt(_('rsBStep555Rev2'), F.formatPercent(dHigh), F.formatOhm(R.R1Calc), F.formatOhm(R.R1), F.formatOhm(R.R2Calc), F.formatOhm(R.R2), ser));
        sf = I.conn === 'both' ? 'rsBStepFreqRev1' : 'rsBStepFreqRev';
        r.push(fmt(_(sf), F.formatSeconds(R.THigh), F.formatSeconds(R.TLow), F.formatFreq(R.F), F.formatPercent1(R.duty1)));
      } else {
        if (I.diode) r.push(fmt(_('rsBStep555HighD'), F.formatOhm(R.R1), F.formatCap(R.C), F.formatSeconds(R.THigh)));
        else r.push(fmt(_('rsBStep555High'), F.formatOhm(R.R1 + R.R2), F.formatCap(R.C), F.formatSeconds(R.THigh)));
        r.push(fmt(_('rsBStep555Low'), F.formatOhm(R.R2), F.formatCap(R.C), F.formatSeconds(R.TLow)));
        sf = I.conn === 'both' ? 'rsBStepFreq1' : 'rsBStepFreq';
        r.push(fmt(_(sf), F.formatSeconds(R.T), F.formatFreq(R.F), F.formatPercent1(R.duty1)));
      }
      if (I.conn === 'vcc') { r.push(fmt(_('rsBStepOutVcc'), F.formatVolt(I.U))); avail = I.U - L.NE555_LOW; }
      else { r.push(fmt(_('rsBStepOut'), F.formatVolt(I.U), F.formatVolt(R.UOut))); avail = R.UOut; }
      if (I.conn === 'both')
        r.push(fmt(_('rsBStepRvBoth'), F.formatOhm(R.led1.R), F.formatOhm(R.led2.R), F.formatMilliAmp(R.led1.IAct), F.formatMilliAmp(R.led2.IAct)));
      else
        r.push(exactStd(fmt(_('rsBStepRv'), F.formatVolt(avail), F.formatVolt(I.Ud), F.formatMilliAmp(I.I), F.formatOhm(R.led1.RCalc), ser,
          F.formatOhm(R.led1.R), F.formatMilliAmp(R.led1.IAct)), ser, R.led1.RCalc, R.led1.R));
    } else {
      r.push(fmt(_('rsBStepMultiK'), F.formatVolt(R.deltaU), F.formatNum(R.K, 3, 3)));
      if (I.reverse)
        r.push(fmt(_('rsBStepMultiRev'), F.formatSeconds(I.duty / I.F), F.formatSeconds((1 - I.duty) / I.F),
          F.formatOhm(R.R2Calc), F.formatOhm(R.R2), F.formatOhm(R.R1Calc), F.formatOhm(R.R1), ser));
      else
        r.push(fmt(_('rsBStepMultiT'), F.formatNum(R.K, 3, 3), F.formatOhm(R.R2), F.formatCap(R.C), F.formatSeconds(R.THigh), F.formatSeconds(R.TLow)));
      r.push(fmt(_('rsBStepMultiF'), F.formatSeconds(R.T), F.formatFreq(R.F), F.formatPercent1(R.duty1)));
      r.push(fmt(_('rsBStepMultiBase'), F.formatVolt(I.U - L.BJT_UBE), F.formatOhm(Math.max(R.R1, R.R2)), F.formatMilliAmp(R.IB),
        F.formatNum(R.overdrive, 1, 1), Math.round(L.BJT_BETA)));
      r.push(exactStd(fmt(_('rsBStepMultiRv'), F.formatVolt(R.led1.UR), F.formatMilliAmp(I.I), F.formatOhm(R.led1.RCalc), ser,
        F.formatOhm(R.led1.R), F.formatMilliAmp(R.led1.IAct)), ser, R.led1.RCalc, R.led1.R));
    }
    return r;
  }

  function ksqRechenwegLines() {
    var R = kRes, partShort;
    if (R.warnings.indexOf('tooHot') >= 0) partShort = fmt(_('rsKPartTooHot'), R.part);
    else if (R.warnings.indexOf('heatsink') >= 0) partShort = fmt(_('rsKPartShortHeat'), R.part, String(Math.floor(R.heatsinkRth)));
    else partShort = R.part;
    if (R.status !== 'ok') return [ksqStatusText(R.status)];
    var ser = seriesName(kInp.series), r = [], rt = R.RRating > 0 ? F.formatRating(R.RRating) : _('rsCardRatingNone');
    if (kInp.circuit === 'lm317') {
      r.push(exactStd(fmt(_('rsKStepL1'), F.formatMilliAmp(kInp.I), F.formatOhm(R.RCalc), ser, F.formatOhm(R.R)), ser, R.RCalc, R.R));
      r.push(fmt(_('rsKStepL2'), F.formatOhm(R.R), F.formatMilliAmp(R.IAct), F.formatMilliAmp(R.IAct), F.formatPower(R.PR), rt));
      r.push(fmt(_('rsKStepL3'), ksqLedVolt(), F.formatVolt(R.UNeed), F.formatVolt(R.UMin), F.formatVolt(R.reserve)));
      r.push(fmt(_('rsKStepL4'), ksqVoltRange(), F.formatVolt(R.ULeds), F.formatMilliAmp(R.IAct), formatPowerRange(R.PLossMin, R.PLossMax), partShort));
      if (R.UMax > R.UMin)
        r.push(fmt(_('rsKStepL5'), F.formatVolt(R.UMin), F.formatVolt(R.ULeds), F.formatMilliAmp(kInp.I), F.formatOhm(R.RvCalc), F.formatVolt(R.UMax), F.formatPercent(R.RvRise)));
      else r.push(_('rsKStepL5Fix'));
    } else {
      var drift = -L.KSQ_UBE_TC * 10 / L.KSQ_UBE_SENSE;
      r.push(exactStd(fmt(_('rsKStepT1'), F.formatMilliAmp(kInp.I), F.formatOhm(R.RCalc), ser, F.formatOhm(R.R)), ser, R.RCalc, R.R));
      r.push(fmt(_('rsKStepT2'), F.formatOhm(R.R), F.formatMilliAmp(R.IAct), F.formatPower(R.PR), rt, F.formatPercent(drift)));
      r.push(fmt(_('rsKStepT3'), F.formatMilliAmp(R.IRB), R.part, F.formatMilliAmp(R.IB1), F.formatVolt(R.UMin), F.formatMilliAmp(R.IRB),
        F.formatOhm(R.RBCalc), F.formatOhm(R.RB)));
      r.push(fmt(_('rsKStepT4'), ksqLedVolt(), F.formatVolt(R.UNeed), F.formatVolt(R.UMin), F.formatVolt(R.reserve)));
      r.push(fmt(_('rsKStepT5'), ksqVoltRange(), F.formatVolt(R.ULeds), F.formatMilliAmp(R.IAct), formatPowerRange(R.PLossMin, R.PLossMax), partShort));
    }
    return r;
  }

  function acRechenwegLines() {
    var R = aRes, I = aInp;
    if (R.status !== 'ok') return [acStatusText(R.status)];
    var ser = seriesName(I.series), r = [];
    if (I.circuit === 'simple') {
      r.push(fmt(_('rsAStepS1'), F.formatVolt(I.U), F.formatVolt(R.UPeak)));
      r.push(exactStd(fmt(_('rsAStepS2'), F.formatMilliAmp(I.I), F.formatVolt(R.UPeak), F.formatVolt(R.ULeds), F.formatMilliAmp(I.I),
        F.formatOhm(R.RCalc), ser, F.formatOhm(R.R)), ser, R.RCalc, R.R));
      r.push(fmt(_('rsAStepS3'), F.formatVolt(R.ULeds), F.formatMilliAmp(R.IPeak), F.formatMilliAmp(R.IAvg), F.formatPercent(R.brightness),
        F.formatMilliAmp(I.I)));
      r.push(fmt(_('rsAStepS4'), F.formatPower(R.PR), acRatingText(R.RRating)));
      r.push(fmt(_('rsAStepS5'), F.formatVolt(R.URevLed), F.formatMilliAmp(R.IRevPeak), R.diode));
    } else {
      r.push(fmt(_('rsAStepB1'), F.formatVolt(R.UPeak), F.formatVolt(R.UDc)));
      r.push(fmt(_('rsAStepB2'), F.formatVolt(R.UDc), F.formatVolt(R.ULeds), F.formatVolt(R.rippleCalc), F.formatCap(R.CCalc), F.formatCap(R.C)));
      r.push(fmt(_('rsAStepB3'), F.formatVolt(R.UDc), F.formatVolt(R.ripple), F.formatVolt(R.UMean), F.formatVolt(R.UDc), F.formatVolt(R.CVolt)));
      r.push(exactStd(fmt(_('rsAStepB4'), F.formatVolt(R.UMean), F.formatVolt(R.ULeds), F.formatMilliAmp(I.I), F.formatOhm(R.RCalc), ser,
        F.formatOhm(R.R), F.formatMilliAmp(R.IAct)), ser, R.RCalc, R.R));
      r.push(fmt(_('rsAStepB5'), F.formatVolt(R.UMean - R.ULeds), F.formatMilliAmp(R.IAct), F.formatPower(R.PR), acRatingText(R.RRating),
        F.formatPower(R.PLeds)));
    }
    return r;
  }

  function rechenwegLegend() {
    if (mode === 1) { if (bRes.status !== 'ok') return ''; return bInp.circuit === 'multi' ? _('rsLegendMulti') : _('rsLegend555'); }
    if (mode === 2) { if (kRes.status !== 'ok') return ''; return kInp.circuit === 'lm317' ? _('rsLegendLM') : _('rsLegendKT'); }
    if (mode === 3) { if (aRes.status !== 'ok') return ''; return aInp.circuit === 'simple' ? _('rsLegendAcS') : _('rsLegendAcB'); }
    if (res.status !== 'ok') return '';
    return inp.N > 1 ? _('rsLegendRN') : _('rsLegendR');
  }
  function currentLines() {
    if (mode === 1) return { lines: blinkRechenwegLines(), ok: bRes.status === 'ok' };
    if (mode === 2) return { lines: ksqRechenwegLines(), ok: kRes.status === 'ok' };
    if (mode === 3) return { lines: acRechenwegLines(), ok: aRes.status === 'ok' };
    return { lines: rechenwegLines(), ok: res.status === 'ok' };
  }
  function paintRechenweg() {
    $('rwTitle').textContent = _('rsRechenweg');
    $('rwHint').textContent = _('rsHintDatasheet');
    $('rwHint').title = _('rsHintDatasheet');
    $('btnCopy').textContent = copiedTimer ? _('rsCopiedBtn') : _('rsCopyBtn');
    $('btnCopy').classList.toggle('done', !!copiedTimer);
    $('rechenweg').classList.toggle('open', rwOpen);
    $('rwToggle').setAttribute('aria-expanded', rwOpen ? 'true' : 'false');
    var c = currentLines(), h = '';
    if (c.ok) c.lines.forEach(function (l, i) { h += '<div class="rw-line"><span class="n">' + (i + 1) + '</span><span class="f">' + rich(keepUnits(l)) + '</span></div>'; });
    else c.lines.forEach(function (l) { h += '<div class="rw-err">' + rich(l) + '</div>'; });
    var leg = rechenwegLegend();
    if (leg) h += '<div class="rw-legend"><span class="lt">' + esc(_('rsCopyLegend')) + '</span><span>' +
      leg.split(' · ').map(rich).join(' · ') + '</span></div>';
    $('rwBody').innerHTML = h;
  }

  /* ===========================================================================
     KOPIEREN (Zusammenfassung, Rechenweg, Zeichen-Erklärung als Text)
     =========================================================================== */
  function resultSummary() {
    if (res.status !== 'ok') return statusText(res.status);
    var s = [], name = ledColorName();
    s.push(fmt(_('rsCopyTitle'), APP_VER));
    s.push(fmt(_('rsCopyInput'), F.formatVolt(inp.U), inp.N, name, F.formatVolt(inp.Ud), F.formatMilliAmp(inp.I)).replace(/_/g, ''));
    s.push(fmt(_('rsCopyStd'), F.formatOhm(res.R), seriesName(inp.series), bandNames(bands, '-'), F.formatOhm(res.RCalc)));
    if (res.strings > 1) {
      s.push(fmt(_('rsCopyCurrentStrings'), F.formatMilliAmp(res.IAct)));
      s.push(fmt(_('rsCopyStrings'), res.strings, F.formatMilliAmp(res.ITotal)));
      s.push(fmt(_('rsCopyPowerStrings'), F.formatPower(res.PR), F.formatPower(res.PTotal - res.PLed), F.formatPower(res.PLed), F.formatPower(res.PTotal)));
    } else {
      s.push(fmt(_('rsCopyCurrent'), F.formatMilliAmp(res.IAct)));
      s.push(fmt(_('rsCopyPower'), F.formatPower(res.PR), F.formatPower(res.PLed), F.formatPower(res.PTotal)));
    }
    if (res.recommendedW > 0) s.push(fmt(_('rsCopyRating'), F.formatRating(res.recommendedW), F.formatRating(res.refW), F.formatPercent(res.load)));
    return s.join('\n');
  }
  function selText(id) { var s = $(id); return s.options[s.selectedIndex] ? s.options[s.selectedIndex].text : ''; }
  function blinkSummary() {
    if (bRes.status !== 'ok') return blinkStatusText(bRes.status).replace(/_/g, '');
    var s = [], multi = bInp.circuit === 'multi';
    s.push(fmt(_('rsBCopyTitle'), APP_VER, selText('comboCircuit')));
    s.push(fmt(_('rsBCopyInput'), F.formatVolt(bInp.U), ledColorName(), F.formatVolt(bInp.Ud), F.formatMilliAmp(bInp.I)).replace(/_/g, ''));
    s.push(fmt(_('rsBCopyParts'), multi ? 'RB1' : 'R1', F.formatOhm(bRes.R1), multi ? 'RB2' : 'R2', F.formatOhm(bRes.R2), F.formatCap(bRes.C)));
    if (bRes.led2.used) s.push(fmt(_('rsBCopyTimes2'), F.formatSeconds(bRes.TOn1), F.formatSeconds(bRes.TOff1), F.formatFreq(bRes.F), F.formatPercent1(bRes.duty1)));
    else s.push(fmt(_('rsBCopyTimes'), F.formatSeconds(bRes.TOn1), F.formatSeconds(bRes.TOff1), F.formatFreq(bRes.F), F.formatPercent1(bRes.duty1)));
    var rv = F.formatOhm(bRes.led1.R) + ' (' + bandNames(bBands1, '-') + ')';
    if (bRes.led2.used) s.push(fmt(_('rsBCopyRv2'), rv, F.formatOhm(bRes.led2.R) + ' (' + bandNames(bBands2, '-') + ')'));
    else s.push(fmt(_('rsBCopyRv'), rv));
    return s.join('\n');
  }
  function ksqSummary() {
    if (kRes.status !== 'ok') return ksqStatusText(kRes.status).replace(/_/g, '');
    var s = [];
    s.push(fmt(_('rsKCopyTitle'), APP_VER, selText('comboKsq')));
    s.push(fmt(_('rsCopyInput'), ksqVoltRange(), kInp.N, ledColorName(), F.formatVolt(kInp.Ud), F.formatMilliAmp(kInp.I)).replace(/_/g, ''));
    s.push(fmt(_('rsKCopyR'), F.formatOhm(kRes.R), seriesName(kInp.series), bandNames(kBands, '-'), F.formatOhm(kRes.RCalc)));
    s.push(fmt(_('rsCopyCurrent'), F.formatMilliAmp(kRes.IAct)));
    if (kInp.circuit === 'trans') s.push(fmt(_('rsKCopyRB'), F.formatOhm(kRes.RB), bandNames(kBandsB, '-')));
    s.push(fmt(_('rsKCopyLoss'), formatPowerRange(kRes.PLossMin, kRes.PLossMax), ksqPartText()));
    s.push(fmt(_('rsKCopyNeed'), F.formatVolt(kRes.UNeed)));
    return s.join('\n');
  }
  function acSummary() {
    if (aRes.status !== 'ok') return acStatusText(aRes.status).replace(/_/g, '');
    var s = [];
    s.push(fmt(_('rsACopyTitle'), APP_VER, selText('comboAc')));
    s.push(fmt(_('rsACopyInput'), F.formatVolt(aInp.U), aInp.N, ledColorName(), F.formatVolt(aInp.Ud), F.formatMilliAmp(aInp.I)).replace(/_/g, ''));
    s.push(fmt(_('rsCopyStd'), F.formatOhm(aRes.R), seriesName(aInp.series), bandNames(aBands, '-'), F.formatOhm(aRes.RCalc)));
    if (aInp.circuit === 'simple') {
      s.push(fmt(_('rsACopyISimple'), F.formatMilliAmp(aRes.IPeak), F.formatMilliAmp(aRes.IAvg)));
      s.push(fmt(_('rsACopyDiode'), aRes.diode));
    } else {
      s.push(fmt(_('rsCopyCurrent'), F.formatMilliAmp(aRes.IAct)));
      s.push(fmt(_('rsACopyCap'), F.formatCap(aRes.C), F.formatVolt(aRes.CVolt)));
      s.push(_('rsACopyBridge'));
    }
    s.push(fmt(_('rsACopyPower'), F.formatPower(aRes.PR), acRatingText(aRes.RRating)));
    return s.join('\n');
  }
  function copyText() {
    var t, c = currentLines();
    t = mode === 1 ? blinkSummary() : (mode === 2 ? ksqSummary() : (mode === 3 ? acSummary() : resultSummary()));
    if (!c.ok) return t;
    var out = t.split('\n');
    out.push('', _('rsCopySteps'));
    c.lines.forEach(function (l, i) { out.push((i + 1) + '. ' + richPlain(l)); });
    var leg = rechenwegLegend();
    if (leg) out.push('', _('rsCopyLegend') + ' ' + richPlain(leg));
    return out.join('\n') + '\n';
  }
  /* ---------------------------------------------------------------------------
     Zeile unter dem Rechner: Satz mit Ko-fi-Knopf, dazu einmal pro neuer Haupt-
     oder Unterversion (2.7 = 207; bei 2.8 auf 208 erhöhen, bei 2.7.1 nicht) ein
     kleiner, schliessbarer Hinweis, nachdem der Benutzer ein paar Mal (DANK_NACH)
     erfolgreich gerechnet hat. Kein Pop-up, nichts unterbricht die Arbeit.
     --------------------------------------------------------------------------- */
  var THANKS_VERSION = 207;
  var DANK_NACH = 3;                // so viele eigene, gültige Berechnungen
  var dankZaehler = 0, dankTimer = null;
  function dankAnstossen() {
    if (dankTimer) clearTimeout(dankTimer);
    dankTimer = setTimeout(function () {
      dankTimer = null;
      if (!currentLines().ok) return;
      dankZaehler++;
      if (dankZaehler >= DANK_NACH && (parseInt(readSetting('thanks', '0'), 10) || 0) < THANKS_VERSION) {
        writeSetting('thanks', THANKS_VERSION);
        $('dankHint').hidden = false;
      }
    }, 1500);                       // erst wenn 1,5 s nichts mehr getippt wurde
  }
  function copyClick() {
    var text = copyText();
    function done() {
      if (copiedTimer) clearTimeout(copiedTimer);
      copiedTimer = setTimeout(function () { copiedTimer = null; paintRechenweg(); }, 1500);
      paintRechenweg();
    }
    function fallback() {
      var ta = document.createElement('textarea');
      ta.value = text; ta.style.position = 'fixed'; ta.style.opacity = '0';
      document.body.appendChild(ta); ta.select();
      try { document.execCommand('copy'); } catch (e) { /* nichts */ }
      document.body.removeChild(ta);
      done();
    }
    if (navigator.clipboard && window.isSecureContext) navigator.clipboard.writeText(text).then(done, fallback);
    else fallback();
  }

  /* ===========================================================================
     LED-VORSCHAU UND BLINKEN
     =========================================================================== */
  function ledLabels() {
    return { anode: _('rsAnode'), anodeHint: _('rsAnodeHint'), cathode: _('rsCathode'),
             cathodeHint1: _('rsCathodeHint1'), cathodeHint2: _('rsCathodeHint2'), flat: _('rsFlat') };
  }
  function renderLedBitmaps() {
    var cv = $('ledCanvas'), box = $('preview');
    var dpr = Math.min(window.devicePixelRatio || 1, 2);
    var w = Math.round(box.clientWidth * dpr), h = Math.round(box.clientHeight * dpr);
    var key = [w, h, currentLed(), onLevel, lang].join('|');
    if (key === ledCache.key) return;
    ledCache.key = key;
    var on = document.createElement('canvas'), off = document.createElement('canvas');
    window.LPRLed.render(on, w, h, LED_GLOW[currentLed()], C.deep, onLevel, ledLabels(), C.soft, dpr);
    window.LPRLed.render(off, w, h, LED_GLOW[currentLed()], C.deep, 0, ledLabels(), C.soft, dpr);
    ledCache.on = on; ledCache.off = off;
    cv.width = w; cv.height = h;
  }
  function paintLed() {
    renderLedBitmaps();
    var cv = $('ledCanvas'), ctx = cv.getContext('2d');
    var src = (ledLit || !blinkTimer) ? ledCache.on : ledCache.off;
    if (src && src.width) { ctx.clearRect(0, 0, cv.width, cv.height); ctx.drawImage(src, 0, 0); }
    var show = mode === 1 && bRes.status === 'ok';
    $('blinkFreq').style.display = show ? 'block' : 'none';
    if (show) { $('blinkFreqTitle').textContent = _('rsBCardFreq'); $('blinkFreqValue').textContent = F.formatFreq(bRes.F); }
  }
  function stopTimer() { if (blinkTimer) { clearInterval(blinkTimer); blinkTimer = null; } }
  function updateBlink() {
    if (mode === 1) {
      var level = 1.0;
      if (bRes.status !== 'ok') {
        stopTimer();
        $('blinkInfo').textContent = _('rsBlinkInfoInvalid');
      } else if (bRes.warnings.indexOf('tooFast') >= 0) {
        stopTimer();
        level = Math.max(0.15, bRes.duty1);
        $('blinkInfo').textContent = fmt(_('rsBlinkInfoFast'), F.formatFreq(bRes.F), F.formatPercent(bRes.duty1));
      } else {
        // Takt aus der Zeit seit dem Start: Verspätungen summieren sich nicht auf
        stopTimer();
        blinkStart = performance.now();
        blinkTimer = setInterval(blinkTick, 10);
        if (bInp.circuit === 'multi' || bInp.conn === 'both')
          $('blinkInfo').textContent = fmt(_('rsBlinkInfoMulti'), F.formatFreq(bRes.F), F.formatSeconds(bRes.TOn1), F.formatSeconds(bRes.TOff1));
        else
          $('blinkInfo').textContent = fmt(_('rsBlinkInfo'), F.formatFreq(bRes.F), F.formatSeconds(bRes.TOn1), F.formatSeconds(bRes.TOff1));
      }
      onLevel = level;
      ledLit = true;
      paintLed();
      return;
    }
    // Wechselstrom einfach: LED leuchtet schwächer (mittlerer Strom)
    onLevel = (mode === 3 && aRes.status === 'ok' && aInp.circuit === 'simple')
      ? Math.min(1, Math.max(0.15, aRes.brightness)) : 1.0;
    stopTimer();
    ledLit = true;
    paintLed();
  }
  function blinkTick() {
    if (mode !== 1) { stopTimer(); return; }
    var minMs = Math.round(BLINK_ANIM_MIN_PHASE * 1000);
    var onMs = Math.max(minMs, Math.round(bRes.TOn1 * 1000));
    var period = onMs + Math.max(minMs, Math.round(bRes.TOff1 * 1000));
    var lit = ((performance.now() - blinkStart) % period) < onMs;
    if (lit === ledLit) return;
    ledLit = lit;
    paintSchematic();
    paintLed();
  }

  /* ===========================================================================
     ALLES ZEICHNEN, REITER, SPRACHE
     =========================================================================== */
  function paintAll() {
    paintSchematic();
    paintCards();
    paintStatus();
    paintRechenweg();
    paintLed();
    $('colorDot').style.background = LED_GLOW[currentLed()];
  }
  function paintTabs() {
    var keys = ['rsTabResistor', 'rsTabBlink', 'rsTabKsq', 'rsTabAc'];
    for (var i = 0; i < 4; i++) {
      var t = $('tab' + i);
      t.textContent = _(keys[i]);
      t.classList.toggle('on', i === mode);
      t.setAttribute('aria-selected', i === mode ? 'true' : 'false');
    }
    // schmales Handy: aktiven Reiter sichtbar machen, falls die Zeile rollt
    var tl = $('tab' + mode).parentNode, at = $('tab' + mode);
    if (at.offsetLeft < tl.scrollLeft || at.offsetLeft + at.offsetWidth > tl.scrollLeft + tl.clientWidth)
      tl.scrollLeft = at.offsetLeft - 4;
    $('btnDe').classList.toggle('on', lang === 'de');
    $('btnEn').classList.toggle('on', lang === 'en');
  }
  function switchMode(m, save) {
    mode = m;
    modeCaptions();
    layoutLeft();
    paintTabs();
    updateBlink();
    ledCache.key = '';
    paintAll();
    if (save) writeSetting('tab', m);
  }

  function applyLanguage() {
    var oldDec = F.fmtSet.dec;
    if (lang === 'en') { F.fmtSet.dec = '.'; F.fmtSet.pct = ''; }
    else { F.fmtSet.dec = ','; F.fmtSet.pct = ' '; }
    document.documentElement.lang = lang;
    document.title = fmt(_('rsCaption'), APP_VER);
    fillCombos();
    var labels = { labelU: null, labelU2: 'rsLabelTo', labelSeries: 'rsLabelSeries', labelColor: 'rsLabelColor', labelUd: 'rsLabelUd',
      labelI: 'rsLabelI', labelN: 'rsLabelN', labelStrings: 'rsLabelStrings', headSupply: 'rsHeadSupply', headTiming: 'rsHeadTiming',
      headPreview: 'rsHeadPreview', labelDiode: 'rsDiode', labelSym: 'rsSym', kofiText: 'rsKofi',
      kofiSatz: 'rsKofiSatz', kofiText2: 'rsKofi', dankHintText: 'rsDankHint', dankLink: 'rsKofi' };
    for (var id in labels) if (labels[id]) $(id).textContent = _(labels[id]);
    $('unitN').textContent = _('rsUnitN'); $('unitStrings').textContent = _('rsUnitN');
    $('btnReset').setAttribute('aria-label', _('rsTipReset')); $('btnReset').dataset.tip = _('rsTipReset');
    $('btnLedInfo').setAttribute('aria-label', _('rsTipLedInfo')); $('btnLedInfo').dataset.tip = _('rsTipLedInfo');
    $('btnAbout').setAttribute('aria-label', _('rsTipAbout')); $('btnAbout').dataset.tip = _('rsTipAbout');
    $('btnDe').dataset.tip = _('rsTipLang'); $('btnEn').dataset.tip = _('rsTipLang');
    if (oldDec !== F.fmtSet.dec) {
      ['editU', 'editUd', 'editI', 'editN', 'editU2', 'editT1', 'editT2', 'editT3', 'editStrings'].forEach(function (id) {
        $(id).value = $(id).value.split(oldDec).join(F.fmtSet.dec);
      });
      ['ne555', 'multi'].forEach(function (c) { ['f', 'r'].forEach(function (d) {
        bTexts[c][d] = bTexts[c][d].map(function (s) { return s.split(oldDec).join(F.fmtSet.dec); });
      }); });
    }
    modeCaptions();
    paintTabs();
    ledCache.key = '';
  }
  function setLanguage(code) {
    if (code === lang) return;
    lang = code;
    writeSetting('lang', code);
    applyLanguage();
    recalc();
    updateBlink();
  }

  /* ===========================================================================
     ZURÜCKSETZEN, INFO, LED-INFO
     =========================================================================== */
  function resetClick() {
    var d = F.fmtSet.dec;
    $('editU').value = '12';
    $('comboColor').selectedIndex = 4;
    $('editUd').value = F.formatNum(L.LED_DEFAULT_UD[4], 2, 1);
    $('editI').value = '20';
    $('editN').value = '1';
    $('editStrings').value = '1';
    $('editU2').value = F.formatNum(14.4, 1, 1);
    $('comboSeries').selectedIndex = 0;
    bTexts = blinkDefaults();
    ['ne555', 'multi'].forEach(function (c) { ['f', 'r'].forEach(function (k) {
      bTexts[c][k] = bTexts[c][k].map(function (s) { return s.replace(',', d); });
    }); });
    if (mode === 1) {
      $('editU').value = '9';
      $('comboColor').selectedIndex = 0;
      $('editUd').value = F.formatNum(L.LED_DEFAULT_UD[0], 2, 1);
      $('editI').value = '15';
    }
    if (mode === 2) $('editN').value = '2';
    if (mode === 3) $('editU').value = '16';
    $('checkDiode').checked = false;
    $('checkSym').checked = true;
    $('comboConn').selectedIndex = 0;
    loadTimingTexts();
    ledCache.key = '';
    recalc();
    updateBlink();
  }
  function aboutClick() {
    $('aboutTitle').textContent = _('rsTipAbout');
    $('aboutText').textContent = fmt(_('rsAbout'), APP_VER);
    $('about').hidden = false;
    $('aboutOk').focus();
  }
  function ledInfoClick() {
    // echter Link statt window.open: funktioniert auch in eingebetteten Ansichten
    var a = document.createElement('a');
    a.href = lang === 'en' ? 'info/led-info-en.html' : 'info/led-info.html';
    a.target = '_blank'; a.rel = 'noopener';
    document.body.appendChild(a); a.click(); a.remove();
  }

  /* ===========================================================================
     EINGABEFELDER: Pfeiltasten, Mausrad, erlaubte Zeichen
     =========================================================================== */
  function stepStd(v, up, digits) {
    if (!(v > 0)) return digits[0] / 10;
    var e, i, w, d = Math.floor(Math.log10(v));
    if (up) {
      for (e = d - 1; e <= d + 2; e++) for (i = 0; i < digits.length; i++) {
        w = digits[i] * Math.pow(10, e - 1);
        if (w > v * (1 + 1e-9)) return w;
      }
    } else {
      for (e = d + 1; e >= d - 2; e--) for (i = digits.length - 1; i >= 0; i--) {
        w = digits[i] * Math.pow(10, e - 1);
        if (w < v * (1 - 1e-9)) return w;
      }
    }
    return v;
  }
  var STEP = { editU: 100, editUd: 100, editI: 1000, editN: 1000, editStrings: 1000, editU2: 100 };
  function stepField(el, up, shift) {
    var v = L.parseDecimal(el.value); if (v === null) v = 0;
    var tag = el.dataset.step !== undefined ? parseInt(el.dataset.step, 10) : STEP[el.id];
    if (tag < 0) {
      v = stepStd(v, up, tag === -2 ? E6_DIGITS : E12_DIGITS);
      el.value = F.formatNum(v, 3, 0);
    } else {
      var step = tag / 1000;
      if (shift) step *= 10;
      v = up ? v + step : v - step;
      if (el.id === 'editN') v = Math.min(MAX_LEDS, Math.max(1, v));
      else if (el.id === 'editStrings') v = Math.min(MAX_STRINGS, Math.max(1, v));
      else if (el.id === 'editU' || el.id === 'editU2') v = Math.min(MAX_U, Math.max(0, v));
      else v = Math.max(0, v);
      el.value = F.formatNum(v, 2, 0);
    }
    onEdit(el);
  }
  function onEdit(el) {
    if (/^editT/.test(el.id)) syncSymmetric();
    recalc();
  }
  function bindEdit(el) {
    var intOnly = el.id === 'editN' || el.id === 'editStrings';
    el.addEventListener('input', function () { onEdit(el); });
    el.addEventListener('keydown', function (e) {
      if (e.key === 'ArrowUp' || e.key === 'ArrowDown') { e.preventDefault(); stepField(el, e.key === 'ArrowUp', e.shiftKey); return; }
      if (e.ctrlKey || e.metaKey || e.altKey || e.key.length !== 1) return;
      if (/[0-9]/.test(e.key)) return;
      if ((e.key === ',' || e.key === '.') && !intOnly) {
        e.preventDefault();
        var dec = F.fmtSet.dec, sel = el.value.substring(el.selectionStart, el.selectionEnd);
        if (el.value.indexOf(dec) < 0 || sel.indexOf(dec) >= 0) {
          var s = el.selectionStart;
          el.setRangeText(dec, el.selectionStart, el.selectionEnd, 'end');
          el.setSelectionRange(s + 1, s + 1);
          onEdit(el);
        }
        return;
      }
      e.preventDefault();
    });
    el.addEventListener('wheel', function (e) {
      if (document.activeElement !== el) return;
      e.preventDefault();
      stepField(el, e.deltaY < 0, e.shiftKey);
    }, { passive: false });
  }

  /* ===========================================================================
     TOOLTIP der Symbole oben rechts
     =========================================================================== */
  function bindTips() {
    var tip = $('tip');
    document.querySelectorAll('[data-tip]').forEach(function (b) {
      b.addEventListener('mouseenter', function () {
        tip.textContent = b.dataset.tip; tip.hidden = false;
        var r = b.getBoundingClientRect();
        var x = Math.min(window.innerWidth - tip.offsetWidth - 4, Math.max(4, r.left + r.width / 2 - tip.offsetWidth / 2));
        tip.style.left = x + 'px'; tip.style.top = (r.bottom + 6) + 'px';
      });
      b.addEventListener('mouseleave', function () { tip.hidden = true; });
      b.addEventListener('click', function () { tip.hidden = true; });
    });
  }

  /* ===========================================================================
     START
     =========================================================================== */
  function init() {
    // Sprache: gespeichert, sonst die des Browsers
    var nav = (navigator.language || 'de').toLowerCase();
    lang = readSetting('lang', nav.indexOf('de') === 0 ? 'de' : 'en');
    if (lang !== 'de' && lang !== 'en') lang = 'de';
    fillCombos();
    $('comboColor').selectedIndex = 4;
    $('comboSeries').selectedIndex = 0;
    $('comboCircuit').selectedIndex = Math.min(1, Math.max(0, parseInt(readSetting('circuit', '0'), 10) || 0));
    $('comboConn').selectedIndex = 0;
    $('comboKsq').selectedIndex = Math.min(1, Math.max(0, parseInt(readSetting('ksq', '0'), 10) || 0));
    $('comboAc').selectedIndex = Math.min(1, Math.max(0, parseInt(readSetting('ac', '0'), 10) || 0));
    // Startwerte wie im Formular (uMain.lfm), deutsch geschrieben
    $('editU').value = '12'; $('editUd').value = '3,2'; $('editI').value = '20'; $('editN').value = '1';
    $('editStrings').value = '1'; $('editU2').value = '14,4';
    loadTimingTexts();
    if (lang === 'en') { F.fmtSet.dec = ','; }   // damit applyLanguage von «,» auf «.» umstellt
    applyLanguage();

    ['editU', 'editUd', 'editI', 'editN', 'editStrings', 'editU2', 'editT1', 'editT2', 'editT3'].forEach(function (id) { bindEdit($(id)); });
    $('comboColor').addEventListener('change', function () {
      $('editUd').value = F.formatNum(L.LED_DEFAULT_UD[currentLed()], 2, 1);
      ledCache.key = '';
      recalc();
    });
    $('comboSeries').addEventListener('change', recalc);
    $('comboConn').addEventListener('change', recalc);
    $('checkDiode').addEventListener('change', recalc);
    $('checkSym').addEventListener('change', function () { syncSymmetric(); recalc(); });
    $('comboCircuit').addEventListener('change', function () {
      storeTimingTexts(); loadTimingTexts(); layoutLeft(); recalc();
      writeSetting('circuit', $('comboCircuit').selectedIndex);
    });
    $('comboKsq').addEventListener('change', function () { recalc(); writeSetting('ksq', $('comboKsq').selectedIndex); });
    $('comboAc').addEventListener('change', function () { modeCaptions(); recalc(); updateBlink(); writeSetting('ac', $('comboAc').selectedIndex); });
    $('modeParts').addEventListener('click', function () { setReverse(false); });
    $('modeRev').addEventListener('click', function () { setReverse(true); });
    for (var i = 0; i < 4; i++) (function (m) { $('tab' + m).addEventListener('click', function () { if (mode !== m) switchMode(m, true); }); })(i);
    $('btnDe').addEventListener('click', function () { setLanguage('de'); });
    $('btnEn').addEventListener('click', function () { setLanguage('en'); });
    $('btnReset').addEventListener('click', resetClick);
    $('btnLedInfo').addEventListener('click', ledInfoClick);
    $('btnAbout').addEventListener('click', aboutClick);
    $('aboutOk').addEventListener('click', function () { $('about').hidden = true; });
    $('about').addEventListener('click', function (e) { if (e.target === $('about')) $('about').hidden = true; });
    $('rwToggle').addEventListener('click', function () { rwOpen = !rwOpen; paintRechenweg(); requestAnimationFrame(function () { ledCache.key = ''; paintLed(); }); });
    $('btnCopy').addEventListener('click', copyClick);
    $('dankHint').addEventListener('click', function (e) {
      if (e.target.classList.contains('dank-x') || e.target.classList.contains('dank-link'))
        setTimeout(function () { $('dankHint').hidden = true; }, 0);
    });
    ['input', 'change'].forEach(function (ev) {
      $('app').addEventListener(ev, function (e) { if (e.isTrusted) dankAnstossen(); });
    });
    document.addEventListener('keydown', function (e) {
      if (e.key === 'Escape' && !$('about').hidden) { $('about').hidden = true; return; }
      if ((e.key === 'C' || e.key === 'c') && (e.ctrlKey || e.metaKey) && e.shiftKey) { e.preventDefault(); copyClick(); return; }
      if ((e.ctrlKey || e.altKey) && !e.shiftKey && /^[1234]$/.test(e.key)) {
        e.preventDefault();
        var m = parseInt(e.key, 10) - 1;
        if (m !== mode) switchMode(m, true);
        return;
      }
      if (e.key === 'F1') { e.preventDefault(); ledInfoClick(); }
    });
    var rt = null;
    window.addEventListener('resize', function () {
      clearTimeout(rt);
      rt = setTimeout(function () { ledCache.key = ''; paintLed(); fitCardValues(); fitSchemForPhone($('schem')); }, 120);
    });
    bindTips();
    var startMode = Math.min(3, Math.max(0, parseInt(readSetting('tab', '0'), 10) || 0));
    recalc();
    switchMode(startMode, false);
  }
  function setReverse(r) {
    if (r === reverse) return;
    storeTimingTexts();
    reverse = r;
    loadTimingTexts();
    recalc();
  }

  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', init); else init();
})();
