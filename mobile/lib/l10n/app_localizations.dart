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
  /// **'Email Address'**
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
  /// **'Start: {time}'**
  String startTimeLabel(String time);

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

  /// No description provided for @sendNotice.
  ///
  /// In en, this message translates to:
  /// **'Send Notice'**
  String get sendNotice;

  /// No description provided for @noticeTypeHeader.
  ///
  /// In en, this message translates to:
  /// **'NOTICE TYPE'**
  String get noticeTypeHeader;

  /// No description provided for @noticeTypeGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get noticeTypeGeneral;

  /// No description provided for @noticeTypeEmergency.
  ///
  /// In en, this message translates to:
  /// **'Emergency'**
  String get noticeTypeEmergency;

  /// No description provided for @noticeTypeMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get noticeTypeMaintenance;

  /// No description provided for @noticeContent.
  ///
  /// In en, this message translates to:
  /// **'Notice Content'**
  String get noticeContent;

  /// No description provided for @noticeTitleHeader.
  ///
  /// In en, this message translates to:
  /// **'NOTICE TITLE'**
  String get noticeTitleHeader;

  /// No description provided for @noticeTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get noticeTitleLabel;

  /// No description provided for @noticeTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Weekly Tanker Schedule Update'**
  String get noticeTitleHint;

  /// No description provided for @messageHeader.
  ///
  /// In en, this message translates to:
  /// **'MESSAGE'**
  String get messageHeader;

  /// No description provided for @message.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get message;

  /// No description provided for @noticeMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Type your announcement details here...'**
  String get noticeMessageHint;

  /// No description provided for @highPriority.
  ///
  /// In en, this message translates to:
  /// **'High Priority'**
  String get highPriority;

  /// No description provided for @noticeHighPrioritySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Mark notice as urgent'**
  String get noticeHighPrioritySubtitle;

  /// No description provided for @pushNotification.
  ///
  /// In en, this message translates to:
  /// **'Push Notification'**
  String get pushNotification;

  /// No description provided for @noticePushNotificationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Send instant alert to devices'**
  String get noticePushNotificationSubtitle;

  /// No description provided for @confirmAndSend.
  ///
  /// In en, this message translates to:
  /// **'Confirm & Send'**
  String get confirmAndSend;

  /// No description provided for @sendArrow.
  ///
  /// In en, this message translates to:
  /// **'Send →'**
  String get sendArrow;

  /// No description provided for @sending.
  ///
  /// In en, this message translates to:
  /// **'Sending...'**
  String get sending;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @audience.
  ///
  /// In en, this message translates to:
  /// **'Audience'**
  String get audience;

  /// No description provided for @noticeAudienceEveryone.
  ///
  /// In en, this message translates to:
  /// **'Everyone (Residents + Vendors)'**
  String get noticeAudienceEveryone;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @noticeValidationRequired.
  ///
  /// In en, this message translates to:
  /// **'Title and message are required'**
  String get noticeValidationRequired;

  /// No description provided for @noticeSentToEveryone.
  ///
  /// In en, this message translates to:
  /// **'Notice sent to everyone'**
  String get noticeSentToEveryone;

  /// No description provided for @noticeFailedToSend.
  ///
  /// In en, this message translates to:
  /// **'Failed to send: {msg}'**
  String noticeFailedToSend(String msg);

  /// No description provided for @noticeErrorSending.
  ///
  /// In en, this message translates to:
  /// **'Error sending notice: {error}'**
  String noticeErrorSending(String error);

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Hamro Pani'**
  String get appName;

  /// No description provided for @wardAdmin.
  ///
  /// In en, this message translates to:
  /// **'Ward Admin'**
  String get wardAdmin;

  /// No description provided for @namaste.
  ///
  /// In en, this message translates to:
  /// **'Namaste, {name}'**
  String namaste(String name);

  /// No description provided for @recentOverview.
  ///
  /// In en, this message translates to:
  /// **'Here is your recent overview.'**
  String get recentOverview;

  /// No description provided for @supplyStatus.
  ///
  /// In en, this message translates to:
  /// **'Supply Status'**
  String get supplyStatus;

  /// No description provided for @normalFlow.
  ///
  /// In en, this message translates to:
  /// **'Normal Flow'**
  String get normalFlow;

  /// No description provided for @activeDistribution.
  ///
  /// In en, this message translates to:
  /// **'Active Distribution'**
  String get activeDistribution;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @postSchedule.
  ///
  /// In en, this message translates to:
  /// **'Post Schedule'**
  String get postSchedule;

  /// No description provided for @updateTimings.
  ///
  /// In en, this message translates to:
  /// **'Update timings'**
  String get updateTimings;

  /// No description provided for @announceUpdates.
  ///
  /// In en, this message translates to:
  /// **'Announce updates'**
  String get announceUpdates;

  /// No description provided for @recentUpdatesMySchedules.
  ///
  /// In en, this message translates to:
  /// **'Recent Updates (My Schedules)'**
  String get recentUpdatesMySchedules;

  /// No description provided for @noSchedulesPostedYet.
  ///
  /// In en, this message translates to:
  /// **'No schedules posted by you yet.'**
  String get noSchedulesPostedYet;

  /// No description provided for @schedulePostedWard.
  ///
  /// In en, this message translates to:
  /// **'Schedule Posted – {wardName}'**
  String schedulePostedWard(String wardName);

  /// No description provided for @postedByYouTapToOpen.
  ///
  /// In en, this message translates to:
  /// **'Posted by you • Tap to open'**
  String get postedByYouTapToOpen;

  /// No description provided for @scheduleDetails.
  ///
  /// In en, this message translates to:
  /// **'Schedule Details'**
  String get scheduleDetails;

  /// No description provided for @scheduleId.
  ///
  /// In en, this message translates to:
  /// **'Schedule ID'**
  String get scheduleId;

  /// No description provided for @ward.
  ///
  /// In en, this message translates to:
  /// **'Ward'**
  String get ward;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @createdAt.
  ///
  /// In en, this message translates to:
  /// **'Created At'**
  String get createdAt;

  /// No description provided for @updatedAt.
  ///
  /// In en, this message translates to:
  /// **'Updated At'**
  String get updatedAt;

  /// No description provided for @postedBy.
  ///
  /// In en, this message translates to:
  /// **'Posted by'**
  String get postedBy;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @fullPostData.
  ///
  /// In en, this message translates to:
  /// **'Full post data'**
  String get fullPostData;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @dashboardLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Dashboard load failed: {error}'**
  String dashboardLoadFailed(String error);

  /// No description provided for @openingReports.
  ///
  /// In en, this message translates to:
  /// **'Opening Reports...'**
  String get openingReports;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @schedules.
  ///
  /// In en, this message translates to:
  /// **'Schedules'**
  String get schedules;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @technicalDetails.
  ///
  /// In en, this message translates to:
  /// **'Technical details'**
  String get technicalDetails;

  /// No description provided for @show.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get show;

  /// No description provided for @hide.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get hide;

  /// No description provided for @vendorCompany.
  ///
  /// In en, this message translates to:
  /// **'Vendor Company'**
  String get vendorCompany;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @newNotification.
  ///
  /// In en, this message translates to:
  /// **'New notification'**
  String get newNotification;

  /// No description provided for @todaysJobs.
  ///
  /// In en, this message translates to:
  /// **'Today\'s jobs'**
  String get todaysJobs;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @rating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get rating;

  /// No description provided for @activeRoutes.
  ///
  /// In en, this message translates to:
  /// **'Active Routes'**
  String get activeRoutes;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @noActiveRoutes.
  ///
  /// In en, this message translates to:
  /// **'No active routes'**
  String get noActiveRoutes;

  /// No description provided for @noActiveRoutesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your slot will appear here only during its time window.'**
  String get noActiveRoutesSubtitle;

  /// No description provided for @recentRequests.
  ///
  /// In en, this message translates to:
  /// **'Recent Requests'**
  String get recentRequests;

  /// No description provided for @noRequests.
  ///
  /// In en, this message translates to:
  /// **'No requests'**
  String get noRequests;

  /// No description provided for @noRequestsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Only requests from the last 24 hours will appear here.'**
  String get noRequestsSubtitle;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @decline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get decline;

  /// No description provided for @route.
  ///
  /// In en, this message translates to:
  /// **'Route'**
  String get route;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @routes.
  ///
  /// In en, this message translates to:
  /// **'Routes'**
  String get routes;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @bookingUpdated.
  ///
  /// In en, this message translates to:
  /// **'Booking updated: {status}'**
  String bookingUpdated(String status);

  /// No description provided for @updateFailed.
  ///
  /// In en, this message translates to:
  /// **'Update failed: {error}'**
  String updateFailed(String error);

  /// No description provided for @locationLabel.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String locationLabel(String location);

  /// No description provided for @startLabel.
  ///
  /// In en, this message translates to:
  /// **'Start: {time}'**
  String startLabel(String time);

  /// No description provided for @endLabel.
  ///
  /// In en, this message translates to:
  /// **'End: {time}'**
  String endLabel(String time);

  /// No description provided for @percentBooked.
  ///
  /// In en, this message translates to:
  /// **'{percent}% Booked'**
  String percentBooked(int percent);

  /// No description provided for @deliveryHistory.
  ///
  /// In en, this message translates to:
  /// **'Delivery History'**
  String get deliveryHistory;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @totalDeliveries.
  ///
  /// In en, this message translates to:
  /// **'Total deliveries'**
  String get totalDeliveries;

  /// No description provided for @totalEarnings.
  ///
  /// In en, this message translates to:
  /// **'Total earnings'**
  String get totalEarnings;

  /// No description provided for @avgRating.
  ///
  /// In en, this message translates to:
  /// **'Avg rating'**
  String get avgRating;

  /// No description provided for @nprAmount.
  ///
  /// In en, this message translates to:
  /// **'NPR {amount}'**
  String nprAmount(String amount);

  /// No description provided for @statusDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get statusDelivered;

  /// No description provided for @statusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPending;

  /// No description provided for @notApplicable.
  ///
  /// In en, this message translates to:
  /// **'Not applicable'**
  String get notApplicable;

  /// No description provided for @liters.
  ///
  /// In en, this message translates to:
  /// **'{liters} L'**
  String liters(int liters);

  /// No description provided for @loadFailed.
  ///
  /// In en, this message translates to:
  /// **'Load failed: {error}'**
  String loadFailed(String error);

  /// No description provided for @manageSlots.
  ///
  /// In en, this message translates to:
  /// **'Manage Slots'**
  String get manageSlots;

  /// No description provided for @openNewSlot.
  ///
  /// In en, this message translates to:
  /// **'Open New Slot'**
  String get openNewSlot;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get selectDate;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @tomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get tomorrow;

  /// No description provided for @endTime.
  ///
  /// In en, this message translates to:
  /// **'End time'**
  String get endTime;

  /// No description provided for @tankerCapacityLiters.
  ///
  /// In en, this message translates to:
  /// **'Tanker capacity (liters)'**
  String get tankerCapacityLiters;

  /// No description provided for @totalBookingSlots.
  ///
  /// In en, this message translates to:
  /// **'Total booking slots'**
  String get totalBookingSlots;

  /// No description provided for @bookingSlots.
  ///
  /// In en, this message translates to:
  /// **'Booking slots'**
  String get bookingSlots;

  /// No description provided for @priceNpr.
  ///
  /// In en, this message translates to:
  /// **'Price (NPR)'**
  String get priceNpr;

  /// No description provided for @deliveryRouteArea.
  ///
  /// In en, this message translates to:
  /// **'Delivery route / area'**
  String get deliveryRouteArea;

  /// No description provided for @deliveryRouteHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Maitidevi, Ward 29'**
  String get deliveryRouteHint;

  /// No description provided for @publishSlotArrow.
  ///
  /// In en, this message translates to:
  /// **'Publish Slot →'**
  String get publishSlotArrow;

  /// No description provided for @slotPublishedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Slot published successfully'**
  String get slotPublishedSuccessfully;

  /// No description provided for @cannotPublishSlot.
  ///
  /// In en, this message translates to:
  /// **'Cannot Publish Slot'**
  String get cannotPublishSlot;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @activeSlots.
  ///
  /// In en, this message translates to:
  /// **'Active Slots'**
  String get activeSlots;

  /// No description provided for @noActiveSlots.
  ///
  /// In en, this message translates to:
  /// **'No active slots'**
  String get noActiveSlots;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'OPEN'**
  String get open;

  /// No description provided for @full.
  ///
  /// In en, this message translates to:
  /// **'FULL'**
  String get full;

  /// No description provided for @editSlot.
  ///
  /// In en, this message translates to:
  /// **'Edit Slot'**
  String get editSlot;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @invalidInputs.
  ///
  /// In en, this message translates to:
  /// **'Invalid inputs'**
  String get invalidInputs;

  /// No description provided for @slotUpdated.
  ///
  /// In en, this message translates to:
  /// **'Slot updated'**
  String get slotUpdated;

  /// No description provided for @markFull.
  ///
  /// In en, this message translates to:
  /// **'Mark Full'**
  String get markFull;

  /// No description provided for @markedFull.
  ///
  /// In en, this message translates to:
  /// **'Marked full'**
  String get markedFull;

  /// No description provided for @slotCancelled.
  ///
  /// In en, this message translates to:
  /// **'Slot cancelled'**
  String get slotCancelled;

  /// No description provided for @slotsLabel.
  ///
  /// In en, this message translates to:
  /// **'Slots: {count}'**
  String slotsLabel(int count);

  /// No description provided for @tankerLabel.
  ///
  /// In en, this message translates to:
  /// **'Tanker: {liters}L'**
  String tankerLabel(int liters);

  /// No description provided for @priceLabel.
  ///
  /// In en, this message translates to:
  /// **'Price: {priceText}'**
  String priceLabel(String priceText);

  /// No description provided for @bookedCount.
  ///
  /// In en, this message translates to:
  /// **'{booked}/{total} booked'**
  String bookedCount(int booked, int total);

  /// No description provided for @availablePercent.
  ///
  /// In en, this message translates to:
  /// **'{percent}% available'**
  String availablePercent(int percent);

  /// No description provided for @startTime.
  ///
  /// In en, this message translates to:
  /// **'Start time'**
  String get startTime;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @markAllAsRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get markAllAsRead;

  /// No description provided for @markedAllAsRead.
  ///
  /// In en, this message translates to:
  /// **'Marked all as read'**
  String get markedAllAsRead;

  /// No description provided for @failedWithError.
  ///
  /// In en, this message translates to:
  /// **'Failed: {error}'**
  String failedWithError(String error);

  /// No description provided for @tabAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get tabAll;

  /// No description provided for @tabUnread.
  ///
  /// In en, this message translates to:
  /// **'Unread ({count})'**
  String tabUnread(int count);

  /// No description provided for @tabOrders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get tabOrders;

  /// No description provided for @tabSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get tabSystem;

  /// No description provided for @noNotificationsYet.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get noNotificationsYet;

  /// No description provided for @notificationsEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ll notify you when something new arrives'**
  String get notificationsEmptySubtitle;

  /// No description provided for @notificationsEnd.
  ///
  /// In en, this message translates to:
  /// **'You\'ve reached the end of your notifications'**
  String get notificationsEnd;

  /// No description provided for @wardNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Ward: {ward}'**
  String wardNameLabel(String ward);

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} min ago'**
  String minutesAgo(int count);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} hrs ago'**
  String hoursAgo(int count);

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} days ago'**
  String daysAgo(int count);

  /// No description provided for @wardNotSet.
  ///
  /// In en, this message translates to:
  /// **'Ward not set'**
  String get wardNotSet;

  /// No description provided for @cityWard.
  ///
  /// In en, this message translates to:
  /// **'{city}, Ward {number}'**
  String cityWard(String city, String number);

  /// No description provided for @todaysSupply.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Supply'**
  String get todaysSupply;

  /// No description provided for @onSchedule.
  ///
  /// In en, this message translates to:
  /// **'On Schedule'**
  String get onSchedule;

  /// No description provided for @nextSupply.
  ///
  /// In en, this message translates to:
  /// **'Next Supply'**
  String get nextSupply;

  /// No description provided for @expectedDurationHours.
  ///
  /// In en, this message translates to:
  /// **'Expected duration: {hours} hours'**
  String expectedDurationHours(int hours);

  /// No description provided for @bookTanker.
  ///
  /// In en, this message translates to:
  /// **'Book Tanker'**
  String get bookTanker;

  /// No description provided for @nearbyTankers.
  ///
  /// In en, this message translates to:
  /// **'Nearby Tankers'**
  String get nearbyTankers;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @noTankersAvailableNow.
  ///
  /// In en, this message translates to:
  /// **'No tankers available right now'**
  String get noTankersAvailableNow;

  /// No description provided for @yourReports.
  ///
  /// In en, this message translates to:
  /// **'Your Reports'**
  String get yourReports;

  /// No description provided for @noReportsYet.
  ///
  /// In en, this message translates to:
  /// **'No reports yet'**
  String get noReportsYet;

  /// No description provided for @issue.
  ///
  /// In en, this message translates to:
  /// **'Issue'**
  String get issue;

  /// No description provided for @inReview.
  ///
  /// In en, this message translates to:
  /// **'In Review'**
  String get inReview;

  /// No description provided for @ticketWithDate.
  ///
  /// In en, this message translates to:
  /// **'Ticket #{ticket} • {dateLabel}'**
  String ticketWithDate(String ticket, String dateLabel);

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get noNotifications;

  /// No description provided for @findTankersTitle.
  ///
  /// In en, this message translates to:
  /// **'Find Tankers'**
  String get findTankersTitle;

  /// No description provided for @searchTankersHint.
  ///
  /// In en, this message translates to:
  /// **'Search by area or vendor name...'**
  String get searchTankersHint;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterAvailableNow.
  ///
  /// In en, this message translates to:
  /// **'Available Now'**
  String get filterAvailableNow;

  /// No description provided for @filterLowStock.
  ///
  /// In en, this message translates to:
  /// **'Low Stock'**
  String get filterLowStock;

  /// No description provided for @currentDemandHigh.
  ///
  /// In en, this message translates to:
  /// **'Current Demand is High'**
  String get currentDemandHigh;

  /// No description provided for @demandMessageAvailableNow.
  ///
  /// In en, this message translates to:
  /// **'Many residents are booking now.\nReserve your slot early.'**
  String get demandMessageAvailableNow;

  /// No description provided for @peakHoursLabel.
  ///
  /// In en, this message translates to:
  /// **'Peak Hours: {range}'**
  String peakHoursLabel(String range);

  /// No description provided for @nearbyVendors.
  ///
  /// In en, this message translates to:
  /// **'Nearby Vendors'**
  String get nearbyVendors;

  /// No description provided for @viewMap.
  ///
  /// In en, this message translates to:
  /// **'View Map'**
  String get viewMap;

  /// No description provided for @noVendorsFound.
  ///
  /// In en, this message translates to:
  /// **'No vendors found'**
  String get noVendorsFound;

  /// No description provided for @tryDifferentSearch.
  ///
  /// In en, this message translates to:
  /// **'Try changing your search or filter and try again.'**
  String get tryDifferentSearch;

  /// No description provided for @tankerStatusAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get tankerStatusAvailable;

  /// No description provided for @tankerStatusBusy.
  ///
  /// In en, this message translates to:
  /// **'Busy'**
  String get tankerStatusBusy;

  /// No description provided for @tankerStatusLowStock.
  ///
  /// In en, this message translates to:
  /// **'Low stock'**
  String get tankerStatusLowStock;

  /// No description provided for @slotsUsedLabel.
  ///
  /// In en, this message translates to:
  /// **'{used}/{total} Slots'**
  String slotsUsedLabel(int used, int total);

  /// No description provided for @nextLabel.
  ///
  /// In en, this message translates to:
  /// **'Next: {time}'**
  String nextLabel(String time);

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// No description provided for @bookedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Booked successfully'**
  String get bookedSuccessfully;

  /// No description provided for @vendorDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Vendor Details'**
  String get vendorDetailsTitle;

  /// No description provided for @verified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verified;

  /// No description provided for @slotDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Slot Details'**
  String get slotDetailsTitle;

  /// No description provided for @paymentMethodTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get paymentMethodTitle;

  /// No description provided for @booking.
  ///
  /// In en, this message translates to:
  /// **'Booking'**
  String get booking;

  /// No description provided for @tanker.
  ///
  /// In en, this message translates to:
  /// **'Tanker'**
  String get tanker;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @cash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get cash;

  /// No description provided for @esewa.
  ///
  /// In en, this message translates to:
  /// **'eSewa'**
  String get esewa;

  /// No description provided for @confirmBookingArrow.
  ///
  /// In en, this message translates to:
  /// **'Confirm Booking →'**
  String get confirmBookingArrow;

  /// No description provided for @noSlotAvailable.
  ///
  /// In en, this message translates to:
  /// **'No Slot Available'**
  String get noSlotAvailable;

  /// No description provided for @immediateDispatchAvailable.
  ///
  /// In en, this message translates to:
  /// **'Immediate dispatch available'**
  String get immediateDispatchAvailable;

  /// No description provided for @paymentCancelled.
  ///
  /// In en, this message translates to:
  /// **'Payment cancelled'**
  String get paymentCancelled;

  /// No description provided for @bookingFailedWithError.
  ///
  /// In en, this message translates to:
  /// **'Booking failed: {error}'**
  String bookingFailedWithError(String error);

  /// No description provided for @esewaProductName.
  ///
  /// In en, this message translates to:
  /// **'Hamro Pani Tanker Booking'**
  String get esewaProductName;

  /// No description provided for @pricePerTanker.
  ///
  /// In en, this message translates to:
  /// **'NPR {price}/tanker'**
  String pricePerTanker(int price);

  /// No description provided for @paymentReceiptTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment Receipt'**
  String get paymentReceiptTitle;

  /// No description provided for @failedToLoadReceipt.
  ///
  /// In en, this message translates to:
  /// **'Failed to load receipt'**
  String get failedToLoadReceipt;

  /// No description provided for @paymentSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Payment Successful'**
  String get paymentSuccessful;

  /// No description provided for @thankYouForPurchase.
  ///
  /// In en, this message translates to:
  /// **'Thank you for your purchase!'**
  String get thankYouForPurchase;

  /// No description provided for @transactionId.
  ///
  /// In en, this message translates to:
  /// **'Transaction ID'**
  String get transactionId;

  /// No description provided for @dateAndTime.
  ///
  /// In en, this message translates to:
  /// **'Date & Time'**
  String get dateAndTime;

  /// No description provided for @paymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get paymentMethod;

  /// No description provided for @recipient.
  ///
  /// In en, this message translates to:
  /// **'Recipient'**
  String get recipient;

  /// No description provided for @service.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get service;

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// No description provided for @downloadPdf.
  ///
  /// In en, this message translates to:
  /// **'Download PDF'**
  String get downloadPdf;

  /// No description provided for @saveCopyForRecords.
  ///
  /// In en, this message translates to:
  /// **'Save a copy for your records.'**
  String get saveCopyForRecords;

  /// No description provided for @downloadReceipt.
  ///
  /// In en, this message translates to:
  /// **'Download Receipt'**
  String get downloadReceipt;

  /// No description provided for @saveCancelled.
  ///
  /// In en, this message translates to:
  /// **'Save cancelled'**
  String get saveCancelled;

  /// No description provided for @receiptSaved.
  ///
  /// In en, this message translates to:
  /// **'Receipt saved: {path}'**
  String receiptSaved(String path);

  /// No description provided for @saveFailedWithError.
  ///
  /// In en, this message translates to:
  /// **'Save failed: {error}'**
  String saveFailedWithError(String error);

  /// No description provided for @backToHome.
  ///
  /// In en, this message translates to:
  /// **'Back to Home'**
  String get backToHome;

  /// No description provided for @litersShort.
  ///
  /// In en, this message translates to:
  /// **'{liters} Ltr'**
  String litersShort(int liters);

  /// No description provided for @whatsTheProblem.
  ///
  /// In en, this message translates to:
  /// **'What\'s the problem?'**
  String get whatsTheProblem;

  /// No description provided for @describeIssueHint.
  ///
  /// In en, this message translates to:
  /// **'Please describe the issue in detail...'**
  String get describeIssueHint;

  /// No description provided for @selectedLocationLabel.
  ///
  /// In en, this message translates to:
  /// **'Selected\n{location}'**
  String selectedLocationLabel(String location);

  /// No description provided for @selected.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get selected;

  /// No description provided for @pickOnMap.
  ///
  /// In en, this message translates to:
  /// **'Pick on map'**
  String get pickOnMap;

  /// No description provided for @locationNotSet.
  ///
  /// In en, this message translates to:
  /// **'Location not set'**
  String get locationNotSet;

  /// No description provided for @photoEvidence.
  ///
  /// In en, this message translates to:
  /// **'Photo Evidence'**
  String get photoEvidence;

  /// No description provided for @addPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add Photo'**
  String get addPhoto;

  /// No description provided for @photosCount.
  ///
  /// In en, this message translates to:
  /// **'{count}/{max}'**
  String photosCount(int count, int max);

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get chooseFromGallery;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhoto;

  /// No description provided for @reportInfoHint.
  ///
  /// In en, this message translates to:
  /// **'Once submitted, your ticket status will be trackable in the History tab.'**
  String get reportInfoHint;

  /// No description provided for @submitReportArrow.
  ///
  /// In en, this message translates to:
  /// **'Submit Report →'**
  String get submitReportArrow;

  /// No description provided for @issueMissedDelivery.
  ///
  /// In en, this message translates to:
  /// **'Missed Delivery'**
  String get issueMissedDelivery;

  /// No description provided for @issuePoorQuality.
  ///
  /// In en, this message translates to:
  /// **'Poor Quality'**
  String get issuePoorQuality;

  /// No description provided for @issueSevereDelay.
  ///
  /// In en, this message translates to:
  /// **'Severe Delay'**
  String get issueSevereDelay;

  /// No description provided for @selectIssueAndDescription.
  ///
  /// In en, this message translates to:
  /// **'Please select an issue type and enter description.'**
  String get selectIssueAndDescription;

  /// No description provided for @pickLocationFromMap.
  ///
  /// In en, this message translates to:
  /// **'Please pick a location from map.'**
  String get pickLocationFromMap;

  /// No description provided for @reportSubmittedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Report submitted successfully'**
  String get reportSubmittedSuccessfully;

  /// No description provided for @submitFailedWithError.
  ///
  /// In en, this message translates to:
  /// **'Submit failed: {error}'**
  String submitFailedWithError(String error);

  /// No description provided for @myBookingsTitle.
  ///
  /// In en, this message translates to:
  /// **'My Bookings'**
  String get myBookingsTitle;

  /// No description provided for @bookingStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get bookingStatusCompleted;

  /// No description provided for @bookingStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get bookingStatusCancelled;

  /// No description provided for @bookingStatusConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get bookingStatusConfirmed;

  /// No description provided for @bookingStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get bookingStatusPending;

  /// No description provided for @rebook.
  ///
  /// In en, this message translates to:
  /// **'Re-book'**
  String get rebook;

  /// No description provided for @bookingDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Booking Detail'**
  String get bookingDetailTitle;

  /// No description provided for @complaintDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Complaint Detail'**
  String get complaintDetailTitle;

  /// No description provided for @failedToLoad.
  ///
  /// In en, this message translates to:
  /// **'Failed to load'**
  String get failedToLoad;

  /// No description provided for @bookingNumberTitle.
  ///
  /// In en, this message translates to:
  /// **'Booking #{id}'**
  String bookingNumberTitle(int id);

  /// No description provided for @complaintNumberTitle.
  ///
  /// In en, this message translates to:
  /// **'Complaint #{id}'**
  String complaintNumberTitle(int id);

  /// No description provided for @bookingNumberLine.
  ///
  /// In en, this message translates to:
  /// **'Booking #{id}'**
  String bookingNumberLine(int id);

  /// No description provided for @bookingSlotsLabel.
  ///
  /// In en, this message translates to:
  /// **'Booking slots: {used}/{total}'**
  String bookingSlotsLabel(int used, int total);

  /// No description provided for @trackingTitle.
  ///
  /// In en, this message translates to:
  /// **'Tracking'**
  String get trackingTitle;

  /// No description provided for @noTrackingHistoryYet.
  ///
  /// In en, this message translates to:
  /// **'No tracking history yet.'**
  String get noTrackingHistoryYet;

  /// No description provided for @statusWithWhen.
  ///
  /// In en, this message translates to:
  /// **'{status} • {when}'**
  String statusWithWhen(String status, String when);

  /// No description provided for @complaintStatusResolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get complaintStatusResolved;

  /// No description provided for @complaintStatusInReview.
  ///
  /// In en, this message translates to:
  /// **'In review'**
  String get complaintStatusInReview;

  /// No description provided for @complaintStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get complaintStatusRejected;

  /// No description provided for @complaintStatusOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get complaintStatusOpen;

  /// No description provided for @photos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get photos;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Kathmandu\'s Smart Water Management'**
  String get appTagline;

  /// No description provided for @roleResident.
  ///
  /// In en, this message translates to:
  /// **'Resident'**
  String get roleResident;

  /// No description provided for @roleVendor.
  ///
  /// In en, this message translates to:
  /// **'Vendor'**
  String get roleVendor;

  /// No description provided for @roleWardAdmin.
  ///
  /// In en, this message translates to:
  /// **'Ward Admin'**
  String get roleWardAdmin;

  /// No description provided for @langEnglishShort.
  ///
  /// In en, this message translates to:
  /// **'EN'**
  String get langEnglishShort;

  /// No description provided for @langNepaliShort.
  ///
  /// In en, this message translates to:
  /// **'NP'**
  String get langNepaliShort;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBack;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get emailHint;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get passwordHint;

  /// No description provided for @forgotPasswordShort.
  ///
  /// In en, this message translates to:
  /// **'Forgot?'**
  String get forgotPasswordShort;

  /// No description provided for @signInArrow.
  ///
  /// In en, this message translates to:
  /// **'Sign In →'**
  String get signInArrow;

  /// No description provided for @orContinueWith.
  ///
  /// In en, this message translates to:
  /// **'Or continue with'**
  String get orContinueWith;

  /// No description provided for @google.
  ///
  /// In en, this message translates to:
  /// **'Google'**
  String get google;

  /// No description provided for @noAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get noAccount;

  /// No description provided for @signUpNow.
  ///
  /// In en, this message translates to:
  /// **'Sign up now'**
  String get signUpNow;

  /// No description provided for @enterEmailAndPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter email and password'**
  String get enterEmailAndPassword;

  /// No description provided for @firebaseUserNotFound.
  ///
  /// In en, this message translates to:
  /// **'Firebase user not found'**
  String get firebaseUserNotFound;

  /// No description provided for @failedToGetIdToken.
  ///
  /// In en, this message translates to:
  /// **'Failed to get Firebase ID token'**
  String get failedToGetIdToken;

  /// No description provided for @signupTitle.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get signupTitle;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @fullNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get fullNameHint;

  /// No description provided for @phoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Mobile Number'**
  String get phoneLabel;

  /// No description provided for @phoneHint.
  ///
  /// In en, this message translates to:
  /// **'+977 98XXXXXXXX'**
  String get phoneHint;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPasswordLabel;

  /// No description provided for @confirmPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your password again'**
  String get confirmPasswordHint;

  /// No description provided for @fillAllFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill all fields'**
  String get fillAllFields;

  /// No description provided for @invalidEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get invalidEmailAddress;

  /// No description provided for @passwordsDoNotMatchMsg.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatchMsg;

  /// No description provided for @agreeToTermsRequired.
  ///
  /// In en, this message translates to:
  /// **'Please agree to Terms & Conditions'**
  String get agreeToTermsRequired;

  /// No description provided for @signupFailedFirebaseNull.
  ///
  /// In en, this message translates to:
  /// **'Signup failed: Firebase user is null'**
  String get signupFailedFirebaseNull;

  /// No description provided for @signupFailedTokenNull.
  ///
  /// In en, this message translates to:
  /// **'Signup failed: Firebase token is null'**
  String get signupFailedTokenNull;

  /// No description provided for @backendRegisterFailed.
  ///
  /// In en, this message translates to:
  /// **'Backend register failed: {code}'**
  String backendRegisterFailed(int code);

  /// No description provided for @signupFailedWithError.
  ///
  /// In en, this message translates to:
  /// **'Signup failed: {error}'**
  String signupFailedWithError(String error);

  /// No description provided for @agreeToTermsText.
  ///
  /// In en, this message translates to:
  /// **'I agree to the Terms & Conditions and Privacy Policy.'**
  String get agreeToTermsText;

  /// No description provided for @haveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get haveAccount;

  /// No description provided for @loginNow.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get loginNow;

  /// No description provided for @signupButton.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signupButton;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password'**
  String get forgotPasswordTitle;

  /// No description provided for @resetYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset your password'**
  String get resetYourPassword;

  /// No description provided for @resetPasswordInstruction.
  ///
  /// In en, this message translates to:
  /// **'Enter your email and we will send a reset link to your email.'**
  String get resetPasswordInstruction;

  /// No description provided for @emailExampleHint.
  ///
  /// In en, this message translates to:
  /// **'name@example.com'**
  String get emailExampleHint;

  /// No description provided for @sendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send Reset Link'**
  String get sendResetLink;

  /// No description provided for @loginSuccess.
  ///
  /// In en, this message translates to:
  /// **'Logged in successfully'**
  String get loginSuccess;

  /// No description provided for @loginFailedWithError.
  ///
  /// In en, this message translates to:
  /// **'Login failed: {error}'**
  String loginFailedWithError(String error);

  /// No description provided for @accountCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Account created successfully'**
  String get accountCreatedSuccess;

  /// No description provided for @googleLoginSuccess.
  ///
  /// In en, this message translates to:
  /// **'Logged in with Google'**
  String get googleLoginSuccess;

  /// No description provided for @googleLoginFailedWithError.
  ///
  /// In en, this message translates to:
  /// **'Google login failed: {error}'**
  String googleLoginFailedWithError(String error);

  /// No description provided for @loginCancelled.
  ///
  /// In en, this message translates to:
  /// **'Login cancelled'**
  String get loginCancelled;

  /// No description provided for @enterEmailToReset.
  ///
  /// In en, this message translates to:
  /// **'Enter your email to reset password'**
  String get enterEmailToReset;

  /// No description provided for @passwordResetEmailSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset email sent'**
  String get passwordResetEmailSent;

  /// No description provided for @failedToSendResetEmail.
  ///
  /// In en, this message translates to:
  /// **'Failed to send reset email'**
  String get failedToSendResetEmail;

  /// No description provided for @bookingStatusDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get bookingStatusDelivered;

  /// No description provided for @confirmDeliveryTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm delivery'**
  String get confirmDeliveryTitle;

  /// No description provided for @confirmDeliveryAndRate.
  ///
  /// In en, this message translates to:
  /// **'Confirm Delivery & Rate'**
  String get confirmDeliveryAndRate;

  /// No description provided for @rateVendorPrompt.
  ///
  /// In en, this message translates to:
  /// **'Did you receive the water? Please rate the vendor.'**
  String get rateVendorPrompt;

  /// No description provided for @optionalCommentHint.
  ///
  /// In en, this message translates to:
  /// **'Optional comment...'**
  String get optionalCommentHint;

  /// No description provided for @thankYouForRating.
  ///
  /// In en, this message translates to:
  /// **'Thank you for your rating!'**
  String get thankYouForRating;

  /// No description provided for @yourRatingLabel.
  ///
  /// In en, this message translates to:
  /// **'Your rating: {rating}/5'**
  String yourRatingLabel(int rating);

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @actionFailed.
  ///
  /// In en, this message translates to:
  /// **'Action failed'**
  String get actionFailed;

  /// No description provided for @vendorBookingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Vendor Bookings'**
  String get vendorBookingsTitle;

  /// No description provided for @vendorTabToDeliver.
  ///
  /// In en, this message translates to:
  /// **'To Deliver'**
  String get vendorTabToDeliver;

  /// No description provided for @vendorTabDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get vendorTabDelivered;

  /// No description provided for @vendorTabCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get vendorTabCompleted;

  /// No description provided for @vendorTabCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get vendorTabCancelled;

  /// No description provided for @noBookingsFound.
  ///
  /// In en, this message translates to:
  /// **'No bookings found'**
  String get noBookingsFound;

  /// No description provided for @residentLabel.
  ///
  /// In en, this message translates to:
  /// **'Resident'**
  String get residentLabel;

  /// No description provided for @timeLabel.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get timeLabel;

  /// No description provided for @markDelivered.
  ///
  /// In en, this message translates to:
  /// **'Mark Delivered'**
  String get markDelivered;

  /// No description provided for @markedAsDelivered.
  ///
  /// In en, this message translates to:
  /// **'Marked as delivered'**
  String get markedAsDelivered;

  /// No description provided for @delivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get delivered;

  /// No description provided for @complaintNumber.
  ///
  /// In en, this message translates to:
  /// **'Complaint #{id}'**
  String complaintNumber(Object id);

  /// No description provided for @fromPerson.
  ///
  /// In en, this message translates to:
  /// **'From: {name}'**
  String fromPerson(Object name);

  /// No description provided for @viewComplaint.
  ///
  /// In en, this message translates to:
  /// **'View Complaint'**
  String get viewComplaint;

  /// No description provided for @complaintStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get complaintStatusLabel;

  /// No description provided for @reportsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search (vendor / ward / resident / message / id)'**
  String get reportsSearchHint;

  /// No description provided for @reportsAllStatus.
  ///
  /// In en, this message translates to:
  /// **'All Status'**
  String get reportsAllStatus;

  /// No description provided for @reportsAllWards.
  ///
  /// In en, this message translates to:
  /// **'All Wards'**
  String get reportsAllWards;

  /// No description provided for @reportsAllVendors.
  ///
  /// In en, this message translates to:
  /// **'All Vendors'**
  String get reportsAllVendors;

  /// No description provided for @reportsClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get reportsClear;

  /// No description provided for @reportsRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get reportsRefresh;

  /// No description provided for @reportsTakeActionTitle.
  ///
  /// In en, this message translates to:
  /// **'Take Action (Ward Admin)'**
  String get reportsTakeActionTitle;

  /// No description provided for @reportsStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get reportsStatusLabel;

  /// No description provided for @reportsSaveStatus.
  ///
  /// In en, this message translates to:
  /// **'Save Status'**
  String get reportsSaveStatus;

  /// No description provided for @reportsPhotosTitle.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get reportsPhotosTitle;

  /// No description provided for @reportsFailedToLoadImage.
  ///
  /// In en, this message translates to:
  /// **'Failed to load image'**
  String get reportsFailedToLoadImage;
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
