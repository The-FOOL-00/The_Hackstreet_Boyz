/// Invite Provider
///
/// Manages game invitation state and real-time invite listening.
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/invite_service.dart';

class InviteProvider extends ChangeNotifier {
  final InviteService _inviteService = InviteService();

  String? _currentUserId;
  String? _currentUserName;

  List<GameInvite> _incomingInvites = [];
  GameInvite? _pendingOutgoingInvite;
  GameInvite? _currentInvite; // The invite being shown in modal

  bool _isLoading = false;
  String? _error;

  StreamSubscription<List<GameInvite>>? _incomingSubscription;
  StreamSubscription<GameInvite?>? _outgoingSubscription;

  // Getters
  List<GameInvite> get incomingInvites => _incomingInvites;
  GameInvite? get pendingOutgoingInvite => _pendingOutgoingInvite;
  GameInvite? get currentInvite => _currentInvite;
  bool get hasIncomingInvite => _incomingInvites.isNotEmpty;
  bool get hasPendingOutgoingInvite => _pendingOutgoingInvite != null;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Initializes the provider
  void init({required String userId, required String userName}) {
    _currentUserId = userId;
    _currentUserName = userName;
    _startListeningForInvites();
  }

  /// Starts listening for incoming invites
  void _startListeningForInvites() {
    if (_currentUserId == null) return;

    _incomingSubscription?.cancel();
    _incomingSubscription = _inviteService
        .watchIncomingInvites(_currentUserId!)
        .listen((invites) {
          _incomingInvites = invites;

          // Show the most recent pending invite
          if (invites.isNotEmpty && _currentInvite == null) {
            _currentInvite = invites.first;
          }

          notifyListeners();
        });
  }

  /// Sends an invite to a buddy
  Future<GameInvite?> sendInvite({
    required String receiverId,
    required String gameType,
    Map<String, dynamic>? gameConfig,
  }) async {
    if (_currentUserId == null || _currentUserName == null) {
      _error = 'Not logged in';
      notifyListeners();
      return null;
    }

    // Check if there's already a pending invite to this user
    final existing = await _inviteService.getPendingInviteTo(
      _currentUserId!,
      receiverId,
    );
    if (existing != null) {
      _error = 'You already have a pending invite to this user';
      notifyListeners();
      return null;
    }

    _setLoading(true);
    _clearError();

    try {
      final invite = await _inviteService.sendInvite(
        senderId: _currentUserId!,
        senderName: _currentUserName!,
        receiverId: receiverId,
        gameType: gameType,
        gameConfig: gameConfig,
      );

      _pendingOutgoingInvite = invite;

      // Watch for response
      _outgoingSubscription?.cancel();
      _outgoingSubscription = _inviteService
          .watchInvite(
            inviteId: invite.inviteId,
            userId: _currentUserId!,
            isOutgoing: true,
          )
          .listen((updatedInvite) {
            if (updatedInvite != null) {
              _pendingOutgoingInvite = updatedInvite;

              // Clear if responded
              if (!updatedInvite.isPending) {
                _pendingOutgoingInvite = null;
                _outgoingSubscription?.cancel();
              }

              notifyListeners();
            }
          });

      notifyListeners();
      return invite;
    } catch (e) {
      _error = 'Failed to send invite: ${e.toString()}';
      notifyListeners();
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Accepts an incoming invite
  Future<GameInvite?> acceptInvite({
    required String inviteId,
    required String roomCode,
  }) async {
    if (_currentUserId == null) {
      _error = 'Not logged in';
      notifyListeners();
      return null;
    }

    _setLoading(true);
    _clearError();

    try {
      final updatedInvite = await _inviteService.acceptInvite(
        inviteId: inviteId,
        receiverId: _currentUserId!,
        roomCode: roomCode,
      );

      // Remove from incoming invites
      _incomingInvites.removeWhere((i) => i.inviteId == inviteId);
      _currentInvite = null;

      notifyListeners();
      return updatedInvite;
    } catch (e) {
      _error = 'Failed to accept invite: ${e.toString()}';
      notifyListeners();
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Declines an incoming invite
  Future<void> declineInvite(String inviteId) async {
    if (_currentUserId == null) return;

    _setLoading(true);
    _clearError();

    try {
      await _inviteService.declineInvite(
        inviteId: inviteId,
        receiverId: _currentUserId!,
      );

      _incomingInvites.removeWhere((i) => i.inviteId == inviteId);

      if (_currentInvite?.inviteId == inviteId) {
        _currentInvite = _incomingInvites.isNotEmpty
            ? _incomingInvites.first
            : null;
      }

      notifyListeners();
    } catch (e) {
      _error = 'Failed to decline invite: ${e.toString()}';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  /// Cancels a pending outgoing invite
  Future<void> cancelInvite() async {
    if (_currentUserId == null || _pendingOutgoingInvite == null) return;

    _setLoading(true);
    _clearError();

    try {
      await _inviteService.cancelInvite(
        inviteId: _pendingOutgoingInvite!.inviteId,
        senderId: _currentUserId!,
      );

      _pendingOutgoingInvite = null;
      _outgoingSubscription?.cancel();

      notifyListeners();
    } catch (e) {
      _error = 'Failed to cancel invite: ${e.toString()}';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  /// Dismisses the current invite modal
  void dismissCurrentInvite() {
    if (_currentInvite != null) {
      // Move to next invite if available
      _incomingInvites.removeWhere(
        (i) => i.inviteId == _currentInvite!.inviteId,
      );
      _currentInvite = _incomingInvites.isNotEmpty
          ? _incomingInvites.first
          : null;
      notifyListeners();
    }
  }

  /// Shows a specific invite in the modal
  void showInvite(GameInvite invite) {
    _currentInvite = invite;
    notifyListeners();
  }

  /// Cleans up expired invites
  Future<void> cleanupExpired() async {
    if (_currentUserId != null) {
      await _inviteService.cleanupExpiredInvites(_currentUserId!);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  void clearError() {
    _clearError();
    notifyListeners();
  }

  @override
  void dispose() {
    _incomingSubscription?.cancel();
    _outgoingSubscription?.cancel();
    super.dispose();
  }
}
