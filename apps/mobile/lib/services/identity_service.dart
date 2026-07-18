import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

class IdentityService {
  IdentityService({
    FlutterSecureStorage? storage,
    Uuid? uuid,
  }) : _storage = storage ?? const FlutterSecureStorage(),
       _uuid = uuid ?? const Uuid();

  static const _identityKey = 'road_dna_anonymous_user_id';

  final FlutterSecureStorage _storage;
  final Uuid _uuid;

  Future<String> getOrCreate() async {
    final existing = await _storage.read(key: _identityKey);
    if (existing != null && existing.isNotEmpty) return existing;
    final created = _uuid.v4();
    await _storage.write(key: _identityKey, value: created);
    return created;
  }
}
