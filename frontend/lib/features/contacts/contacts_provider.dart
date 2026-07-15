import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../../core/api_client.dart';

class PhonebookState {
  final List<dynamic> matchedUsers;
  final List<Contact> unmatchedContacts;
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
    List<Contact>? unmatchedContacts,
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
      final granted = await FlutterContacts.requestPermission(readonly: true);
      if (!granted) {
        state = state.copyWith(permissionGranted: false, isLoading: false);
        return;
      }

      // 2. Fetch Contacts with phone numbers
      final contacts = await FlutterContacts.getContacts(withProperties: true);
      
      // Extract unique phone numbers
      final List<String> phoneNumbers = [];
      for (final contact in contacts) {
        for (final phone in contact.phones) {
          final normalized = phone.number.replaceAll(RegExp(r'\s+'), '');
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
          final cleanP = p.number.replaceAll(RegExp(r'\D'), '');
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
