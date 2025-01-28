import 'package:flutter/material.dart';
import 'package:interstellar/src/utils/share.dart';
import 'package:interstellar/src/widgets/loading_button.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:media_kit_video/media_kit_video_controls/media_kit_video_controls.dart'
    as media_kit_video_controls;
import 'package:provider/provider.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart'
    as youtube_explode_dart;
import 'package:interstellar/src/controller/controller.dart';

bool isSupportedYouTubeVideo(Uri link) {
  return ['www.youtube.com', 'youtube.com', 'youtu.be', 'm.youtube.com']
      .contains(link.host);
}

class VideoPlayer extends StatefulWidget {
  final Uri uri;

  const VideoPlayer(this.uri, {super.key});

  @override
  State<VideoPlayer> createState() => _VideoPlayerState();
}

class _VideoPlayerState extends State<VideoPlayer> {
  final player = Player();
  late final controller = VideoController(player);

  Future<void> _initController() async {
    final autoPlay = context.read<AppController>().profile.autoPlayVideos;

    if (isSupportedYouTubeVideo(widget.uri)) {
      final yt = youtube_explode_dart.YoutubeExplode();

      final manifest = await yt.videos.streamsClient.getManifest(widget.uri);

      if (!mounted) return;

      // Use best muxed stream if available, else use best separate video and audio streams
      // TODO: calculate best quality for device based on screen size and data saver mode, also add manual stream selection
      if (manifest.muxed.isNotEmpty) {
        final muxedStream = manifest.muxed.bestQuality;
        player.open(
          Media(muxedStream.url.toString()),
          play: autoPlay,
        );
      } else {
        final videoStream = manifest.video.bestQuality;
        final audioStream = manifest.audio.withHighestBitrate();
        final media = Media(videoStream.url.toString());

        player.open(
          media,
          play: autoPlay,
        );
        player.setAudioTrack(AudioTrack.uri(audioStream.url.toString()));
      }
    } else {
      player.open(
        Media(widget.uri.toString()),
        play: autoPlay,
      );
    }
  }

  @override
  void initState() {
    _initController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement top buttons by setting a MaterialVideoControls & MaterialDesktopVideoControlsTheme
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.width * 9.0 / 16.0,
      child: Video(
        controller: controller,
        controls: (state) {
          return Stack(
            children: [
              media_kit_video_controls.AdaptiveVideoControls(state),
              if (!state.isFullscreen())
                Align(
                  alignment: Alignment.topRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      LoadingIconButton(
                        onPressed: () async => await shareUri(widget.uri),
                        icon: const Icon(Symbols.share_rounded),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!ModalRoute.of(context)!.isCurrent) {
        player.pause();
      }
    });
  }
}
