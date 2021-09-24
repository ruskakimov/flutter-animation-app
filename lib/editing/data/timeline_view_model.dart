import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:mooltik/common/data/extensions/duration_methods.dart';
import 'package:mooltik/common/data/project/fps_config.dart';
import 'package:mooltik/common/data/project/frame_interface.dart';
import 'package:mooltik/common/data/project/scene.dart';
import 'package:mooltik/common/data/project/scene_layer.dart';
import 'package:mooltik/common/data/project/sound_clip.dart';
import 'package:mooltik/common/data/sequence/sequence.dart';
import 'package:mooltik/common/data/sequence/time_span.dart';
import 'package:mooltik/drawing/data/frame/frame.dart';
import 'package:mooltik/editing/data/convert.dart';
import 'package:mooltik/editing/data/timeline_model.dart';
import 'package:mooltik/editing/ui/timeline/view/sliver/image_sliver.dart';
import 'package:mooltik/editing/ui/timeline/view/sliver/sliver.dart';
import 'package:mooltik/editing/ui/timeline/view/sliver/sound_sliver.dart';
import 'package:mooltik/editing/ui/timeline/view/sliver/video_sliver.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _msPerPxKey = 'timeline_view_ms_per_px';

class TimelineViewModel extends ChangeNotifier {
  TimelineViewModel({
    required TimelineModel timeline,
    required List<SoundClip>? soundClips,
    required SharedPreferences? sharedPreferences,
  })  : _timeline = timeline,
        _soundClips = soundClips ?? [],
        _preferences = sharedPreferences,
        _msPerPx = sharedPreferences?.getDouble(_msPerPxKey) ?? 10 {
    _prevMsPerPx = _msPerPx;
    _timeline.addListener(notifyListeners);
  }

  @override
  void dispose() {
    _timeline.removeListener(notifyListeners);
    super.dispose();
  }

  SharedPreferences? _preferences;
  final TimelineModel _timeline;
  final List<SoundClip> _soundClips;

  bool get isEditingScene => _sceneEdit;
  bool _sceneEdit = false;

  double get msPerPx => _msPerPx;
  double _msPerPx;
  late double _prevMsPerPx;
  double? _scaleOffset;
  late Offset _prevFocalPoint;

  double get timelineWidth => durationToPx(_timeline.totalDuration, _msPerPx);

  void onScaleStart(ScaleStartDetails details) {
    _prevMsPerPx = _msPerPx;
    _prevFocalPoint = details.localFocalPoint;
  }

  void onScaleUpdate(ScaleUpdateDetails details) {
    _scaleOffset ??= 1 - details.scale;
    _setScale(_prevMsPerPx / (details.scale + _scaleOffset!));

    final diff = (details.localFocalPoint - _prevFocalPoint);
    var timeDiff = pxToDuration(-diff.dx, _msPerPx);
    _timeline.scrub(timeDiff);

    removeSliverSelection();

    _prevFocalPoint = details.localFocalPoint;

    notifyListeners();
  }

  void _setScale(double newMsPerPx) {
    _msPerPx = newMsPerPx.clamp(1.0, 100.0);
    _preferences!.setDouble(_msPerPxKey, _msPerPx);
  }

  void onScaleEnd(ScaleEndDetails details) {
    _scaleOffset = null;
  }

  void onTapUp(TapUpDetails details) {
    final sliverCoord = _getSliverCoordUnderPosition(details.localPosition);
    selectSliver(sliverCoord);
  }

  SliverCoord? _getSliverCoordUnderPosition(Offset position) {
    bool withinRow(double rowTop, double rowBottom) =>
        position.dy >= rowTop && position.dy <= rowBottom;

    for (var r = 0; r < _sliverRows.length; r++) {
      final row = _sliverRows[r];

      final rowTop = row.first.area.top;
      final rowBottom = row.first.area.bottom;

      if (!withinRow(rowTop, rowBottom)) continue;

      for (var c = 0; c < row.length; c++) {
        final sliver = row[c];

        if (sliver.area.contains(position)) {
          // Ghost slivers cannot be selected.
          if (sliver is ImageSliver && sliver.ghost) return null;

          return SliverCoord(r, c);
        }
      }
    }
    return null;
  }

  /// Size of the timeline view.
  /// Update before painting or gesture detection.
  Size size = Size.zero;

  double get _midX => size.width / 2;

  double get sliverHeight => 56;
  double get sliverGap => 8;

  int get sliverRows => isEditingScene ? _sceneLayers.length + 1 : 2;

  // TODO: Use another getter where grouped layers are combined
  // TODO: List of `SceneLayerInterface` or `TimelineSceneLayerInterface` with only neccessary API
  List<SceneLayer> get _sceneLayers => _timeline.currentScene.layers;

  List<Sequence<TimeSpan>> get sequenceRows => isEditingScene
      ? _sceneLayers.map((layer) => layer.frameSeq).toList()
      : [_timeline.sceneSeq];

  double get viewHeight =>
      sliverRows * sliverHeight + (sliverRows + 1) * sliverGap;

  double rowTop(int rowIndex) =>
      (rowIndex + 1) * sliverGap + rowIndex * sliverHeight;

  double rowMiddle(int rowIndex) =>
      (rowTop(rowIndex) + rowBottom(rowIndex)) / 2;

  double rowBottom(int rowIndex) => rowTop(rowIndex) + sliverHeight;

  double xFromTime(Duration time) =>
      _midX + durationToPx(time - _timeline.playheadPosition, _msPerPx);

  Duration timeFromX(double x) =>
      _timeline.playheadPosition + pxToDuration(x - _midX, msPerPx);

  double widthFromDuration(Duration duration) =>
      durationToPx(duration, _msPerPx);

  Duration get sceneStart => _timeline.currentSceneStart;

  Duration get sceneEnd => _timeline.currentSceneEnd;

  late List<List<Sliver>> _sliverRows;

  List<List<Sliver>> getSliverRows() {
    final rows = <List<Sliver>>[];
    int rowIndex = 0;

    void addRow(List<Sliver> row) {
      rows.add(row);
      rowIndex++;
    }

    if (isEditingScene) {
      for (final layer in _sceneLayers) {
        final frames = layer.getFrames(_timeline.currentScene.duration);
        final frameRow = frameSliverRow(
          areas: timeSpanAreas(
            timeSpans: frames,
            top: rowTop(rowIndex),
            bottom: rowBottom(rowIndex),
            start: sceneStart,
          ),
          frames: frames,
          numberOfRealFrames: layer.frameSeq.length,
        ).toList();

        addRow(frameRow);
      }
    } else {
      final sceneSeq = _timeline.sceneSeq;
      final sceneRow = sceneSliverRow(
        areas: timeSpanAreas(
          timeSpans: sceneSeq.iterable,
          top: rowTop(rowIndex),
          bottom: rowBottom(rowIndex),
        ),
        scenes: sceneSeq.iterable,
      ).toList();

      addRow(sceneRow);
    }

    if (_soundClips.isNotEmpty) {
      addRow(soundSliverRow(
        rowTop: rowTop(rowIndex),
        rowBottom: rowBottom(rowIndex),
      ).toList());
    }

    _sliverRows = rows;
    return rows;
  }

  Iterable<ImageSliver> frameSliverRow({
    required Iterable<Rect> areas,
    required Iterable<FrameInterface> frames,
    required int numberOfRealFrames,
  }) sync* {
    int frameIndex = 0;
    final areaIt = areas.iterator;
    final frameIt = frames.iterator;

    while (areaIt.moveNext() && frameIt.moveNext()) {
      final area = areaIt.current;
      final frame = frameIt.current;
      final isGhostFrame = frameIndex >= numberOfRealFrames;

      yield ImageSliver(
        area: area,
        image: frame.image,
        ghost: isGhostFrame,
      );

      frameIndex++;
    }
  }

  Iterable<VideoSliver> sceneSliverRow({
    required Iterable<Rect> areas,
    required Iterable<Scene> scenes,
  }) sync* {
    final areaIt = areas.iterator;
    final sceneIt = scenes.iterator;

    while (areaIt.moveNext() && sceneIt.moveNext()) {
      final area = areaIt.current;
      final scene = sceneIt.current;

      yield VideoSliver(
        area: area,
        thumbnailAt: (double x) {
          final position = pxToDuration(x - area.left, msPerPx);
          return scene.imageAt(position);
        },
      );
    }
  }

  Iterable<SoundSliver> soundSliverRow({
    required double rowTop,
    required double rowBottom,
  }) {
    return _soundClips.map((soundClip) => SoundSliver(
          area: Rect.fromLTRB(
            xFromTime(soundClip.startTime),
            rowTop,
            xFromTime(soundClip.endTime),
            rowBottom,
          ),
        ));
  }

  Iterable<Rect> timeSpanAreas({
    required Iterable<TimeSpan> timeSpans,
    required double top,
    required double bottom,
    Duration start = Duration.zero,
  }) sync* {
    for (final timeSpan in timeSpans) {
      final end = start + timeSpan.duration;
      final left = xFromTime(start);
      final right = xFromTime(end);

      yield Rect.fromLTRB(left, top, right, bottom);

      start += timeSpan.duration;
    }
  }

  // ===========================
  // Selected sliver operations:
  // ===========================

  SliverCoord? get selectedSliverId => _selectedSliverCoord;
  SliverCoord? _selectedSliverCoord;

  Sequence<TimeSpan>? get selectedSliverSequence => _selectedSliverCoord != null
      ? sequenceRows[_selectedSliverCoord!.rowIndex]
      : null;

  void selectSliver(SliverCoord? sliverId) {
    if (_timeline.isPlaying) _timeline.pause();
    _selectedSliverCoord = sliverId;
    notifyListeners();
  }

  void selectScene(int sceneIndex) {
    if (isEditingScene) return;
    selectSliver(SliverCoord(0, sceneIndex));
  }

  void removeSliverSelection() => selectSliver(null);

  bool get showSliverMenu => _selectedSliverCoord != null;

  double get selectedSliverMidY => rowMiddle(_selectedSliverCoord!.rowIndex);

  bool get showResizeStartHandle =>
      showSliverMenu &&
      _selectedSliverCoord!.colIndex != 0 &&
      !hasSelectedSoundClip;

  bool get showResizeEndHandle => showSliverMenu && !hasSelectedSoundClip;

  TimeSpan? get selectedSpan {
    final coord = _selectedSliverCoord;
    if (coord == null) return null;

    if (coord.rowIndex < sequenceRows.length) {
      return sequenceRows[coord.rowIndex][coord.colIndex];
    } else if (coord.rowIndex == sequenceRows.length) {
      // Sound row.
      return _soundClips[coord.colIndex];
    }
    return null;
  }

  bool get hasSelectedSoundClip => selectedSpan is SoundClip;

  Frame? get selectedFrame => selectedSpan as Frame?;
  Scene? get selectedScene => selectedSpan as Scene?;

  Duration? get _selectedSliverDuration => selectedSpan?.duration;

  String? get selectedSliverDurationLabel {
    if (_selectedSliverDuration == null) return null;
    final duration = _selectedSliverDuration!;

    if (duration < Duration(seconds: 1)) {
      final frameCount = (duration / singleFrameDuration).floor();
      return '$frameCount F';
    } else if (duration < Duration(minutes: 1)) {
      final seconds = duration / Duration(seconds: 1);
      return '${seconds.toStringAsFixed(2)}s';
    } else {
      final minutes = duration.inMinutes;
      final seconds = (duration % Duration(minutes: 1)) / Duration(seconds: 1);
      return '${minutes}m ${seconds.toStringAsFixed(2)}s';
    }
  }

  void editScene() {
    if (isEditingScene) return;
    _timeline.sceneSeq.currentIndex = _selectedSliverCoord!.colIndex;
    _sceneEdit = true;
    _timeline.isSceneBound = true;
    removeSliverSelection();
    notifyListeners();
  }

  void finishSceneEdit() {
    if (!isEditingScene) return;
    _sceneEdit = false;
    _timeline.isSceneBound = false;
    removeSliverSelection();
    notifyListeners();
  }

  // =====================
  // Scene layers methods:
  // =====================

  int get sceneLayerCount => _sceneLayers.length;

  List<FrameInterface> layerFrames(int layerIndex) =>
      _sceneLayers[layerIndex].frameSeq.iterable.toList();

  void setLayerSpeed(int layerIndex, Duration frameDuration) {
    final frameSeq = _sceneLayers[layerIndex].frameSeq;

    for (var i = 0; i < frameSeq.length; i++) {
      frameSeq.changeSpanDurationAt(i, frameDuration);
    }
  }

  PlayMode layerPlayMode(int layerIndex) => _sceneLayers[layerIndex].playMode;

  void nextScenePlayModeForLayer(int layerIndex) {
    final layer = _sceneLayers[layerIndex];
    layer.nextPlayMode();
    notifyListeners();
  }

  bool isLayerVisible(int layerIndex) => _sceneLayers[layerIndex].visible;

  void toggleLayerVisibility(int layerIndex) {
    final layer = _sceneLayers[layerIndex];
    layer.setVisibility(!layer.visible);
    notifyListeners();
  }

  // ===============
  // Sliver methods:
  // ===============

  bool get canDeleteSelected {
    if (hasSelectedSoundClip) return true;

    return selectedSliverSequence != null
        ? selectedSliverSequence!.length > 1
        : false;
  }

  void deleteSelected() {
    if (_selectedSliverCoord == null) return;
    if (!canDeleteSelected) return;

    final removedSliver =
        selectedSliverSequence!.removeAt(_selectedSliverCoord!.colIndex);

    Future.delayed(
      Duration(seconds: 1),
      () => removedSliver.dispose(),
    );

    removeSliverSelection();
    notifyListeners();
  }

  void deleteSoundClips() {
    _soundClips.clear();
    notifyListeners();
  }

  Future<void> duplicateSelected() async {
    if (_selectedSliverCoord == null) return;
    final duplicate = isEditingScene
        ? await selectedFrame!.duplicate()
        : await selectedScene!.duplicate();
    selectedSliverSequence!
        .insert(_selectedSliverCoord!.colIndex + 1, duplicate);
    removeSliverSelection();
    notifyListeners();
  }

  Duration get selectedSliverStartTime => isEditingScene
      ? sceneStart +
          selectedSliverSequence!.startTimeOf(_selectedSliverCoord!.colIndex)
      : selectedSliverSequence!.startTimeOf(_selectedSliverCoord!.colIndex);

  /// Handle start time drag handle's new [updatedTimestamp].
  void onStartTimeHandleDragUpdate(Duration updatedTimestamp) {
    if (_shouldSnapToPlayhead(updatedTimestamp)) {
      updatedTimestamp = _timeline.playheadPosition;
    }
    updatedTimestamp = TimeSpan.roundDurationToFrames(updatedTimestamp);

    final newSelectedDuration = selectedSliverEndTime - updatedTimestamp;
    final diff = newSelectedDuration - _selectedSliverDuration!;
    final newPrevDuration =
        selectedSliverSequence![_selectedSliverCoord!.colIndex - 1].duration -
            diff;

    if (newPrevDuration < singleFrameDuration) return;

    selectedSliverSequence!.changeSpanDurationAt(
        _selectedSliverCoord!.colIndex - 1, newPrevDuration);
    selectedSliverSequence!.changeSpanDurationAt(
        _selectedSliverCoord!.colIndex, newSelectedDuration);
    notifyListeners();
  }

  Duration get selectedSliverEndTime => isEditingScene
      ? sceneStart +
          selectedSliverSequence!.endTimeOf(_selectedSliverCoord!.colIndex)
      : selectedSliverSequence!.endTimeOf(_selectedSliverCoord!.colIndex);

  /// Handle end time drag handle's new [updatedTimestamp].
  void onEndTimeHandleDragUpdate(Duration updatedTimestamp) {
    if (_shouldSnapToPlayhead(updatedTimestamp)) {
      updatedTimestamp = _timeline.playheadPosition;
    }
    updatedTimestamp = TimeSpan.roundDurationToFrames(updatedTimestamp);
    final newDuration = updatedTimestamp - selectedSliverStartTime;

    selectedSliverSequence!
        .changeSpanDurationAt(_selectedSliverCoord!.colIndex, newDuration);
    notifyListeners();
  }

  /// Whether timestamp is close enough to playhead for it to snap to it.
  bool _shouldSnapToPlayhead(Duration timestamp) {
    final diff = (_timeline.playheadPosition - timestamp).abs();
    final pxDiff = durationToPx(diff, _msPerPx);
    return pxDiff <= 12;
  }

  void onSceneEndHandleDragUpdate(Duration updatedTimestamp) {
    updatedTimestamp = TimeSpan.roundDurationToFrames(updatedTimestamp);

    // Keep playhead within current scene.
    if (updatedTimestamp <= _timeline.playheadPosition) {
      updatedTimestamp = TimeSpan.ceilDurationToFrames(
        _timeline.playheadPosition + Duration(microseconds: 1),
      );
    }

    final newDuration = updatedTimestamp - sceneStart;

    _timeline.sceneSeq.changeCurrentSpanDuration(newDuration);
    notifyListeners();
  }
}

class SliverCoord extends Equatable {
  SliverCoord(this.rowIndex, this.colIndex);

  final int rowIndex;
  final int colIndex;

  @override
  List<Object> get props => [rowIndex, colIndex];
}
