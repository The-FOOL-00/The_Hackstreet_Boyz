/// User Search Screen
///
/// Search for users by phone number or name and add them as buddies.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';
import '../services/user_search_service.dart';
import '../services/phone_auth_service.dart';

class UserSearchScreen extends StatefulWidget {
  const UserSearchScreen({super.key});

  @override
  State<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> {
  final _searchController = TextEditingController();
  final _userSearchService = UserSearchService();
  final _phoneAuthService = PhoneAuthService();

  List<UserSearchResult> _searchResults = [];
  bool _isSearching = false;
  String? _errorMessage;
  String? _successMessage;
  Set<String> _sentInvites = {};

  @override
  void initState() {
    super.initState();
    _ensurePhoneIndexExists();
  }

  /// Ensures current user's phone number is indexed
  Future<void> _ensurePhoneIndexExists() async {
    try {
      final currentUser = _phoneAuthService.currentUser;
      if (currentUser != null) {
        // Get user data
        final userData = await _phoneAuthService.getUserData(currentUser.uid);
        if (userData != null && userData['phone'] != null) {
          final phone = userData['phone'] as String;
          // Re-register phone (will create/update index)
          await _userSearchService.registerPhoneNumber(phone, currentUser.uid);
        }
      }
    } catch (e) {
      debugPrint('Failed to ensure phone index: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      // Get current user to exclude from search
      final currentUser = _phoneAuthService.currentUser;
      final excludeUid = currentUser?.uid;

      // Check if it's a phone number
      final isPhone = RegExp(r'^[\d+\s-]+$').hasMatch(query);

      debugPrint(
        '🔍 Searching for: "$query" (isPhone: $isPhone, excludeUid: $excludeUid)',
      );

      if (isPhone) {
        final result = await _userSearchService.searchByPhone(
          query,
          excludeUid: excludeUid,
        );
        debugPrint('📱 Phone search result: ${result?.displayName ?? "null"}');

        setState(() {
          _searchResults = result != null ? [result] : [];
          if (_searchResults.isEmpty) {
            _errorMessage = 'No user found with this phone number';
          }
        });
      } else {
        final results = await _userSearchService.searchByName(
          query,
          excludeUid: excludeUid,
        );
        debugPrint('👤 Name search results: ${results.length}');

        setState(() {
          _searchResults = results;
          if (_searchResults.isEmpty) {
            _errorMessage = 'No users found matching "$query"';
          }
        });
      }
    } catch (e) {
      debugPrint('❌ Search error: $e');
      setState(() {
        _errorMessage = 'Search failed: ${e.toString()}';
      });
    } finally {
      setState(() => _isSearching = false);
    }
  }

  Future<void> _sendBuddyInvite(UserSearchResult user) async {
    final notificationProvider = context.read<NotificationProvider>();

    setState(() => _successMessage = null);

    final success = await notificationProvider.sendBuddyInvite(
      toUserId: user.uid,
      toUserName: user.displayName,
    );

    if (success) {
      setState(() {
        _sentInvites.add(user.uid);
        _successMessage = 'Buddy invite sent to ${user.displayName}!';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5F2),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF2D3B36)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Find Friends',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2D3B36),
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {}); // Update UI for clear button
                // Debounce search
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (mounted && _searchController.text == value) {
                    _searchUsers(value);
                  }
                });
              },
              decoration: InputDecoration(
                hintText: 'Search by name or phone number',
                hintStyle: GoogleFonts.poppins(color: const Color(0xFF5C6B66)),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF6B9080)),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchResults = [];
                            _errorMessage = null;
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Color(0xFF6B9080),
                    width: 2,
                  ),
                ),
              ),
            ),
          ),

          // Success message
          if (_successMessage != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _successMessage!,
                      style: GoogleFonts.poppins(color: Colors.green.shade700),
                    ),
                  ),
                ],
              ),
            ),

          // Content area
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    // Loading state
    if (_isSearching) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF6B9080)),
      );
    }

    // Error state
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: const Color(0xFF5C6B66),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Results state
    if (_searchResults.isNotEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          final user = _searchResults[index];
          final inviteSent = _sentInvites.contains(user.uid);
          return _buildUserCard(user, inviteSent);
        },
      );
    }

    // Initial/empty state
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('👥', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 24),
            Text(
              'Find Your Friends',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2D3B36),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Search for friends by entering their phone number or name above',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF5C6B66),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F0ED),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '💡 Tips:',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2D3B36),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Enter phone number with country code\n• Example: +91 8888888888\n• Or search by name',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: const Color(0xFF5C6B66),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(UserSearchResult user, bool inviteSent) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xFFE8F0ED),
              child: Text(
                user.displayName.isNotEmpty
                    ? user.displayName[0].toUpperCase()
                    : '?',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF6B9080),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Name and status
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    user.displayName,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2D3B36),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: user.isOnline ? Colors.green : Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        user.isOnline ? 'Online' : 'Offline',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF5C6B66),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Button
            inviteSent
                ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '✓ Sent',
                      style: GoogleFonts.poppins(
                        color: Colors.green.shade700,
                        fontSize: 12,
                      ),
                    ),
                  )
                : TextButton(
                    onPressed: () => _sendBuddyInvite(user),
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFF6B9080),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Add',
                      style: GoogleFonts.poppins(fontSize: 12),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
