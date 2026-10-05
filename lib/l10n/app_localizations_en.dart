// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String welcomeMessage(String prenom) {
    return 'Hello $prenom,';
  }

  @override
  String mainQuestion(String accord) {
    return 'What makes you happy today?';
  }

  @override
  String get personalData => 'Personal data';

  @override
  String get firstName => 'First name';

  @override
  String get gender => 'Gender';

  @override
  String get password => 'Password';

  @override
  String get biometrics => 'Biometrics';

  @override
  String get accountSettings => 'App settings';

  @override
  String get notifications => 'Notifications';

  @override
  String get personalization => 'Personalization';

  @override
  String get archiving => 'Archiving';

  @override
  String get accessibility => 'Accessibility';

  @override
  String get langues => 'Languages';

  @override
  String get help => 'Help';

  @override
  String get secureLocalStorage => 'Secure local storage';

  @override
  String get secureStorageSubtitle =>
      'Your memories are automatically saved locally on your private storage space.';

  @override
  String get active => 'Active';

  @override
  String get spaceOccupied => 'Storage used';

  @override
  String storageCounter(String photos, String notes) {
    return 'Photos: $photos | Notes: $notes';
  }

  @override
  String get darkMode => 'Dark mode';

  @override
  String get darkModeSubtitle =>
      'Switch the interface to dark tones to rest your eyes at night.';

  @override
  String get smoothAnimations => 'Smooth animations';

  @override
  String get smoothAnimationsSubtitle =>
      'Replaces the jar\'s tornado effect with a lighter fade-in effect.';

  @override
  String get helpFaq => 'Help / FAQ';

  @override
  String get faqQuestion1 => 'Where are my memories stored?';

  @override
  String get faqAnswer1 =>
      'They remain locally in your phone\'s secure folder, no one else has access to them.';

  @override
  String get faqQuestion2 => 'How does the lucky draw work?';

  @override
  String get faqAnswer2 => 'Tap the jar to bring up a random memory.';

  @override
  String get faqQuestion3 => 'How to categorize memories?';

  @override
  String get faqAnswer3 =>
      'Go to history and long-press a memory. You can then select multiple items and choose \'Categorize\'.';

  @override
  String get faqQuestion5 => 'How do I categorize my memories one by one?';

  @override
  String get faqAnswer5 =>
      'There are 2 ways to categorize your memories one by one:\n1- Import your memories one at a time.\n2- On the categorization screen for the selected batch, tap the photo with the counter: a carousel of your memories appears, along with the “Categorize one by one” option.';

  @override
  String get faqQuestion6 => 'How do I delete memory categories?';

  @override
  String get faqAnswer6 =>
      'On the category selection screen, swipe the category you want to delete to the left.';

  @override
  String get faqQuestion4 => 'How to delete memories?';

  @override
  String get faqAnswer4 =>
      'Go to history, long-press the memory, select it and press the \'Delete\' button.';

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
  String get btnReset => 'Reset';

  @override
  String get btnFilter => 'Filter';

  @override
  String writeHappyThought(String accord) {
    return 'Write down what makes you happy...';
  }

  @override
  String get btnValidate => 'Validate';

  @override
  String get categoryQuestion =>
      'Which category(ies) does this souvenir belong to?';

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
  String get emptyJarMessage => 'The jar is empty, add a memory!';

  @override
  String get btnCancel => 'Cancel';

  @override
  String get btnDeleteConfirm => 'Delete';

  @override
  String get onboardingBtnGetStarted => 'Get started';

  @override
  String get onboardingWelcomeMessage =>
      'Welcome to your\npersonal space designed\nto bring back your\nsmile!';

  @override
  String get onboardingQuestionName => 'What is your name?';

  @override
  String get onboardingHintName => 'First name';

  @override
  String get onboardingQuestionGender => 'How should I address you?';

  @override
  String get onboardingGenderMale => 'Masculine';

  @override
  String get onboardingGenderFemale => 'Feminine';

  @override
  String get onboardingGenderNone => 'Inclusive language';

  @override
  String get onboardingSecurityTitle => 'Secure access to your space';

  @override
  String get onboardingHintPassword => 'Password (min. 6 chars)';

  @override
  String get onboardingBiometricsLabel => 'Enable biometrics';

  @override
  String get onboardingBiometricsHelp =>
      'Turning on biometrics lets you unlock the app with your fingerprint or face recognition, without typing your password every time.';

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
  String get demoPhotoDesc =>
      'Click here to import your favorite photos and organize them in your personal space.';

  @override
  String get demoNoteTitle => 'Write a note';

  @override
  String get demoNoteDesc =>
      'Save a thought, a sweet word, or a text-based memory to keep.';

  @override
  String get demoBocalTitle => 'Your memory jar';

  @override
  String get demoBocalDesc =>
      'Tap the jar at any time to randomly draw a saved memory and put a smile back on your face!';

  @override
  String get demoBurgerTitle => 'Your history';

  @override
  String get demoBurgerDesc =>
      'Open this menu at any time to find the chronological list of all your precious saved memories.';

  @override
  String get notifLabelTitleGratitude => 'Gratitude reminder';

  @override
  String get notifLabelSubGratitude =>
      'Remind me to write down a positive memory';

  @override
  String get notifLabelTime => 'Reminder time';

  @override
  String get notifLabelTitleSouvenirs => 'Drawn memories frequency';

  @override
  String get notifLabelSubSouvenirs => 'Suggest an old memory for me to review';

  @override
  String get notifLabelFreqSettings => 'Frequency settings';

  @override
  String get notifFreqEveryDay => 'Every day';

  @override
  String get notifFreqEveryWeek => 'Every week';

  @override
  String get notifLabelDayOfWeek => 'Days of the week';

  @override
  String get notifDayMonday => 'Monday';

  @override
  String get notifDayTuesday => 'Tuesday';

  @override
  String get notifDayWednesday => 'Wednesday';

  @override
  String get notifDayThursday => 'Thursday';

  @override
  String get notifDayFriday => 'Friday';

  @override
  String get notifDaySaturday => 'Saturday';

  @override
  String get notifDaySunday => 'Sunday';

  @override
  String get notifLabelCategoriesIncluded => 'Categories included';

  @override
  String get notifAllCategories => 'All categories';

  @override
  String get notifBocalVideTitle => 'Empty jar';

  @override
  String get notifBocalVideBody =>
      'No memories to display in the selected categories.';

  @override
  String get resetPasswordTitle => 'Reset your password';

  @override
  String get resetPasswordHintNew => 'New password';

  @override
  String get resetPasswordHintConfirm => 'Confirm password';

  @override
  String get resetPasswordErrorEmpty => 'Please fill in all fields';

  @override
  String get resetPasswordErrorMismatch => 'Passwords do not match';

  @override
  String get resetPasswordSuccess => 'Password reset successfully';

  @override
  String get lockBiometricReason => 'Sourire security lock';

  @override
  String get lockInputHint => 'Enter your password';

  @override
  String get lockErrorIncorrect => 'Incorrect password';

  @override
  String get lockForgotPassword => 'Forgot password?';

  @override
  String get lockBtnBiometric => 'Use fingerprint';

  @override
  String get purchaseAlertTitle => 'Limit reached';

  @override
  String purchaseAlertMessage(int limite) {
    return 'You have reached the limit of $limite memories for the free version. Upgrade to Premium to add unlimited memories!';
  }

  @override
  String get deleteAlertTitle => 'Do you really want to delete these memories?';

  @override
  String get deleteAlertMessage =>
      'This action cannot be undone and will permanently delete the selected memories.';

  @override
  String get emptyHistory => 'History is empty';

  @override
  String get notifGratitudeChannelName => 'Gratitude Reminder';

  @override
  String get notifGratitudeChannelDesc =>
      'To remind you to write down your positive thoughts';

  @override
  String get notifSouvenirsChannelName => 'Happy memory';

  @override
  String get notifSouvenirsChannelDesc => 'Psst, look what just popped up...';

  @override
  String get notifGratitudeTitle => 'Gratitude reminder';

  @override
  String get notifGratitudeBodyDaily =>
      'What positive thing happened in your day?';

  @override
  String get notifGratitudeBodyWeekly =>
      'What positive thing happened in your week?';

  @override
  String get notifSouvenirsDefaultTitle => 'Psst, look what just popped up 👀';

  @override
  String get notifSouvenirsEmptyTitle => 'Your happiness jar is empty...';

  @override
  String get notifSouvenirsEmptyBody =>
      'Add your first happy memories to be able to see them!';

  @override
  String get notifSouvenirsAllBody => 'Take a look at this souvenir...';

  @override
  String get btnPasserPremium => 'Go Premium';

  @override
  String get btnAppliquer => 'Apply';

  @override
  String get themesTitle => 'Home screen themes';

  @override
  String get notesPurchaseSuccessSnackBar =>
      'Thank you! Premium is unlocked: unlimited memories and every backdrop.';

  @override
  String premiumSuccessSnackBar(String themeLabel) {
    return 'Premium Activated! All locks have been removed. Theme “$themeLabel” applied.';
  }

  @override
  String get themeClassique => 'Classic';

  @override
  String get themeMontagne => 'Mountain';

  @override
  String get themeMer => 'Ocean';

  @override
  String get themeSport => 'Sports';

  @override
  String get themeVoyage => 'Travel';

  @override
  String get themeMusique => 'Music';

  @override
  String get themeCinema => 'Cinema';

  @override
  String get themeAnimauxMarins => 'Marine Animals';

  @override
  String get themeAmour => 'Love';

  @override
  String get themeCelebration => 'Celebrations';

  @override
  String get themeNature => 'Nature';

  @override
  String get themeKawaii => 'Kawaii';

  @override
  String get btnContinuerPalier => 'Continue';

  @override
  String get badge10Name => 'Star Seeker';

  @override
  String get badge10Phrase => 'The most beautiful memories often start small.';

  @override
  String get badge50Name => 'Beauty Gatherer';

  @override
  String get badge50Phrase =>
      'Keep capturing the moments that light up your days.';

  @override
  String get badge100Name => 'Guardian of Moments';

  @override
  String get badge100Phrase =>
      'Your jar is becoming a true haven for memories.';

  @override
  String get badge200Name => 'Storyteller of Memories';

  @override
  String get badge200Phrase => 'Every memory adds a page to your story.';

  @override
  String get badge500Name => 'Wellspring of Joy';

  @override
  String get badge500Phrase =>
      'Your jar is filling up with beautiful moments to relive.';

  @override
  String get badge1000Name => 'Alchemist of Happiness';

  @override
  String get badge1000Phrase => 'Keep treasuring these little sparks of joy.';

  @override
  String get badge1500Name => 'Fairy of Light';

  @override
  String get badge1500Phrase =>
      'Every memory you add brightens your everyday life a little more.';

  @override
  String get badge2000Name => 'Archivist of the Heart';

  @override
  String get badge2000Phrase =>
      'Your jar is becoming a true archive of emotions.';

  @override
  String get badge2500Name => 'Goldsmith of Emotions';

  @override
  String get badge2500Phrase =>
      'You\'re collecting memories as precious as they are rare.';

  @override
  String get badge3000Name => 'Clockmaker of Moments';

  @override
  String get badge3000Phrase =>
      'You\'re turning fleeting moments into lasting memories.';

  @override
  String get badge3500Name => 'Watcher of Light';

  @override
  String get badge3500Phrase => 'Even small moments can light up a whole day.';

  @override
  String get badge4000Name => 'Guardian of Eternity';

  @override
  String get badge4000Phrase =>
      'You\'re building a timeless collection of memories.';

  @override
  String get badge4500Name => 'Mage of Memories';

  @override
  String get badge4500Phrase =>
      'Your jar is already overflowing with precious moments.';

  @override
  String get badge5000Name => 'Legend of Sourire';

  @override
  String get badge5000Phrase =>
      'The most beautiful memories are still to come.';

  @override
  String get rewardsSectionTitle => 'Rewards';

  @override
  String get myBadgesTitle => 'My badges';

  @override
  String get btnSelectAll => 'Select all';

  @override
  String get btnDeselectAll => 'Deselect all';

  @override
  String selectedCountLabel(int count) {
    return '$count selected';
  }

  @override
  String get jarFullTitle => 'Your jar is full!';

  @override
  String get jarFullMessage =>
      'A new jar awaits you. All your memories are of course kept — only the display changes.';

  @override
  String get btnNewJar => 'New jar';

  @override
  String get shareError => 'Sharing didn\'t go through. Please try again.';

  @override
  String get amorceVoyage => 'Your best travel memory...';

  @override
  String get amorceFouRire => 'The last time you laughed until you cried!';

  @override
  String get amorceCadeau => 'The most beautiful gift you\'ve ever been given.';

  @override
  String get amorceToi => 'What you like most about yourself.';

  @override
  String get amorceFierte => 'What you\'re proudest of!';

  @override
  String get backupExportTitle => 'Export my memories';

  @override
  String get backupExportSub =>
      'Builds an archive with your notes and photos. Keep it wherever you like — nothing is sent over the internet.';

  @override
  String get backupImportTitle => 'Restore a backup';

  @override
  String get backupImportSub =>
      'Adds the memories from an archive. Nothing is deleted, and memories already present are skipped.';

  @override
  String get backupExportError =>
      'The export didn\'t go through. Please try again.';

  @override
  String get backupImportError =>
      'Unreadable archive. Check that it is a Sourire export.';

  @override
  String backupImportDone(int ajoutes, int ignores) {
    return '$ajoutes memory/ies restored, $ignores already present.';
  }

  @override
  String get restoreDefaultCategoriesTitle => 'Restore default categories';

  @override
  String get restoreDefaultCategoriesSub =>
      'Brings back Self-love, Friendship, Couple, Family, Leisure and Work if you deleted them. Your memories are left untouched.';

  @override
  String get restoreDefaultCategoriesDone => 'Default categories restored.';

  @override
  String get batchCategoryQuestion =>
      'Which categories do these memories belong to?';

  @override
  String get batchCategorizeOneByOne => 'Categorize one by one';

  @override
  String deleteCategoryConfirmTitle(String categorie) {
    return 'Delete “$categorie”?';
  }

  @override
  String deleteCategoryConfirmBody(int nombre) {
    String _temp0 = intl.Intl.pluralLogic(
      nombre,
      locale: localeName,
      other: '$nombre memories will lose this category.',
      one: 'One memory will lose this category.',
    );
    return '$_temp0 No memory is deleted.';
  }

  @override
  String get filterByPeriod => 'By period';

  @override
  String get filterByCategory => 'By category';

  @override
  String get btnApply => 'Apply';

  @override
  String get themePreviewQuestion => 'What made you happy today?';

  @override
  String get notesThemesPurchaseMessage =>
      'Choose the backdrop for your notes from the library of themes.';

  @override
  String get eraseAllTitle => 'Erase all my memories';

  @override
  String get eraseAllSub =>
      'Empties the jar completely: memories, photos and the categories you created. Your first name, language and settings stay as they are.';

  @override
  String get eraseAllConfirmTitle => 'Erase all your memories?';

  @override
  String get eraseAllConfirmMessage =>
      'The memories, photos and categories you created will be deleted from this phone. Nothing can be recovered. Your first name, language and settings stay as they are.';

  @override
  String get eraseAllContinue => 'Continue';

  @override
  String get eraseAllLastCallTitle => 'One last check';

  @override
  String get eraseAllLastCallMessage =>
      'If you want to keep a trace, close this window and export a backup first.';

  @override
  String get eraseAllConfirmButton => 'Erase permanently';

  @override
  String get eraseAllDone => 'Your jar is empty.';

  @override
  String get eraseAllError => 'The erase didn\'t go through.';

  @override
  String get premiumSoon => 'Coming soon';

  @override
  String get premiumRestore => 'Restore my purchases';

  @override
  String get premiumRestoreNone => 'No purchase to restore on this account.';

  @override
  String get premiumRestoreDone => 'Your Premium has been restored.';

  @override
  String get premiumUnavailable =>
      'The store can\'t be reached right now. Try again in a moment.';

  @override
  String get premiumPending =>
      'Your purchase is awaiting approval. Premium will unlock on its own once it\'s granted.';

  @override
  String get premiumError =>
      'The purchase didn\'t go through. You have not been charged.';

  @override
  String get premiumRestoreTitle => 'Restore my purchases';

  @override
  String get premiumRestoreSub =>
      'Already paid for Premium on another phone, or after reinstalling? Get it back here.';

  @override
  String get themesPurchaseMessage =>
      'Choose the backdrop for your home screen from the library of themes.';

  @override
  String premiumPriceNote(String prix) {
    return '$prix per month, no commitment. Cancel any time.';
  }

  @override
  String get premiumLinkPrivacy => 'Privacy';

  @override
  String get premiumLinkTerms => 'Terms of use';
}
