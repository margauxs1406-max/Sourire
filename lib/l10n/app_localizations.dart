import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';

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
    Locale('es'),
    Locale('fr'),
  ];

  /// No description provided for @welcomeMessage.
  ///
  /// In fr, this message translates to:
  /// **'Bonjour {prenom},'**
  String welcomeMessage(String prenom);

  /// No description provided for @mainQuestion.
  ///
  /// In fr, this message translates to:
  /// **'Qu’est-ce qui te rend {accord} aujourd’hui ?'**
  String mainQuestion(String accord);

  /// No description provided for @personalData.
  ///
  /// In fr, this message translates to:
  /// **'Données personnelles'**
  String get personalData;

  /// No description provided for @firstName.
  ///
  /// In fr, this message translates to:
  /// **'Prénom'**
  String get firstName;

  /// No description provided for @gender.
  ///
  /// In fr, this message translates to:
  /// **'Genre'**
  String get gender;

  /// No description provided for @password.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get password;

  /// No description provided for @biometrics.
  ///
  /// In fr, this message translates to:
  /// **'Biométrie'**
  String get biometrics;

  /// No description provided for @accountSettings.
  ///
  /// In fr, this message translates to:
  /// **'Réglages de l\'application'**
  String get accountSettings;

  /// No description provided for @notifications.
  ///
  /// In fr, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @personalization.
  ///
  /// In fr, this message translates to:
  /// **'Personnalisation'**
  String get personalization;

  /// No description provided for @permissions.
  ///
  /// In fr, this message translates to:
  /// **'Autorisations'**
  String get permissions;

  /// No description provided for @archiving.
  ///
  /// In fr, this message translates to:
  /// **'Archivage'**
  String get archiving;

  /// No description provided for @accessibility.
  ///
  /// In fr, this message translates to:
  /// **'Accessibilité'**
  String get accessibility;

  /// No description provided for @langues.
  ///
  /// In fr, this message translates to:
  /// **'Langues'**
  String get langues;

  /// No description provided for @help.
  ///
  /// In fr, this message translates to:
  /// **'Aide'**
  String get help;

  /// No description provided for @photoGalleryAccess.
  ///
  /// In fr, this message translates to:
  /// **'Accès à la galerie photo'**
  String get photoGalleryAccess;

  /// No description provided for @photoGallerySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Indispensable pour ajouter des photos de tes moments précieux.'**
  String get photoGallerySubtitle;

  /// No description provided for @secureLocalStorage.
  ///
  /// In fr, this message translates to:
  /// **'Stockage local sécurisé'**
  String get secureLocalStorage;

  /// No description provided for @secureStorageSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Tes souvenirs sont automatiquement sauvegardés localement sur ton espace de stockage privé.'**
  String get secureStorageSubtitle;

  /// No description provided for @active.
  ///
  /// In fr, this message translates to:
  /// **'Actif'**
  String get active;

  /// No description provided for @spaceOccupied.
  ///
  /// In fr, this message translates to:
  /// **'Espace occupé'**
  String get spaceOccupied;

  /// No description provided for @storageCounter.
  ///
  /// In fr, this message translates to:
  /// **'Photos : {photos} | Notes : {notes}'**
  String storageCounter(String photos, String notes);

  /// No description provided for @darkMode.
  ///
  /// In fr, this message translates to:
  /// **'Mode sombre'**
  String get darkMode;

  /// No description provided for @darkModeSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Bascule l\'interface dans des tons sombres pour reposer tes yeux le soir.'**
  String get darkModeSubtitle;

  /// No description provided for @smoothAnimations.
  ///
  /// In fr, this message translates to:
  /// **'Animations douces'**
  String get smoothAnimations;

  /// No description provided for @smoothAnimationsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Remplace l\'effet tornade du bocal par une apparition en fondu plus légère.'**
  String get smoothAnimationsSubtitle;

  /// No description provided for @francais.
  ///
  /// In fr, this message translates to:
  /// **'Français'**
  String get francais;

  /// No description provided for @anglais.
  ///
  /// In fr, this message translates to:
  /// **'English'**
  String get anglais;

  /// No description provided for @helpFaq.
  ///
  /// In fr, this message translates to:
  /// **'Aide / FAQ'**
  String get helpFaq;

  /// No description provided for @faqQuestion1.
  ///
  /// In fr, this message translates to:
  /// **'Où sont stockés mes souvenirs ?'**
  String get faqQuestion1;

  /// No description provided for @faqAnswer1.
  ///
  /// In fr, this message translates to:
  /// **'Ils restent localement dans le dossier sécurisé de ton téléphone, personne d\'autre n\'y a accès.'**
  String get faqAnswer1;

  /// No description provided for @faqQuestion2.
  ///
  /// In fr, this message translates to:
  /// **'Comment fonctionne le tirage au sort ?'**
  String get faqQuestion2;

  /// No description provided for @faqAnswer2.
  ///
  /// In fr, this message translates to:
  /// **'Clique sur le bocal pour faire remonter un souvenir au hasard.'**
  String get faqAnswer2;

  /// No description provided for @faqQuestion3.
  ///
  /// In fr, this message translates to:
  /// **'Comment catégoriser des souvenirs ?'**
  String get faqQuestion3;

  /// No description provided for @faqAnswer3.
  ///
  /// In fr, this message translates to:
  /// **'Va dans l\'historique et appuie longuement sur un souvenir. Tu pourras alors en sélectionner plusieurs et choisir \'Catégoriser\'.'**
  String get faqAnswer3;

  /// No description provided for @faqQuestion5.
  ///
  /// In fr, this message translates to:
  /// **'Comment catégoriser mes souvenirs un par un ?'**
  String get faqQuestion5;

  /// No description provided for @faqAnswer5.
  ///
  /// In fr, this message translates to:
  /// **'Pour catégoriser tes souvenirs un par un, tu as 2 options :\n1- Importe tes souvenirs un par un.\n2- Depuis l\'écran de catégorisation du lot de souvenirs sélectionnés, clique sur la photo qui porte la pastille : un carrousel de tes souvenirs apparaît, avec l\'option « Catégoriser 1 par 1 ».'**
  String get faqAnswer5;

  /// No description provided for @faqQuestion6.
  ///
  /// In fr, this message translates to:
  /// **'Comment supprimer des catégories de souvenirs ?'**
  String get faqQuestion6;

  /// No description provided for @faqAnswer6.
  ///
  /// In fr, this message translates to:
  /// **'Dans l\'écran de sélection des catégories, fais glisser la catégorie que tu veux supprimer vers la gauche.'**
  String get faqAnswer6;

  /// No description provided for @faqQuestion4.
  ///
  /// In fr, this message translates to:
  /// **'Comment supprimer des souvenirs ?'**
  String get faqQuestion4;

  /// No description provided for @faqAnswer4.
  ///
  /// In fr, this message translates to:
  /// **'Va dans l\'historique, fais un appui long le souvenir, sélectionne-le et appuie sur le bouton \'Supprimer\'.'**
  String get faqAnswer4;

  /// No description provided for @catSelfLove.
  ///
  /// In fr, this message translates to:
  /// **'Amour de soi'**
  String get catSelfLove;

  /// No description provided for @catFriendship.
  ///
  /// In fr, this message translates to:
  /// **'Amitié'**
  String get catFriendship;

  /// No description provided for @catCouple.
  ///
  /// In fr, this message translates to:
  /// **'Couple'**
  String get catCouple;

  /// No description provided for @catFamily.
  ///
  /// In fr, this message translates to:
  /// **'Famille'**
  String get catFamily;

  /// No description provided for @catLeisure.
  ///
  /// In fr, this message translates to:
  /// **'Loisirs'**
  String get catLeisure;

  /// No description provided for @catWork.
  ///
  /// In fr, this message translates to:
  /// **'Travail'**
  String get catWork;

  /// No description provided for @catOthers.
  ///
  /// In fr, this message translates to:
  /// **'Autres'**
  String get catOthers;

  /// No description provided for @catUnclassified.
  ///
  /// In fr, this message translates to:
  /// **'Non classées'**
  String get catUnclassified;

  /// No description provided for @btnNewCategory.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle catégorie'**
  String get btnNewCategory;

  /// No description provided for @hintNewCategory.
  ///
  /// In fr, this message translates to:
  /// **'Nom de la catégorie...'**
  String get hintNewCategory;

  /// No description provided for @btnReset.
  ///
  /// In fr, this message translates to:
  /// **'Rétablir'**
  String get btnReset;

  /// No description provided for @btnFilter.
  ///
  /// In fr, this message translates to:
  /// **'Filtrer'**
  String get btnFilter;

  /// No description provided for @writeHappyThought.
  ///
  /// In fr, this message translates to:
  /// **'Écris ce qui te rend {accord}...'**
  String writeHappyThought(String accord);

  /// No description provided for @btnValidate.
  ///
  /// In fr, this message translates to:
  /// **'Valider'**
  String get btnValidate;

  /// No description provided for @categoryQuestion.
  ///
  /// In fr, this message translates to:
  /// **'À quelle(s) catégorie(s) appartient ce souvenir ?'**
  String get categoryQuestion;

  /// No description provided for @btnSkip.
  ///
  /// In fr, this message translates to:
  /// **'Passer'**
  String get btnSkip;

  /// No description provided for @today.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd\'hui'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In fr, this message translates to:
  /// **'Hier'**
  String get yesterday;

  /// No description provided for @btnDeleteSelection.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get btnDeleteSelection;

  /// No description provided for @btnCategorizeSelection.
  ///
  /// In fr, this message translates to:
  /// **'Catégoriser'**
  String get btnCategorizeSelection;

  /// No description provided for @alertWarningTitle.
  ///
  /// In fr, this message translates to:
  /// **'Attention'**
  String get alertWarningTitle;

  /// No description provided for @galleryDisabledMessage.
  ///
  /// In fr, this message translates to:
  /// **'Tu as désactivé l\'accès à ta galerie photo. Active-la dans tes autorisations.'**
  String get galleryDisabledMessage;

  /// No description provided for @btnEnableAccess.
  ///
  /// In fr, this message translates to:
  /// **'Activer l\'accès'**
  String get btnEnableAccess;

  /// No description provided for @emptyJarMessage.
  ///
  /// In fr, this message translates to:
  /// **'Le bocal est vide, ajoute un souvenir !'**
  String get emptyJarMessage;

  /// No description provided for @btnCancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get btnCancel;

  /// No description provided for @btnDeleteConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get btnDeleteConfirm;

  /// No description provided for @onboardingBtnGetStarted.
  ///
  /// In fr, this message translates to:
  /// **'Commencer'**
  String get onboardingBtnGetStarted;

  /// No description provided for @onboardingWelcomeMessage.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue dans ton\nespace personnel conçu\npour te redonner le\nsourire !'**
  String get onboardingWelcomeMessage;

  /// No description provided for @onboardingQuestionName.
  ///
  /// In fr, this message translates to:
  /// **'Comment t\'appelles-tu ?'**
  String get onboardingQuestionName;

  /// No description provided for @onboardingHintName.
  ///
  /// In fr, this message translates to:
  /// **'Prénom'**
  String get onboardingHintName;

  /// No description provided for @onboardingQuestionGender.
  ///
  /// In fr, this message translates to:
  /// **'Comment dois-je m\'adresser à toi ?'**
  String get onboardingQuestionGender;

  /// No description provided for @onboardingGenderMale.
  ///
  /// In fr, this message translates to:
  /// **'Au masculin'**
  String get onboardingGenderMale;

  /// No description provided for @onboardingGenderFemale.
  ///
  /// In fr, this message translates to:
  /// **'Au féminin'**
  String get onboardingGenderFemale;

  /// No description provided for @onboardingGenderNone.
  ///
  /// In fr, this message translates to:
  /// **'En écriture inclusive'**
  String get onboardingGenderNone;

  /// No description provided for @onboardingSecurityTitle.
  ///
  /// In fr, this message translates to:
  /// **'Sécurise l\'accès à ton espace'**
  String get onboardingSecurityTitle;

  /// No description provided for @onboardingHintPassword.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe (6 caractères min.)'**
  String get onboardingHintPassword;

  /// No description provided for @onboardingBiometricsLabel.
  ///
  /// In fr, this message translates to:
  /// **'Activer la biométrie'**
  String get onboardingBiometricsLabel;

  /// No description provided for @onboardingBiometricsHelp.
  ///
  /// In fr, this message translates to:
  /// **'L\'activation de la biométrie permet de déverrouiller l\'application grâce à l\'empreinte digitale ou la reconnaissance faciale, sans avoir à réécrire le mot de passe à chaque connexion.'**
  String get onboardingBiometricsHelp;

  /// No description provided for @onboardingBtnNext.
  ///
  /// In fr, this message translates to:
  /// **'Suivant'**
  String get onboardingBtnNext;

  /// No description provided for @onboardingBtnValidate.
  ///
  /// In fr, this message translates to:
  /// **'Valider'**
  String get onboardingBtnValidate;

  /// No description provided for @demoSkip.
  ///
  /// In fr, this message translates to:
  /// **'PASSER'**
  String get demoSkip;

  /// No description provided for @demoBtnNext.
  ///
  /// In fr, this message translates to:
  /// **'Suivant'**
  String get demoBtnNext;

  /// No description provided for @demoBtnFinish.
  ///
  /// In fr, this message translates to:
  /// **'Terminer'**
  String get demoBtnFinish;

  /// No description provided for @demoPhotoTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une photo'**
  String get demoPhotoTitle;

  /// No description provided for @demoPhotoDesc.
  ///
  /// In fr, this message translates to:
  /// **'Clique ici pour importer tes photos préférées et les classer dans ton espace personnel.'**
  String get demoPhotoDesc;

  /// No description provided for @demoNoteTitle.
  ///
  /// In fr, this message translates to:
  /// **'Écrire une note'**
  String get demoNoteTitle;

  /// No description provided for @demoNoteDesc.
  ///
  /// In fr, this message translates to:
  /// **'Enregistre une pensée, un mot doux ou un souvenir marquant textuel à conserver.'**
  String get demoNoteDesc;

  /// No description provided for @demoBocalTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ton bocal à souvenirs'**
  String get demoBocalTitle;

  /// No description provided for @demoBocalDesc.
  ///
  /// In fr, this message translates to:
  /// **'Appuie sur le bocal à tout moment pour tirer au sort un souvenir enregistré et te redonner le sourire !'**
  String get demoBocalDesc;

  /// No description provided for @demoBurgerTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ton historique'**
  String get demoBurgerTitle;

  /// No description provided for @demoBurgerDesc.
  ///
  /// In fr, this message translates to:
  /// **'Ouvre ce menu à tout moment pour retrouver la liste chronologique de tous tes précieux souvenirs enregistrés.'**
  String get demoBurgerDesc;

  /// No description provided for @profilAlertGalleryMessage.
  ///
  /// In fr, this message translates to:
  /// **'Attention, si tu décides de supprimer l\'accès à ta galerie photo, tu ne pourras plus enregistrer de photos dans tes souvenirs.'**
  String get profilAlertGalleryMessage;

  /// No description provided for @profilAlertBtnDisable.
  ///
  /// In fr, this message translates to:
  /// **'Désactiver l\'accès'**
  String get profilAlertBtnDisable;

  /// No description provided for @notifLabelTitleGratitude.
  ///
  /// In fr, this message translates to:
  /// **'Rappel de gratitude'**
  String get notifLabelTitleGratitude;

  /// No description provided for @notifLabelSubGratitude.
  ///
  /// In fr, this message translates to:
  /// **'Me rappeler de noter un souvenir positif'**
  String get notifLabelSubGratitude;

  /// No description provided for @notifLabelTime.
  ///
  /// In fr, this message translates to:
  /// **'Heure du rappel'**
  String get notifLabelTime;

  /// No description provided for @notifLabelTitleSouvenirs.
  ///
  /// In fr, this message translates to:
  /// **'Fréquence des souvenirs tirés'**
  String get notifLabelTitleSouvenirs;

  /// No description provided for @notifLabelSubSouvenirs.
  ///
  /// In fr, this message translates to:
  /// **'Me proposer un vieux souvenir à revoir'**
  String get notifLabelSubSouvenirs;

  /// No description provided for @notifLabelFreqSettings.
  ///
  /// In fr, this message translates to:
  /// **'Réglages de la fréquence'**
  String get notifLabelFreqSettings;

  /// No description provided for @notifFreqEveryDay.
  ///
  /// In fr, this message translates to:
  /// **'Tous les jours'**
  String get notifFreqEveryDay;

  /// No description provided for @notifFreqEveryWeek.
  ///
  /// In fr, this message translates to:
  /// **'Toutes les semaines'**
  String get notifFreqEveryWeek;

  /// No description provided for @notifLabelDayOfWeek.
  ///
  /// In fr, this message translates to:
  /// **'Jours de la semaine'**
  String get notifLabelDayOfWeek;

  /// No description provided for @notifDayMonday.
  ///
  /// In fr, this message translates to:
  /// **'Lundi'**
  String get notifDayMonday;

  /// No description provided for @notifDayTuesday.
  ///
  /// In fr, this message translates to:
  /// **'Mardi'**
  String get notifDayTuesday;

  /// No description provided for @notifDayWednesday.
  ///
  /// In fr, this message translates to:
  /// **'Mercredi'**
  String get notifDayWednesday;

  /// No description provided for @notifDayThursday.
  ///
  /// In fr, this message translates to:
  /// **'Jeudi'**
  String get notifDayThursday;

  /// No description provided for @notifDayFriday.
  ///
  /// In fr, this message translates to:
  /// **'Vendredi'**
  String get notifDayFriday;

  /// No description provided for @notifDaySaturday.
  ///
  /// In fr, this message translates to:
  /// **'Samedi'**
  String get notifDaySaturday;

  /// No description provided for @notifDaySunday.
  ///
  /// In fr, this message translates to:
  /// **'Dimanche'**
  String get notifDaySunday;

  /// No description provided for @notifLabelCategoriesIncluded.
  ///
  /// In fr, this message translates to:
  /// **'Catégories incluses'**
  String get notifLabelCategoriesIncluded;

  /// No description provided for @notifAllCategories.
  ///
  /// In fr, this message translates to:
  /// **'Toutes catégories'**
  String get notifAllCategories;

  /// No description provided for @notifBocalVideTitle.
  ///
  /// In fr, this message translates to:
  /// **'Bocal vide'**
  String get notifBocalVideTitle;

  /// No description provided for @notifBocalVideBody.
  ///
  /// In fr, this message translates to:
  /// **'Aucun souvenir à afficher dans les catégories sélectionnées.'**
  String get notifBocalVideBody;

  /// No description provided for @resetPasswordTitle.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialise ton mot de passe'**
  String get resetPasswordTitle;

  /// No description provided for @resetPasswordHintNew.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau mot de passe'**
  String get resetPasswordHintNew;

  /// No description provided for @resetPasswordHintConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Confirmez le mot de passe'**
  String get resetPasswordHintConfirm;

  /// No description provided for @resetPasswordErrorEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez remplir tous les champs'**
  String get resetPasswordErrorEmpty;

  /// No description provided for @resetPasswordErrorMismatch.
  ///
  /// In fr, this message translates to:
  /// **'Les mots de passe ne correspondent pas'**
  String get resetPasswordErrorMismatch;

  /// No description provided for @resetPasswordSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe réinitialisé avec succès'**
  String get resetPasswordSuccess;

  /// No description provided for @lockBiometricReason.
  ///
  /// In fr, this message translates to:
  /// **'Verrouillage de sécurité Sourire'**
  String get lockBiometricReason;

  /// No description provided for @lockInputHint.
  ///
  /// In fr, this message translates to:
  /// **'Entrez votre mot de passe'**
  String get lockInputHint;

  /// No description provided for @lockErrorIncorrect.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe incorrect'**
  String get lockErrorIncorrect;

  /// No description provided for @lockForgotPassword.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe oublié ?'**
  String get lockForgotPassword;

  /// No description provided for @lockBtnBiometric.
  ///
  /// In fr, this message translates to:
  /// **'Utiliser l\'empreinte'**
  String get lockBtnBiometric;

  /// No description provided for @purchaseAlertTitle.
  ///
  /// In fr, this message translates to:
  /// **'Limite atteinte'**
  String get purchaseAlertTitle;

  /// No description provided for @purchaseAlertMessage.
  ///
  /// In fr, this message translates to:
  /// **'Tu as atteint la limite de {limite} souvenirs pour la version gratuite. Passe à la version Premium pour ajouter des souvenirs en illimité !'**
  String purchaseAlertMessage(int limite);

  /// No description provided for @deleteAlertTitle.
  ///
  /// In fr, this message translates to:
  /// **'Veux-tu vraiment supprimer ces souvenirs ?'**
  String get deleteAlertTitle;

  /// No description provided for @deleteAlertMessage.
  ///
  /// In fr, this message translates to:
  /// **'Cette action est irréversible et entraînera la suppression définitive des souvenirs sélectionnés.'**
  String get deleteAlertMessage;

  /// No description provided for @emptyHistory.
  ///
  /// In fr, this message translates to:
  /// **'L\'historique est vide'**
  String get emptyHistory;

  /// No description provided for @notifGratitudeChannelName.
  ///
  /// In fr, this message translates to:
  /// **'Rappel de Gratitude'**
  String get notifGratitudeChannelName;

  /// No description provided for @notifGratitudeChannelDesc.
  ///
  /// In fr, this message translates to:
  /// **'Pour te rappeler de noter tes pensées positives'**
  String get notifGratitudeChannelDesc;

  /// No description provided for @notifSouvenirsChannelName.
  ///
  /// In fr, this message translates to:
  /// **'Souvenir heureux'**
  String get notifSouvenirsChannelName;

  /// No description provided for @notifSouvenirsChannelDesc.
  ///
  /// In fr, this message translates to:
  /// **'Psst, regarde ce qui vient de remonter...'**
  String get notifSouvenirsChannelDesc;

  /// No description provided for @notifGratitudeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Rappel de gratitude'**
  String get notifGratitudeTitle;

  /// No description provided for @notifGratitudeBodyDaily.
  ///
  /// In fr, this message translates to:
  /// **'Que s\'est-il passé de positif dans ta journée ?'**
  String get notifGratitudeBodyDaily;

  /// No description provided for @notifGratitudeBodyWeekly.
  ///
  /// In fr, this message translates to:
  /// **'Que s\'est-il passé de positif dans ta semaine ?'**
  String get notifGratitudeBodyWeekly;

  /// No description provided for @notifSouvenirsDefaultTitle.
  ///
  /// In fr, this message translates to:
  /// **'Psst, regarde ce qui vient de remonter 👀'**
  String get notifSouvenirsDefaultTitle;

  /// No description provided for @notifSouvenirsEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ton bocal à bonheur est vide...'**
  String get notifSouvenirsEmptyTitle;

  /// No description provided for @notifSouvenirsEmptyBody.
  ///
  /// In fr, this message translates to:
  /// **'Ajoute tes premiers souvenirs heureux pour pouvoir les revoir ! '**
  String get notifSouvenirsEmptyBody;

  /// No description provided for @notifSouvenirsAllBody.
  ///
  /// In fr, this message translates to:
  /// **'Jette un oeil à ce souvenir...'**
  String get notifSouvenirsAllBody;

  /// No description provided for @btnPasserPremium.
  ///
  /// In fr, this message translates to:
  /// **'Passer Premium'**
  String get btnPasserPremium;

  /// No description provided for @btnAppliquer.
  ///
  /// In fr, this message translates to:
  /// **'Appliquer'**
  String get btnAppliquer;

  /// No description provided for @themesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Thèmes de l\'écran d\'accueil'**
  String get themesTitle;

  /// No description provided for @notesPurchaseSuccessSnackBar.
  ///
  /// In fr, this message translates to:
  /// **'Merci ! Le Premium est débloqué : souvenirs illimités et tous les décors.'**
  String get notesPurchaseSuccessSnackBar;

  /// No description provided for @premiumSuccessSnackBar.
  ///
  /// In fr, this message translates to:
  /// **'Premium Activé ! Tous les verrous ont sauté. Thème « {themeLabel} » appliqué.'**
  String premiumSuccessSnackBar(String themeLabel);

  /// No description provided for @themeClassique.
  ///
  /// In fr, this message translates to:
  /// **'Classique'**
  String get themeClassique;

  /// No description provided for @themeMontagne.
  ///
  /// In fr, this message translates to:
  /// **'Montagne'**
  String get themeMontagne;

  /// No description provided for @themeMer.
  ///
  /// In fr, this message translates to:
  /// **'Mer'**
  String get themeMer;

  /// No description provided for @themeSport.
  ///
  /// In fr, this message translates to:
  /// **'Sport'**
  String get themeSport;

  /// No description provided for @themeVoyage.
  ///
  /// In fr, this message translates to:
  /// **'Voyage'**
  String get themeVoyage;

  /// No description provided for @themeMusique.
  ///
  /// In fr, this message translates to:
  /// **'Musique'**
  String get themeMusique;

  /// No description provided for @themeCinema.
  ///
  /// In fr, this message translates to:
  /// **'Cinéma'**
  String get themeCinema;

  /// No description provided for @themeAnimauxMarins.
  ///
  /// In fr, this message translates to:
  /// **'Animaux marins'**
  String get themeAnimauxMarins;

  /// No description provided for @themeAmour.
  ///
  /// In fr, this message translates to:
  /// **'Amour'**
  String get themeAmour;

  /// No description provided for @themeCelebration.
  ///
  /// In fr, this message translates to:
  /// **'Célébrations'**
  String get themeCelebration;

  /// No description provided for @themeNature.
  ///
  /// In fr, this message translates to:
  /// **'Nature'**
  String get themeNature;

  /// No description provided for @themeKawaii.
  ///
  /// In fr, this message translates to:
  /// **'Kawaii'**
  String get themeKawaii;

  /// No description provided for @btnContinuerPalier.
  ///
  /// In fr, this message translates to:
  /// **'Continuer'**
  String get btnContinuerPalier;

  /// No description provided for @badge10Name.
  ///
  /// In fr, this message translates to:
  /// **'Chercheur d’Étoiles'**
  String get badge10Name;

  /// No description provided for @badge10Phrase.
  ///
  /// In fr, this message translates to:
  /// **'Les plus beaux souvenirs commencent souvent tout petits.'**
  String get badge10Phrase;

  /// No description provided for @badge50Name.
  ///
  /// In fr, this message translates to:
  /// **'Cueilleur de Beauté'**
  String get badge50Name;

  /// No description provided for @badge50Phrase.
  ///
  /// In fr, this message translates to:
  /// **'Continue à capturer les instants qui illuminent tes journées.'**
  String get badge50Phrase;

  /// No description provided for @badge100Name.
  ///
  /// In fr, this message translates to:
  /// **'Gardien des Instants'**
  String get badge100Name;

  /// No description provided for @badge100Phrase.
  ///
  /// In fr, this message translates to:
  /// **'Ton bocal devient un vrai refuge à souvenirs.'**
  String get badge100Phrase;

  /// No description provided for @badge200Name.
  ///
  /// In fr, this message translates to:
  /// **'Conteur de Souvenirs'**
  String get badge200Name;

  /// No description provided for @badge200Phrase.
  ///
  /// In fr, this message translates to:
  /// **'Chaque souvenir ajoute une page à ton histoire.'**
  String get badge200Phrase;

  /// No description provided for @badge500Name.
  ///
  /// In fr, this message translates to:
  /// **'Émanateur de Joie'**
  String get badge500Name;

  /// No description provided for @badge500Phrase.
  ///
  /// In fr, this message translates to:
  /// **'Ton bocal se remplit de beaux moments à revivre.'**
  String get badge500Phrase;

  /// No description provided for @badge1000Name.
  ///
  /// In fr, this message translates to:
  /// **'Alchimiste du Bonheur'**
  String get badge1000Name;

  /// No description provided for @badge1000Phrase.
  ///
  /// In fr, this message translates to:
  /// **'Continue à garder précieusement ces petits instants de joie.'**
  String get badge1000Phrase;

  /// No description provided for @badge1500Name.
  ///
  /// In fr, this message translates to:
  /// **'Fée de Lumière'**
  String get badge1500Name;

  /// No description provided for @badge1500Phrase.
  ///
  /// In fr, this message translates to:
  /// **'Chaque souvenir ajouté éclaire un peu plus ton quotidien.'**
  String get badge1500Phrase;

  /// No description provided for @badge2000Name.
  ///
  /// In fr, this message translates to:
  /// **'Archiviste du Cœur'**
  String get badge2000Name;

  /// No description provided for @badge2000Phrase.
  ///
  /// In fr, this message translates to:
  /// **'Ton bocal devient une vraie mémoire d’émotions.'**
  String get badge2000Phrase;

  /// No description provided for @badge2500Name.
  ///
  /// In fr, this message translates to:
  /// **'Orfèvre d’Émotions'**
  String get badge2500Name;

  /// No description provided for @badge2500Phrase.
  ///
  /// In fr, this message translates to:
  /// **'Tu collectionnes des souvenirs aussi précieux que rares.'**
  String get badge2500Phrase;

  /// No description provided for @badge3000Name.
  ///
  /// In fr, this message translates to:
  /// **'Horloger des Instants'**
  String get badge3000Name;

  /// No description provided for @badge3000Phrase.
  ///
  /// In fr, this message translates to:
  /// **'Tu transformes les instants fugaces en souvenirs durables.'**
  String get badge3000Phrase;

  /// No description provided for @badge3500Name.
  ///
  /// In fr, this message translates to:
  /// **'Veilleur de Lumière'**
  String get badge3500Name;

  /// No description provided for @badge3500Phrase.
  ///
  /// In fr, this message translates to:
  /// **'Même les petits moments peuvent illuminer une journée.'**
  String get badge3500Phrase;

  /// No description provided for @badge4000Name.
  ///
  /// In fr, this message translates to:
  /// **'Gardien d’Éternité'**
  String get badge4000Name;

  /// No description provided for @badge4000Phrase.
  ///
  /// In fr, this message translates to:
  /// **'Tu construis une collection de souvenirs hors du temps.'**
  String get badge4000Phrase;

  /// No description provided for @badge4500Name.
  ///
  /// In fr, this message translates to:
  /// **'Mage des Souvenirs'**
  String get badge4500Name;

  /// No description provided for @badge4500Phrase.
  ///
  /// In fr, this message translates to:
  /// **'Ton bocal déborde déjà de moments précieux.'**
  String get badge4500Phrase;

  /// No description provided for @badge5000Name.
  ///
  /// In fr, this message translates to:
  /// **'Légende de Sourire'**
  String get badge5000Name;

  /// No description provided for @badge5000Phrase.
  ///
  /// In fr, this message translates to:
  /// **'Les plus beaux souvenirs sont encore à venir.'**
  String get badge5000Phrase;

  /// No description provided for @rewardsSectionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Récompenses'**
  String get rewardsSectionTitle;

  /// No description provided for @myBadgesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mes badges'**
  String get myBadgesTitle;

  /// No description provided for @btnSelectAll.
  ///
  /// In fr, this message translates to:
  /// **'Tout sélectionner'**
  String get btnSelectAll;

  /// No description provided for @btnDeselectAll.
  ///
  /// In fr, this message translates to:
  /// **'Tout désélectionner'**
  String get btnDeselectAll;

  /// No description provided for @selectedCountLabel.
  ///
  /// In fr, this message translates to:
  /// **'{count} sélectionné(s)'**
  String selectedCountLabel(int count);

  /// No description provided for @jarFullTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ton bocal est plein !'**
  String get jarFullTitle;

  /// No description provided for @jarFullMessage.
  ///
  /// In fr, this message translates to:
  /// **'Un nouveau bocal t\'attend, tes souvenirs restent bien sûr tous conservés, seul l\'affichage change.'**
  String get jarFullMessage;

  /// No description provided for @btnNewJar.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau bocal'**
  String get btnNewJar;

  /// No description provided for @shareError.
  ///
  /// In fr, this message translates to:
  /// **'Le partage n\'a pas pu aboutir. Réessaie.'**
  String get shareError;

  /// No description provided for @amorceVoyage.
  ///
  /// In fr, this message translates to:
  /// **'Ton meilleur souvenir de voyage...'**
  String get amorceVoyage;

  /// No description provided for @amorceFouRire.
  ///
  /// In fr, this message translates to:
  /// **'Ton dernier fou rire !'**
  String get amorceFouRire;

  /// No description provided for @amorceCadeau.
  ///
  /// In fr, this message translates to:
  /// **'Le plus beau cadeau qu\'on t\'ait offert.'**
  String get amorceCadeau;

  /// No description provided for @amorceToi.
  ///
  /// In fr, this message translates to:
  /// **'Ce que tu aimes le plus chez toi.'**
  String get amorceToi;

  /// No description provided for @amorceFierte.
  ///
  /// In fr, this message translates to:
  /// **'Ce dont tu es le·la plus fièr·e !'**
  String get amorceFierte;

  /// No description provided for @backupExportTitle.
  ///
  /// In fr, this message translates to:
  /// **'Exporter mes souvenirs'**
  String get backupExportTitle;

  /// No description provided for @backupExportSub.
  ///
  /// In fr, this message translates to:
  /// **'Fabrique une archive contenant tes notes et tes photos. Tu la ranges où tu veux : rien n\'est envoyé sur Internet.'**
  String get backupExportSub;

  /// No description provided for @backupImportTitle.
  ///
  /// In fr, this message translates to:
  /// **'Restaurer une sauvegarde'**
  String get backupImportTitle;

  /// No description provided for @backupImportSub.
  ///
  /// In fr, this message translates to:
  /// **'Ajoute les souvenirs d\'une archive. Rien n\'est supprimé, et les souvenirs déjà présents sont ignorés.'**
  String get backupImportSub;

  /// No description provided for @backupExportError.
  ///
  /// In fr, this message translates to:
  /// **'L\'export n\'a pas pu aboutir. Réessaie.'**
  String get backupExportError;

  /// No description provided for @backupImportError.
  ///
  /// In fr, this message translates to:
  /// **'Archive illisible. Vérifie que c\'est bien un export Sourire.'**
  String get backupImportError;

  /// No description provided for @backupImportDone.
  ///
  /// In fr, this message translates to:
  /// **'{ajoutes} souvenir(s) restauré(s), {ignores} déjà présent(s).'**
  String backupImportDone(int ajoutes, int ignores);

  /// No description provided for @restoreDefaultCategoriesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Restaurer les catégories par défaut'**
  String get restoreDefaultCategoriesTitle;

  /// No description provided for @restoreDefaultCategoriesSub.
  ///
  /// In fr, this message translates to:
  /// **'Fait revenir Amour de soi, Amitié, Couple, Famille, Loisirs et Travail si tu les as supprimées. Tes souvenirs ne sont pas modifiés.'**
  String get restoreDefaultCategoriesSub;

  /// No description provided for @restoreDefaultCategoriesDone.
  ///
  /// In fr, this message translates to:
  /// **'Catégories par défaut restaurées.'**
  String get restoreDefaultCategoriesDone;

  /// No description provided for @batchCategoryQuestion.
  ///
  /// In fr, this message translates to:
  /// **'À quelle(s) catégorie(s) appartiennent ces souvenirs ?'**
  String get batchCategoryQuestion;

  /// No description provided for @batchCategorizeOneByOne.
  ///
  /// In fr, this message translates to:
  /// **'Catégoriser 1 par 1'**
  String get batchCategorizeOneByOne;

  /// No description provided for @deleteCategoryConfirmTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer « {categorie} » ?'**
  String deleteCategoryConfirmTitle(String categorie);

  /// No description provided for @deleteCategoryConfirmBody.
  ///
  /// In fr, this message translates to:
  /// **'{nombre, plural, one{Un souvenir perdra cette catégorie.} other{{nombre} souvenirs perdront cette catégorie.}} Aucun souvenir n\'est supprimé.'**
  String deleteCategoryConfirmBody(int nombre);

  /// No description provided for @filterByPeriod.
  ///
  /// In fr, this message translates to:
  /// **'Par période'**
  String get filterByPeriod;

  /// No description provided for @filterByCategory.
  ///
  /// In fr, this message translates to:
  /// **'Par catégorie'**
  String get filterByCategory;

  /// No description provided for @btnApply.
  ///
  /// In fr, this message translates to:
  /// **'Appliquer'**
  String get btnApply;

  /// No description provided for @themePreviewQuestion.
  ///
  /// In fr, this message translates to:
  /// **'Qu\'est-ce qui te rend heureux·se aujourd\'hui ?'**
  String get themePreviewQuestion;

  /// No description provided for @notesThemesPurchaseMessage.
  ///
  /// In fr, this message translates to:
  /// **'Choisis le décor de tes notes parmi la bibliothèque de thèmes proposés.'**
  String get notesThemesPurchaseMessage;

  /// Titre de l'action « effacer tous mes souvenirs » dans le profil
  ///
  /// In fr, this message translates to:
  /// **'Effacer tous mes souvenirs'**
  String get eraseAllTitle;

  /// Explication sous le titre de l'action d'effacement
  ///
  /// In fr, this message translates to:
  /// **'Vide entièrement le bocal : souvenirs, photos et catégories créées. Ton prénom, ta langue et tes réglages restent en place.'**
  String get eraseAllSub;

  /// Titre de la première confirmation d'effacement
  ///
  /// In fr, this message translates to:
  /// **'Effacer tous tes souvenirs ?'**
  String get eraseAllConfirmTitle;

  /// Message de la première confirmation d'effacement
  ///
  /// In fr, this message translates to:
  /// **'Les souvenirs, les photos et les catégories que tu as créées seront supprimés de ce téléphone. Rien ne pourra être récupéré. Ton prénom, ta langue et tes réglages restent en place.'**
  String get eraseAllConfirmMessage;

  /// Bouton de la première confirmation
  ///
  /// In fr, this message translates to:
  /// **'Continuer'**
  String get eraseAllContinue;

  /// Titre de la seconde confirmation
  ///
  /// In fr, this message translates to:
  /// **'Dernière vérification'**
  String get eraseAllLastCallTitle;

  /// Message de la seconde confirmation
  ///
  /// In fr, this message translates to:
  /// **'Si tu veux garder une trace, ferme cette fenêtre et exporte d\'abord une sauvegarde.'**
  String get eraseAllLastCallMessage;

  /// Bouton de la seconde confirmation
  ///
  /// In fr, this message translates to:
  /// **'Effacer définitivement'**
  String get eraseAllConfirmButton;

  /// Confirmation après effacement
  ///
  /// In fr, this message translates to:
  /// **'Ton bocal est vide.'**
  String get eraseAllDone;

  /// Message d'erreur si l'effacement échoue
  ///
  /// In fr, this message translates to:
  /// **'L\'effacement n\'a pas abouti.'**
  String get eraseAllError;

  /// Bouton quand le produit n'existe pas encore dans la boutique
  ///
  /// In fr, this message translates to:
  /// **'Bientôt disponible'**
  String get premiumSoon;

  /// Lien de restauration des achats, dans la modale Premium
  ///
  /// In fr, this message translates to:
  /// **'Restaurer mes achats'**
  String get premiumRestore;

  /// Aucun achat trouvé à restaurer
  ///
  /// In fr, this message translates to:
  /// **'Aucun achat à restaurer sur ce compte.'**
  String get premiumRestoreNone;

  /// Confirmation après une restauration réussie
  ///
  /// In fr, this message translates to:
  /// **'Ton Premium a bien été restauré.'**
  String get premiumRestoreDone;

  /// La boutique ne répond pas
  ///
  /// In fr, this message translates to:
  /// **'La boutique n\'est pas joignable pour le moment. Réessaie dans un instant.'**
  String get premiumUnavailable;

  /// Achat en attente de validation extérieure
  ///
  /// In fr, this message translates to:
  /// **'Ton achat attend une validation. Le Premium se débloquera tout seul dès qu\'elle sera accordée.'**
  String get premiumPending;

  /// Échec de l'achat
  ///
  /// In fr, this message translates to:
  /// **'L\'achat n\'a pas abouti. Rien ne t\'a été facturé.'**
  String get premiumError;

  /// Titre de l'action de restauration dans le profil
  ///
  /// In fr, this message translates to:
  /// **'Restaurer mes achats'**
  String get premiumRestoreTitle;

  /// Explication sous le titre de la restauration dans le profil
  ///
  /// In fr, this message translates to:
  /// **'Tu as déjà payé le Premium sur un autre téléphone, ou après une réinstallation ? Récupère-le ici.'**
  String get premiumRestoreSub;

  /// Message de la modale Premium ouverte depuis le choix du décor de la home
  ///
  /// In fr, this message translates to:
  /// **'Choisis le décor de ton écran d\'accueil parmi la bibliothèque de thèmes proposés.'**
  String get themesPurchaseMessage;

  /// Mention sous le bouton d'abonnement : durée et prix par période. Exigée par Apple à côté du bouton d'achat (directive 3.1.2). Le prix vient de la boutique.
  ///
  /// In fr, this message translates to:
  /// **'{prix} par mois, sans engagement. Résiliable à tout moment.'**
  String premiumPriceNote(String prix);

  /// Lien vers la politique de confidentialité, dans la modale d'abonnement
  ///
  /// In fr, this message translates to:
  /// **'Confidentialité'**
  String get premiumLinkPrivacy;

  /// Lien vers les conditions d'utilisation, dans la modale d'abonnement (iOS)
  ///
  /// In fr, this message translates to:
  /// **'Conditions d\'utilisation'**
  String get premiumLinkTerms;
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
      <String>['en', 'es', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
