import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'schedule_models.dart';

const double kMinTempF = 50.0;
const double kMaxTempF = 3659.0;
const double kMinTempC = 10.0;
const double kMaxTempC = 2015.0;

double tempMin(String scale) => scale == 'C' ? kMinTempC : kMinTempF;
double tempMax(String scale) => scale == 'C' ? kMaxTempC : kMaxTempF;

class SegmentSpan {
  final double startTime;
  final double endTime;
  final double startTemp;
  final double endTemp;
  final Color color;
  const SegmentSpan({
    required this.startTime,
    required this.endTime,
    required this.startTemp,
    required this.endTemp,
    required this.color,
  });
}

List<SegmentSpan> buildFireSpans(List<FiringSegment> segments) {
  final spans = <SegmentSpan>[];
  double t = 0;
  for (final seg in segments) {
    final low  = seg.lowTemp;
    final high = seg.highTemp;
    final rate = seg.ratePerHour;
    final hold = seg.holdMinutes;

    if (low != null && high != null && rate != null && rate > 0) {
      final hours = (high - low).abs() / rate;
      spans.add(SegmentSpan(
        startTime: t, endTime: t + hours,
        startTemp: low, endTemp: high,
        color: high >= low ? Colors.deepOrange : Colors.teal,
      ));
      t += hours;
    }

    if (hold != null && hold > 0) {
      final holdTemp = high ?? (low ?? 0);
      final hours = hold / 60.0;
      spans.add(SegmentSpan(
        startTime: t, endTime: t + hours,
        startTemp: holdTemp, endTemp: holdTemp,
        color: Colors.purple.shade300,
      ));
      t += hours;
    }
  }
  return spans;
}

String fmtFireHours(double hours) {
  final h = hours.floor();
  final m = ((hours - h) * 60).round();
  return m == 0 ? '${h}h' : '${h}h ${m}m';
}

class FiringChart extends StatefulWidget {
  const FiringChart({
    super.key,
    required this.segments,
    required this.scale,
    this.height = 220,
    this.showTitle = true,
    this.showLegend = true,
  });
  final List<FiringSegment> segments;
  final String scale;
  final double height;
  final bool showTitle;
  final bool showLegend;

  @override
  State<FiringChart> createState() => _FiringChartState();
}

class _FiringChartState extends State<FiringChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final CurvedAnimation _anim;
  List<SegmentSpan> _fromSpans = [];
  List<SegmentSpan> _toSpans = [];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _toSpans = buildFireSpans(widget.segments);
    _ctrl.value = 1.0;
  }

  @override
  void didUpdateWidget(FiringChart old) {
    super.didUpdateWidget(old);
    final newSpans = buildFireSpans(widget.segments);
    if (!_spansEqual(newSpans, _toSpans)) {
      _fromSpans = _lerp(_fromSpans, _toSpans, _anim.value);
      _toSpans = newSpans;
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  bool _spansEqual(List<SegmentSpan> a, List<SegmentSpan> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].startTime != b[i].startTime ||
          a[i].endTime   != b[i].endTime   ||
          a[i].startTemp != b[i].startTemp ||
          a[i].endTemp   != b[i].endTemp   ||
          a[i].color     != b[i].color) return false;
    }
    return true;
  }

  // Lerps matching spans by index. Mismatched counts snap immediately
  // to avoid axis label chaos when segments are added/removed.
  List<SegmentSpan> _lerp(List<SegmentSpan> from, List<SegmentSpan> to, double t) {
    if (t >= 1.0 || from.length != to.length || from.isEmpty) return to;
    return [
      for (var i = 0; i < from.length; i++)
        SegmentSpan(
          startTime: _li(from[i].startTime, to[i].startTime, t),
          endTime:   _li(from[i].endTime,   to[i].endTime,   t),
          startTemp: _li(from[i].startTemp, to[i].startTemp, t),
          endTemp:   _li(from[i].endTemp,   to[i].endTemp,   t),
          color:     Color.lerp(from[i].color, to[i].color, t)!,
        ),
    ];
  }

  static double _li(double a, double b, double t) => a + (b - a) * t;

  @override
  Widget build(BuildContext context) {
    final totalHours = _toSpans.isNotEmpty ? _toSpans.last.endTime : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.showTitle) ...[
          Row(children: [
            Text('Temperature Profile',
                style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            Text('Total: ${fmtFireHours(totalHours)}',
                style: Theme.of(context).textTheme.bodySmall),
          ]),
          const SizedBox(height: 8),
        ],
        AnimatedBuilder(
          animation: _anim,
          builder: (ctx, _) {
            final spans = _lerp(_fromSpans, _toSpans, _anim.value);
            if (spans.isEmpty) return SizedBox(height: widget.height);
            return SizedBox(
              height: widget.height,
              child: CustomPaint(
                painter: FiringChartPainter(
                  spans: spans,
                  scale: widget.scale,
                  scheme: Theme.of(ctx).colorScheme,
                ),
                size: Size.infinite,
              ),
            );
          },
        ),
        if (widget.showLegend) ...[
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendDot(color: Colors.deepOrange, label: 'Ramp up'),
              const SizedBox(width: 16),
              _LegendDot(color: Colors.teal, label: 'Ramp down'),
              const SizedBox(width: 16),
              _LegendDot(color: Colors.purple, label: 'Hold'),
            ],
          ),
        ],
      ],
    );
  }
}

class FiringChartPainter extends CustomPainter {
  const FiringChartPainter({
    required this.spans,
    required this.scale,
    required this.scheme,
  });
  final List<SegmentSpan> spans;
  final String scale;
  final ColorScheme scheme;

  static const _lPad = 54.0;
  static const _rPad = 12.0;
  static const _tPad = 12.0;
  static const _bPad = 32.0;
  static const _cornerR = 8.0;

  @override
  void paint(Canvas canvas, Size size) {
    final cW = size.width  - _lPad - _rPad;
    final cH = size.height - _tPad - _bPad;

    final temps = spans.expand((s) => [s.startTemp, s.endTemp]).toList();
    final rawMin = temps.reduce(math.min);
    final rawMax = temps.reduce(math.max);
    final maxTime = spans.last.endTime;
    if (maxTime <= 0) return;

    final range = rawMax - rawMin;
    final yMin = range > 0
        ? math.max(0.0, (rawMin / 100).floor() * 100.0 - 100)
        : math.max(0.0, rawMin - 100);
    final yMax = range > 0
        ? (rawMax / 100).ceil() * 100.0 + 100
        : rawMax + 100;
    if (yMax <= yMin) return;

    Offset toPx(double time, double temp) => Offset(
      _lPad + (time / maxTime) * cW,
      _tPad + cH - ((temp - yMin) / (yMax - yMin)) * cH,
    );

    // Grid
    final gridPaint = Paint()
      ..color = scheme.outlineVariant.withAlpha(70)
      ..strokeWidth = 0.5;
    final tempStep = _niceStep(yMax - yMin, 5);
    final firstTick = ((yMin / tempStep).ceil() * tempStep).toDouble();
    for (double temp = firstTick; temp <= yMax; temp += tempStep) {
      final y = toPx(0, temp).dy;
      canvas.drawLine(Offset(_lPad, y), Offset(_lPad + cW, y), gridPaint);
      _drawText(canvas, '${temp.toStringAsFixed(0)}°',
          Offset(_lPad - 4, y), scheme.onSurfaceVariant, align: TextAlign.right);
    }
    final timeStep = _niceStep(maxTime, 6);
    for (double t = 0; t <= maxTime + 0.001; t += timeStep) {
      final x = toPx(t, 0).dx;
      canvas.drawLine(Offset(x, _tPad), Offset(x, _tPad + cH), gridPaint);
      _drawText(canvas, '${t.toStringAsFixed(t == t.floor() ? 0 : 1)}h',
          Offset(x, _tPad + cH + 4), scheme.onSurfaceVariant,
          align: TextAlign.center);
    }

    // Axes
    final axisPaint = Paint()
      ..color = scheme.outline.withAlpha(140)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(_lPad, _tPad), Offset(_lPad, _tPad + cH), axisPaint);
    canvas.drawLine(
        Offset(_lPad, _tPad + cH), Offset(_lPad + cW, _tPad + cH), axisPaint);

    _paintLines(canvas, toPx);

    // Dots at transitions
    final dotKeys = <String>{};
    final dotPoints = <Offset>[];
    for (final s in spans) {
      for (final (t, temp) in [
        (s.startTime, s.startTemp),
        (s.endTime, s.endTemp)
      ]) {
        final key = '${t.toStringAsFixed(4)}_${temp.toStringAsFixed(4)}';
        if (dotKeys.add(key)) dotPoints.add(toPx(t, temp));
      }
    }
    final dotFill   = Paint()..color = scheme.surface;
    final dotBorder = Paint()
      ..color = scheme.onSurfaceVariant.withAlpha(180)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (final pt in dotPoints) {
      canvas.drawCircle(pt, 3.5, dotFill);
      canvas.drawCircle(pt, 3.5, dotBorder);
    }
  }

  void _paintLines(Canvas canvas, Offset Function(double, double) toPx) {
    Offset lerpOff(Offset a, Offset b, double t) =>
        Offset(a.dx + (b.dx - a.dx) * t, a.dy + (b.dy - a.dy) * t);

    double dist(Offset a, Offset b) {
      final dx = b.dx - a.dx;
      final dy = b.dy - a.dy;
      return math.sqrt(dx * dx + dy * dy);
    }

    final pts = spans
        .map((s) => (
              start: toPx(s.startTime, s.startTemp),
              end: toPx(s.endTime, s.endTemp),
            ))
        .toList();

    for (int i = 0; i < spans.length; i++) {
      final p   = pts[i];
      final len = dist(p.start, p.end);
      if (len == 0) continue;

      final r         = math.min(_cornerR, len * 0.35);
      final drawStart = lerpOff(p.start, p.end, i > 0               ? r / len : 0.0);
      final drawEnd   = lerpOff(p.start, p.end, i < spans.length - 1 ? 1 - r / len : 1.0);

      canvas.drawLine(
        drawStart, drawEnd,
        Paint()
          ..color = spans[i].color
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke,
      );

      // Quadratic bezier into next span for smooth junction
      if (i < spans.length - 1) {
        final np   = pts[i + 1];
        final nLen = dist(np.start, np.end);
        if (nLen > 0) {
          final nR         = math.min(_cornerR, nLen * 0.35);
          final nDrawStart = lerpOff(np.start, np.end, nR / nLen);
          canvas.drawPath(
            Path()
              ..moveTo(drawEnd.dx, drawEnd.dy)
              ..quadraticBezierTo(
                  p.end.dx, p.end.dy, nDrawStart.dx, nDrawStart.dy),
            Paint()
              ..color = spans[i + 1].color
              ..strokeWidth = 2.5
              ..strokeCap = StrokeCap.round
              ..style = PaintingStyle.stroke,
          );
        }
      }
    }
  }

  void _drawText(Canvas canvas, String text, Offset anchor, Color color,
      {TextAlign align = TextAlign.left}) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(fontSize: 9, color: color)),
      textDirection: TextDirection.ltr,
      textAlign: align,
    )..layout(maxWidth: 48);
    final dx = switch (align) {
      TextAlign.right  => anchor.dx - tp.width,
      TextAlign.center => anchor.dx - tp.width / 2,
      _                => anchor.dx,
    };
    tp.paint(canvas, Offset(dx, anchor.dy - tp.height / 2));
  }

  double _niceStep(double range, int target) {
    if (range <= 0) return 1;
    final rough = range / target;
    for (final s in [
      0.25, 0.5, 1, 2, 5, 10, 25, 50, 100, 150, 200, 250, 500, 1000
    ]) {
      if (s >= rough) return s.toDouble();
    }
    return 1000.0;
  }

  @override
  bool shouldRepaint(FiringChartPainter old) =>
      old.spans != spans || old.scheme != scheme;
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 20, height: 3, color: color),
          const SizedBox(width: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      );
}
