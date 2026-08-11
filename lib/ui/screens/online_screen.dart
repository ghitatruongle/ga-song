import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../../core/theme/tokens.dart';
import '../../providers/service_providers.dart';
import '../widgets/desktop_title_bar.dart';

class OnlineScreen extends ConsumerStatefulWidget {
  const OnlineScreen({super.key});

  @override
  ConsumerState<OnlineScreen> createState() => _OnlineScreenState();
}

class _OnlineScreenState extends ConsumerState<OnlineScreen> {
  final TextEditingController _searchController = TextEditingController();
  late YoutubePlayerController _controller;
  String _currentTitle = 'Chưa chọn bài hát';
  bool _showVideo = true;

  // ─── Desktop webview state (youtube_player_iframe chỉ chạy trên mobile) ──
  bool get _isDesktopPlatform =>
      !kIsWeb && !Platform.isIOS && !Platform.isAndroid;
  String? _desktopVideoId;
  InAppWebViewController? _webViewController;
  String? _webViewError;

  // Preset sample songs for 1-tap testing
  final List<Map<String, String>> _sampleSongs = [
    {
      'title': 'Lofi Hip Hop - Beats to Relax/Study',
      'id': 'jfKfPfyJRdk',
      'tag': 'Lofi Chill',
    },
    {
      'title': 'Beautiful Piano Music - Peaceful & Relaxing',
      'id': '77ZozI0rw7w',
      'tag': 'Piano',
    },
    {
      'title': 'Acoustic Guitar Hits Collection',
      'id': 'N3oCS85HVPY',
      'tag': 'Acoustic',
    },
    {
      'title': 'Deep Focus Music for Work & Study',
      'id': 'WPni755-Krg',
      'tag': 'Focus',
    },
  ];

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      params: const YoutubePlayerParams(
        showFullscreenButton: true,
        strictRelatedVideos: true,
      ),
    );

    _controller.listen((final event) {
      if (mounted) {
        setState(() {
          if (event.metaData.title.isNotEmpty) {
            _currentTitle = event.metaData.title;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _webViewController = null;
    _searchController.dispose();
    _controller.close();
    super.dispose();
  }

  /// Extracts standard 11-char YouTube Video ID from any link format or direct ID.
  String? _extractYouTubeId(final String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;

    // Direct 11-char video ID
    final idRegex = RegExp(r'^[a-zA-Z0-9_-]{11}$');
    if (idRegex.hasMatch(trimmed)) return trimmed;

    // Full YouTube URLs (watch?v=, youtu.be/, shorts/, embed/, m.youtube.com, etc.)
    final urlRegex = RegExp(
      r'(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?|shorts)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})',
      caseSensitive: false,
    );
    final match = urlRegex.firstMatch(trimmed);
    if (match != null && match.groupCount >= 1) {
      return match.group(1);
    }

    // Fallback to built-in converter
    try {
      return YoutubePlayerController.convertUrlToId(trimmed);
    } catch (_) {
      return null;
    }
  }

  void _playVideo(final String input) {
    final videoId = _extractYouTubeId(input);
    if (videoId == null || videoId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không nhận diện được Link hoặc Video ID YouTube!'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // Pause local audio player if playing
    try {
      ref.read(audioEngineServiceProvider).pause();
    } catch (_) {}

    if (_isDesktopPlatform) {
      // Desktop: youtube_player_iframe không hỗ trợ → dùng webview.
      // Dùng trang watch thay vì embed — embed hay bị YouTube chặn trên webview.
      setState(() => _desktopVideoId = videoId);
      _webViewController?.loadUrl(
        urlRequest: URLRequest(
          url: WebUri('https://www.youtube.com/watch?v=$videoId'),
        ),
      );
    } else {
      _controller.loadVideoById(videoId: videoId);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đang tải video ID: $videoId...'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildTitleBar(final Color textColor) =>
      DesktopTitleBar(iconColor: textColor);

  /// Desktop player: youtube_player_iframe không hỗ trợ desktop nên dùng
  /// InAppWebView mở YouTube embed. Nếu chưa có video → hiển thị hướng dẫn.
  Widget _buildDesktopWebView() {
    final videoId = _desktopVideoId;
    if (videoId == null) {
      return Container(
        color: Colors.black,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: const Text(
          'Dán Link hoặc Video ID YouTube phía trên để bắt đầu',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white54, fontSize: 14),
        ),
      );
    }
    if (_webViewError != null) {
      // Fallback instead of a blank/white screen when the webview fails
      return Container(
        color: Colors.black,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange,
              size: 40,
            ),
            const SizedBox(height: 8),
            const Text(
              'Không tải được video từ YouTube.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              _webViewError!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white38, fontSize: 11),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: () {
                setState(() => _webViewError = null);
                _webViewController?.loadUrl(
                  urlRequest: URLRequest(
                    url: WebUri('https://www.youtube.com/watch?v=$videoId'),
                  ),
                );
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }
    return InAppWebView(
      key: ValueKey('yt_$videoId'),
      initialUrlRequest: URLRequest(
        url: WebUri('https://www.youtube.com/watch?v=$videoId'),
      ),
      initialSettings: InAppWebViewSettings(
        mediaPlaybackRequiresUserGesture: false,
        allowsInlineMediaPlayback: true,
        // Keep default UA — a custom one can trigger YouTube bot checks.
      ),
      onWebViewCreated: (final controller) {
        _webViewController = controller;
        if (_webViewError != null) setState(() => _webViewError = null);
      },
      onReceivedError: (final controller, final request, final error) {
        if (mounted) setState(() => _webViewError = error.description);
      },
    );
  }

  @override
  Widget build(final BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildTitleBar(textColor),
            // Header Search Input
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 40,
                vertical: 12,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        hintText:
                            'Dán Link YouTube (https://youtu.be/...) hoặc ID...',
                        hintStyle: TextStyle(
                          color: textColor.withValues(alpha: 0.5),
                          fontSize: isMobile ? 13 : 15,
                        ),
                        filled: true,
                        fillColor: isDark
                            ? AppColors.darkSurface2
                            : Colors.grey.shade200,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        prefixIcon: Icon(
                          Icons.link_rounded,
                          color: Theme.of(context).primaryColor,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 20),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                              )
                            : null,
                      ),
                      onChanged: (_) => setState(() {}),
                      onSubmitted: _playVideo,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      _showVideo ? Icons.videocam : Icons.videocam_off,
                      color: textColor,
                    ),
                    tooltip: _showVideo
                        ? 'Ẩn Video (Chỉ nghe nhạc)'
                        : 'Hiện Video',
                    onPressed: () => setState(() => _showVideo = !_showVideo),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _playVideo(_searchController.text),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 16 : 24,
                        vertical: 14,
                      ),
                    ),
                    child: const Text('Phát'),
                  ),
                ],
              ),
            ),

            // Main Content Area (Responsive)
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 16 : 40,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // YouTube Player Container
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkPlayerBar
                            : AppColors.lightSurface3,
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
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        // Player luôn mounted → đổi chế độ hiện/ẩn video chỉ che
                        // hình bằng overlay, KHÔNG reload player (audio không bị ngắt)
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            _isDesktopPlatform
                                ? _buildDesktopWebView()
                                : YoutubePlayer(
                                    controller: _controller,
                                    backgroundColor: Colors.black,
                                  ),
                            // Chế độ "chỉ nghe nhạc": che video, audio vẫn chạy
                            if (!_showVideo &&
                                !(_isDesktopPlatform &&
                                    _desktopVideoId == null))
                              IgnorePointer(
                                child: ColoredBox(
                                  color: Colors.black,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.music_note_rounded,
                                        size: 64,
                                        color: textColor.withValues(alpha: 0.3),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Đang phát âm thanh',
                                        style: TextStyle(
                                          color: textColor.withValues(
                                            alpha: 0.6,
                                          ),
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                        ),
                                        child: Text(
                                          _currentTitle,
                                          style: TextStyle(
                                            color: textColor,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Preset YouTube Sample Music Section
                    Text(
                      'Gợi ý nhạc Online hot',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: isMobile ? 2 : 4,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        // Keep tiles tall enough for tag + 2 title lines;
                        // 2.2 was too short → content overflowed on desktop.
                        childAspectRatio: isMobile ? 1.6 : 1.5,
                      ),
                      itemCount: _sampleSongs.length,
                      itemBuilder: (final context, final index) {
                        final item = _sampleSongs[index];
                        return InkWell(
                          onTap: () {
                            _searchController.text =
                                'https://youtu.be/${item['id']}';
                            _playVideo(item['id']!);
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkSurface2
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Theme.of(
                                  context,
                                ).primaryColor.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).primaryColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    item['tag']!,
                                    style: TextStyle(
                                      color: Theme.of(context).primaryColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  item['title']!,
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
