import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'auth_service.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    // Load all users when page opens
    _loadAllUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllUsers() async {
    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      print('Loading all users...');

      // Get all users from Firestore
      final QuerySnapshot snapshot = await _firestore
          .collection('users')
          .limit(50)
          .get();

      print('Found ${snapshot.docs.length} total users in database');

      final List<Map<String, dynamic>> results = [];

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        // Don't show current user in results
        if (doc.id != _authService.currentUser?.uid) {
          results.add({
            'id': doc.id,
            'displayName': data['displayName'] ?? 'Unknown User',
            'email': data['email'] ?? '',
            'createdAt': data['createdAt'],
          });
        }
      }

      print('Total users to show: ${results.length}');
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading all users: $e');
      setState(() {
        _searchResults = [];
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Error loading users')));
      }
    }
  }

  Future<void> _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      // Show all users when search is empty
      await _loadAllUsers();
      return;
    }

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      print('Searching for: "$query"');

      // Get all users and filter client-side for more flexible search
      final QuerySnapshot snapshot = await _firestore
          .collection('users')
          .limit(100)
          .get();

      print('Found ${snapshot.docs.length} total users, filtering...');

      final List<Map<String, dynamic>> results = [];
      final String searchTerm = query.trim().toLowerCase();

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        // Don't show current user in search results
        if (doc.id != _authService.currentUser?.uid) {
          final displayName = (data['displayName'] ?? '').toLowerCase();
          final email = (data['email'] ?? '').toLowerCase();

          // Check if search term matches displayName or email
          if (displayName.contains(searchTerm) || email.contains(searchTerm)) {
            results.add({
              'id': doc.id,
              'displayName': data['displayName'] ?? 'Unknown User',
              'email': data['email'] ?? '',
              'createdAt': data['createdAt'],
            });
          }
        }
      }

      print('Total search results: ${results.length}');
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      print('Error searching users: $e');
      setState(() {
        _searchResults = [];
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Error searching users')));
      }
    }
  }

  Future<void> _viewUserProfile(String userId) async {
    try {
      // Get user's posts from both collections
      final QuerySnapshot userPostsSnapshot = await _firestore
          .collection('user_posts')
          .where('userId', isEqualTo: userId)
          .get();

      final QuerySnapshot anonymousPostsSnapshot = await _firestore
          .collection('anonymous_posts')
          .where('userId', isEqualTo: userId)
          .get();

      final totalPostsCount =
          userPostsSnapshot.docs.length + anonymousPostsSnapshot.docs.length;

      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data();

      print(
        'User profile - userId: $userId, user posts: ${userPostsSnapshot.docs.length}, anonymous posts: ${anonymousPostsSnapshot.docs.length}, total: $totalPostsCount',
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserProfileViewPage(
              userId: userId,
              userData: userData,
              postsCount: totalPostsCount,
            ),
          ),
        );
      }
    } catch (e) {
      print('Error viewing user profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error loading user profile')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Search Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.search_rounded,
                        color: scheme.onPrimaryContainer,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Search Users',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: scheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Search Input
                  Container(
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: scheme.outline.withOpacity(0.3),
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _searchUsers,
                      decoration: InputDecoration(
                        hintText: 'Search by name or email...',
                        hintStyle: TextStyle(
                          color: scheme.onSurface.withOpacity(0.6),
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: scheme.onSurface.withOpacity(0.6),
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.clear,
                                  color: scheme.onSurface.withOpacity(0.6),
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  _searchUsers('');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Search Results
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(color: scheme.primary),
                    )
                  : _hasSearched
                  ? _searchResults.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off_rounded,
                                  size: 64,
                                  color: scheme.onSurface.withOpacity(0.4),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No users found',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: scheme.onSurface.withOpacity(0.6),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Try a different search term',
                                  style: TextStyle(
                                    color: scheme.onSurface.withOpacity(0.4),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _searchResults.length,
                            itemBuilder: (context, index) {
                              final user = _searchResults[index];
                              return _buildUserCard(user, scheme);
                            },
                          )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_rounded,
                            size: 64,
                            color: scheme.onSurface.withOpacity(0.4),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Search for users',
                            style: TextStyle(
                              fontSize: 18,
                              color: scheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Enter a name or email to find users',
                            style: TextStyle(
                              color: scheme.onSurface.withOpacity(0.4),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user, ColorScheme scheme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: scheme.surface,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: scheme.primary,
          child: Text(
            (user['displayName'] as String).isNotEmpty
                ? (user['displayName'] as String)[0].toUpperCase()
                : 'U',
            style: TextStyle(
              color: scheme.onPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          user['displayName'] ?? 'Unknown User',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: scheme.onSurface,
          ),
        ),
        subtitle: Text(
          user['email'] ?? '',
          style: TextStyle(color: scheme.onSurface.withOpacity(0.7)),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          size: 16,
          color: scheme.onSurface.withOpacity(0.5),
        ),
        onTap: () => _viewUserProfile(user['id']),
      ),
    );
  }
}

class UserProfileViewPage extends StatefulWidget {
  final String userId;
  final Map<String, dynamic>? userData;
  final int postsCount;

  const UserProfileViewPage({
    super.key,
    required this.userId,
    required this.userData,
    required this.postsCount,
  });

  @override
  State<UserProfileViewPage> createState() => _UserProfileViewPageState();
}

class _UserProfileViewPageState extends State<UserProfileViewPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();
  List<Map<String, dynamic>> _userPosts = [];
  bool _isLoading = true;
  bool _isFollowing = false;
  bool _isFollowLoading = false;

  @override
  void initState() {
    super.initState();
    print('UserProfileViewPage initState - userId: ${widget.userId}');
    print('UserProfileViewPage initState - userData: ${widget.userData}');
    print('UserProfileViewPage initState - postsCount: ${widget.postsCount}');
    _loadUserPosts();
    _checkFollowStatus();
  }

  Future<void> _checkFollowStatus() async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return;

    try {
      final doc = await _firestore
          .collection('follows')
          .doc('${currentUser.uid}_${widget.userId}')
          .get();

      setState(() {
        _isFollowing = doc.exists;
      });
    } catch (e) {
      print('Error checking follow status: $e');
    }
  }

  Future<void> _toggleFollow() async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return;

    setState(() {
      _isFollowLoading = true;
    });

    try {
      final followDocId = '${currentUser.uid}_${widget.userId}';

      if (_isFollowing) {
        // Unfollow
        await _firestore.collection('follows').doc(followDocId).delete();

        // Update follower count
        await _firestore.collection('users').doc(widget.userId).update({
          'followers': FieldValue.increment(-1),
        });

        // Update following count
        await _firestore.collection('users').doc(currentUser.uid).update({
          'following': FieldValue.increment(-1),
        });
      } else {
        // Follow
        await _firestore.collection('follows').doc(followDocId).set({
          'followerId': currentUser.uid,
          'followingId': widget.userId,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Update follower count
        await _firestore.collection('users').doc(widget.userId).update({
          'followers': FieldValue.increment(1),
        });

        // Update following count
        await _firestore.collection('users').doc(currentUser.uid).update({
          'following': FieldValue.increment(1),
        });
      }

      setState(() {
        _isFollowing = !_isFollowing;
        _isFollowLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isFollowing ? 'Following user' : 'Unfollowed user'),
          ),
        );
      }
    } catch (e) {
      print('Error toggling follow: $e');
      setState(() {
        _isFollowLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error updating follow status')),
        );
      }
    }
  }

  Future<void> _loadUserPosts() async {
    print('Loading posts for user: ${widget.userId}');
    try {
      // First try user_posts collection
      final QuerySnapshot userPostsSnapshot = await _firestore
          .collection('user_posts')
          .where('userId', isEqualTo: widget.userId)
          .get();

      print(
        'Found ${userPostsSnapshot.docs.length} posts in user_posts for user ${widget.userId}',
      );

      // Also check anonymous_posts collection in case some posts are there
      final QuerySnapshot anonymousPostsSnapshot = await _firestore
          .collection('anonymous_posts')
          .where('userId', isEqualTo: widget.userId)
          .get();

      print(
        'Found ${anonymousPostsSnapshot.docs.length} posts in anonymous_posts for user ${widget.userId}',
      );

      final List<Map<String, dynamic>> posts = [];

      // Add posts from user_posts collection
      for (final doc in userPostsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        posts.add({'id': doc.id, ...data});
        print('User post data: ${doc.id} - ${data['text']}');
      }

      // Add posts from anonymous_posts collection
      for (final doc in anonymousPostsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        posts.add({'id': doc.id, ...data});
        print('Anonymous post data: ${doc.id} - ${data['text']}');
      }

      // Sort by creation date (newest first)
      posts.sort((a, b) {
        DateTime? aTime;
        DateTime? bTime;

        // Handle both Timestamp and String formats
        if (a['createdAt'] is Timestamp) {
          aTime = (a['createdAt'] as Timestamp).toDate();
        } else if (a['createdAt'] is String) {
          aTime = DateTime.parse(a['createdAt'] as String);
        }

        if (b['createdAt'] is Timestamp) {
          bTime = (b['createdAt'] as Timestamp).toDate();
        } else if (b['createdAt'] is String) {
          bTime = DateTime.parse(b['createdAt'] as String);
        }

        if (aTime == null || bTime == null) return 0;
        return bTime.compareTo(aTime);
      });

      print('Final posts count: ${posts.length}');
      print(
        'Setting state - _userPosts: ${posts.length} posts, _isLoading: false',
      );

      setState(() {
        _userPosts = posts;
        _isLoading = false;
      });

      print('State updated - _userPosts length: ${_userPosts.length}');
    } catch (e) {
      print('Error loading user posts: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final displayName = widget.userData?['displayName'] ?? 'Unknown User';
    final email = widget.userData?['email'] ?? '';
    final followers = widget.userData?['followers'] ?? 0;
    final following = widget.userData?['following'] ?? 0;
    final currentUser = _authService.currentUser;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Cat wallpaper background
          Image.asset(
            'assets/catbg.jpg',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: scheme.background),
          ),
          // Soft overlay for readability
          Container(color: Colors.black.withOpacity(0.20)),

          // Content
          Column(
            children: [
              // Custom App Bar
              Container(
                padding: const EdgeInsets.fromLTRB(16, 50, 16, 16),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer.withOpacity(0.9),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.arrow_back_ios_rounded,
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        displayName,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: scheme.onPrimaryContainer,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48), // Balance the back button
                  ],
                ),
              ),

              // User Info Card
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: scheme.surface.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: scheme.shadow.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: scheme.primary,
                      child: Text(
                        displayName.isNotEmpty
                            ? displayName[0].toUpperCase()
                            : 'U',
                        style: TextStyle(
                          color: scheme.onPrimary,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      displayName,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      email,
                      style: TextStyle(
                        color: scheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Follow Button (only show if not current user)
                    if (currentUser?.uid != widget.userId) ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isFollowLoading ? null : _toggleFollow,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isFollowing
                                ? scheme.surfaceContainerHighest
                                : scheme.primary,
                            foregroundColor: _isFollowing
                                ? scheme.onSurface
                                : scheme.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isFollowLoading
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: _isFollowing
                                        ? scheme.onSurface
                                        : scheme.onPrimary,
                                  ),
                                )
                              : Text(
                                  _isFollowing ? 'Following' : 'Follow',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Stats
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatItem(
                          'Posts',
                          widget.postsCount.toString(),
                          scheme,
                        ),
                        _buildStatItem(
                          'Followers',
                          followers.toString(),
                          scheme,
                        ),
                        _buildStatItem(
                          'Following',
                          following.toString(),
                          scheme,
                        ),
                        _buildStatItem('Joined', _formatJoinDate(), scheme),
                      ],
                    ),
                  ],
                ),
              ),

              // Posts Section
              Expanded(
                child: Builder(
                  builder: (context) {
                    print(
                      'Building posts section - isLoading: $_isLoading, posts count: ${_userPosts.length}',
                    );
                    return _isLoading
                        ? Center(
                            child: CircularProgressIndicator(
                              color: scheme.primary,
                            ),
                          )
                        : _userPosts.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.post_add_rounded,
                                  size: 64,
                                  color: scheme.onSurface.withOpacity(0.4),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No posts yet',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: scheme.onSurface.withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _userPosts.length,
                            itemBuilder: (context, index) {
                              final post = _userPosts[index];
                              print(
                                'Building post card for index $index: ${post['text']}',
                              );
                              return _buildPostCard(post, scheme, displayName);
                            },
                          );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, ColorScheme scheme) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: scheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: scheme.onSurface.withOpacity(0.7))),
      ],
    );
  }

  Widget _buildPostCard(
    Map<String, dynamic> post,
    ColorScheme scheme,
    String displayName,
  ) {
    print('_buildPostCard called with post: $post');
    print('_buildPostCard displayName: $displayName');

    final text = post['text'] ?? '';
    final likes = post['likes'] ?? 0;
    final attachmentPath = post['attachmentPath'] as String?;
    final musicTitle = post['musicTitle'] as String?;
    final musicArtist = post['musicArtist'] as String?;
    final albumImage = post['albumImage'] as String?;
    final mainReaction = post['mainReaction'] as String?;
    final comments = post['comments'] as List? ?? [];

    // Handle both Timestamp and String formats for createdAt
    DateTime? createdAt;
    if (post['createdAt'] is Timestamp) {
      createdAt = (post['createdAt'] as Timestamp).toDate();
    } else if (post['createdAt'] is String) {
      createdAt = DateTime.parse(post['createdAt'] as String);
    }

    final String time = _formatRealTime(createdAt ?? DateTime.now());
    final bool hasLikes = likes > 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
                  displayName,
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
                      _formatFullDate(createdAt ?? DateTime.now()),
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
              text,
              style: TextStyle(
                fontSize: 16,
                height: 1.35,
                color: scheme.onPrimaryContainer,
              ),
            ),
            if (attachmentPath != null) ...<Widget>[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: double.infinity,
                  height: 200,
                  child: _buildImageFromFile(attachmentPath),
                ),
              ),
            ],
            if (musicTitle != null || musicArtist != null) ...<Widget>[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Row(
                  children: <Widget>[
                    // Album Cover
                    if (albumImage != null && albumImage.isNotEmpty) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          albumImage,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.grey[600],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.music_note,
                                color: Colors.white,
                                size: 24,
                              ),
                            );
                          },
                        ),
                      ),
                    ] else ...[
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.grey[600],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.music_note,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ],
                    const SizedBox(width: 12),
                    // Song Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (musicTitle != null && musicTitle.isNotEmpty)
                            Text(
                              musicTitle,
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          if (musicArtist != null &&
                              musicArtist.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              musicArtist,
                              style: TextStyle(
                                color: Colors.black.withOpacity(0.7),
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                AnimatedContainer(
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
                      if (mainReaction == null) ...[
                        Icon(
                          Icons.favorite_border_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ] else
                        Text(
                          mainReaction,
                          style: const TextStyle(fontSize: 18),
                        ),
                      const SizedBox(width: 6),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        transitionBuilder:
                            (Widget child, Animation<double> anim) =>
                                ScaleTransition(scale: anim, child: child),
                        child: Text(
                          likes.toString(),
                          key: ValueKey<int>(likes),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () {
                    // Comments functionality could be added here
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    backgroundColor: Colors.white.withOpacity(0.14),
                    shape: const StadiumBorder(),
                  ),
                  icon: const Icon(Icons.mode_comment_outlined, size: 18),
                  label: Text('${comments.length}'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatJoinDate() {
    final createdAt = widget.userData?['createdAt'] as Timestamp?;
    if (createdAt == null) return 'Unknown';

    final date = createdAt.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays < 30) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years year${years > 1 ? 's' : ''} ago';
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
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
}
