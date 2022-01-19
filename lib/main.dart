// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:math' as math;

const EdgeInsets DEFAULT_PADDING = EdgeInsets.all(8);
const double DEFAULT_SIZE = 8.0;
const BORDER_COLOR = Color(0xFF000000);

void main() {
  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => PaintDataCubit()),
        BlocProvider(create: (context) => ToolboxCubit()),
      ],
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pesla Designer',
      home: Home(),
    );
  }
}

class Home extends StatelessWidget {
  const Home({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var toolbox = context.read<ToolboxCubit>();
    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: BORDER_COLOR,
                ),
              ),
            ),
            child: Row(
              children: [
                const Text(
                  'Persla Designer',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Expanded(
                  child: SizedBox.shrink(),
                ),
                IconButton(
                  onPressed: () {
                    context.read<PaintDataCubit>().resetPoints();
                  },
                  icon: const Icon(Icons.clear),
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: DEFAULT_PADDING,
                  decoration: const BoxDecoration(
                    border: Border(
                      right: BorderSide(
                        color: BORDER_COLOR,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text('Toolbox'),
                      const Divider(),
                      IconButton(
                        onPressed: () {
                          toolbox.changeTool(Toolbox.line);
                        },
                        icon: const Icon(Icons.edit),
                      ),
                      Helpers.verticalSpace(),
                      IconButton(
                        onPressed: () {
                          toolbox.changeTool(Toolbox.circle);
                        },
                        icon: const Icon(Icons.circle_outlined),
                      ),
                      Helpers.verticalSpace(),
                      IconButton(
                        onPressed: () {
                          toolbox.changeTool(Toolbox.curve);
                        },
                        icon: const Icon(Icons.bedtime_outlined),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    padding: DEFAULT_PADDING,
                    child: const DrawerCanvas(),
                  ),
                ),
                Container(
                  width: MediaQuery.of(context).size.width * 0.2,
                  padding: DEFAULT_PADDING,
                  decoration: const BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: BORDER_COLOR,
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DrawerCanvas extends StatelessWidget {
  const DrawerCanvas({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CustomPaint(
          painter: GraphPainter(cellSize: 24),
          child: Container(),
        ),
        BlocBuilder<PaintDataCubit, List<PaintData>>(
          builder: (context, state) {
            return CustomPaint(
              painter: MyCustomPainter(data: state),
              child: Container(),
            );
          },
        ),
        BlocBuilder<ToolboxCubit, Toolbox>(builder: (context, state) {
          switch (state) {
            case Toolbox.circle:
              return const CircleDrawerCanvas();
            case Toolbox.line:
              return const LineDrawerCanvas();

            case Toolbox.curve:
              return const CurveDrawerCanvas();
            default:
              return const SizedBox.shrink();
          }
        }),
      ],
    );
  }
}

class LineDrawerCanvas extends StatefulWidget {
  const LineDrawerCanvas({Key? key}) : super(key: key);

  @override
  _LineDrawerCanvasState createState() => _LineDrawerCanvasState();
}

class _LineDrawerCanvasState extends State<LineDrawerCanvas> {
  DynamicOffset _start = const DynamicOffset(0, 0);
  bool _updateEnd = false;

  final GlobalKey _key = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: _key,
      onPanDown: (details) {
        setState(() {
          _start = Helpers.fromOffset(_key, details.localPosition);
        });
      },
      onPanUpdate: _paintOnUpdate,
      onPanEnd: (details) {
        setState(() {
          _updateEnd = false;
        });
      },
      child: Container(
        color: Colors.transparent,
      ),
    );
  }

  _paintOnUpdate(details) {
    var paintDataCubit = context.read<PaintDataCubit>();

    if (_updateEnd) {
      paintDataCubit.updateLast(
        LinePainter(
          start: _start,
          end: Helpers.fromOffset(_key, details.localPosition),
        ),
      );
    } else {
      paintDataCubit.addData(
        LinePainter(
          start: _start,
          end: Helpers.fromOffset(_key, details.localPosition),
        ),
      );
      setState(() {
        _updateEnd = true;
      });
    }
  }
}

class CircleDrawerCanvas extends StatefulWidget {
  const CircleDrawerCanvas({Key? key}) : super(key: key);

  @override
  _CircleDrawerCanvasState createState() => _CircleDrawerCanvasState();
}

class _CircleDrawerCanvasState extends State<CircleDrawerCanvas> {
  final GlobalKey _key = GlobalKey();
  var _start = const Offset(0, 0);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: _key,
      onPanDown: (details) {
        var paintDataCubit = context.read<PaintDataCubit>();
        setState(() {
          _start = details.localPosition;
        });
        paintDataCubit.addData(
          CirclePainter(
            center: Helpers.fromOffset(_key, _start),
            radius: 0,
          ),
        );
      },
      onPanUpdate: _paintOnUpdate,
      child: Container(
        color: Colors.transparent,
      ),
    );
  }

  _paintOnUpdate(DragUpdateDetails details) {
    var paintDataCubit = context.read<PaintDataCubit>();

    paintDataCubit.updateLast(
      CirclePainter(
        radius: Helpers.distanceBetweenOffsets(details.localPosition, _start),
        center: Helpers.fromOffset(_key, _start),
      ),
    );
  }
}

class CurveDrawerCanvas extends StatefulWidget {
  const CurveDrawerCanvas({Key? key}) : super(key: key);

  @override
  _CurveDrawerCanvasState createState() => _CurveDrawerCanvasState();
}

class _CurveDrawerCanvasState extends State<CurveDrawerCanvas> {
  final GlobalKey _key = GlobalKey();
  var _start = const Offset(0, 0);
  var _end = const Offset(0, 0);
  bool _isDrawingLine = true;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: _key,
      onPanDown: (details) {
        if (_isDrawingLine) {
          var paintDataCubit = context.read<PaintDataCubit>();
          setState(() {
            _start = details.localPosition;
          });
          paintDataCubit.addData(
            CurvePainter(
              start: Helpers.fromOffset(_key, _start),
              controlPoint: Helpers.fromOffset(_key, _start),
              end: Helpers.fromOffset(_key, _start),
            ),
          );
        }
      },
      onPanUpdate: _paintOnUpdate,
      onPanEnd: (details) {
        setState(() {
          _isDrawingLine = !_isDrawingLine;
        });
      },
      child: Container(
        color: Colors.transparent,
      ),
    );
  }

  _paintOnUpdate(DragUpdateDetails details) {
    var paintDataCubit = context.read<PaintDataCubit>();

    // print('Gesture: ${details.localPosition}');

    if (_isDrawingLine) {
      setState(() {
        _end = details.localPosition;
      });
      paintDataCubit.updateLast(
        CurvePainter(
          start: Helpers.fromOffset(_key, _start),
          controlPoint: Helpers.fromOffset(_key, _start),
          end: Helpers.fromOffset(_key, _end),
        ),
      );
    } else {
      paintDataCubit.updateLast(
        CurvePainter(
          start: Helpers.fromOffset(_key, _start),
          controlPoint: Helpers.fromOffset(_key, details.localPosition),
          end: Helpers.fromOffset(_key, _end),
        ),
      );
    }
  }
}

class MyCustomPainter extends CustomPainter {
  MyCustomPainter({required this.data});

  final List<PaintData> data;

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke;

    for (var paintData in data) {
      if (paintData is LinePainter) {
        canvas.drawLine(
          Helpers.fromDynamicOffset(paintData.start, size),
          Helpers.fromDynamicOffset(paintData.end, size),
          paint,
        );
      }

      if (paintData is CirclePainter) {
        canvas.drawCircle(
          Helpers.fromDynamicOffset(paintData.center, size),
          paintData.radius,
          paint,
        );
      }

      if (paintData is CurvePainter) {
        Path path = Path();
        var startOffset = Helpers.fromDynamicOffset(paintData.start, size);
        var endOffset = Helpers.fromDynamicOffset(paintData.end, size);
        var controlOffset = Helpers.fromDynamicOffset(paintData.controlPoint, size);

        var cx = controlOffset.dx;
        var cy = controlOffset.dy;

        var ex = endOffset.dx;
        var ey = endOffset.dy;

        path.moveTo(startOffset.dx, startOffset.dy);

        if (startOffset == controlOffset) {
          path.lineTo(ex, ey);
        } else {
          path.quadraticBezierTo(cx, cy, ex, ey);
        }

        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class GraphPainter extends CustomPainter {
  final double? cellSize;
  GraphPainter({this.cellSize});

  @override
  void paint(Canvas canvas, Size size) {
    var width = size.width;
    var height = size.height;

    double x = 0;
    double y = 0;

    Paint paint = Paint()
      ..color = Colors.grey
      ..style = PaintingStyle.fill;

    while (x < width) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, height),
        paint,
      );
      x += cellSize ?? 8;
    }

    while (y < height) {
      canvas.drawLine(
        Offset(0, y),
        Offset(width, y),
        paint,
      );
      y += cellSize ?? 8;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Interface for paint data that is required by MyCustomPainter
abstract class PaintData {}

// Paint Data for a line
class LinePainter extends PaintData {
  LinePainter({
    required this.start,
    required this.end,
  });

  final DynamicOffset start;
  final DynamicOffset end;
}

// Paint Data for a circle
class CirclePainter extends PaintData {
  CirclePainter({
    required this.center,
    required this.radius,
  });
  final DynamicOffset center;
  final double radius;
}

class CurvePainter extends PaintData {
  CurvePainter({
    required this.controlPoint,
    required this.end,
    required this.start,
  });

  final DynamicOffset start;
  final DynamicOffset end;
  final DynamicOffset controlPoint;
}

// Object that provides offset as percentages
class DynamicOffset {
  const DynamicOffset(this.x, this.y);

  final double x;
  final double y;

  @override
  String toString() {
    return 'DynamicOffset($x, $y)';
  }
}

// Managing paint data state
class PaintDataCubit extends Cubit<List<PaintData>> {
  PaintDataCubit() : super([]);

  addData(PaintData paintData) {
    List<PaintData> list = [];
    list.addAll(state);
    list.add(paintData);
    emit(list);
  }

  updateLast(PaintData paintData) {
    List<PaintData> list = [];
    list.addAll(state);
    list[list.length - 1] = paintData;
    emit(list);
  }

  resetPoints() {
    emit([]);
  }
}

class ToolboxCubit extends Cubit<Toolbox> {
  ToolboxCubit() : super(Toolbox.line);

  void changeTool(Toolbox tool) {
    emit(tool);
  }
}

enum Toolbox { line, circle, curve }

// All helper methods are in this class
class Helpers {
  // Method to add a vertical space
  static SizedBox verticalSpace({double size = DEFAULT_SIZE}) {
    return SizedBox(height: size);
  }

  // Method to add horizontal space
  static SizedBox horizontalSpace({double size = DEFAULT_SIZE}) {
    return SizedBox(width: size);
  }

  // Method for getting a dynamic offset from offset
  static DynamicOffset fromOffset(GlobalKey key, Offset offset) {
    if (key.currentContext != null) {
      var size = key.currentContext!.size!;
      var x = offset.dx / size.width;
      var y = offset.dy / size.height;
      return DynamicOffset(x, y);
    }
    return const DynamicOffset(0, 0);
  }

  // Method for getting offset from dynamic offset
  static Offset fromDynamicOffset(DynamicOffset dynamicOffset, Size size) {
    var dx = dynamicOffset.x * size.width;
    var dy = dynamicOffset.y * size.height;
    return Offset(dx, dy);
  }

  // Get distance between offsets
  static double distanceBetweenOffsets(Offset p1, Offset p2) {
    var x1 = p2.dx - p1.dx;
    var y1 = p2.dy - p1.dy;
    var sum = math.pow(x1, 2) + math.pow(y1, 2);
    return math.sqrt(sum);
  }
}
