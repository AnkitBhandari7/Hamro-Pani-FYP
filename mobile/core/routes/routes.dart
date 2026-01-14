class AppRoutes {
  // Auth Screens
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';

  // Main Screens
  static const String home = '/home';
  static const String orders = '/orders';
  static const String profile = '/profile';
  static const String changePassword = '/change-password';
  static const String notifications = '/notifications';
  static const String bookingDetails = '/booking-details';
  static const String locationPicker = '/location-picker';

  // Initial route
  static const String initial = login; // or home if user logged in
}