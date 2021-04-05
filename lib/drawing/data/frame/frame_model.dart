import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:mooltik/common/data/io/png.dart';
import 'package:mooltik/common/data/duration_methods.dart';
import 'package:mooltik/common/data/sequence/time_span.dart';
import 'package:path/path.dart' as p;

class FrameModel extends TimeSpan {
  FrameModel({
    @required this.file,
    Duration duration = const Duration(seconds: 1),
  }) : super(duration);

  final File file;

  Size get size => Size(width.toDouble(), height.toDouble());

  int get width => _snapshot?.width;

  int get height => _snapshot?.height;

  ui.Image get snapshot => _snapshot;
  ui.Image _snapshot;
  set snapshot(ui.Image snapshot) {
    _snapshot = snapshot;
    notifyListeners();
  }

  Future<void> loadSnapshot() async {
    _snapshot = await pngRead(file);
  }

  Future<void> saveSnapshot() async {
    await pngWrite(file, _snapshot);
  }

  factory FrameModel.fromJson(Map<String, dynamic> json, String frameDirPath) =>
      FrameModel(
        file: File(p.join(frameDirPath, json['file_name'])),
        duration: parseDuration(json['duration']),
      );

  Map<String, dynamic> toJson() => {
        'file_name': p.basename(file.path),
        'duration': duration.toString(),
      };
}
