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
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ne'),
  ];

  /// No description provided for @myProfile.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get myProfile;

  /// No description provided for @vendorProfile.
  ///
  /// In en, this message translates to:
  /// **'Vendor Profile'**
  String get vendorProfile;

  /// No description provided for @wardAdminProfile.
  ///
  /// In en, this message translates to:
  /// **'Ward Admin Profile'**
  String get wardAdminProfile;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

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

  /// No description provided for @noWardSelected.
  ///
  /// In en, this message translates to:
  /// **'No ward selected'**
  String get noWardSelected;

  /// No description provided for @wardLabel.
  ///
  /// In en, this message translates to:
  /// **'Ward'**
  String get wardLabel;

  /// No description provided for @selectYourWard.
  ///
  /// In en, this message translates to:
  /// **'Select Your Ward'**
  String get selectYourWard;

  /// No description provided for @selectYourWardHint.
  ///
  /// In en, this message translates to:
  /// **'Select your ward'**
  String get selectYourWardHint;

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

  /// No description provided for @tapEditFirstToChangePhoto.
  ///
  /// In en, this message translates to:
  /// **'Tap Edit first to change photo'**
  String get tapEditFirstToChangePhoto;

  /// No description provided for @companyNameHint.
  ///
  /// In en, this message translates to:
  /// **'Company Name'**
  String get companyNameHint;

  /// No description provided for @fullNameContactPersonHint.
  ///
  /// In en, this message translates to:
  /// **'Full Name (Contact Person)'**
  String get fullNameContactPersonHint;

  /// No description provided for @verifiedVendor.
  ///
  /// In en, this message translates to:
  /// **'Verified Vendor'**
  String get verifiedVendor;

  /// No description provided for @deliveries.
  ///
  /// In en, this message translates to:
  /// **'Deliveries'**
  String get deliveries;

  /// No description provided for @tankers.
  ///
  /// In en, this message translates to:
  /// **'Tankers'**
  String get tankers;

  /// No description provided for @businessDetails.
  ///
  /// In en, this message translates to:
  /// **'Business Details'**
  String get businessDetails;

  /// No description provided for @addressLabel.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get addressLabel;

  /// No description provided for @vendorId.
  ///
  /// In en, this message translates to:
  /// **'Vendor ID'**
  String get vendorId;

  /// No description provided for @noAddress.
  ///
  /// In en, this message translates to:
  /// **'No Address'**
  String get noAddress;

  /// No description provided for @profileSaved.
  ///
  /// In en, this message translates to:
  /// **'Profile saved'**
  String get profileSaved;

  /// No description provided for @profileSavedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Profile saved successfully'**
  String get profileSavedSuccessfully;

  /// No description provided for @saveFailed.
  ///
  /// In en, this message translates to:
  /// **'Save failed'**
  String get saveFailed;

  /// No description provided for @photoUpdated.
  ///
  /// In en, this message translates to:
  /// **'Photo updated'**
  String get photoUpdated;

  /// No description provided for @profilePhotoUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile photo updated'**
  String get profilePhotoUpdated;

  /// No description provided for @photoUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Photo upload failed'**
  String get photoUploadFailed;

  /// No description provided for @photoRemoved.
  ///
  /// In en, this message translates to:
  /// **'Photo removed'**
  String get photoRemoved;

  /// No description provided for @removeFailed.
  ///
  /// In en, this message translates to:
  /// **'Remove failed'**
  String get removeFailed;

  /// No description provided for @logoutFailed.
  ///
  /// In en, this message translates to:
  /// **'Logout failed'**
  String get logoutFailed;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get currentPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @updatePassword.
  ///
  /// In en, this message translates to:
  /// **'Update Password'**
  String get updatePassword;

  /// No description provided for @wardAdminUpper.
  ///
  /// In en, this message translates to:
  /// **'WARD ADMIN'**
  String get wardAdminUpper;

  /// No description provided for @noWardCanPostAll.
  ///
  /// In en, this message translates to:
  /// **'No Ward (can post to all wards)'**
  String get noWardCanPostAll;

  /// No description provided for @personalDetailsUpper.
  ///
  /// In en, this message translates to:
  /// **'PERSONAL DETAILS'**
  String get personalDetailsUpper;

  /// No description provided for @emailAddressUpper.
  ///
  /// In en, this message translates to:
  /// **'EMAIL ADDRESS'**
  String get emailAddressUpper;

  /// No description provided for @newSchedule.
  ///
  /// In en, this message translates to:
  /// **'New Schedule'**
  String get newSchedule;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @manualEntry.
  ///
  /// In en, this message translates to:
  /// **'Manual Entry'**
  String get manualEntry;

  /// No description provided for @uploadFile.
  ///
  /// In en, this message translates to:
  /// **'Upload File'**
  String get uploadFile;

  /// No description provided for @dragDropOrTapToUpload.
  ///
  /// In en, this message translates to:
  /// **'Drag and drop or tap to upload'**
  String get dragDropOrTapToUpload;

  /// No description provided for @selectScheduleFileToBegin.
  ///
  /// In en, this message translates to:
  /// **'Select your schedule file to begin'**
  String get selectScheduleFileToBegin;

  /// No description provided for @locationDetails.
  ///
  /// In en, this message translates to:
  /// **'Location Details'**
  String get locationDetails;

  /// No description provided for @wardNumber.
  ///
  /// In en, this message translates to:
  /// **'WARD NUMBER'**
  String get wardNumber;

  /// No description provided for @selectWard.
  ///
  /// In en, this message translates to:
  /// **'Select Ward'**
  String get selectWard;

  /// No description provided for @affectedAreasUpper.
  ///
  /// In en, this message translates to:
  /// **'AFFECTED AREAS'**
  String get affectedAreasUpper;

  /// No description provided for @affectedAreasHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Galli No. 5, Main Chowk...\\nSeparate with commas'**
  String get affectedAreasHint;

  /// No description provided for @dateTime.
  ///
  /// In en, this message translates to:
  /// **'Date & Time'**
  String get dateTime;

  /// No description provided for @supplyDateUpper.
  ///
  /// In en, this message translates to:
  /// **'SUPPLY DATE'**
  String get supplyDateUpper;

  /// No description provided for @startTimeUpper.
  ///
  /// In en, this message translates to:
  /// **'START TIME'**
  String get startTimeUpper;

  /// No description provided for @endTimeUpper.
  ///
  /// In en, this message translates to:
  /// **'END TIME'**
  String get endTimeUpper;

  /// No description provided for @notifyResidents.
  ///
  /// In en, this message translates to:
  /// **'Notify Residents'**
  String get notifyResidents;

  /// No description provided for @alertAffectedUsers.
  ///
  /// In en, this message translates to:
  /// **'Alert affected users'**
  String get alertAffectedUsers;

  /// No description provided for @preview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get preview;

  /// No description provided for @publishArrow.
  ///
  /// In en, this message translates to:
  /// **'Publish →'**
  String get publishArrow;

  /// No description provided for @scheduleFillAllRequiredFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill all required fields'**
  String get scheduleFillAllRequiredFields;

  /// No description provided for @schedulePublishedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Schedule published successfully!'**
  String get schedulePublishedSuccessfully;

  /// No description provided for @errorLabel.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get errorLabel;

  /// No description provided for @pleaseSelectAFile.
  ///
  /// In en, this message translates to:
  /// **'Please select a file'**
  String get pleaseSelectAFile;

  /// No description provided for @fileUploadNotImplementedYet.
  ///
  /// In en, this message translates to:
  /// **'File upload not implemented yet'**
  String get fileUploadNotImplementedYet;

  /// No description provided for @schedulePreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Schedule Preview'**
  String get schedulePreviewTitle;

  /// No description provided for @schedulePreviewSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This is how residents will see your schedule'**
  String get schedulePreviewSubtitle;

  /// No description provided for @waterSupplyScheduleTitle.
  ///
  /// In en, this message translates to:
  /// **'Water Supply Schedule'**
  String get waterSupplyScheduleTitle;

  /// No description provided for @affectedAreas.
  ///
  /// In en, this message translates to:
  /// **'Affected Areas'**
  String get affectedAreas;

  /// No description provided for @supplyDate.
  ///
  /// In en, this message translates to:
  /// **'Supply Date'**
  String get supplyDate;

  /// No description provided for @startTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Start Time'**
  String get startTimeLabel;

  /// No description provided for @endTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'End Time'**
  String get endTimeLabel;

  /// No description provided for @notSelected.
  ///
  /// In en, this message translates to:
  /// **'Not selected'**
  String get notSelected;

  /// No description provided for @notSpecified.
  ///
  /// In en, this message translates to:
  /// **'Not specified'**
  String get notSpecified;

  /// No description provided for @residentsWillBeNotified.
  ///
  /// In en, this message translates to:
  /// **'Residents will be notified'**
  String get residentsWillBeNotified;

  /// No description provided for @noNotificationsWillBeSent.
  ///
  /// In en, this message translates to:
  /// **'No notifications will be sent'**
  String get noNotificationsWillBeSent;

  /// No description provided for @closePreview.
  ///
  /// In en, this message translates to:
  /// **'Close Preview'**
  String get closePreview;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ne'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ne':
      return AppLocalizationsNe();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
