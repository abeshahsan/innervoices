import 'package:flutter/foundation.dart';
import 'package:innervoices/data/models/realm/note_realm_model.dart';
import 'package:realm/realm.dart';

// Singleton class to manage a single Realm instance across the app
class RealmManager {
  static RealmManager? _instance;
  static Realm? _realm;

  RealmManager._();

  // Get the singleton instance of RealmManager
  static RealmManager get instance {
    _instance ??= RealmManager._();
    return _instance!;
  }

  // Initialize Realm with configuration
  void initialize() {
    if (_realm == null || _realm!.isClosed) {
      debugPrint('DEBUG: [RealmManager] Initializing Realm...');
      final config = Configuration.local([NoteRealm.schema]);
      debugPrint('DEBUG: [RealmManager] Realm path: ${config.path}');
      _realm = Realm(config);
      debugPrint(
        'DEBUG: [RealmManager] Realm initialized. Path: ${_realm!.config.path}',
      );

      // Debug: Count notes after init
      try {
        final noteCount = _realm!.all<NoteRealm>().length;
        debugPrint(
          'DEBUG: [RealmManager] Notes in Realm after init: $noteCount',
        );
      } catch (e) {
        debugPrint('DEBUG: [RealmManager] Error counting notes: $e');
      }
    } else {
      debugPrint('DEBUG: [RealmManager] Realm already initialized.');
    }
  }

  // Get the Realm instance
  Realm get realm {
    if (_realm == null || _realm!.isClosed) {
      debugPrint(
        'DEBUG: [RealmManager] Realm was null/closed, reinitializing...',
      );
      initialize();
    }
    return _realm!;
  }

  // Close Realm instance
  void close() {
    debugPrint('DEBUG: [RealmManager] Closing Realm...');
    if (_realm != null && !_realm!.isClosed) {
      _realm!.close();
      debugPrint('DEBUG: [RealmManager] Realm closed.');
    }
    _realm = null;
  }

  // Reinitialize Realm after restore
  // This should be called after restoring data from backup
  void reinitialize() {
    debugPrint('DEBUG: [RealmManager] Reinitializing Realm (close + init)...');
    close();
    initialize();
    debugPrint('DEBUG: [RealmManager] Reinitialization complete.');
  }

  // Check if Realm is initialized and open
  bool get isOpen => _realm != null && !_realm!.isClosed;
}
