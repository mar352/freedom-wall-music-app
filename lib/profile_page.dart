import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';
import 'main.dart';
import 'post_card.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Post> _userPosts = [];
  List<Post> _filteredPosts = [];
  bool _isLoading = true;
  DateTime? _selectedDate;
  bool _isFiltered = false;

  @override
  void initState() {
    super.initState();
    _loadUserPosts();
    _setupRealtimeListener();
  }

  void _setupRealtimeListener() {
    if (_authService.isAnonymous) return;

    final user = _authService.currentUser;
    if (user != null) {
      _firestore
          .collection('user_posts')
          .where('userId', isEqualTo: user.uid)
          .snapshots()
          .listen((snapshot) {
            final List<Post> posts = snapshot.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return Post.fromJson({...data, 'id': doc.id});
            }).toList();

            // Sort posts by creation date (newest first)
            posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));

            if (mounted) {
              setState(() {
                _userPosts = posts;
                _filteredPosts = _isFiltered
                    ? _filterPostsByDate(posts, _selectedDate!)
                    : posts;
                _isLoading = false;
              });
            }
          });
    }
  }

  Future<void> _loadUserPosts() async {
    if (_authService.isAnonymous) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final user = _authService.currentUser;
      if (user != null) {
        final QuerySnapshot snapshot = await _firestore
            .collection('user_posts')
            .where('userId', isEqualTo: user.uid)
            .get();

        final List<Post> posts = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return Post.fromJson({...data, 'id': doc.id});
        }).toList();

        // Sort posts by creation date (newest first)
        posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        setState(() {
          _userPosts = posts;
          _filteredPosts = _isFiltered
              ? _filterPostsByDate(posts, _selectedDate!)
              : posts;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading user posts: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deletePost(Post post) async {
    // Check if current user owns this post
    final currentUser = _authService.currentUser;
    if (currentUser == null || post.userId != currentUser.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can only delete your own posts')),
      );
      return;
    }

    try {
      await _firestore.collection('user_posts').doc(post.id).delete();
      setState(() {
        _userPosts.removeWhere((p) => p.id == post.id);
        _filteredPosts.removeWhere((p) => p.id == post.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post deleted successfully')),
      );
    } catch (e) {
      print('Error deleting post: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to delete post')));
    }
  }

  Future<void> _likePost(Post post) async {
    const String defaultEmoji = '❤️';
    await _toggleLike(post, defaultEmoji);
  }

  Future<void> _toggleLike(Post post, String emoji) async {
    final int index = _userPosts.indexWhere((p) => p.id == post.id);
    if (index < 0) return;

    final currentUser = _authService.currentUser;
    final currentUserId =
        currentUser?.uid ??
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
    await _updatePostInFirestore(updated);

    // Update local state
    setState(() {
      _userPosts[index] = updated;
      final filteredIndex = _filteredPosts.indexWhere((p) => p.id == post.id);
      if (filteredIndex >= 0) {
        _filteredPosts[filteredIndex] = updated;
      }
    });
  }

  Future<void> _reactToPost(Post post, String emoji) async {
    final int index = _userPosts.indexWhere((p) => p.id == post.id);
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
    await _updatePostInFirestore(updated);

    // Update local state
    setState(() {
      _userPosts[index] = updated;
      final filteredIndex = _filteredPosts.indexWhere((p) => p.id == post.id);
      if (filteredIndex >= 0) {
        _filteredPosts[filteredIndex] = updated;
      }
    });
  }

  Future<void> _addComment(Post post, String text) async {
    final int index = _userPosts.indexWhere((p) => p.id == post.id);
    if (index < 0) return;
    final PostComment comment = PostComment(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      text: text.trim(),
      createdAt: DateTime.now(),
    );
    final List<PostComment> updated = <PostComment>[...post.comments, comment];
    final Post updatedPost = post.copyWith(comments: updated);

    // Update in Firestore for real-time sync
    await _updatePostInFirestore(updatedPost);

    // Update local state
    setState(() {
      _userPosts[index] = updatedPost;
      final filteredIndex = _filteredPosts.indexWhere((p) => p.id == post.id);
      if (filteredIndex >= 0) {
        _filteredPosts[filteredIndex] = updatedPost;
      }
    });
  }

  Future<void> _updatePostInFirestore(Post post) async {
    try {
      await _firestore.collection('user_posts').doc(post.id).update({
        'likes': post.likes,
        'likedBy': post.likedBy,
        'reactions': post.reactions,
        'mainReaction': post.mainReaction,
        'comments': post.comments.map((c) => c.toJson()).toList(),
      });
    } catch (e) {
      print('Error updating post in Firestore: $e');
    }
  }

  void _showCommentsSheet(Post post) {
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
                      await _addComment(post, t);
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

  String _formatTimeAgo(DateTime time) {
    final Duration diff = DateTime.now().difference(time);
    if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  List<Post> _filterPostsByDate(List<Post> posts, DateTime selectedDate) {
    return posts.where((post) {
      final postDate = DateTime(
        post.createdAt.year,
        post.createdAt.month,
        post.createdAt.day,
      );
      final filterDate = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
      );
      return postDate.isAtSameMomentAs(filterDate);
    }).toList();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _isFiltered = true;
        _filteredPosts = _filterPostsByDate(_userPosts, picked);
      });
    }
  }

  void _clearFilter() {
    setState(() {
      _selectedDate = null;
      _isFiltered = false;
      _filteredPosts = _userPosts;
    });
  }

  String _formatDate(DateTime date) {
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
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isAnonymous = _authService.isAnonymous;

    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Info Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: isAnonymous
                                  ? Colors.grey
                                  : Colors.blue,
                              child: Icon(
                                isAnonymous
                                    ? Icons.person_outline
                                    : Icons.person,
                                size: 30,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _authService.userDisplayName,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (!isAnonymous &&
                                      _authService.userEmail != null)
                                    Text(
                                      _authService.userEmail!,
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isAnonymous
                                          ? Colors.orange
                                          : Colors.green,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      isAnonymous ? 'Anonymous' : 'Registered',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                'Posts',
                                _userPosts.length.toString(),
                                Icons.post_add,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                'Total Likes',
                                _userPosts
                                    .fold<int>(
                                      0,
                                      (sum, post) => sum + post.likes,
                                    )
                                    .toString(),
                                Icons.favorite,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Posts Section
                if (isAnonymous) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Icon(
                            Icons.visibility_off,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Anonymous Mode',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your posts are anonymous and cannot be viewed in your profile. Create an account to track your posts.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  Row(
                    children: [
                      Text(
                        'My Posts',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      if (_isFiltered)
                        Text(
                          'Filtered by ${_formatDate(_selectedDate!)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Date Filter Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(
                            Icons.filter_list,
                            color: Colors.blue[600],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Filter by date:',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _selectDate,
                              icon: const Icon(Icons.calendar_today, size: 16),
                              label: Text(
                                _selectedDate != null
                                    ? _formatDate(_selectedDate!)
                                    : 'Select Date',
                                style: const TextStyle(fontSize: 12),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ),
                          if (_isFiltered) ...[
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: _clearFilter,
                              icon: const Icon(Icons.clear, size: 18),
                              tooltip: 'Clear filter',
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.red[50],
                                foregroundColor: Colors.red[600],
                                padding: const EdgeInsets.all(4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_filteredPosts.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(
                              Icons.post_add_outlined,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _isFiltered
                                  ? 'No posts on this date'
                                  : 'No posts yet',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _isFiltered
                                  ? 'Try selecting a different date or clear the filter'
                                  : 'Start sharing your thoughts!',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _filteredPosts.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final post = _filteredPosts[index];
                        final currentUser = _authService.currentUser;
                        final canDelete =
                            currentUser != null &&
                            post.userId == currentUser.uid;

                        if (canDelete) {
                          return Dismissible(
                            key: ValueKey(post.id),
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
                            confirmDismiss: (direction) async {
                              return await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Delete Post'),
                                      content: const Text(
                                        'Are you sure you want to delete this post?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(false),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(true),
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  ) ??
                                  false;
                            },
                            onDismissed: (direction) => _deletePost(post),
                            child: PostCard(
                              post: post,
                              onLike: () => _likePost(post),
                              onReact: (emoji) => _reactToPost(post, emoji),
                              onComment: () => _showCommentsSheet(post),
                              currentUserId: _authService.currentUser?.uid,
                            ),
                          );
                        } else {
                          return PostCard(
                            post: post,
                            onLike: () => _likePost(post),
                            onReact: (emoji) => _reactToPost(post, emoji),
                            onComment: () => _showCommentsSheet(post),
                            currentUserId: _authService.currentUser?.uid,
                          );
                        }
                      },
                    ),
                ],
              ],
            ),
          );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.grey[600]),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }
}
