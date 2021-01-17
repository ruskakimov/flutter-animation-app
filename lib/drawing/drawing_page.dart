import 'package:flutter/material.dart';
import 'package:mooltik/common/data/project/project.dart';
import 'package:mooltik/drawing/data/easel_model.dart';
import 'package:mooltik/drawing/data/frame/frame_model.dart';
import 'package:mooltik/drawing/ui/drawing_actionbar.dart';
import 'package:mooltik/drawing/data/onion_model.dart';
import 'package:mooltik/drawing/ui/size_picker.dart';
import 'package:mooltik/editing/data/timeline_model.dart';
import 'package:mooltik/drawing/data/toolbox/toolbox_model.dart';
import 'package:mooltik/drawing/ui/easel/easel.dart';
import 'package:mooltik/editing/ui/preview/frame_thumbnail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DrawingPage extends StatelessWidget {
  static const routeName = '/draw';

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProxyProvider<TimelineModel, OnionModel>(
          update: (context, timeline, model) =>
              model..updateSelectedIndex(timeline.selectedFrameIndex),
          create: (context) => OnionModel(
            frames: context.read<TimelineModel>().frames,
            selectedIndex: context.read<TimelineModel>().selectedFrameIndex,
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => ToolboxModel(context.read<SharedPreferences>()),
        ),
      ],
      builder: (context, child) {
        final timeline = context.watch<TimelineModel>();
        final onion = context.watch<OnionModel>();

        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.background,
          body: MultiProvider(
            providers: [
              ChangeNotifierProvider<FrameModel>.value(
                value: timeline.selectedFrame,
              ),
              ChangeNotifierProxyProvider2<TimelineModel, ToolboxModel,
                  EaselModel>(
                create: (context) => EaselModel(
                  frame: timeline.selectedFrame,
                  frameSize: context.read<Project>().frameSize,
                  selectedTool: context.read<ToolboxModel>().selectedTool,
                ),
                update: (_, reel, toolbox, easel) => easel
                  ..updateFrame(reel.selectedFrame)
                  ..updateSelectedTool(toolbox.selectedTool),
              ),
            ],
            child: SafeArea(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 44.0),
                      child: Easel(),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 44,
                    child: DrawingActionbar(),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: SizePicker(),
                    ),
                  ),
                  Positioned(
                    bottom: 24,
                    left: 8,
                    width: 60,
                    height: 60,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Color(0xC4C4C4).withOpacity(0.5),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: FrameThumbnail(frame: onion.frameBefore),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 24,
                    right: 8,
                    width: 60,
                    height: 60,
                    child: FrameThumbnail(frame: onion.frameAfter),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
