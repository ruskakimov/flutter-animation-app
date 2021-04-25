import 'package:mooltik/common/data/project/scene_model.dart';
import 'package:mooltik/common/data/project/sound_clip.dart';
import 'package:mooltik/common/data/sequence/sequence.dart';
import 'package:mooltik/drawing/data/frame/frame_model.dart';

class ProjectSaveData {
  ProjectSaveData({
    this.width,
    this.height,
    this.scenes,
    this.sounds,
  });

  ProjectSaveData.fromJson(
    Map<String, dynamic> json,
    String frameDirPath,
    String soundDirPath,
  )   : width = json['width'],
        height = json['height'],
        scenes = _parseScenes(json, frameDirPath),
        sounds = json['sounds'] != null
            ? (json['sounds'] as List<dynamic>)
                .map((d) => SoundClip.fromJson(d, soundDirPath))
                .toList()
            : [];

  Map<String, dynamic> toJson() => {
        'width': width,
        'height': height,
        'scenes': scenes.map((d) => d.toJson()).toList(),
        'sounds': sounds?.map((d) => d.toJson())?.toList() ?? [],
      };

  final double width;
  final double height;
  final List<SceneModel> scenes;
  final List<SoundClip> sounds;

  static List<SceneModel> _parseScenes(
    Map<String, dynamic> json,
    String frameDirPath,
  ) {
    // Latest format.
    if (json.containsKey('scenes')) {
      return (json['scenes'] as List<dynamic>)
          .map((d) => SceneModel.fromJson(d, frameDirPath))
          .toList();
    }

    // Convert v0.8 format to the latest.
    if (json.containsKey('frames')) {
      final frameSeq = Sequence<FrameModel>(
        (json['frames'] as List<dynamic>)
            .map((d) => _parseLegacyFrameData(d, frameDirPath))
            .toList(),
      );
      return [
        SceneModel(
          frameSeq: frameSeq,
          duration: frameSeq.totalDuration,
          playMode: PlayMode.loop, // Showcase new loop feature.
        )
      ];
    }

    throw Exception('Unable to parse project scenes.');
  }

  static FrameModel _parseLegacyFrameData(
    Map<String, dynamic> json,
    String frameDirPath,
  ) {
    json['file_name'] = 'frame${json['id']}.png';
    return FrameModel.fromJson(json, frameDirPath);
  }
}
