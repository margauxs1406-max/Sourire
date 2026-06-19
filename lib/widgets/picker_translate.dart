import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class FrenchAssetPickerTextDelegate extends AssetPickerTextDelegate {
  const FrenchAssetPickerTextDelegate();
  @override
  String get confirm => 'Valider';
  @override
  String get cancel => 'Annuler';
  @override
  String get edit => 'Modifier';
  @override
  String get gifIndicator => 'GIF';
  @override
  String get loadFailed => 'Échec du chargement';
  @override
  String get original => 'Original';
  @override
  String get preview => 'Aperçu';
  @override
  String get select => 'Sélectionner';
  @override
  String get emptyList => 'Galerie vide';
  @override
  String get unableToAccessAll => 'Veuillez autoriser l\'accès aux photos dans les réglages.';
}