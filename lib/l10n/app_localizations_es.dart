// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String welcomeMessage(String prenom) {
    return 'Hola $prenom,';
  }

  @override
  String mainQuestion(String accord) {
    return '¿Qué te hace feliz hoy?';
  }

  @override
  String get personalData => 'Datos personales';

  @override
  String get firstName => 'Nombre';

  @override
  String get gender => 'Género';

  @override
  String get password => 'Contraseña';

  @override
  String get biometrics => 'Biometría';

  @override
  String get accountSettings => 'Ajustes de la aplicación';

  @override
  String get notifications => 'Notificaciones';

  @override
  String get personalization => 'Personalización';

  @override
  String get archiving => 'Archivado';

  @override
  String get accessibility => 'Accesibilidad';

  @override
  String get langues => 'Idiomas';

  @override
  String get help => 'Ayuda';

  @override
  String get secureLocalStorage => 'Almacenamiento local seguro';

  @override
  String get secureStorageSubtitle =>
      'Tus recuerdos se guardan automáticamente en tu espacio de almacenamiento privado.';

  @override
  String get active => 'Activo';

  @override
  String get spaceOccupied => 'Espacio ocupado';

  @override
  String storageCounter(String photos, String notes) {
    return 'Fotos: $photos | Notas: $notes';
  }

  @override
  String get darkMode => 'Modo oscuro';

  @override
  String get darkModeSubtitle =>
      'Cambia la interfaz a tonos oscuros para descansar la vista por la noche.';

  @override
  String get smoothAnimations => 'Animaciones suaves';

  @override
  String get smoothAnimationsSubtitle =>
      'Sustituye el efecto tornado del tarro por una aparición en fundido más ligera.';

  @override
  String get helpFaq => 'Ayuda / Preguntas frecuentes';

  @override
  String get faqQuestion1 => '¿Dónde se guardan mis recuerdos?';

  @override
  String get faqAnswer1 =>
      'Se quedan en la carpeta segura de tu teléfono, nadie más tiene acceso a ellos.';

  @override
  String get faqQuestion2 => '¿Cómo funciona el sorteo?';

  @override
  String get faqAnswer2 =>
      'Toca el tarro para hacer subir un recuerdo al azar.';

  @override
  String get faqQuestion3 => '¿Cómo se categorizan los recuerdos?';

  @override
  String get faqAnswer3 =>
      'Ve al historial y mantén pulsado un recuerdo. Entonces podrás seleccionar varios y elegir «Categorizar».';

  @override
  String get faqQuestion5 => '¿Cómo categorizo mis recuerdos uno a uno?';

  @override
  String get faqAnswer5 =>
      'Para categorizar tus recuerdos uno a uno tienes 2 opciones:\n1- Importa tus recuerdos de uno en uno.\n2- Desde la pantalla de categorización del lote seleccionado, toca la foto que lleva el contador: aparece un carrusel de tus recuerdos con la opción «Categorizar de 1 en 1».';

  @override
  String get faqQuestion6 => '¿Cómo elimino categorías de recuerdos?';

  @override
  String get faqAnswer6 =>
      'En la pantalla de selección de categorías, desliza hacia la izquierda la categoría que quieres eliminar.';

  @override
  String get faqQuestion4 => '¿Cómo se eliminan los recuerdos?';

  @override
  String get faqAnswer4 =>
      'Ve al historial, mantén pulsado el recuerdo, selecciónalo y toca el botón «Eliminar».';

  @override
  String get catSelfLove => 'Amor propio';

  @override
  String get catFriendship => 'Amistad';

  @override
  String get catCouple => 'Pareja';

  @override
  String get catFamily => 'Familia';

  @override
  String get catLeisure => 'Ocio';

  @override
  String get catWork => 'Trabajo';

  @override
  String get catOthers => 'Otros';

  @override
  String get catUnclassified => 'Sin clasificar';

  @override
  String get btnNewCategory => 'Nueva categoría';

  @override
  String get hintNewCategory => 'Nombre de la categoría...';

  @override
  String get btnReset => 'Restablecer';

  @override
  String get btnFilter => 'Filtrar';

  @override
  String writeHappyThought(String accord) {
    return 'Escribe lo que te hace feliz...';
  }

  @override
  String get btnValidate => 'Validar';

  @override
  String get categoryQuestion => '¿A qué categoría(s) pertenece este recuerdo?';

  @override
  String get btnSkip => 'Omitir';

  @override
  String get today => 'Hoy';

  @override
  String get yesterday => 'Ayer';

  @override
  String get btnDeleteSelection => 'Eliminar';

  @override
  String get btnCategorizeSelection => 'Categorizar';

  @override
  String get emptyJarMessage => 'El tarro está vacío, ¡añade un recuerdo!';

  @override
  String get btnCancel => 'Cancelar';

  @override
  String get btnDeleteConfirm => 'Eliminar';

  @override
  String get onboardingBtnGetStarted => 'Empezar';

  @override
  String get onboardingWelcomeMessage =>
      '¡Te damos la bienvenida\na tu espacio personal,\ncreado para devolverte\nla sonrisa!';

  @override
  String get onboardingQuestionName => '¿Cómo te llamas?';

  @override
  String get onboardingHintName => 'Nombre';

  @override
  String get onboardingQuestionGender => '¿Cómo debo dirigirme a ti?';

  @override
  String get onboardingGenderMale => 'En masculino';

  @override
  String get onboardingGenderFemale => 'En femenino';

  @override
  String get onboardingGenderNone => 'En lenguaje inclusivo';

  @override
  String get onboardingSecurityTitle => 'Protege el acceso a tu espacio';

  @override
  String get onboardingHintPassword => 'Contraseña (mín. 6 caracteres)';

  @override
  String get onboardingBiometricsLabel => 'Activar la biometría';

  @override
  String get onboardingBiometricsHelp =>
      'Activar la biometría permite desbloquear la aplicación con la huella digital o el reconocimiento facial, sin tener que escribir la contraseña cada vez.';

  @override
  String get onboardingBtnNext => 'Siguiente';

  @override
  String get onboardingBtnValidate => 'Validar';

  @override
  String get demoSkip => 'OMITIR';

  @override
  String get demoBtnNext => 'Siguiente';

  @override
  String get demoBtnFinish => 'Terminar';

  @override
  String get demoPhotoTitle => 'Añadir una foto';

  @override
  String get demoPhotoDesc =>
      'Toca aquí para importar tus fotos favoritas y ordenarlas en tu espacio personal.';

  @override
  String get demoNoteTitle => 'Escribir una nota';

  @override
  String get demoNoteDesc =>
      'Guarda un pensamiento, unas palabras bonitas o un recuerdo escrito que quieras conservar.';

  @override
  String get demoBocalTitle => 'Tu tarro de recuerdos';

  @override
  String get demoBocalDesc =>
      'Toca el tarro cuando quieras para sortear un recuerdo guardado y devolverte la sonrisa.';

  @override
  String get demoBurgerTitle => 'Tu historial';

  @override
  String get demoBurgerDesc =>
      'Abre este menú cuando quieras para encontrar la lista cronológica de todos tus preciados recuerdos guardados.';

  @override
  String get notifLabelTitleGratitude => 'Recordatorio de gratitud';

  @override
  String get notifLabelSubGratitude => 'Recordarme anotar un recuerdo positivo';

  @override
  String get notifLabelTime => 'Hora del recordatorio';

  @override
  String get notifLabelTitleSouvenirs =>
      'Frecuencia de los recuerdos sorteados';

  @override
  String get notifLabelSubSouvenirs =>
      'Proponerme un recuerdo antiguo para revivirlo';

  @override
  String get notifLabelFreqSettings => 'Ajustes de la frecuencia';

  @override
  String get notifFreqEveryDay => 'Todos los días';

  @override
  String get notifFreqEveryWeek => 'Todas las semanas';

  @override
  String get notifLabelDayOfWeek => 'Días de la semana';

  @override
  String get notifDayMonday => 'Lunes';

  @override
  String get notifDayTuesday => 'Martes';

  @override
  String get notifDayWednesday => 'Miércoles';

  @override
  String get notifDayThursday => 'Jueves';

  @override
  String get notifDayFriday => 'Viernes';

  @override
  String get notifDaySaturday => 'Sábado';

  @override
  String get notifDaySunday => 'Domingo';

  @override
  String get notifLabelCategoriesIncluded => 'Categorías incluidas';

  @override
  String get notifAllCategories => 'Todas las categorías';

  @override
  String get notifBocalVideTitle => 'Tarro vacío';

  @override
  String get notifBocalVideBody =>
      'No hay ningún recuerdo que mostrar en las categorías seleccionadas.';

  @override
  String get resetPasswordTitle => 'Restablece tu contraseña';

  @override
  String get resetPasswordHintNew => 'Nueva contraseña';

  @override
  String get resetPasswordHintConfirm => 'Confirma la contraseña';

  @override
  String get resetPasswordErrorEmpty => 'Rellena todos los campos';

  @override
  String get resetPasswordErrorMismatch => 'Las contraseñas no coinciden';

  @override
  String get resetPasswordSuccess => 'Contraseña restablecida correctamente';

  @override
  String get lockBiometricReason => 'Bloqueo de seguridad de Sourire';

  @override
  String get lockInputHint => 'Introduce tu contraseña';

  @override
  String get lockErrorIncorrect => 'Contraseña incorrecta';

  @override
  String get lockForgotPassword => '¿Has olvidado tu contraseña?';

  @override
  String get lockBtnBiometric => 'Usar la huella';

  @override
  String get purchaseAlertTitle => 'Límite alcanzado';

  @override
  String purchaseAlertMessage(int limite) {
    return 'Has alcanzado el límite de $limite recuerdos de la versión gratuita. ¡Pásate a Premium para añadir recuerdos sin límite!';
  }

  @override
  String get deleteAlertTitle =>
      '¿Seguro que quieres eliminar estos recuerdos?';

  @override
  String get deleteAlertMessage =>
      'Esta acción es irreversible y eliminará definitivamente los recuerdos seleccionados.';

  @override
  String get emptyHistory => 'El historial está vacío';

  @override
  String get notifGratitudeChannelName => 'Recordatorio de gratitud';

  @override
  String get notifGratitudeChannelDesc =>
      'Para recordarte anotar tus pensamientos positivos';

  @override
  String get notifSouvenirsChannelName => 'Recuerdo feliz';

  @override
  String get notifSouvenirsChannelDesc => 'Oye, mira lo que acaba de salir...';

  @override
  String get notifGratitudeTitle => 'Recordatorio de gratitud';

  @override
  String get notifGratitudeBodyDaily => '¿Qué ha pasado de bonito en tu día?';

  @override
  String get notifGratitudeBodyWeekly =>
      '¿Qué ha pasado de bonito en tu semana?';

  @override
  String get notifSouvenirsDefaultTitle => 'Oye, mira lo que acaba de salir 👀';

  @override
  String get notifSouvenirsEmptyTitle =>
      'Tu tarro de la felicidad está vacío...';

  @override
  String get notifSouvenirsEmptyBody =>
      '¡Añade tus primeros recuerdos felices para poder revivirlos! ';

  @override
  String get notifSouvenirsAllBody => 'Echa un vistazo a este recuerdo...';

  @override
  String get btnPasserPremium => 'Pasar a Premium';

  @override
  String get btnAppliquer => 'Aplicar';

  @override
  String get themesTitle => 'Temas de la pantalla de inicio';

  @override
  String get notesPurchaseSuccessSnackBar =>
      '¡Gracias! El Premium está desbloqueado: recuerdos ilimitados y todos los decorados.';

  @override
  String premiumSuccessSnackBar(String themeLabel) {
    return '¡Premium activado! Todos los candados se han abierto. Tema «$themeLabel» aplicado.';
  }

  @override
  String get themeClassique => 'Clásico';

  @override
  String get themeMontagne => 'Montaña';

  @override
  String get themeMer => 'Mar';

  @override
  String get themeSport => 'Deporte';

  @override
  String get themeVoyage => 'Viajes';

  @override
  String get themeMusique => 'Música';

  @override
  String get themeCinema => 'Cine';

  @override
  String get themeAnimauxMarins => 'Animales marinos';

  @override
  String get themeAmour => 'Amor';

  @override
  String get themeCelebration => 'Celebraciones';

  @override
  String get themeNature => 'Naturaleza';

  @override
  String get themeKawaii => 'Kawaii';

  @override
  String get btnContinuerPalier => 'Continuar';

  @override
  String get badge10Name => 'Buscador de Estrellas';

  @override
  String get badge10Phrase =>
      'Los recuerdos más bonitos suelen empezar siendo muy pequeños.';

  @override
  String get badge50Name => 'Recolector de Belleza';

  @override
  String get badge50Phrase =>
      'Sigue capturando los instantes que iluminan tus días.';

  @override
  String get badge100Name => 'Guardián de los Instantes';

  @override
  String get badge100Phrase =>
      'Tu tarro se convierte en un verdadero refugio de recuerdos.';

  @override
  String get badge200Name => 'Narrador de Recuerdos';

  @override
  String get badge200Phrase => 'Cada recuerdo añade una página a tu historia.';

  @override
  String get badge500Name => 'Fuente de Alegría';

  @override
  String get badge500Phrase =>
      'Tu tarro se llena de bonitos momentos para revivir.';

  @override
  String get badge1000Name => 'Alquimista de la Felicidad';

  @override
  String get badge1000Phrase =>
      'Sigue guardando con cariño estos pequeños instantes de alegría.';

  @override
  String get badge1500Name => 'Hada de Luz';

  @override
  String get badge1500Phrase =>
      'Cada recuerdo añadido ilumina un poco más tu día a día.';

  @override
  String get badge2000Name => 'Archivista del Corazón';

  @override
  String get badge2000Phrase =>
      'Tu tarro se convierte en una verdadera memoria de emociones.';

  @override
  String get badge2500Name => 'Orfebre de Emociones';

  @override
  String get badge2500Phrase =>
      'Coleccionas recuerdos tan preciados como raros.';

  @override
  String get badge3000Name => 'Relojero de los Instantes';

  @override
  String get badge3000Phrase =>
      'Transformas los instantes fugaces en recuerdos duraderos.';

  @override
  String get badge3500Name => 'Vigía de la Luz';

  @override
  String get badge3500Phrase =>
      'Incluso los pequeños momentos pueden iluminar un día.';

  @override
  String get badge4000Name => 'Guardián de la Eternidad';

  @override
  String get badge4000Phrase =>
      'Construyes una colección de recuerdos fuera del tiempo.';

  @override
  String get badge4500Name => 'Mago de los Recuerdos';

  @override
  String get badge4500Phrase => 'Tu tarro ya rebosa de momentos preciados.';

  @override
  String get badge5000Name => 'Leyenda de Sourire';

  @override
  String get badge5000Phrase =>
      'Los recuerdos más bonitos están aún por llegar.';

  @override
  String get rewardsSectionTitle => 'Recompensas';

  @override
  String get myBadgesTitle => 'Mis insignias';

  @override
  String get btnSelectAll => 'Seleccionar todo';

  @override
  String get btnDeselectAll => 'Deseleccionar todo';

  @override
  String selectedCountLabel(int count) {
    return '$count seleccionado(s)';
  }

  @override
  String get jarFullTitle => '¡Tu tarro está lleno!';

  @override
  String get jarFullMessage =>
      'Te espera un tarro nuevo. Por supuesto, todos tus recuerdos se conservan: solo cambia la presentación.';

  @override
  String get btnNewJar => 'Nuevo tarro';

  @override
  String get shareError => 'No se ha podido compartir. Inténtalo de nuevo.';

  @override
  String get amorceVoyage => 'Tu mejor recuerdo de viaje...';

  @override
  String get amorceFouRire => '¡Tu último ataque de risa!';

  @override
  String get amorceCadeau => 'El regalo más bonito que te han hecho.';

  @override
  String get amorceToi => 'Lo que más te gusta de ti.';

  @override
  String get amorceFierte => '¡Tu mayor motivo de orgullo!';

  @override
  String get backupExportTitle => 'Exportar mis recuerdos';

  @override
  String get backupExportSub =>
      'Crea un archivo con tus notas y tus fotos. Lo guardas donde quieras: no se envía nada a Internet.';

  @override
  String get backupImportTitle => 'Restaurar una copia de seguridad';

  @override
  String get backupImportSub =>
      'Añade los recuerdos de un archivo. No se borra nada, y los recuerdos ya presentes se ignoran.';

  @override
  String get backupExportError =>
      'La exportación no se ha podido completar. Inténtalo de nuevo.';

  @override
  String get backupImportError =>
      'Archivo ilegible. Comprueba que sea realmente una exportación de Sourire.';

  @override
  String backupImportDone(int ajoutes, int ignores) {
    return '$ajoutes recuerdo(s) restaurado(s), $ignores ya presente(s).';
  }

  @override
  String get restoreDefaultCategoriesTitle =>
      'Restaurar las categorías por defecto';

  @override
  String get restoreDefaultCategoriesSub =>
      'Devuelve Amor propio, Amistad, Pareja, Familia, Ocio y Trabajo si las has eliminado. Tus recuerdos no se modifican.';

  @override
  String get restoreDefaultCategoriesDone =>
      'Categorías por defecto restauradas.';

  @override
  String get batchCategoryQuestion =>
      '¿A qué categoría(s) pertenecen estos recuerdos?';

  @override
  String get batchCategorizeOneByOne => 'Categorizar de 1 en 1';

  @override
  String deleteCategoryConfirmTitle(String categorie) {
    return '¿Eliminar «$categorie»?';
  }

  @override
  String deleteCategoryConfirmBody(int nombre) {
    String _temp0 = intl.Intl.pluralLogic(
      nombre,
      locale: localeName,
      other: '$nombre recuerdos perderán esta categoría.',
      one: 'Un recuerdo perderá esta categoría.',
    );
    return '$_temp0 No se elimina ningún recuerdo.';
  }

  @override
  String get filterByPeriod => 'Por periodo';

  @override
  String get filterByCategory => 'Por categoría';

  @override
  String get btnApply => 'Aplicar';

  @override
  String get themePreviewQuestion => '¿Qué te hace feliz hoy?';

  @override
  String get notesThemesPurchaseMessage =>
      'Elige el decorado de tus notas entre la biblioteca de temas.';

  @override
  String get eraseAllTitle => 'Borrar todos mis recuerdos';

  @override
  String get eraseAllSub =>
      'Vacía el tarro por completo: recuerdos, fotos y las categorías que creaste. Tu nombre, tu idioma y tus ajustes se mantienen.';

  @override
  String get eraseAllConfirmTitle => '¿Borrar todos tus recuerdos?';

  @override
  String get eraseAllConfirmMessage =>
      'Los recuerdos, las fotos y las categorías que creaste se eliminarán de este teléfono. No se podrá recuperar nada. Tu nombre, tu idioma y tus ajustes se mantienen.';

  @override
  String get eraseAllContinue => 'Continuar';

  @override
  String get eraseAllLastCallTitle => 'Última comprobación';

  @override
  String get eraseAllLastCallMessage =>
      'Si quieres conservar una copia, cierra esta ventana y exporta antes una copia de seguridad.';

  @override
  String get eraseAllConfirmButton => 'Borrar definitivamente';

  @override
  String get eraseAllDone => 'Tu tarro está vacío.';

  @override
  String get eraseAllError => 'El borrado no se ha completado.';

  @override
  String get premiumSoon => 'Muy pronto';

  @override
  String get premiumRestore => 'Restaurar mis compras';

  @override
  String get premiumRestoreNone =>
      'No hay ninguna compra que restaurar en esta cuenta.';

  @override
  String get premiumRestoreDone => 'Tu Premium se ha restaurado.';

  @override
  String get premiumUnavailable =>
      'No se puede contactar con la tienda ahora mismo. Inténtalo dentro de un momento.';

  @override
  String get premiumPending =>
      'Tu compra está pendiente de aprobación. El Premium se desbloqueará solo en cuanto se conceda.';

  @override
  String get premiumError =>
      'La compra no se ha completado. No se te ha cobrado nada.';

  @override
  String get premiumRestoreTitle => 'Restaurar mis compras';

  @override
  String get premiumRestoreSub =>
      '¿Ya pagaste el Premium en otro teléfono o tras reinstalar? Recupéralo aquí.';

  @override
  String get themesPurchaseMessage =>
      'Elige el decorado de tu pantalla de inicio entre la biblioteca de temas.';

  @override
  String premiumPriceNote(String prix) {
    return '$prix al mes, sin compromiso. Puedes cancelar cuando quieras.';
  }

  @override
  String get premiumLinkPrivacy => 'Privacidad';

  @override
  String get premiumLinkTerms => 'Condiciones de uso';
}
