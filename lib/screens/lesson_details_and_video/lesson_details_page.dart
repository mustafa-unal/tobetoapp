import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tobetoapp/bloc/videos/videos_bloc.dart';
import 'package:tobetoapp/bloc/videos/videos_state.dart';
import 'package:tobetoapp/models/lesson_model.dart';
import 'package:tobetoapp/utils/theme/constants/constants.dart';
import 'package:tobetoapp/widgets/common_header.dart';
import 'package:tobetoapp/widgets/common_info_dialog.dart';
import 'package:tobetoapp/widgets/common_video_handler.dart';
import 'package:tobetoapp/widgets/common_video_player.dart';
import 'package:tobetoapp/widgets/common_video_progress.dart';

class LessonDetailsPage extends StatefulWidget {
  final LessonModel lesson;

  const LessonDetailsPage({Key? key, required this.lesson}) : super(key: key);

  @override
  _LessonDetailsPageState createState() => _LessonDetailsPageState();
}

class _LessonDetailsPageState extends State<LessonDetailsPage> {
  late VideoHandler _videoHandler;
  String? _currentVideoUrl;

  @override
  void initState() {
    super.initState();
    _videoHandler = VideoHandler(
      context: context,
      collectionId: widget.lesson.id!,
      videoIds: widget.lesson.videoIds ?? [],
    );
    _videoHandler.loadVideos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Image.asset(
          "assets/logo/tobetologo.PNG",
          width: MediaQuery.of(context).size.width * 0.43,
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<VideoBloc, VideoState>(
        builder: (context, state) {
          if (state is VideosLoading) {
            return Center(child: CircularProgressIndicator());
          } else if (state is VideosLoaded) {
            final videos = state.videos;
            final progress = _videoHandler.calculateProgress(videos);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CommonHeader(
                  itemId: widget.lesson.id,
                  title: widget.lesson.title,
                  onInfoPressed: () => showCommonInfoDialog(
                    context,
                    videos,
                    widget.lesson.startDate,
                    widget.lesson.endDate,
                    widget.lesson.title!,
                  ),
                ),
                SizedBox(height: AppConstants.sizedBoxHeightSmall),
                CommonVideoPlayer(
                  videoUrl: _currentVideoUrl ?? _videoHandler.currentVideoUrl,
                  onVideoComplete: _videoHandler.onVideoComplete,
                  onTimeUpdate: _videoHandler.onTimeUpdate,
                ),
                Expanded(
                  child: CommonVideoProgress(
                    videos: videos,
                    onVideoTap: (video) {
                      setState(() {
                        _videoHandler.onVideoTap(video);
                        _currentVideoUrl = video.link;
                      });
                    },
                    progress: progress,
                  ),
                ),
              ],
            );
          } else {
            return SizedBox.shrink();
          }
        },
      ),
    );
  }
}
