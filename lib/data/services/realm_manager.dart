import 'package:innervoices/data/models/realm/note_realm_model.dart';
import 'package:realm/realm.dart';

/// Singleton class to manage a single Realm instance across the app
class RealmManager {
  static RealmManager? _instance;
  static Realm? _realm;

  RealmManager._();

  /// Get the singleton instance of RealmManager
  static RealmManager get instance {
    _instance ??= RealmManager._();
    return _instance!;
  }

  /// Initialize Realm with configuration
  void initialize() {
    if (_realm == null || _realm!.isClosed) {
      final config = Configuration.local([NoteRealm.schema]);
      _realm = Realm(config);
    }
  }

  /// Get the Realm instance
  Realm get realm {
    if (_realm == null || _realm!.isClosed) {
      initialize();
    }
    return _realm!;
  }

  /// Close Realm instance
  void close() {
    _realm?.close();
    _realm = null;
  }

  /// Check if Realm is initialized and open
  bool get isOpen => _realm != null && !_realm!.isClosed;
}
