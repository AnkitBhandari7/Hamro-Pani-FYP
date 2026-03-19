import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ne.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ne')
  ];

  /// No description provided for @myProfile.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get myProfile;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @menu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menu;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @languagePreference.
  ///
  /// In en, this message translates to:
  /// **'Language Preference'**
  String get languagePreference;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logOut;

  /// No description provided for @savedLocations.
  ///
  /// In en, this message translates to:
  /// **'Saved Locations'**
  String get savedLocations;

  /// No description provided for @addNew.
  ///
  /// In en, this message translates to:
  /// **'+ Add New'**
  String get addNew;

  /// No description provided for @recentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get recentActivity;

  /// No description provided for @showRecentActivity.
  ///
  /// In en, this message translates to:
  /// **'Show Recent Activity'**
  String get showRecentActivity;

  /// No description provided for @hideRecentActivity.
  ///
  /// In en, this message translates to:
  /// **'Hide Recent Activity'**
  String get hideRecentActivity;

  /// No description provided for @selectYourWard.
  ///
  /// In en, this message translates to:
  /// **'Select Your Ward'**
  String get selectYourWard;

  /// No description provided for @pickLocation.
  ///
  /// In en, this message translates to:
  /// **'Pick Location'**
  String get pickLocation;

  /// No description provided for @confirmLocation.
  ///
  /// In en, this message translates to:
  /// **'Confirm Location'**
  String get confirmLocation;

  /// No description provided for @moveMapToChoose.
  ///
  /// In en, this message translates to:
  /// **'Move map to choose location'**
  String get moveMapToChoose;

  /// No description provided for @selectedLocation.
  ///
  /// In en, this message translates to:
  /// **'Selected location'**
  String get selectedLocation;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search (e.g. Baneshwor)'**
  String get searchHint;

  /// No description provided for @myLocation.
  ///
  /// In en, this message translates to:
  /// **'My Location'**
  String get myLocation;

  /// No description provided for @reportIssue.
  ///
  /// In en, this message translates to:
  /// **'Report Issue'**
  String get reportIssue;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @tapToPickLocation.
  ///
  /// In en, this message translates to:
  /// **'Tap to pick location from map'**
  String get tapToPickLocation;

  /// No description provided for @submitReport.
  ///
  /// In en, this message translates to:
  /// **'Submit Report →'**
  String get submitReport;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @nepali.
  ///
  /// In en, this message translates to:
  /// **'Nepali'**
  String get nepali;

  /// No description provided for @saveLanguage.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveLanguage;

  /// No description provided for @noWardSelected.
  ///
  /// In en, this message translates to:
  /// **'No ward selected'**
  String get noWardSelected;

  /// No description provided for @bookings.
  ///
  /// In en, this message translates to:
  /// **'Bookings'**
  String get bookings;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// No description provided for @personalDetails.
  ///
  /// In en, this message translates to:
  /// **'Personal Details'**
  String get personalDetails;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @wardLabel.
  ///
  /// In en, this message translates to:
  /// **'Ward'**
  String get wardLabel;

  /// No description provided for @selectYourWardHint.
  ///
  /// In en, this message translates to:
  /// **'Select your ward'**
  String get selectYourWardHint;

  /// No description provided for @noSavedLocationsYet.
  ///
  /// In en, this message translates to:
  /// **'No saved locations yet'**
  String get noSavedLocationsYet;

  /// No description provided for @defaultBadge.
  ///
  /// In en, this message translates to:
  /// **'DEFAULT'**
  String get defaultBadge;

  /// No description provided for @setDefault.
  ///
  /// In en, this message translates to:
  /// **'Set Default'**
  String get setDefault;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @tabBookings.
  ///
  /// In en, this message translates to:
  /// **'Bookings'**
  String get tabBookings;

  /// No description provided for @tabComplaints.
  ///
  /// In en, this message translates to:
  /// **'Complaints'**
  String get tabComplaints;

  /// No description provided for @noBookingsYet.
  ///
  /// In en, this message translates to:
  /// **'No bookings yet'**
  String get noBookingsYet;

  /// No description provided for @noComplaintsYet.
  ///
  /// In en, this message translates to:
  /// **'No complaints yet'**
  String get noComplaintsYet;

  /// No description provided for @complaintsHistoryNotAdded.
  ///
  /// In en, this message translates to:
  /// **'Complaints history screen not added yet'**
  String get complaintsHistoryNotAdded;

  /// No description provided for @resident.
  ///
  /// In en, this message translates to:
  /// **'Resident'**
  String get resident;

  /// No description provided for @vendor.
  ///
  /// In en, this message translates to:
  /// **'Vendor'**
  String get vendor;

  /// No description provided for @admin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get admin;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'ne'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'ne': return AppLocalizationsNe();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
