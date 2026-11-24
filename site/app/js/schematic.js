/* ==============================================================================
   schematic.js - Schaltpläne als SVG
   ==============================================================================
   Zweck:     Übertragung von uSchematic, uBlinkSchematic und uKsqSchematic
              (Windows 2.5.2). Alle Koordinaten sind die Vorlagen-Punkte der
              Pascal-Units; das SVG skaliert sie über die viewBox, darum sind
              die Pläne bei jeder Grösse scharf.
                resistor  Vorlage 460 × 240  (Vorwiderstand, Stränge parallel)
                ne555     Vorlage 580 × 320
                multi     Vorlage 600 × 300  (Multivibrator, 2 × BC547)
                lm317     Vorlage 580 × 300
                ksqT      Vorlage 600 × 300  (Konstantstrom mit 2 Transistoren)
                acSimple  Vorlage 580 × 300  (Wechselstrom mit Schutzdiode)
                acBridge  Vorlage 580 × 300  (Wechselstrom mit Gleichrichter und Elko)
   Polarität: LEDs zeigen mit der Spitze nach unten (Anode oben, Kathode mit
              Querstrich unten), Elkos mit «+» an der Platte zur höheren
              Spannung, NPN mit Emitterpfeil nach aussen, NE555-Pins wie im
              Datenblatt. Jede Lage ist aus der Pascal-Vorlage übernommen.
   Autor:     Elospeed
   Versionen: 2.5.2-html 18.11.2026  erste Fassung
              2.7        23.11.2026  Wechselstrom (Trafo, Schutzdiode, Gleichrichter)
   ============================================================================== */
(function (global) {
  'use strict';

  var COL = {
    line: '#C9D1DA', text: '#C9D1DA', accent: '#5AA9FF', dim: '#7F8A96', body: '#23272E',
    wire: '#9AA3AB', resBody: '#E3C992', resEdge: '#9C804C'
  };
  var BAND = ['#1A1A1A', '#7A4A1D', '#D02A2A', '#F07A10', '#F4C300', '#2EA043',
              '#2F6BD8', '#8A3FD1', '#8C8C8C', '#F4F4F4', '#C9A33A', '#B8BCC2'];
  var FONT = '"Segoe UI", system-ui, -apple-system, Arial, sans-serif';
  // Pascal setzt eine negative Font.Height: das ist die Schriftgrösse (em) in Pixeln
  var EM = 1;

  function esc(s) {
    return String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
  }
  function n(v) { return Math.round(v * 100) / 100; }

  /* Zeichenhilfe: sammelt SVG-Elemente als Text */
  function Pen() { this.out = []; }
  Pen.prototype.line = function (x1, y1, x2, y2, c, w, extra) {
    this.out.push('<line x1="' + n(x1) + '" y1="' + n(y1) + '" x2="' + n(x2) + '" y2="' + n(y2) +
      '" stroke="' + c + '" stroke-width="' + w + '" stroke-linecap="' + (extra || 'butt') + '"/>');
  };
  Pen.prototype.poly = function (pts, c, w) {          // offener Linienzug
    var p = [];
    for (var i = 0; i < pts.length; i += 2) p.push(n(pts[i]) + ',' + n(pts[i + 1]));
    this.out.push('<polyline points="' + p.join(' ') + '" fill="none" stroke="' + c + '" stroke-width="' + w +
      '" stroke-linejoin="miter" stroke-linecap="butt"/>');
  };
  Pen.prototype.polygon = function (pts, fill, stroke, w) {
    var p = [];
    for (var i = 0; i < pts.length; i += 2) p.push(n(pts[i]) + ',' + n(pts[i + 1]));
    this.out.push('<polygon points="' + p.join(' ') + '" fill="' + fill + '"' +
      (stroke ? ' stroke="' + stroke + '" stroke-width="' + w + '" stroke-linejoin="miter"' : '') + '/>');
  };
  Pen.prototype.rect = function (x1, y1, x2, y2, fill, stroke, w, rx) {
    this.out.push('<rect x="' + n(Math.min(x1, x2)) + '" y="' + n(Math.min(y1, y2)) + '" width="' + n(Math.abs(x2 - x1)) +
      '" height="' + n(Math.abs(y2 - y1)) + '"' + (rx ? ' rx="' + n(rx) + '"' : '') + ' fill="' + (fill || 'none') + '"' +
      (stroke ? ' stroke="' + stroke + '" stroke-width="' + w + '"' : '') + '/>');
  };
  Pen.prototype.circle = function (cx, cy, r, fill, stroke, w) {
    this.out.push('<circle cx="' + n(cx) + '" cy="' + n(cy) + '" r="' + n(r) + '" fill="' + (fill || 'none') + '"' +
      (stroke ? ' stroke="' + stroke + '" stroke-width="' + w + '"' : '') + '/>');
  };
  Pen.prototype.path = function (d, fill, stroke, w) {
    this.out.push('<path d="' + d + '" fill="' + (fill || 'none') + '"' +
      (stroke ? ' stroke="' + stroke + '" stroke-width="' + w + '"' : '') + '/>');
  };
  /* Text mit Auszeichnung: «_X» tiefgestellt, «**» fett. BaseY = Grundlinie.
     Align 0 = links, 1 = Mitte, 2 = rechts; H = Zeilenhöhe der Vorlage. */
  Pen.prototype.txt = function (x, baseY, t, color, align, bold, H) {
    if (!t) return;
    var size = (H || 12) * EM;
    var anchor = align === 1 ? 'middle' : (align === 2 ? 'end' : 'start');
    var parts = [], i = 0, sub = false, run = '', shifted = false;
    var dy = n(size * 0.22);
    function flush(isSub) {
      if (!run) return;
      if (isSub) {
        // tiefgestellt wie WalkRich: 72 % gross, 1 px Abstand danach; mehrere
        // tiefgestellte Zeichen hintereinander bleiben auf derselben Linie
        parts.push('<tspan font-size="' + n(size * 0.72) + '"' + (shifted ? '' : ' dy="' + dy + '"') + '>' + esc(run) + '</tspan>');
        shifted = true;
      } else {
        parts.push('<tspan' + (shifted ? ' dy="-' + dy + '"' : '') + '>' + esc(run) + '</tspan>');
        shifted = false;
      }
      run = '';
    }
    var curSub = false;
    var chars = Array.from(String(t).replace(/\*\*/g, ''));
    for (i = 0; i < chars.length; i++) {
      var ch = chars[i];
      if (ch === '_' && i < chars.length - 1) { sub = true; continue; }
      if (sub !== curSub) { flush(curSub); curSub = sub; }
      run += ch;
      if (sub) { flush(true); sub = false; curSub = false; }
    }
    flush(curSub);
    if (shifted) parts.push('<tspan dy="-' + dy + '">​</tspan>');
    this.out.push('<text x="' + n(x) + '" y="' + n(baseY) + '" fill="' + color + '" font-size="' + n(size) +
      '" text-anchor="' + anchor + '"' + (bold ? ' font-weight="700"' : '') + '>' + parts.join('') + '</text>');
  };
  Pen.prototype.svg = function (w, h, cls) {
    return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ' + w + ' ' + h + '" preserveAspectRatio="xMidYMid meet"' +
      ' font-family=\'' + FONT + '\' class="' + (cls || '') + '">' + this.out.join('') + '</svg>';
  };

  /* --------------------------------------------------------------------------
     DrawResistor (uSchematic): Widerstand mit Farbringen waagrecht in Rect,
     Draht quer durch, beiger Körper 20 % ... 80 %, Ringe ab 15 %, Toleranz bei 78 %.
     -------------------------------------------------------------------------- */
  function drawResistor(P, L, T, R, B, bands) {
    var W = R - L, H = B - T;
    if (W < 4 || H < 2) return;
    P.line(L, T + H / 2, R, T + H / 2, COL.wire, Math.max(H / 12, 0.8));
    var bl = L + W * 0.20, br = L + W * 0.80, bt = T + H / 7, bb = B - H / 7;
    var rad = (bb - bt) * 0.4;
    P.rect(bl, bt, br, bb, COL.resBody, COL.resEdge, Math.max(H / 22, 0.6), rad);
    if (!bands || bands.length < 3) return;
    var N = bands.length, bw = Math.max(1, (br - bl) * 0.09);
    for (var i = 0; i < N; i++) {
      var pct = (i < N - 1) ? (15 + i * Math.floor(55 / (N - 1))) : 78;
      var x = bl + (br - bl) * pct / 100;
      P.rect(x, bt + H / 40, x + bw, bb, BAND[bands[i]]);
    }
  }

  /* Einzelner Widerstand für die Resultatkarten (eigenes kleines SVG) */
  function resistorSvg(bands, w, h) {
    var P = new Pen();
    drawResistor(P, 0, 0, w, h, bands);
    return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ' + w + ' ' + h + '" width="' + w + '" height="' + h + '">' + P.out.join('') + '</svg>';
  }

  /* ==========================================================================
     VORWIDERSTAND (uSchematic.DrawSchematic), Vorlage 460 × 240
     V: UBText, RText, URText, LedText, UFText, IText, StringsText, IStringText,
        String1Text, StringLastText, LedCount, StringCount, LedColor, Bands
     ========================================================================== */
  function resistor(V) {
    var P = new Pen(), C = COL;
    var labelY = 0;
    var S2_X = 415, S2_Y = 9, S2_R1 = 300, S2_R2 = 390;

    function drawLed(cx, top, sc) {
      P.polygon([cx - 18 * sc, top, cx + 18 * sc, top, cx, top + 38 * sc], V.LedColor, C.line, 2);
      P.line(cx - 20 * sc, top + 40 * sc, cx + 20 * sc, top + 40 * sc, C.line, 2.5);  // Kathode
      P.line(cx + 22 * sc, top + 12 * sc, cx + 42 * sc, top - 2 * sc, C.line, 2);
      P.line(cx + 26 * sc, top + 24 * sc, cx + 46 * sc, top + 10 * sc, C.line, 2);
      P.polygon([cx + 42 * sc, top - 2 * sc, cx + 33 * sc, top - 1 * sc, cx + 38 * sc, top + 5 * sc], C.line);
      P.polygon([cx + 46 * sc, top + 10 * sc, cx + 37 * sc, top + 11 * sc, cx + 42 * sc, top + 17 * sc], C.line);
    }
    function drawResistorBox(x1, x2, ym, hh) {
      P.rect(x1, ym - hh / 2, x2, ym + hh / 2, C.body, C.line, 2);
      if (V.Bands && V.Bands.length >= 3) drawResistor(P, x1 + 2, ym - hh / 2 + 2, x2 - 2, ym + hh / 2 - 2, V.Bands);
      P.rect(x1, ym - hh / 2, x2, ym + hh / 2, null, C.line, 2);
    }
    function drawLedColumn(cx, yTop) {
      var N = Math.max(1, V.LedCount || 0), K = Math.min(N, 3), GAP = 14;
      var sc = K === 1 ? 1 : (K === 2 ? 0.9 : 0.72);
      if ((V.StringCount || 0) > 1) sc *= 0.85;
      var H = 40 * sc, top = 120 - (K * H + (K - 1) * GAP) / 2;
      P.line(cx, yTop, cx, top, C.line, 2);
      var yy = top;
      for (var i = 1; i <= K; i++) {
        if (N > 3 && i === 2) {
          P.circle(cx, yy + H * 0.2, 2.2, C.line);
          P.circle(cx, yy + H * 0.5, 2.2, C.line);
          P.circle(cx, yy + H * 0.8, 2.2, C.line);
        } else drawLed(cx, yy, sc);
        if (i < K) P.line(cx, yy + H, cx, yy + H + GAP, C.line, 2);
        yy += H + GAP;
      }
      P.line(cx, yy - GAP, cx, 205, C.line, 2);
      labelY = yy - GAP + 10;
    }
    function drawSecondString() {
      P.poly([110, 40, 110, S2_Y, S2_R1, S2_Y], C.line, 2);
      drawResistorBox(S2_R1, S2_R2, S2_Y, 18);
      P.line(S2_R2, S2_Y, S2_X, S2_Y, C.line, 2);
      drawLedColumn(S2_X, S2_Y);
      P.line(S2_X, 205, 350, 205, C.line, 2);
      P.circle(110, 40, 3.5, C.line);
      P.circle(350, 205, 3.5, C.line);
    }

    if ((V.StringCount || 0) > 1) drawSecondString();
    P.poly([70, 108, 70, 40, 160, 40], C.line, 2);
    P.line(250, 40, 350, 40, C.line, 2);
    P.poly([350, 205, 70, 205, 70, 128], C.line, 2);
    P.line(48, 108, 92, 108, C.line, 2.5);           // Quelle: langer Strich = +
    P.line(59, 128, 81, 128, C.line, 6);             // kurzer dicker Strich = −
    drawResistorBox(160, 250, 40, 22);
    drawLedColumn(350, 40);
    P.polygon([200, 205, 212, 199, 212, 211], C.accent);   // Stromrichtung nach links (zum Minuspol)

    P.txt(40, 104, '+', C.line, 2, false, 14);
    P.txt(40, 134, '−', C.line, 2, false, 14);
    P.txt(96, 123, V.UBText, C.line, 0, false);
    P.txt(205, 22, V.RText, C.accent, 1, true);
    P.txt(205, 70, V.URText, C.line, 1, false);
    if ((V.StringCount || 0) > 1) {
      P.txt(326, 174, V.LedText, C.line, 2, false);
      P.txt(326, 190, V.UFText, C.line, 2, false);
      P.txt(350, 222, V.String1Text, C.line, 1, false);
      P.txt(S2_X, 222, V.StringLastText, C.line, 1, false);
    } else {
      P.txt(378, labelY, V.LedText, C.line, 0, false);
      P.txt(378, labelY + 16, V.UFText, C.line, 0, false);
    }
    if (V.StringsText) P.txt(96, 150, V.StringsText, C.accent, 0, true);
    P.txt(96, 168, V.IStringText, C.line, 0, false);
    P.txt(210, 226, V.IText, C.accent, 1, true);
    return P.svg(460, 240);
  }

  /* ==========================================================================
     ZEICHENHILFEN DER BLINK- UND KONSTANTSTROM-PLÄNE (uBlinkSchematic)
     ========================================================================== */
  function wire(P, pts) { P.poly(pts, COL.line, 1.6); }
  function dot(P, x, y) { P.circle(x, y, 2.8, COL.line); }
  function resV(P, x, y1, y2) {           // Zeitwiderstand: Rand hervorgehoben
    P.rect(x - 9, y1, x + 9, y2, COL.body, COL.accent, 1.8);
  }
  function resBands(P, x, y1, y2, bands) {  // Widerstand mit Farbringen, senkrecht
    var p = 1;
    P.rect(x - 9, y1, x + 9, y2, COL.resEdge);
    P.rect(x - 9 + p, y1 + p, x + 9 - p, y2 - p, COL.resBody);
    if (bands && bands.length >= 3) {
      var N = bands.length, bh = Math.max(2 * p, (y2 - y1) * 0.08);
      for (var i = 0; i < N; i++) {
        var pct = (i < N - 1) ? (12 + i * Math.floor(52 / (N - 1))) : 80;
        var y = y1 + (y2 - y1) * pct / 100;
        P.rect(x - 9 + p, y, x + 9 - p, y + bh, BAND[bands[i]]);
      }
    }
  }
  function ledDown(P, x, top, lit, ledColor, ledOff) {   // Anode oben, Kathode unten
    P.polygon([x - 14, top, x + 14, top, x, top + 24], lit ? ledColor : ledOff, COL.line, 1.6);
    P.line(x - 14, top + 24, x + 14, top + 24, COL.line, 2.2);
    if (lit) {
      P.line(x + 18, top + 6, x + 32, top - 4, ledColor, 1.6);
      P.line(x + 22, top + 16, x + 36, top + 6, ledColor, 1.6);
      P.polygon([x + 32, top - 4, x + 24, top - 3, x + 28, top + 3], ledColor);
      P.polygon([x + 36, top + 6, x + 28, top + 7, x + 32, top + 13], ledColor);
    }
  }
  function capV(P, x, y, elko) {          // Platten waagrecht bei y und y + 8
    P.line(x - 14, y, x + 14, y, COL.line, 2.4);
    P.line(x - 14, y + 8, x + 14, y + 8, COL.line, 2.4);
    if (elko) P.txt(x + 17, y - 1, '+', COL.dim, 0, false);
  }
  function capH(P, x, y, elko, plusRight) {   // Platten senkrecht bei x und x + 8
    P.line(x, y - 12, x, y + 12, COL.line, 2.4);
    P.line(x + 8, y - 12, x + 8, y + 12, COL.line, 2.4);
    if (elko) {
      if (plusRight) P.txt(x + 12, y - 14, '+', COL.dim, 0, false);
      else P.txt(x - 4, y - 14, '+', COL.dim, 2, false);
    }
  }
  function txtCap(P, bx, baseY, t) {      // «C1 = 22 µF/16 V» in zwei Zeilen
    var i = t.indexOf('/');
    if (i < 0) { P.txt(bx, baseY, t, COL.accent, 1, true); return; }
    P.txt(bx, baseY, t.slice(0, i), COL.accent, 1, true);
    P.txt(bx, baseY + 13, t.slice(i + 1), COL.accent, 1, false);
  }
  /* NPN: Kreis um (cx, cy), Basisbalken bei BX, Kollektor oben und Emitter
     unten schräg zur Leitung PX; Pfeil am Emitter zeigt nach aussen. */
  function npn(P, cx, cy, px, fromLeft) {
    var bx = fromLeft ? cx - 14 : cx + 14;
    P.circle(cx, cy, 25, null, COL.line, 1.6);
    P.line(bx, cy - 17, bx, cy + 17, COL.line, 3);
    wire(P, [bx, cy - 8, px, cy - 22]);
    wire(P, [bx, cy + 8, px, cy + 22]);
    var dx = px - bx, dy = 14, l = Math.sqrt(dx * dx + dy * dy);
    dx /= l; dy /= l;
    var tx = px - dx * 3, ty = cy + 22 - dy * 3, bx2 = tx - dx * 12, by2 = ty - dy * 12;
    P.polygon([tx, ty, bx2 + dy * 5, by2 - dx * 5, bx2 - dy * 5, by2 + dx * 5], COL.line);
  }
  function diodeH(P, xa, xk, y, color) {  // Dreieck zeigt zur Kathode, dort der Querstrich
    var dir = xk >= xa ? 1 : -1, xt = xk - dir * 6;
    P.line(xa, y, xa + dir * 6, y, color, 1.6);
    P.line(xt, y, xk, y, color, 1.6);
    P.polygon([xa + dir * 6, y - 9, xa + dir * 6, y + 9, xt, y], color);
    P.line(xt, y - 9, xt, y + 9, color, 2.2);
  }
  function wireHop(P, x1, y, x2, hopX) {  // Kreuzung ohne Verbindung: kleiner Bogen
    var dir = x2 >= x1 ? 1 : -1, HR = 6;
    var d = 'M' + n(x1) + ' ' + n(y) + ' L' + n(hopX - dir * HR) + ' ' + n(y) +
      ' A' + HR + ' ' + HR + ' 0 0 ' + (dir > 0 ? 1 : 0) + ' ' + n(hopX + dir * HR) + ' ' + n(y) + ' L' + n(x2) + ' ' + n(y);
    P.path(d, null, COL.line, 1.6);
  }

  /* ==========================================================================
     NE555 ASTABIL (DrawSchematic555), Vorlage 580 × 320
     ========================================================================== */
  function ne555(V) {
    var P = new Pen(), C = COL, outEnd;
    wire(P, [60, 30, 520, 30]);
    wire(P, [60, 295, 520, 295]);
    // Zeitglied: R1 von +Ub nach Pin 7, R2 von Pin 7 nach C, C nach Masse
    wire(P, [170, 30, 170, 48]);
    wire(P, [170, 92, 170, 132]);
    wire(P, [170, 120, 250, 120]);
    wire(P, [170, 176, 170, 236]);
    wire(P, [170, 185, 220, 185]);
    wire(P, [250, 170, 220, 170, 220, 200, 250, 200]);
    wire(P, [170, 244, 170, 295]);
    if (V.Diode) {
      // Diode über R2: Anode an Pin 7 (oben), Kathode zum Kondensator (unten)
      wire(P, [170, 124, 136, 124, 136, 140]);
      wire(P, [136, 166, 136, 181, 170, 181]);
      P.polygon([126, 140, 146, 140, 136, 160], C.line, C.line, 1.6);
      P.line(126, 161, 146, 161, C.line, 2.2);
      dot(P, 170, 124);
      dot(P, 170, 181);
    }
    resV(P, 170, 48, 92);
    resV(P, 170, 132, 176);
    capV(P, 170, 236, V.Elko);
    dot(P, 170, 120); dot(P, 170, 185); dot(P, 220, 185);
    // Pin 8 und 4 an +Ub, Pin 1 an Masse, Pin 5 über 10 nF an Masse
    wire(P, [276, 90, 276, 30]);
    wire(P, [336, 90, 336, 30]);
    wire(P, [310, 250, 310, 295]);
    wire(P, [370, 220, 400, 220, 400, 250]);
    wire(P, [400, 258, 400, 295]);
    capV(P, 400, 250, false);
    P.rect(250, 90, 370, 250, C.body, C.line, 1.6);
    // Ausgang Pin 3
    outEnd = (V.Conn === 'vcc') ? 430 : 470;
    wire(P, [370, 150, outEnd, 150]);
    if (V.Conn === 'gnd' || V.Conn === 'both') {
      // Pin 3 -> R_V1 -> LED 1 (Anode oben) -> Masse: leuchtet bei High
      wire(P, [470, 150, 470, 160]);
      wire(P, [470, 204, 470, 228]);
      wire(P, [470, 252, 470, 295]);
      resBands(P, 470, 160, 204, V.Bands1);
      ledDown(P, 470, 228, V.Led1Lit, V.LedColor, V.LedOff);
    }
    if (V.Conn === 'vcc' || V.Conn === 'both') {
      // +Ub -> LED (Anode oben) -> R_V -> Pin 3: leuchtet bei Low
      wire(P, [430, 30, 430, 44]);
      wire(P, [430, 68, 430, 82]);
      wire(P, [430, 126, 430, 150]);
      if (V.Conn === 'vcc') {
        ledDown(P, 430, 44, V.Led1Lit, V.LedColor, V.LedOff);
        resBands(P, 430, 82, 126, V.Bands1);
      } else {
        ledDown(P, 430, 44, V.Led2Lit, V.LedColor, V.LedOff);
        resBands(P, 430, 82, 126, V.Bands2);
      }
      dot(P, 430, 30);
    }
    if (V.Conn === 'both') dot(P, 430, 150);

    P.txt(22, 34, '+Ub', C.text, 0, false);
    P.txt(22, 299, 'GND', C.text, 0, false);
    P.txt(70, 22, V.UBText, C.dim, 0, false);
    P.txt(156, 74, V.R1Text, C.accent, 2, true);
    P.txt(V.Diode ? 122 : 156, 158, V.R2Text, C.accent, 2, true);
    P.txt(150, 244, V.CText, C.accent, 2, true);
    P.txt(422, 258, '10 nF', C.dim, 0, false);
    P.txt(316, 196, 'NE555', C.text, 1, true, 16);
    P.txt(254, 124, '7 DIS', C.dim, 0, false, 10);
    P.txt(254, 174, '6 THR', C.dim, 0, false, 10);
    P.txt(254, 204, '2 TRI', C.dim, 0, false, 10);
    P.txt(366, 154, 'OUT 3', C.dim, 2, false, 10);
    P.txt(366, 224, 'CV 5', C.dim, 2, false, 10);
    P.txt(270, 104, '8', C.dim, 0, false, 10);
    P.txt(331, 104, '4', C.dim, 0, false, 10);
    P.txt(304, 244, '1', C.dim, 0, false, 10);
    if (V.Conn === 'vcc' || V.Conn === 'both') P.txt(376, 168, V.UOutText, C.dim, 0, false);
    else P.txt(376, 142, V.UOutText, C.dim, 0, false);
    if (V.Conn === 'gnd' || V.Conn === 'both') {
      P.txt(486, 186, V.RV1Text, C.accent, 0, true);
      P.txt(490, 270, V.Led1Text, C.text, 0, false);
    }
    if (V.Conn === 'vcc') {
      P.txt(446, 108, V.RV1Text, C.accent, 0, true);
      P.txt(470, 62, V.Led1Text, C.text, 0, false);
    } else if (V.Conn === 'both') {
      P.txt(446, 108, V.RV2Text, C.accent, 0, true);
      P.txt(470, 62, V.Led2Text, C.text, 0, false);
    }
    return P.svg(580, 320);
  }

  /* ==========================================================================
     MULTIVIBRATOR (DrawSchematicMulti), Vorlage 600 × 300
     ========================================================================== */
  function multi(V) {
    var P = new Pen(), C = COL;
    wire(P, [60, 25, 560, 25]);
    wire(P, [60, 285, 560, 285]);
    // Kollektorzweige: +Ub -> R_V -> LED -> Kollektor
    wire(P, [120, 25, 120, 40]); wire(P, [120, 78, 120, 94]); wire(P, [120, 118, 120, 208]); wire(P, [120, 252, 120, 285]);
    wire(P, [480, 25, 480, 40]); wire(P, [480, 78, 480, 94]); wire(P, [480, 118, 480, 208]); wire(P, [480, 252, 480, 285]);
    // Basiswiderstände: R_B1 (x 240) zur Basis T1, R_B2 (x 360) zur Basis T2
    wire(P, [240, 25, 240, 45]);
    if (V.BaseDiodes) { wire(P, [240, 95, 240, 230, 205, 230]); wire(P, [175, 230, 146, 230]); }
    else wire(P, [240, 95, 240, 230, 146, 230]);
    wire(P, [360, 25, 360, 45]);
    if (V.BaseDiodes) { wire(P, [360, 95, 360, 230, 395, 230]); wire(P, [425, 230, 454, 230]); }
    else wire(P, [360, 95, 360, 230, 454, 230]);
    // Kreuzkopplung: C1 vom Kollektor T1 zur Basis T2, C2 vom Kollektor T2 zur Basis T1
    wire(P, [120, 150, 180, 150]);
    wireHop(P, 188, 150, 360, 240);
    wire(P, [480, 180, 420, 180]);
    wireHop(P, 412, 180, 240, 360);
    capH(P, 180, 150, V.Elko, false);   // + am Kollektor (links)
    capH(P, 412, 180, V.Elko, true);    // + am Kollektor (rechts)
    resBands(P, 120, 40, 78, V.Bands1);
    resBands(P, 480, 40, 78, V.Bands2);
    ledDown(P, 120, 94, V.Led1Lit, V.LedColor, V.LedOff);
    ledDown(P, 480, 94, V.Led2Lit, V.LedColor, V.LedOff);
    resV(P, 240, 45, 95);
    resV(P, 360, 45, 95);
    if (V.BaseDiodes) {
      // 1N4148 vor jeder Basis (grau = empfohlen): Anode zum R_B, Kathode zur Basis
      diodeH(P, 205, 175, 230, C.dim);
      diodeH(P, 395, 425, 230, C.dim);
    }
    npn(P, 132, 230, 120, false);
    npn(P, 468, 230, 480, true);
    dot(P, 120, 150); dot(P, 360, 150); dot(P, 480, 180); dot(P, 240, 180); dot(P, 240, 25); dot(P, 360, 25);

    P.txt(22, 29, '+Ub', C.text, 0, false);
    P.txt(22, 289, 'GND', C.text, 0, false);
    P.txt(70, 17, V.UBText, C.dim, 0, false);
    P.txt(104, 64, V.RV1Text, C.accent, 2, true);
    P.txt(496, 64, V.RV2Text, C.accent, 0, true);
    P.txt(98, 112, V.Led1Text, C.text, 2, false);
    P.txt(520, 112, V.Led2Text, C.text, 0, false);
    P.txt(226, 74, V.R1Text, C.accent, 2, true);
    P.txt(376, 74, V.R2Text, C.accent, 0, true);
    txtCap(P, 184, 171, V.CText);
    txtCap(P, 402, 203, V.C2Text);
    P.txt(98, 268, V.T1Text, C.text, 2, false);
    P.txt(502, 268, V.T2Text, C.text, 0, false);
    if (V.BaseDiodes) {
      P.txt(190, 252, '1N4148', C.dim, 1, false);
      P.txt(410, 252, '1N4148', C.dim, 1, false);
    }
    return P.svg(600, 300);
  }

  /* LEDs der Konstantstrom-Pläne: 1 bis 3 einzeln, ab 4: LED, Punkte, LED */
  function ksqLeds(P, x, top, V) {
    var N = Math.max(1, V.LedCount || 0), r;
    ledDown(P, x, top, true, V.LedColor, V.LedOff);
    r = top + 24;
    if (N >= 4) {
      wire(P, [x, r, x, r + 8]);
      P.circle(x, r + 12, 2, COL.line); P.circle(x, r + 20, 2, COL.line); P.circle(x, r + 28, 2, COL.line);
      wire(P, [x, r + 32, x, r + 40]);
      r += 40;
    } else if (N === 3) {
      wire(P, [x, r, x, r + 8]);
      ledDown(P, x, r + 8, true, V.LedColor, V.LedOff);
      wire(P, [x, r + 32, x, r + 40]);
      r += 40;
    } else if (N === 2) {
      wire(P, [x, r, x, r + 8]);
      r += 8;
    }
    if (N >= 2) { ledDown(P, x, r, true, V.LedColor, V.LedOff); r += 24; }
    return r;
  }

  /* ==========================================================================
     LM317 ALS STROMQUELLE (DrawSchematicLM317), Vorlage 580 × 300
     ========================================================================== */
  function lm317(V) {
    var P = new Pen(), C = COL, top, bot;
    wire(P, [60, 60, 190, 60]);                 // +Ub an IN
    wire(P, [60, 280, 520, 280]);
    wire(P, [310, 60, 420, 60, 420, 72]);       // OUT -> R
    wire(P, [420, 120, 420, 150]);
    wire(P, [250, 100, 250, 150, 420, 150]);    // ADJ an den Knoten unter R
    resBands(P, 420, 72, 120, V.Bands);
    top = (V.LedCount >= 3) ? 156 : (V.LedCount === 2 ? 168 : 186);
    wire(P, [420, 150, 420, top]);
    bot = ksqLeds(P, 420, top, V);
    wire(P, [420, bot, 420, 280]);
    dot(P, 420, 150);
    P.rect(190, 30, 310, 100, C.body, C.line, 1.6);

    P.txt(22, 64, '+Ub', C.text, 0, false);
    P.txt(22, 284, 'GND', C.text, 0, false);
    P.txt(66, 48, V.UBText, C.dim, 0, false);
    P.txt(404, 138, V.RefText, C.dim, 2, false);
    P.txt(436, 96, V.RText, C.accent, 0, true);
    P.txt(436, 116, V.RSubText, C.dim, 0, false);
    if (V.LedCount >= 2) { P.txt(462, 196, V.LedText, C.text, 0, false); P.txt(462, 216, V.UFText, C.dim, 0, false); }
    else { P.txt(462, 198, V.LedText, C.text, 0, false); P.txt(462, 218, V.UFText, C.dim, 0, false); }
    P.txt(250, 74, V.ChipText, C.text, 1, true, 16);
    P.txt(196, 52, 'IN', C.dim, 0, false, 10);
    P.txt(304, 52, 'OUT', C.dim, 2, false, 10);
    P.txt(250, 95, 'ADJ', C.dim, 1, false, 10);
    return P.svg(580, 300);
  }

  /* ==========================================================================
     KONSTANTSTROM MIT 2 TRANSISTOREN (DrawSchematicKsqT), Vorlage 600 × 300
     ========================================================================== */
  function ksqT(V) {
    var P = new Pen(), C = COL, top, bot;
    wire(P, [60, 30, 540, 30]);
    wire(P, [60, 280, 540, 280]);
    wire(P, [200, 30, 200, 48]);                       // +Ub -> R_B
    wire(P, [200, 96, 200, 150, 394, 150]);            // R_B -> Basis T1
    wire(P, [270, 150, 270, 208]);                     // Kollektor T2 an der Basis von T1
    wire(P, [270, 252, 270, 280]);                     // Emitter T2 an Masse
    top = (V.LedCount >= 3) ? 36 : (V.LedCount === 2 ? 44 : 62);
    wire(P, [420, 30, 420, top]);                      // +Ub -> LEDs (Anode oben)
    bot = ksqLeds(P, 420, top, V);
    wire(P, [420, bot, 420, 128]);                     // -> Kollektor T1
    wire(P, [420, 172, 420, 196]);                     // Emitter T1 -> R_S
    wire(P, [420, 244, 420, 280]);                     // R_S -> Masse
    wire(P, [296, 230, 350, 230, 350, 186, 420, 186]); // Basis T2 misst die Spannung an R_S
    resBands(P, 200, 48, 96, V.BandsB);
    resBands(P, 420, 196, 244, V.Bands);
    npn(P, 408, 150, 420, true);
    npn(P, 282, 230, 270, false);
    dot(P, 200, 30); dot(P, 420, 30); dot(P, 270, 150); dot(P, 420, 186);

    P.txt(22, 34, '+Ub', C.text, 0, false);
    P.txt(22, 284, 'GND', C.text, 0, false);
    P.txt(66, 22, V.UBText, C.dim, 0, false);
    P.txt(186, 76, V.RBText, C.accent, 2, true);
    if (V.LedCount >= 2) { P.txt(462, 66, V.LedText, C.text, 0, false); P.txt(462, 86, V.UFText, C.dim, 0, false); }
    else { P.txt(462, 76, V.LedText, C.text, 0, false); P.txt(462, 96, V.UFText, C.dim, 0, false); }
    P.txt(446, 155, V.T1Text, C.text, 0, false);
    P.txt(250, 235, V.T2Text, C.text, 2, false);
    P.txt(440, 218, V.RText, C.accent, 0, true);
    P.txt(440, 238, V.RSubText, C.dim, 0, false);
    return P.svg(600, 300);
  }

  /* ==========================================================================
     WECHSELSTROM (uAcSchematic), Vorlage 580 × 300
     ========================================================================== */
  /* Wechselspannungsquelle (Trafo): Kreis r = 22 mit Sinuswelle, Anschlüsse oben und unten */
  function acSource(P, x, y) {
    var pts = [], STEPS = 24;
    P.circle(x, y, 22, COL.body, COL.line, 1.6);
    for (var i = 0; i <= STEPS; i++) pts.push(x - 13 + 26 * i / STEPS, y - 7 * Math.sin(2 * Math.PI * i / STEPS));
    P.poly(pts, COL.line, 1.6);
  }
  /* Diode von Anode (xa, ya) zur Kathode (xk, yk), beliebige Richtung: Dreieck
     (18 breit, 16 lang) in der Mitte zeigt zur Kathode, dort der Querstrich */
  function diodeSeg(P, xa, ya, xk, yk, color) {
    var l = Math.sqrt((xk - xa) * (xk - xa) + (yk - ya) * (yk - ya));
    if (l <= 0) return;
    var dx = (xk - xa) / l, dy = (yk - ya) / l, nx = -dy, ny = dx;
    var bx = (xa + xk) / 2 - 8 * dx, by = (ya + yk) / 2 - 8 * dy;
    var tx = (xa + xk) / 2 + 8 * dx, ty = (ya + yk) / 2 + 8 * dy;
    P.line(xa, ya, bx, by, color, 1.6);
    P.line(tx, ty, xk, yk, color, 1.6);
    P.polygon([bx + 9 * nx, by + 9 * ny, bx - 9 * nx, by - 9 * ny, tx, ty], color);
    P.line(tx + 9 * nx, ty + 9 * ny, tx - 9 * nx, ty - 9 * ny, color, 2.2);
  }
  function acLedTop(N) { return N >= 3 ? 156 : (N === 2 ? 168 : 186); }
  function acLabels(P, V) {
    P.txt(436, 96, V.RText, COL.accent, 0, true);
    P.txt(436, 116, V.RSubText, COL.dim, 0, false);
    if (V.LedCount >= 2) { P.txt(462, 196, V.LedText, COL.text, 0, false); P.txt(462, 216, V.UFText, COL.dim, 0, false); }
    else { P.txt(462, 198, V.LedText, COL.text, 0, false); P.txt(462, 218, V.UFText, COL.dim, 0, false); }
  }
  /* Einfach: Trafo, R, LEDs, Schutzdiode antiparallel (Kathode oben) */
  function acSimple(V) {
    var P = new Pen(), C = COL, top, bot;
    wire(P, [60, 148, 60, 60, 420, 60, 420, 72]);       // Trafo oben -> R
    wire(P, [60, 192, 60, 280, 420, 280]);              // Trafo unten -> zurück
    acSource(P, 60, 170);
    resBands(P, 420, 72, 120, V.Bands);
    top = acLedTop(V.LedCount);
    wire(P, [420, 120, 420, top]);
    bot = ksqLeds(P, 420, top, V);
    wire(P, [420, bot, 420, 280]);
    wire(P, [420, 150, 340, 150, 340, 183]);
    wire(P, [340, 223, 340, 280]);
    diodeSeg(P, 340, 223, 340, 183, C.line);            // Anode unten, Kathode oben
    dot(P, 420, 150); dot(P, 340, 280);
    P.txt(96, 166, V.UText, C.text, 0, false);
    P.txt(96, 186, V.UPeakText, C.dim, 0, false);
    P.txt(326, 200, V.DiodeText, C.text, 2, false);
    P.txt(326, 220, V.DiodeSubText, C.dim, 2, false);
    acLabels(P, V);
    return P.svg(580, 300);
  }
  /* Ohne Flackern: Trafo, Gleichrichter-Kasten, Elko (Plus oben), R, LEDs */
  function acBridge(V) {
    var P = new Pen(), C = COL, top, bot;
    // Rahmen wie das fertige Bauteil, darin vier Dioden als Raute: oben und
    // unten die Wechselspannung, rechts Plus, links Minus (wie uAcSchematic)
    P.rect(116, 108, 224, 236, C.body, C.line, 1.6);
    wire(P, [60, 148, 60, 130, 170, 130]);
    wire(P, [60, 192, 60, 210]);
    wireHop(P, 60, 210, 170, 130);                       // kreuzt die Minus-Leitung
    acSource(P, 60, 170);
    wire(P, [210, 170, 210, 130, 290, 130, 290, 60, 420, 60, 420, 72]);  // Plus -> R
    wire(P, [130, 170, 130, 222, 290, 222, 290, 280, 420, 280]);         // Minus -> Rückleitung
    diodeSeg(P, 170, 130, 210, 170, C.line);             // oben -> Plus
    diodeSeg(P, 130, 170, 170, 130, C.line);             // Minus -> oben
    diodeSeg(P, 130, 170, 170, 210, C.line);             // Minus -> unten
    diodeSeg(P, 170, 210, 210, 170, C.line);             // unten -> Plus
    dot(P, 170, 130); dot(P, 170, 210); dot(P, 130, 170); dot(P, 210, 170);
    wire(P, [340, 60, 340, 158]);
    wire(P, [340, 166, 340, 280]);
    capV(P, 340, 158, true);
    dot(P, 340, 60); dot(P, 340, 280);
    resBands(P, 420, 72, 120, V.Bands);
    top = acLedTop(V.LedCount);
    wire(P, [420, 120, 420, top]);
    bot = ksqLeds(P, 420, top, V);
    wire(P, [420, bot, 420, 280]);
    P.txt(60, 254, V.UText, C.text, 1, false);
    P.txt(60, 274, V.UPeakText, C.dim, 1, false);
    P.txt(170, 252, V.BridgeText, C.text, 1, false);
    P.txt(170, 269, V.BridgeSubText, C.dim, 1, false);
    P.txt(318, 152, V.CapText, C.accent, 2, true);
    P.txt(318, 172, V.CapSubText, C.accent, 2, false);
    P.txt(300, 50, V.UDcText, C.dim, 0, false);
    P.txt(110, 126, '~', C.text, 2, false);
    P.txt(110, 206, '~', C.text, 2, false);
    P.txt(230, 126, '+', C.text, 0, false);
    P.txt(230, 218, '\u2212', C.text, 0, false);      // Minuszeichen
    acLabels(P, V);
    return P.svg(580, 300);
  }

  global.LPRSchem = { COL: COL, BAND: BAND, resistor: resistor, ne555: ne555, multi: multi,
    lm317: lm317, ksqT: ksqT, acSimple: acSimple, acBridge: acBridge, resistorSvg: resistorSvg };
})(typeof window !== 'undefined' ? window : globalThis);
