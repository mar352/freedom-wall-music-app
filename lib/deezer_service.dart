import 'dart:convert';
import 'package:http/http.dart' as http;

class DeezerTrack {
  final String id;
  final String title;
  final String artist;
  final String album;
  final String albumImage;
  final String previewUrl;
  final String deezerUrl;
  final int duration;

  DeezerTrack({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.albumImage,
    required this.previewUrl,
    required this.deezerUrl,
    required this.duration,
  });

  factory DeezerTrack.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> artist = json['artist'] ?? {};
    final Map<String, dynamic> album = json['album'] ?? {};
    final String albumImageUrl =
        album['cover_medium'] ?? album['cover_small'] ?? '';

    return DeezerTrack(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? 'Unknown Track',
      artist: artist['name'] ?? 'Unknown Artist',
      album: album['title'] ?? 'Unknown Album',
      albumImage: albumImageUrl,
      previewUrl: json['preview'] ?? '',
      deezerUrl: json['link'] ?? '',
      duration: json['duration'] ?? 0,
    );
  }
}

class DeezerService {
  static const String _baseUrl = 'https://api.deezer.com';

  Future<List<DeezerTrack>> searchTracks(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/search/track?q=${Uri.encodeComponent(query)}&limit=10',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> tracks = data['data'] ?? [];

        if (tracks.isNotEmpty) {
          return tracks.map((track) => DeezerTrack.fromJson(track)).toList();
        }
      } else {
        print('Deezer API error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error searching Deezer tracks: $e');
    }

    // Fallback to sample tracks if API fails
    return searchSampleTracks(query);
  }

  // For demo purposes, return some sample tracks if Deezer API is not available
  List<DeezerTrack> getSampleTracks() {
    return [
      DeezerTrack(
        id: 'sample1',
        title: 'Bohemian Rhapsody',
        artist: 'Queen',
        album: 'A Night at the Opera',
        albumImage:
            'https://via.placeholder.com/300x300/00C7B7/FFFFFF?text=Queen',
        previewUrl:
            'https://cdns-preview-9.dzcdn.net/stream/c-9b8b8b8b8b8b8b8b8b8b8b8b8b8b8b8b-1.mp3',
        deezerUrl: 'https://www.deezer.com/track/3135556',
        duration: 355,
      ),
      DeezerTrack(
        id: 'sample2',
        title: 'Imagine',
        artist: 'John Lennon',
        album: 'Imagine',
        albumImage:
            'https://via.placeholder.com/300x300/00C7B7/FFFFFF?text=John+Lennon',
        previewUrl:
            'https://cdns-preview-8.dzcdn.net/stream/c-8a8a8a8a8a8a8a8a8a8a8a8a8a8a8a8a-1.mp3',
        deezerUrl: 'https://www.deezer.com/track/3135557',
        duration: 183,
      ),
      DeezerTrack(
        id: 'sample3',
        title: 'Hotel California',
        artist: 'Eagles',
        album: 'Hotel California',
        albumImage:
            'https://via.placeholder.com/300x300/00C7B7/FFFFFF?text=Eagles',
        previewUrl:
            'https://cdns-preview-7.dzcdn.net/stream/c-7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a7a-1.mp3',
        deezerUrl: 'https://www.deezer.com/track/3135558',
        duration: 391,
      ),
      DeezerTrack(
        id: 'sample4',
        title: 'Shape of You',
        artist: 'Ed Sheeran',
        album: '÷ (Divide)',
        albumImage:
            'https://via.placeholder.com/300x300/00C7B7/FFFFFF?text=Ed+Sheeran',
        previewUrl:
            'https://cdns-preview-6.dzcdn.net/stream/c-6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a-1.mp3',
        deezerUrl: 'https://www.deezer.com/track/3135559',
        duration: 233,
      ),
      DeezerTrack(
        id: 'sample5',
        title: 'Blinding Lights',
        artist: 'The Weeknd',
        album: 'After Hours',
        albumImage:
            'https://via.placeholder.com/300x300/00C7B7/FFFFFF?text=The+Weeknd',
        previewUrl:
            'https://cdns-preview-5.dzcdn.net/stream/c-5a5a5a5a5a5a5a5a5a5a5a5a5a5a5a5a-1.mp3',
        deezerUrl: 'https://www.deezer.com/track/3135560',
        duration: 200,
      ),
      DeezerTrack(
        id: 'sample6',
        title: 'Dance Monkey',
        artist: 'Tones and I',
        album: 'The Kids Are Coming',
        albumImage:
            'https://via.placeholder.com/300x300/00C7B7/FFFFFF?text=Tones+and+I',
        previewUrl:
            'https://cdns-preview-4.dzcdn.net/stream/c-4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a-1.mp3',
        deezerUrl: 'https://www.deezer.com/track/3135561',
        duration: 210,
      ),
      DeezerTrack(
        id: 'sample7',
        title: 'Bad Guy',
        artist: 'Billie Eilish',
        album: 'When We All Fall Asleep, Where Do We Go?',
        albumImage:
            'https://via.placeholder.com/300x300/00C7B7/FFFFFF?text=Billie+Eilish',
        previewUrl:
            'https://cdns-preview-3.dzcdn.net/stream/c-3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a-1.mp3',
        deezerUrl: 'https://www.deezer.com/track/3135562',
        duration: 194,
      ),
      DeezerTrack(
        id: 'sample8',
        title: 'Uptown Funk',
        artist: 'Mark Ronson ft. Bruno Mars',
        album: 'Uptown Special',
        albumImage:
            'https://via.placeholder.com/300x300/00C7B7/FFFFFF?text=Mark+Ronson',
        previewUrl:
            'https://cdns-preview-2.dzcdn.net/stream/c-2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a-1.mp3',
        deezerUrl: 'https://www.deezer.com/track/3135563',
        duration: 269,
      ),
    ];
  }

  // Simulate search functionality with sample tracks
  List<DeezerTrack> searchSampleTracks(String query) {
    if (query.trim().isEmpty) return getSampleTracks();

    final String lowerQuery = query.toLowerCase();
    final List<DeezerTrack> allTracks = getSampleTracks();

    return allTracks.where((track) {
      return track.title.toLowerCase().contains(lowerQuery) ||
          track.artist.toLowerCase().contains(lowerQuery) ||
          track.album.toLowerCase().contains(lowerQuery);
    }).toList();
  }
}
