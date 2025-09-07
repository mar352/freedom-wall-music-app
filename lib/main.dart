import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';

import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:audioplayers/audioplayers.dart';

import 'firebase_options.dart';
import 'deezer_service.dart';
import 'song_search_widget.dart';
import 'auth_service.dart';
import 'login_page.dart';
import 'profile_page.dart';
import 'post_card.dart';
import 'search_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase for cross-device sync
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');
  } catch (e) {
    print('Firebase initialization failed: $e');
    print('App will use local storage only');
  }

  // Hide status and nav bars; reveal with swipe
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const FreedomWallApp());
}

class FreedomWallApp extends StatelessWidget {
  const FreedomWallApp({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = ColorScheme.fromSeed(seedColor: Colors.indigo);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Freedom Wall',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: const Color(0xFFF7F8FA),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: scheme.onSurface,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          centerTitle: true,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: EdgeInsets.zero,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: scheme.primaryContainer,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>((states) {
            final bool selected = states.contains(WidgetState.selected);
            return TextStyle(
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            );
          }),
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          return const FreedomWallPage();
        } else {
          return const LoginPage();
        }
      },
    );
  }
}

void _showCommentsSheet(
  BuildContext context,
  Post post,
  Future<void> Function(Post, String) addComment,
) {
  final TextEditingController c = TextEditingController();
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).cardColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (BuildContext ctx) {
      return Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          top: 12,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Text(
                  'Comments',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Text('${post.comments.length}'),
              ],
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView.separated(
                shrinkWrap: true,
                itemBuilder: (_, int i) {
                  final PostComment cm = post.comments[i];
                  return ListTile(
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      child: Icon(Icons.person_outline),
                    ),
                    title: Text(cm.text),
                    subtitle: Text(_formatTimeAgo(cm.createdAt)),
                  );
                },
                separatorBuilder: (_, __) => const Divider(height: 12),
                itemCount: post.comments.length,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: c,
                    minLines: 1,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Write a comment...',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () async {
                    final String t = c.text.trim();
                    if (t.isEmpty) return;
                    Navigator.of(ctx).pop();
                    await addComment(post, t);
                  },
                  icon: const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}

class Post {
  final String id;
  final String text;
  final DateTime createdAt;
  final int likes;
  final Map<String, int> reactions; // emoji -> count
  final List<PostComment> comments;
  final String? mainReaction; // emoji displayed on chip
  final String? attachmentPath; // local image path
  final String? musicTitle;
  final String? musicArtist;
  final String? deezerTrackId;
  final String? deezerTrackUrl;
  final String? albumImage;
  final String? userId; // Track who created the post
  final bool isAnonymous; // Track if post is anonymous
  final String? authorName; // Display name of the author
  final List<String> likedBy; // List of user IDs who liked this post

  const Post({
    required this.id,
    required this.text,
    required this.createdAt,
    required this.likes,
    this.reactions = const <String, int>{},
    this.comments = const <PostComment>[],
    this.mainReaction,
    this.attachmentPath,
    this.musicTitle,
    this.musicArtist,
    this.deezerTrackId,
    this.deezerTrackUrl,
    this.albumImage,
    this.userId,
    this.isAnonymous = true,
    this.authorName,
    this.likedBy = const <String>[],
  });

  Post copyWith({
    String? text,
    int? likes,
    Map<String, int>? reactions,
    List<PostComment>? comments,
    String? mainReaction,
    String? attachmentPath,
    String? musicTitle,
    String? musicArtist,
    String? deezerTrackId,
    String? deezerTrackUrl,
    String? albumImage,
    String? userId,
    bool? isAnonymous,
    String? authorName,
    List<String>? likedBy,
  }) {
    return Post(
      id: id,
      text: text ?? this.text,
      createdAt: createdAt,
      likes: likes ?? this.likes,
      reactions: reactions ?? this.reactions,
      comments: comments ?? this.comments,
      mainReaction: mainReaction ?? this.mainReaction,
      attachmentPath: attachmentPath ?? this.attachmentPath,
      musicTitle: musicTitle ?? this.musicTitle,
      musicArtist: musicArtist ?? this.musicArtist,
      deezerTrackId: deezerTrackId ?? this.deezerTrackId,
      deezerTrackUrl: deezerTrackUrl ?? this.deezerTrackUrl,
      albumImage: albumImage ?? this.albumImage,
      userId: userId ?? this.userId,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      authorName: authorName ?? this.authorName,
      likedBy: likedBy ?? this.likedBy,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'createdAt': createdAt.toIso8601String(),
    'likes': likes,
    'reactions': reactions,
    'comments': comments.map((c) => c.toJson()).toList(),
    'mainReaction': mainReaction,
    'attachmentPath': attachmentPath,
    'musicTitle': musicTitle,
    'musicArtist': musicArtist,
    'deezerTrackId': deezerTrackId,
    'deezerTrackUrl': deezerTrackUrl,
    'albumImage': albumImage,
    'userId': userId,
    'isAnonymous': isAnonymous,
    'authorName': authorName,
    'likedBy': likedBy,
  };

  static Post fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] as String,
      text: json['text'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      likes: (json['likes'] ?? 0) as int,
      reactions:
          (json['reactions'] as Map?)?.cast<String, int>() ?? <String, int>{},
      comments: List<Map<String, dynamic>>.from(
        (json['comments'] as List?) ?? const <dynamic>[],
      ).map((Map<String, dynamic> e) => PostComment.fromJson(e)).toList(),
      mainReaction: json['mainReaction'] as String?,
      attachmentPath: json['attachmentPath'] as String?,
      musicTitle: json['musicTitle'] as String?,
      musicArtist: json['musicArtist'] as String?,
      deezerTrackId: json['deezerTrackId'] as String?,
      deezerTrackUrl: json['deezerTrackUrl'] as String?,
      albumImage: json['albumImage'] as String?,
      userId: json['userId'] as String?,
      isAnonymous: json['isAnonymous'] as bool? ?? true,
      authorName: json['authorName'] as String?,
      likedBy: List<String>.from(json['likedBy'] as List? ?? []),
    );
  }
}

class PostComment {
  final String id;
  final String text;
  final DateTime createdAt;

  const PostComment({
    required this.id,
    required this.text,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'createdAt': createdAt.toIso8601String(),
  };

  static PostComment fromJson(Map<String, dynamic> json) => PostComment(
    id: json['id'] as String,
    text: json['text'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}

class PostStorageService {
  static const String _storageKey = 'freedom_wall_posts_v1';
  static const String _collectionName = 'anonymous_posts';
  static const String _userPostsCollection = 'user_posts';

  // Real-time stream for posts (combines both anonymous and user posts)
  Stream<List<Post>> get postsStream {
    try {
      if (Firebase.apps.isNotEmpty) {
        // Create a controller to combine both streams
        final StreamController<List<Post>> controller =
            StreamController<List<Post>>();
        List<Post> anonymousPosts = [];
        List<Post> userPosts = [];

        // Listen to anonymous posts
        FirebaseFirestore.instance
            .collection(_collectionName)
            .orderBy('createdAt', descending: true)
            .snapshots()
            .listen((snapshot) {
              anonymousPosts = snapshot.docs.map((doc) {
                final data = doc.data();
                return Post.fromJson({...data, 'id': doc.id});
              }).toList();

              // Combine and emit
              _emitCombinedPosts(controller, anonymousPosts, userPosts);
            });

        // Listen to user posts
        FirebaseFirestore.instance
            .collection(_userPostsCollection)
            .orderBy('createdAt', descending: true)
            .snapshots()
            .listen((snapshot) {
              userPosts = snapshot.docs.map((doc) {
                final data = doc.data();
                return Post.fromJson({...data, 'id': doc.id});
              }).toList();

              // Combine and emit
              _emitCombinedPosts(controller, anonymousPosts, userPosts);
            });

        return controller.stream;
      }
    } catch (e) {
      print('Firestore stream failed: $e, falling back to local storage');
    }

    // Fallback to local storage stream
    return Stream.value(<Post>[]);
  }

  void _emitCombinedPosts(
    StreamController<List<Post>> controller,
    List<Post> anonymousPosts,
    List<Post> userPosts,
  ) {
    final List<Post> allPosts = [...anonymousPosts, ...userPosts];
    allPosts.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    print(
      'Real-time update: ${allPosts.length} posts from Firestore (${anonymousPosts.length} anonymous + ${userPosts.length} user posts)',
    );

    controller.add(allPosts);
  }

  Future<List<Post>> loadPosts() async {
    try {
      // Try Firestore first for cross-device sync
      if (Firebase.apps.isNotEmpty) {
        // Load from both collections
        final QuerySnapshot anonymousSnapshot = await FirebaseFirestore.instance
            .collection(_collectionName)
            .orderBy('createdAt', descending: true)
            .get();

        final QuerySnapshot userSnapshot = await FirebaseFirestore.instance
            .collection(_userPostsCollection)
            .orderBy('createdAt', descending: true)
            .get();

        final List<Post> allPosts = [];

        // Add anonymous posts
        allPosts.addAll(
          anonymousSnapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Post.fromJson({...data, 'id': doc.id});
          }),
        );

        // Add user posts
        allPosts.addAll(
          userSnapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Post.fromJson({...data, 'id': doc.id});
          }),
        );

        // Sort all posts by creation date (newest first)
        allPosts.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        print(
          'Loaded ${allPosts.length} posts from Firestore (${anonymousSnapshot.docs.length} anonymous + ${userSnapshot.docs.length} user posts)',
        );
        return allPosts;
      }
    } catch (e) {
      print('Firestore load failed: $e, falling back to local storage');
    }

    // Fallback to local storage
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      return <Post>[];
    }
    final List<dynamic> data = jsonDecode(raw) as List<dynamic>;
    return data
        .map((dynamic e) => Post.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> savePosts(List<Post> posts) async {
    try {
      // Try Firestore first for cross-device sync
      if (Firebase.apps.isNotEmpty) {
        final batch = FirebaseFirestore.instance.batch();

        // Clear existing posts and add all current ones
        final QuerySnapshot existing = await FirebaseFirestore.instance
            .collection(_collectionName)
            .get();

        for (final doc in existing.docs) {
          batch.delete(doc.reference);
        }

        for (final post in posts) {
          final docRef = FirebaseFirestore.instance
              .collection(_collectionName)
              .doc(post.id);
          batch.set(docRef, post.toJson());
        }

        await batch.commit();
        print('Saved ${posts.length} posts to Firestore');
        return;
      }
    } catch (e) {
      print('Firestore save failed: $e, falling back to local storage');
    }

    // Fallback to local storage
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String raw = jsonEncode(posts.map((p) => p.toJson()).toList());
    await prefs.setString(_storageKey, raw);
  }

  Future<void> addPostToFirestore(Post post) async {
    try {
      if (Firebase.apps.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection(_collectionName)
            .doc(post.id)
            .set(post.toJson());
        print('Added post to Firestore: ${post.id}');
      }
    } catch (e) {
      print('Failed to add post to Firestore: $e');
    }
  }

  Future<void> addUserPostToFirestore(Post post) async {
    try {
      if (Firebase.apps.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection(_userPostsCollection)
            .doc(post.id)
            .set(post.toJson());
        print('Added user post to Firestore: ${post.id}');
      }
    } catch (e) {
      print('Failed to add user post to Firestore: $e');
    }
  }

  Future<void> updatePostInFirestore(Post post) async {
    try {
      if (Firebase.apps.isNotEmpty) {
        // Determine which collection to update based on post type
        final String collection = post.isAnonymous
            ? _collectionName
            : _userPostsCollection;

        await FirebaseFirestore.instance
            .collection(collection)
            .doc(post.id)
            .update(post.toJson());
        print(
          'Updated post in Firestore: ${post.id} (collection: $collection)',
        );
      }
    } catch (e) {
      print('Failed to update post to Firestore: $e');
    }
  }

  Future<void> deletePostFromFirestore(
    String postId, {
    bool isAnonymous = true,
  }) async {
    try {
      if (Firebase.apps.isNotEmpty) {
        final String collection = isAnonymous
            ? _collectionName
            : _userPostsCollection;
        await FirebaseFirestore.instance
            .collection(collection)
            .doc(postId)
            .delete();
        print('Deleted post from Firestore: $postId (collection: $collection)');
      }
    } catch (e) {
      print('Failed to delete post from Firestore: $e');
    }
  }
}

class FreedomWallPage extends StatefulWidget {
  const FreedomWallPage({super.key});

  @override
  State<FreedomWallPage> createState() => _FreedomWallPageState();
}

class _FreedomWallPageState extends State<FreedomWallPage> {
  final PostStorageService _storage = PostStorageService();
  final AuthService _authService = AuthService();
  final TextEditingController _controller = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();
  final AudioPlayer _notificationPlayer = AudioPlayer();

  List<Post> _posts = <Post>[];
  bool _initializing = true;
  int _currentIndex = 0;
  final String _defaultAssetBg = 'assets/catbg.jpg';
  String? _anonymousUserId;
  StreamSubscription<List<Post>>? _postsSubscription;
  XFile? _pickedImage; // Store selected image at class level
  DeezerTrack? _selectedTrack; // Store selected Deezer track

  @override
  void initState() {
    super.initState();
    _anonymousUserId = 'anonymous_${DateTime.now().millisecondsSinceEpoch}';
    _setupRealTimeListener();
  }

  @override
  void dispose() {
    _postsSubscription?.cancel();
    _notificationPlayer.dispose();
    super.dispose();
  }

  void _setupRealTimeListener() {
    try {
      // Listen to real-time Firestore updates
      _postsSubscription = _storage.postsStream.listen(
        (posts) {
          setState(() {
            _posts = posts;
            _initializing = false;
          });
          print('Real-time update received: ${posts.length} posts');
        },
        onError: (error) {
          print(
            'Real-time stream error: $error, falling back to local storage',
          );
          _loadFromLocalStorage();
        },
      );
    } catch (e) {
      print('Failed to setup real-time listener: $e, using local storage');
      _loadFromLocalStorage();
    }
  }

  Future<void> _loadFromLocalStorage() async {
    final List<Post> loaded = await _storage.loadPosts();
    setState(() {
      _posts = loaded;
      _initializing = false;
    });
  }

  Future<void> _playNotificationSound() async {
    try {
      // Play system notification sound
      await SystemSound.play(SystemSoundType.click);
      // Add haptic feedback
      HapticFeedback.lightImpact();
    } catch (e) {
      print('Could not play notification sound: $e');
    }
  }

  Future<void> _addPost(
    String text, {
    String? attachmentPath,
    String? musicTitle,
    String? musicArtist,
    DeezerTrack? deezerTrack,
  }) async {
    final String trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final user = _authService.currentUser;
    final isAnonymous = _authService.isAnonymous;
    final userDisplayName = _authService.userDisplayName;
    final authorName = isAnonymous ? null : userDisplayName;

    final Post post = Post(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      text: trimmed,
      createdAt: DateTime.now(),
      likes: 0,
      attachmentPath: attachmentPath,
      musicTitle: musicTitle,
      musicArtist: musicArtist,
      deezerTrackId: deezerTrack?.id,
      deezerTrackUrl: deezerTrack?.deezerUrl,
      albumImage: deezerTrack?.albumImage,
      userId: user?.uid,
      isAnonymous: isAnonymous,
      authorName: authorName,
    );

    // Add to appropriate Firestore collection
    if (isAnonymous) {
      await _storage.addPostToFirestore(post);
    } else {
      await _storage.addUserPostToFirestore(post);
    }

    // Local state will update automatically via the real-time stream

    // Play notification sound
    await _playNotificationSound();

    // Show success message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Post created successfully! 🎉'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _likePost(Post post) async {
    const String defaultEmoji = '❤️';
    await _toggleLike(post, defaultEmoji);
  }

  Future<void> _toggleLike(Post post, String emoji) async {
    final int index = _posts.indexWhere((p) => p.id == post.id);
    if (index < 0) return;

    final currentUser = _authService.currentUser;
    final currentUserId =
        currentUser?.uid ??
        _anonymousUserId ??
        'anonymous_${DateTime.now().millisecondsSinceEpoch}';

    final List<String> newLikedBy = List<String>.from(post.likedBy);
    final bool isCurrentlyLiked = newLikedBy.contains(currentUserId);

    if (isCurrentlyLiked) {
      // Unlike: remove user from likedBy list
      newLikedBy.remove(currentUserId);
    } else {
      // Like: add user to likedBy list
      newLikedBy.add(currentUserId);
    }

    final int newLikes = newLikedBy.length;
    final Map<String, int> reactions = Map<String, int>.from(post.reactions);

    if (isCurrentlyLiked) {
      // Remove like reaction
      reactions[emoji] = (reactions[emoji] ?? 1) - 1;
      if (reactions[emoji]! <= 0) {
        reactions.remove(emoji);
      }
    } else {
      // Add like reaction
      reactions[emoji] = (reactions[emoji] ?? 0) + 1;
    }

    final Post updated = post.copyWith(
      likes: newLikes,
      reactions: reactions,
      mainReaction: reactions.isNotEmpty ? reactions.keys.first : null,
      likedBy: newLikedBy,
    );

    // Update in Firestore for real-time sync
    await _storage.updatePostInFirestore(updated);
  }

  Future<void> _reactToPost(Post post, String emoji) async {
    final int index = _posts.indexWhere((p) => p.id == post.id);
    if (index < 0) return;
    final Map<String, int> reactions = Map<String, int>.from(post.reactions);
    reactions[emoji] = (reactions[emoji] ?? 0) + 1;
    final int newLikes = emoji == '❤️' ? post.likes + 1 : post.likes;
    final Post updated = post.copyWith(
      likes: newLikes,
      reactions: reactions,
      mainReaction: emoji,
    );

    // Update in Firestore for real-time sync
    await _storage.updatePostInFirestore(updated);

    // Local state will update automatically via the real-time stream
  }

  Future<void> _addComment(Post post, String text) async {
    final int index = _posts.indexWhere((p) => p.id == post.id);
    if (index < 0) return;
    final PostComment comment = PostComment(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      text: text.trim(),
      createdAt: DateTime.now(),
    );
    final List<PostComment> updated = <PostComment>[...post.comments, comment];
    final Post updatedPost = post.copyWith(comments: updated);

    // Update in Firestore for real-time sync
    await _storage.updatePostInFirestore(updatedPost);

    // Local state will update automatically via the real-time stream
  }

  Future<void> _deletePost(Post post) async {
    // Check if current user owns this post
    final currentUser = _authService.currentUser;
    final currentUserId =
        currentUser?.uid ??
        _anonymousUserId ??
        'anonymous_${DateTime.now().millisecondsSinceEpoch}';

    if (post.userId != currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can only delete your own posts')),
      );
      return;
    }

    // Delete from Firestore for real-time sync
    await _storage.deletePostFromFirestore(
      post.id,
      isAnonymous: post.isAnonymous,
    );

    // Local state will update automatically via the real-time stream
  }

  void _showAddPostSheet() {
    _controller.clear();
    _selectedTrack = null; // Reset selected track
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (BuildContext ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                _authService.isAnonymous ? 'New Anonymous Post' : 'New Post',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _controller,
                focusNode: _inputFocusNode,
                autofocus: true,
                maxLines: 5,
                minLines: 3,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  hintText: 'Share your thoughts... (be kind)',
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  OutlinedButton.icon(
                    onPressed: () async {
                      try {
                        final ImagePicker picker = ImagePicker();
                        final XFile? x = await picker.pickImage(
                          source: ImageSource.gallery,
                          imageQuality: 85,
                        );
                        if (x != null) {
                          _pickedImage = x;
                          // refresh bottom sheet
                          // ignore: use_build_context_synchronously
                          Navigator.of(ctx).pop();
                          // reopen with preserved controllers
                          _controller.text = _controller.text;
                          _showAddPostSheet();
                        }
                      } catch (e) {}
                    },
                    icon: const Icon(Icons.attachment_outlined),
                    label: const Text('Add attachment'),
                  ),
                  const SizedBox(width: 12),
                  if (_pickedImage != null)
                    const Icon(Icons.check_circle, color: Colors.green),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Add Music (Optional)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              SongSearchWidget(
                onSongSelected: (track) {
                  setState(() {
                    _selectedTrack = track;
                  });
                },
                selectedTrack: _selectedTrack,
              ),
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                onPressed: () async {
                  final String value = _controller.text;
                  final String? att = _pickedImage?.path;

                  final String? title = _selectedTrack?.title;
                  final String? artist = _selectedTrack?.artist;
                  Navigator.of(ctx).pop();
                  await _addPost(
                    value,
                    attachmentPath: att,
                    musicTitle: title,
                    musicArtist: artist,
                    deezerTrack: _selectedTrack,
                  );

                  // Clear the picked image and track after posting
                  _pickedImage = null;
                  _selectedTrack = null;
                },
                icon: const Icon(Icons.send_rounded),
                label: const Text('Post'),
              ),
            ],
          ),
        );
      },
    );
  }

  // Background is loaded from assets only (no picker)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          // Asset background
          Image.asset(
            _defaultAssetBg,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
          // Soft overlay for readability
          Container(color: Colors.black.withOpacity(0.20)),
          _currentIndex == 0
              ? (_initializing
                    ? const Center(child: CircularProgressIndicator())
                    : (_posts.isEmpty
                          ? const _EmptyState()
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                12,
                                16,
                                96,
                              ),
                              itemBuilder: (BuildContext context, int index) {
                                final Post post = _posts[index];
                                final currentUser = _authService.currentUser;
                                final currentUserId =
                                    currentUser?.uid ??
                                    _anonymousUserId ??
                                    'anonymous_${DateTime.now().millisecondsSinceEpoch}';
                                final canDelete = post.userId == currentUserId;

                                if (canDelete) {
                                  return Dismissible(
                                    key: ValueKey<String>(post.id),
                                    direction: DismissDirection.endToStart,
                                    background: Container(
                                      alignment: Alignment.centerRight,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      color: Colors.red.withOpacity(0.15),
                                      child: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                    ),
                                    confirmDismiss: (DismissDirection d) async {
                                      return await showDialog<bool>(
                                            context: context,
                                            builder: (BuildContext ctx) =>
                                                AlertDialog(
                                                  title: const Text(
                                                    'Delete post?',
                                                  ),
                                                  content: const Text(
                                                    'This will permanently remove the post on this device.',
                                                  ),
                                                  actions: <Widget>[
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.of(
                                                            ctx,
                                                          ).pop(false),
                                                      child: const Text(
                                                        'Cancel',
                                                      ),
                                                    ),
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.of(
                                                            ctx,
                                                          ).pop(true),
                                                      child: const Text(
                                                        'Delete',
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                          ) ??
                                          false;
                                    },
                                    onDismissed: (_) => _deletePost(post),
                                    child: PostCard(
                                      post: post,
                                      onLike: () => _likePost(post),
                                      onReact: (e) => _reactToPost(post, e),
                                      onComment: () => _showCommentsSheet(
                                        context,
                                        post,
                                        _addComment,
                                      ),
                                      currentUserId: currentUserId,
                                    ),
                                  );
                                } else {
                                  return PostCard(
                                    post: post,
                                    onLike: () => _likePost(post),
                                    onReact: (e) => _reactToPost(post, e),
                                    onComment: () => _showCommentsSheet(
                                      context,
                                      post,
                                      _addComment,
                                    ),
                                    currentUserId: currentUserId,
                                  );
                                }
                              },
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemCount: _posts.length,
                            )))
              : _currentIndex == 1
              ? const ProfilePage()
              : _currentIndex == 2
              ? const SearchPage()
              : const _AboutTab(),
        ],
      ),
      bottomNavigationBar: _ModernBottomBar(
        selectedIndex: _currentIndex,
        onSelect: (int i) {
          if (i == 2) {
            _showAddPostSheet();
            return;
          }
          if (i == 4) {
            // Logout button - handled by onLogout callback
            return;
          }
          // Map: Wall (0), Profile (1), Compose (2), Search (3), Logout (4)
          if (i == 0) setState(() => _currentIndex = 0);
          if (i == 1) setState(() => _currentIndex = 1);
          if (i == 3) setState(() => _currentIndex = 2);
        },
        onLogout: () async {
          final bool? confirm = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Logout'),
              content: const Text('Are you sure you want to logout?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Logout'),
                ),
              ],
            ),
          );

          if (confirm == true) {
            await _authService.signOut();
          }
        },
      ),
      floatingActionButton: null,
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: const <Widget>[
            Icon(Icons.forum_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              'No posts yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 6),
            Text('Tap "New Post" to share your thoughts.'),
          ],
        ),
      ),
    );
  }
}

String _formatTimeAgo(DateTime time) {
  final Duration diff = DateTime.now().difference(time);
  if (diff.inSeconds < 60) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  final int weeks = (diff.inDays / 7).floor();
  if (weeks < 5) return '${weeks}w ago';
  return '${time.year}/${time.month.toString().padLeft(2, '0')}/${time.day.toString().padLeft(2, '0')}';
}

class _AboutTab extends StatelessWidget {
  const _AboutTab();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const <Widget>[
          SizedBox(height: 12),
          Text(
            'About',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 8),
          Text(
            'Freedom Wall lets you share anonymous thoughts on your device.\n'
            'Posts are stored locally only and can be liked or swiped away.',
          ),
        ],
      ),
    );
  }
}

class _ModernBottomBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onLogout;

  const _ModernBottomBar({
    required this.selectedIndex,
    required this.onSelect,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    // Visual selection: treat 0 (Wall) as active position
    final bool wallActive = selectedIndex == 0;

    Widget buildIcon({
      required IconData icon,
      required bool active,
      required VoidCallback onTap,
    }) {
      return InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Icon(
            icon,
            size: 26,
            color: active ? Colors.white : Colors.white.withOpacity(0.5),
          ),
        ),
      );
    }

    Widget buildCenterCompose() {
      return GestureDetector(
        onTap: () => onSelect(2),
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      );
    }

    return Container(
      color: const Color(0xFF1F1F1F),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1F1F1F),
              borderRadius: BorderRadius.circular(24),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                buildIcon(
                  icon: Icons.home_outlined,
                  active: wallActive,
                  onTap: () => onSelect(0),
                ),
                const SizedBox(width: 8),
                buildIcon(
                  icon: Icons.person_outline,
                  active: selectedIndex == 1,
                  onTap: () => onSelect(1),
                ),
                const SizedBox(width: 12),
                buildCenterCompose(),
                const SizedBox(width: 12),
                buildIcon(
                  icon: Icons.search_rounded,
                  active: selectedIndex == 2,
                  onTap: () => onSelect(3),
                ),
                const SizedBox(width: 8),
                buildIcon(icon: Icons.logout, active: false, onTap: onLogout),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
