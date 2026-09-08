// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String welcomeMessage(String prenom) {
    return 'Bonjour $prenom,';
  }

  @override
  String mainQuestion(String accord) {
    return 'Qu’est-ce qui te rend $accord aujourd’hui ?';
  }

  @override
  String get personalData => 'Données personnelles';

  @override
  String get firstName => 'Prénom';

  @override
  String get gender => 'Genre';

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
  String get personalization => 'Personnalisation';

  @override
  String get permissions => 'Autorisations';

  @override
  String get archiving => 'Archivage';

  @override
  String get accessibility => 'Accessibilité';

  @override
  String get langues => 'Langues';

  @override
  String get help => 'Aide';

  @override
  String get photoGalleryAccess => 'Accès à la galerie photo';

  @override
  String get photoGallerySubtitle =>
      'Indispensable pour ajouter des photos de tes moments précieux.';

  @override
  String get secureLocalStorage => 'Stockage local sécurisé';

  @override
  String get secureStorageSubtitle =>
      'Tes souvenirs sont automatiquement sauvegardés localement sur ton espace de stockage privé.';

  @override
  String get active => 'Actif';

  @override
  String get spaceOccupied => 'Espace occupé';

  @override
  String storageCounter(String photos, String notes) {
    return 'Photos : $photos | Notes : $notes';
  }

  @override
  String get darkMode => 'Mode sombre';

  @override
  String get darkModeSubtitle =>
      'Bascule l\'interface dans des tons sombres pour reposer tes yeux le soir.';

  @override
  String get smoothAnimations => 'Animations douces';

  @override
  String get smoothAnimationsSubtitle =>
      'Remplace l\'effet tornade du bocal par une apparition en fondu plus légère.';

  @override
  String get francais => 'Français';

  @override
  String get anglais => 'English';

  @override
  String get helpFaq => 'Aide / FAQ';

  @override
  String get faqQuestion1 => 'Où sont stockés mes souvenirs ?';

  @override
  String get faqAnswer1 =>
      'Ils restent localement dans le dossier sécurisé de ton téléphone, personne d\'autre n\'y a accès.';

  @override
  String get faqQuestion2 => 'Comment fonctionne le tirage au sort ?';

  @override
  String get faqAnswer2 =>
      'Clique sur le bocal pour faire remonter un souvenir au hasard.';

  @override
  String get faqQuestion3 => 'Comment catégoriser des souvenirs ?';

  @override
  String get faqAnswer3 =>
      'Va dans l\'historique et appuie longuement sur un souvenir. Tu pourras alors en sélectionner plusieurs et choisir \'Catégoriser\'.';

  @override
  String get faqQuestion5 => 'Comment catégoriser mes souvenirs un par un ?';

  @override
  String get faqAnswer5 =>
      'Pour catégoriser tes souvenirs un par un, tu as 2 options :\n1- Importe tes souvenirs un par un.\n2- Depuis l\'écran de catégorisation du lot de souvenirs sélectionnés, clique sur la photo qui porte la pastille : un carrousel de tes souvenirs apparaît, avec l\'option « Catégoriser 1 par 1 ».';

  @override
  String get faqQuestion6 => 'Comment supprimer des catégories de souvenirs ?';

  @override
  String get faqAnswer6 =>
      'Dans l\'écran de sélection des catégories, fais glisser la catégorie que tu veux supprimer vers la gauche.';

  @override
  String get faqQuestion4 => 'Comment supprimer des souvenirs ?';

  @override
  String get faqAnswer4 =>
      'Va dans l\'historique, fais un appui long le souvenir, sélectionne-le et appuie sur le bouton \'Supprimer\'.';

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
  String get btnReset => 'Rétablir';

  @override
  String get btnFilter => 'Filtrer';

  @override
  String writeHappyThought(String accord) {
    return 'Écris ce qui te rend $accord...';
  }

  @override
  String get btnValidate => 'Valider';

  @override
  String get categoryQuestion =>
      'À quelle(s) catégorie(s) appartient ce souvenir ?';

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
  String get alertWarningTitle => 'Attention';

  @override
  String get galleryDisabledMessage =>
      'Tu as désactivé l\'accès à ta galerie photo. Active-la dans tes autorisations.';

  @override
  String get btnEnableAccess => 'Activer l\'accès';

  @override
  String get emptyJarMessage => 'Le bocal est vide, ajoute un souvenir !';

  @override
  String get btnCancel => 'Annuler';

  @override
  String get btnDeleteConfirm => 'Supprimer';

  @override
  String get onboardingBtnGetStarted => 'Commencer';

  @override
  String get onboardingWelcomeMessage =>
      'Bienvenue dans ton\nespace personnel conçu\npour te redonner le\nsourire !';

  @override
  String get onboardingQuestionName => 'Comment t\'appelles-tu ?';

  @override
  String get onboardingHintName => 'Prénom';

  @override
  String get onboardingQuestionGender => 'Comment dois-je m\'adresser à toi ?';

  @override
  String get onboardingGenderMale => 'Au masculin';

  @override
  String get onboardingGenderFemale => 'Au féminin';

  @override
  String get onboardingGenderNone => 'En écriture inclusive';

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
  String get demoPhotoDesc =>
      'Clique ici pour importer tes photos préférées et les classer dans ton espace personnel.';

  @override
  String get demoNoteTitle => 'Écrire une note';

  @override
  String get demoNoteDesc =>
      'Enregistre une pensée, un mot doux ou un souvenir marquant textuel à conserver.';

  @override
  String get demoBocalTitle => 'Ton bocal à souvenirs';

  @override
  String get demoBocalDesc =>
      'Appuie sur le bocal à tout moment pour tirer au sort un souvenir enregistré et te redonner le sourire !';

  @override
  String get demoBurgerTitle => 'Ton historique';

  @override
  String get demoBurgerDesc =>
      'Ouvre ce menu à tout moment pour retrouver la liste chronologique de tous tes précieux souvenirs enregistrés.';

  @override
  String get profilAlertGalleryMessage =>
      'Attention, si tu décides de supprimer l\'accès à ta galerie photo, tu ne pourras plus enregistrer de photos dans tes souvenirs.';

  @override
  String get profilAlertBtnDisable => 'Désactiver l\'accès';

  @override
  String get notifLabelTitleGratitude => 'Rappel de gratitude';

  @override
  String get notifLabelSubGratitude =>
      'Me rappeler de noter un souvenir positif';

  @override
  String get notifLabelTime => 'Heure du rappel';

  @override
  String get notifLabelTitleSouvenirs => 'Fréquence des souvenirs tirés';

  @override
  String get notifLabelSubSouvenirs => 'Me proposer un vieux souvenir à revoir';

  @override
  String get notifLabelFreqSettings => 'Réglages de la fréquence';

  @override
  String get notifFreqEveryDay => 'Tous les jours';

  @override
  String get notifFreqEveryWeek => 'Toutes les semaines';

  @override
  String get notifLabelDayOfWeek => 'Jours de la semaine';

  @override
  String get notifDayMonday => 'Lundi';

  @override
  String get notifDayTuesday => 'Mardi';

  @override
  String get notifDayWednesday => 'Mercredi';

  @override
  String get notifDayThursday => 'Jeudi';

  @override
  String get notifDayFriday => 'Vendredi';

  @override
  String get notifDaySaturday => 'Samedi';

  @override
  String get notifDaySunday => 'Dimanche';

  @override
  String get notifLabelCategoriesIncluded => 'Catégories incluses';

  @override
  String get notifAllCategories => 'Toutes catégories';

  @override
  String get notifBocalVideTitle => 'Bocal vide';

  @override
  String get notifBocalVideBody =>
      'Aucun souvenir à afficher dans les catégories sélectionnées.';

  @override
  String get resetPasswordTitle => 'Réinitialise ton mot de passe';

  @override
  String get resetPasswordHintNew => 'Nouveau mot de passe';

  @override
  String get resetPasswordHintConfirm => 'Confirmez le mot de passe';

  @override
  String get resetPasswordErrorEmpty => 'Veuillez remplir tous les champs';

  @override
  String get resetPasswordErrorMismatch =>
      'Les mots de passe ne correspondent pas';

  @override
  String get resetPasswordSuccess => 'Mot de passe réinitialisé avec succès';

  @override
  String get lockBiometricReason => 'Verrouillage de sécurité Sourire';

  @override
  String get lockInputHint => 'Entrez votre mot de passe';

  @override
  String get lockErrorIncorrect => 'Mot de passe incorrect';

  @override
  String get lockForgotPassword => 'Mot de passe oublié ?';

  @override
  String get lockBtnBiometric => 'Utiliser l\'empreinte';

  @override
  String get purchaseAlertTitle => 'Limite atteinte';

  @override
  String purchaseAlertMessage(int limite) {
    return 'Tu as atteint la limite de $limite souvenirs pour la version gratuite. Passe à la version Premium pour ajouter des souvenirs en illimité !';
  }

  @override
  String get deleteAlertTitle => 'Veux-tu vraiment supprimer ces souvenirs ?';

  @override
  String get deleteAlertMessage =>
      'Cette action est irréversible et entraînera la suppression définitive des souvenirs sélectionnés.';

  @override
  String get emptyHistory => 'L\'historique est vide';

  @override
  String get notifGratitudeChannelName => 'Rappel de Gratitude';

  @override
  String get notifGratitudeChannelDesc =>
      'Pour te rappeler de noter tes pensées positives';

  @override
  String get notifSouvenirsChannelName => 'Souvenir heureux';

  @override
  String get notifSouvenirsChannelDesc =>
      'Psst, regarde ce qui vient de remonter...';

  @override
  String get notifGratitudeTitle => 'Rappel de gratitude';

  @override
  String get notifGratitudeBodyDaily =>
      'Que s\'est-il passé de positif dans ta journée ?';

  @override
  String get notifGratitudeBodyWeekly =>
      'Que s\'est-il passé de positif dans ta semaine ?';

  @override
  String get notifSouvenirsDefaultTitle =>
      'Psst, regarde ce qui vient de remonter 👀';

  @override
  String get notifSouvenirsEmptyTitle => 'Ton bocal à bonheur est vide...';

  @override
  String get notifSouvenirsEmptyBody =>
      'Ajoute tes premiers souvenirs heureux pour pouvoir les revoir ! ';

  @override
  String get notifSouvenirsAllBody => 'Jette un oeil à ce souvenir...';

  @override
  String get btnPasserPremium => 'Passer Premium';

  @override
  String get btnAppliquer => 'Appliquer';

  @override
  String get themesTitle => 'Thèmes de l\'écran d\'accueil';

  @override
  String get notesPurchaseSuccessSnackBar =>
      'Merci ! Le Premium est débloqué : souvenirs illimités et tous les décors.';

  @override
  String premiumSuccessSnackBar(String themeLabel) {
    return 'Premium Activé ! Tous les verrous ont sauté. Thème « $themeLabel » appliqué.';
  }

  @override
  String get themeClassique => 'Classique';

  @override
  String get themeMontagne => 'Montagne';

  @override
  String get themeMer => 'Mer';

  @override
  String get themeSport => 'Sport';

  @override
  String get themeVoyage => 'Voyage';

  @override
  String get themeMusique => 'Musique';

  @override
  String get themeCinema => 'Cinéma';

  @override
  String get themeAnimauxMarins => 'Animaux marins';

  @override
  String get themeAmour => 'Amour';

  @override
  String get themeCelebration => 'Célébrations';

  @override
  String get themeNature => 'Nature';

  @override
  String get themeKawaii => 'Kawaii';

  @override
  String get btnContinuerPalier => 'Continuer';

  @override
  String get badge10Name => 'Chercheur d’Étoiles';

  @override
  String get badge10Phrase =>
      'Les plus beaux souvenirs commencent souvent tout petits.';

  @override
  String get badge50Name => 'Cueilleur de Beauté';

  @override
  String get badge50Phrase =>
      'Continue à capturer les instants qui illuminent tes journées.';

  @override
  String get badge100Name => 'Gardien des Instants';

  @override
  String get badge100Phrase => 'Ton bocal devient un vrai refuge à souvenirs.';

  @override
  String get badge200Name => 'Conteur de Souvenirs';

  @override
  String get badge200Phrase =>
      'Chaque souvenir ajoute une page à ton histoire.';

  @override
  String get badge500Name => 'Émanateur de Joie';

  @override
  String get badge500Phrase =>
      'Ton bocal se remplit de beaux moments à revivre.';

  @override
  String get badge1000Name => 'Alchimiste du Bonheur';

  @override
  String get badge1000Phrase =>
      'Continue à garder précieusement ces petits instants de joie.';

  @override
  String get badge1500Name => 'Fée de Lumière';

  @override
  String get badge1500Phrase =>
      'Chaque souvenir ajouté éclaire un peu plus ton quotidien.';

  @override
  String get badge2000Name => 'Archiviste du Cœur';

  @override
  String get badge2000Phrase =>
      'Ton bocal devient une vraie mémoire d’émotions.';

  @override
  String get badge2500Name => 'Orfèvre d’Émotions';

  @override
  String get badge2500Phrase =>
      'Tu collectionnes des souvenirs aussi précieux que rares.';

  @override
  String get badge3000Name => 'Horloger des Instants';

  @override
  String get badge3000Phrase =>
      'Tu transformes les instants fugaces en souvenirs durables.';

  @override
  String get badge3500Name => 'Veilleur de Lumière';

  @override
  String get badge3500Phrase =>
      'Même les petits moments peuvent illuminer une journée.';

  @override
  String get badge4000Name => 'Gardien d’Éternité';

  @override
  String get badge4000Phrase =>
      'Tu construis une collection de souvenirs hors du temps.';

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
  String selectedCountLabel(int count) {
    return '$count sélectionné(s)';
  }

  @override
  String get jarFullTitle => 'Ton bocal est plein !';

  @override
  String get jarFullMessage =>
      'Un nouveau bocal t\'attend, tes souvenirs restent bien sûr tous conservés, seul l\'affichage change.';

  @override
  String get btnNewJar => 'Nouveau bocal';

  @override
  String get shareError => 'Le partage n\'a pas pu aboutir. Réessaie.';

  @override
  String get amorceVoyage => 'Ton meilleur souvenir de voyage...';

  @override
  String get amorceFouRire => 'Ton dernier fou rire !';

  @override
  String get amorceCadeau => 'Le plus beau cadeau qu\'on t\'ait offert.';

  @override
  String get amorceToi => 'Ce que tu aimes le plus chez toi.';

  @override
  String get amorceFierte => 'Ce dont tu es le·la plus fièr·e !';

  @override
  String get backupExportTitle => 'Exporter mes souvenirs';

  @override
  String get backupExportSub =>
      'Fabrique une archive contenant tes notes et tes photos. Tu la ranges où tu veux : rien n\'est envoyé sur Internet.';

  @override
  String get backupImportTitle => 'Restaurer une sauvegarde';

  @override
  String get backupImportSub =>
      'Ajoute les souvenirs d\'une archive. Rien n\'est supprimé, et les souvenirs déjà présents sont ignorés.';

  @override
  String get backupExportError => 'L\'export n\'a pas pu aboutir. Réessaie.';

  @override
  String get backupImportError =>
      'Archive illisible. Vérifie que c\'est bien un export Sourire.';

  @override
  String backupImportDone(int ajoutes, int ignores) {
    return '$ajoutes souvenir(s) restauré(s), $ignores déjà présent(s).';
  }

  @override
  String get restoreDefaultCategoriesTitle =>
      'Restaurer les catégories par défaut';

  @override
  String get restoreDefaultCategoriesSub =>
      'Fait revenir Amour de soi, Amitié, Couple, Famille, Loisirs et Travail si tu les as supprimées. Tes souvenirs ne sont pas modifiés.';

  @override
  String get restoreDefaultCategoriesDone =>
      'Catégories par défaut restaurées.';

  @override
  String get batchCategoryQuestion =>
      'À quelle(s) catégorie(s) appartiennent ces souvenirs ?';

  @override
  String get batchCategorizeOneByOne => 'Catégoriser 1 par 1';

  @override
  String deleteCategoryConfirmTitle(String categorie) {
    return 'Supprimer « $categorie » ?';
  }

  @override
  String deleteCategoryConfirmBody(int nombre) {
    String _temp0 = intl.Intl.pluralLogic(
      nombre,
      locale: localeName,
      other: '$nombre souvenirs perdront cette catégorie.',
      one: 'Un souvenir perdra cette catégorie.',
    );
    return '$_temp0 Aucun souvenir n\'est supprimé.';
  }

  @override
  String get filterByPeriod => 'Par période';

  @override
  String get filterByCategory => 'Par catégorie';

  @override
  String get btnApply => 'Appliquer';

  @override
  String get themePreviewQuestion =>
      'Qu\'est-ce qui te rend heureux·se aujourd\'hui ?';

  @override
  String get notesThemesPurchaseMessage =>
      'Choisis le décor de tes notes parmi la bibliothèque de thèmes proposés.';

  @override
  String get eraseAllTitle => 'Effacer tous mes souvenirs';

  @override
  String get eraseAllSub =>
      'Vide entièrement le bocal : souvenirs, photos et catégories créées. Ton prénom, ta langue et tes réglages restent en place.';

  @override
  String get eraseAllConfirmTitle => 'Effacer tous tes souvenirs ?';

  @override
  String get eraseAllConfirmMessage =>
      'Les souvenirs, les photos et les catégories que tu as créées seront supprimés de ce téléphone. Rien ne pourra être récupéré. Ton prénom, ta langue et tes réglages restent en place.';

  @override
  String get eraseAllContinue => 'Continuer';

  @override
  String get eraseAllLastCallTitle => 'Dernière vérification';

  @override
  String get eraseAllLastCallMessage =>
      'Si tu veux garder une trace, ferme cette fenêtre et exporte d\'abord une sauvegarde.';

  @override
  String get eraseAllConfirmButton => 'Effacer définitivement';

  @override
  String get eraseAllDone => 'Ton bocal est vide.';

  @override
  String get eraseAllError => 'L\'effacement n\'a pas abouti.';

  @override
  String get premiumSoon => 'Bientôt disponible';

  @override
  String get premiumRestore => 'Restaurer mes achats';

  @override
  String get premiumRestoreNone => 'Aucun achat à restaurer sur ce compte.';

  @override
  String get premiumRestoreDone => 'Ton Premium a bien été restauré.';

  @override
  String get premiumUnavailable =>
      'La boutique n\'est pas joignable pour le moment. Réessaie dans un instant.';

  @override
  String get premiumPending =>
      'Ton achat attend une validation. Le Premium se débloquera tout seul dès qu\'elle sera accordée.';

  @override
  String get premiumError =>
      'L\'achat n\'a pas abouti. Rien ne t\'a été facturé.';

  @override
  String get premiumRestoreTitle => 'Restaurer mes achats';

  @override
  String get premiumRestoreSub =>
      'Tu as déjà payé le Premium sur un autre téléphone, ou après une réinstallation ? Récupère-le ici.';

  @override
  String get themesPurchaseMessage =>
      'Choisis le décor de ton écran d\'accueil parmi la bibliothèque de thèmes proposés.';

  @override
  String premiumPriceNote(String prix) {
    return '$prix par mois, sans engagement. Résiliable à tout moment.';
  }

  @override
  String get premiumLinkPrivacy => 'Confidentialité';

  @override
  String get premiumLinkTerms => 'Conditions d\'utilisation';
}
