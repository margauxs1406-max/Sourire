// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get titleSourire => 'Sourire';

  @override
  String welcomeMessage(String prenom) => 'Hello $prenom,';

  @override
  String mainQuestion(String accord) => 'What makes you happy today?';

  @override
  String get personalData => 'Personal data';

  @override
  String get firstName => 'First name';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get biometrics => 'Biometrics';

  @override
  String get accountSettings => 'Account settings';

  @override
  String get notifications => 'Notifications';

  @override
  String get permissions => 'Permissions';

  @override
  String get archiving => 'Archiving';

  @override
  String get accessibility => 'Appearance';

  @override
  String get langues => 'Languages';

  @override
  String get help => 'Help';

  @override
  String get logout => 'Log out';

  @override
  String get dailyGratitudeReminder => 'Daily gratitude reminder';

  @override
  String get dailyReminderSubtitle => 'Remind me to write down a positive memory';

  @override
  String get reminderTime => 'Reminder time';

  @override
  String get drawnMemoriesFrequency => 'Frequency of drawn memories';

  @override
  String get drawnMemoriesSubtitle => 'Suggest an old memory for me to review';

  @override
  String get frequencySettings => 'Frequency settings';

  @override
  String get categoriesIncluded => 'Categories included';

  @override
  String get everyDay => 'Every day';

  @override
  String get everyTwoDays => 'Every 2 days';

  @override
  String get everyWeek => 'Every week';

  @override
  String get photoGalleryAccess => 'Photo gallery access';

  @override
  String get photoGallerySubtitle => 'Essential for adding photos of your previous moments.';

  @override
  String get secureLocalStorage => 'Secure local storage';

  @override
  String get secureStorageSubtitle => 'Your memories are automatically saved locally on your private storage space.';

  @override
  String get active => 'Active';

  @override
  String get spaceOccupied => 'Storage used';

  @override
  String storageCounter(String photos, String notes) => 'Photos: $photos KB | Notes: $notes KB';

  @override
  String get darkMode => 'Dark mode';

  @override
  String get darkModeSubtitle => 'Switch the interface to dark tones to rest your eyes at night.';

  @override
  String get smoothAnimations => 'Smooth animations';

  @override
  String get smoothAnimationsSubtitle => 'Replaces the jar\'s tornado effect with a lighter fade-in effect.';

  @override
  String get francais => 'French';

  @override
  String get anglais => 'English';

  @override
  String get helpFaq => 'Help / FAQ';

  @override
  String get faqQuestion1 => 'Where are my memories stored?';

  @override
  String get faqAnswer1 => 'They remain locally in your phone\'s secure folder, no one else has access to them.';

  @override
  String get faqQuestion2 => 'How does the lucky draw work?';

  @override
  String get faqAnswer2 => 'Shake your phone or click on the jar to bring up a random memory.';

  @override
  String get faqQuestion3 => 'How to categorize memories?';

  @override
  String get faqAnswer3 => 'Go to history and long-press a memory. You can then select multiple items and choose \'Categorize\'.';

  @override
  String get faqQuestion4 => 'How to delete memories?';

  @override
  String get faqAnswer4 => 'Go to history, long-press the memory, select it and press the \'Delete\' button.';

  @override
  String get filterTitle => 'Filter';

  @override
  String get categoriesTitle => 'Categories';

  @override
  String get catSelfLove => 'Self-love';

  @override
  String get catFriendship => 'Friendship';

  @override
  String get catCouple => 'Couple';

  @override
  String get catFamily => 'Family';

  @override
  String get catLeisure => 'Leisure';

  @override
  String get catWork => 'Work';

  @override
  String get catOthers => 'Others';

  @override
  String get catUnclassified => 'Unclassified';

  @override
  String get btnNewCategory => 'New category';

  @override
  String get hintNewCategory => 'Category name...';

  @override
  String get btnDeleteCategories => 'Delete categories';

  @override
  String get noCustomCategoryToDelete => 'No custom categories to delete.';
  
  @override
  String get btnClose => 'Close';

  @override
  String get titleDeleteModal => 'Manage categories';

  @override
  String get btnReset => 'Reset';

  @override
  String get btnFilter => 'Filter';

  @override
  String writeHappyThought(String accord) => 'Write down what makes you happy...';

  @override
  String get btnValidate => 'Validate';

  @override
  String get categoryQuestion => 'Which category(ies) does this souvenir belong to?';

  @override
  String get btnSkip => 'Skip';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get btnDeleteSelection => 'Delete';

  @override
  String get btnCategorizeSelection => 'Categorize';

  @override
  String get galleryRecent => 'Recent';

  @override
  String get galleryPreview => 'Preview';

  @override
  String get btnOk => 'OK';

  @override
  String get alertWarningTitle => 'Warning';

  @override
  String get galleryDisabledMessage => 'You have disabled access to your photo gallery. Please enable it in your permissions.';

  @override
  String get btnEnableAccess => 'Enable access';

  @override
  String get emptyJarMessage => 'The jar is empty, add a memory!';

  @override
  String get deleteConfirmMessage => 'Are you sure you want to permanently delete these memories?';

  @override
  String get btnCancel => 'Cancel';

  @override
  String get btnDeleteConfirm => 'Delete';

  @override
  String get recategorizeTitle => 'Select the categories to apply to the selected memories:';

  @override
  String get btnSave => 'Save';

  @override
  String get onboardingBtnGetStarted => 'Get started';

  @override
  String get onboardingWelcomeMessage => 'Welcome to your\npersonal space designed\nto bring back your\nsmile!';

  @override
  String get onboardingQuestionName => 'What is your name?';

  @override
  String get onboardingHintName => 'First name';

  @override
  String get onboardingQuestionGender => 'You are...';

  @override
  String get onboardingGenderMale => 'A man';

  @override
  String get onboardingGenderFemale => 'A woman';

  @override
  String get onboardingSecurityTitle => 'Secure your data';

  @override
  String get onboardingHintEmail => 'Email';

  @override
  String get onboardingEmailValid => 'valid email';

  @override
  String get onboardingEmailInvalid => 'invalid email';

  @override
  String get onboardingHintPassword => 'Password (min. 6 chars)';

  @override
  String get onboardingBiometricsTitle => 'Simplify your access to the app';

  @override
  String get onboardingBiometricsLabel => 'Enable biometrics';

  @override
  String get onboardingBtnNext => 'Next';

  @override
  String get onboardingBtnValidate => 'Validate';

  @override
  String get demoSkip => 'SKIP';

  @override
  String get demoBtnNext => 'Next';

  @override
  String get demoBtnFinish => 'Finish';

  @override
  String get demoPhotoTitle => 'Add a photo';

  @override
  String get demoPhotoDesc => 'Click here to import your favorite photos and organize them in your personal space.';

  @override
  String get demoNoteTitle => 'Write a note';

  @override
  String get demoNoteDesc => 'Save a thought, a sweet word, or a text-based memory to keep.';

  @override
  String get demoBocalTitle => 'Your memory jar';

  @override
  String get demoBocalDesc => 'Tap the jar at any time to randomly draw a saved memory and put a smile back on your face!';

  @override
  String get demoBurgerTitle => 'Your history';

  @override
  String get demoBurgerDesc => 'Open this menu at any time to find the chronological list of all your precious saved memories.';

  @override
  String get profilTitlePersonalData => "Personal data";
  @override
  String get profilLabelFirstName => "First name";
  @override
  String get profilLabelEmail => "Email";
  @override
  String get profilLabelPassword => "Password";
  @override
  String get profilLabelBiometrics => "Biometrics";
  @override
  String get profilTitleAccountSettings => "Account settings";
  @override
  String get profilMenuNotifications => "Notifications";
  @override
  String get profilMenuLanguage => "Application language";
  @override
  String get profilMenuDarkMode => "Dark theme";
  @override
  String get profilMenuSoftAnimations => "Smooth animations";
  @override
  String get profilTitleStorage => "Device storage";
  @override
  String get profilLabelImportedPhotos => "Imported photos";
  @override
  String get profilLabelTextMemories => "Textual memories";
  @override
  String get profilLabelGalleryAccess => "Gallery access";
  @override
  String get profilBtnEmpty => "Clear";
  @override
  String profilSnackbarEmptied(String label) => "$label cleared";
  @override
  String get profilTitleHelp => "Need help?";
  @override
  String get profilHelpQuestion1 => "How to add a memory?";
  @override
  String get profilHelpAnswer1 => "Click the '+' button on the home screen to start writing a memory or importing a photo.";
  @override
  String get profilHelpQuestion2 => "Is my data secure?";
  @override
  String get profilHelpAnswer2 => "Yes, all your data is stored locally on your phone and encrypted.";
  @override
  String get profilAlertTitle => "Warning";
  @override
  String get profilAlertGalleryMessage => "Warning, if you decide to remove access to your photo gallery, you will no longer be able to save photos in your memories.";
  @override
  String get profilAlertBtnDisable => "Disable access";
  @override
  String get notifLabelTitleGratitude => "Daily gratitude reminder";
  @override
  String get notifLabelSubGratitude => "Remind me to write down a positive memory";
  @override
  String get notifLabelTime => "Reminder time";
  @override
  String get notifLabelTitleSouvenirs => "Drawn memories frequency";
  @override
  String get notifLabelSubSouvenirs => "Suggest an old memory for me to review";
  @override
  String get notifLabelFreqSettings => "Frequency settings";
  @override
  String get notifFreqEveryDay => "Every day";
  @override
  String get notifFreqEveryTwoDays => "Every 2 days";
  @override
  String get notifFreqEveryWeek => "Every week";
  @override
  String get notifLabelDayOfWeek => "Day of the week";
  @override
  String get notifDayMonday => "Monday";
  @override
  String get notifDayTuesday => "Tuesday";
  @override
  String get notifDayWednesday => "Wednesday";
  @override
  String get notifDayThursday => "Thursday";
  @override
  String get notifDayFriday => "Friday";
  @override
  String get notifDaySaturday => "Saturday";
  @override
  String get notifDaySunday => "Sunday";
  @override
  String get notifLabelCategoriesIncluded => "Categories included";
  @override
  String get notifAllCategories => "All categories";

  @override
  String get resetPasswordTitle => "Reset your password";

  @override
  String get resetPasswordHintNew => "New password";

  @override
  String get resetPasswordHintConfirm => "Confirm password";

  @override
  String get resetPasswordErrorEmpty => "Please fill in all fields";

  @override
  String get resetPasswordErrorMismatch => "Passwords do not match";

  @override
  String get resetPasswordSuccess => "Password reset successfully";

  @override
  String get lockBiometricReason => "Sourire security lock";

  @override
  String get lockInputHint => "Enter your password";

  @override
  String get lockErrorIncorrect => "Incorrect password";

  @override
  String get lockForgotPassword => "Forgot password?";

  @override
  String get lockBtnBiometric => "Use fingerprint";

  @override
  String get purchaseAlertTitle => "Limit reached";

  @override
  String get purchaseAlertPhotosMessage => "You have reached the maximum limit of 10 photos for the free version. Upgrade to Premium to add unlimited memories and unlock new themes!";

  @override
  String get purchaseAlertNotesMessage => "You have reached the maximum limit of 5 notes for the free version. Upgrade to Premium to add unlimited memories and unlock new themes!";

  @override
  String get btnGoPremium => "Go Premium";

  @override
 String get emptyHistory => "History is empty";

 @override
  String get notifGratitudeChannelName => 'Gratitude Reminder';

  @override
  String get notifGratitudeChannelDesc => 'To remind you to write down your positive thoughts';

  @override
  String get notifSouvenirsChannelName => 'Happy memory';

  @override
  String get notifSouvenirsChannelDesc => 'Psst, look what just popped up...';

  @override
  String get notifGratitudeTitle => 'Gratitude reminder';

  @override
  String get notifGratitudeBody => 'What positive thing happened in your day? ☀️ ';

  @override
  String get notifSouvenirsDefaultTitle => 'Psst, look what just popped up...😉';

  @override
  String get notifSouvenirsEmptyTitle => 'Your happiness jar is empty...';

  @override
  String get notifSouvenirsEmptyBody => 'Add your first happy memories to be able to see them!';

  @override
  String get notifSouvenirsPhotoBody => '📸 Take a look at this photo!';

  @override
  String get btnPasserPremium => 'Go Premium';

  @override
  String get btnAppliquer => 'Apply';

  @override
  String get themesTitle => 'Themes';

  @override
  String get themesDescription => 'Customize your interface and notes at any time by choosing from the following themes.';

  @override
  String get notesPurchaseSuccessSnackBar => 'Purchase successfully simulated! Unlimited notes and photos unlocked.';

  @override
  String premiumSuccessSnackBar(String themeLabel) {
    return 'Premium Activated! All locks have been removed. \'$themeLabel\' theme applied.';
  }

  @override
  String get themeClassique => 'Classic';

  @override
  String get themeMontagne => 'Mountain';

  @override
  String get themeMer => 'Ocean';

  @override
  String get themeAbstrait => 'Abstract';

  @override
  String get themeSport => 'Sports';

  @override
  String get themeMusique => 'Music';

  @override
  String get themeCinema => 'Cinema';

  @override
  String get themeAnimauxMarins => 'Marine Animals';

  @override
  String get themeFloral => 'Floral';

  @override
  String get themeKawaii => 'Kawaii';
}