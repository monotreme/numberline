import 'dart:ui';

import 'package:arrow_path/arrow_path.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:fraction/fraction.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Number line Example',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: ExampleApp(),
    );
  }
}

class ExampleApp extends StatefulWidget {
  ExampleApp({Key? key}) : super(key: key);

  @override
  _ExampleAppState createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  @override
  void initState() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        constraints: BoxConstraints.expand(),
        child: CustomPaint(
          painter: ArrowPainter(numberLine: example),
        ),
      ),
    );
  }
}

class Arrow {
  final double start;
  final double end;
  final double height;
  final Color color;
  final String label;

  Arrow(
      {required this.start,
      required this.end,
      this.height = 50,
      this.color = Colors.blue,
      this.label = ''});
}

enum TickLabelStyle {
  natural,
  fraction,
}

class NumberLine {
  final double low;
  final double high;
  final List<Arrow> arrows;
  late double tickInterval;
  late TickLabelStyle tickLabelStyle;

  NumberLine({
    required this.low,
    required this.high,
    required this.arrows,
    double? tickInterval,
    this.tickLabelStyle = TickLabelStyle.natural,
  }) {
    this.tickInterval = tickInterval ?? high - low;
  }
}

NumberLine example = NumberLine(
    low: 0,
    high: 5,
    tickInterval: 1 / 3,
    tickLabelStyle: TickLabelStyle.fraction,
    arrows: [
      Arrow(start: 0, end: 1, label: 'default'),
      Arrow(start: 1, end: 2, color: Colors.orange, label: 'orange'),
      Arrow(start: 2, end: 3, color: Colors.green, label: 'green'),
      Arrow(start: 3, end: 4, color: Colors.purple, label: 'purple'),
      Arrow(start: 4, end: 5, color: Colors.red, label: 'red'),
    ]);

const EPSILON = 1.0e-8;

class ArrowPainter extends CustomPainter {
  final NumberLine numberLine;

  const ArrowPainter({required this.numberLine});

  @override
  void paint(Canvas canvas, Size size) {
    var pad = 0.05;
    var xLow = pad * size.width;
    var xHigh = (1 - pad) * size.width;

    var high = numberLine.high;
    var low = numberLine.low;
    var x0 = (xLow * high - xHigh * low) / (high - low);
    var y0 = size.height * 0.25;
    var tickDepth = 10;
    print(xLow);
    print(xHigh);
    print(size.width);

    print(high);
    print(low);
    print(x0);
    print("y0=");
    print(y0);
    double x(double num) => num * (xHigh - xLow) / (high - low) + x0;
    TextSpan textSpan;
    TextPainter textPainter;
    Path path;

    void labelTick(String tickLabel, double xPos) {
      textSpan = TextSpan(
        text: tickLabel,
      );

      textPainter = TextPainter(
        text: textSpan,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout(minWidth: 50);
      textPainter.paint(canvas, Offset(xPos - textPainter.width / 2, y0 + 12));
    }

    // Draw number line

    Paint paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 3.0;
    String lowLabel = low.toString();
    String highLabel = high.toString();
    double tipAngle = .3;

    /// Draw a line
    path = Path();
    var xStart = x(low);
    print("xStart");
    print(xStart);
    path.moveTo(xStart - 20, y0);
    var xEnd = x(high);
    double offset = xEnd - xStart + 40;
    path.relativeCubicTo(offset / 3, 0, 2 * offset / 3, 0, offset, 0);
    path = ArrowPath.make(
      path: path,
      isDoubleSided: true,
      tipAngle: tipAngle,
    );
    canvas.drawPath(path, paint..color = Colors.black);
    for (double num = low;
        num <= high + EPSILON;
        num += numberLine.tickInterval) {
      double pos = x(num);
      canvas.drawLine(Offset(pos, y0), Offset(pos, y0 + tickDepth), paint);
      late String label;
      switch (numberLine.tickLabelStyle) {
        case TickLabelStyle.natural:
          label = num.toString();
          break;
        case TickLabelStyle.fraction:
          label = Fraction.fromDouble(num).toString();
          break;
        default:
          throw new FormatException();
      }
      labelTick(label, pos);
    }

    /// Draw start and end ticks

    labelTick(lowLabel, xStart);
    labelTick(highLabel, xEnd);

    void drawArrow(Arrow arrow) {
      // The arrows usually looks better with rounded caps.
      Paint paint = Paint()
        ..color = arrow.color
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = 3.0;

      /// Draw a single arrow.
      double tipAngle = .3;
      path = Path();
      var xStart = x(arrow.start);
      print("xStart");
      print(xStart);
      path.moveTo(xStart, y0);
      var xEnd = x(arrow.end);

      print('arrow end');
      print(arrow.end);
      print(xEnd);
      double offset = xEnd - xStart;
      print("offset");
      print(offset);
      path.relativeCubicTo(
          offset / 3, -arrow.height, 2 * offset / 3, -arrow.height, offset, 0);
      path = ArrowPath.make(path: path, tipAngle: tipAngle);
      canvas.drawPath(path, paint);
      if (arrow.label.isNotEmpty) {
        textSpan = TextSpan(
          text: arrow.label,
          style: TextStyle(color: arrow.color),
        );
        textPainter = TextPainter(
          text: textSpan,
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
        );
        double width = (-xStart + xEnd);
        textPainter.layout(minWidth: width);
        print(xEnd);
        textPainter.paint(canvas, Offset(xStart, y0 - 10 - arrow.height));
      }
    }

    for (var arrow in numberLine.arrows) {
      drawArrow(arrow);
    }
  }

  @override
  bool shouldRepaint(ArrowPainter oldDelegate) => false;
}
