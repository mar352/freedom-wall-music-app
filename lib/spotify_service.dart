import 'dart:convert';
import 'package:http/http.dart' as http;

class SpotifyTrack {
  final String id;
  final String name;
  final String artist;
  final String album;
  final String albumImage;
  final String previewUrl;
  final String spotifyUrl;

  SpotifyTrack({
    required this.id,
    required this.name,
    required this.artist,
    required this.album,
    required this.albumImage,
    required this.previewUrl,
    required this.spotifyUrl,
  });

  factory SpotifyTrack.fromJson(Map<String, dynamic> json) {
    final List<dynamic> artists = json['artists'] ?? [];
    final String artistName = artists.isNotEmpty
        ? artists[0]['name'] ?? 'Unknown Artist'
        : 'Unknown Artist';

    final List<dynamic> images = json['album']?['images'] ?? [];
    final String albumImageUrl = images.isNotEmpty
        ? images[0]['url'] ?? ''
        : '';

    return SpotifyTrack(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unknown Track',
      artist: artistName,
      album: json['album']?['name'] ?? 'Unknown Album',
      albumImage: albumImageUrl,
      previewUrl: json['preview_url'] ?? '',
      spotifyUrl: json['external_urls']?['spotify'] ?? '',
    );
  }
}

class SpotifyService {
  // Your real Spotify API credentials
  static const String _clientId = 'b258225bf6d249658b58550893f2e95f';
  static const String _clientSecret = '9aeb49938ece4978911271f8af2b4fb5';
  static const String _baseUrl = 'https://api.spotify.com/v1';

  String? _accessToken;
  DateTime? _tokenExpiry;

  Future<String?> _getAccessToken() async {
    if (_accessToken != null &&
        _tokenExpiry != null &&
        DateTime.now().isBefore(_tokenExpiry!)) {
      return _accessToken;
    }

    try {
      final response = await http.post(
        Uri.parse('https://accounts.spotify.com/api/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'client_credentials',
          'client_id': _clientId,
          'client_secret': _clientSecret,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _accessToken = data['access_token'];
        final expiresIn = data['expires_in'] as int;
        _tokenExpiry = DateTime.now().add(
          Duration(seconds: expiresIn - 60),
        ); // Buffer of 1 minute
        return _accessToken;
      }
    } catch (e) {
      print('Error getting Spotify access token: $e');
    }
    return null;
  }

  Future<List<SpotifyTrack>> searchTracks(String query) async {
    if (query.trim().isEmpty) return [];

    // Try real Spotify API first
    final token = await _getAccessToken();
    if (token != null) {
      try {
        final response = await http.get(
          Uri.parse(
            '$_baseUrl/search?q=${Uri.encodeComponent(query)}&type=track&limit=10',
          ),
          headers: {'Authorization': 'Bearer $token'},
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final List<dynamic> tracks = data['tracks']?['items'] ?? [];
          if (tracks.isNotEmpty) {
            return tracks.map((track) => SpotifyTrack.fromJson(track)).toList();
          }
        } else {
          print('Spotify API error: ${response.statusCode} - ${response.body}');
        }
      } catch (e) {
        print('Error searching Spotify tracks: $e');
      }
    } else {
      print('Spotify API not configured, using sample search');
    }

    // Fallback to sample search if API fails or not configured
    return searchSampleTracks(query);
  }

  // For demo purposes, return some sample tracks if Spotify API is not configured
  List<SpotifyTrack> getSampleTracks() {
    return [
      SpotifyTrack(
        id: 'sample1',
        name: 'Bohemian Rhapsody',
        artist: 'Queen',
        album: 'A Night at the Opera',
        albumImage:
            'https://via.placeholder.com/300x300/1DB954/FFFFFF?text=Queen',
        previewUrl: '',
        spotifyUrl: 'https://open.spotify.com/track/3z8h0TU7ReDPLIbEnYhWZb',
      ),
      SpotifyTrack(
        id: 'sample2',
        name: 'Imagine',
        artist: 'John Lennon',
        album: 'Imagine',
        albumImage:
            'https://via.placeholder.com/300x300/1DB954/FFFFFF?text=John+Lennon',
        previewUrl: '',
        spotifyUrl: 'https://open.spotify.com/track/7pKfPomDEeI4TPT6EOYjn9',
      ),
      SpotifyTrack(
        id: 'sample3',
        name: 'Hotel California',
        artist: 'Eagles',
        album: 'Hotel California',
        albumImage:
            'https://via.placeholder.com/300x300/1DB954/FFFFFF?text=Eagles',
        previewUrl: '',
        spotifyUrl: 'https://open.spotify.com/track/40riOy7x9W7udXy6SA5vG5',
      ),
      SpotifyTrack(
        id: 'sample4',
        name: 'Shape of You',
        artist: 'Ed Sheeran',
        album: '÷ (Divide)',
        albumImage:
            'https://via.placeholder.com/300x300/1DB954/FFFFFF?text=Ed+Sheeran',
        previewUrl: '',
        spotifyUrl: 'https://open.spotify.com/track/7qiZfU4dY1lWnlzVn6nQ0B',
      ),
      SpotifyTrack(
        id: 'sample5',
        name: 'Blinding Lights',
        artist: 'The Weeknd',
        album: 'After Hours',
        albumImage:
            'https://via.placeholder.com/300x300/1DB954/FFFFFF?text=The+Weeknd',
        previewUrl: '',
        spotifyUrl: 'https://open.spotify.com/track/0VjIjW4GlUZAMYd2vXMi3b',
      ),
      SpotifyTrack(
        id: 'sample6',
        name: 'Dance Monkey',
        artist: 'Tones and I',
        album: 'The Kids Are Coming',
        albumImage:
            'https://via.placeholder.com/300x300/1DB954/FFFFFF?text=Tones+and+I',
        previewUrl: '',
        spotifyUrl: 'https://open.spotify.com/track/2XU0oxnq2qxCpomAAuJY8K',
      ),
      SpotifyTrack(
        id: 'sample7',
        name: 'Bad Guy',
        artist: 'Billie Eilish',
        album: 'When We All Fall Asleep, Where Do We Go?',
        albumImage:
            'https://via.placeholder.com/300x300/1DB954/FFFFFF?text=Billie+Eilish',
        previewUrl: '',
        spotifyUrl: 'https://open.spotify.com/track/2Fxmhks0bxgB3dKZG4wA0P',
      ),
      SpotifyTrack(
        id: 'sample8',
        name: 'Uptown Funk',
        artist: 'Mark Ronson ft. Bruno Mars',
        album: 'Uptown Special',
        albumImage:
            'https://via.placeholder.com/300x300/1DB954/FFFFFF?text=Mark+Ronson',
        previewUrl: '',
        spotifyUrl: 'https://open.spotify.com/track/32OlwWuMpZ6b0aN2R45e45',
      ),
    ];
  }

  // Simulate search functionality with sample tracks
  List<SpotifyTrack> searchSampleTracks(String query) {
    if (query.trim().isEmpty) return getSampleTracks();

    final String lowerQuery = query.toLowerCase();
    final List<SpotifyTrack> allTracks = getSampleTracks();

    return allTracks.where((track) {
      return track.name.toLowerCase().contains(lowerQuery) ||
          track.artist.toLowerCase().contains(lowerQuery) ||
          track.album.toLowerCase().contains(lowerQuery);
    }).toList();
  }
}
