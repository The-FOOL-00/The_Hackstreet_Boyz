/// Contact Service
///
/// Handles reading device contacts and matching with registered users.
library;

import 'dart:async';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:permission_handler/permission_handler.dart';

/// Represents a buddy (matched contact)
class Buddy {
  final String uid;
  final String displayName;
  final String phone;
  final String status; // 'online' or 'offline'
  final DateTime lastActive;
  final String? photoUrl;

  const Buddy({
    required this.uid,
    required this.displayName,
    required this.phone,
    required this.status,
    required this.lastActive,
    this.photoUrl,
  });

  bool get isOnline => status == 'online';

  factory Buddy.fromJson(Map<String, dynamic> json, {String? odId}) {
    return Buddy(
      uid: odId ?? json['uid'] as String? ?? '',
      displayName: json['displayName'] as String? ?? 'User',
      phone: json['phone'] as String? ?? '',
      status: json['status'] as String? ?? 'offline',
      lastActive: DateTime.fromMillisecondsSinceEpoch(
        json['lastActive'] as int? ?? 0,
      ),
      photoUrl: json['photoUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'displayName': displayName,
    'phone': phone,
    'status': status,
    'lastActive': lastActive.millisecondsSinceEpoch,
    'photoUrl': photoUrl,
  };
}

class ContactService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  /// Reference to phone index in Firebase
  DatabaseReference get _phoneIndexRef => _database.ref('phoneIndex');

  /// Reference to users in Firebase
  DatabaseReference get _usersRef => _database.ref('users');

  /// Requests contacts permission
  Future<bool> requestContactsPermission() async {
    final status = await Permission.contacts.request();
    return status.isGranted;
  }

  /// Checks if contacts permission is granted
  Future<bool> hasContactsPermission() async {
    return await Permission.contacts.isGranted;
  }

  /// Gets all device contacts
  Future<List<Contact>> getDeviceContacts() async {
    if (!await hasContactsPermission()) {
      final granted = await requestContactsPermission();
      if (!granted) {
        return [];
      }
    }

    try {
      return await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false,
      );
    } catch (e) {
      return [];
    }
  }

  /// Extracts all phone numbers from contacts
  List<String> _extractPhoneNumbers(List<Contact> contacts) {
    final phones = <String>[];
    for (final contact in contacts) {
      for (final phone in contact.phones) {
        final normalized = _normalizePhoneNumber(phone.number);
        if (normalized.isNotEmpty) {
          phones.add(normalized);
        }
      }
    }
    return phones;
  }

  /// Normalizes phone number for matching
  String _normalizePhoneNumber(String phone) {
    // Remove all non-digit characters except leading +
    String normalized = phone.replaceAll(RegExp(r'[^\d+]'), '');

    // If no country code, assume India (+91)
    if (!normalized.startsWith('+')) {
      if (normalized.length == 10) {
        normalized = '+91$normalized';
      } else if (normalized.startsWith('91') && normalized.length == 12) {
        normalized = '+$normalized';
      }
    }

    return normalized;
  }

  /// Matches device contacts with registered users
  /// Returns list of buddies (users who are in contacts and registered)
  Future<List<Buddy>> findBuddies({required String excludeUid}) async {
    final contacts = await getDeviceContacts();
    final phoneNumbers = _extractPhoneNumbers(contacts);

    if (phoneNumbers.isEmpty) {
      return [];
    }

    // Create a map of phone -> contact name for display
    final phoneToName = <String, String>{};
    for (final contact in contacts) {
      for (final phone in contact.phones) {
        final normalized = _normalizePhoneNumber(phone.number);
        if (normalized.isNotEmpty) {
          phoneToName[normalized] = contact.displayName;
        }
      }
    }

    final buddies = <Buddy>[];

    // Check each phone number against Firebase phone index
    for (final phone in phoneNumbers) {
      final userId = await _getUserIdByPhone(phone);
      if (userId != null && userId != excludeUid) {
        final userData = await _getUserData(userId);
        if (userData != null) {
          // Use contact name if available, otherwise Firebase name
          final displayName =
              phoneToName[phone] ??
              userData['displayName'] as String? ??
              'User';

          buddies.add(
            Buddy(
              uid: userId,
              displayName: displayName,
              phone: phone,
              status: userData['status'] as String? ?? 'offline',
              lastActive: DateTime.fromMillisecondsSinceEpoch(
                userData['lastActive'] as int? ?? 0,
              ),
              photoUrl: userData['photoUrl'] as String?,
            ),
          );
        }
      }
    }

    // Sort: online users first, then by name
    buddies.sort((a, b) {
      if (a.isOnline && !b.isOnline) return -1;
      if (!a.isOnline && b.isOnline) return 1;
      return a.displayName.compareTo(b.displayName);
    });

    return buddies;
  }

  /// Gets user ID by phone number
  Future<String?> _getUserIdByPhone(String phone) async {
    final snapshot = await _phoneIndexRef
        .child(phone.replaceAll('+', ''))
        .get();
    if (snapshot.exists) {
      return snapshot.value as String;
    }

    // Also try with + prefix stored differently
    final snapshot2 = await _database.ref('phoneIndex/$phone').get();
    if (snapshot2.exists) {
      return snapshot2.value as String;
    }

    return null;
  }

  /// Gets user data from database
  Future<Map<String, dynamic>?> _getUserData(String uid) async {
    final snapshot = await _usersRef.child(uid).get();
    if (snapshot.exists) {
      return Map<String, dynamic>.from(snapshot.value as Map);
    }
    return null;
  }

  /// Streams buddy list changes (for real-time status updates)
  Stream<List<Buddy>> watchBuddies({
    required String excludeUid,
    required List<String> buddyUids,
  }) {
    if (buddyUids.isEmpty) {
      return Stream.value([]);
    }

    // Watch changes to all buddy users
    final streams = buddyUids.map((uid) => _usersRef.child(uid).onValue);

    return streams.first.asyncExpand((event) async* {
      final buddies = <Buddy>[];

      for (final uid in buddyUids) {
        final snapshot = await _usersRef.child(uid).get();
        if (snapshot.exists) {
          final data = Map<String, dynamic>.from(snapshot.value as Map);
          buddies.add(Buddy.fromJson(data, odId: uid));
        }
      }

      // Sort: online users first, then by name
      buddies.sort((a, b) {
        if (a.isOnline && !b.isOnline) return -1;
        if (!a.isOnline && b.isOnline) return 1;
        return a.displayName.compareTo(b.displayName);
      });

      yield buddies;
    });
  }

  /// Watches a single buddy's status
  Stream<Buddy?> watchBuddyStatus(String uid) {
    return _usersRef.child(uid).onValue.map((event) {
      if (event.snapshot.exists) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        return Buddy.fromJson(data, odId: uid);
      }
      return null;
    });
  }
}
