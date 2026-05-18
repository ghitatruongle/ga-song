import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../widgets/desktop_title_bar.dart';

class OnlineScreen extends StatefulWidget {
  const OnlineScreen({super.key});

  @override
  State<OnlineScreen> createState() => _OnlineScreenState();
}

class _OnlineScreenState extends State<OnlineScreen> {
  final TextEditingController _searchController = TextEditingController();
  late YoutubePlayerController _controller;
  bool _isPlaying = false;
  String _currentTitle = 'Chưa chọn bài hát';

  // Chế độ xem video hay chỉ nghe nhạc
  bool _showVideo = true; 

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      params: const YoutubePlayerParams(
        showControls: true,
        mute: false,
        showFullscreenButton: true,
        loop: false,
      ),
    );
    _controller.listen((event) {
      if (mounted) {
        setState(() {
          _isPlaying = event.playerState == PlayerState.playing;
          _currentTitle = event.metaData.title;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _controller.close();
    super.dispose();
  }

  void _search(String query) {
    if (query.trim().isEmpty) return;
    // Extract video ID from youtube URL or just load if it's an ID
    // Simplest way is to parse if it's a link:
    String? videoId = YoutubePlayerController.convertUrlToId(query);
    if (videoId != null) {
      _controller.loadVideoById(videoId: videoId);
    } else {
      // Giả sử user nhập trực tiếp ID, hoặc tương lai tích hợp YouTube Data API để search
      // Tạm thời nếu không phải URL, coi như là ID.
      _controller.loadVideoById(videoId: query.trim());
    }
  }

  // Q-3 fix: Use shared DesktopTitleBar widget
  Widget _buildTitleBar(Color textColor) => DesktopTitleBar(iconColor: textColor);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Column(
      children: [
        _buildTitleBar(textColor),
        Padding(
          padding: const EdgeInsets.fromLTRB(40, 10, 40, 20),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    hintText: 'Dán Link hoặc ID YouTube vào đây...',
                    hintStyle: TextStyle(color: textColor.withValues(alpha: 0.5)),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: Icon(Icons.search, color: textColor.withValues(alpha: 0.5)),
                  ),
                  onSubmitted: _search,
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: Icon(
                  _showVideo ? Icons.videocam : Icons.videocam_off,
                  color: textColor,
                ),
                tooltip: _showVideo ? 'Ẩn Video (Chỉ nghe nhạc)' : 'Hiện Video',
                onPressed: () {
                  setState(() {
                    _showVideo = !_showVideo;
                  });
                },
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: () => _search(_searchController.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
                child: const Text('Tìm'),
              ),
            ],
          ),
        ),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Trình phát Video
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(40, 0, 20, 40),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFEEEEEE),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _showVideo
                        ? YoutubePlayer(
                            controller: _controller,
                            backgroundColor: Colors.transparent,
                          )
                        : Stack(
                            alignment: Alignment.center,
                            children: [
                              // Ẩn player đi, chỉ nghe tiếng
                              Opacity(
                                opacity: 0.01,
                                child: IgnorePointer(
                                  child: YoutubePlayer(controller: _controller),
                                ),
                              ),
                              // Cover art tĩnh
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.music_note_rounded, size: 80, color: textColor.withValues(alpha: 0.2)),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Đang phát âm thanh',
                                    style: TextStyle(color: textColor.withValues(alpha: 0.5), fontSize: 16),
                                  ),
                                  const SizedBox(height: 8),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 24),
                                    child: Text(
                                      _currentTitle.isEmpty ? 'Chưa chọn bài hát' : _currentTitle,
                                      style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              
              // Hướng dẫn / Thông tin bổ sung
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 0, 40, 40),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hướng dẫn',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Tính năng YouTube Stream hoạt động hoàn toàn độc lập với kho nhạc Offline. '
                          'Giúp bạn nghe bất kỳ bài hát nào từ kho tàng YouTube.\n\n'
                          'Để phát nhạc, hãy copy đường dẫn (Link) của video YouTube và dán vào thanh tìm kiếm bên cạnh.',
                          style: TextStyle(
                            color: textColor.withValues(alpha: 0.7),
                            height: 1.5,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 32),
                        if (_isPlaying) ...[
                          Text(
                            'Đang phát',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _currentTitle,
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
