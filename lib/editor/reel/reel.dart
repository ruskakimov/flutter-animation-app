import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mooltik/editor/drawer/bar_icon_button.dart';
import 'package:mooltik/editor/frame/frame_model.dart';
import 'package:mooltik/editor/frame/frame_painter.dart';
import 'package:provider/provider.dart';
import 'package:mooltik/editor/reel/reel_model.dart';

const thumbnailSize = Size(112, 64);
const durationModeScrollUnit = 20.0;

class Reel extends StatefulWidget {
  const Reel({Key key}) : super(key: key);

  @override
  _ReelState createState() => _ReelState();
}

class _ReelState extends State<Reel> {
  ScrollController controller;
  bool _durationMode = false;
  double _draggedInDurationMode = 0;

  ReelModel get reel => context.read<ReelModel>();

  int get selectedId => (controller.offset / thumbnailSize.height).round();

  @override
  void initState() {
    super.initState();
    controller = ScrollController(
      initialScrollOffset: reel.selectedFrameId * thumbnailSize.height,
    )..addListener(_onScroll);
  }

  void _onScroll() {
    reel.selectFrame(selectedId);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (controller.hasClients &&
        selectedId != reel.selectedFrameId &&
        !reel.playing) {
      controller.removeListener(_onScroll);
      _scrollTo(reel.selectedFrameId);
      controller.addListener(_onScroll);
    }
  }

  void _scrollTo(int index) {
    controller.animateTo(
      index * thumbnailSize.height,
      duration: Duration(milliseconds: 150),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Update when selected frame is painted on.
    context.watch<FrameModel>();

    final reel = context.watch<ReelModel>();

    var visibleFrame = reel.frames.first;
    final visibleFrames = reel.frames.map((f) {
      if (f != null) {
        visibleFrame = f;
      }
      return visibleFrame;
    }).toList();

    return Stack(
      children: [
        Positioned.fill(
          child: LayoutBuilder(builder: (context, constraints) {
            final padding = (constraints.maxHeight - thumbnailSize.height) / 2;
            final lastIndex = reel.frames.length - 1;

            final before = SizedBox(height: padding);
            final after = SizedBox(
              height: padding,
              child: Column(
                children: [
                  SizedBox(
                    height: thumbnailSize.height,
                    child: BarIconButton(
                      icon: FontAwesomeIcons.plusCircle,
                      onTap: () {
                        reel.addFrame();
                      },
                    ),
                  ),
                ],
              ),
            );

            return ListView.builder(
              itemBuilder: (context, index) {
                final selected = index == reel.selectedFrameId;
                return Column(
                  children: [
                    if (index == 0) before,
                    GestureDetector(
                      onTap: () {
                        _scrollTo(index);
                        if (selected) {
                          setState(() {
                            _durationMode = !_durationMode;
                          });
                        }
                      },
                      onHorizontalDragEnd: (dragDetails) {
                        final toLeft =
                            dragDetails.velocity.pixelsPerSecond.dx < 0;
                        if (toLeft) {
                          // Swiped to left.
                          reel.deleteFrameAt(index);
                        } else {
                          // Swiped to right.
                          reel.createOrRestoreFrameAt(index);
                        }
                      },
                      child: Transform.scale(
                        scale: 0.99,
                        child: FrameThumbnail(
                          frame: visibleFrames[index],
                          size: thumbnailSize,
                          selected: selected,
                          copy: reel.frames[index] == null,
                          duration: _durationMode ? 4 : null,
                        ),
                      ),
                    ),
                    if (index == lastIndex) after,
                  ],
                );
              },
              itemCount: reel.frames.length,
              controller: controller,
            );
          }),
        ),
        if (_durationMode)
          GestureDetector(
            onVerticalDragUpdate: (details) {
              _draggedInDurationMode += details.primaryDelta;

              if (_draggedInDurationMode >= durationModeScrollUnit) {
                _draggedInDurationMode -= durationModeScrollUnit;
                reel.addFrameSlot();
              } else if (_draggedInDurationMode <= -durationModeScrollUnit) {
                _draggedInDurationMode += durationModeScrollUnit;
                reel.removeFrameSlot();
              }
            },
          ),
      ],
    );
  }
}

class FrameThumbnail extends StatelessWidget {
  const FrameThumbnail({
    Key key,
    @required this.size,
    @required this.frame,
    @required this.selected,
    @required this.copy,
    this.duration,
  }) : super(key: key);

  final Size size;
  final FrameModel frame;
  final bool selected;
  final bool copy;
  final int duration;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Opacity(
          opacity: copy ? 0.5 : 1,
          child: CustomPaint(
            size: size,
            painter: FramePainter(frame: frame),
          ),
        ),
        if (selected)
          Container(
            height: size.height,
            width: size.width,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.amber, width: 4),
              color: duration != null
                  ? Colors.amber.withOpacity(0.8)
                  : Colors.transparent,
            ),
            child: duration != null
                ? Center(
                    child: Text(
                      '$duration',
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  )
                : null,
          ),
      ],
    );
  }
}
