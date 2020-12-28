import 'package:flutter/material.dart';
import 'package:mooltik/editor/frame/frame_model.dart';

class TimelineModel extends ChangeNotifier {
  TimelineModel({
    @required this.frames,
    TickerProvider vsync,
  })  : assert(frames != null && frames.isNotEmpty),
        _selectedFrameIndex = 0,
        _selectedFrameStart = Duration.zero,
        _playheadController = AnimationController(
          vsync: vsync,
          duration: frames.fold(
            Duration.zero,
            (duration, frame) => duration + frame.duration,
          ),
        ) {
    _playheadController.addListener(() {
      _updateSelectedFrame();
      notifyListeners();
    });
  }

  final List<FrameModel> frames;
  final AnimationController _playheadController;

  Duration get playheadPosition => totalDuration * _playheadController.value;

  bool get isPlaying => _playheadController.isAnimating;

  Duration get totalDuration => _playheadController.duration;

  FrameModel get selectedFrame => frames[_selectedFrameIndex];

  int get selectedFrameIndex => _selectedFrameIndex;
  int _selectedFrameIndex;

  bool get lastFrameSelected => _selectedFrameIndex == frames.length - 1;

  Duration get selectedFrameStartTime => _selectedFrameStart;
  Duration _selectedFrameStart;

  Duration get selectedFrameEndTime =>
      _selectedFrameStart + selectedFrame.duration;

  void _updateSelectedFrame() {
    if (playheadPosition < _selectedFrameStart) {
      _selectPrevFrame();
    } else if (playheadPosition >= selectedFrameEndTime) {
      _selectNextFrame();
    }
  }

  void _selectPrevFrame() {
    if (_selectedFrameIndex == 0) return;
    _selectedFrameIndex--;
    _selectedFrameStart -= selectedFrame.duration;
  }

  void _selectNextFrame() {
    if (lastFrameSelected) return;
    _selectedFrameIndex++;
    _selectedFrameStart = selectedFrameEndTime;
  }

  void _resetSelectedFrame() {
    _selectedFrameIndex = 0;
    _selectedFrameStart = Duration.zero;
  }

  double _fraction(Duration playheadPosition) =>
      playheadPosition.inMicroseconds / totalDuration.inMicroseconds;

  /// Scrolls to a new playhead position.
  void seekTo(Duration playheadPosition) {
    _playheadController.animateTo(
      _fraction(playheadPosition),
      duration: Duration(milliseconds: 200),
      curve: Curves.easeInOut,
    );
  }

  /// Scrolls the timeline by a [fraction] of total duration.
  void scrub(double fraction) {
    _playheadController.value += fraction;
  }

  void play() {
    if (_playheadController.value == _playheadController.upperBound) {
      _playheadController.reset();
      _resetSelectedFrame();
    }
    _playheadController.forward();
    notifyListeners();
  }

  void pause() {
    _playheadController.stop();
    notifyListeners();
  }

  bool get stepBackwardAvailable => !isPlaying && _selectedFrameIndex > 0;

  void stepBackward() {
    if (!stepBackwardAvailable) return;
    final Duration time =
        _selectedFrameStart - frames[_selectedFrameIndex - 1].duration;
    final double fraction = time.inMilliseconds / totalDuration.inMilliseconds;
    _playheadController.value = fraction;
    _updateSelectedFrame();
    notifyListeners();
  }

  bool get stepForwardAvailable => !isPlaying && !lastFrameSelected;

  void stepForward() {
    if (!stepForwardAvailable) return;
    final double fraction =
        selectedFrameEndTime.inMilliseconds / totalDuration.inMilliseconds;
    _playheadController.value = fraction;
    _updateSelectedFrame();
    notifyListeners();
  }

  void addFrameAfterSelected() {
    final newFrame = FrameModel(size: frames.first.size);
    frames.insert(_selectedFrameIndex + 1, newFrame);
    _playheadController.duration += newFrame.duration;
    stepForward();
    notifyListeners();
  }

  void deleteFrameAt(int frameIndex) {
    // Outside index range.
    if (frameIndex < 0 || frameIndex >= frames.length) return;

    _playheadController.duration -= frames[frameIndex].duration;
    frames.removeAt(frameIndex);
    _updateSelectedFrame();
    notifyListeners();
  }

  void duplicateFrameAt(int frameIndex) {
    // Outside index range.
    if (frameIndex < 0 || frameIndex >= frames.length) return;

    final newFrame = FrameModel(
      size: frames.first.size,
      initialSnapshot: frames[frameIndex].snapshot,
      duration: frames[frameIndex].duration,
    );
    frames.insert(frameIndex + 1, newFrame);
    _playheadController.duration += newFrame.duration;
    _updateSelectedFrame();
    notifyListeners();
  }
}
