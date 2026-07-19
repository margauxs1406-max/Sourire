// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get titleSourire => 'Sourire';

  @override
  String welcomeMessage(String prenom) => 'Bonjour $prenom,';

  @override
  String mainQuestion(String accord) => 'Qu’est-ce qui te rend $accord aujourd’hui ?';

  @override
  String get personalData => 'Données personnelles';

  @override
  String get firstName => 'Prénom';

  @override
  String get email => 'Email';

  @override
  String get password => 'Mot de passe';

  @override
  String get biometrics => 'Biométrie';

  @override
  String get accountSettings => 'Paramètres du compte';

  @override
  String get notifications => 'Notifications';

  @override
  String get permissions => 'Autorisations';

  @override
  String get archiving => 'Archivage';

  @override
  String get accessibility => 'Apparence';

  @override
  String get langues => 'Langues';

  @override
  String get help => 'Aide';

  @override
  String get logout => 'Se déconnecter';

  @override
  String get dailyGratitudeReminder => 'Rappel quotidien de gratitude';

  @override
  String get dailyReminderSubtitle => 'Me rappeler de noter un souvenir positif';

  @override
  String get reminderTime => 'Heure du rappel';

  @override
  String get drawnMemoriesFrequency => 'Fréquence des souvenirs tirés';

  @override
  String get drawnMemoriesSubtitle => 'Me proposer un vieux souvenir à revoir';

  @override
  String get frequencySettings => 'Réglages de la fréquence';

  @override
  String get categoriesIncluded => 'Catégories incluses';

  @override
  String get everyDay => 'Tous les jours';

  @override
  String get everyTwoDays => 'Tous les 2 jours';

  @override
  String get everyWeek => 'Toutes les semaines';

  @override
  String get photoGalleryAccess => 'Accès à la galerie photo';

  @override
  String get photoGallerySubtitle => 'Indispensable pour ajouter des photos de tes moments précieux.';

  @override
  String get secureLocalStorage => 'Stockage local sécurisé';

  @override
  String get secureStorageSubtitle => 'Tes souvenirs sont automatiquement sauvegardés localement sur ton espace de stockage privé.';

  @override
  String get active => 'Actif';

  @override
  String get spaceOccupied => 'Espace occupé';

  @override
  String storageCounter(String photos, String notes) => 'Photos : $photos | Notes : $notes';

  @override
  String get darkMode => 'Mode sombre';

  @override
  String get darkModeSubtitle => 'Bascule l\'interface dans des tons sombres pour reposer tes yeux le soir.';

  @override
  String get smoothAnimations => 'Animations douces';

  @override
  String get smoothAnimationsSubtitle => 'Remplace l\'effet tornade du bocal par une apparition en fondu plus légère.';

  @override
  String get francais => 'Français';

  @override
  String get anglais => 'English';

  @override
  String get helpFaq => 'Aide / FAQ';

  @override
  String get faqQuestion1 => 'Où sont stockés mes souvenirs ?';

  @override
  String get faqAnswer1 => 'Ils restent localement dans le dossier sécurisé de ton téléphone, personne d\'autre n\'y a accès.';

  @override
  String get faqQuestion2 => 'Comment fonctionne le tirage au sort ?';

  @override
  String get faqAnswer2 => 'Secoue ton téléphone ou clique sur le bocal pour faire remonter un souvenir au hasard.';

  @override
  String get faqQuestion3 => 'Comment catégoriser des souvenirs ?';

  @override
  String get faqAnswer3 => 'Va dans l\'historique et appuie longuement sur un souvenir. Tu pourras alors en sélectionner plusieurs et choisir \'Catégoriser\'.';

  @override
  String get faqQuestion4 => 'Comment supprimer des souvenirs ?';

  @override
  String get faqAnswer4 => 'Va dans l\'historique, fais un appui long le souvenir, sélectionne-le et appuie sur le bouton \'Supprimer\'.';

  @override
  String get filterTitle => 'Filtrer';

  @override
  String get categoriesTitle => 'Catégories';

  @override
  String get catSelfLove => 'Amour de soi';

  @override
  String get catFriendship => 'Amitié';

  @override
  String get catCouple => 'Couple';

  @override
  String get catFamily => 'Famille';

  @override
  String get catLeisure => 'Loisirs';

  @override
  String get catWork => 'Travail';

  @override
  String get catOthers => 'Autres';

  @override
  String get catUnclassified => 'Non classées';

  @override
  String get btnNewCategory => 'Nouvelle catégorie';

  @override
  String get hintNewCategory => 'Nom de la catégorie...';

  @override
  String get btnDeleteCategories => 'Supprimer des catégories';

  @override
  String get noCustomCategoryToDelete => 'Aucune catégorie personnalisée à supprimer.';
  
  @override
  String get btnClose => 'Fermer';

  @override
  String get titleDeleteModal => 'Gérer les catégories';

  @override
  String get btnReset => 'Rétablir';

  @override
  String get btnFilter => 'Filtrer';

  @override
  String writeHappyThought(String accord) => 'Écris ce qui te rend $accord...';

  @override
  String get btnValidate => 'Valider';

  @override
  String get categoryQuestion => 'À quelle(s) catégorie(s) appartient ce souvenir ?';

  @override
  String get btnSkip => 'Passer';

  @override
  String get today => 'Aujourd\'hui';

  @override
  String get yesterday => 'Hier';

  @override
  String get btnDeleteSelection => 'Supprimer';

  @override
  String get btnCategorizeSelection => 'Catégoriser';

  @override
  String get galleryRecent => 'Recent';

  @override
  String get galleryPreview => 'Aperçu';

  @override
  String get btnOk => 'OK';

  @override
  String get alertWarningTitle => 'Attention';

  @override
  String get galleryDisabledMessage => 'Tu as désactivé l\'accès à ta galerie photo. Active-la dans tes autorisations.';

  @override
  String get btnEnableAccess => 'Activer l\'accès';

  @override
  String get emptyJarMessage => 'Le bocal est vide, ajoute un souvenir !';

  @override
  String get deleteConfirmMessage => 'Voulez-vous vraiment supprimer définitivement ces souvenirs ?';

  @override
  String get btnCancel => 'Annuler';

  @override
  String get btnDeleteConfirm => 'Supprimer';

  @override
  String get recategorizeTitle => 'Sélectionnez les catégories à appliquer aux souvenirs sélectionnés :';

  @override
  String get btnSave => 'Enregistrer';

  @override
  String get onboardingBtnGetStarted => 'Commencer';

  @override
  String get onboardingWelcomeMessage => 'Bienvenue dans ton\nespace personnel conçu\npour te redonner le\nsourire !';

  @override
  String get onboardingQuestionName => "Comment t'appelles-tu ?";

  @override
  String get onboardingHintName => 'Prénom';

  @override
  String get onboardingQuestionGender => 'Tu es...';

  @override
  String get onboardingGenderMale => 'Un homme';

  @override
  String get onboardingGenderFemale => 'Une femme';

  @override
  String get onboardingSecurityTitle => 'Sécurise tes données';

  @override
  String get onboardingHintEmail => 'Email';

  @override
  String get onboardingEmailValid => 'email valide';

  @override
  String get onboardingEmailInvalid => 'email non valide';

  @override
  String get onboardingHintPassword => 'Mot de passe (6 caractères min.)';

  @override
  String get onboardingBiometricsTitle => 'Facilite ton accès à l\'application';

  @override
  String get onboardingBiometricsLabel => 'Activer la biométrie';

  @override
  String get onboardingBtnNext => 'Suivant';

  @override
  String get onboardingBtnValidate => 'Valider';

  @override
  String get demoSkip => 'PASSER';

  @override
  String get demoBtnNext => 'Suivant';

  @override
  String get demoBtnFinish => 'Terminer';

  @override
  String get demoPhotoTitle => 'Ajouter une photo';

  @override
  String get demoPhotoDesc => 'Clique ici pour importer tes photos préférées et les classer dans ton espace personnel.';

  @override
  String get demoNoteTitle => 'Écrire une note';

  @override
  String get demoNoteDesc => 'Enregistre une pensée, un mot doux ou un souvenir marquant textuel à conserver.';

  @override
  String get demoBocalTitle => 'Ton bocal à souvenirs';

  @override
  String get demoBocalDesc => 'Appuie sur le bocal à tout moment pour tirer au sort un souvenir enregistré et te redonner le sourire !';

  @override
  String get demoBurgerTitle => 'Ton historique';

  @override
  String get demoBurgerDesc => 'Ouvre ce menu à tout moment pour retrouver la liste chronologique de tous tes précieux souvenirs enregistrés.';

  @override
  String get profilTitlePersonalData => "Données personnelles";
  @override
  String get profilLabelFirstName => "Prénom";
  @override
  String get profilLabelEmail => "Email";
  @override
  String get profilLabelPassword => "Mot de passe";
  @override
  String get profilLabelBiometrics => "Biométrie";
  @override
  String get profilTitleAccountSettings => "Paramètres du compte";
  @override
  String get profilMenuNotifications => "Notifications";
  @override
  String get profilMenuLanguage => "Langue de l'application";
  @override
  String get profilMenuDarkMode => "Thème sombre";
  @override
  String get profilMenuSoftAnimations => "Animations douces";
  @override
  String get profilTitleStorage => "Stockage de l'appareil";
  @override
  String get profilLabelImportedPhotos => "Photos importées";
  @override
  String get profilLabelTextMemories => "Souvenirs textuels";
  @override
  String get profilLabelGalleryAccess => "Accès à la galerie";
  @override
  String get profilBtnEmpty => "Vider";
  @override
  String profilSnackbarEmptied(String label) => "$label vidé";
  @override
  String get profilTitleHelp => "Besoin d'aide ?";
  @override
  String get profilHelpQuestion1 => "Comment ajouter un souvenir ?";
  @override
  String get profilHelpAnswer1 => "Clique sur le bouton '+' sur l'écran d'accueil pour commencer à rédiger un souvenir ou importer une photo.";
  @override
  String get profilHelpQuestion2 => "Mes données sont-elles sécurisées ?";
  @override
  String get profilHelpAnswer2 => "Oui, toutes tes données sont stockées localement sur ton téléphone et chiffrées.";
  @override
  String get profilAlertTitle => "Attention";
  @override
  String get profilAlertGalleryMessage => "Attention, si tu décides de supprimer l'accès à ta galerie photo, tu ne pourras plus enregistrer de photos dans tes souvenirs.";
  @override
  String get profilAlertBtnDisable => "Désactiver l'accès";
  @override
  String get notifLabelTitleGratitude => "Rappel quotidien de gratitude";
  @override
  String get notifLabelSubGratitude => "Me rappeler de noter un souvenir positif";
  @override
  String get notifLabelTime => "Heure du rappel";
  @override
  String get notifLabelTitleSouvenirs => "Fréquence des souvenirs tirés";
  @override
  String get notifLabelSubSouvenirs => "Me proposer un vieux souvenir à revoir";
  @override
  String get notifLabelFreqSettings => "Réglages de la fréquence";
  @override
  String get notifFreqEveryDay => "Tous les jours";
  @override
  String get notifFreqEveryTwoDays => "Tous les 2 jours";
  @override
  String get notifFreqEveryWeek => "Toutes les semaines";
  @override
  String get notifLabelDayOfWeek => "Jour de la semaine";
  @override
  String get notifDayMonday => "Lundi";
  @override
  String get notifDayTuesday => "Mardi";
  @override
  String get notifDayWednesday => "Mercredi";
  @override
  String get notifDayThursday => "Jeudi";
  @override
  String get notifDayFriday => "Vendredi";
  @override
  String get notifDaySaturday => "Samedi";
  @override
  String get notifDaySunday => "Dimanche";
  @override
  String get notifLabelCategoriesIncluded => "Catégories incluses";
  @override
  String get notifAllCategories => "Toutes catégories";

  @override
String get notifBocalVideTitle => 'Bocal vide';

@override
String get notifBocalVideBody => 'Aucun souvenir à afficher dans les catégories sélectionnées.';

  @override
  String get resetPasswordTitle => "Réinitialise ton mot de passe";

  @override
  String get resetPasswordHintNew => "Nouveau mot de passe";

  @override
  String get resetPasswordHintConfirm => "Confirmez le mot de passe";

  @override
  String get resetPasswordErrorEmpty => "Veuillez remplir tous les champs";

  @override
  String get resetPasswordErrorMismatch => "Les mots de passe ne correspondent pas";

  @override
  String get resetPasswordSuccess => "Mot de passe réinitialisé avec succès";

  @override
  String get lockBiometricReason => "Verrouillage de sécurité Sourire";

  @override
  String get lockInputHint => "Entrez votre mot de passe";

  @override
  String get lockErrorIncorrect => "Mot de passe incorrect";

  @override
  String get lockForgotPassword => "Mot de passe oublié ?";

  @override
  String get lockBtnBiometric => "Utiliser l'empreinte";

  @override
  String get purchaseAlertTitle => "Limite atteinte";

  @override
  String get purchaseAlertPhotosMessage => "Tu as atteint la limite maximale de 10 photos pour la version gratuite. Passe à la version Premium pour ajouter des souvenirs en illimité et débloquer de nouveaux thèmes !";

  @override
  String get purchaseAlertNotesMessage => "Tu as atteint la limite maximale de 5 notes pour la version gratuite. Passe à la version Premium pour ajouter des souvenirs en illimité et débloquer de nouveaux thèmes !";


  @override
  String get deleteAlertTitle => "Veux-tu vraiment supprimer ces souvenirs ?";

  @override
  String get deleteAlertMessage => "Cette action est irréversible et entraînera la suppression définitive des souvenirs sélectionnés.";

  @override
  String get btnGoPremium => "Passer Premium";

  @override
  String get emptyHistory => "L'historique est vide";

  @override
  String get notifGratitudeChannelName => 'Rappel de Gratitude';

  @override
  String get notifGratitudeChannelDesc => 'Pour te rappeler de noter tes pensées positives';

  @override
  String get notifSouvenirsChannelName => 'Souvenir heureux';

  @override
  String get notifSouvenirsChannelDesc => 'Psst, regarde ce qui vient de remonter...';

  @override
  String get notifGratitudeTitle => 'Rappel de gratitude';

  @override
  String get notifGratitudeBody => "Que s'est-il passé de positif dans ta journée ? ";

  @override
  String get notifSouvenirsDefaultTitle => 'Psst, regarde ce qui vient de remonter 👀';

  @override
  String get notifSouvenirsEmptyTitle => 'Ton bocal à bonheur est vide...';

  @override
  String get notifSouvenirsEmptyBody => 'Ajoute tes premiers souvenirs heureux pour pouvoir les revoir ! ';

  @override
  String get notifSouvenirsAllBody => 'Jette un oeil à ce souvenir...';

  @override
  String get btnPasserPremium => 'Passer Premium';

  @override
  String get btnAppliquer => 'Appliquer';

  @override
  String get themesTitle => 'Thèmes';

  @override
  String get themesDescription => 'Personnalise ton interface et tes notes à tout moment en choisissant parmi les thèmes suivants.';

  @override
  String get notesPurchaseSuccessSnackBar => 'Achat simulé avec succès ! Notes et photos illimitées débloquées.';

  @override
  String premiumSuccessSnackBar(String themeLabel) {
    return 'Premium Activé ! Tous les verrous ont sauté. Thème \'$themeLabel\' appliqué.';
  }

  @override
  String get themeClassique => 'Classique';

  @override
  String get themeMontagne => 'Montagne';

  @override
  String get themeMer => 'Mer';

  @override
  String get themeAbstrait => 'Abstrait';

  @override
  String get themeSport => 'Sport';

  @override
  String get themeMusique => 'Musique';

  @override
  String get themeCinema => 'Cinéma';

  @override
  String get themeAnimauxMarins => 'Animaux marins';

  @override
  String get themeFloral => 'Floral';

  @override
  String get themeKawaii => 'Kawaii';

  @override
String get popupPalierTitle => 'Félicitations !';

@override
String popupPalierMessage(int palier) => 'Tu as ajouté $palier souvenirs à ton bocal !';

@override
String get btnContinuerPalier => 'Continuer';

@override
String get badge10Name => 'Chercheur d’Étoiles';
@override
String get badge10Phrase => 'Les plus beaux souvenirs commencent souvent tout petits.';

@override
String get badge50Name => 'Cueilleur de Beauté';
@override
String get badge50Phrase => 'Continue à capturer les instants qui illuminent tes journées.';

@override
String get badge100Name => 'Gardien des Instants';
@override
String get badge100Phrase => 'Ton bocal devient un vrai refuge à souvenirs.';

@override
String get badge200Name => 'Conteur de Souvenirs';
@override
String get badge200Phrase => 'Chaque souvenir ajoute une page à ton histoire.';

@override
String get badge500Name => 'Émanateur de Joie';
@override
String get badge500Phrase => 'Ton bocal se remplit de beaux moments à revivre.';

@override
String get badge1000Name => 'Alchimiste du Bonheur';
@override
String get badge1000Phrase => 'Continue à garder précieusement ces petits instants de joie.';

@override
String get badge1500Name => 'Fée de Lumière';
@override
String get badge1500Phrase => 'Chaque souvenir ajouté éclaire un peu plus ton quotidien.';

@override
String get badge2000Name => 'Archiviste du Cœur';
@override
String get badge2000Phrase => 'Ton bocal devient une vraie mémoire d’émotions.';

@override
String get badge2500Name => 'Orfèvre d’Émotions';
@override
String get badge2500Phrase => 'Tu collectionnes des souvenirs aussi précieux que rares.';

@override
String get badge3000Name => 'Horloger des Instants';
@override
String get badge3000Phrase => 'Tu transformes les instants fugaces en souvenirs durables.';

@override
String get badge3500Name => 'Veilleur de Lumière';
@override
String get badge3500Phrase => 'Même les petits moments peuvent illuminer une journée.';

@override
String get badge4000Name => 'Gardien d’Éternité';
@override
String get badge4000Phrase => 'Tu construis une collection de souvenirs hors du temps.';

@override
String get badge4500Name => 'Mage des Souvenirs';
@override
String get badge4500Phrase => 'Ton bocal déborde déjà de moments précieux.';

@override
String get badge5000Name => 'Légende de Sourire';
@override
String get badge5000Phrase => 'Les plus beaux souvenirs sont encore à venir.';

@override
String get rewardsSectionTitle => 'Récompenses';
@override
String get myBadgesTitle => 'Mes badges';

@override
String get btnSelectAll => 'Tout sélectionner';

@override
String get btnDeselectAll => 'Tout désélectionner';

@override
String selectedCountLabel(int count) => '$count sélectionné(s)';
}
