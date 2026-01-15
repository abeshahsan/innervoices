import 'package:realm/realm.dart';
// ignore: unnecessary_import, depend_on_referenced_packages
import 'package:realm_common/realm_common.dart';

part 'note_realm_model.realm.dart';

@RealmModel()
class _NoteRealm {
  @PrimaryKey()
  late String id;

  late String title;
  late String content;
  late DateTime lastEdited;
  late String userId;
}
