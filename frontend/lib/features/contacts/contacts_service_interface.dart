class AppContact {
  final String displayName;
  final List<String> phones;
  AppContact({required this.displayName, required this.phones});
}

abstract class ContactsServiceInterface {
  Future<bool> requestPermission();
  Future<List<AppContact>> getContacts();
}
