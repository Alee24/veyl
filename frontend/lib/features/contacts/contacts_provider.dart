import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import 'contacts_service_interface.dart';
import 'contacts_service_web.dart' if (dart.library.io) 'contacts_service_mobile.dart';

class PhonebookState {
  final List<dynamic> matchedUsers;
  final List<AppContact> unmatchedContacts;
  final bool permissionGranted;
  final bool isLoading;

  PhonebookState({
    required this.matchedUsers,
    required this.unmatchedContacts,
    required this.permissionGranted,
    required this.isLoading,
  });

  PhonebookState copyWith({
    List<dynamic>? matchedUsers,
    List<AppContact>? unmatchedContacts,
    bool? permissionGranted,
    bool? isLoading,
  }) {
    return PhonebookState(
      matchedUsers: matchedUsers ?? this.matchedUsers,
      unmatchedContacts: unmatchedContacts ?? this.unmatchedContacts,
      permissionGranted: permissionGranted ?? this.permissionGranted,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class PhonebookNotifier extends StateNotifier<PhonebookState> {
  final Ref _ref;
  final ContactsService _contactsService = ContactsService();

  PhonebookNotifier(this._ref)
      : super(PhonebookState(
          matchedUsers: [],
          unmatchedContacts: [],
          permissionGranted: false,
          isLoading: false,
        ));

  Future<void> fetchAndMatchContacts() async {
    state = state.copyWith(isLoading: true);
    try {
      // 1. Request Contacts Permission
      final granted = await _contactsService.requestPermission();
      if (!granted) {
        state = state.copyWith(permissionGranted: false, isLoading: false);
        return;
      }

      // 2. Fetch Contacts
      final contacts = await _contactsService.getContacts();
      
      // Extract unique phone numbers
      final List<String> phoneNumbers = [];
      for (final contact in contacts) {
        for (final phone in contact.phones) {
          final normalized = phone.replaceAll(RegExp(r'\s+'), '');
          if (normalized.isNotEmpty) {
            phoneNumbers.add(normalized);
          }
        }
      }

      if (phoneNumbers.isEmpty) {
        state = state.copyWith(
          permissionGranted: true,
          unmatchedContacts: contacts,
          matchedUsers: [],
          isLoading: false,
        );
        return;
      }

      // 3. Match against backend
      final dio = _ref.read(dioProvider);
      final response = await dio.post('/users/match-contacts', data: {
        'phoneNumbers': phoneNumbers,
      });

      final matched = response.data as List<dynamic>;

      // Filter unmatched contacts
      final matchedPhones = matched.map((u) => u['phoneNumber'] as String).toList();
      final unmatched = contacts.where((contact) {
        return !contact.phones.any((p) {
          final cleanP = p.replaceAll(RegExp(r'\D'), '');
          return matchedPhones.any((m) {
            final cleanM = m.replaceAll(RegExp(r'\D'), '');
            return cleanP.endsWith(cleanM.length >= 9 ? cleanM.substring(cleanM.length - 9) : cleanM);
          });
        });
      }).toList();

      state = PhonebookState(
        matchedUsers: matched,
        unmatchedContacts: unmatched,
        permissionGranted: true,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }
}

final phonebookProvider = StateNotifierProvider<PhonebookNotifier, PhonebookState>((ref) {
  return PhonebookNotifier(ref);
});
