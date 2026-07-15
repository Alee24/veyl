import 'contacts_service_interface.dart';

class ContactsService implements ContactsServiceInterface {
  @override
  Future<bool> requestPermission() async {
    // Web environment does not support device address book permissions
    return false;
  }

  @override
  Future<List<AppContact>> getContacts() async {
    return [];
  }
}
