import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mooltik/common/ui/app_vertical_slider.dart';
import 'package:mooltik/common/ui/app_icon_button.dart';
import 'package:mooltik/common/ui/surface.dart';
import 'package:mooltik/common/ui/animated_drawer.dart';
import 'package:mooltik/drawing/ui/color_picker_drawer.dart';
import 'package:mooltik/drawing/data/onion_model.dart';
import 'package:mooltik/editing/ui/timeline/actionbar/step_backward_button.dart';
import 'package:mooltik/editing/ui/timeline/actionbar/step_forward_button.dart';
import 'package:mooltik/editing/data/timeline_model.dart';
import 'package:provider/provider.dart';
import 'package:mooltik/drawing/data/toolbox/toolbox_model.dart';

enum RightDrawer {
  strokeSize,
  color,
}

class DrawingActionbar extends StatefulWidget {
  const DrawingActionbar({Key key}) : super(key: key);

  @override
  _DrawingActionbarState createState() => _DrawingActionbarState();
}

class _DrawingActionbarState extends State<DrawingActionbar> {
  RightDrawer rightOpen;

  @override
  Widget build(BuildContext context) {
    final toolbox = context.watch<ToolboxModel>();

    final bar = Surface(
      child: Row(
        children: <Widget>[
          AppIconButton(
            icon: FontAwesomeIcons.arrowLeft,
            onTap: () {
              Navigator.pop(context);
            },
          ),
          AppIconButton(
            icon: FontAwesomeIcons.lightbulb,
            selected: context.watch<OnionModel>().enabled,
            onTap: () {
              context.read<OnionModel>().toggle();
            },
          ),
          Spacer(),
          for (var i = 0; i < toolbox.tools.length; i++)
            AppIconButton(
              icon: toolbox.tools[i].icon,
              selected: toolbox.tools[i] == toolbox.selectedTool,
              onTap: () {
                if (toolbox.tools[i] == toolbox.selectedTool) {
                  setState(() {
                    rightOpen = rightOpen == RightDrawer.strokeSize
                        ? null
                        : RightDrawer.strokeSize;
                  });
                }
                toolbox.selectTool(i);
              },
            ),
          Spacer(),
          StepBackwardButton(),
          SizedBox(
            width: 32,
            child: Center(
              child: Text(
                '${context.watch<TimelineModel>().selectedFrameIndex + 1}',
              ),
            ),
          ),
          StepForwardButton(),
        ],
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        bar,
        Expanded(
          child: _buildDrawerArea(),
        ),
      ],
    );
  }

  Widget _buildDrawerArea() {
    return Stack(
      alignment: Alignment.center,
      children: [
        StrokeSizeDrawer(
          open: rightOpen == RightDrawer.strokeSize,
        ),
        ColorPickerDrawer(
          open: rightOpen == RightDrawer.color,
        ),
      ],
    );
  }
}

class StrokeSizeDrawer extends StatelessWidget {
  const StrokeSizeDrawer({
    Key key,
    this.open,
  }) : super(key: key);

  final bool open;

  @override
  Widget build(BuildContext context) {
    final toolbox = context.watch<ToolboxModel>();
    final width = toolbox.selectedTool.paint.strokeWidth;

    return AnimatedRightDrawer(
      width: 64,
      open: open,
      child: AppVerticalSlider(
        value: width,
        onChanged: (value) {
          toolbox.changeToolWidth(value.round());
        },
      ),
    );
  }
}