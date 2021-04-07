import 'package:flutter/material.dart';
import 'package:mooltik/editing/data/timeline_view_model.dart';
import 'package:mooltik/editing/ui/timeline/view/overlay/resize_handle.dart';
import 'package:mooltik/editing/ui/timeline/view/overlay/timeline_positioned.dart';
import 'package:provider/provider.dart';

class ResizeStartHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final timelineView = context.watch<TimelineViewModel>();

    return TimelinePositioned(
      timestamp: timelineView.selectedSliverStartTime,
      y: timelineView.imageSliverMid,
      width: resizeHandleWidth,
      height: resizeHandleHeight,
      onDragUpdate: (Duration updatedTime) =>
          timelineView.onStartTimeHandleDragUpdate(updatedTime),
      child: ResizeHandle(),
    );
  }
}
