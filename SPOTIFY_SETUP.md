# Spotify API Integration Setup

This app now includes Spotify integration that allows users to search for and select songs while posting their rants. Here's how to set it up:

## Prerequisites

1. A Spotify account
2. Access to the Spotify Developer Dashboard

## Setup Steps

### 1. Create a Spotify App

1. Go to [Spotify Developer Dashboard](https://developer.spotify.com/dashboard)
2. Log in with your Spotify account
3. Click "Create App"
4. Fill in the app details:
   - App name: "Freedom Wall" (or your preferred name)
   - App description: "A social media app for anonymous posts with music sharing"
   - Website: Your app's website (optional)
   - Redirect URI: Leave blank for now
   - API/SDKs: Select "Web API"
5. Accept the terms and click "Save"

### 2. Get Your Credentials

1. In your app dashboard, you'll see your **Client ID** and **Client Secret**
2. Copy these values - you'll need them for the next step

### 3. Configure the App

1. Open `lib/spotify_service.dart`
2. Replace the placeholder values:
   ```dart
   static const String _clientId = 'YOUR_SPOTIFY_CLIENT_ID';
   static const String _clientSecret = 'YOUR_SPOTIFY_CLIENT_SECRET';
   ```
3. Replace with your actual credentials from step 2

### 4. Install Dependencies

Run the following command to install the required packages:
```bash
flutter pub get
```

## How It Works

### For Users
1. When creating a new post, users can click "Add Music (Optional)"
2. They can search for songs using the search bar
3. Results show album art, song title, and artist
4. Clicking a song selects it for the post
5. The selected song appears with album art and can be changed
6. When posted, the song information is displayed with a play button

### Features
- **Real-time search**: Search Spotify's catalog as you type
- **Album art**: Beautiful visual representation of selected songs
- **Rich metadata**: Song title, artist, and album information
- **Spotify integration**: Direct links to songs on Spotify
- **Fallback support**: Sample tracks when API is not configured

## Troubleshooting

### Common Issues

1. **"Failed to get Spotify access token"**
   - Check your Client ID and Client Secret are correct
   - Ensure your Spotify app is properly configured

2. **No search results**
   - Verify your internet connection
   - Check the Spotify API status at [status.spotify.com](https://status.spotify.com)

3. **Sample tracks only**
   - This means the Spotify API is not configured
   - Follow the setup steps above

### API Limits

- Spotify API has rate limits for free accounts
- For production use, consider upgrading to a paid plan
- Current implementation includes error handling and fallbacks

## Security Notes

- Never commit your Client Secret to version control
- Consider using environment variables for production
- The current implementation uses client credentials flow (server-to-server)

## Future Enhancements

- User authentication for personalized recommendations
- Playlist integration
- Audio preview playback
- Recently played tracks
- Collaborative playlists

## Support

If you encounter issues:
1. Check the console logs for error messages
2. Verify your Spotify app configuration
3. Ensure all dependencies are properly installed
4. Check your internet connection

The app will gracefully fall back to sample tracks if the Spotify API is unavailable, ensuring users can still enjoy the music sharing feature even during setup or API issues.
