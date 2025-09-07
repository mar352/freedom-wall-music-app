import 'package:flutter/material.dart';
import 'dart:io';
import 'main.dart';
import 'music_player_widget.dart';
import 'deezer_service.dart';

class PostCard extends StatefulWidget {
  final Post post;
  final VoidCallback onLike;
  final void Function(String emoji)? onReact;
  final VoidCallback? onComment;
  final String? currentUserId;

  const PostCard({
    super.key,
    required this.post,
    required this.onLike,
    this.onReact,
    this.onComment,
    this.currentUserId,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  String? _previewUrl;
  bool _isLoadingPreview = false;

  bool _isLikedByCurrentUser() {
    if (widget.currentUserId == null) return false;
    return widget.post.likedBy.contains(widget.currentUserId);
  }

  @override
  Widget build(BuildContext context) {
    final String time = _formatRealTime(widget.post.createdAt);
    final bool hasLikes = widget.post.likes > 0;
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Card(
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: <Color>[Colors.indigo, Colors.blue],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const CircleAvatar(
                    backgroundColor: Colors.transparent,
                    child: Icon(Icons.person_outline, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  widget.post.isAnonymous
                      ? 'Anonymous'
                      : (widget.post.authorName ?? 'User'),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.onPrimaryContainer.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        time,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: scheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatFullDate(widget.post.createdAt),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: scheme.onPrimaryContainer.withOpacity(0.7),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              widget.post.text,
              style: TextStyle(
                fontSize: 16,
                height: 1.35,
                color: scheme.onPrimaryContainer,
              ),
            ),
            if (widget.post.attachmentPath != null) ...<Widget>[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: double.infinity,
                  height: 200,
                  child: _buildImageFromFile(widget.post.attachmentPath!),
                ),
              ),
            ],
            if (widget.post.musicTitle != null ||
                widget.post.musicArtist != null) ...<Widget>[
              const SizedBox(height: 8),
              _buildMusicPlayer(),
            ],
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                GestureDetector(
                  onTap: widget.onLike,
                  onLongPressStart: (details) async {
                    if (widget.onReact == null) return;
                    final RenderBox box =
                        context.findRenderObject() as RenderBox;
                    final Offset pos = box.localToGlobal(Offset.zero);
                    final RelativeRect position = RelativeRect.fromLTRB(
                      details.globalPosition.dx,
                      details.globalPosition.dy,
                      pos.dx + box.size.width - details.globalPosition.dx,
                      pos.dy + box.size.height - details.globalPosition.dy,
                    );
                    final String? choice = await showMenu<String>(
                      context: context,
                      position: position,
                      items: <PopupMenuEntry<String>>[
                        const PopupMenuItem<String>(
                          value: '❤️',
                          child: Text('❤️'),
                        ),
                        const PopupMenuItem<String>(
                          value: '👍',
                          child: Text('👍'),
                        ),
                        const PopupMenuItem<String>(
                          value: '😂',
                          child: Text('😂'),
                        ),
                        const PopupMenuItem<String>(
                          value: '😮',
                          child: Text('😮'),
                        ),
                        const PopupMenuItem<String>(
                          value: '😢',
                          child: Text('😢'),
                        ),
                      ],
                    );
                    if (choice != null) widget.onReact!(choice);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: hasLikes
                          ? Colors.white.withOpacity(0.22)
                          : Colors.white.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      children: <Widget>[
                        if (widget.post.mainReaction == null) ...[
                          Icon(
                            _isLikedByCurrentUser()
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: _isLikedByCurrentUser()
                                ? Colors.red
                                : Colors.white,
                            size: 20,
                          ),
                        ] else
                          Text(
                            widget.post.mainReaction!,
                            style: const TextStyle(fontSize: 18),
                          ),
                        const SizedBox(width: 6),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          transitionBuilder:
                              (Widget child, Animation<double> anim) =>
                                  ScaleTransition(scale: anim, child: child),
                          child: Text(
                            widget.post.likes.toString(),
                            key: ValueKey<int>(widget.post.likes),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (widget.onComment != null)
                  TextButton.icon(
                    onPressed: widget.onComment,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      backgroundColor: Colors.white.withOpacity(0.14),
                      shape: const StadiumBorder(),
                    ),
                    icon: const Icon(
                      Icons.mode_comment_outlined,
                      size: 18,
                      color: Colors.black,
                    ),
                    label: Text(
                      '${widget.post.comments.length}',
                      style: const TextStyle(color: Colors.black),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageFromFile(String imagePath) {
    try {
      if (imagePath.startsWith('http')) {
        // Network image
        return Image.network(
          imagePath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildImageError();
          },
        );
      } else if (imagePath.startsWith('assets/')) {
        // Asset image
        return Image.asset(
          imagePath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildImageError();
          },
        );
      } else {
        // Local file image
        return Image.file(
          File(imagePath),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildImageError();
          },
        );
      }
    } catch (e) {
      return _buildImageError();
    }
  }

  Widget _buildImageError() {
    return Container(
      color: Colors.grey[300],
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text('Image not found', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Future<void> _fetchPreviewUrl() async {
    if (_previewUrl != null || _isLoadingPreview) return;

    setState(() {
      _isLoadingPreview = true;
    });

    try {
      final deezerService = DeezerService();
      final searchQuery =
          '${widget.post.musicTitle} ${widget.post.musicArtist}';
      final tracks = await deezerService.searchTracks(searchQuery);

      if (tracks.isNotEmpty) {
        setState(() {
          _previewUrl = tracks.first.previewUrl;
          _isLoadingPreview = false;
        });
      } else {
        setState(() {
          _isLoadingPreview = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingPreview = false;
      });
    }
  }

  Widget _buildMusicPlayer() {
    // Fetch preview URL if not already fetched
    if (_previewUrl == null && !_isLoadingPreview) {
      _fetchPreviewUrl();
    }

    // Create a DeezerTrack from the post data
    final track = DeezerTrack(
      id: widget.post.deezerTrackId ?? 'unknown',
      title: widget.post.musicTitle ?? 'Unknown Track',
      artist: widget.post.musicArtist ?? 'Unknown Artist',
      album: 'Unknown Album',
      albumImage: widget.post.albumImage ?? '',
      previewUrl: _previewUrl ?? '',
      deezerUrl: widget.post.deezerTrackUrl ?? '',
      duration: 0,
    );

    return MusicPlayerWidget(track: track, isCompact: true);
  }
}

String _formatRealTime(DateTime time) {
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String _formatFullDate(DateTime time) {
  final months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  final day = time.day.toString().padLeft(2, '0');
  final month = months[time.month - 1];
  final year = time.year;

  return '$day $month $year, $hour:$minute';
}
