/// Centralized route paths for the app's go_router configuration.
class AppRoute {
  AppRoute._();

  static const String root = '/';
  static const String loading = '/loading';
  static const String login = '/login';
  static const String banned = '/banned';
  static const String authRequired = '/auth-required';

  static const String homeMessages = '/home/messages';
  static const String homeContacts = '/home/contacts';
  static const String homeContactsFull = '/home/contacts/full';
  static const String homeDiscover = '/home/discover';
  static const String homeWall = '/home/wall';
  static const String homePersonal = '/home/personal';

  static const String admin = '/admin';
  static const String adminUsers = '/admin/users';
  static const String settings = '/settings';

  /// Locations where the user MUST NOT stay if their session is active.
  static const Set<String> authOnly = <String>{
    root,
    loading,
    login,
    banned,
    authRequired,
  };
}
