import 'package:flutter_contacts/flutter_contacts.dart';
import 'contacts_service_interface.dart';

class ContactsService implements ContactsServiceInterface {
  @override
  Future<bool> requestPermission() async {
    final status = await FlutterContacts.permissions.request(PermissionType.read);
    return status == PermissionStatus.granted;
  }

  @override
  Future<List<AppContact>> getContacts() async {
    final contacts = await FlutterContacts.getAll(
      properties: {ContactProperty.phone},
    );
    return contacts.map((c) {
      final name = c.displayName;
      return AppContact(
        displayName: (name == null || name.isEmpty) ? 'Contact' : name,
        phones: c.phones.map((p) => p.number).toList(),
      );
    }).toList();
  }
}
