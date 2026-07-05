import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr')
  ];

  String get titleSourire;
  String welcomeMessage(String prenom);
  String mainQuestion(String accord);
  String get personalData;
  String get firstName;
  String get email;
  String get password;
  String get biometrics;
  String get accountSettings;
  String get notifications;
  String get permissions;
  String get archiving;
  String get accessibility;
  String get langues;
  String get help;
  String get logout;
  String get dailyGratitudeReminder;
  String get dailyReminderSubtitle;
  String get reminderTime;
  String get drawnMemoriesFrequency;
  String get drawnMemoriesSubtitle;
  String get frequencySettings;
  String get categoriesIncluded;
  String get everyDay;
  String get everyTwoDays;
  String get everyWeek;
  String get photoGalleryAccess;
  String get photoGallerySubtitle;
  String get secureLocalStorage;
  String get secureStorageSubtitle;
  String get active;
  String get spaceOccupied;
  String storageCounter(String photos, String notes);
  String get darkMode;
  String get darkModeSubtitle;
  String get smoothAnimations;
  String get smoothAnimationsSubtitle;
  String get francais;
  String get anglais;
  String get helpFaq;
  String get faqQuestion1;
  String get faqAnswer1;
  String get faqQuestion2;
  String get faqAnswer2;
  String get faqQuestion3;
  String get faqAnswer3;
  String get faqQuestion4;
  String get faqAnswer4;
  String get filterTitle;
  String get categoriesTitle;
  String get catSelfLove;
  String get catFriendship;
  String get catCouple;
  String get catFamily;
  String get catLeisure;
  String get catWork;
  String get catOthers;
  String get catUnclassified;
  String get btnNewCategory;
  String get hintNewCategory;
  String get btnDeleteCategories;
  String get noCustomCategoryToDelete;
  String get btnClose;
  String get titleDeleteModal;
  String get btnReset;
  String get btnFilter;
  String writeHappyThought (String accord);
  String get btnValidate;
  String get categoryQuestion;
  String get btnSkip;
  String get today;
  String get yesterday;
  String get btnDeleteSelection;
  String get btnCategorizeSelection;
  String get galleryRecent;
  String get galleryPreview;
  String get btnOk;
  String get alertWarningTitle; // <-- AJOUTÉ
  String get galleryDisabledMessage; // <-- AJOUTÉ
  String get btnEnableAccess;
  String get emptyJarMessage; // <-- AJOUTÉ
  String get deleteConfirmMessage; // <-- AJOUTÉ
  String get btnCancel; // <-- AJOUTÉ
  String get btnDeleteConfirm; // <-- AJOUTÉ
  String get recategorizeTitle; // <-- AJOUTÉ
  String get btnSave;
  String get profilTitlePersonalData;
  String get profilLabelFirstName;
  String get profilLabelEmail;
  String get profilLabelPassword;
  String get profilLabelBiometrics;
  String get profilTitleAccountSettings;
  String get profilMenuNotifications;
  String get profilMenuLanguage;
  String get profilMenuDarkMode;
  String get profilMenuSoftAnimations;
  String get profilTitleStorage;
  String get profilLabelImportedPhotos;
  String get profilLabelTextMemories;
  String get profilLabelGalleryAccess;
  String get profilBtnEmpty;
  String profilSnackbarEmptied(String label);
  String get profilTitleHelp;
  String get profilHelpQuestion1;
  String get profilHelpAnswer1;
  String get profilHelpQuestion2;
  String get profilHelpAnswer2;
  String get profilAlertTitle;
  String get profilAlertGalleryMessage;
  String get profilAlertBtnDisable;
  String get notifLabelTitleGratitude;
  String get notifLabelSubGratitude;
  String get notifLabelTime;
  String get notifLabelTitleSouvenirs;
  String get notifLabelSubSouvenirs;
  String get notifLabelFreqSettings;
  String get notifFreqEveryDay;
  String get notifFreqEveryTwoDays;
  String get notifFreqEveryWeek;
  String get notifLabelDayOfWeek;
  String get notifDayMonday;
  String get notifDayTuesday;
  String get notifDayWednesday;
  String get notifDayThursday;
  String get notifDayFriday;
  String get notifDaySaturday;
  String get notifDaySunday;
  String get notifLabelCategoriesIncluded;
  String get notifAllCategories;
  String get notifBocalVideTitle;
  String get notifBocalVideBody;
  String get onboardingBtnGetStarted;
  String get onboardingWelcomeMessage;
  String get onboardingQuestionName;
  String get onboardingHintName;
  String get onboardingQuestionGender;
  String get onboardingGenderMale;
  String get onboardingGenderFemale;
  String get onboardingSecurityTitle;
  String get onboardingHintEmail;
  String get onboardingEmailValid;
  String get onboardingEmailInvalid;
  String get onboardingHintPassword;
  String get onboardingBiometricsTitle;
  String get onboardingBiometricsLabel;
  String get onboardingBtnNext;
  String get onboardingBtnValidate;
  String get demoSkip;
  String get demoBtnNext;
  String get demoBtnFinish;
  String get demoPhotoTitle;
  String get demoPhotoDesc;
  String get demoNoteTitle;
  String get demoNoteDesc;
  String get demoBocalTitle;
  String get demoBocalDesc;
  String get demoBurgerTitle;
  String get demoBurgerDesc;
  String get resetPasswordTitle;
  String get resetPasswordHintNew;
  String get resetPasswordHintConfirm;
  String get resetPasswordErrorEmpty;
  String get resetPasswordErrorMismatch;
  String get resetPasswordSuccess;
  String get lockBiometricReason;
  String get lockInputHint;
  String get lockErrorIncorrect;
  String get lockForgotPassword;
  String get lockBtnBiometric;
  String get purchaseAlertTitle;
  String get purchaseAlertPhotosMessage;
  String get purchaseAlertNotesMessage;
  String get deleteAlertTitle;
  String get deleteAlertMessage;
  String get btnGoPremium;
  String get emptyHistory;
  String get notifGratitudeChannelName;
  String get notifGratitudeChannelDesc;
  String get notifSouvenirsChannelName;
  String get notifSouvenirsChannelDesc;
  String get notifGratitudeTitle;
  String get notifGratitudeBody;
  String get notifSouvenirsDefaultTitle;
  String get notifSouvenirsEmptyTitle;
  String get notifSouvenirsEmptyBody;
  String get notifSouvenirsAllBody;
  String premiumSuccessSnackBar(String themeLabel);
  String get btnPasserPremium;
  String get btnAppliquer;
  String get themesTitle;
  String get themesDescription;
  String get notesPurchaseSuccessSnackBar;
  String get themeClassique;
  String get themeMontagne;
  String get themeMer;
  String get themeAbstrait;
  String get themeSport;
  String get themeMusique;
  String get themeCinema;
  String get themeAnimauxMarins;
  String get themeFloral;
  String get themeKawaii;
  String get popupPalierTitle;
  String popupPalierMessage(int palier);
  String get btnContinuerPalier;

String get newBadgeUnlockedLabel;

String get badge10Name;
String get badge10Phrase;
String get badge50Name;
String get badge50Phrase;
String get badge100Name;
String get badge100Phrase;
String get badge200Name;
String get badge200Phrase;
String get badge500Name;
String get badge500Phrase;
String get badge1000Name;
String get badge1000Phrase;
String get badge1500Name;
String get badge1500Phrase;
String get badge2000Name;
String get badge2000Phrase;
String get badge2500Name;
String get badge2500Phrase;
String get badge3000Name;
String get badge3000Phrase;
String get badge3500Name;
String get badge3500Phrase;
String get badge4000Name;
String get badge4000Phrase;
String get badge4500Name;
String get badge4500Phrase;
String get badge5000Name;
String get badge5000Phrase;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'fr': return AppLocalizationsFr();
  }
  throw FlutterError('AppLocalizations.delegate failed to load unsupported locale "$locale".');
}