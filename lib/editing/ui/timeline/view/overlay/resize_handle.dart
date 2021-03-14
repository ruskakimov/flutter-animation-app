import 'package:flutter/material.dart';

const double resizeHandleWidth = 24;
const double resizeHandleHeight = 48;

class ResizeHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(8),
      color: Theme.of(context).colorScheme.primary,
      elevation: 10,
      child: SizedBox(
        width: resizeHandleWidth,
        height: resizeHandleHeight,
        child: RotatedBox(
          quarterTurns: 1,
          child: Icon(
            Icons.drag_handle_rounded,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
      ),
    );
  }
}
