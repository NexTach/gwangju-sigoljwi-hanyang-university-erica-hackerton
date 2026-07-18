import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ProfileAvatarStyle {
  initial,
  walking,
  wheelchair,
  stroller,
  navigation,
  neighborhood,
}

class ProfileAvatarController extends Notifier<ProfileAvatarStyle> {
  static const _preferenceKey = 'demoProfile.avatarStyle';

  bool _restored = false;

  @override
  ProfileAvatarStyle build() => ProfileAvatarStyle.initial;

  Future<void> restore() async {
    if (_restored) return;
    _restored = true;
    final preferences = await SharedPreferences.getInstance();
    final savedName = preferences.getString(_preferenceKey);
    state = ProfileAvatarStyle.values.firstWhere(
      (style) => style.name == savedName,
      orElse: () => ProfileAvatarStyle.initial,
    );
  }

  Future<void> select(ProfileAvatarStyle style) async {
    state = style;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_preferenceKey, style.name);
  }

  Future<void> reset() async {
    state = ProfileAvatarStyle.initial;
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_preferenceKey);
  }
}

final profileAvatarProvider =
    NotifierProvider<ProfileAvatarController, ProfileAvatarStyle>(
      ProfileAvatarController.new,
    );
