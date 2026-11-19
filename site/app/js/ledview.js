/* ==============================================================================
   ledview.js - LED-Vorschau (Übertragung von uLedView.pas)
   ==============================================================================
   Zweck:     Rechnet das Bild einer 5-mm-LED Punkt für Punkt, genau wie die
              Windows-Version: Leuchtschein, Beine (Anode lang, Kathode mit
              Knick), Kuppel mit Farbverlauf, Träger und Chip, Lichtreflex,
              Kragen mit der flachen Seite. Jedes Pixel wird 3 × 3-mal
              abgetastet (Kantenglättung). Beschriftung Anode/Kathode darüber.
   Vorlage:   200 × 250 Punkte, mittig eingepasst.
   Autor:     Elospeed
   Versionen: 2.5.2-html 18.11.2026  erste Fassung
   ============================================================================== */
(function (global) {
  'use strict';
  var BASE_W = 200, BASE_H = 250, SS = 3;

  function hex(c) {
    return { r: parseInt(c.substr(1, 2), 16) / 255, g: parseInt(c.substr(3, 2), 16) / 255, b: parseInt(c.substr(5, 2), 16) / 255 };
  }
  function blend(p, c, a) {
    if (a <= 0) return;
    if (a > 1) a = 1;
    p.r += (c.r - p.r) * a; p.g += (c.g - p.g) * a; p.b += (c.b - p.b) * a;
  }
  function ramp3(t, v0, m, vm, v1) {
    if (t <= 0) return v0;
    if (t >= 1) return v1;
    if (t < m) return v0 + (vm - v0) * (t / m);
    return vm + (v1 - vm) * ((t - m) / (1 - m));
  }
  function segDist(px, py, ax, ay, bx, by) {
    var dx = bx - ax, dy = by - ay;
    var t = ((px - ax) * dx + (py - ay) * dy) / (dx * dx + dy * dy);
    t = Math.max(0, Math.min(1, t));
    return Math.hypot(px - (ax + t * dx), py - (ay + t * dy));
  }
  function inDome(x, y) {
    if (x < 60 || x > 140 || y > 141) return false;
    if (y >= 72) return true;
    return (x - 100) * (x - 100) + (y - 72) * (y - 72) <= 1600;
  }
  function inPost(x, y) {
    if (y >= 96 && y <= 141) return x >= 106 && x <= 130;
    if (y >= 88 && y < 96) return x >= 108 + (y - 88) / 4 && x <= 128 - (y - 88) / 4;
    return false;
  }
  var LEG = hex('#B9C0C8'), ANVIL = hex('#9AA2AB'), POSTC = hex('#8A929B'),
      WHITE = { r: 1, g: 1, b: 1 }, GREY = hex('#555555');

  function sample(x, y, back, led, off, glow) {
    var res = { r: back.r, g: back.g, b: back.b }, d, t, a;
    // 1. Leuchtschein um die Kuppel
    d = Math.hypot(x - 100, y - 78) / 100;
    if (d < 1) blend(res, led, ramp3(d, 0.75 * glow, 0.45, 0.28 * glow, 0));
    // 2. Beine: Anode gerade und lang, Kathode kürzer mit Knick
    if (segDist(x, y, 82, 140, 82, 236) <= 2.25) res = { r: LEG.r, g: LEG.g, b: LEG.b };
    if (segDist(x, y, 118, 140, 118, 170) <= 2.25 || segDist(x, y, 118, 170, 126, 180) <= 2.25 ||
        segDist(x, y, 126, 180, 126, 206) <= 2.25) res = { r: LEG.r, g: LEG.g, b: LEG.b };
    // 3. Kuppel
    if (inDome(x, y)) {
      res = { r: off.r, g: off.g, b: off.b };
      t = (x - 60) / 80;
      blend(res, led, ramp3(t, 0.35 + 0.35 * glow, 0.55, 0.55 + 0.45 * glow, 0.3 + 0.3 * glow));
      if (x >= 79 && x <= 86 && y >= 96) res = { r: ANVIL.r, g: ANVIL.g, b: ANVIL.b };
      if (inPost(x, y)) res = { r: POSTC.r, g: POSTC.g, b: POSTC.b };
      d = Math.pow((x - 118) / 34, 2) + Math.pow((y - 87) / 30, 2);
      if (d < 1) {
        t = Math.hypot(x - 118, y - 87) / 34;
        if (t < 0.35) {
          a = t / 0.35;
          blend(res, WHITE, glow * (1 - a));
          blend(res, led, 0.9 * glow * a);
        } else blend(res, led, 0.9 * glow * (1 - (t - 0.35) / 0.65));
      }
      if (x >= 115 && x <= 121 && y >= 84 && y <= 88) res = glow > 0.2 ? { r: 1, g: 1, b: 1 } : { r: GREY.r, g: GREY.g, b: GREY.b };
      d = segDist(x, y, 68, 74, 68, 128);
      if (x < 100 && y < 74 && y > 44) d = Math.min(d, Math.abs(Math.hypot(x - 100, y - 74) - 32));
      if (d <= 2.5) blend(res, WHITE, 0.45);
      if (!inDome(x - 1.2, y) || !inDome(x + 1.2, y) || !inDome(x, y - 1.2)) blend(res, WHITE, 0.35);
    }
    // 4. Kragen mit flacher Seite (Kathode)
    if (x >= 50 && x <= 140 && y >= 141 && y <= 154) {
      res = { r: off.r, g: off.g, b: off.b };
      blend(res, led, 0.45 + 0.3 * glow);
      if (y < 142.2 || y > 152.8 || x < 51.2) blend(res, WHITE, 0.3);
    }
    return res;
  }

  /* Rechnet das Bild in ein Canvas der Grösse w × h (Gerätepixel).
     labels: {anode, anodeHint, cathode, cathodeHint1, cathodeHint2, flat}
     dpr: Gerätepixel je CSS-Pixel (für die Schriftgrössen) */
  function render(canvas, w, h, ledColor, backColor, glow, labels, labelColor, dpr) {
    if (w < 10 || h < 10) return;
    canvas.width = w; canvas.height = h;
    var ctx = canvas.getContext('2d');
    var img = ctx.createImageData(w, h), data = img.data;
    var back = hex(backColor), led = hex(ledColor), off = hex('#3A3F47');
    var scale = Math.max(BASE_W / w, BASE_H / h);
    var ox = (w - BASE_W / scale) / 2, oy = (h - BASE_H / scale) / 2;
    var inv = 1 / (SS * SS), k = 0;
    for (var py = 0; py < h; py++) {
      for (var px = 0; px < w; px++) {
        var ar = 0, ag = 0, ab = 0;
        var vx0 = (px - ox) * scale, vy0 = (py - oy) * scale;
        // ausserhalb von Schein, Kuppel, Beinen und Kragen: nur Hintergrund
        var cx = vx0 - 100, cy = vy0 - 78;
        var far = (cx * cx + cy * cy > 102 * 102) && (vx0 < 76 || vx0 > 132 || vy0 < 136 || vy0 > 240);
        if (far) {
          ar = back.r; ag = back.g; ab = back.b;
        } else {
          for (var sy = 0; sy < SS; sy++)
            for (var sx = 0; sx < SS; sx++) {
              var c = sample((px + (sx + 0.5) / SS - ox) * scale, (py + (sy + 0.5) / SS - oy) * scale, back, led, off, glow);
              ar += c.r; ag += c.g; ab += c.b;
            }
          ar *= inv; ag *= inv; ab *= inv;
        }
        data[k++] = Math.round(ar * 255); data[k++] = Math.round(ag * 255); data[k++] = Math.round(ab * 255); data[k++] = 255;
      }
    }
    ctx.putImageData(img, 0, 0);

    // Beschriftung (wie TextOut in RenderLed; negative Font.Height = Schriftgrösse in Pixeln)
    function PX2(v) { return Math.round(ox + v / scale); }
    function PY2(v) { return Math.round(oy + v / scale); }
    var font = '"Segoe UI", system-ui, -apple-system, Arial, sans-serif';
    var unit = dpr || 1;
    ctx.fillStyle = labelColor;
    ctx.textBaseline = 'alphabetic';
    var hB = Math.max(9 * unit, Math.round(13 / scale));
    ctx.font = '700 ' + hB + 'px ' + font;
    ctx.textAlign = 'right';
    ctx.fillText(labels.anode, PX2(74), PY2(200) - hB * 0.26);
    ctx.textAlign = 'left';
    ctx.fillText(labels.cathode, PX2(136), PY2(192) - hB * 0.26);
    var hS = Math.max(8 * unit, Math.round(10.5 / scale));
    ctx.font = hS + 'px ' + font;
    ctx.textAlign = 'right';
    ctx.fillText(labels.anodeHint, PX2(74), PY2(215) - hS * 0.26);
    ctx.textAlign = 'left';
    ctx.fillText(labels.cathodeHint1, PX2(136), PY2(207) - hS * 0.26);
    ctx.fillText(labels.cathodeHint2, PX2(136), PY2(220) - hS * 0.26);
    // gestrichelte Linie zur flachen Seite
    ctx.strokeStyle = labelColor;
    ctx.lineWidth = unit;
    ctx.setLineDash([unit, unit * 2]);
    ctx.beginPath();
    ctx.moveTo(PX2(146), PY2(147) + 0.5);
    ctx.lineTo(PX2(168), PY2(147) + 0.5);
    ctx.stroke();
    ctx.setLineDash([]);
    var hF = Math.max(8 * unit, Math.round(10 / scale));
    ctx.font = hF + 'px ' + font;
    ctx.textBaseline = 'middle';
    ctx.fillText(labels.flat, PX2(171), PY2(147));
  }

  global.LPRLed = { render: render };
})(typeof window !== 'undefined' ? window : globalThis);
