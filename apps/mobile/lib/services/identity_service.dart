import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

final _anonymousIdentityPattern = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-'
  r'[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
);

bool isValidAnonymousIdentity(String value) =>
    _anonymousIdentityPattern.hasMatch(value);

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
    if (existing != null && isValidAnonymousIdentity(existing)) {
      return existing;
    }
    final created = _uuid.v4();
    await _storage.write(key: _identityKey, value: created);
    return created;
  }
}
