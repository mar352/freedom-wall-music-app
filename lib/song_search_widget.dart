import 'package:flutter/material.dart';
import 'deezer_service.dart';

class SongSearchWidget extends StatefulWidget {
  final Function(DeezerTrack?) onSongSelected;
  final DeezerTrack? selectedTrack;

  const SongSearchWidget({
    super.key,
    required this.onSongSelected,
    this.selectedTrack,
  });

  @override
  State<SongSearchWidget> createState() => _SongSearchWidgetState();
}

class _SongSearchWidgetState extends State<SongSearchWidget> {
  final TextEditingController _searchController = TextEditingController();
  final DeezerService _deezerService = DeezerService();
  List<DeezerTrack> _searchResults = [];
  bool _isLoading = false;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    // Show sample tracks initially
    _searchResults = _deezerService.getSampleTracks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchSongs(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = _deezerService.getSampleTracks();
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _isSearching = true;
    });

    try {
      final results = await _deezerService.searchTracks(query);
      setState(() {
        _searchResults = results.isNotEmpty
            ? results
            : _deezerService.getSampleTracks();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _searchResults = _deezerService.getSampleTracks();
        _isLoading = false;
      });
    }
  }

  void _selectSong(DeezerTrack track) {
    widget.onSongSelected(track);
    // Don't close the search - let user continue with post creation
  }

  void _clearSelection() {
    widget.onSongSelected(null);
    // Don't close the screen - let user continue
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search for a song...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : null,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    _searchSongs(value);
                  } else {
                    setState(() {
                      _searchResults = _deezerService.getSampleTracks();
                      _isSearching = false;
                    });
                  }
                },
              ),
            ),
            if (widget.selectedTrack != null) ...[
              const SizedBox(width: 8),
              IconButton(
                onPressed: _clearSelection,
                icon: const Icon(Icons.clear),
                tooltip: 'Clear selection',
              ),
            ],
          ],
        ),
        if (widget.selectedTrack != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.network(
                    widget.selectedTrack!.albumImage,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 48,
                        height: 48,
                        color: Colors.grey[300],
                        child: const Icon(Icons.music_note, color: Colors.grey),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.selectedTrack!.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        widget.selectedTrack!.artist,
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _selectSong(widget.selectedTrack!),
                  icon: const Icon(Icons.edit, color: Colors.green),
                  tooltip: 'Change selection',
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  child: const Text('Done'),
                ),
              ],
            ),
          ),
        ] else ...[
          const SizedBox(height: 12),
          Text(
            _isSearching ? 'Search results:' : 'Popular songs:',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 200,
                  child: ListView.builder(
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final track = _searchResults[index];
                      return ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.network(
                            track.albumImage,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 48,
                                height: 48,
                                color: Colors.grey[300],
                                child: const Icon(
                                  Icons.music_note,
                                  color: Colors.grey,
                                ),
                              );
                            },
                          ),
                        ),
                        title: Text(
                          track.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          track.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const Icon(Icons.add_circle_outline),
                        onTap: () => _selectSong(track),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                child: const Text('Done'),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
