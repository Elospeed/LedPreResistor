/* ==============================================================================
   calc.js - Rechenlogik von LedPreResistor (HTML-Version)
   ==============================================================================
   Zweck:     1:1-Übertragung der Pascal-Units der Windows-Version 2.5.2:
                uESeries  - Normreihen E12, E24, E96
                uColorCode- Farbringe
                uCalc     - Vorwiderstand (auch Stränge parallel)
                uBlink    - Blinkschaltung NE555 und Multivibrator
                uKsq      - Konstantstrom LM317 und zwei Transistoren
                uAc       - LEDs an Wechselspannung (Einfach, Ohne Flackern)
                uFormat   - Zahlen als Text
              Gerechnet wird immer in SI-Einheiten (V, A, Ω, F, s, Hz, W).
              Keine Oberfläche, keine Texte: Fehler und Hinweise kommen als
              Kennungen zurück, app.js übersetzt sie.
   Regeln:    Konstanten und Formeln wie im Pascal-Code; Pascal-Round rundet
              «zur geraden Zahl» (Banker's Rounding), darum pasRound.
   Autor:     Elospeed
   Versionen: 2.5.2-html 18.11.2026  erste Fassung (Stand Windows 2.5.2)
              2.7        23.11.2026  uAc: Reiter Wechselstrom
   ============================================================================== */
(function (global) {
  'use strict';

  /* ===========================================================================
     HILFSFUNKTIONEN WIE IN PASCAL
     =========================================================================== */

  // Pascal Round: bei genau ,5 zur geraden Zahl (Round(2.5) = 2, Round(3.5) = 4)
  function pasRound(x) {
    var f = Math.floor(x);
    var d = x - f;
    if (d > 0.5) return f + 1;
    if (d < 0.5) return f;
    return (f % 2 === 0) ? f : f + 1;
  }

  // Floor(Log10(x)) wie in Pascal
  function floorLog10(x) {
    return Math.floor(Math.log10(x));
  }

  // IntPower(10, e)
  function pow10(e) {
    return Math.pow(10, e);
  }

  function isNum(x) {
    return typeof x === 'number' && isFinite(x);
  }

  /* ===========================================================================
     uESeries - NORMREIHEN
     =========================================================================== */
  var E12 = [10, 12, 15, 18, 22, 27, 33, 39, 47, 56, 68, 82];
  var E24 = [10, 11, 12, 13, 15, 16, 18, 20, 22, 24, 27, 30,
             33, 36, 39, 43, 47, 51, 56, 62, 68, 75, 82, 91];
  var E96 = [100, 102, 105, 107, 110, 113, 115, 118, 121, 124, 127, 130,
             133, 137, 140, 143, 147, 150, 154, 158, 162, 165, 169, 174,
             178, 182, 187, 191, 196, 200, 205, 210, 215, 221, 226, 232,
             237, 243, 249, 255, 261, 267, 274, 280, 287, 294, 301, 309,
             316, 324, 332, 340, 348, 357, 365, 374, 383, 392, 402, 412,
             422, 432, 442, 453, 464, 475, 487, 499, 511, 523, 536, 549,
             562, 576, 590, 604, 619, 634, 649, 665, 681, 698, 715, 732,
             750, 768, 787, 806, 825, 845, 866, 887, 909, 931, 953, 976];
  var E_TOLERANCE = 1e-9;
  var ES = { E12: 0, E24: 1, E96: 2 };

  function seriesDigits(series) {
    return series === ES.E12 ? E12 : (series === ES.E24 ? E24 : E96);
  }
  function seriesDigitCount(series) {
    return series === ES.E96 ? 3 : 2;
  }
  function stdValue(digits, digitCount, e) {
    var exp = e - digitCount + 1;
    return { value: digits * pow10(exp), digits: digits, digitCount: digitCount, exponent: exp };
  }

  // NextStdValue: kleinster Normwert >= R
  function nextStdValue(R, series) {
    if (!isNum(R) || R <= 0) return null;
    var dc = seriesDigitCount(series), list = seriesDigits(series);
    var decade = floorLog10(R);
    for (var e = decade - 1; e <= decade + 1; e++)
      for (var i = 0; i < list.length; i++) {
        var v = list[i] * pow10(e - dc + 1);
        if (v >= R * (1 - E_TOLERANCE)) return stdValue(list[i], dc, e);
      }
    return null;
  }

  // PrevStdValue: grösster Normwert <= R
  function prevStdValue(R, series) {
    if (!isNum(R) || R <= 0) return null;
    var dc = seriesDigitCount(series), list = seriesDigits(series);
    var decade = floorLog10(R);
    for (var e = decade + 1; e >= decade - 1; e--)
      for (var i = list.length - 1; i >= 0; i--) {
        var v = list[i] * pow10(e - dc + 1);
        if (v <= R * (1 + E_TOLERANCE)) return stdValue(list[i], dc, e);
      }
    return null;
  }

  // NearestStdValue (uBlink): am nächsten im Verhältnis
  function nearestStdValue(R, series) {
    if (!isNum(R) || R <= 0) return null;
    var dc = seriesDigitCount(series), list = seriesDigits(series);
    var decade = floorLog10(R);
    var best = Number.MAX_VALUE, res = null;
    for (var e = decade - 1; e <= decade + 1; e++)
      for (var i = 0; i < list.length; i++) {
        var v = list[i] * pow10(e - dc + 1);
        var d = Math.abs(Math.log(v / R));
        if (d < best - 1e-12) { best = d; res = stdValue(list[i], dc, e); }
      }
    return res;
  }

  /* ===========================================================================
     uColorCode - FARBRINGE
     =========================================================================== */
  // Ringfarben 0..9 = Ziffern, 10 = Gold, 11 = Silber
  var BC = { black: 0, brown: 1, red: 2, orange: 3, yellow: 4, green: 5,
             blue: 6, violet: 7, grey: 8, white: 9, gold: 10, silver: 11 };

  function colorBands(std, series) {
    if (!std) return null;
    if (std.exponent < -2 || std.exponent > 9 || std.digitCount < 2) return null;
    var count = std.digitCount, bands = new Array(count + 2), rest = std.digits;
    for (var i = count - 1; i >= 0; i--) { bands[i] = rest % 10; rest = Math.floor(rest / 10); }
    if (std.exponent === -2) bands[count] = BC.silver;
    else if (std.exponent === -1) bands[count] = BC.gold;
    else bands[count] = std.exponent;
    bands[count + 1] = (series === ES.E96) ? BC.brown : BC.gold;
    return bands;
  }

  /* ===========================================================================
     uCalc - VORWIDERSTAND
     =========================================================================== */
  var RATINGS = [0.125, 0.25, 0.5, 1.0];
  var LOAD_WARN = 0.5;
  var RATING_REFERENCE = 0.25;
  var RTH_QUARTER_WATT = 225.0;
  // rot, gelb, grün, blau, weiss, infrarot
  var LED_DEFAULT_UD = [2.0, 2.1, 2.2, 3.2, 3.2, 1.3];

  function loadLevelOf(load) {
    if (load > 1.0) return 'overload';
    if (load > LOAD_WARN) return 'warning';
    return 'ok';
  }
  function recommendRating(P) {
    for (var i = 0; i < RATINGS.length; i++)
      if (P <= RATINGS[i] * LOAD_WARN) return RATINGS[i];
    return 0;
  }
  function estimateTempRise(P, ratingW) {
    if (ratingW <= 0) return 0;
    return P * RTH_QUARTER_WATT * (0.25 / ratingW);
  }

  // ParseDecimal: Komma und Punkt, höchstens ein Dezimalzeichen
  function parseDecimal(s) {
    var t = String(s == null ? '' : s).trim().replace(/,/g, '.');
    if (t === '' || t.indexOf('.') !== t.lastIndexOf('.')) return null;
    // wie TryStrToFloat: Zahl mit optionalem Vorzeichen und Exponent
    if (!/^[+-]?(\d+\.?\d*|\.\d+)([eE][+-]?\d+)?$/.test(t)) return null;
    var v = parseFloat(t);
    return isNum(v) ? v : null;
  }

  /* Input: { U, Ud, I, N, series, ratingW, strings } */
  function calculate(inp) {
    var r = { status: 'ok' };
    if (!(inp.U > 0)) r.status = 'invalidU';
    else if (!(inp.Ud > 0)) r.status = 'invalidUd';
    else if (!(inp.I > 0)) r.status = 'invalidI';
    else if (inp.N < 1) r.status = 'invalidN';
    else if (inp.strings < 0) r.status = 'invalidStrings';
    else if (inp.U <= inp.N * inp.Ud) r.status = 'uTooLow';
    if (r.status !== 'ok') return r;

    r.UR = inp.U - inp.N * inp.Ud;
    r.RCalc = r.UR / inp.I;
    r.std = nextStdValue(r.RCalc, inp.series);
    if (!r.std) return { status: 'noStdValue' };

    r.R = r.std.value;
    r.IAct = r.UR / r.R;
    r.strings = Math.max(1, inp.strings);
    r.ITotal = r.strings * r.IAct;
    r.PR = r.UR * r.IAct;
    r.PLed = inp.N * inp.Ud * r.ITotal;
    r.PTotal = inp.U * r.ITotal;

    r.recommendedW = recommendRating(r.PR);
    r.refW = inp.ratingW;
    if (r.recommendedW > 0) r.refW = r.recommendedW;
    r.load = r.refW > 0 ? r.PR / r.refW : 0;
    r.loadStd = inp.ratingW > 0 ? r.PR / inp.ratingW : 0;
    r.loadLevel = loadLevelOf(r.load);
    r.tempRise = estimateTempRise(r.PR, r.refW);
    return r;
  }

  /* ===========================================================================
     uBlink - BLINKSCHALTUNG
     =========================================================================== */
  var NE555_DROP_HIGH = 1.7, NE555_LOW = 0.1, NE555_U_MIN = 4.5, NE555_U_MAX = 16.0,
      NE555_I_MAX = 0.2, NE555_R1_MIN = 1000.0;
  var BJT_UCE_SAT = 0.2, BJT_UBE = 0.6, BJT_BETA = 100.0, BJT_UEB_MAX = 6.0,
      BJT_UEB_WARN = 12.0, BJT_UCE_MAX = 45.0, BJT_IC_MAX = 0.1, BJT_OVERDRIVE_MIN = 1.0;
  var BLINK_VISIBLE_MAX = 50.0, R_TIMING_MAX = 1e6;

  function multiFactor(U, deltaU, uTh) {
    if (uTh === undefined) uTh = 0.6;
    if (U - uTh <= 0 || deltaU <= 0) return Math.log(2);
    return Math.log((U - uTh + deltaU) / (U - uTh));
  }

  function ledResistor(UR, I, series) {
    if (!(UR > 0 && I > 0)) return null;
    var lr = { used: true, UR: UR, RCalc: UR / I };
    lr.std = nextStdValue(lr.RCalc, series);
    if (!lr.std) return null;
    lr.R = lr.std.value;
    lr.IAct = UR / lr.R;
    lr.P = UR * lr.IAct;
    return lr;
  }
  var NO_LED = { used: false, UR: 0, RCalc: 0, std: null, R: 0, IAct: 0, P: 0 };

  function roundTiming(RCalc, series) {
    var s = nearestStdValue(RCalc, series);
    return s ? s.value : 0;
  }

  function calc555(inp, res) {
    var K = Math.log(2), S, DHigh;
    res.K = K;
    if (inp.reverse) {
      DHigh = (inp.conn === 'vcc') ? 1 - inp.duty : inp.duty;
      if (inp.diode) {
        S = 1 / (inp.F * K * inp.C);
        res.R1Calc = DHigh * S;
        res.R2Calc = (1 - DHigh) * S;
      } else {
        if (DHigh <= 0.5) { res.status = 'dutyNeedsDiode'; return; }
        S = 1 / (inp.F * K * inp.C);
        res.R2Calc = (1 - DHigh) * S;
        res.R1Calc = (2 * DHigh - 1) * S;
      }
      res.R1 = roundTiming(res.R1Calc, inp.series);
      res.R2 = roundTiming(res.R2Calc, inp.series);
      if (!(res.R1 > 0 && res.R2 > 0)) { res.status = 'noStdValue'; return; }
    } else {
      res.R1 = inp.R1;
      res.R2 = inp.R2;
    }
    res.C = inp.C;

    res.THigh = inp.diode ? K * res.R1 * res.C : K * (res.R1 + res.R2) * res.C;
    res.TLow = K * res.R2 * res.C;
    if (inp.conn === 'vcc') { res.TOn1 = res.TLow; res.TOff1 = res.THigh; }
    else { res.TOn1 = res.THigh; res.TOff1 = res.TLow; }

    res.UOut = inp.U - NE555_DROP_HIGH;
    if (inp.conn === 'gnd' || inp.conn === 'both') {
      res.led1 = ledResistor(res.UOut - inp.Ud, inp.I, inp.series);
      if (!res.led1) { res.status = 'uTooLow'; return; }
    }
    if (inp.conn === 'vcc' || inp.conn === 'both') {
      var lr = ledResistor(inp.U - inp.Ud - NE555_LOW, inp.I, inp.series);
      if (!lr) { res.status = 'uTooLow'; return; }
      if (inp.conn === 'vcc') res.led1 = lr; else res.led2 = lr;
    }

    if (inp.U < NE555_U_MIN) res.warnings.push('supply555');
    if (res.R1 < NE555_R1_MIN) res.warnings.push('r1Small');
    if (Math.max(res.R1, res.R2) > R_TIMING_MAX) res.warnings.push('rHigh');
  }

  function calcMulti(inp, res) {
    var l1 = ledResistor(inp.U - inp.Ud - BJT_UCE_SAT, inp.I, inp.series);
    var l2 = ledResistor(inp.U - inp.Ud - BJT_UCE_SAT, inp.I, inp.series);
    if (!(l1 && l2)) { res.status = 'uTooLow'; return; }
    res.led1 = l1; res.led2 = l2;
    res.deltaU = inp.U - inp.Ud - BJT_UCE_SAT;
    res.URev = res.deltaU - BJT_UBE;
    res.baseDiode = res.URev > BJT_UEB_MAX;
    res.K = multiFactor(inp.U, res.deltaU, BJT_UBE);
    res.C = inp.C;

    if (inp.reverse) {
      res.R2Calc = inp.duty / inp.F / (res.K * res.C);
      res.R1Calc = (1 - inp.duty) / inp.F / (res.K * res.C);
      res.R1 = roundTiming(res.R1Calc, inp.series);
      res.R2 = roundTiming(res.R2Calc, inp.series);
      if (!(res.R1 > 0 && res.R2 > 0)) { res.status = 'noStdValue'; return; }
    } else {
      res.R1 = inp.R1;
      res.R2 = inp.R2;
    }
    res.THigh = res.K * res.R2 * res.C;
    res.TLow = res.K * res.R1 * res.C;
    res.TOn1 = res.THigh;
    res.TOff1 = res.TLow;

    var IC = res.led1.IAct;
    res.IB = (inp.U - BJT_UBE) / Math.max(res.R1, res.R2);
    if (IC > 0) res.overdrive = res.IB * BJT_BETA / IC;

    if (res.URev > BJT_UEB_WARN) res.warnings.push('baseReverse');
    if (res.overdrive < BJT_OVERDRIVE_MIN) res.warnings.push('notSaturated');
    if (Math.max(res.R1, res.R2) > R_TIMING_MAX) res.warnings.push('rHigh');
  }

  /* Input: { circuit: 'ne555'|'multi', reverse, R1, R2, C, F, duty, diode,
              conn: 'gnd'|'vcc'|'both', U, Ud, I, series } */
  function calculateBlink(inp) {
    var res = { status: 'ok', warnings: [], R1Calc: 0, R2Calc: 0, R1: 0, R2: 0, C: 0, K: 0,
                THigh: 0, TLow: 0, T: 0, F: 0, TOn1: 0, TOff1: 0, duty1: 0, UOut: 0,
                deltaU: 0, URev: 0, IB: 0, overdrive: 0, baseDiode: false,
                led1: NO_LED, led2: NO_LED };
    var s = 'ok';
    if (!(inp.U > 0)) s = 'invalidU';
    else if (!(inp.Ud > 0)) s = 'invalidUd';
    else if (!(inp.I > 0)) s = 'invalidI';
    else if (!inp.reverse && !(inp.R1 > 0)) s = 'invalidR1';
    else if (!inp.reverse && !(inp.R2 > 0)) s = 'invalidR2';
    else if (inp.reverse && !(inp.F > 0)) s = 'invalidF';
    else if (inp.reverse && !(inp.duty > 0 && inp.duty < 1)) s = 'invalidDuty';
    else if (!(inp.C > 0)) s = 'invalidC';
    else if (inp.circuit === 'ne555' && inp.U > NE555_U_MAX + 1e-9) s = 'supply555';
    else if (inp.circuit === 'ne555' && inp.I > NE555_I_MAX + 1e-9) s = 'current555';
    else if (inp.circuit === 'multi' && inp.U > BJT_UCE_MAX + 1e-9) s = 'multiVoltage';
    else if (inp.circuit === 'multi' && inp.I > BJT_IC_MAX + 1e-9) s = 'multiCurrent';
    if (s !== 'ok') return { status: s, warnings: [], led1: NO_LED, led2: NO_LED };

    if (inp.circuit === 'ne555') calc555(inp, res); else calcMulti(inp, res);

    if (res.status === 'ok') {
      res.T = res.THigh + res.TLow;
      if (res.T > 0) { res.F = 1 / res.T; res.duty1 = res.TOn1 / res.T; }
      if (res.F > BLINK_VISIBLE_MAX) res.warnings.push('tooFast');
      return res;
    }
    return { status: res.status, warnings: [], led1: NO_LED, led2: NO_LED };
  }

  /* ===========================================================================
     uKsq - KONSTANTSTROM
     =========================================================================== */
  var LM317_UREF = 1.25, LM317_DROPOUT = 2.0, LM317_I_MIN = 0.010, LM317_UDIFF_MAX = 40.0,
      KSQ_I_MAX = 1.5, KSQ_UBE_SENSE = 0.6, KSQ_UBE_T1 = 0.7, KSQ_UCE_T1_MIN = 0.6,
      KSQ_IRB_MIN = 0.002, KSQ_IRB_FACTOR = 2.0, KSQ_UCE_MAX = 45.0, KSQ_UT = 0.026,
      KSQ_UBE_TC = -0.002, KSQ_DELTA_T = 70.0, KSQ_RTH_CS = 1.0;
  // LM317L, LM317, BC547, BC337, BD139
  var PARTS = ['LM317L', 'LM317', 'BC547', 'BC337', 'BD139'];
  var PART_P_FREE = { LM317L: 0.35, LM317: 1.0, BC547: 0.25, BC337: 0.3, BD139: 0.7 };
  var PART_RTH_JC = { LM317L: 0, LM317: 5.0, BC547: 0, BC337: 0, BD139: 10.0 };
  var PART_I_MAX = { LM317L: 0.1, LM317: 1.5, BC547: 0.1, BC337: 0.5, BD139: 1.5 };

  function partBeta(p) {
    if (p === 'BC547' || p === 'BC337') return 100;
    if (p === 'BD139') return 40;
    return 0;
  }
  function choosePart(circuit, I, P) {
    if (circuit === 'lm317') {
      if (I <= PART_I_MAX.LM317L && P <= PART_P_FREE.LM317L) return 'LM317L';
      return 'LM317';
    }
    if (I <= PART_I_MAX.BC547 && P <= PART_P_FREE.BC547) return 'BC547';
    if (I <= PART_I_MAX.BC337 && P <= PART_P_FREE.BC337) return 'BC337';
    return 'BD139';
  }

  /* Input: { circuit: 'lm317'|'trans', UMin, UMax, Ud, I, N, series } */
  function calculateKsq(inp) {
    var r = { status: 'ok', warnings: [], UMin: 0, UMax: 0, ULeds: 0, URef: 0, RCalc: 0,
              std: null, R: 0, IAct: 0, PR: 0, RRating: 0, headroom: 0, UNeed: 0, reserve: 0,
              PLossMin: 0, PLossMax: 0, part: 'LM317L', heatsinkRth: 0, RvCalc: 0, RvRise: 0,
              ksqRise: 0, beta1: 0, IB1: 0, IRB: 0, RBCalc: 0, RBStd: null, RB: 0,
              IRBMax: 0, PRB: 0, RBRating: 0 };
    var U1 = inp.UMin, U2 = inp.UMax;
    if (!(U2 > 0)) U2 = U1;
    if (U2 < U1) { U1 = inp.UMax; U2 = inp.UMin; }

    if (!(U1 > 0)) r.status = 'invalidU';
    else if (!(inp.Ud > 0)) r.status = 'invalidUd';
    else if (!(inp.I > 0)) r.status = 'invalidI';
    else if (inp.N < 1) r.status = 'invalidN';
    else if (inp.I > KSQ_I_MAX * (1 + 1e-9)) r.status = 'tooMuchCurrent';
    else if (inp.circuit === 'lm317' && U2 > LM317_UDIFF_MAX + 1e-9) r.status = 'overVoltage';
    else if (inp.circuit !== 'lm317' && U2 > KSQ_UCE_MAX + 1e-9) r.status = 'overVoltage';
    r.UMin = U1;
    r.UMax = U2;
    if (r.status !== 'ok') return r;

    r.ULeds = inp.N * inp.Ud;
    if (inp.circuit === 'lm317') { r.URef = LM317_UREF; r.headroom = LM317_DROPOUT; }
    else { r.URef = KSQ_UBE_SENSE; r.headroom = KSQ_UCE_T1_MIN; }
    r.UNeed = r.ULeds + r.URef + r.headroom;
    r.reserve = U1 - r.UNeed;
    if (r.reserve < -1e-9) { r.status = 'uTooLow'; return r; }

    r.RCalc = r.URef / inp.I;
    r.std = nextStdValue(r.RCalc, inp.series);
    if (!r.std) { r.status = 'noStdValue'; return r; }
    r.R = r.std.value;
    r.IAct = r.URef / r.R;
    r.PR = r.URef * r.IAct;
    r.RRating = recommendRating(r.PR);
    if (r.RRating === 0) r.warnings.push('rPower');

    r.PLossMin = (U1 - r.ULeds - r.URef) * r.IAct;
    r.PLossMax = (U2 - r.ULeds - r.URef) * r.IAct;
    r.part = choosePart(inp.circuit, r.IAct, r.PLossMax);
    if (r.PLossMax > PART_P_FREE[r.part]) {
      r.warnings.push('heatsink');
      r.heatsinkRth = KSQ_DELTA_T / r.PLossMax - PART_RTH_JC[r.part] - KSQ_RTH_CS;
      if (r.heatsinkRth < 1.0) { r.warnings.push('tooHot'); r.heatsinkRth = 0; }
    }

    if (inp.circuit === 'lm317') {
      if (r.IAct < LM317_I_MIN) r.warnings.push('minLoad');
      r.ksqRise = 0;
    } else {
      r.beta1 = partBeta(r.part);
      r.IB1 = r.IAct / r.beta1;
      r.IRB = Math.max(KSQ_IRB_MIN, KSQ_IRB_FACTOR * r.IB1);
      var UBase = KSQ_UBE_SENSE + KSQ_UBE_T1;
      if (U1 - UBase < 0.1) { r.status = 'uTooLow'; return r; }
      r.RBCalc = (U1 - UBase) / r.IRB;
      r.RBStd = prevStdValue(r.RBCalc, inp.series);
      if (!r.RBStd) { r.status = 'noStdValue'; return r; }
      r.RB = r.RBStd.value;
      r.IRBMax = (U2 - UBase) / r.RB;
      r.PRB = Math.pow(U2 - UBase, 2) / r.RB;
      r.RBRating = recommendRating(r.PRB);
      if (r.RBRating === 0 || r.RBRating > 0.25 || r.IRBMax > 0.1) r.warnings.push('baseHigh');
      r.ksqRise = KSQ_UT * Math.log((U2 - UBase) / (U1 - UBase)) / KSQ_UBE_SENSE;
    }

    if (U1 > r.ULeds) {
      r.RvCalc = (U1 - r.ULeds) / inp.I;
      r.RvRise = (U2 - r.ULeds) / (U1 - r.ULeds) - 1;
    }
    return r;
  }

  /* ===========================================================================
     uAc - WECHSELSTROM
     =========================================================================== */
  var AC_FREQ = 50.0, AC_U_MAX = 42.0, AC_I_MAX = 1.0, AC_UD_DIODE = 0.7, AC_BRIDGE_DIODES = 2,
      AC_RIPPLE = 0.2, AC_CAP_MARGIN = 1.25, AC_CAP_BIG = 4700e-6, AC_1N4148_I_PEAK = 0.3,
      AC_UR_MIN = 1.0, AC_UR_FRAC = 0.25, AC_I_REV_MAX = 1.0, AC_DIM_MIN = 0.2;
  var CAP_DIGITS = [10, 15, 22, 33, 47, 68];                 // Elko-Werte pro Dekade (E6) × 10
  var CAP_VOLTS = [10, 16, 25, 35, 50, 63, 100];             // übliche Nennspannungen (V)
  var AC_POWER_RATINGS = [2, 3, 5, 10, 25, 50, 100];               // Leistungswiderstände über 1 W

  // nächster Elko-Normwert darüber (E6); 0 bei ungültigem C
  function nextCapValue(C) {
    if (!(C > 0)) return 0;
    var dec10 = Math.pow(10, Math.floor(Math.log10(C) + 1e-9));
    for (var i = 0; i < CAP_DIGITS.length; i++)
      if (CAP_DIGITS[i] / 10 * dec10 >= C * (1 - 1e-9)) return CAP_DIGITS[i] / 10 * dec10;
    return 10 * dec10;
  }
  // kleinste übliche Nennspannung, die mindestens U ist; 0 wenn auch 100 V nicht reicht
  function capVoltage(U) {
    for (var i = 0; i < CAP_VOLTS.length; i++) if (CAP_VOLTS[i] >= U - 1e-9) return CAP_VOLTS[i];
    return 0;
  }
  // mittlerer Strom einer Halbwelle über eine ganze Periode (A)
  function halfWaveAvg(UPeak, ULeds, R) {
    if (UPeak <= ULeds || R <= 0) return 0;
    var T = Math.asin(Math.max(0, ULeds) / UPeak);
    return (2 * UPeak * Math.cos(T) - ULeds * (Math.PI - 2 * T)) / (2 * Math.PI * R);
  }
  // mittlere Leistung in R während einer Halbwelle, über eine ganze Periode (W)
  function halfWavePower(UPeak, ULeds, R) {
    if (UPeak <= ULeds || R <= 0) return 0;
    var A = UPeak, B = Math.max(0, ULeds), T = Math.asin(B / A);
    return (A * A * ((Math.PI - 2 * T) / 2 + Math.sin(2 * T) / 2) - 4 * A * B * Math.cos(T)
      + B * B * (Math.PI - 2 * T)) / (2 * Math.PI * R);
  }

  /* Input: { circuit: 'simple'|'bridge', U, Ud, I, N, series } */
  function calculateAc(inp) {
    var r = { status: 'ok', warnings: [], UPeak: 0, ULeds: 0, UNeedAc: 0, RCalc: 0, std: null,
              R: 0, PR: 0, RRating: 0, PLeds: 0, IPeak: 0, IAvg: 0, brightness: 0, theta: 0,
              IRevPeak: 0, URevLed: 0, URevDiode: 0, diode: '1N4148', UDc: 0, rippleCalc: 0,
              CCalc: 0, C: 0, CVolt: 0, ripple: 0, UMean: 0, IAct: 0, IRipple: 0 };
    // ----- 1. Eingaben prüfen -----
    if (!(inp.U > 0)) r.status = 'invalidU';
    else if (!(inp.Ud > 0)) r.status = 'invalidUd';
    else if (!(inp.I > 0)) r.status = 'invalidI';
    else if (inp.N < 1) r.status = 'invalidN';
    else if (inp.U > AC_U_MAX + 1e-9) r.status = 'overVoltage';
    else if (inp.I > AC_I_MAX + 1e-9) r.status = 'tooMuchCurrent';
    if (r.status !== 'ok') return r;

    // ----- 2. Spannungen -----
    var bridge = inp.circuit === 'bridge';
    r.UPeak = inp.U * Math.SQRT2;
    r.ULeds = inp.N * inp.Ud;
    var UDrop = bridge ? AC_BRIDGE_DIODES * AC_UD_DIODE : 0;
    // mindestens 1 V und ein Viertel der Spitze (bzw. Elko-Spannung) am Widerstand
    function needAc(UL) {
      if (bridge) return (Math.max(UL + AC_UR_MIN * (1 + AC_RIPPLE / 2),
        UL / (1 - AC_UR_FRAC * (1 + AC_RIPPLE / 2))) + UDrop) / Math.SQRT2;
      return Math.max(UL + AC_UR_MIN, UL / (1 - AC_UR_FRAC)) / Math.SQRT2;
    }
    r.UNeedAc = needAc(r.ULeds);
    if (inp.U < r.UNeedAc - 1e-9) {
      r.status = 'uTooLow';
      r.NMax = inp.N - 1;                            // so viele LEDs gingen (0 = keine)
      while (r.NMax > 0 && inp.U < needAc(r.NMax * inp.Ud) - 1e-9) r.NMax--;
      return r;
    }

    if (!bridge) {
      // ----- 3a. Einfach: Vorwiderstand + Schutzdiode -----
      r.RCalc = (r.UPeak - r.ULeds) / inp.I;
      r.std = nextStdValue(r.RCalc, inp.series);
      if (!r.std) { r.status = 'noStdValue'; return r; }
      r.R = r.std.value;
      r.IPeak = (r.UPeak - r.ULeds) / r.R;
      r.theta = Math.asin(r.ULeds / r.UPeak);
      r.IAvg = halfWaveAvg(r.UPeak, r.ULeds, r.R);
      r.brightness = r.IAvg / inp.I;
      r.PR = halfWavePower(r.UPeak, r.ULeds, r.R) + halfWavePower(r.UPeak, AC_UD_DIODE, r.R);
      r.PLeds = r.ULeds * r.IAvg;
      r.IRevPeak = (r.UPeak - AC_UD_DIODE) / r.R;
      r.diode = r.IRevPeak <= AC_1N4148_I_PEAK ? '1N4148' : '1N4007';
      r.URevLed = AC_UD_DIODE;
      r.URevDiode = r.ULeds;
      if (r.IRevPeak > AC_I_REV_MAX + 1e-9) { r.status = 'revTooHigh'; return r; }  // Rückstrom durch D
      if (r.brightness < AC_DIM_MIN) r.warnings.push('dim');
    } else {
      // ----- 3b. Ohne Flackern: Gleichrichter + Elko -----
      r.UDc = r.UPeak - UDrop;
      r.rippleCalc = AC_RIPPLE * (r.UDc - r.ULeds) / (1 + AC_RIPPLE / 2);
      r.CCalc = inp.I / (2 * AC_FREQ * r.rippleCalc);
      r.C = nextCapValue(r.CCalc);
      if (r.C <= 0) { r.status = 'noStdValue'; return r; }
      r.ripple = inp.I / (2 * AC_FREQ * r.C);
      r.UMean = r.UDc - r.ripple / 2;
      r.CVolt = capVoltage(AC_CAP_MARGIN * r.UDc);
      var URes = r.UMean - r.ULeds;
      r.RCalc = URes / inp.I;
      r.std = nextStdValue(r.RCalc, inp.series);
      if (!r.std) { r.status = 'noStdValue'; return r; }
      r.R = r.std.value;
      r.IAct = URes / r.R;
      r.IPeak = r.IAct;
      r.IAvg = r.IAct;
      r.brightness = r.IAct / inp.I;
      r.IRipple = r.IAct / (2 * AC_FREQ * r.C) / 2 / URes;
      r.PR = URes * r.IAct;
      r.PLeds = r.ULeds * r.IAct;
      if (r.C > AC_CAP_BIG * (1 + 1e-9)) r.warnings.push('bigCap');
    }
    r.RRating = recommendRating(r.PR);
    if (r.RRating === 0) {
      // Leistungswiderstand: übliche Bauform mit doppelter Reserve (0 = über 100 W)
      r.warnings.push('rPower');
      for (var k = 0; k < AC_POWER_RATINGS.length; k++)
        if (r.PR <= AC_POWER_RATINGS[k] / 2) { r.RRating = AC_POWER_RATINGS[k]; break; }
    }
    return r;
  }

  /* ===========================================================================
     uFormat - ZAHLEN ALS TEXT
     =========================================================================== */
  var fmtSet = { dec: ',', pct: ' ' };   // Deutsch: «4,7» und «66 %»; Englisch: «4.7» und «66%»

  /* FloatToStrF(V, ffFixed, 15, Dec): erst auf 15 gültige Stellen, dann
     kaufmännisch (Hälfte weg von 0) auf Dec Nachkommastellen runden. */
  function toFixedPas(v, dec) {
    if (v === 0) return dec > 0 ? '0.' + '0'.repeat(dec) : '0';
    var neg = v < 0;
    var a = Math.abs(v);
    var p = a.toPrecision(15);                       // z. B. "16.9650000000000"
    var m, digits, e;
    // in Ziffern und Exponent zerlegen
    if (p.indexOf('e') >= 0) {
      var parts = p.split('e');
      m = parts[0]; e = parseInt(parts[1], 10);
    } else { m = p; e = 0; }
    var ip = m.split('.')[0], fp = m.split('.')[1] || '';
    digits = ip + fp;
    var pointPos = ip.length + e;                    // Ziffern vor dem Komma
    // auf dec Nachkommastellen runden
    var keep = pointPos + dec;
    var arr = digits.split('').map(Number);
    while (arr.length < keep + 1) arr.push(0);
    if (keep < 0) return (dec > 0 ? '0.' + '0'.repeat(dec) : '0');
    var roundUp = arr[keep] >= 5;
    arr = arr.slice(0, keep);
    if (roundUp) {
      var i = arr.length - 1;
      while (i >= 0) { if (arr[i] === 9) { arr[i] = 0; i--; } else { arr[i]++; break; } }
      if (i < 0) { arr.unshift(1); pointPos++; }
    }
    var intPart, fracPart;
    if (pointPos <= 0) {
      intPart = '0';
      fracPart = '0'.repeat(-pointPos) + arr.join('');
      fracPart = fracPart.slice(0, dec);
    } else {
      intPart = arr.slice(0, pointPos).join('') || '0';
      fracPart = arr.slice(pointPos).join('');
    }
    while (fracPart.length < dec) fracPart += '0';
    intPart = intPart.replace(/^0+(?=\d)/, '');
    var s = dec > 0 ? intPart + '.' + fracPart : intPart;
    if (neg && /[1-9]/.test(s)) s = '-' + s;
    return s;
  }

  function formatNum(v, maxDec, minDec) {
    var s = toFixedPas(v, maxDec).replace('.', fmtSet.dec);
    var p = s.indexOf(fmtSet.dec);
    if (p >= 0) {
      while (s.length - 1 - p > minDec && s.charAt(s.length - 1) === '0') s = s.slice(0, -1);
      if (s.charAt(s.length - 1) === fmtSet.dec) s = s.slice(0, -1);
    }
    if (s === '-0') s = '0';
    return s;
  }
  function formatVolt(v) { return formatNum(v, 2, 0) + ' V'; }
  function formatOhm(r) {
    if (Math.abs(r) >= 1e6) return formatNum(r / 1e6, 2, 0) + ' MΩ';
    if (Math.abs(r) >= 1e3) return formatNum(r / 1e3, 2, 0) + ' kΩ';
    return formatNum(r, 2, 0) + ' Ω';
  }
  function formatMilliAmp(i) { return formatNum(i * 1000, 2, 1) + ' mA'; }
  function formatPower(p) {
    if (Math.abs(p) >= 1) return formatNum(p, 2, 0) + ' W';
    return formatNum(p * 1000, 1, 1) + ' mW';
  }
  function sameValue(a, b) { return Math.abs(a - b) <= Math.max(Math.min(Math.abs(a), Math.abs(b)) * 1e-12, 1e-12); }
  function formatRating(w) {
    if (sameValue(w, 0.125)) return '⅛ W';
    if (sameValue(w, 0.25)) return '¼ W';
    if (sameValue(w, 0.5)) return '½ W';
    return formatNum(w, 2, 0) + ' W';
  }
  function formatPercent(x) { return String(pasRound(x * 100)) + fmtSet.pct + '%'; }
  function formatPercent1(x) { return formatNum(x * 100, 1, 0) + fmtSet.pct + '%'; }
  function formatSig(v, n) {
    if (v === 0) return '0';
    var dec = n - 1 - floorLog10(Math.abs(v));
    if (dec < 0) dec = 0;
    return formatNum(v, dec, 0);
  }
  function formatSeconds(t) { return t >= 0.1 ? formatSig(t, 3) + ' s' : formatSig(t * 1000, 3) + ' ms'; }
  function formatFreq(f) { return f >= 1000 ? formatSig(f / 1000, 3) + ' kHz' : formatSig(f, 3) + ' Hz'; }
  function formatCap(c) {
    if (c >= 1e-6 * 0.9999) return formatSig(c * 1e6, 3) + ' µF';
    if (c >= 1e-9 * 0.9999) return formatSig(c * 1e9, 3) + ' nF';
    return formatSig(c * 1e12, 3) + ' pF';
  }

  global.LPR = {
    pasRound: pasRound, ES: ES, BC: BC,
    nextStdValue: nextStdValue, prevStdValue: prevStdValue, nearestStdValue: nearestStdValue,
    colorBands: colorBands,
    RATINGS: RATINGS, LOAD_WARN: LOAD_WARN, RATING_REFERENCE: RATING_REFERENCE,
    RTH_QUARTER_WATT: RTH_QUARTER_WATT, LED_DEFAULT_UD: LED_DEFAULT_UD,
    loadLevelOf: loadLevelOf, recommendRating: recommendRating, estimateTempRise: estimateTempRise,
    parseDecimal: parseDecimal, calculate: calculate,
    NE555_DROP_HIGH: NE555_DROP_HIGH, NE555_LOW: NE555_LOW, BJT_UCE_SAT: BJT_UCE_SAT,
    BJT_UBE: BJT_UBE, BJT_BETA: BJT_BETA, multiFactor: multiFactor, ledResistor: ledResistor,
    calculateBlink: calculateBlink,
    KSQ_UBE_TC: KSQ_UBE_TC, KSQ_UBE_SENSE: KSQ_UBE_SENSE, partBeta: partBeta,
    calculateKsq: calculateKsq,
    AC_UD_DIODE: AC_UD_DIODE, AC_U_MAX: AC_U_MAX, AC_I_MAX: AC_I_MAX, AC_I_REV_MAX: AC_I_REV_MAX,
    nextCapValue: nextCapValue, capVoltage: capVoltage, calculateAc: calculateAc,
    fmtSet: fmtSet, sameValue: sameValue, formatNum: formatNum, formatVolt: formatVolt,
    formatOhm: formatOhm, formatMilliAmp: formatMilliAmp, formatPower: formatPower,
    formatRating: formatRating, formatPercent: formatPercent, formatPercent1: formatPercent1,
    formatSig: formatSig, formatSeconds: formatSeconds, formatFreq: formatFreq, formatCap: formatCap
  };
})(typeof window !== 'undefined' ? window : globalThis);
