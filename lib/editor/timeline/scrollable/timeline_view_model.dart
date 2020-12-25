import 'package:flutter/material.dart';
import 'package:mooltik/editor/timeline/scrollable/convert.dart';
import 'package:mooltik/editor/timeline/scrollable/sliver/frame_sliver.dart';
import 'package:mooltik/editor/timeline/timeline_model.dart';

class TimelineViewModel extends ChangeNotifier {
  TimelineViewModel({
    TimelineModel timeline,
  }) : _timeline = timeline;

  final TimelineModel _timeline;

  double get msPerPx => _msPerPx;
  double _msPerPx = 10;
  double _prevMsPerPx = 10;
  double _scaleOffset;
  Offset _prevFocalPoint;

  double get timelineWidth => durationToPx(_timeline.totalDuration, _msPerPx);

  void onScaleStart(ScaleStartDetails details) {
    _prevMsPerPx = _msPerPx;
    _prevFocalPoint = details.localFocalPoint;
  }

  void onScaleUpdate(ScaleUpdateDetails details) {
    _scaleOffset ??= 1 - details.scale;
    _msPerPx = _prevMsPerPx / (details.scale + _scaleOffset);

    final diff = (details.localFocalPoint - _prevFocalPoint);
    _timeline.scrub(-diff.dx / timelineWidth);

    _prevFocalPoint = details.localFocalPoint;

    notifyListeners();
  }

  void onScaleEnd(ScaleEndDetails details) {
    _scaleOffset = null;
  }

  void onTapUp(TapUpDetails details) {
    print(details.localPosition);
    // details.localPosition.dy < frameSliverTop
    // details.localPosition.dy > frameSliverBottom
    // iterate visibleFrameSlivers
  }

  /// Size of the timeline view.
  /// Update before painting or gesture detection.
  Size size = Size.zero;

  double get _midX => size.width / 2;

  double xFromTime(Duration time) =>
      _midX + durationToPx(time - _timeline.playheadPosition, _msPerPx);

  double widthFromDuration(Duration duration) =>
      durationToPx(duration, _msPerPx);

  FrameSliver getSelectedFrameSliver() {
    final double selectedFrameStartX =
        xFromTime(_timeline.selectedFrameStartTime);
    final double selectedFrameWidth =
        widthFromDuration(_timeline.selectedFrame.duration);
    return FrameSliver(
      startX: selectedFrameStartX,
      endX: selectedFrameStartX + selectedFrameWidth,
      thumbnail: _timeline.selectedFrame.snapshot,
    );
  }

  List<FrameSliver> getVisibleFrameSlivers() {
    final List<FrameSliver> slivers = [getSelectedFrameSliver()];

    // Fill with slivers on left side.
    for (int i = _timeline.selectedFrameIndex - 1;
        i >= 0 && slivers.first.startX > 0;
        i--) {
      slivers.insert(
        0,
        FrameSliver(
          startX: slivers.first.startX -
              widthFromDuration(_timeline.frames[i].duration),
          endX: slivers.first.startX,
          thumbnail: _timeline.frames[i].snapshot,
        ),
      );
    }

    // Fill with slivers on right side.
    for (int i = _timeline.selectedFrameIndex + 1;
        i < _timeline.frames.length && slivers.last.endX < size.width;
        i++) {
      slivers.add(FrameSliver(
        startX: slivers.last.endX,
        endX:
            slivers.last.endX + widthFromDuration(_timeline.frames[i].duration),
        thumbnail: _timeline.frames[i].snapshot,
      ));
    }
    return slivers;
  }
}
